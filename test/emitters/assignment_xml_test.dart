import 'package:course_builder/src/emitters/assignment_xml.dart';
import 'package:course_builder/src/emitters/rubrics_xml.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('assignment_settings.xml carries title, points, due, group', () {
    final c = loadCourse('test/fixtures/minimal_course');
    final a = c.assignments.single;
    final doc = XmlDocument.parse(emitAssignmentSettingsXml(a));

    expect(doc.findAllElements('title').single.innerText, 'Test Onboarding 1');
    expect(doc.findAllElements('points_possible').single.innerText, '10');
    expect(doc.findAllElements('grading_type').single.innerText, 'pass_fail');
    expect(doc.findAllElements('submission_types').single.innerText,
        'online_text_entry');
  });

  test('assignment_settings.xml emits Canvas-compatible rubric attachment',
      () {
    // Regression: verifies the four elements Canvas's CC importer needs
    // to actually attach a rubric to an assignment (not just dump it in
    // the rubric library).
    final c = loadCourse('test/fixtures/minimal_course');
    final a = c.assignments.single;
    final doc = XmlDocument.parse(emitAssignmentSettingsXml(a));

    expect(doc.findAllElements('rubric_id').single.innerText, startsWith('g'));
    expect(
      doc.findAllElements('rubric_use_for_grading').single.innerText,
      'true',
    );
    expect(
      doc.findAllElements('rubric_hide_score_total').single.innerText,
      'false',
    );
    expect(
      doc.findAllElements('rubric_hide_points').single.innerText,
      'false',
    );

    // No more <rubric_id_ref> — that was the wrong field name.
    expect(doc.findAllElements('rubric_id_ref'), isEmpty);
  });

  test('rubric_id in assignment_settings matches a rubric in rubrics.xml',
      () {
    // Regression: catches the case where an assignment references a
    // rubric identifier that doesn't actually exist in rubrics.xml
    // (e.g. due to slug → identifier hashing inconsistency).
    final c = loadCourse('test/fixtures/minimal_course');
    final a = c.assignments.single;

    final assignmentDoc = XmlDocument.parse(emitAssignmentSettingsXml(a));
    final rubricsDoc = XmlDocument.parse(emitRubricsXml(c));

    final assignmentRubricId =
        assignmentDoc.findAllElements('rubric_id').single.innerText;
    final rubricIdentifiers = rubricsDoc
        .findAllElements('rubric')
        .map((e) => e.getAttribute('identifier'))
        .whereType<String>()
        .toSet();

    expect(rubricIdentifiers.contains(assignmentRubricId), isTrue,
        reason: 'assignment references rubric_id $assignmentRubricId but '
            'rubrics.xml only declares ${rubricIdentifiers.toList()}');
  });
}
