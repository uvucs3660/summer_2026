import 'package:course_builder/src/emitters/assignment_xml.dart';
import 'package:course_builder/src/models/assignment.dart';
import 'package:course_builder/src/ims_id.dart';
import 'package:course_builder/src/emitters/rubrics_xml.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  rubricAssociation();
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
    // Regression: verifies the four elements Canvas's CC importer needs to
    // actually attach a rubric to an assignment rather than just dumping it
    // in the rubric library.
    //
    // This test previously asserted `rubric_id`, which is not in cccv1p0.xsd.
    // It therefore pinned the bug in place instead of catching it: Canvas
    // dropped the unknown element silently and no rubric ever attached.
    final c = loadCourse('test/fixtures/minimal_course');
    final a = c.assignments.single;
    final doc = XmlDocument.parse(emitAssignmentSettingsXml(a));

    expect(doc.findAllElements('rubric_identifierref').single.innerText, startsWith('g'));
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

  test('rubric_identifierref in assignment_settings matches a rubric in rubrics.xml',
      () {
    // Regression: catches the case where an assignment references a
    // rubric identifier that doesn't actually exist in rubrics.xml
    // (e.g. due to slug → identifier hashing inconsistency).
    final c = loadCourse('test/fixtures/minimal_course');
    final a = c.assignments.single;

    final assignmentDoc = XmlDocument.parse(emitAssignmentSettingsXml(a));
    final rubricsDoc = XmlDocument.parse(emitRubricsXml(c));

    final assignmentRubricId =
        assignmentDoc.findAllElements('rubric_identifierref').single.innerText;
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

void rubricAssociation() {
  group('rubric association', () {
    final a = Assignment(
      slug: 'demo',
      title: 'Demo',
      htmlBody: '<p>x</p>',
      groupSlug: 'codex',
      pointsPossible: 100,
      submissionTypes: const ['online_url'],
      gradingType: 'points',
      rubricSlug: 'cs3540-devlog',
      dueAt: null,
    );

    test('uses rubric_identifierref, the element the CC schema defines', () {
      // cccv1p0.xsd declares rubric_identifierref on assignmentType, and
      // canvas-lms emits/reads exactly that name. An element Canvas does not
      // know is dropped silently, so a wrong name means the rubric imports
      // as a free-floating library and never attaches to the assignment.
      final xml = emitAssignmentSettingsXml(a);
      expect(xml, contains('<rubric_identifierref>'));
      expect(xml, isNot(contains('<rubric_id>')));
    });

    test('the referenced id matches the rubric identifier in rubrics.xml', () {
      final xml = emitAssignmentSettingsXml(a);
      expect(xml, contains(imsId('rubric:cs3540-devlog')));
    });

    test('declares the association is used for grading', () {
      expect(emitAssignmentSettingsXml(a),
          contains('<rubric_use_for_grading>true</rubric_use_for_grading>'));
    });

    test('omits every rubric element when no rubric is set', () {
      final none = Assignment(
        slug: 'n', title: 'N', htmlBody: '', groupSlug: 'codex',
        pointsPossible: 1, submissionTypes: const ['online_url'],
        gradingType: 'points', rubricSlug: null, dueAt: null,
      );
      expect(emitAssignmentSettingsXml(none), isNot(contains('rubric')));
    });
  });
}
