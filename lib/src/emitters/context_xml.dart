import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

String emitContextXml(Course c) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('context_info',
      attributes: {'identifier': imsId('context:${c.courseCode}')},
      nest: () {
    b.element('course_id',
        nest: imsId('course:${c.courseCode}'));
    b.element('course_name', nest: c.title);
    b.element('course_code', nest: c.courseCode);
  });
  return b.buildDocument().toXmlString(pretty: true);
}
