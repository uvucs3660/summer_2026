import 'dart:convert';
import 'dart:io';
import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';
import 'package:test/test.dart';

Lecture _lectureWithScripts(List<String> scripts) => Lecture(
      id: 'probe',
      week: 1,
      track: 'ai',
      title: 'Probe',
      subtitle: null,
      slides: [
        for (var i = 0; i < scripts.length; i++)
          Slide(
            index: i + 1,
            heading: null,
            blocks: const [],
            script: scripts[i],
            links: const [],
          ),
      ],
    );

void main() {
  const path = 'test/fixtures/decks/fenced-deck.md';

  test('lecture JSON matches the golden file', () {
    final actual = lectureToJson(loadDeck(path), deckPath: path);
    final expected = jsonDecode(
        File('test/fixtures/decks/fenced-deck.golden.json').readAsStringSync());
    expect(actual, expected);
  });

  test('generated documents validate against the schema', () {
    final doc = lectureToJson(loadDeck(path), deckPath: path);
    expect(() => validateLecture(doc), returnsNormally);
  });

  test('validation rejects an unknown block type', () {
    final doc = lectureToJson(loadDeck(path), deckPath: path);
    (doc['slides'] as List)[0]['blocks'] = [
      {'type': 'callout', 'text': 'nope'}
    ];
    expect(() => validateLecture(doc), throwsA(isA<LectureSchemaException>()));
  });

  test('script hash is stable and prefixed', () {
    final deck = loadDeck(path);
    final h = scriptHash(deck);
    expect(h, startsWith('sha256:'));
    expect(scriptHash(deck), h);
  });

  test('script hash does not collide across slide-structure boundaries', () {
    // A one-slide script that happens to contain the old join separator
    // literally ("\n \n") must NOT hash the same as a two-slide deck whose
    // scripts concatenate to that same byte sequence. The old
    // `join('\n \n')`-based hash collided here because List.join emits no
    // separator for a single-element list.
    final merged = _lectureWithScripts(['Foo\n \nBar']);
    final split = _lectureWithScripts(['Foo', 'Bar']);
    expect(scriptHash(merged), isNot(equals(scriptHash(split))));
  });

  test('index carries one entry per lecture with estimated duration', () {
    final deck = loadDeck(path);
    final idx = indexToJson([deck], course: 'cs3540', year: 2026);
    expect(idx['schema_version'], '1.0.0');
    expect(idx['course'], 'cs3540');
    final entry = (idx['lectures'] as List).single as Map;
    expect(entry['id'], 'fenced-deck');
    expect(entry['file'], 'fenced-deck.json');
    expect(entry['slide_count'], 3);
    expect(entry['duration_ms'], deck.estimatedDurationMs);
  });
}
