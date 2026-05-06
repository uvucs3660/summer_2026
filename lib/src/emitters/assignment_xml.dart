import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/assignment.dart';

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
      b.element('rubric_id_ref', nest: imsId('rubric:${a.rubricSlug}'));
    }
    b.element('workflow_state', nest: 'published');
  });
  return b.buildDocument().toXmlString(pretty: true);
}
