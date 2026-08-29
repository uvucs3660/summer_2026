import 'dart:convert';
import 'dart:io';

import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';
import 'package:path/path.dart' as p;

const _encoder = JsonEncoder.withIndent('  ');

const _knownFlags = {
  '--slides-dir',
  '--out',
  '--course',
  '--year',
  '--render',
};

/// Parses `--flag value` pairs into a map, failing cleanly (stderr one-liner,
/// exit 1, no stack trace -- matching this file's existing clean-failure
/// style, e.g. the `--year` FormatException handling below) on either an
/// unrecognised flag or a recognised flag given with no following value.
/// Previously a missing value silently fell back to the default and an
/// unrecognised flag was silently ignored entirely, so a typo like
/// `--corse cs3660` would silently produce a correct-looking but mislabeled
/// artifact set.
Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  var i = 0;
  while (i < args.length) {
    final flag = args[i];
    if (!_knownFlags.contains(flag)) {
      stderr.writeln('Unrecognized argument: "$flag"');
      exit(1);
    }
    if (i + 1 >= args.length) {
      stderr.writeln('Flag "$flag" requires a value');
      exit(1);
    }
    out[flag] = args[i + 1];
    i += 2;
  }
  return out;
}

String _arg(Map<String, String> a, String flag, String fallback) =>
    a[flag] ?? fallback;

/// Posts each lecture's already-written JSON (phase 2 output, `outDir`) to
/// the Java renderer's `/api/lecture/render` endpoint and writes the
/// returned `.pptx` into `slidesDir/_render_java/` (created if needed). Must
/// only be called after phase 2 has written the JSON -- it reads
/// `outDir/<id>.json` from disk, not from `docs` in memory, so the CLI's
/// actual on-disk state is exactly what gets rendered.
///
/// Deliberately NOT written to `slidesDir/<id>.pptx`: that is the exact path
/// `build_pptx.py` (`src.with_suffix(".pptx")`) writes to, and Python remains
/// the pptx producer -- the Java renderer's output would otherwise silently
/// overwrite the diagram-carrying Python decks in place (both paths are
/// gitignored, so the loss would be invisible until someone opened a deck).
/// `_render_java/` follows the existing `_render/` / `_lectures/`
/// build-output convention so it reads unambiguously as a build artifact.
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
  final renderDir = p.join(slidesDir, '_render_java');
  Directory(renderDir).createSync(recursive: true);

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
    File(p.join(renderDir, '${l.id}.pptx')).writeAsBytesSync(bytes);
    stdout.writeln('rendered ${l.id}.pptx');
  }
  client.close();
}

Future<void> main(List<String> rawArgs) async {
  final args = _parseArgs(rawArgs);

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
