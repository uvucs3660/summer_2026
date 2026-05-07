import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/assignment.dart';
import '../models/assignment_group.dart';
import '../models/course.dart';
import '../models/late_policy.dart';
import '../models/module.dart';
import '../models/module_item.dart';
import '../models/quiz.dart';
import '../models/web_resource.dart';
import '../models/wiki_page.dart';
import '../ims_id.dart';
import 'frontmatter.dart';
import 'markdown_loader.dart';
import 'quiz_loader.dart';
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
  // title = first H1 in the markdown.
  //
  // Image references in the cheat-sheet markdown (e.g. `diagrams/foo.svg`)
  // are rewritten to `$IMS-CC-FILEBASE$/<cheatsheets_dir>/diagrams/foo.svg`,
  // and every non-markdown file under <cheatsheets_dir>/ is registered as
  // a WebResource so the packager copies it into the cartridge's
  // `web_resources/<cheatsheets_dir>/...` path. Canvas serves files in
  // `web_resources/` as raw binaries (no HTML sanitization), which is
  // the only way to get SVGs with embedded <style> blocks to render.
  final cheatsheetsDir = doc['cheatsheets_dir'] as String?;
  final cheatsheetSlugs = <String>[];
  final webResources = <WebResource>[];
  if (cheatsheetsDir != null) {
    final dir = Directory(p.join(contentDir, cheatsheetsDir));
    if (dir.existsSync()) {
      // Cheat sheet markdown files become wiki pages.
      final mdFiles = dir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.md'),
          ).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in mdFiles) {
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
            webResourceBaseUrl: '\$IMS-CC-FILEBASE\$/$cheatsheetsDir',
            canvasIdentifier: imsId('page:$slug'),
          ),
        ));
        cheatsheetSlugs.add(slug);
      }

      // Every non-markdown file under the cheatsheets directory ships
      // in web_resources/.
      _collectWebResources(dir, contentDir, webResources);
    }
  }

  // Build a rubric lookup so we can inline rubric tables into assignment
  // HTML bodies. Canvas Common Cartridge import does NOT carry rubric ↔
  // assignment associations (the 2025 export confirms — rubrics import as
  // a library, not attached to specific assignments). Inlining the rubric
  // table makes the criteria visible to students on the assignment page
  // even before the instructor manually attaches it via the Canvas UI.
  final rubricsBySlug = {for (final r in rubrics) r.slug: r};

  final assignments = (doc['assignments'] as List? ?? []).map((a) {
    final bodyPath = p.join(contentDir, a['body'] as String);
    final markdown = File(bodyPath).readAsStringSync();
    final rubricSlug = a['rubric'] as String?;
    final renderedBody = renderMarkdownToCanvasHtml(
      markdown,
      title: a['title'] as String,
      assetsDir: p.dirname(bodyPath),
    );
    final bodyWithRubric = rubricSlug != null && rubricsBySlug.containsKey(rubricSlug)
        ? _appendRubricTable(renderedBody, rubricsBySlug[rubricSlug]!)
        : renderedBody;
    return Assignment(
      slug: a['slug'] as String,
      title: a['title'] as String,
      htmlBody: bodyWithRubric,
      groupSlug: a['group'] as String,
      pointsPossible: a['points'] as num,
      submissionTypes: (a['submission_types'] as List).cast<String>(),
      gradingType: a['grading_type'] as String,
      rubricSlug: rubricSlug,
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
          case 'quiz':
            return ModuleItem.quiz(it['ref'] as String);
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
          webResourceBaseUrl: '\$IMS-CC-FILEBASE\$/$lecturesDir',
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

      // Pick up any non-markdown sidecar files (lecture-specific diagrams,
      // images, downloads) under the lectures directory.
      _collectWebResources(dir, contentDir, webResources);
    }
  }

  // Glob-loaded quizzes (one per .yaml file in <contentDir>/<quizzes_dir>/).
  // Each quiz auto-pairs with a remediation assignment in the same
  // assignment group, due 48h after the quiz, that the C-3 workflow uses
  // for "explain the concept you missed" submissions. The remediation
  // assignment is appended to the assignments list.
  final quizzes = <Quiz>[];
  final quizzesDir = doc['quizzes_dir'] as String?;
  if (quizzesDir != null) {
    final dir = Directory(p.join(contentDir, quizzesDir));
    if (dir.existsSync()) {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        final q = loadQuiz(f.path);
        quizzes.add(q);

        // Auto-pair a remediation assignment.
        final remediationDue = q.dueAt?.add(const Duration(hours: 48));
        final remediationBody = renderMarkdownToCanvasHtml(
          _remediationAssignmentMarkdown(q),
          title: 'Remediation — ${q.title}',
        );
        final rubric = rubricsBySlug['quiz-remediation'];
        final bodyWithRubric = rubric != null
            ? _appendRubricTable(remediationBody, rubric)
            : remediationBody;
        assignments.add(Assignment(
          slug: q.remediationAssignmentSlug,
          title: 'Remediation — ${q.title}',
          htmlBody: bodyWithRubric,
          groupSlug: q.groupSlug,
          pointsPossible: 0, // Remediation recovers points; doesn't add them.
          submissionTypes: const ['online_url'],
          gradingType: 'points',
          rubricSlug: rubric != null ? 'quiz-remediation' : null,
          dueAt: remediationDue,
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
    quizzes: quizzes,
    webResources: webResources,
    frontPageSlug: doc['front_page'] as String,
  );
}

/// Markdown body for a quiz's auto-paired remediation assignment.
/// Describes the C-3 workflow: take the quiz, for each missed question
/// commit an explanation to the portfolio repo, LLM grader scores it.
String _remediationAssignmentMarkdown(Quiz q) {
  return '''
# Remediation — ${q.title}

**Auto-paired with:** ${q.title}
**Trigger:** required only if you missed any question on the quiz.
**Submission:** commit `reflections/quiz-${q.slug}-remediation.md` to your
portfolio repo and submit the commit URL.

## What to do

For **each question you got wrong** on the quiz, write a short explanation
in your portfolio repo at `reflections/quiz-${q.slug}-remediation.md` with:

1. **The question text** (copy verbatim from the quiz feedback).
2. **The concept you missed**, in your own words (≥150 words). Cite the
   companion cheat sheet section the feedback pointed you to.
3. **A concrete example** — code snippet, system you've seen, or sprint
   work you've touched — that shows the concept in action.

If you got 100% on the quiz, you don't need to submit this assignment.

## Score recovery

The LLM grader checks each explanation for genuine understanding (vs.
paraphrasing the cheat sheet). If your remediation passes, you recover
**50% of the points you missed** on the quiz. The combined score is
recorded against the quiz, not as a separate grade entry.

If your explanations are mostly paraphrase or shallow restatement, no
points are recovered — the LLM grader's rationale will explain what was
missing.

## Vernacular

The remediation file must use vocabulary precisely. Misuse of the term
you're explaining (e.g. calling a Publish-Subscribe Channel a "broadcast"
without the EIP name) is the exact failure mode this assignment catches.
''';
}

/// Walk [dir] recursively and add every non-markdown file to [out] as a
/// WebResource. The zipPath is the file's path relative to [contentDir]
/// using POSIX separators — that path becomes the location inside the
/// cartridge's `web_resources/` directory and the suffix of every
/// `$IMS-CC-FILEBASE$/...` URL referencing it.
void _collectWebResources(
  Directory dir,
  String contentDir,
  List<WebResource> out,
) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (lower.endsWith('.md')) continue;
    final rel = p.relative(entity.path, from: contentDir).replaceAll('\\', '/');
    out.add(WebResource(srcPath: entity.path, zipPath: rel));
  }
}

/// Append a rendered HTML rubric table to an assignment body, inserted
/// just before the closing `</body>` tag. The table mirrors the rubric's
/// criteria and ratings so students can see grading criteria directly on
/// the assignment page — Canvas Common Cartridge import does not link
/// rubrics to assignments automatically.
String _appendRubricTable(String html, dynamic rubric) {
  final buf = StringBuffer();
  buf.writeln('<hr/>');
  buf.writeln('<h2>Grading rubric — ${_escapeHtml(rubric.title as String)}</h2>');
  buf.writeln(
    '<p><em>Total: ${rubric.totalPoints} points. The rubric is also '
    'in the Canvas rubric library; your instructor will attach it to '
    'this assignment for gradebook scoring.</em></p>',
  );

  final criteria = rubric.criteria as List;
  if (criteria.isEmpty) {
    buf.writeln('<p><em>(rubric has no criteria)</em></p>');
    return _spliceBeforeBody(html, buf.toString());
  }

  // Determine the maximum number of ratings any criterion has, so we can
  // build a uniformly-shaped table.
  final maxRatings = criteria
      .map<int>((c) => (c.ratings as List).length)
      .reduce((a, b) => a > b ? a : b);

  buf.writeln('<table border="1" cellpadding="6" cellspacing="0" '
      'style="border-collapse:collapse;width:100%;">');
  buf.writeln('<thead><tr>');
  buf.writeln('<th style="text-align:left;width:30%;">Criterion (max points)</th>');
  for (var i = 0; i < maxRatings; i++) {
    buf.writeln('<th style="text-align:left;">Rating ${i + 1}</th>');
  }
  buf.writeln('</tr></thead>');
  buf.writeln('<tbody>');

  for (final c in criteria) {
    buf.writeln('<tr>');
    buf.writeln(
      '<td><strong>${_escapeHtml(c.description as String)}</strong>'
      '<br/><span style="color:#6b7280;">'
      '(${c.maxPoints} pts max)</span></td>',
    );
    final ratings = c.ratings as List;
    for (var i = 0; i < maxRatings; i++) {
      if (i < ratings.length) {
        final r = ratings[i];
        buf.writeln(
          '<td>${_escapeHtml(r.description as String)}'
          '<br/><strong>${r.points} pts</strong></td>',
        );
      } else {
        buf.writeln('<td></td>');
      }
    }
    buf.writeln('</tr>');
  }
  buf.writeln('</tbody></table>');

  return _spliceBeforeBody(html, buf.toString());
}

String _spliceBeforeBody(String html, String fragment) {
  return html.replaceFirst('</body>', '$fragment\n</body>');
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

  // Canvas's CC importer resolves $WIKI_REFERENCE$/pages/<X> and
  // $CANVAS_OBJECT_REFERENCE$/assignments/<X> by matching X against the
  // IMS identifier from the manifest, NOT against the page/assignment
  // slug. Using slugs here produces "Missing links found in imported
  // content" import errors. The 2025 export confirms the format:
  // href="$WIKI_REFERENCE$/pages/g2feeec8416db2fb365488e18763c1c81".
  if (companionSheets.isNotEmpty) {
    final links = companionSheets
        .map((s) =>
            '<a href="\$WIKI_REFERENCE\$/pages/${imsId('page:$s')}">'
            '${_displayNameFromSlug(s)}</a>')
        .join(' · ');
    buf.writeln('<p><strong>Companion cheat sheets:</strong> $links</p>');
  }

  if (reflectionAssignment != null) {
    buf.writeln(
      '<p><strong>Reflection assignment:</strong> '
      '<a href="\$CANVAS_OBJECT_REFERENCE\$/assignments/'
      '${imsId('assignment:$reflectionAssignment')}">'
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
