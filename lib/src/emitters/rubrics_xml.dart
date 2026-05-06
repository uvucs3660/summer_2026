import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

String emitRubricsXml(Course c) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('rubrics', namespaces: {
    'http://canvas.instructure.com/xsd/cccv1p0': '',
  }, nest: () {
    for (final r in c.rubrics) {
      b.element('rubric', attributes: {
        'identifier': imsId('rubric:${r.slug}'),
      }, nest: () {
        b.element('title', nest: r.title);
        b.element('points_possible', nest: r.totalPoints.toString());
        b.element('reusable', nest: 'true');
        b.element('public', nest: 'false');
        b.element('read_only', nest: 'false');
        b.element('free_form_criterion_comments', nest: 'true');
        b.element('hide_score_total', nest: 'false');
        b.element('data', nest: () {
          for (final crit in r.criteria) {
            b.element('criterion', attributes: {
              'identifier': imsId('criterion:${r.slug}:${crit.slug}'),
            }, nest: () {
              b.element('description', nest: crit.description);
              b.element('points', nest: crit.maxPoints.toString());
              b.element('ratings', nest: () {
                for (final rt in crit.ratings) {
                  b.element('rating', nest: () {
                    b.element('description', nest: rt.description);
                    b.element('points', nest: rt.points.toString());
                  });
                }
              });
            });
          }
        });
      });
    }
  });
  return b.buildDocument().toXmlString(pretty: true);
}
