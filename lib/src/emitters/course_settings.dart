import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

String emitCourseSettings(Course c) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('course', namespaces: {
    'http://canvas.instructure.com/xsd/cccv1p0': '',
  }, attributes: {
    'identifier': imsId('course:${c.courseCode}'),
  }, nest: () {
    b.element('title', nest: c.title);
    b.element('course_code', nest: c.courseCode);
    b.element('start_at', nest: c.startAt.toIso8601String());
    b.element('conclude_at', nest: c.endAt.toIso8601String());
    b.element('group_weighting_scheme', nest: 'percent');
    b.element('default_view', nest: 'modules');
    b.element('grading_standard_enabled', nest: 'true');
    b.element('grading_standard_identifier_ref',
        nest: imsId('grading-standard:default'));
    b.element('license', nest: 'private');
    b.element('default_post_policy', nest: () {
      b.element('post_manually', nest: 'false');
    });
  });
  return b.buildDocument().toXmlString(pretty: true);
}
