/// Typed model of a parsed lecture deck. Mirrors the block vocabulary the deck
/// markdown actually uses -- do not add types here without changing the schema.

const int wordsPerMinute = 140;

sealed class Block {
  const Block();
  Map<String, dynamic> toJson();

  /// Text this block contributes to link extraction. Code and images contribute
  /// nothing: a URL inside a fenced block is sample data, not a resource.
  String get linkSource => '';
}

class TitleBlock extends Block {
  final String text;
  const TitleBlock(this.text);
  @override
  Map<String, dynamic> toJson() => {'type': 'title', 'text': text};
  @override
  String get linkSource => text;
}

class SubtitleBlock extends Block {
  final String text;
  const SubtitleBlock(this.text);
  @override
  Map<String, dynamic> toJson() => {'type': 'subtitle', 'text': text};
  @override
  String get linkSource => text;
}

class BulletItem {
  final int depth;
  final String text;
  const BulletItem({required this.depth, required this.text});
  Map<String, dynamic> toJson() => {'depth': depth, 'text': text};
}

class BulletsBlock extends Block {
  final List<BulletItem> items;
  const BulletsBlock(this.items);
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'bullets', 'items': items.map((i) => i.toJson()).toList()};
  @override
  String get linkSource => items.map((i) => i.text).join('\n');
}

class CodeBlock extends Block {
  final String lang;
  final List<String> lines;
  const CodeBlock(this.lang, this.lines);
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'code', 'lang': lang, 'lines': lines};
}

class ImageBlock extends Block {
  final String src;
  const ImageBlock(this.src);
  @override
  Map<String, dynamic> toJson() => {'type': 'image', 'src': src};
}

class QuoteBlock extends Block {
  final String text;
  const QuoteBlock(this.text);
  @override
  Map<String, dynamic> toJson() => {'type': 'quote', 'text': text};
  @override
  String get linkSource => text;
}

class ParaBlock extends Block {
  final String text;
  const ParaBlock(this.text);
  @override
  Map<String, dynamic> toJson() => {'type': 'para', 'text': text};
  @override
  String get linkSource => text;
}

/// A resource link surfaced by the player. Derived from inline `[text](url)`
/// markers in slide body text -- never authored separately, so the prose and the
/// resource list cannot disagree.
class LinkRef {
  final String text;
  final String url;
  const LinkRef({required this.text, required this.url});
  Map<String, dynamic> toJson() => {'text': text, 'url': url};
}

class Slide {
  /// 1-based position. Slide identity is positional by design (spec section 2, #7).
  final int index;
  final String? heading;
  final List<Block> blocks;
  final String script;
  final List<LinkRef> links;

  const Slide({
    required this.index,
    required this.heading,
    required this.blocks,
    required this.script,
    required this.links,
  });

  int get wordCount =>
      script.trim().isEmpty ? 0 : script.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toJson() => {
        'index': index,
        if (heading != null) 'heading': heading,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'script': script,
        if (links.isNotEmpty) 'links': links.map((l) => l.toJson()).toList(),
      };
}

class Lecture {
  final String id;
  final int week;
  final String track;
  final String title;
  final String? subtitle;
  final List<Slide> slides;

  const Lecture({
    required this.id,
    required this.week,
    required this.track,
    required this.title,
    required this.subtitle,
    required this.slides,
  });

  int get wordCount => slides.fold(0, (sum, s) => sum + s.wordCount);

  int get estimatedDurationMs =>
      (wordCount / wordsPerMinute * 60 * 1000).round();
}
