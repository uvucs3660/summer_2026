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

    test('no inlined SVG carries a <style> block', () {
      // Regression: Canvas's HTML sanitizer strips <style> from imported
      // content (including inside <svg>), so any class-based styling is
      // silently lost on import. The markdown loader must inline <style>
      // rules as style="..." attributes before emission.
      final htmlFiles = archiveContents.entries
          .where((e) => e.key.endsWith('.html'));
      for (final entry in htmlFiles) {
        // Looser check than '<style' so we'd still catch '<style ' or
        // '<style\n'.
        expect(entry.value, isNot(matches(RegExp(r'<style[\s>]'))),
            reason: '${entry.key} contains a <style> block — Canvas will '
                'strip it on import, breaking any class-based SVG styling');
      }
    });

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
