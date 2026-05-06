import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

String emitAssignmentGroups(Course c) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('assignmentGroups', namespaces: {
    'http://canvas.instructure.com/xsd/cccv1p0': '',
  }, nest: () {
    int pos = 1;
    for (final g in c.assignmentGroups) {
      b.element('assignmentGroup',
          attributes: {'identifier': imsId('group:${g.slug}')},
          nest: () {
        b.element('title', nest: g.title);
        b.element('position', nest: '${pos++}');
        b.element('group_weight', nest: g.weight.toString());
      });
    }
  });
  return b.buildDocument().toXmlString(pretty: true);
}
