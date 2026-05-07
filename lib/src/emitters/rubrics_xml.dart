import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

/// Emit the course-wide rubrics.xml in the format Canvas's CC importer
/// expects. The structure mirrors the 2025 export's rubrics.xml exactly:
///
/// - Criteria are wrapped in `<criteria>` (not `<data>`).
/// - Each `<criterion>` carries its identifier as a `<criterion_id>`
///   child element (not as an `identifier=` attribute).
/// - Each `<rating>` includes `<id>` (Canvas-internal rating id),
///   `<criterion_id>` (back-reference to its parent criterion), and
///   `<long_description>` (may be empty but the element should exist).
///
/// Canvas's CC export will strip rubric ↔ assignment associations on
/// round-trip; the IMPORTER reads `<rubric_id>` from `assignment_settings.xml`
/// — see assignment_xml.dart.
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
        b.element('read_only', nest: 'false');
        b.element('title', nest: r.title);
        b.element('reusable', nest: 'true');
        b.element('public', nest: 'false');
        b.element('points_possible', nest: r.totalPoints.toString());
        b.element('hide_score_total', nest: 'false');
        b.element('free_form_criterion_comments', nest: 'true');
        b.element('criteria', nest: () {
          for (final crit in r.criteria) {
            final criterionId = imsId('criterion:${r.slug}:${crit.slug}');
            b.element('criterion', nest: () {
              b.element('criterion_id', nest: criterionId);
              b.element('points', nest: crit.maxPoints.toString());
              b.element('description', nest: crit.description);
              b.element('long_description', nest: '');
              b.element('ratings', nest: () {
                for (var i = 0; i < crit.ratings.length; i++) {
                  final rt = crit.ratings[i];
                  b.element('rating', nest: () {
                    b.element('description', nest: rt.description);
                    b.element('points', nest: rt.points.toString());
                    b.element('criterion_id', nest: criterionId);
                    b.element('long_description', nest: '');
                    b.element('id',
                        nest: imsId('rating:${r.slug}:${crit.slug}:$i'));
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
