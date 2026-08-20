import 'dart:io';

import 'package:test/test.dart';
import 'package:xml/xml.dart';

/// Structural checks from `cheatsheets/SPEC.md` section 9, plus the shape
/// rules the spec states but never enforced.
///
/// These previously lived in a bash script, which meant they ran when someone
/// remembered. With 39 sheets and 39 diagrams, "when someone remembers" is not
/// a control: a duplicate `class` attribute on one `<rect>` renders fine in a
/// browser, is invalid XML, and Canvas serves web_resources as raw bytes -- so
/// it would have shipped as a broken image on exactly one page.
void main() {
  // Universal checks run on every course. The SHAPE rules -- title form,
  // gotchas, when-you're-stuck, a diagram -- are SPEC.md requirements that
  // CS 3660 predates: 5 of its 41 sheets have a gotchas section. They are
  // enforced where content was authored against them. Bringing CS 3660 up to
  // them is a content job, not a test job, and doing it here would mean
  // either 35 failing tests or a rule weakened for everyone.
  const enforcesShape = {'content/cs3540/2026/cheatsheets'};

  for (final dir in const [
    'content/cs3540/2026/cheatsheets',
    'content/cs3660/2026/cheatsheets',
  ]) {
    final root = Directory(dir);
    if (!root.existsSync()) continue;

    final sheets = root
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .where((f) => !f.path.endsWith('SPEC.md'))
        .where((f) => !f.path.endsWith('CATALOG.md'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final diagramsDir = Directory('$dir/diagrams');
    final svgs = diagramsDir.existsSync()
        ? (diagramsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.svg'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];

    group('cheat sheets — $dir', () {
      test('there is at least one', () => expect(sheets, isNotEmpty));

      for (final f in sheets) {
        final name = f.uri.pathSegments.last;
        final text = f.readAsStringSync();

        if (enforcesShape.contains(dir)) {
          test('$name has the required shape', () {
            expect(text.split('\n').first,
                matches(RegExp(r'^# .+Cheat Sheet \(80/20\)$')),
                reason: 'first line must be the SPEC title form');
            expect(text, contains('\n## Common gotchas'));
            expect(text, contains("\n## When you're stuck"));
            expect(RegExp(r'^!\[', multiLine: true).hasMatch(text), isTrue,
                reason: 'every sheet needs a diagram');
          });
        }

        test('$name references only diagrams that exist', () {
          for (final m
              in RegExp(r'\((diagrams/[a-z0-9-]+\.svg)\)').allMatches(text)) {
            expect(File('$dir/${m.group(1)}').existsSync(), isTrue,
                reason: '$name references missing ${m.group(1)}');
          }
        });
      }

      for (final f in svgs) {
        final name = f.uri.pathSegments.last;

        test('$name is well-formed XML', () {
          expect(
              () => XmlDocument.parse(f.readAsStringSync()), returnsNormally);
        });

        test('$name has no duplicate attributes', () {
          // package:xml ACCEPTS a duplicate attribute; xmllint rejects it, and
          // so does Canvas, which serves web_resources as raw bytes. The bash
          // version of this check used xmllint and caught exactly this bug
          // once already, so parsing alone would be a weaker replacement.
          final doc = XmlDocument.parse(f.readAsStringSync());
          for (final el in doc.descendants.whereType<XmlElement>()) {
            final names = el.attributes.map((a) => a.name.qualified).toList();
            expect(names.toSet().length, names.length,
                reason: '<${el.name.qualified}> in $name repeats an attribute: '
                    '${names.join(" ")}');
          }
        });

        test('$name scales — viewBox, no width/height on the root', () {
          final first = f.readAsLinesSync().first;
          expect(first, contains('<svg'));
          expect(first, contains('viewBox='));
          expect(first, isNot(contains(' width=')));
          expect(first, isNot(contains(' height=')));
        });
      }

      test('no orphan diagrams', () {
        final referenced = <String>{};
        for (final f in sheets) {
          for (final m in RegExp(r'diagrams/([a-z0-9-]+\.svg)')
              .allMatches(f.readAsStringSync())) {
            referenced.add(m.group(1)!);
          }
        }
        final orphans = svgs
            .map((f) => f.uri.pathSegments.last)
            .where((n) => !referenced.contains(n))
            .toList();
        expect(orphans, isEmpty, reason: 'unreferenced: ${orphans.join(", ")}');
      });
    });
  }
}
