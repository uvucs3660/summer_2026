import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/assignment.dart';

/// Emit a per-assignment `assignment_settings.xml`. Canvas's CC importer
/// attaches a rubric to the assignment when these four elements are
/// present together:
///
///   <rubric_id>g...</rubric_id>          — must match a <rubric identifier="..."> in rubrics.xml
///   <rubric_use_for_grading>true</...>   — required for the gradebook to score against the rubric
///   <rubric_hide_score_total>false</...>
///   <rubric_hide_points>false</...>
///
/// Canvas's CC EXPORTER does not write these on round-trip (which is why
/// the 2025 export's assignment_settings.xml lacks them); the IMPORTER
/// nonetheless reads them. Confirm by re-importing the generated zip.
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
      b.element('rubric_id', nest: imsId('rubric:${a.rubricSlug}'));
      b.element('rubric_use_for_grading', nest: 'true');
      b.element('rubric_hide_score_total', nest: 'false');
      b.element('rubric_hide_points', nest: 'false');
    }

    b.element('workflow_state', nest: 'published');
  });
  return b.buildDocument().toXmlString(pretty: true);
}
