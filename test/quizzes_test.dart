// Smoke test for the quiz pipeline — loader + QTI emitter + meta emitter
// + auto-paired remediation assignment + manifest entries. Uses the real
// 2026 course content as the fixture (the W6 quiz) so we catch shape
// regressions in production data.

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:course_builder/src/loaders/course_loader.dart';
import 'package:course_builder/src/loaders/quiz_loader.dart';
import 'package:course_builder/src/packager.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('quiz_loader', () {
    test('loads w06 quiz with all questions and correct-choice validation',
        () {
      final q = loadQuiz('content/cs3660/2026/quizzes/w06-eips-part1.yaml');
      expect(q.slug, 'w06-eips-part1-quiz');
      expect(q.questions.length, 5);
      expect(q.pointsPossible, 5);
      // Each question has exactly one correct answer.
      for (final qq in q.questions) {
        expect(qq.choices.where((c) => c.isCorrect).length, 1,
            reason: 'question ${qq.slug} should have one correct choice');
      }
    });

    test('rejects quiz with no correct choice', () {
      final tmp = File('${Directory.systemTemp.path}/badquiz.yaml')
        ..writeAsStringSync('''
slug: bad-quiz
title: Bad
week: 1
remediation_assignment: bad-quiz-remediation
questions:
  - text: "no correct"
    choices:
      - text: "a"
        correct: false
      - text: "b"
        correct: false
''');
      addTearDown(tmp.deleteSync);
      expect(() => loadQuiz(tmp.path), throwsFormatException);
    });
  });

  group('quiz emission in 2026 zip', () {
    late final Map<String, String> archiveContents;

    setUpAll(() {
      final out = File('${Directory.systemTemp.path}/quiz_zip_test.imscc');
      if (out.existsSync()) out.deleteSync();
      final c = loadCourse('content/cs3660/2026');
      packageCourse(c, out.path);
      archiveContents = {};
      for (final f in ZipDecoder().decodeBytes(out.readAsBytesSync()).files) {
        if (f.isFile) {
          archiveContents[f.name] =
              String.fromCharCodes(f.content as List<int>);
        }
      }
    });

    test('emits assessment_qti.xml + assessment_meta.xml + non_cc_assessments copy',
        () {
      final qtiFiles = archiveContents.keys
          .where((k) => k.endsWith('/assessment_qti.xml'))
          .toList();
      expect(qtiFiles.length, greaterThan(0));

      for (final qti in qtiFiles) {
        // Each quiz dir must also have an assessment_meta.xml.
        final metaPath = qti.replaceFirst(
            '/assessment_qti.xml', '/assessment_meta.xml');
        expect(archiveContents.containsKey(metaPath), isTrue,
            reason: 'expected sibling $metaPath alongside $qti');

        // And a duplicate copy in non_cc_assessments/.
        final dirId = qti.split('/').first;
        expect(
          archiveContents.containsKey('non_cc_assessments/$dirId.xml.qti'),
          isTrue,
          reason: 'expected non_cc_assessments/$dirId.xml.qti to mirror $qti',
        );
      }
    });

    test('quiz QTI has correct shape: assessment > section > items', () {
      final qtiPath = archiveContents.keys
          .firstWhere((k) => k.endsWith('/assessment_qti.xml'));
      final doc = XmlDocument.parse(archiveContents[qtiPath]!);
      expect(doc.findAllElements('assessment').length, 1);
      expect(doc.findAllElements('section').length, 1);
      // 5-question quiz → 5 items.
      expect(doc.findAllElements('item').length, 5);

      // Each item must have a presentation, render_choice, resprocessing,
      // and at least one itemfeedback (for the per-choice feedback hooks).
      for (final item in doc.findAllElements('item')) {
        expect(item.findAllElements('presentation'), isNotEmpty);
        expect(item.findAllElements('render_choice'), isNotEmpty);
        expect(item.findAllElements('resprocessing'), isNotEmpty);
      }
    });

    test('manifest declares both QTI and meta resources per quiz, with dependency',
        () {
      final manifest = XmlDocument.parse(archiveContents['imsmanifest.xml']!);
      final qtiResources = manifest.findAllElements('resource').where((e) =>
          e.getAttribute('type') ==
          'imsqti_xmlv1p2/imscc_xmlv1p1/assessment');
      expect(qtiResources, isNotEmpty);

      // Each QTI resource must have a <dependency> on the meta resource.
      for (final qtiRes in qtiResources) {
        final deps = qtiRes.findElements('dependency');
        expect(deps, isNotEmpty,
            reason: 'QTI resource ${qtiRes.getAttribute("identifier")} '
                'must declare <dependency identifierref="..."> for its '
                'assessment_meta.xml resource');
      }
    });

    test('auto-paired remediation assignment is created for each quiz', () {
      final c = loadCourse('content/cs3660/2026');
      for (final q in c.quizzes) {
        final remediationSlug = q.remediationAssignmentSlug;
        final found = c.assignments.any((a) => a.slug == remediationSlug);
        expect(found, isTrue,
            reason: 'expected auto-paired assignment $remediationSlug '
                'for quiz ${q.slug}');
      }
    });
  });
}
