import 'dart:convert';
import 'dart:io';
import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';

void main() {
  const path = 'test/fixtures/decks/fenced-deck.md';
  final json = lectureToJson(loadDeck(path), deckPath: path);
  validateLecture(json);
  File('test/fixtures/decks/fenced-deck.golden.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln('golden written and validated');
}
