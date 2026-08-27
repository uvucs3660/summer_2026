import 'package:course_builder/src/models/lecture.dart';
import 'package:test/test.dart';

void main() {
  test('BulletsBlock serialises depth and raw inline markers', () {
    final b = BulletsBlock([
      BulletItem(depth: 0, text: 'The frontmatter is the **contract**'),
      BulletItem(depth: 1, text: 'See [the spec](https://example.com/s)'),
    ]);
    expect(b.toJson(), {
      'type': 'bullets',
      'items': [
        {'depth': 0, 'text': 'The frontmatter is the **contract**'},
        {'depth': 1, 'text': 'See [the spec](https://example.com/s)'},
      ],
    });
  });

  test('CodeBlock keeps lang and lines verbatim', () {
    final b = CodeBlock('yaml', ['name: open-pr', 'description: Use when...']);
    expect(b.toJson(), {
      'type': 'code',
      'lang': 'yaml',
      'lines': ['name: open-pr', 'description: Use when...'],
    });
  });

  test('Slide emits links and omits empty ones', () {
    final withLinks = Slide(
      index: 1, heading: null, blocks: const [], script: 'x',
      links: [LinkRef(text: 'the spec', url: 'https://example.com/s')],
    );
    expect(withLinks.toJson()['links'], [
      {'text': 'the spec', 'url': 'https://example.com/s'}
    ]);

    final none = Slide(
      index: 2, heading: null, blocks: const [], script: 'y', links: const [],
    );
    expect(none.toJson().containsKey('links'), isFalse);
  });

  test('Lecture word count sums slide scripts and estimates at 140 wpm', () {
    final l = Lecture(
      id: 'w03-ai-skills', week: 3, track: 'ai', title: 'Skills', subtitle: null,
      slides: [
        Slide(index: 1, heading: null, blocks: const [], script: 'one two three', links: const []),
        Slide(index: 2, heading: 'H', blocks: const [], script: 'four five', links: const []),
      ],
    );
    expect(l.wordCount, 5);
    expect(l.estimatedDurationMs, (5 / 140 * 60 * 1000).round());
  });

  test('Prose-bearing blocks expose text via linkSource', () {
    final title = TitleBlock('The title **text**');
    expect(title.linkSource, 'The title **text**');

    final subtitle = SubtitleBlock('See [the spec](https://example.com)');
    expect(subtitle.linkSource, 'See [the spec](https://example.com)');

    final quote = QuoteBlock('Famous quote with [a link](https://example.com)');
    expect(quote.linkSource, 'Famous quote with [a link](https://example.com)');

    final para = ParaBlock('Paragraph text with **bold** and [links](https://example.com)');
    expect(para.linkSource, 'Paragraph text with **bold** and [links](https://example.com)');
  });

  test('CodeBlock and ImageBlock do NOT expose linkSource', () {
    // CodeBlock with URL in content should NOT expose it
    final code = CodeBlock('yaml', ['homepage: https://example.com/not-a-resource', 'version: 1.0']);
    expect(code.linkSource, '');

    // ImageBlock with URL as src should NOT expose it
    final image = ImageBlock('https://example.com/image.png');
    expect(image.linkSource, '');
  });

  test('BulletsBlock joins ALL item texts in linkSource', () {
    final b = BulletsBlock([
      BulletItem(depth: 0, text: 'Check [docs](https://example.com/docs)'),
      BulletItem(depth: 0, text: 'Visit [repo](https://example.com/repo)'),
      BulletItem(depth: 1, text: 'Read [guide](https://example.com/guide)'),
    ]);
    final linkSource = b.linkSource;
    expect(linkSource.contains('https://example.com/docs'), isTrue);
    expect(linkSource.contains('https://example.com/repo'), isTrue);
    expect(linkSource.contains('https://example.com/guide'), isTrue);
  });

  test('Slide.toJson() omits heading when null', () {
    final withHeading = Slide(
      index: 1, heading: 'Slide Title', blocks: const [], script: 'text', links: const [],
    );
    expect(withHeading.toJson().containsKey('heading'), isTrue);
    expect(withHeading.toJson()['heading'], 'Slide Title');

    final withoutHeading = Slide(
      index: 2, heading: null, blocks: const [], script: 'text', links: const [],
    );
    expect(withoutHeading.toJson().containsKey('heading'), isFalse);
  });
}
