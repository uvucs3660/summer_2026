import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/assignment.dart';

/// Emit a per-assignment `assignment_settings.xml`.
///
/// The rubric association is carried by `<rubric_identifierref>`, whose value
/// must equal the `identifier` of a `<rubric>` in `course_settings/rubrics.xml`.
/// That element name is not a guess: `cccv1p0.xsd` declares it on
/// `assignmentType`, and canvas-lms both writes it
/// (`lib/cc/assignment_resources.rb`) and reads it
/// (`lib/cc/importer/standard/assignment_converter.rb`).
///
///   <rubric_identifierref>g...</rubric_identifierref>
///   <rubric_use_for_grading>true</rubric_use_for_grading>
///   <rubric_hide_score_total>false</rubric_hide_score_total>
///   <rubric_hide_points>false</rubric_hide_points>
///
/// This previously emitted `<rubric_id>`, which is not in the schema. Canvas
/// drops unknown elements silently, so every rubric imported as a
/// free-floating library and none attached to an assignment — with no error
/// at import time and nothing visible until someone opened SpeedGrader.
///
/// Canvas's own exporter only writes these when a rubric is actually
/// associated, which is why the 2025 reference export has none.
String emitAssignmentSettingsXml(Assignment a) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('assignment',
      attributes: {'identifier': imsId('assignment:${a.slug}')},
      namespaces: {'http://canvas.instructure.com/xsd/cccv1p0': ''},
      nest: () {
    b.element('title', nest: a.title);
    if (a.dueAt != null) {
      b.element('due_at', nest: a.dueAt!.toIso8601String());
    }
    b.element('assignment_group_identifierref',
        nest: imsId('group:${a.groupSlug}'));
    b.element('points_possible', nest: a.pointsPossible.toString());
    b.element('grading_type', nest: a.gradingType);
    b.element('submission_types', nest: a.submissionTypes.join(','));

    if (a.rubricSlug != null) {
      b.element('rubric_identifierref',
          nest: imsId('rubric:${a.rubricSlug}'));
      b.element('rubric_use_for_grading', nest: 'true');
      b.element('rubric_hide_score_total', nest: 'false');
      b.element('rubric_hide_points', nest: 'false');
    }

    b.element('workflow_state', nest: 'published');
  });
  return b.buildDocument().toXmlString(pretty: true);
}
