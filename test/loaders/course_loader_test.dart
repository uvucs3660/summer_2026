import 'package:course_builder/src/ims_id.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';

void main() {
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
  group('cheat sheet sibling cross-links', () {
    // SPEC.md section 8 instructs authors to cross-link cheat sheets with
    // relative links, because those work on GitHub and in IDE preview.
    // Canvas cannot resolve them: its CC importer matches
    // $WIKI_REFERENCE$/pages/<X> against the manifest IMS identifier, and a
    // bare relative path produces "Missing links found in imported content".
    // So the loader rewrites them at render time.
    test('rewrites a sibling .md link to a WIKI_REFERENCE token', () {
      final html = rewriteCheatsheetLinks(
        '<a href="theory-of-fun.md">fun</a>',
      );
      expect(html, contains(r'$WIKI_REFERENCE$/pages/'));
      expect(html, contains(imsId('page:cheatsheet-theory-of-fun')));
      expect(html, isNot(contains('theory-of-fun.md')));
    });

    test('leaves external links alone', () {
      const href = '<a href="https://example.com/a.md">x</a>';
      expect(rewriteCheatsheetLinks(href), href);
    });

    test('leaves diagram image paths alone', () {
      const img = '<img src="diagrams/theory-of-fun-bracket.svg" alt="x"/>';
      expect(rewriteCheatsheetLinks(img), img);
    });

    test('rewrites every occurrence, not just the first', () {
      final html = rewriteCheatsheetLinks(
        '<a href="a-one.md">1</a> and <a href="b-two.md">2</a>',
      );
      expect(html, contains(imsId('page:cheatsheet-a-one')));
      expect(html, contains(imsId('page:cheatsheet-b-two')));
      expect(html.contains('.md"'), isFalse);
    });
  });
}
