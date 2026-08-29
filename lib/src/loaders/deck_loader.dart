import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/lecture.dart';
import 'frontmatter.dart';

final _linkPattern = RegExp(r'\[([^\]]+)\]\((https?://[^)\s]+)\)');

/// Split a deck body into slide chunks on a lone `---`.
///
/// A `---` inside a fenced code block is NOT a slide break. Several decks teach
/// YAML frontmatter by showing it inside a fence; splitting naively shatters
/// exactly those slides and silently orphans their scripts.
///
/// [deckLabel] identifies the deck (its file path, when called from
/// [loadDeck]) in the error thrown for an unclosed fence.
///
/// An unclosed fence (an odd number of ``` lines) leaves the fence flag `true`
/// for the rest of the body, which would otherwise silently swallow every
/// following slide -- including its script -- into one oversized chunk with
/// no crash and no visible sign anything went wrong. Throwing converts that
/// silent corruption into a loud, named failure.
List<String> splitSlides(String body, {String deckLabel = 'deck'}) {
  final chunks = <String>[];
  var cur = <String>[];
  var fenced = false;

  for (final line in body.split('\n')) {
    final stripped = line.trim();
    if (stripped.startsWith('```')) fenced = !fenced;
    if (!fenced && stripped == '---') {
      if (cur.join('\n').trim().isNotEmpty) chunks.add(cur.join('\n'));
      cur = <String>[];
      continue;
    }
    cur.add(line);
  }
  if (fenced) {
    throw FormatException(
        'Unclosed code fence in $deckLabel: a ``` block was opened but '
        'never closed, which would silently swallow every following slide '
        '(and its script) into one chunk.');
  }
  if (cur.join('\n').trim().isNotEmpty) chunks.add(cur.join('\n'));
  return chunks;
}

/// Split a slide body into typed blocks.
List<Block> parseBlocks(String src) {
  final blocks = <Block>[];
  final lines = src.split('\n');
  var i = 0;

  while (i < lines.length) {
    final stripped = lines[i].trim();

    if (stripped.isEmpty) {
      i++;
    } else if (stripped.startsWith('```')) {
      final lang = stripped.substring(3).trim();
      i++;
      final buf = <String>[];
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        buf.add(lines[i]);
        i++;
      }
      i++;
      blocks.add(CodeBlock(lang, buf));
    } else if (stripped.startsWith('# ')) {
      blocks.add(TitleBlock(stripped.substring(2).trim()));
      i++;
    } else if (stripped.startsWith('## ')) {
      blocks.add(SubtitleBlock(stripped.substring(3).trim()));
      i++;
    } else if (stripped.startsWith('![')) {
      final m = RegExp(r'\((.+?)\)').firstMatch(stripped);
      if (m != null) blocks.add(ImageBlock(m.group(1)!));
      i++;
    } else if (stripped.startsWith('> ')) {
      blocks.add(QuoteBlock(stripped.substring(2).trim()));
      i++;
    } else if (stripped.startsWith('- ')) {
      final items = <BulletItem>[];
      while (i < lines.length && lines[i].trim().startsWith('- ')) {
        final depth = lines[i].startsWith('  ') ? 1 : 0;
        items.add(
            BulletItem(depth: depth, text: lines[i].trim().substring(2).trim()));
        i++;
      }
      blocks.add(BulletsBlock(items));
    } else {
      blocks.add(ParaBlock(stripped));
      i++;
    }
  }
  return blocks;
}

/// Collect `[text](url)` markers from block body text, in order, de-duplicated
/// by URL. Code blocks and images contribute nothing -- a URL inside a fence is
/// sample data, and an image src is an asset, not a resource for the student.
List<LinkRef> extractLinks(List<Block> blocks) {
  final seen = <String>{};
  final links = <LinkRef>[];
  for (final b in blocks) {
    for (final m in _linkPattern.allMatches(b.linkSource)) {
      final url = m.group(2)!;
      if (seen.add(url)) {
        links.add(LinkRef(text: m.group(1)!, url: url));
      }
    }
  }
  return links;
}

/// Parse a deck markdown file into a [Lecture].
///
/// The lecture id is the filename stem, which is also the JSON filename and the
/// minio key prefix for its media.
Lecture loadDeck(String path) {
  final raw = File(path).readAsStringSync();
  final fm = parseFrontmatter(raw);

  final slides = <Slide>[];
  var index = 1;
  for (final chunk in splitSlides(fm.body, deckLabel: path)) {
    final marker = chunk.indexOf('\nNOTES:');
    final bodySrc = marker == -1 ? chunk : chunk.substring(0, marker);
    final script = marker == -1 ? '' : chunk.substring(marker + 7).trim();

    final blocks = parseBlocks(bodySrc);
    final titles = blocks.whereType<TitleBlock>();

    slides.add(Slide(
      index: index,
      heading: titles.isEmpty ? null : titles.first.text,
      blocks: blocks,
      script: script,
      links: extractLinks(blocks),
    ));
    index++;
  }

  final data = fm.data;
  return Lecture(
    id: p.basenameWithoutExtension(path),
    week: data['week'] as int,
    track: data['track'] as String,
    title: data['title'] as String,
    subtitle: data['subtitle'] as String?,
    slides: slides,
  );
}
