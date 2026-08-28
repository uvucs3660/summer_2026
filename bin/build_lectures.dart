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

/// Posts each lecture's already-written JSON (phase 2 output, `outDir`) to
/// the Java renderer's `/api/lecture/render` endpoint and writes the
/// returned `.pptx` beside the source decks in `slidesDir`. Must only be
/// called after phase 2 has written the JSON -- it reads `outDir/<id>.json`
/// from disk, not from `docs` in memory, so the CLI's actual on-disk state
/// is exactly what gets rendered.
///
/// Fails loudly: a non-200 response writes a clear stderr line naming the
/// deck and the HTTP status, then exits 1. No failure is swallowed or
/// skipped past.
Future<void> renderDecks(
  String baseUrl,
  String outDir,
  List<Lecture> lectures,
  String slidesDir,
) async {
  final client = HttpClient();
  for (final l in lectures) {
    final body = File(p.join(outDir, '${l.id}.json')).readAsStringSync();
    final req = await client.postUrl(Uri.parse('$baseUrl/api/lecture/render'));
    req.headers.contentType = ContentType.json;
    req.write(body);
    final res = await req.close();
    if (res.statusCode != 200) {
      stderr.writeln('render failed for ${l.id}: HTTP ${res.statusCode}');
      exit(1);
    }
    final bytes = await res.fold<List<int>>(<int>[], (b, d) => b..addAll(d));
    File(p.join(slidesDir, '${l.id}.pptx')).writeAsBytesSync(bytes);
    stdout.writeln('rendered ${l.id}.pptx');
  }
  client.close();
}

Future<void> main(List<String> args) async {
  final slidesDir =
      _arg(args, '--slides-dir', 'content/cs3540/2026/lectures/slides');
  final outDir = _arg(args, '--out', p.join(slidesDir, '_lectures'));
  final course = _arg(args, '--course', 'cs3540');

  final yearArg = _arg(args, '--year', '2026');
  final year = int.tryParse(yearArg);
  if (year == null) {
    stderr.writeln('Invalid --year value: "$yearArg" is not an integer');
    exit(1);
  }

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

  // Phase 1: parse and validate every deck before writing anything. A run
  // that fails partway through must leave the filesystem untouched -- never
  // a directory with some decks written and others missing.
  final lectures = <Lecture>[];
  final docs = <Map<String, dynamic>>[];
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
    docs.add(doc);
  }

  // Phase 2: every deck parsed and validated. Replace outDir wholesale so
  // stale per-lecture files (e.g. from a renamed or removed deck) can never
  // linger alongside a fresh index. Only ever clear a directory that looks
  // like our own build output -- refuse if it holds anything unexpected, so
  // a mistaken --out never nukes a real directory.
  final dir = Directory(outDir);
  if (dir.existsSync()) {
    final entries = dir.listSync();
    final hasUnexpectedEntry = entries.any((e) =>
        e is Directory || (e is File && p.extension(e.path) != '.json'));
    if (entries.isNotEmpty && hasUnexpectedEntry) {
      stderr.writeln(
          'Refusing to clear $outDir: it contains files other than .json. '
          'Pass --out pointing at a build directory, not a directory with '
          'real content in it.');
      exit(1);
    }
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);

  for (var i = 0; i < lectures.length; i++) {
    File(p.join(outDir, '${lectures[i].id}.json'))
        .writeAsStringSync('${_encoder.convert(docs[i])}\n');
  }

  File(p.join(outDir, 'lectures.json')).writeAsStringSync(
      '${_encoder.convert(indexToJson(lectures, course: course, year: year))}\n');

  final renderBase = _arg(args, '--render', '');
  if (renderBase.isNotEmpty) {
    await renderDecks(renderBase, outDir, lectures, slidesDir);
  }

  final slides = lectures.fold(0, (s, l) => s + l.slides.length);
  final words = lectures.fold(0, (s, l) => s + l.wordCount);
  stdout.writeln(
      '${lectures.length} lectures, $slides slides, $words words -> $outDir');
}
