/// A non-markdown file (SVG, PNG, PDF, etc.) that ships in the Canvas
/// cartridge's `web_resources/` directory and is referenced from rendered
/// HTML via `$IMS-CC-FILEBASE$/<zipPath>`.
class WebResource {
  /// Absolute path on disk to the source file.
  final String srcPath;

  /// Path inside the cartridge's `web_resources/` directory (forward-slash
  /// separated). For example, `cheatsheets/diagrams/foo.svg` lands at
  /// `web_resources/cheatsheets/diagrams/foo.svg` in the zip and is
  /// referenced as `$IMS-CC-FILEBASE$/cheatsheets/diagrams/foo.svg`.
  final String zipPath;

  const WebResource({required this.srcPath, required this.zipPath});
}
