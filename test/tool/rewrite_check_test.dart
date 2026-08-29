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
}
