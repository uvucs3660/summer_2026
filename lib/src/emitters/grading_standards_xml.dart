import 'package:xml/xml.dart';
import '../ims_id.dart';

const _scale =
    '[["A",0.93],["A-",0.9],["B+",0.87],["B",0.83],["B-",0.8],'
    '["C+",0.77],["C",0.73],["C-",0.7],["D+",0.67],["D",0.63],'
    '["D-",0.62],["F",0.0]]';

String emitGradingStandardsXml() {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('gradingStandards', namespaces: {
    'http://canvas.instructure.com/xsd/cccv1p0': '',
  }, nest: () {
    b.element('gradingStandard', attributes: {
      'identifier': imsId('grading-standard:default'),
      'version': '2',
    }, nest: () {
      b.element('title', nest: 'Standard Letter Scale');
      b.element('data', nest: _scale);
      b.element('points_based', nest: 'false');
      b.element('scaling_factor', nest: '1.0');
    });
  });
  return b.buildDocument().toXmlString(pretty: true);
}
