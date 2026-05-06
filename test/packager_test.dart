import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:course_builder/src/packager.dart';
import 'package:test/test.dart';

void main() {
  test('packageCourse writes a zip containing the manifest and core files',
      () async {
    final c = loadCourse('test/fixtures/minimal_course');
    final outFile = File('${Directory.systemTemp.path}/test_pack.imscc');
    if (outFile.existsSync()) outFile.deleteSync();

    packageCourse(c, outFile.path);
    expect(outFile.existsSync(), isTrue);

    final bytes = outFile.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();

    expect(names, contains('imsmanifest.xml'));
    expect(names, contains('course_settings/course_settings.xml'));
    expect(names, contains('course_settings/module_meta.xml'));
    expect(names, contains('course_settings/assignment_groups.xml'));
    expect(names, contains('course_settings/rubrics.xml'));
    expect(names, contains('course_settings/late_policy.xml'));
    expect(names, contains('course_settings/grading_standards.xml'));
    expect(names, contains('course_settings/context.xml'));
    expect(names.any((n) => n.startsWith('wiki_content/')), isTrue);
    expect(names.any((n) => n.endsWith('.html') && n.startsWith('g')), isTrue);
  });
}
