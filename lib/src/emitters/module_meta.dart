import 'package:xml/xml.dart';
import '../ims_id.dart';
import '../models/course.dart';
import '../models/module_item.dart';

String emitModuleMeta(Course c) {
  final b = XmlBuilder();
  b.processing('xml', 'version="1.0" encoding="UTF-8"');
  b.element('modules', namespaces: {
    'http://canvas.instructure.com/xsd/cccv1p0': '',
  }, nest: () {
    int modulePos = 1;
    for (final m in c.modules) {
      b.element('module',
          attributes: {'identifier': imsId('module:${m.slug}')}, nest: () {
        b.element('title', nest: m.title);
        b.element('workflow_state',
            nest: m.published ? 'active' : 'unpublished');
        b.element('position', nest: '${modulePos++}');
        b.element('require_sequential_progress', nest: 'false');
        b.element('locked', nest: 'false');
        b.element('items', nest: () {
          int itemPos = 1;
          for (final it in m.items) {
            b.element('item',
                attributes: {'identifier': imsId('module-item:${m.slug}:${itemPos}')},
                nest: () {
              switch (it.kind) {
                case ModuleItemKind.assignment:
                  b.element('content_type', nest: 'Assignment');
                  b.element('workflow_state', nest: 'active');
                  b.element('title', nest: ''); // populated by Canvas at import
                  b.element('identifierref',
                      nest: imsId('assignment:${it.referenceSlug}'));
                  break;
                case ModuleItemKind.wikiPage:
                  b.element('content_type', nest: 'WikiPage');
                  b.element('workflow_state', nest: 'active');
                  b.element('title', nest: '');
                  b.element('identifierref',
                      nest: imsId('page:${it.referenceSlug}'));
                  break;
                case ModuleItemKind.subHeader:
                  b.element('content_type', nest: 'ContextModuleSubHeader');
                  b.element('workflow_state', nest: 'active');
                  b.element('title', nest: it.subHeaderTitle ?? '');
                  break;
                case ModuleItemKind.externalUrl:
                  b.element('content_type', nest: 'ExternalUrl');
                  b.element('workflow_state', nest: 'active');
                  b.element('title', nest: it.externalUrlTitle ?? '');
                  b.element('url', nest: it.externalUrl ?? '');
                  break;
              }
              b.element('position', nest: '${itemPos}');
              b.element('indent', nest: '${it.indent}');
              itemPos++;
            });
          }
        });
      });
    }
  });
  return b.buildDocument().toXmlString(pretty: true);
}
