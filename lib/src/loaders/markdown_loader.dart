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
///
/// For Canvas WikiPages, [canvasIdentifier] must be set to the page's
/// IMS identifier so Canvas links the imported HTML to the right entry
/// in the manifest. Without it, the page imports as an orphan HTML file
/// and module references to it are silently broken. [canvasFrontPage]
/// marks the page as the course front page (only one per course).
/// Assignment HTML bodies do NOT need these — leave [canvasIdentifier]
/// null and Canvas reads metadata from `assignment_settings.xml` instead.
String renderMarkdownToCanvasHtml(
  String markdown, {
  String? title,
  String? assetsDir,
  String? canvasIdentifier,
  bool canvasFrontPage = false,
  String canvasEditingRoles = 'teachers',
  String canvasWorkflowState = 'active',
}) {
  final body = markdownToHtml(
    markdown,
    extensionSet: ExtensionSet.gitHubFlavored,
    inlineSyntaxes: [],
  );
  final inlined = assetsDir != null ? _inlineLocalSvgs(body, assetsDir) : body;
  final t = title ?? '';

  final headMeta = StringBuffer()
    ..write(
      '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>\n',
    )
    ..write('<title>$t</title>\n');

  if (canvasIdentifier != null) {
    headMeta
      ..write('<meta name="identifier" content="$canvasIdentifier"/>\n')
      ..write('<meta name="editing_roles" content="$canvasEditingRoles"/>\n')
      ..write('<meta name="workflow_state" content="$canvasWorkflowState"/>\n');
    if (canvasFrontPage) {
      headMeta.write('<meta name="front_page" content="true"/>\n');
    }
  }

  return '<html>\n<head>\n$headMeta</head>\n<body>\n$inlined\n</body>\n</html>';
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

    // Inline any embedded <style> rules as `style="..."` attributes on
    // matching elements, then remove the <style> block. Canvas's HTML
    // sanitizer strips <style> from imported content (including inside
    // <svg>), so without this every class-based SVG renders unstyled
    // (transparent fills, default strokes — usually invisible).
    svgContent = _inlineSvgClassStyles(svgContent);

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

/// Convert `<style>.foo { fill: red; }</style>` + `<rect class="foo">` into
/// `<rect class="foo" style="fill: red;">` and drop the `<style>` block.
///
/// Handles only what our diagrams actually use: simple `.classname` and
/// comma-separated `.a, .b` selectors with single-line declarations. No
/// pseudo-classes, attribute selectors, or media queries — those don't
/// appear in our SVG library and aren't worth supporting.
String _inlineSvgClassStyles(String svg) {
  final styleMatch = RegExp(
    r'<style[^>]*>(.*?)</style>',
    dotAll: true,
  ).firstMatch(svg);
  if (styleMatch == null) return svg;

  // Parse rules: each rule is `selector(s) { declarations }`. For each
  // class selector found, accumulate the declarations under that class.
  final declarationsByClass = <String, String>{};
  final ruleRegex = RegExp(r'([^{}]+)\{([^{}]*)\}', dotAll: true);
  for (final m in ruleRegex.allMatches(styleMatch.group(1)!)) {
    final selectors = m.group(1)!.split(',').map((s) => s.trim());
    final declarations = m
        .group(2)!
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (declarations.isEmpty) continue;
    for (final sel in selectors) {
      if (!sel.startsWith('.')) continue;
      final cls = sel.substring(1).trim();
      if (cls.isEmpty) continue;
      final existing = declarationsByClass[cls];
      declarationsByClass[cls] = existing == null
          ? declarations
          : '$existing ${declarations.endsWith(";") ? "" : "; "}$declarations';
    }
  }

  // Remove the <style> block.
  var out = svg.replaceFirst(styleMatch.group(0)!, '');

  // For each element with `class="..."`, append a `style="..."` attribute
  // composed from the rules of its classes. Multi-class elements combine
  // declarations from every matching class, in source order.
  out = out.replaceAllMapped(
    RegExp(r'class="([^"]+)"'),
    (match) {
      final classes = match.group(1)!.split(RegExp(r'\s+'));
      final combined = classes
          .map((c) => declarationsByClass[c])
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (combined.isEmpty) return match.group(0)!;
      // Tidy: ensure declarations are well-separated and end with ;
      final tidy = combined.replaceAll(RegExp(r';\s*'), '; ').trim();
      return 'class="${match.group(1)}" style="$tidy"';
    },
  );

  return out;
}

String _escapeAttr(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;');
