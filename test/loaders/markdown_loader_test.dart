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

    test(
      'rewrites local relative img src to \$IMS-CC-FILEBASE\$/<base>/<src> '
      'when assetsDir + webResourceBaseUrl are provided',
      () {
        final md = File('test/fixtures/svg_dir/sample.md').readAsStringSync();
        final html = renderMarkdownToCanvasHtml(
          md,
          assetsDir: 'test/fixtures/svg_dir',
          webResourceBaseUrl: r'$IMS-CC-FILEBASE$/svg_dir',
        );

        // <img> stays an <img>, src rewritten to a Canvas-rooted URL.
        expect(html, contains('<img'));
        expect(
          html,
          contains(r'<img src="$IMS-CC-FILEBASE$/svg_dir/diagrams/test.svg"'),
        );
        // Original relative path is gone.
        expect(html, isNot(contains('src="diagrams/test.svg"')));
        // No SVG inlining — the file's contents must NOT be embedded in HTML.
        expect(html, isNot(contains('<svg')));
      },
    );

    test('leaves external image URLs untouched', () {
      final html = renderMarkdownToCanvasHtml(
        '![](https://example.com/foo.svg)',
        assetsDir: 'test/fixtures/svg_dir',
        webResourceBaseUrl: r'$IMS-CC-FILEBASE$/svg_dir',
      );
      expect(html, contains('<img'));
      expect(html, contains('https://example.com/foo.svg'));
      // Must not double-prefix.
      expect(html, isNot(contains(r'$IMS-CC-FILEBASE$/svg_dir/https')));
    });

    test('leaves missing-file references untouched (graceful)', () {
      final html = renderMarkdownToCanvasHtml(
        '![](diagrams/does-not-exist.svg)',
        assetsDir: 'test/fixtures/svg_dir',
        webResourceBaseUrl: r'$IMS-CC-FILEBASE$/svg_dir',
      );
      expect(html, contains('<img'));
      // Unknown file is left as the original path, not silently rewritten
      // to a Canvas URL that points nowhere.
      expect(html, contains('does-not-exist.svg'));
      expect(
        html,
        isNot(contains(
            r'$IMS-CC-FILEBASE$/svg_dir/diagrams/does-not-exist.svg')),
      );
    });

    test(
      'does not rewrite imgs when webResourceBaseUrl is not provided',
      () {
        final md = File('test/fixtures/svg_dir/sample.md').readAsStringSync();
        final html = renderMarkdownToCanvasHtml(
          md,
          assetsDir: 'test/fixtures/svg_dir',
        );
        // Without webResourceBaseUrl, the <img> stays as the original
        // relative path (and the file is not inlined either).
        expect(html, contains('src="diagrams/test.svg"'));
        expect(html, isNot(contains(r'$IMS-CC-FILEBASE$')));
      },
    );
  });
}
