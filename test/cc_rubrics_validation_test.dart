import 'package:course_builder/src/loaders/rubric_loader.dart';
import 'package:test/test.dart';

void main() {
  for (final slug in const [
    'cc-artifact-1-skill',
    'cc-artifact-2-subagent',
    'cc-artifact-3-hook',
    'cc-artifact-4-mcp',
    'cc-artifact-5-plugin',
  ]) {
    test('$slug rubric parses and sums to 60', () {
      final r = loadRubric('content/cs3660/2026/rubrics/$slug.yaml');
      expect(r.slug, slug);
      expect(r.totalPoints, 60, reason: '$slug should total 60');
    });
  }

  group('cs3540 rubrics', () {
    test('cs3540-pass-fail parses and its slug matches its filename', () {
      final r = loadRubric('content/cs3540/2026/rubrics/cs3540-pass-fail.yaml');
      expect(r.slug, 'cs3540-pass-fail');
      expect(r.criteria, isNotEmpty);
    });
  });
}
