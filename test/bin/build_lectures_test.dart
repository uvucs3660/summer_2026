import 'dart:convert';
import 'dart:io';
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
}
