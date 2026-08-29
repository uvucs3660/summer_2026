import 'package:test/test.dart';
import '../../tool/rewrite_check.dart';

void main() {
  const before = 'test/fixtures/decks/rewrite-before.md';

  test('a faithful rewrite passes', () {
    final r = compareDecks(before, 'test/fixtures/decks/rewrite-after-ok.md');
    expect(r.ok, isTrue, reason: r.toString());
    expect(r.slideCountChanged, isFalse);
    expect(r.unscriptedSlides, isEmpty);
    expect(r.bodyChanges, isEmpty);
    expect(r.missingTokens, isEmpty);
    expect(r.afterWords, greaterThan(r.beforeWords));
  });

  test('a dropped deadline and URL are caught', () {
    final r = compareDecks(before, 'test/fixtures/decks/rewrite-after-bad.md');
    expect(r.ok, isFalse);
    expect(r.missingTokens, contains('Sun Sep 21'));
    expect(r.missingTokens, contains('https://example.com/x'));
  });

  test('an edited slide body is caught', () {
    final r = compareDecks(before, 'test/fixtures/decks/rewrite-after-bad.md');
    expect(r.bodyChanges, isNotEmpty);
    expect(r.bodyChanges.first, contains('slide 1'));
  });

  test('a spelled-out date changing (October fifth -> October ninth) is caught', () {
    final r = compareDecks(
      'test/fixtures/decks/rewrite-spelled-date-before.md',
      'test/fixtures/decks/rewrite-spelled-date-after.md',
    );
    expect(r.ok, isFalse, reason: r.toString());
    expect(r.missingTokens, contains('October fifth'));
  });

  test('an invented token not present in the original is caught', () {
    final r = compareDecks(
      before,
      'test/fixtures/decks/rewrite-invented-after.md',
    );
    expect(r.ok, isFalse, reason: r.toString());
    expect(r.missingTokens, isEmpty, reason: 'the original token survived');
    expect(r.inventedTokens, contains('Sun Sep 28'));
  });

  test('a real "the <ordinal>" deadline changing is still caught', () {
    final r = compareDecks(
      'test/fixtures/decks/rewrite-weekday-ordinal-before.md',
      'test/fixtures/decks/rewrite-weekday-ordinal-after.md',
    );
    expect(r.ok, isFalse, reason: r.toString());
    expect(r.missingTokens, contains('Sunday the nineteenth'));
  });

  test('a prose ordinal rephrase is not falsely flagged', () {
    // "The first thing you'll notice" rephrased away entirely (no date-signal
    // word nearby) must not be treated as a dropped verbatim token -- this is
    // the false-positive the un-narrowed "the <ordinal>" pattern produced on
    // ordinary spoken-lecture prose (measured at 99 hits across the real
    // corpus against 33 real dates).
    final r = compareDecks(
      'test/fixtures/decks/rewrite-prose-ordinal-before.md',
      'test/fixtures/decks/rewrite-prose-ordinal-after.md',
    );
    expect(r.ok, isTrue, reason: r.toString());
    expect(r.missingTokens, isEmpty);
  });
}
