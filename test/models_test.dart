import 'package:course_builder/src/models/course.dart';
import 'package:course_builder/src/models/late_policy.dart';
import 'package:course_builder/src/models/rubric.dart';
import 'package:test/test.dart';

void main() {
  test('Course can be constructed with empty collections', () {
    final c = Course(
      title: 'Test',
      courseCode: 'CS-TEST',
      startAt: DateTime(2026, 5, 5),
      endAt: DateTime(2026, 8, 7),
      gradingScheme: 'letter',
      latePolicy: const LatePolicy(dailyDeductionPercent: 10, floorPercent: 50),
      assignmentGroups: const [],
      assignments: const [],
      wikiPages: const [],
      modules: const [],
      rubrics: const [],
      frontPageSlug: 'syllabus',
    );
    expect(c.title, 'Test');
  });

  test('Rubric.totalPoints sums max-rating per criterion', () {
    final r = Rubric(
      slug: 'r1',
      title: 'Test',
      criteria: [
        RubricCriterion(
          slug: 'a',
          description: 'A',
          ratings: const [
            RubricRating(description: 'good', points: 10),
            RubricRating(description: 'ok', points: 5),
          ],
        ),
        RubricCriterion(
          slug: 'b',
          description: 'B',
          ratings: const [
            RubricRating(description: 'good', points: 20),
          ],
        ),
      ],
    );
    expect(r.totalPoints, 30);
  });
}
