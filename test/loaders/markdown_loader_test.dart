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

    test('inlines local SVGs when assetsDir is provided', () {
      final md = File('test/fixtures/svg_dir/sample.md').readAsStringSync();
      final html = renderMarkdownToCanvasHtml(
        md,
        assetsDir: 'test/fixtures/svg_dir',
      );

      // The <img> tag is gone, replaced by the inlined <svg>.
      expect(html, isNot(contains('<img')));
      expect(html, contains('<svg'));
      expect(html, contains('viewBox="0 0 100 100"'));
      expect(html, contains('TEST'));
      // Accessibility: alt becomes aria-label.
      expect(html, contains('role="img"'));
      expect(html, contains('aria-label="A test diagram"'));
    });

    test('leaves external image URLs untouched', () {
      final html = renderMarkdownToCanvasHtml(
        '![](https://example.com/foo.svg)',
        assetsDir: 'test/fixtures/svg_dir',
      );
      expect(html, contains('<img'));
      expect(html, contains('https://example.com/foo.svg'));
    });

    test('leaves missing SVG files untouched (graceful)', () {
      final html = renderMarkdownToCanvasHtml(
        '![](diagrams/does-not-exist.svg)',
        assetsDir: 'test/fixtures/svg_dir',
      );
      expect(html, contains('<img'));
      expect(html, contains('does-not-exist.svg'));
    });
  });
}
