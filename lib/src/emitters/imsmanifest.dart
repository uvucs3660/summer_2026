import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

/// Emit the Common Cartridge top-level imsmanifest.xml as a string.
String emitImsManifest(Course c) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('manifest', namespaces: {
    'http://www.imsglobal.org/xsd/imsccv1p3/imscp_v1p1': '',
    'http://www.w3.org/2001/XMLSchema-instance': 'xsi',
    'http://canvas.instructure.com/xsd/cccv1p0': 'lomimscc',
  }, attributes: {
    'identifier': imsId('manifest:${c.courseCode}'),
  }, nest: () {
    builder.element('metadata', nest: () {
      builder.element('schema', nest: 'IMS Common Cartridge');
      builder.element('schemaversion', nest: '1.3.0');
    });

    builder.element('organizations', nest: () {
      builder.element('organization', attributes: {
        'identifier': imsId('org:root'),
        'structure': 'rooted-hierarchy',
      });
    });

    builder.element('resources', nest: () {
      // Each assignment becomes a resource pointing at its directory
      for (final a in c.assignments) {
        final id = imsId('assignment:${a.slug}');
        builder.element('resource', attributes: {
          'identifier': id,
          'type': 'associatedcontent/imscc_xsd/learning-application-resource',
          'href': '$id/${a.slug}.html',
        }, nest: () {
          builder.element('file',
              attributes: {'href': '$id/$id.html'});
          builder.element('file',
              attributes: {'href': '$id/assignment_settings.xml'});
        });
      }

      // Each wiki page is a resource
      for (final p in c.wikiPages) {
        final id = imsId('page:${p.slug}');
        builder.element('resource', attributes: {
          'identifier': id,
          'type': 'webcontent',
          'href': 'wiki_content/${p.slug}.html',
        }, nest: () {
          builder.element('file',
              attributes: {'href': 'wiki_content/${p.slug}.html'});
        });
      }

      // Course settings bundle
      final csId = imsId('course-settings');
      builder.element('resource', attributes: {
        'identifier': csId,
        'type': 'associatedcontent/imscc_xsd/learning-application-resource',
        'href': 'course_settings/canvas_export.txt',
      }, nest: () {
        for (final f in const [
          'course_settings.xml',
          'module_meta.xml',
          'assignment_groups.xml',
          'rubrics.xml',
          'late_policy.xml',
          'grading_standards.xml',
          'context.xml',
          'syllabus.html',
          'canvas_export.txt',
        ]) {
          builder.element('file',
              attributes: {'href': 'course_settings/$f'});
        }
      });
    });
  });

  return builder.buildDocument().toXmlString(pretty: true);
}
