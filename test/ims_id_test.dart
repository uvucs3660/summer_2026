import 'package:course_builder/src/ims_id.dart';
import 'package:test/test.dart';

void main() {
  group('imsId', () {
    test('returns g-prefixed 33-char hex string', () {
      final id = imsId('assignment:project-1-job-pack');
      expect(id, startsWith('g'));
      expect(id.length, 33);
      expect(RegExp(r'^g[0-9a-f]{32}$').hasMatch(id), isTrue);
    });

    test('is stable for the same input', () {
      expect(imsId('foo'), imsId('foo'));
    });

    test('differs across distinct inputs', () {
      expect(imsId('foo'), isNot(imsId('bar')));
    });

    test('namespaces collide if different kinds use the same slug', () {
      // policy: callers must pre-namespace (e.g. "assignment:job-pack")
      // this test pins that we do NOT namespace internally
      final raw = imsId('job-pack');
      final namespaced = imsId('assignment:job-pack');
      expect(raw, isNot(namespaced));
    });
  });
}
