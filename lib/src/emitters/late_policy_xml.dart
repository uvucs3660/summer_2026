import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

String emitLatePolicyXml(Course c) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('late_policy',
      attributes: {'identifier': imsId('late-policy:default')},
      namespaces: {'http://canvas.instructure.com/xsd/cccv1p0': ''},
      nest: () {
    b.element('missing_submission_deduction_enabled', nest: 'false');
    b.element('missing_submission_deduction', nest: '0.0');
    b.element('late_submission_deduction_enabled', nest: 'true');
    b.element('late_submission_deduction',
        nest: '${c.latePolicy.dailyDeductionPercent}.0');
    b.element('late_submission_interval', nest: 'day');
    b.element('late_submission_minimum_percent_enabled', nest: 'true');
    b.element('late_submission_minimum_percent',
        nest: '${c.latePolicy.floorPercent}.0');
  });
  return b.buildDocument().toXmlString(pretty: true);
}
