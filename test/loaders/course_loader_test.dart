import 'package:course_builder/src/ims_id.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';

void main() {
  pageToPageLinks();
  pageImages();
  imagesDirSupport();
  cheatsheetCrossLinks();
  test('loadCourse parses minimal_course fixture', () {
    final c = loadCourse('test/fixtures/minimal_course');
    expect(c.title, 'Test Course');
    expect(c.courseCode, 'TEST-001');
    expect(c.startAt, DateTime(2026, 5, 5));
    expect(c.assignmentGroups.length, 1);
    expect(c.assignments.length, 1);
    expect(c.wikiPages.length, 1);
    expect(c.modules.length, 1);
    expect(c.rubrics.length, 1);
    expect(c.frontPageSlug, 'syllabus');

    expect(c.assignments[0].htmlBody, contains('Test Onboarding 1'));
    expect(c.wikiPages[0].htmlBody, contains('Welcome to the test course'));
    expect(c.modules[0].items.length, 2);
  });
}

void cheatsheetCrossLinks() {
  group('relative markdown link rewriting', () {
    // Every page slug in a small course, for the resolver to match against.
    const slugs = {'cheatsheet-theory-of-fun', 'cheatsheet-a-one',
        'cheatsheet-b-two', 'privacy-policy', 'syllabus'};

    // SPEC.md section 8 instructs authors to cross-link cheat sheets with
    // relative links, because those work on GitHub and in IDE preview.
    // Canvas cannot resolve them: its CC importer matches
    // $WIKI_REFERENCE$/pages/<X> against the manifest IMS identifier, and a
    // bare relative path produces "Missing links found in imported content".
    // So the loader rewrites them at render time.
    test('rewrites a sibling .md link to a WIKI_REFERENCE token', () {
      final html = rewriteRelativeMarkdownLinks(
        '<a href="theory-of-fun.md">fun</a>', slugs);
      expect(html, contains(r'$WIKI_REFERENCE$/pages/'));
      expect(html, contains(imsId('page:cheatsheet-theory-of-fun')));
      expect(html, isNot(contains('theory-of-fun.md')));
    });

    test('resolves a page slug directly, not as a cheat sheet', () {
      final html = rewriteRelativeMarkdownLinks(
          '<a href="privacy-policy.md">p</a>', slugs);
      expect(html, contains(imsId('page:privacy-policy')));
      expect(html, isNot(contains(imsId('page:cheatsheet-privacy-policy'))));
    });

    test('leaves an unresolvable target alone rather than dangling it', () {
      // A visibly relative link is easier to diagnose than a plausible
      // WIKI_REFERENCE pointing at an identifier that is not in the manifest.
      const href = '<a href="nonexistent.md">x</a>';
      expect(rewriteRelativeMarkdownLinks(href, slugs), href);
    });

    test('leaves external links alone', () {
      const href = '<a href="https://example.com/a.md">x</a>';
      expect(rewriteRelativeMarkdownLinks(href, slugs), href);
    });

    test('leaves diagram image paths alone', () {
      const img = '<img src="diagrams/theory-of-fun-bracket.svg" alt="x"/>';
      expect(rewriteRelativeMarkdownLinks(img, slugs), img);
    });

    test('rewrites every occurrence, not just the first', () {
      final html = rewriteRelativeMarkdownLinks(
        '<a href="a-one.md">1</a> and <a href="b-two.md">2</a>', slugs);
      expect(html, contains(imsId('page:cheatsheet-a-one')));
      expect(html, contains(imsId('page:cheatsheet-b-two')));
      expect(html.contains('.md"'), isFalse);
    });
  });
}

void imagesDirSupport() {
  group('images_dir', () {
    // Pages get an assetsDir but no webResourceBaseUrl, so an image
    // referenced from a page rendered as a broken link. CS 3660 has no page
    // images, so this path was never exercised. images_dir ships them as
    // web_resources, where Canvas serves them as raw bytes without
    // sanitizing.
    test('files under images_dir ship as web resources', () {
      final c = loadCourse('test/fixtures/cheatsheet_course');
      final paths = c.webResources.map((r) => r.zipPath).toList();
      expect(paths, contains('images/sample.png'));
    });

    test('markdown files under images_dir are not shipped', () {
      final c = loadCourse('test/fixtures/cheatsheet_course');
      expect(c.webResources.where((r) => r.zipPath.endsWith('.md')), isEmpty);
    });
  });
}

void pageImages() {
  group('page images', () {
    test('a page image is rewritten to the IMS-CC-FILEBASE token', () {
      // Pages were rendered with assetsDir but no webResourceBaseUrl, so an
      // image src stayed a raw relative path and Canvas could not resolve it.
      final c = loadCourse('test/fixtures/cheatsheet_course');
      final page = c.wikiPages.firstWhere((p) => p.slug == 'syllabus');
      expect(page.htmlBody, contains(r'$IMS-CC-FILEBASE$/images/sample.png'));
      expect(page.htmlBody, isNot(contains('src="images/sample.png"')));
    });
  });
}

void pageToPageLinks() {
  group('page-to-page links', () {
    // A page linking to another page with a relative `.md` href imports as
    // "Missing links found in imported content" and renders dead. The
    // cheat-sheet rewriter only mapped siblings to `cheatsheet-<name>`; a page
    // maps to its own slug.
    test('a sibling page link becomes a WIKI_REFERENCE token', () {
      final c = loadCourse('test/fixtures/cheatsheet_course');
      final page = c.wikiPages.firstWhere((p) => p.slug == 'other');
      expect(page.htmlBody, contains(r'$WIKI_REFERENCE$/pages/'));
      expect(page.htmlBody, contains(imsId('page:syllabus')));
      expect(page.htmlBody, isNot(contains('href="syllabus.md"')));
    });

    test('it does not mistake a page link for a cheat sheet', () {
      final c = loadCourse('test/fixtures/cheatsheet_course');
      final page = c.wikiPages.firstWhere((p) => p.slug == 'other');
      expect(page.htmlBody, isNot(contains(imsId('page:cheatsheet-syllabus'))));
    });

    test('a cheat sheet still maps to its cheatsheet- slug', () {
      final c = loadCourse('test/fixtures/cheatsheet_course');
      final sheet = c.wikiPages.firstWhere((p) => p.slug == 'cheatsheet-alpha');
      expect(sheet.htmlBody, contains(imsId('page:cheatsheet-beta')));
    });
  });
}
