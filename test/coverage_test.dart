import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';

/// Cross-artifact coverage.
///
/// Every other test in this suite verifies one artifact against itself: a
/// rubric parses, a page renders, the manifest resolves. None of them noticed
/// that CS 3540 shipped with five of six assignment groups empty -- 92% of the
/// final grade carrying weight with no assignments behind it, and 17 of 19
/// rubrics never referenced. Both states build cleanly and import cleanly.
/// They are only visible by checking the artifacts against each other.
void main() {
  for (final dir in ['content/cs3540/2026', 'content/cs3660/2026']) {
    group('coverage — $dir', () {
      late final course = loadCourse(dir);

      test('every assignment group with weight has at least one assignment', () {
        final counted = <String, int>{};
        for (final a in course.assignments) {
          counted[a.groupSlug] = (counted[a.groupSlug] ?? 0) + 1;
        }
        final empty = course.assignmentGroups
            .where((g) => g.weight > 0 && (counted[g.slug] ?? 0) == 0)
            .map((g) => '${g.slug} (${g.weight}%)')
            .toList();
        expect(empty, isEmpty,
            reason: 'groups carry weight but have no assignments: '
                '${empty.join(", ")} — that weight is unreachable');
      });

      test('assignment group weights sum to 100', () {
        final total =
            course.assignmentGroups.fold<num>(0, (s, g) => s + g.weight);
        expect(total, 100);
      });

      test('every rubric is referenced by at least one assignment', () {
        final used = course.assignments
            .map((a) => a.rubricSlug)
            .whereType<String>()
            .toSet();
        final orphans =
            course.rubrics.map((r) => r.slug).where((s) => !used.contains(s));
        expect(orphans, isEmpty,
            reason: 'rubrics with no assignment never run: '
                '${orphans.join(", ")}');
      });

      test('every assignment names a rubric that exists, or none at all', () {
        final defined = course.rubrics.map((r) => r.slug).toSet();
        final dangling = course.assignments
            .where((a) => a.rubricSlug != null && !defined.contains(a.rubricSlug))
            .map((a) => '${a.slug} -> ${a.rubricSlug}');
        expect(dangling, isEmpty);
      });

      test('every assignment body file exists and is non-trivial', () {
        for (final a in course.assignments) {
          expect(a.htmlBody.length, greaterThan(200),
              reason: '${a.slug} has an almost-empty body');
        }
      });
    });
  }
}

