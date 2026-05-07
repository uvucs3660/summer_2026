import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';

import 'emitters/assignment_groups.dart';
import 'emitters/assignment_xml.dart';
import 'emitters/context_xml.dart';
import 'emitters/course_settings.dart';
import 'emitters/grading_standards_xml.dart';
import 'emitters/imsmanifest.dart';
import 'emitters/late_policy_xml.dart';
import 'emitters/module_meta.dart';
import 'emitters/rubrics_xml.dart';
import 'ims_id.dart';
import 'models/course.dart';

/// Build all Canvas Common Cartridge files for [c] and write a zip to
/// [outputPath]. Zip contents follow the structure observed in
/// `cs-3660-001-_-2025-summer-full-term-export/`.
void packageCourse(Course c, String outputPath) {
  final archive = Archive();

  void addFile(String path, String content) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  // Top-level manifest
  addFile('imsmanifest.xml', emitImsManifest(c));

  // Course settings bundle
  addFile('course_settings/canvas_export.txt',
      'Q: What did the panda say when he was forced out of his natural habitat?\n'
      'A: This is un-BEAR-able\n');
  addFile('course_settings/context.xml', emitContextXml(c));
  addFile('course_settings/course_settings.xml', emitCourseSettings(c));
  addFile('course_settings/assignment_groups.xml', emitAssignmentGroups(c));
  addFile('course_settings/module_meta.xml', emitModuleMeta(c));
  addFile('course_settings/rubrics.xml', emitRubricsXml(c));
  addFile('course_settings/late_policy.xml', emitLatePolicyXml(c));
  addFile('course_settings/grading_standards.xml',
      emitGradingStandardsXml());
  // Syllabus is rendered as a wiki page below; stub here for compatibility.
  addFile('course_settings/syllabus.html',
      '<html><body><p>See Syllabus page in modules.</p></body></html>');

  // Wiki pages
  for (final p in c.wikiPages) {
    addFile('wiki_content/${p.slug}.html', p.htmlBody);
  }

  // Assignments — each gets its own dir g<id>/
  for (final a in c.assignments) {
    final id = imsId('assignment:${a.slug}');
    addFile('$id/${a.slug}.html', a.htmlBody);
    addFile('$id/assignment_settings.xml',
        emitAssignmentSettingsXml(a));
  }

  // Web resources — files referenced from HTML via $IMS-CC-FILEBASE$.
  // Read each as bytes so binary formats (PDF, PNG) survive intact; text
  // files (SVG, HTML) round-trip correctly via UTF-8 too.
  for (final wr in c.webResources) {
    final bytes = File(wr.srcPath).readAsBytesSync();
    archive.addFile(
      ArchiveFile('web_resources/${wr.zipPath}', bytes.length, bytes),
    );
  }

  // Write zip
  final out = File(outputPath);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(ZipEncoder().encode(archive)!);
}
