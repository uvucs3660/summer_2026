import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:json_schema/json_schema.dart';

import '../models/lecture.dart';

const String schemaVersion = '1.0.0';
const String defaultSchemaPath = 'schemas/lecture.schema.json';

/// Thrown when a generated document does not conform to the schema. The
/// producer is not allowed to write a document it cannot validate.
class LectureSchemaException implements Exception {
  final String id;
  final List<String> errors;
  LectureSchemaException(this.id, this.errors);
  @override
  String toString() =>
      'Lecture "$id" failed schema validation:\n  ${errors.join('\n  ')}';
}

/// Hash of every slide script in order. Stage 2 compares this against the hash
/// the audio was generated from to decide whether a deck needs re-synthesis.
String scriptHash(Lecture l) {
  final joined = l.slides.map((s) => s.script).join('\n \n');
  return 'sha256:${sha256.convert(utf8.encode(joined))}';
}

Map<String, dynamic> lectureToJson(Lecture l, {required String deckPath}) => {
      'schema_version': schemaVersion,
      'id': l.id,
      'week': l.week,
      'track': l.track,
      'title': l.title,
      if (l.subtitle != null) 'subtitle': l.subtitle,
      'source': {'deck': deckPath, 'script_hash': scriptHash(l)},
      'audio': null,
      'video': {'intro': null, 'outro': null},
      'slides': l.slides.map((s) => s.toJson()).toList(),
    };

Map<String, dynamic> indexToJson(
  List<Lecture> lectures, {
  required String course,
  required int year,
}) {
  final sorted = [...lectures]..sort((a, b) {
      final byWeek = a.week.compareTo(b.week);
      if (byWeek != 0) return byWeek;
      // Game before AI within a week, matching the track table in slides/README.md.
      return a.track == 'game' ? -1 : 1;
    });

  return {
    'schema_version': schemaVersion,
    'course': course,
    'year': year,
    'lectures': sorted
        .map((l) => {
              'id': l.id,
              'week': l.week,
              'track': l.track,
              'title': l.title,
              if (l.subtitle != null) 'subtitle': l.subtitle,
              'slide_count': l.slides.length,
              'word_count': l.wordCount,
              'duration_ms': l.estimatedDurationMs,
              'file': '${l.id}.json',
            })
        .toList(),
  };
}

JsonSchema? _cached;

/// Validate a generated lecture document. Follows the platform pattern in
/// forge_ui/lib/com/fti/io/file_manager.dart:230.
void validateLecture(Map<String, dynamic> doc,
    {String schemaPath = defaultSchemaPath}) {
  _cached ??= JsonSchema.create(
      jsonDecode(File(schemaPath).readAsStringSync()) as Map<String, dynamic>);

  final result = _cached!.validate(doc);
  if (!result.isValid) {
    throw LectureSchemaException(
        doc['id']?.toString() ?? '<unknown>',
        result.errors.map((e) => e.toString()).toList());
  }
}
