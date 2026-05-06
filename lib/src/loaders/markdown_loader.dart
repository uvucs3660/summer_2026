import 'package:markdown/markdown.dart';

/// Render markdown to a Canvas-style HTML page (with <html>/<body>
/// envelope and tables enabled). The result is the body of a Canvas
/// WikiPage or assignment description.
String renderMarkdownToCanvasHtml(String markdown, {String? title}) {
  final body = markdownToHtml(
    markdown,
    extensionSet: ExtensionSet.gitHubFlavored,
    inlineSyntaxes: [],
  );
  final t = title ?? '';
  return '<html>\n<head>\n'
      '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>\n'
      '<title>$t</title>\n'
      '</head>\n<body>\n$body\n</body>\n</html>';
}
