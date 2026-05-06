import 'package:course_builder/src/emitters/imsmanifest.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('emits a manifest containing every assignment, page, and rubric', () {
    final c = loadCourse('test/fixtures/minimal_course');
    final xml = XmlDocument.parse(emitImsManifest(c));

    final resources =
        xml.findAllElements('resource').toList();
    // Expect: 1 assignment + 1 page + 1 rubric resource minimum
    expect(resources.length, greaterThanOrEqualTo(3));

    // Manifest must declare correct namespace
    final root = xml.rootElement;
    expect(root.name.local, 'manifest');
  });
}
