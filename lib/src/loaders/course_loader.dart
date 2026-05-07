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
import '../ims_id.dart';
import 'frontmatter.dart';
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

  // Explicit pages from course.yaml. Each page's HTML carries the Canvas
  // <meta name="identifier"> tag matching the manifest entry — without it
  // Canvas can't link the imported HTML to the page record, leaving module
  // references silently broken.
  final pages = <WikiPage>[
    ...(doc['pages'] as List? ?? []).map((p_) {
      final bodyPath = p.join(contentDir, p_['body'] as String);
      final markdown = File(bodyPath).readAsStringSync();
      final slug = p_['slug'] as String;
      final isFront = p_['front_page'] as bool? ?? false;
      return WikiPage(
        slug: slug,
        title: p_['title'] as String,
        htmlBody: renderMarkdownToCanvasHtml(
          markdown,
          title: p_['title'] as String,
          assetsDir: p.dirname(bodyPath),
          canvasIdentifier: imsId('page:$slug'),
          canvasFrontPage: isFront,
        ),
        frontPage: isFront,
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
            canvasIdentifier: imsId('page:$slug'),
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

  // Glob-loaded lectures (one wiki page per markdown file in
  // <contentDir>/<lectures_dir>/). Each lecture has YAML frontmatter
  // declaring `week`, `youtube_id`, `companion_sheets`, `reflection_assignment`,
  // and `vernacular_tags`. The loader prepends an auto-generated metadata
  // banner (companion sheet links, reflection link, vernacular tags, video
  // embed) to the rendered markdown body. A "Lecture Spine" module is
  // auto-emitted with lectures sorted by week.
  final lecturesDir = doc['lectures_dir'] as String?;
  if (lecturesDir != null) {
    final dir = Directory(p.join(contentDir, lecturesDir));
    if (dir.existsSync()) {
      final lectureEntries = <_LectureEntry>[];
      final files = dir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.md'),
          );
      for (final f in files) {
        final raw = f.readAsStringSync();
        final fm = parseFrontmatter(raw);
        final basename = p.basenameWithoutExtension(f.path);
        final slug = (fm.data['slug'] as String?) ?? basename;
        final week = fm.data['week'] as int? ?? 0;
        final title = _extractFirstH1(fm.body) ?? slug;
        final youtubeId = fm.data['youtube_id'] as String?;
        final companionSheets = (fm.data['companion_sheets'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        final reflection = fm.data['reflection_assignment'] as String?;
        final vernacular = (fm.data['vernacular_tags'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

        final renderedBody = renderMarkdownToCanvasHtml(
          fm.body,
          title: title,
          assetsDir: p.dirname(f.path),
          canvasIdentifier: imsId('page:$slug'),
        );
        final banner = _buildLectureBanner(
          companionSheets: companionSheets,
          reflectionAssignment: reflection,
          vernacularTags: vernacular,
          youtubeId: youtubeId,
        );
        // Splice the banner into the rendered HTML right after <body>.
        final withBanner = renderedBody.replaceFirst(
          '<body>\n',
          '<body>\n$banner',
        );

        lectureEntries.add(_LectureEntry(
          slug: slug,
          week: week,
          title: title,
          html: withBanner,
        ));
      }

      lectureEntries.sort((a, b) => a.week.compareTo(b.week));
      for (final entry in lectureEntries) {
        pages.add(WikiPage(
          slug: entry.slug,
          title: entry.title,
          htmlBody: entry.html,
        ));
      }

      if (lectureEntries.isNotEmpty) {
        modules.add(Module(
          slug: 'lecture-spine',
          title: 'Lecture Spine',
          items: [
            for (final e in lectureEntries) ModuleItem.wikiPage(e.slug),
          ],
        ));
      }
    }
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

class _LectureEntry {
  final String slug;
  final int week;
  final String title;
  final String html;
  _LectureEntry({
    required this.slug,
    required this.week,
    required this.title,
    required this.html,
  });
}

/// Build the auto-generated banner HTML that's prepended to each lecture
/// page. Includes companion-sheet links, reflection link, vernacular tags,
/// and YouTube embed (or "not yet recorded" placeholder).
///
/// Internal Canvas links use the `$WIKI_REFERENCE$/pages/<slug>` and
/// `$CANVAS_OBJECT_REFERENCE$/assignments/<slug>` tokens that Canvas
/// resolves during Common Cartridge import.
String _buildLectureBanner({
  required List<String> companionSheets,
  String? reflectionAssignment,
  required List<String> vernacularTags,
  String? youtubeId,
}) {
  final buf = StringBuffer();
  buf.writeln(
    '<section class="lecture-banner" '
    'style="background:#f3f4f6;padding:1em 1.25em;'
    'border-radius:8px;margin-bottom:1.5em;border-left:4px solid #2563eb;">',
  );

  if (companionSheets.isNotEmpty) {
    final links = companionSheets
        .map((s) => '<a href="\$WIKI_REFERENCE\$/pages/$s">'
            '${_displayNameFromSlug(s)}</a>')
        .join(' · ');
    buf.writeln('<p><strong>Companion cheat sheets:</strong> $links</p>');
  }

  if (reflectionAssignment != null) {
    buf.writeln(
      '<p><strong>Reflection assignment:</strong> '
      '<a href="\$CANVAS_OBJECT_REFERENCE\$/assignments/$reflectionAssignment">'
      'Submit your reflection</a></p>',
    );
  }

  if (vernacularTags.isNotEmpty) {
    buf.writeln(
      '<p><strong>Vernacular introduced:</strong> '
      '${vernacularTags.map(_escapeHtml).join(' · ')}</p>',
    );
  }

  if (youtubeId != null && youtubeId.trim().isNotEmpty) {
    buf.writeln(
      '<div class="lecture-video" style="margin-top:0.75em;">'
      '<iframe width="640" height="360" '
      'src="https://www.youtube.com/embed/${_escapeAttr(youtubeId)}" '
      'title="Lecture video" frameborder="0" allowfullscreen></iframe>'
      '</div>',
    );
  } else {
    buf.writeln(
      '<p><em>📹 Video not yet recorded. The outline below is the '
      'authoritative content until the recording is published.</em></p>',
    );
  }

  buf.writeln('</section>');
  return buf.toString();
}

/// Convert a slug like `cheatsheet-html` to `HTML` for display. Strips a
/// known `cheatsheet-` prefix and uppercases recognized acronyms; otherwise
/// returns the slug with hyphens replaced by spaces and title-cased.
String _displayNameFromSlug(String slug) {
  var s = slug;
  if (s.startsWith('cheatsheet-')) s = s.substring('cheatsheet-'.length);
  // Recognized acronyms are uppercased verbatim.
  const acronyms = {'html', 'css', 'sql', 'pwa', 'mcp', 'ci-cd'};
  return s.split('-').map((part) {
    if (acronyms.contains(part)) return part.toUpperCase();
    if (part.isEmpty) return part;
    return part[0].toUpperCase() + part.substring(1);
  }).join(' ');
}

String _escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _escapeAttr(String s) =>
    _escapeHtml(s).replaceAll('"', '&quot;');
