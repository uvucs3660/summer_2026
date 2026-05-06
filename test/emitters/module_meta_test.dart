import 'package:course_builder/src/emitters/module_meta.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('module_meta.xml lists each module and its items with refs', () {
    final c = loadCourse('test/fixtures/minimal_course');
    final doc = XmlDocument.parse(emitModuleMeta(c));

    final modules = doc.findAllElements('module').toList();
    expect(modules.length, 1);

    final items = modules.single.findAllElements('item').toList();
    expect(items.length, 2);

    // Items must have identifierref attributes pointing at resources
    final refs = items
        .map((i) => i.findElements('identifierref').single.innerText)
        .toList();
    expect(refs.every((r) => r.startsWith('g')), isTrue);
  });
}
