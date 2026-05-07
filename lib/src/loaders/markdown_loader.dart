import 'dart:io';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;

/// Render markdown to a Canvas-style HTML page (with <html>/<body>
/// envelope and tables enabled). The result is the body of a Canvas
/// WikiPage or assignment description.
///
/// **Image handling.** When [assetsDir] AND [webResourceBaseUrl] are both
/// provided, any markdown image whose `src` is a local relative path
/// (e.g. `diagrams/foo.svg`) and exists on disk is rewritten to use
/// Canvas's `$IMS-CC-FILEBASE$` token, e.g. `<img src="$IMS-CC-FILEBASE$/
/// cheatsheets/diagrams/foo.svg">`. The corresponding file must be added
/// to the Canvas cartridge's `web_resources/` directory by the packager
/// (see Course.webResources). Canvas serves files in `web_resources/` as
/// binaries without HTML sanitization, which is the only way to get a
/// `<style>`-block-using SVG to render correctly post-import.
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
  String? webResourceBaseUrl,
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
  final rewritten = (assetsDir != null && webResourceBaseUrl != null)
      ? _rewriteRelativeImgPaths(body, assetsDir, webResourceBaseUrl)
      : body;
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

  return '<html>\n<head>\n$headMeta</head>\n<body>\n$rewritten\n</body>\n</html>';
}

/// Rewrite local-relative `<img src>` paths to use a `$IMS-CC-FILEBASE$`-
/// rooted URL. External URLs, data URIs, and `$IMS-CC-FILEBASE$`-prefixed
/// references are left alone. Files that don't exist on disk are also
/// left alone (graceful degradation — the missing-file noise is caught
/// by the build script's verification step, not by silently producing a
/// broken `<img>`).
String _rewriteRelativeImgPaths(
  String html,
  String assetsDir,
  String webResourceBaseUrl,
) {
  final imgRegex = RegExp(
    r'<img\s+src="([^"]+)"((?:\s+[a-z-]+="[^"]*")*)\s*/?>',
  );
  return html.replaceAllMapped(imgRegex, (match) {
    final src = match.group(1)!;
    final otherAttrs = match.group(2) ?? '';

    if (src.startsWith('http://') ||
        src.startsWith('https://') ||
        src.startsWith('data:') ||
        src.startsWith(r'$')) {
      return match.group(0)!;
    }

    final fullPath = p.join(assetsDir, src);
    if (!File(fullPath).existsSync()) {
      return match.group(0)!;
    }

    // Canonicalize the URL with forward slashes (zip paths are POSIX).
    final newSrc = '$webResourceBaseUrl/${src.replaceAll('\\', '/')}';
    return '<img src="$newSrc"$otherAttrs/>';
  });
}
