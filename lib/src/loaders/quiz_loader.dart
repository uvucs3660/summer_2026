import 'dart:io';
import 'package:yaml/yaml.dart';

import '../models/quiz.dart';

/// Parse a quiz YAML file into a [Quiz] model. The YAML schema is:
///
/// ```yaml
/// slug: w06-eips-quiz
/// title: "Week 6 — EIPs Part 1 Comprehension Quiz"
/// week: 6
/// group: lectures               # optional, defaults to 'lectures'
/// allowed_attempts: -1          # optional, default 1; -1 = unlimited
/// scoring_policy: keep_highest  # optional, default keep_highest
/// due_at: "2026-06-15T05:59:59" # optional
/// remediation_assignment: w06-quiz-remediation  # the paired assignment slug
/// description_html: |
///   <p>5 questions...</p>
/// questions:
///   - text: "Which EIP describes one-sender-many-receivers?"
///     points: 1
///     choices:
///       - text: "Point-to-Point Channel"
///         correct: false
///         feedback: "P2P is one-to-one. See cheatsheet-eips-part1."
///         cheatsheet: cheatsheet-eips-part1
///       - text: "Publish-Subscribe Channel"
///         correct: true
///         feedback: "Correct."
/// ```
Quiz loadQuiz(String path) {
  final raw = File(path).readAsStringSync();
  final doc = loadYaml(raw) as Map;

  final slug = doc['slug'] as String;
  final questions = (doc['questions'] as List).asMap().entries.map((entry) {
    final i = entry.key;
    final q = entry.value as Map;
    return QuizQuestion(
      slug: q['slug'] as String? ?? '$slug-q${i + 1}',
      textHtml: q['text'] as String,
      points: (q['points'] as num?) ?? 1,
      choices: (q['choices'] as List).map((c) {
        return QuizChoice(
          text: c['text'] as String,
          isCorrect: c['correct'] as bool? ?? false,
          feedback: c['feedback'] as String? ?? '',
          cheatsheetSlug: c['cheatsheet'] as String?,
        );
      }).toList(),
    );
  }).toList();

  // Validate: each question must have exactly one correct choice.
  for (final q in questions) {
    final correctCount = q.choices.where((c) => c.isCorrect).length;
    if (correctCount != 1) {
      throw FormatException(
        'Quiz "$slug" question "${q.slug}" must have exactly one '
        'correct: true choice (found $correctCount).',
      );
    }
  }

  return Quiz(
    slug: slug,
    title: doc['title'] as String,
    week: doc['week'] as int? ?? 0,
    groupSlug: doc['group'] as String? ?? 'lectures',
    descriptionHtml: doc['description_html'] as String? ?? '',
    allowedAttempts: doc['allowed_attempts'] as int? ?? 1,
    scoringPolicy: doc['scoring_policy'] as String? ?? 'keep_highest',
    dueAt: doc['due_at'] != null ? DateTime.parse(doc['due_at'] as String) : null,
    remediationAssignmentSlug:
        doc['remediation_assignment'] as String? ?? '$slug-remediation',
    questions: questions,
  );
}
