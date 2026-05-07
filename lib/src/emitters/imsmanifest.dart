import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';

/// Emit the Common Cartridge top-level imsmanifest.xml as a string.
///
/// Resource type strings use the `imscc_xmlv1p1` namespace because that's
/// what Canvas's Common Cartridge importer is built around — the same
/// strings the 2025 export uses, which we know imports cleanly. Don't
/// switch to `imscc_xsd` (a different IMS spec variant) without reading
/// Canvas's CC importer source first.
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
      // Each assignment becomes a resource pointing at its directory.
      // The `<file>` listing must reference files that actually exist
      // — Canvas validates the file list and will fail to import the
      // body if any listed file is missing.
      for (final a in c.assignments) {
        final id = imsId('assignment:${a.slug}');
        builder.element('resource', attributes: {
          'identifier': id,
          'type':
              'associatedcontent/imscc_xmlv1p1/learning-application-resource',
          'href': '$id/${a.slug}.html',
        }, nest: () {
          builder.element('file',
              attributes: {'href': '$id/${a.slug}.html'});
          builder.element('file',
              attributes: {'href': '$id/assignment_settings.xml'});
        });
      }

      // Each wiki page is a webcontent resource. The HTML file itself
      // must carry Canvas-specific <meta> tags (identifier / editing_roles
      // / workflow_state / front_page) — see markdown_loader.dart's
      // canvasIdentifier parameter. Without those tags Canvas imports the
      // file but does not link it to the manifest identifier, leaving
      // module items with empty bodies.
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

      // Web resources — each non-markdown file under cheatsheets/lectures/
      // dirs gets its own <resource type="webcontent"> entry. Canvas's CC
      // importer copies these into the course's Files area (preserving
      // the directory structure), and `$IMS-CC-FILEBASE$/<zipPath>`
      // references in HTML resolve to those files.
      for (final wr in c.webResources) {
        final id = imsId('webresource:${wr.zipPath}');
        builder.element('resource', attributes: {
          'identifier': id,
          'type': 'webcontent',
          'href': 'web_resources/${wr.zipPath}',
        }, nest: () {
          builder.element('file',
              attributes: {'href': 'web_resources/${wr.zipPath}'});
        });
      }

      // Course settings bundle.
      final csId = imsId('course-settings');
      builder.element('resource', attributes: {
        'identifier': csId,
        'type':
            'associatedcontent/imscc_xmlv1p1/learning-application-resource',
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
