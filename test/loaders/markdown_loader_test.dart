import 'dart:io';
import 'package:course_builder/src/loaders/markdown_loader.dart';
import 'package:test/test.dart';

void main() {
  group('renderMarkdownToCanvasHtml', () {
    test('wraps body in <html><body> envelope and converts markdown', () {
      final md = File('test/fixtures/sample.md').readAsStringSync();
      final html = renderMarkdownToCanvasHtml(md);

      expect(html, contains('<html'));
      expect(html, contains('<body'));
      expect(html, contains('<h1>Sample Page</h1>'));
      expect(html, contains('<strong>bold</strong>'));
      expect(html, contains('<em>italic</em>'));
      expect(html, contains('<table'));
    });
  });
}
