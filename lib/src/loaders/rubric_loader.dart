import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/rubric.dart';

Rubric loadRubric(String path) {
  final raw = File(path).readAsStringSync();
  final doc = loadYaml(raw) as Map;
  final criteria = (doc['criteria'] as List).map((c) {
    final ratings = (c['ratings'] as List).map((r) {
      return RubricRating(
        description: r['description'] as String,
        points: r['points'] as num,
      );
    }).toList();
    return RubricCriterion(
      slug: c['slug'] as String,
      description: c['description'] as String,
      ratings: ratings,
    );
  }).toList();
  return Rubric(
    slug: doc['slug'] as String,
    title: doc['title'] as String,
    criteria: criteria,
  );
}
