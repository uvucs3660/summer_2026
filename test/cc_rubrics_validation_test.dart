import 'dart:io';

import 'package:course_builder/src/loaders/rubric_loader.dart';
import 'package:test/test.dart';

void main() {
  for (final slug in const [
    'cc-artifact-1-skill',
    'cc-artifact-2-subagent',
    'cc-artifact-3-hook',
    'cc-artifact-4-mcp',
    'cc-artifact-5-plugin',
  ]) {
    test('$slug rubric parses and sums to 60', () {
      final r = loadRubric('content/cs3660/2026/rubrics/$slug.yaml');
      expect(r.slug, slug);
      expect(r.totalPoints, 60, reason: '$slug should total 60');
    });
  }

  group('cs3540 rubrics', () {
    final dir = Directory('content/cs3540/2026/rubrics');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    test('there is at least one', () => expect(files, isNotEmpty));

    for (final f in files) {
      final stem = f.uri.pathSegments.last.replaceAll('.yaml', '');
      test('$stem is well formed', () {
        final r = loadRubric(f.path);

        // The grader keys rubrics by filename in a flat directory shared
        // with CS 3660 and throws if the slug field disagrees with the stem.
        expect(r.slug, stem, reason: 'slug must equal the filename stem');
        expect(stem.startsWith('cs3540-'), isTrue,
            reason: 'CS 3540 slugs are prefixed to keep the shared namespace unique');

        expect(r.criteria, isNotEmpty);
        for (final c in r.criteria) {
          expect(c.ratings.length, greaterThanOrEqualTo(2),
              reason: '${c.slug} needs at least two ratings');
          expect(c.ratings.map((x) => x.points), contains(0),
              reason: '${c.slug} has no zero-point rating, so it has no failing case');
        }

        final expected = stem == 'cs3540-pass-fail' ? 1 : 100;
        expect(r.totalPoints, expected,
            reason: '$stem should total $expected');
      });
    }
  });
}
