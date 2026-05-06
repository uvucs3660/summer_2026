import 'package:course_builder/src/emitters/assignment_xml.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('assignment_settings.xml carries title, points, due, group, rubric', () {
    final c = loadCourse('test/fixtures/minimal_course');
    final a = c.assignments.single;
    final doc = XmlDocument.parse(emitAssignmentSettingsXml(a));

    expect(doc.findAllElements('title').single.innerText, 'Test Onboarding 1');
    expect(doc.findAllElements('points_possible').single.innerText, '10');
    expect(doc.findAllElements('grading_type').single.innerText, 'pass_fail');
    expect(doc.findAllElements('submission_types').single.innerText,
        'online_text_entry');
    expect(doc.findAllElements('rubric_id_ref').single.innerText,
        startsWith('g'));
  });
}
