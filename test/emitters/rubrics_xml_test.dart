import 'package:course_builder/src/emitters/rubrics_xml.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('rubrics.xml lists each rubric with criteria and ratings', () {
    final c = loadCourse('test/fixtures/minimal_course');
    final doc = XmlDocument.parse(emitRubricsXml(c));
    expect(doc.findAllElements('rubric').length, 1);
    expect(doc.findAllElements('criterion').length, 1);
    expect(doc.findAllElements('rating').length, 2);
  });
}
