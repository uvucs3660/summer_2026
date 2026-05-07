import 'dart:io';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;

/// Render markdown to a Canvas-style HTML page (with <html>/<body>
/// envelope and tables enabled). The result is the body of a Canvas
/// WikiPage or assignment description.
///
/// When [assetsDir] is provided, any markdown image whose `src` is a
/// local relative `.svg` path (e.g. `diagrams/foo.svg`) is replaced by
/// the file's SVG content inlined directly into the HTML. This keeps
/// pages self-contained — no Common Cartridge `web_resources/` step
/// or `$IMS-CC-FILEBASE$` rewriting needed.
String renderMarkdownToCanvasHtml(
  String markdown, {
  String? title,
  String? assetsDir,
}) {
  final body = markdownToHtml(
    markdown,
    extensionSet: ExtensionSet.gitHubFlavored,
    inlineSyntaxes: [],
  );
  final inlined = assetsDir != null ? _inlineLocalSvgs(body, assetsDir) : body;
  final t = title ?? '';
  return '<html>\n<head>\n'
      '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>\n'
      '<title>$t</title>\n'
      '</head>\n<body>\n$inlined\n</body>\n</html>';
}

/// Replace `<img src="<local>.svg" alt="...">` tags with the SVG file's
/// contents inlined. External URLs, data URIs, and `$IMS-CC-FILEBASE$`
/// references are left untouched.
String _inlineLocalSvgs(String html, String assetsDir) {
  // Match <img src="..." alt="..."> with alt optional and self-closing optional.
  // The markdown package's output is consistent enough that this regex covers
  // every image it produces; if a future renderer change adds attribute order
  // variation, expand or replace with package:html.
  final imgRegex = RegExp(
    r'<img\s+src="([^"]+)"(?:\s+alt="([^"]*)")?\s*/?>',
  );
  return html.replaceAllMapped(imgRegex, (match) {
    final src = match.group(1)!;
    final alt = match.group(2) ?? '';

    if (!src.toLowerCase().endsWith('.svg')) return match.group(0)!;
    if (src.startsWith('http://') ||
        src.startsWith('https://') ||
        src.startsWith('data:') ||
        src.startsWith(r'$')) {
      return match.group(0)!;
    }

    final svgPath = p.join(assetsDir, src);
    final svgFile = File(svgPath);
    if (!svgFile.existsSync()) return match.group(0)!;

    var svgContent = svgFile.readAsStringSync();
    // Strip any leading XML declaration or BOM that would be invalid in HTML.
    svgContent = svgContent.replaceFirst(
      RegExp(r'^\s*<\?xml[^>]*\?>\s*'),
      '',
    );

    // Add role + aria-label to the opening <svg> tag for accessibility.
    if (alt.isNotEmpty) {
      svgContent = svgContent.replaceFirst(
        RegExp(r'<svg\b'),
        '<svg role="img" aria-label="${_escapeAttr(alt)}"',
      );
    }

    return svgContent.trim();
  });
}

String _escapeAttr(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;');
