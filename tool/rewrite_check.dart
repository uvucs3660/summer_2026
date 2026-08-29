import 'dart:convert';
import 'dart:io';

import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';

/// Tokens that must survive a rewrite verbatim: dates, deadlines, URLs and
/// assignment names. Spec section 4.3 rule 6.
final _tokenPatterns = <RegExp>[
  RegExp(r'https?://[^\s)]+'),
  RegExp(r'\b(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)\s+'
      r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}\b'),
  RegExp(r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}\b'),
  RegExp(r'\bForge\s+\d+\b'),
  RegExp(r'\bSprint\s+\d+\b'),
  RegExp(r'\bWeek\s+\d+\b'),
];

class RewriteReport {
  final bool slideCountChanged;
  final List<int> unscriptedSlides;
  final List<String> bodyChanges;
  final List<String> missingTokens;
  final int beforeWords;
  final int afterWords;

  RewriteReport({
    required this.slideCountChanged,
    required this.unscriptedSlides,
    required this.bodyChanges,
    required this.missingTokens,
    required this.beforeWords,
    required this.afterWords,
  });

  bool get ok =>
      !slideCountChanged &&
      unscriptedSlides.isEmpty &&
      bodyChanges.isEmpty &&
      missingTokens.isEmpty;

  int get deltaPercent =>
      beforeWords == 0 ? 0 : (((afterWords - beforeWords) / beforeWords) * 100).round();

  @override
  String toString() {
    final b = StringBuffer();
    if (slideCountChanged) b.writeln('  SLIDE COUNT CHANGED');
    for (final s in unscriptedSlides) b.writeln('  slide $s has no script');
    for (final c in bodyChanges) b.writeln('  $c');
    for (final t in missingTokens) b.writeln('  missing verbatim token: "$t"');
    b.write('  words $beforeWords -> $afterWords '
        '(${deltaPercent >= 0 ? '+' : ''}$deltaPercent%), '
        'runtime ~${(afterWords / 140).toStringAsFixed(1)} min');
    return b.toString();
  }
}

Set<String> _tokensIn(String text) {
  final found = <String>{};
  for (final p in _tokenPatterns) {
    for (final m in p.allMatches(text)) {
      found.add(m.group(0)!);
    }
  }
  return found;
}

String _bodyOf(Slide s) =>
    jsonEncode(s.blocks.map((b) => b.toJson()).toList());

RewriteReport compareDecks(String beforePath, String afterPath) {
  final before = loadDeck(beforePath);
  final after = loadDeck(afterPath);

  final countChanged = before.slides.length != after.slides.length;
  final bodyChanges = <String>[];
  final unscripted = <int>[];
  final missing = <String>[];

  if (!countChanged) {
    for (var i = 0; i < before.slides.length; i++) {
      final b = before.slides[i];
      final a = after.slides[i];

      if (_bodyOf(b) != _bodyOf(a)) {
        bodyChanges.add('slide ${a.index}: body changed (only NOTES may be edited)');
      }
      if (a.script.trim().isEmpty) unscripted.add(a.index);

      for (final t in _tokensIn(b.script)) {
        if (!a.script.contains(t)) missing.add(t);
      }
    }
  }

  return RewriteReport(
    slideCountChanged: countChanged,
    unscriptedSlides: unscripted,
    bodyChanges: bodyChanges,
    missingTokens: missing,
    beforeWords: before.wordCount,
    afterWords: after.wordCount,
  );
}

/// CLI: compare a deck in the working tree against its committed version.
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/rewrite_check.dart <deck-id>');
    exit(2);
  }
  final id = args.single;
  const dir = 'content/cs3540/2026/lectures/slides';
  final working = '$dir/$id.md';

  if (!File(working).existsSync()) {
    stderr.writeln('no such deck: $working');
    exit(2);
  }

  final show = Process.runSync('git', ['show', 'HEAD:$dir/$id.md']);
  if (show.exitCode != 0) {
    stderr.writeln('could not read committed version of $id: ${show.stderr}');
    exit(2);
  }

  final tmp = File('${Directory.systemTemp.path}/$id.before.md')
    ..writeAsStringSync(show.stdout as String);

  final report = compareDecks(tmp.path, working);
  tmp.deleteSync();

  stdout.writeln('$id:\n$report');
  if (!report.ok) {
    stderr.writeln('REWRITE CHECK FAILED');
    exit(1);
  }
  stdout.writeln('OK');
}
