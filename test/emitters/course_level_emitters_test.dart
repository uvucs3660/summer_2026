import 'package:course_builder/src/emitters/assignment_groups.dart';
import 'package:course_builder/src/emitters/context_xml.dart';
import 'package:course_builder/src/emitters/course_settings.dart';
import 'package:course_builder/src/emitters/grading_standards_xml.dart';
import 'package:course_builder/src/emitters/late_policy_xml.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  late final c = loadCourse('test/fixtures/minimal_course');

  test('context.xml parses and contains course title', () {
    final doc = XmlDocument.parse(emitContextXml(c));
    expect(doc.findAllElements('course_name').single.innerText, 'Test Course');
  });

  test('course_settings.xml has start_at and weighting_scheme percent', () {
    final doc = XmlDocument.parse(emitCourseSettings(c));
    expect(doc.findAllElements('start_at').single.innerText,
        contains('2026-05-05'));
    expect(doc.findAllElements('group_weighting_scheme').single.innerText,
        'percent');
  });

  test('assignment_groups.xml lists each group with weight', () {
    final doc = XmlDocument.parse(emitAssignmentGroups(c));
    expect(doc.findAllElements('assignmentGroup').length, 1);
    expect(doc.findAllElements('group_weight').single.innerText, '100');
  });

  test('late_policy.xml carries 10/50 settings', () {
    final doc = XmlDocument.parse(emitLatePolicyXml(c));
    expect(doc.findAllElements('late_submission_deduction').single.innerText,
        '10.0');
    expect(
        doc.findAllElements('late_submission_minimum_percent').single.innerText,
        '50.0');
  });

  test('grading_standards.xml carries the letter scale', () {
    final doc = XmlDocument.parse(emitGradingStandardsXml());
    expect(doc.findAllElements('data').single.innerText, contains('"A",0.93'));
  });
}
