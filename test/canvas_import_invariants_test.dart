// Regression tests for Canvas import invariants. These guard against
// the bugs found during manual Canvas import in May 2026:
//
//   Bug 1: assignment manifest's <file href> referenced a non-existent
//          file (`g<id>/g<id>.html`) instead of the actual body
//          (`g<id>/<slug>.html`). Canvas couldn't find the body, so
//          assignments imported with empty descriptions.
//
//   Bug 2: wiki pages were missing Canvas-specific <meta name="identifier">,
//          <meta name="editing_roles">, and <meta name="workflow_state">
//          tags. Canvas couldn't link the imported HTML to the manifest
//          identifier, so module references were silently broken.
//
//   Bug 3: resource type used `imscc_xsd` (a different IMS spec variant)
//          instead of `imscc_xmlv1p1` (the one Canvas's importer is built
//          around).
//
// If any of these tests fail in the future, do not ship the zip. Open
// the 2025 export at cs-3660-001-_-2025-summer-full-term-export/ to
// confirm the format Canvas expects.

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:course_builder/src/packager.dart';
import 'package:test/test.dart';

void main() {
  cheatsheetLinkInvariants();
  group('Canvas import invariants', () {
    late final Map<String, String> archiveContents;

    setUpAll(() {
      // Build a fresh zip from the minimal_course fixture and decode it.
      final out = File('${Directory.systemTemp.path}/canvas_invariants.imscc');
      if (out.existsSync()) out.deleteSync();
      final c = loadCourse('test/fixtures/minimal_course');
      packageCourse(c, out.path);

      archiveContents = {};
      final archive = ZipDecoder().decodeBytes(out.readAsBytesSync());
      for (final f in archive.files) {
        if (f.isFile) {
          archiveContents[f.name] = String.fromCharCodes(f.content as List<int>);
        }
      }
    });

    test('every <file> referenced by the manifest exists in the zip', () {
      // Bug 1 regression. Catches off-by-slug-vs-id <file> hrefs.
      final manifest = archiveContents['imsmanifest.xml']!;
      final fileHrefs = RegExp(r'<file href="([^"]+)"')
          .allMatches(manifest)
          .map((m) => m.group(1)!)
          .toList();

      expect(fileHrefs, isNotEmpty,
          reason: 'manifest should declare at least some files');

      for (final href in fileHrefs) {
        expect(archiveContents.containsKey(href), isTrue,
            reason:
                'manifest declares <file href="$href"> but no such file '
                'exists in the zip — Canvas will fail to import the body');
      }
    });

    test('every wiki page HTML carries the Canvas identifier meta tag', () {
      // Bug 2 regression. Without this, Canvas imports the file but does
      // not link it to the manifest identifier, leaving module items empty.
      final pageFiles = archiveContents.keys
          .where((k) => k.startsWith('wiki_content/') && k.endsWith('.html'))
          .toList();

      expect(pageFiles, isNotEmpty,
          reason: 'expected at least one wiki page in the zip');

      for (final path in pageFiles) {
        final html = archiveContents[path]!;
        expect(html, contains('<meta name="identifier"'),
            reason: '$path is missing <meta name="identifier"> — '
                'Canvas will not link this page to the manifest entry');
        expect(html, contains('<meta name="editing_roles"'),
            reason: '$path is missing <meta name="editing_roles">');
        expect(html, contains('<meta name="workflow_state"'),
            reason: '$path is missing <meta name="workflow_state">');
      }
    });

    test('exactly one wiki page declares itself the front page', () {
      final pageFiles = archiveContents.keys
          .where((k) => k.startsWith('wiki_content/') && k.endsWith('.html'));
      final frontPages = pageFiles.where((p) {
        return archiveContents[p]!.contains('<meta name="front_page"');
      }).toList();

      expect(frontPages.length, 1,
          reason: 'exactly one wiki page must be marked as the front page; '
              'found ${frontPages.length}');
    });

    test('manifest uses imscc_xmlv1p1 resource type (not imscc_xsd)', () {
      // Bug 3 regression. Canvas's CC importer is built around v1.1.
      final manifest = archiveContents['imsmanifest.xml']!;
      expect(manifest, isNot(contains('imscc_xsd')),
          reason: 'manifest contains the imscc_xsd type variant — '
              'Canvas may silently ignore resources of unknown types');
      expect(manifest, contains('imscc_xmlv1p1'),
          reason: 'expected manifest to use imscc_xmlv1p1 resource types '
              'for assignments and learning-application-resource bundles');
    });

    test('no wiki page or assignment HTML contains placeholder (#) links',
        () {
      // Regression: Canvas's import validator flags <a href="#"> as a
      // missing link ("Missing links found in imported content - Wiki
      // Page body"). These slip in when authors write `[text](#)` as a
      // placeholder for "I'll fix this later." Catch them at build time.
      final htmlFiles = archiveContents.entries.where(
        (e) => e.key.endsWith('.html'),
      );
      for (final entry in htmlFiles) {
        // package:markdown emits href="#" for `[text](#)`. Canvas treats
        // this as a missing link.
        expect(entry.value, isNot(contains('href="#"')),
            reason: '${entry.key} contains a placeholder href="#" link — '
                'Canvas will report "Missing links found in imported content"');
      }
    });

    test('QTI feedback does not use \$WIKI_REFERENCE\$ tokens', () {
      // Regression: Canvas's CC importer flags $WIKI_REFERENCE$ tokens
      // inside QTI question feedback HTML as missing links. The token
      // resolver runs over wiki-page bodies and assignment HTML, but
      // not over QTI XML. Use plain-text cheat-sheet references inside
      // quiz feedback (cheat sheet is already named in the quiz
      // description and reachable from the module structure).
      final qtiFiles = archiveContents.entries.where(
        (e) => e.key.endsWith('assessment_qti.xml') ||
            e.key.endsWith('.xml.qti'),
      );
      for (final entry in qtiFiles) {
        expect(entry.value, isNot(contains(r'$WIKI_REFERENCE$')),
            reason: '${entry.key} contains a \$WIKI_REFERENCE\$ token in '
                'QTI content — Canvas reports this as a missing link '
                'during import. Use plain text references in QTI feedback.');
        expect(entry.value, isNot(contains(r'$CANVAS_OBJECT_REFERENCE$')),
            reason: '${entry.key} contains a \$CANVAS_OBJECT_REFERENCE\$ token '
                'in QTI content — Canvas reports this as a missing link.');
      }
    });

    test('no HTML contains relative ".md" href links', () {
      // Regression: cheat sheets occasionally cross-reference each other
      // with bare-name relative links like `[CSS cheat sheet](css.md)`.
      // The markdown renderer passes those through as `href="css.md"` —
      // Canvas can't resolve them and reports "Missing links found in
      // imported content - Wiki Page body". Use the `cheatsheet-X` form
      // (backticks, plain text) instead, or a full Canvas wiki link.
      final mdHrefRegex = RegExp(r'href="([^"$/]+\.md)"');
      for (final entry
          in archiveContents.entries.where((e) => e.key.endsWith('.html'))) {
        final match = mdHrefRegex.firstMatch(entry.value);
        expect(match, isNull,
            reason: '${entry.key} contains relative .md href '
                '("${match?.group(1)}") — Canvas reports this as a '
                'missing link. Convert to `cheatsheet-X` form or use '
                'a full \$WIKI_REFERENCE\$ token.');
      }
    });

    test('Canvas \$WIKI_REFERENCE\$ tokens use IMS identifiers, not slugs',
        () {
      // Regression: Canvas's CC importer resolves
      // $WIKI_REFERENCE$/pages/<X> by matching X against the manifest IMS
      // identifier (g-prefixed 32-hex), not the page slug. Using slugs
      // produces "Missing links found in imported content" errors.
      final htmlFiles = archiveContents.entries
          .where((e) => e.key.endsWith('.html'))
          .toList();

      final wikiTokenRegex = RegExp(r'\$WIKI_REFERENCE\$/pages/([^"\s]+)');
      final assignmentTokenRegex =
          RegExp(r'\$CANVAS_OBJECT_REFERENCE\$/assignments/([^"\s]+)');
      final imsIdShape = RegExp(r'^g[0-9a-f]{32}$');

      for (final entry in htmlFiles) {
        for (final m in wikiTokenRegex.allMatches(entry.value)) {
          final ref = m.group(1)!;
          expect(imsIdShape.hasMatch(ref), isTrue,
              reason: '${entry.key}: \$WIKI_REFERENCE\$/pages/$ref must '
                  'reference a g-prefixed IMS identifier, not a slug. '
                  'Use imsId("page:<slug>") instead of <slug>.');
        }
        for (final m in assignmentTokenRegex.allMatches(entry.value)) {
          final ref = m.group(1)!;
          expect(imsIdShape.hasMatch(ref), isTrue,
              reason: '${entry.key}: \$CANVAS_OBJECT_REFERENCE\$/assignments/$ref '
                  'must reference a g-prefixed IMS identifier, not a slug. '
                  'Use imsId("assignment:<slug>") instead of <slug>.');
        }
      }
    });

    test(
      'no SVG content is inlined into HTML — diagrams ship as web_resources/',
      () {
        // Regression: when SVG is inlined into HTML, Canvas's sanitizer
        // strips <style> blocks (and sometimes <svg> entirely), breaking
        // diagrams. The current architecture rewrites <img src> paths to
        // $IMS-CC-FILEBASE$ URLs and ships the SVG files in web_resources/
        // so the browser renders them natively, untouched by Canvas.
        for (final entry
            in archiveContents.entries.where((e) => e.key.endsWith('.html'))) {
          // <svg> elements should not appear in HTML pages — they live as
          // standalone files in web_resources/.
          expect(entry.value, isNot(contains('<svg')),
              reason: '${entry.key} contains an inlined <svg> element. '
                  'SVGs should be referenced via <img src="\$IMS-CC-FILEBASE\$/...">, '
                  'not inlined into the HTML body.');
        }
      },
    );

    test(
      'every <img src="\$IMS-CC-FILEBASE\$/..."> resolves to a file in '
      'web_resources/',
      () {
        final tokenRegex =
            RegExp(r'<img\s+src="\$IMS-CC-FILEBASE\$/([^"]+)"');
        for (final entry
            in archiveContents.entries.where((e) => e.key.endsWith('.html'))) {
          for (final match in tokenRegex.allMatches(entry.value)) {
            final pathInZip = 'web_resources/${match.group(1)}';
            expect(archiveContents.containsKey(pathInZip), isTrue,
                reason:
                    '${entry.key} references \$IMS-CC-FILEBASE\$/${match.group(1)} '
                    'but no file exists at $pathInZip in the cartridge');
          }
        }
      },
    );

    test('assignment HTML body is non-empty for every assignment', () {
      // Smoke check: each assignment dir contains an HTML file with real
      // markdown-rendered body content (not just the empty <html><body>
      // envelope).
      final assignmentDirs = archiveContents.keys
          .where((k) => RegExp(r'^g[0-9a-f]{32}/').hasMatch(k))
          .map((k) => k.split('/').first)
          .toSet()
          .where((dir) {
            // Only count dirs that have an assignment_settings.xml — the
            // course-settings bundle has a different shape.
            return archiveContents.containsKey('$dir/assignment_settings.xml');
          })
          .toList();

      expect(assignmentDirs, isNotEmpty,
          reason: 'expected at least one assignment dir');

      for (final dir in assignmentDirs) {
        final htmlFiles = archiveContents.keys
            .where((k) => k.startsWith('$dir/') && k.endsWith('.html'))
            .toList();
        expect(htmlFiles.length, 1,
            reason: '$dir should contain exactly one HTML body file');

        final body = archiveContents[htmlFiles.single]!;
        // Strip the boilerplate envelope and check for real content.
        final bodyContent = RegExp(r'<body>(.*)</body>', dotAll: true)
            .firstMatch(body)
            ?.group(1)
            ?.trim();
        expect(bodyContent, isNotNull,
            reason: '$dir HTML has no <body> section');
        expect(bodyContent!.length, greaterThan(20),
            reason: '$dir HTML body is suspiciously short (${bodyContent.length} '
                'chars) — markdown rendering may have produced an empty body');
      }
    });
  });
}


