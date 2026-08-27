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
}
