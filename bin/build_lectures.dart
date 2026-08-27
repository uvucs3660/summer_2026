import 'dart:convert';
import 'dart:io';

import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';
import 'package:path/path.dart' as p;

const _encoder = JsonEncoder.withIndent('  ');

String _arg(List<String> a, String flag, String fallback) {
  final i = a.indexOf(flag);
  return i == -1 || i + 1 >= a.length ? fallback : a[i + 1];
}

void main(List<String> args) {
  final slidesDir =
      _arg(args, '--slides-dir', 'content/cs3540/2026/lectures/slides');
  final outDir = _arg(args, '--out', p.join(slidesDir, '_lectures'));
  final course = _arg(args, '--course', 'cs3540');
  final year = int.parse(_arg(args, '--year', '2026'));

  final deckFiles = Directory(slidesDir)
      .listSync()
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.md')
      .where((f) => RegExp(r'^(w\d\d-|fenced-)').hasMatch(p.basename(f.path)))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (deckFiles.isEmpty) {
    stderr.writeln('No decks found in $slidesDir');
    exit(1);
  }

  Directory(outDir).createSync(recursive: true);

  final lectures = <Lecture>[];
  for (final f in deckFiles) {
    final Lecture deck;
    try {
      deck = loadDeck(f.path);
    } catch (e) {
      stderr.writeln('Failed to parse ${f.path}: $e');
      exit(1);
    }

    final doc = lectureToJson(deck, deckPath: f.path);
    try {
      validateLecture(doc);
    } on LectureSchemaException catch (e) {
      stderr.writeln(e);
      exit(1);
    }

    lectures.add(deck);
    File(p.join(outDir, '${deck.id}.json'))
        .writeAsStringSync('${_encoder.convert(doc)}\n');
  }

  File(p.join(outDir, 'lectures.json')).writeAsStringSync(
      '${_encoder.convert(indexToJson(lectures, course: course, year: year))}\n');

  final slides = lectures.fold(0, (s, l) => s + l.slides.length);
  final words = lectures.fold(0, (s, l) => s + l.wordCount);
  stdout.writeln(
      '${lectures.length} lectures, $slides slides, $words words -> $outDir');
}