/// Cross-link rewriting gets its own fixture and its own build, so the
/// minimal_course fixture stays minimal -- other tests assert exact page and
/// module counts against it.
void cheatsheetLinkInvariants() {
  group('cheat sheet cross-link invariants', () {
    late final Map<String, String> contents;

    setUpAll(() {
      final out = File('${Directory.systemTemp.path}/cheatsheet_links.imscc');
      if (out.existsSync()) out.deleteSync();
      packageCourse(loadCourse('test/fixtures/cheatsheet_course'), out.path);
      contents = {};
      for (final f in ZipDecoder().decodeBytes(out.readAsBytesSync()).files) {
        if (f.isFile) {
          contents[f.name] = String.fromCharCodes(f.content as List<int>);
        }
      }
    });

    test('no wiki page body contains an unresolved relative .md link', () {
      // Canvas resolves $WIKI_REFERENCE$/pages/<X> against the manifest IMS
      // identifier. A bare relative href imports as "Missing links found in
      // imported content" and renders dead for students -- with no
      // build-time error. SPEC.md tells authors to write relative links, so
      // the loader must rewrite them.
      final offenders = contents.entries
          .where((e) =>
              e.key.startsWith('wiki_content/') &&
              e.key.endsWith('.html') &&
              RegExp('href="[a-z0-9][a-z0-9-]*[.]md"').hasMatch(e.value))
          .map((e) => e.key)
          .toList();
      expect(offenders, isEmpty,
          reason: 'relative .md links survived into: ${offenders.join(", ")}');
    });

    test('a page-to-page link also resolves, not just cheat sheets', () {
      // The rewriter originally only mapped `<name>.md` to `cheatsheet-<name>`,
      // so a page linking to another page imported as a missing link. Canvas
      // reported exactly one: submission-mechanics -> privacy-policy.
      final other = contents['wiki_content/other.html'];
      expect(other, isNotNull);
      expect(other, contains(r'$WIKI_REFERENCE$/pages/'));
      expect(other, isNot(contains('href="syllabus.md"')));
    });

    test('sibling links become WIKI_REFERENCE tokens present in the manifest',
        () {
      final alpha = contents['wiki_content/cheatsheet-alpha.html'];
      expect(alpha, isNotNull);
      expect(alpha, contains(r'$WIKI_REFERENCE$/pages/'));

      final manifest = contents['imsmanifest.xml']!;
      final targets =
          RegExp(r'WIKI_REFERENCE\$/pages/(g[a-f0-9]+)').allMatches(alpha!);
      expect(targets, isNotEmpty);
      for (final m in targets) {
        expect(manifest, contains('identifier="${m.group(1)}"'),
            reason: 'link target ${m.group(1)} is not declared in the manifest');
      }
    });

    test('an absolute URL ending in .md is left alone', () {
      expect(contents['wiki_content/cheatsheet-alpha.html'],
          contains('https://example.com/x.md'));
    });
  });
}
