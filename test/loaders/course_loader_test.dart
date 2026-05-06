import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';

void main() {
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
