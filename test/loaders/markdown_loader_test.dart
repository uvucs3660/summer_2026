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

    test('inlines SVG <style> rules as style attributes on matching elements',
        () {
      // Regression: Canvas's HTML sanitizer strips <style> tags from
      // imported content (even inside <svg>), so class-based SVG styling
      // is silently lost. The renderer must convert <style> rules into
      // `style="..."` attributes on each element with a matching class
      // before the <svg> reaches Canvas.
      final tmp = Directory.systemTemp.createTempSync('svg_style_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final dgDir = Directory('${tmp.path}/diagrams')..createSync();
      File('${dgDir.path}/styled.svg').writeAsStringSync('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <style>
    .node { fill: #1f2937; stroke: #60a5fa; }
    .leaf { fill: #34d399; }
    .label, .badge { font-weight: 600; }
  </style>
  <rect class="node" x="10" y="10" width="80" height="40" />
  <circle class="leaf node" cx="50" cy="80" r="10" />
  <text class="label">hi</text>
  <text class="unstyled">no rule</text>
</svg>
''');
      File('${tmp.path}/styled.md').writeAsStringSync(
        '![](diagrams/styled.svg)',
      );

      final html = renderMarkdownToCanvasHtml(
        File('${tmp.path}/styled.md').readAsStringSync(),
        assetsDir: tmp.path,
      );

      // <style> block must be removed from the rendered HTML — Canvas
      // would strip it anyway, so leaving it in is misleading.
      expect(html, isNot(contains('<style')),
          reason:
              '<style> blocks must be inlined and removed before Canvas import');

      // Each class-based element must have a style="..." with the right
      // declarations.
      expect(html, contains('class="node"'));
      expect(html, contains('fill: #1f2937'));
      expect(html, contains('stroke: #60a5fa'));

      // Multi-class element gets declarations from both classes.
      expect(html, contains('class="leaf node"'));

      // Comma-separated selector applies to both classes.
      expect(html, contains('font-weight: 600'));

      // Unstyled element gets no `style="..."` injection.
      expect(html, contains('class="unstyled"'));
    });
  });
}
