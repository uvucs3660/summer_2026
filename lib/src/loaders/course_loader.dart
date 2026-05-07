import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/assignment.dart';
import '../models/assignment_group.dart';
import '../models/course.dart';
import '../models/late_policy.dart';
import '../models/module.dart';
import '../models/module_item.dart';
import '../models/wiki_page.dart';
import 'markdown_loader.dart';
import 'rubric_loader.dart';

Course loadCourse(String contentDir) {
  final yamlPath = p.join(contentDir, 'course.yaml');
  final doc = loadYaml(File(yamlPath).readAsStringSync()) as Map;

  final lp = doc['late_policy'] as Map;
  final latePolicy = LatePolicy(
    dailyDeductionPercent: lp['daily_deduction_percent'] as int,
    floorPercent: lp['floor_percent'] as int,
  );

  final groups = (doc['assignment_groups'] as List).map((g) {
    return AssignmentGroup(
      slug: g['slug'] as String,
      title: g['title'] as String,
      weight: g['weight'] as num,
    );
  }).toList();

  final rubrics = (doc['rubrics'] as List? ?? []).map((path) {
    return loadRubric(p.join(contentDir, path as String));
  }).toList();

  // Explicit pages from course.yaml
  final pages = <WikiPage>[
    ...(doc['pages'] as List? ?? []).map((p_) {
      final bodyPath = p.join(contentDir, p_['body'] as String);
      final markdown = File(bodyPath).readAsStringSync();
      return WikiPage(
        slug: p_['slug'] as String,
        title: p_['title'] as String,
        htmlBody: renderMarkdownToCanvasHtml(
          markdown,
          title: p_['title'] as String,
          assetsDir: p.dirname(bodyPath),
        ),
        frontPage: p_['front_page'] as bool? ?? false,
      );
    }),
  ];

  // Glob-loaded cheat sheets (one wiki page per markdown file in
  // <contentDir>/<cheatsheets_dir>/). Slug = `cheatsheet-<basename>`,
  // title = first H1 in the markdown. SVG references resolve relative
  // to the cheat sheet's directory (typically <cheatsheets_dir>/diagrams/).
  final cheatsheetsDir = doc['cheatsheets_dir'] as String?;
  final cheatsheetSlugs = <String>[];
  if (cheatsheetsDir != null) {
    final dir = Directory(p.join(contentDir, cheatsheetsDir));
    if (dir.existsSync()) {
      final files = dir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.md'),
          ).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        final basename = p.basenameWithoutExtension(f.path);
        final slug = 'cheatsheet-$basename';
        final markdown = f.readAsStringSync();
        final title = _extractFirstH1(markdown) ?? basename;
        pages.add(WikiPage(
          slug: slug,
          title: title,
          htmlBody: renderMarkdownToCanvasHtml(
            markdown,
            title: title,
            assetsDir: p.dirname(f.path),
          ),
        ));
        cheatsheetSlugs.add(slug);
      }
    }
  }

  final assignments = (doc['assignments'] as List? ?? []).map((a) {
    final bodyPath = p.join(contentDir, a['body'] as String);
    final markdown = File(bodyPath).readAsStringSync();
    return Assignment(
      slug: a['slug'] as String,
      title: a['title'] as String,
      htmlBody: renderMarkdownToCanvasHtml(
        markdown,
        title: a['title'] as String,
        assetsDir: p.dirname(bodyPath),
      ),
      groupSlug: a['group'] as String,
      pointsPossible: a['points'] as num,
      submissionTypes: (a['submission_types'] as List).cast<String>(),
      gradingType: a['grading_type'] as String,
      rubricSlug: a['rubric'] as String?,
      dueAt: a['due_at'] != null ? DateTime.parse(a['due_at'] as String) : null,
    );
  }).toList();

  final modules = <Module>[
    ...(doc['modules'] as List? ?? []).map((m) {
      final items = (m['items'] as List).map<ModuleItem>((it) {
        switch (it['kind'] as String) {
          case 'assignment':
            return ModuleItem.assignment(it['ref'] as String);
          case 'wiki_page':
            return ModuleItem.wikiPage(it['ref'] as String);
          case 'sub_header':
            return ModuleItem.subHeader(it['title'] as String);
          case 'external_url':
            return ModuleItem.externalUrl(
                it['title'] as String, it['url'] as String);
          default:
            throw FormatException('unknown module item kind: ${it['kind']}');
        }
      }).toList();
      return Module(
        slug: m['slug'] as String,
        title: m['title'] as String,
        items: items,
        published: m['published'] as bool? ?? true,
      );
    }),
  ];

  // Auto-emit a "Cheat Sheet Library" module containing every glob-loaded
  // cheat sheet, in filename-sorted order.
  if (cheatsheetSlugs.isNotEmpty) {
    modules.add(Module(
      slug: 'cheat-sheet-library',
      title: 'Cheat Sheet Library',
      items: [
        for (final slug in cheatsheetSlugs) ModuleItem.wikiPage(slug),
      ],
    ));
  }

  return Course(
    title: doc['title'] as String,
    courseCode: doc['course_code'] as String,
    startAt: DateTime.parse(doc['start_at'] as String),
    endAt: DateTime.parse(doc['end_at'] as String),
    gradingScheme: doc['grading_scheme'] as String,
    latePolicy: latePolicy,
    assignmentGroups: groups,
    assignments: assignments,
    wikiPages: pages,
    modules: modules,
    rubrics: rubrics,
    frontPageSlug: doc['front_page'] as String,
  );
}

/// Returns the text of the first H1 heading (`# ...`) in the markdown,
/// or null if none exists. Skips lines that are deeper headings (`##`).
String? _extractFirstH1(String markdown) {
  for (final line in markdown.split('\n')) {
    final t = line.trimLeft();
    if (t.startsWith('# ') && !t.startsWith('## ')) {
      return t.substring(2).trim();
    }
  }
  return null;
}
