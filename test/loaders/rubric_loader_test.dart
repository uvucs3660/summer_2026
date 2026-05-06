import 'package:course_builder/src/loaders/rubric_loader.dart';
import 'package:test/test.dart';

void main() {
  test('loadRubric parses YAML into Rubric', () {
    final r = loadRubric('test/fixtures/sample_rubric.yaml');
    expect(r.slug, 'sample-rubric');
    expect(r.title, 'Sample Rubric');
    expect(r.criteria.length, 2);
    expect(r.criteria[0].slug, 'functionality');
    expect(r.criteria[0].ratings.length, 3);
    expect(r.criteria[0].ratings[0].points, 10);
    expect(r.totalPoints, 15);
  });
}
