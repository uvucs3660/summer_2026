import 'dart:io';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:course_builder/src/packager.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run bin/build_canvas_zip.dart '
        '<content-dir> <output-file>');
    exit(64);
  }
  final contentDir = args[0];
  final outputPath = args[1];

  stderr.writeln('Loading course from $contentDir...');
  final course = loadCourse(contentDir);
  stderr.writeln('Loaded: ${course.title} (${course.courseCode})');
  stderr.writeln('  ${course.assignments.length} assignments, '
      '${course.wikiPages.length} pages, '
      '${course.modules.length} modules, '
      '${course.rubrics.length} rubrics.');

  stderr.writeln('Packaging to $outputPath...');
  packageCourse(course, outputPath);
  stderr.writeln('Done.');
}
