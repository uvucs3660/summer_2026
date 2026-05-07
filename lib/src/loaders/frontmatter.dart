import 'package:yaml/yaml.dart';

/// A markdown file's parsed YAML frontmatter and body.
class Frontmatter {
  /// Parsed frontmatter as a map. Empty if no frontmatter block was present.
  final Map<String, dynamic> data;

  /// Markdown body content (everything after the closing `---`, or the whole
  /// file if there was no frontmatter).
  final String body;

  const Frontmatter({required this.data, required this.body});
}

/// Parse YAML frontmatter from a markdown string.
///
/// A frontmatter block is delimited by `---` lines at the very top of the
/// file. If the file does not start with `---`, or the closing delimiter is
/// missing, the whole input is treated as the body and `data` is empty.
Frontmatter parseFrontmatter(String markdown) {
  final lines = markdown.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    return Frontmatter(data: const {}, body: markdown);
  }

  var endLine = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      endLine = i;
      break;
    }
  }
  if (endLine == -1) {
    return Frontmatter(data: const {}, body: markdown);
  }

  final yamlPart = lines.sublist(1, endLine).join('\n');
  final body = lines.sublist(endLine + 1).join('\n');

  final parsed = loadYaml(yamlPart);
  final data = parsed is Map
      ? parsed.map((k, v) => MapEntry(k.toString(), v))
      : <String, dynamic>{};

  return Frontmatter(data: data, body: body);
}
