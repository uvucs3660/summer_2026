import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: build_canvas_zip <content-dir> <output-file>');
    exit(64);
  }
  final contentDir = args[0];
  final outputFile = args[1];
  stderr.writeln('TODO: build $outputFile from $contentDir');
  exit(1);
}
