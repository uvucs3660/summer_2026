import 'dart:convert';
import 'dart:io';

import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';

/// Spelled-out ordinal day words, longest/most-specific alternative first so
/// the hyphenated twenties and thirties never get shadowed by a shorter
/// alternative earlier in the list. Repeated verbatim (rather than composed
/// with `+`) inside each pattern below, since string interpolation cannot
/// reach into a raw string literal and `+`-composing a raw regex risks
/// silently losing an escape.
const _ordinal = r'(?:thirty-first|thirtieth|twenty-ninth|twenty-eighth|'
    r'twenty-seventh|twenty-sixth|twenty-fifth|twenty-fourth|twenty-third|'
    r'twenty-second|twenty-first|twentieth|nineteenth|eighteenth|'
    r'seventeenth|sixteenth|fifteenth|fourteenth|thirteenth|twelfth|'
    r'eleventh|tenth|ninth|eighth|seventh|sixth|fifth|fourth|third|second|'
    r'first)';

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
  // Spelled-out dates -- the corpus's dominant idiom for deadlines ("due
  // October fifth", "due on the twenty-first", "due Sunday the nineteenth").
  // Case-insensitive: a sentence-initial "October" and a mid-sentence
  // "october" are the same token.
  RegExp(
    '\\b(?:January|February|March|April|May|June|July|August|September|'
        'October|November|December)\\s+$_ordinal\\b',
    caseSensitive: false,
  ),
  // "the <ordinal-word>" alone is the corpus's single noisiest shape --
  // measured at 33 real dates against 99 ordinary spoken-lecture-prose hits
  // ("the first thing you'll notice", "the second one is the one that
  // matters") across all 28 decks. An alarm that fires on nearly every
  // slide teaches the reviewer to wave it through, which erases the
  // protection for the real 33. Only count it as a date token when BOTH:
  // (a) a date-signal word (due/deadline/by/on/before/submit/ship) appears
  // within the ~40 characters before the phrase, and (b) the ordinal is not
  // immediately followed by a lowercase word -- real spoken deadlines end
  // the phrase ("due Sunday the nineteenth."); prose continues into a noun
  // ("the first thing", "on the first pass").
  RegExp(
    '(?<=(?:due|deadline|by|on|before|submit|ship)\\b.{0,40})'
        '\\bthe\\s+$_ordinal\\b(?!\\s*[a-z])',
    caseSensitive: false,
    dotAll: true,
  ),
  RegExp(
    '\\b(?:Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)\\s+'
        'the\\s+$_ordinal\\b',
    caseSensitive: false,
  ),
  // Cheap classes not seen in the corpus today but unprotected if a rewrite
  // introduces them.
  RegExp(r'\b\d{4}-\d{2}-\d{2}\b'), // ISO date, e.g. 2026-09-21
  RegExp(r'\b\d{1,2}:\d{2}\s*[APap][Mm]\b'), // clock time, e.g. 11:59pm
  RegExp(r'\b\d+\s+points?\b', caseSensitive: false), // point value
  RegExp(r'\b\d+(?:\.\d+)?%'), // percentage
];

class RewriteReport {
  final bool slideCountChanged;
  final List<int> unscriptedSlides;
  final List<String> bodyChanges;
  final List<String> missingTokens;
  final List<String> inventedTokens;
  final int beforeWords;
  final int afterWords;

  RewriteReport({
    required this.slideCountChanged,
    required this.unscriptedSlides,
    required this.bodyChanges,
    required this.missingTokens,
    required this.inventedTokens,
    required this.beforeWords,
    required this.afterWords,
  });

  bool get ok =>
      !slideCountChanged &&
      unscriptedSlides.isEmpty &&
      bodyChanges.isEmpty &&
      missingTokens.isEmpty &&
      inventedTokens.isEmpty;

  int get deltaPercent =>
      beforeWords == 0 ? 0 : (((afterWords - beforeWords) / beforeWords) * 100).round();

  @override
  String toString() {
    final b = StringBuffer();
    if (slideCountChanged) b.writeln('  SLIDE COUNT CHANGED');
    for (final s in unscriptedSlides) b.writeln('  slide $s has no script');
    for (final c in bodyChanges) b.writeln('  $c');
    for (final t in missingTokens) b.writeln('  missing verbatim token: "$t"');
    for (final t in inventedTokens) {
      b.writeln('  invented verbatim token: "$t" (not present in original -- check for fabrication)');
    }
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
  final invented = <String>[];

  if (!countChanged) {
    for (var i = 0; i < before.slides.length; i++) {
      final b = before.slides[i];
      final a = after.slides[i];

      if (_bodyOf(b) != _bodyOf(a)) {
        bodyChanges.add('slide ${a.index}: body changed (only NOTES may be edited)');
      }
      if (a.script.trim().isEmpty) unscripted.add(a.index);

      // Dropped: every verbatim token in the original script must still be
      // present in the rewrite, character-for-character.
      for (final t in _tokensIn(b.script)) {
        if (!a.script.contains(t)) missing.add(t);
      }
      // Invented: the check must also run in reverse, or a rewrite can slip
      // in a date/deadline/URL that was never in the original -- a
      // fabrication just as dangerous as a dropped one, and a one-directional
      // check cannot see it.
      for (final t in _tokensIn(a.script)) {
        if (!b.script.contains(t)) invented.add(t);
      }
    }
  }

  return RewriteReport(
    slideCountChanged: countChanged,
    unscriptedSlides: unscripted,
    bodyChanges: bodyChanges,
    missingTokens: missing,
    inventedTokens: invented,
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
