import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('CLI emits a validated index and one file per deck', () async {
    final tmp = Directory.systemTemp.createTempSync('lectures_cli');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = await Process.run('dart', [
      'run', 'bin/build_lectures.dart',
      '--slides-dir', 'test/fixtures/decks',
      '--out', tmp.path,
      '--course', 'cs3540',
      '--year', '2026',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());

    final index = jsonDecode(File('${tmp.path}/lectures.json').readAsStringSync());
    expect(index['course'], 'cs3540');
    expect((index['lectures'] as List).length, 1);
    expect(File('${tmp.path}/fenced-deck.json').existsSync(), isTrue);
  });

  test('exits 1 and writes nothing when frontmatter is missing week',
      () async {
    final decksDir =
        Directory.systemTemp.createTempSync('lectures_cli_decks_missing_week');
    addTearDown(() => decksDir.deleteSync(recursive: true));
    final outDir =
        Directory.systemTemp.createTempSync('lectures_cli_out_missing_week');
    addTearDown(() => outDir.deleteSync(recursive: true));

    File(p.join(decksDir.path, 'w01-bad-deck.md')).writeAsStringSync('''
---
track: ai
title: Missing Week
---

# Opening

- A point

NOTES:
Opening script.
''');

    final result = await Process.run('dart', [
      'run', 'bin/build_lectures.dart',
      '--slides-dir', decksDir.path,
      '--out', outDir.path,
      '--course', 'cs3540',
      '--year', '2026',
    ]);

    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('w01-bad-deck.md'));
    expect(outDir.listSync(), isEmpty);
  });

  test('exits 1 and writes nothing when a deck has zero slides', () async {
    final decksDir =
        Directory.systemTemp.createTempSync('lectures_cli_decks_empty');
    addTearDown(() => decksDir.deleteSync(recursive: true));
    final outDir =
        Directory.systemTemp.createTempSync('lectures_cli_out_empty');
    addTearDown(() => outDir.deleteSync(recursive: true));

    File(p.join(decksDir.path, 'w01-empty-deck.md')).writeAsStringSync('''
---
track: ai
week: 1
title: Empty Deck
---
''');

    final result = await Process.run('dart', [
      'run', 'bin/build_lectures.dart',
      '--slides-dir', decksDir.path,
      '--out', outDir.path,
      '--course', 'cs3540',
      '--year', '2026',
    ]);

    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('w01-empty-deck'));
    expect(outDir.listSync(), isEmpty);
  });

  test('exits 1 on a non-integer --year instead of crashing', () async {
    final result = await Process.run('dart', [
      'run', 'bin/build_lectures.dart',
      '--slides-dir', 'test/fixtures/decks',
      '--out', Directory.systemTemp.createTempSync('lectures_cli_year').path,
      '--course', 'cs3540',
      '--year', 'notanumber',
    ]);

    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('notanumber'));
    expect(result.stderr.toString(), isNot(contains('Unhandled exception')));
  });
}
