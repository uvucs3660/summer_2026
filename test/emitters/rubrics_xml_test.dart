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

  test('rubrics.xml uses Canvas-compatible <criteria> wrapper, '
      '<criterion_id> child elements, and per-rating <id>', () {
    // Regression: matches the format in the 2025 export. Our previous
    // format used <data><criterion identifier=> which Canvas's CC importer
    // does not understand for rubric attachment.
    final c = loadCourse('test/fixtures/minimal_course');
    final doc = XmlDocument.parse(emitRubricsXml(c));

    // <criteria> wrapper, not <data>.
    expect(doc.findAllElements('criteria'), isNotEmpty);
    expect(doc.findAllElements('data'), isEmpty);

    // Each <criterion> has <criterion_id> as a child element (no
    // identifier= attribute).
    for (final crit in doc.findAllElements('criterion')) {
      final id = crit.findElements('criterion_id');
      expect(id, isNotEmpty,
          reason: '<criterion> must have a <criterion_id> child');
      expect(crit.getAttribute('identifier'), isNull,
          reason: 'Canvas does not read identifier= on <criterion>');
    }

    // Each <rating> has <id>, back-references its <criterion_id>, and
    // includes a <long_description> (may be empty).
    for (final rating in doc.findAllElements('rating')) {
      expect(rating.findElements('id'), isNotEmpty,
          reason: '<rating> must have an <id> child');
      expect(rating.findElements('criterion_id'), isNotEmpty,
          reason: '<rating> must have a <criterion_id> back-reference');
      expect(rating.findElements('long_description'), isNotEmpty,
          reason: '<rating> must have a <long_description> child');
    }
  });
}
