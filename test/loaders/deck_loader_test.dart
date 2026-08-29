import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';
import 'package:test/test.dart';

void main() {
  Lecture deck() => loadDeck('test/fixtures/decks/fenced-deck.md');

  test('a --- inside a fenced block is not a slide break', () {
    expect(deck().slides.length, 3,
        reason: 'naive splitting yields 5 by cutting the YAML fence');
  });

  test('every slide carries its script', () {
    expect(deck().slides.map((s) => s.script).toList(),
        ['Opening script.', 'Second slide script.', 'Third slide script.']);
  });

  test('frontmatter populates metadata and id comes from the filename', () {
    final d = deck();
    expect(d.id, 'fenced-deck');
    expect(d.week, 3);
    expect(d.track, 'ai');
    expect(d.title, 'Skills');
    expect(d.subtitle, 'The Description Is the Product');
  });

  test('slides are indexed from 1 and headings extracted', () {
    final d = deck();
    expect(d.slides.map((s) => s.index).toList(), [1, 2, 3]);
    expect(d.slides.map((s) => s.heading).toList(),
        ['Opening', 'A skill is a folder', 'Closing']);
  });

  test('the fenced slide keeps its code block intact with lang', () {
    final code = deck().slides[1].blocks.whereType<CodeBlock>().single;
    expect(code.lang, 'yaml');
    expect(code.lines.first, '---');
    expect(code.lines, contains('name: open-pr'));
    expect(code.lines.last, '---');
  });

  test('block types cover bullets, quote, image and para', () {
    final d = deck();
    expect(d.slides[0].blocks.whereType<BulletsBlock>().single.items.first.text,
        'First point with **bold**');
    expect(d.slides[2].blocks.whereType<QuoteBlock>().single.text, 'A quote line');
    expect(d.slides[2].blocks.whereType<ImageBlock>().single.src, 'img/x.png');
    expect(d.slides[1].blocks.whereType<ParaBlock>().single.text,
        'The frontmatter is the **contract**.');
  });

  test('links are derived from body text, keeping the raw marker in place', () {
    final slide = deck().slides[0];
    expect(slide.links.length, 1);
    expect(slide.links.single.text, 'the spec');
    expect(slide.links.single.url, 'https://github.com/uvucs3540/engine-spec');
    expect(slide.blocks.whereType<BulletsBlock>().single.items[1].text,
        'See [the spec](https://github.com/uvucs3540/engine-spec)');
  });

  test('URLs inside code blocks and images are not links', () {
    expect(deck().slides[1].links, isEmpty);
    expect(deck().slides[2].links, isEmpty);
  });

  test('extractLinks dedupes repeated URLs, keeping the first link text', () {
    final blocks = [
      ParaBlock('See [first mention](https://example.com/x) for details.'),
      ParaBlock('Also see [second mention](https://example.com/x) again.'),
    ];
    final links = extractLinks(blocks);
    expect(links.length, 1);
    expect(links.single.text, 'first mention');
    expect(links.single.url, 'https://example.com/x');
  });

  test('extractLinks preserves order of first appearance across distinct URLs',
      () {
    final blocks = [
      ParaBlock('First [b](https://example.com/b) then [a](https://example.com/a).'),
      ParaBlock('Then [c](https://example.com/c).'),
    ];
    final links = extractLinks(blocks);
    expect(links.map((l) => l.url).toList(), [
      'https://example.com/b',
      'https://example.com/a',
      'https://example.com/c',
    ]);
  });

  test('an unclosed code fence throws a clear error naming the deck', () {
    const body = '''
# Slide one

Some text.

```js
const x = 1;

---

# Slide two
''';
    expect(
      () => splitSlides(body, deckLabel: 'test-deck.md'),
      throwsA(isA<FormatException>().having(
          (e) => e.message, 'message', contains('test-deck.md'))),
    );
  });
}
