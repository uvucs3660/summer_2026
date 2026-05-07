import 'package:course_builder/src/loaders/frontmatter.dart';
import 'package:test/test.dart';

void main() {
  group('parseFrontmatter', () {
    test('parses YAML frontmatter and returns the body', () {
      const md = '''---
slug: w01-intro
week: 1
companion_sheets:
  - cheatsheet-agile-v2
  - cheatsheet-perfect-framework
---
# Week 1

Hello, world.
''';
      final fm = parseFrontmatter(md);
      expect(fm.data['slug'], 'w01-intro');
      expect(fm.data['week'], 1);
      expect((fm.data['companion_sheets'] as List).length, 2);
      expect(fm.body, contains('# Week 1'));
      expect(fm.body, contains('Hello, world.'));
    });

    test('returns empty data when no frontmatter is present', () {
      const md = '# Just markdown\n\nNo frontmatter.';
      final fm = parseFrontmatter(md);
      expect(fm.data, isEmpty);
      expect(fm.body, equals(md));
    });

    test('treats missing closing delimiter as no frontmatter', () {
      const md = '---\nslug: x\nstill no closing\n# Body';
      final fm = parseFrontmatter(md);
      expect(fm.data, isEmpty);
      expect(fm.body, equals(md));
    });

    test('handles empty frontmatter block', () {
      const md = '---\n---\n# Body';
      final fm = parseFrontmatter(md);
      expect(fm.data, isEmpty);
      expect(fm.body, contains('# Body'));
    });
  });
}
