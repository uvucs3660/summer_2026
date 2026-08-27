# CS 3540 Lecture Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move deck parsing into `course_builder` (Dart), emit schema-validated `lectures.json`, and replace the Python `.pptx` renderer with a Java/POI renderer — leaving deck markdown as the single source of truth and no Python in the pipeline.

**Architecture:** Exactly one component parses deck markdown: a Dart loader in `course_builder`. It emits an index plus one JSON document per lecture, each validated against `schemas/lecture.schema.json` before it is written. Every other consumer — the Java/POI `.pptx` renderer now, ElevenLabs and Flutter later — reads already-parsed JSON. The renderer becomes a leaf, so its language stops being an architectural decision.

**Tech Stack:** Dart 3 (`package:test`, `package:yaml`, `package:crypto`, `json_schema ^5.1.7`), Java 21 / Spring Boot 4.1.1 / Apache POI (XSLF), TypeScript / `ajv`.

**Spec:** `tools/course_builder/docs/superpowers/specs/2026-08-27-cs3540-lecture-delivery-design.md`

## Global Constraints

- **Script content is frozen for this plan.** Do not edit any `NOTES:` text. The persona rewrite is a separate plan; parity checks here compare against current output and are meaningless if the input changes.
- Dart SDK `^3.0.0`. Do not raise the floor in `pubspec.yaml`.
- `json_schema` is pinned to `^5.1.7` — the same version `forge_ui` uses. Do not diverge.
- Slide identity is **positional** (`index`, 1-based). No id markers in deck markdown.
- `schema_version` is `"1.0.0"` everywhere.
- Block types are exactly: `title`, `subtitle`, `bullets`, `code`, `image`, `quote`, `para`. Do not invent new types.
- Inline `**bold**`, `` `code` `` and `[text](url)` markers stay **raw** in text fields. Renderers style them; the parser does not strip them.
- `links[]` is derived from block text, never authored separately. Scripts are not scanned.
- Media is referenced by object **`key`** (minio), never a filesystem path.
- Working directory for all Dart commands: `/Users/michael/code/uvu/tools/course_builder`.
- Java work is in `~/code/fivex/mod_java`, package `com.fivex.module.lecture`.
- Reference corpus: 28 decks, 253 slides, 31,946 words.

---

### Task 1: POI notes-slide spike (GATE)

Prerequisite for Tasks 8–10. POI's `XSLFNotes` is documented for reading; the `setNotes()` API in the docs belongs to `HSLFSlide` (legacy binary `.ppt`). Speaker notes **are** the script, so this must be proven before any renderer rewrite.

**Files:**
- Create: `~/code/fivex/mod_java/src/test/java/com/fivex/module/lecture/PoiNotesSpikeTest.java`
- Modify: `~/code/fivex/mod_java/build.gradle`
- Create: `tools/course_builder/docs/superpowers/plans/2026-08-27-poi-spike-findings.md`

**Interfaces:**
- Consumes: nothing
- Produces: the pinned POI version and a recorded boolean `notesWorkOnBlankDeck: true|false`. Task 8 reads this to choose its first two lines.

- [ ] **Step 1: Add POI to build.gradle**

Resolve the current 5.x release from Maven Central and pin it explicitly. Add inside `dependencies { }`:

```groovy
    implementation 'org.apache.poi:poi-ooxml:<pinned-5.x-version>'
```

Record the exact version string in the findings doc in Step 6.

- [ ] **Step 2: Write the spike test**

```java
package com.fivex.module.lecture;

import org.apache.poi.xslf.usermodel.*;
import org.junit.jupiter.api.Test;
import java.io.FileOutputStream;
import java.nio.file.Path;
import static org.junit.jupiter.api.Assertions.*;

class PoiNotesSpikeTest {

    @Test
    void notesSlideCanBeCreatedOnBlankPresentation() throws Exception {
        XMLSlideShow ppt = new XMLSlideShow();
        XSLFSlide slide = ppt.createSlide();

        XSLFTextBox body = slide.createTextBox();
        body.setAnchor(new java.awt.Rectangle(50, 50, 600, 100));
        XSLFTextParagraph p = body.addNewTextParagraph();
        XSLFTextRun r = p.addNewTextRun();
        r.setText("Spike slide");

        XSLFNotes notes = ppt.getNotesSlide(slide);
        assertNotNull(notes, "getNotesSlide returned null on a blank presentation");

        boolean wrote = false;
        for (XSLFShape sh : notes) {
            if (sh instanceof XSLFTextShape ts) {
                ts.setText("SPIKE NOTES BODY");
                wrote = true;
                break;
            }
        }
        assertTrue(wrote, "no text shape available on the notes slide");

        Path out = Path.of(System.getProperty("java.io.tmpdir"), "poi-spike.pptx");
        try (FileOutputStream fos = new FileOutputStream(out.toFile())) {
            ppt.write(fos);
        }
        ppt.close();
        System.out.println("SPIKE OUTPUT: " + out);
    }
}
```

- [ ] **Step 3: Run the spike**

Run: `cd ~/code/fivex/mod_java && ./gradlew test --tests 'com.fivex.module.lecture.PoiNotesSpikeTest'`

Both outcomes are valid results — record which happened.
- PASS: blank-deck notes creation works.
- FAIL (null notes slide, or no text shape): the template path is required; go to Step 4.

- [ ] **Step 4: If Step 3 failed, prove the template path**

Create a minimal `template.pptx` in PowerPoint or Keynote with one slide that has a speaker note typed into it — typing a note is what forces a notes master into the file. Save to `~/code/fivex/mod_java/src/main/resources/lecture/template.pptx`. Replace the spike's first two lines with:

```java
XMLSlideShow ppt = new XMLSlideShow(
    getClass().getResourceAsStream("/lecture/template.pptx"));
for (int i = ppt.getSlides().size() - 1; i >= 0; i--) {
    ppt.removeSlide(i);
}
XSLFSlide slide = ppt.createSlide();
```

Re-run Step 3's command.

- [ ] **Step 5: Open the output and verify by eye**

Run: `open /tmp/poi-spike.pptx`
Expected: the notes pane shows `SPIKE NOTES BODY`. A file that opens without the note is a FAIL even if the test passed.

- [ ] **Step 6: Record findings**

Write `docs/superpowers/plans/2026-08-27-poi-spike-findings.md` recording: the pinned POI version, whether blank-deck notes worked, whether a template was needed, and the exact working code path.

**If neither path produced a readable notes pane, STOP and escalate.** Spec §7 requires the renderer decision be revisited before any rewrite, not after.

- [ ] **Step 7: Commit**

```bash
cd ~/code/fivex/mod_java
git add build.gradle src/test/java/com/fivex/module/lecture/PoiNotesSpikeTest.java
git add src/main/resources/lecture/template.pptx 2>/dev/null || true
git commit -m "spike(lecture): prove POI XSLF speaker-notes creation"
```

---

### Task 2: Dart lecture models

**Files:**
- Create: `lib/src/models/lecture.dart`
- Test: `test/models/lecture_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `sealed class Block` with `TitleBlock`, `SubtitleBlock`, `BulletsBlock`, `CodeBlock`, `ImageBlock`, `QuoteBlock`, `ParaBlock`; `BulletItem({int depth, String text})`; `LinkRef({String text, String url})`; `Slide({int index, String? heading, List<Block> blocks, String script, List<LinkRef> links})`; `Lecture({String id, int week, String track, String title, String? subtitle, List<Slide> slides})`. All expose `Map<String, dynamic> toJson()`. `Lecture` exposes `int get wordCount` and `int get estimatedDurationMs`.

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/models/lecture_test.dart`
Expected: FAIL — `lecture.dart` does not exist.

- [ ] **Step 3: Write the implementation**

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/models/lecture_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/src/models/lecture.dart test/models/lecture_test.dart
git commit -m "feat(lecture): typed models for decks, slides, blocks and links"
```

---

### Task 3: Dart deck loader

The fenced-code rule is the point of this task. `w02-ai-claude-md`, `w03-ai-skills` and `w04-ai-writing-a-spec` teach YAML frontmatter by showing it inside a fence, so a naive splitter cuts those slides apart and silently orphans their scripts.

**Files:**
- Create: `lib/src/loaders/deck_loader.dart`
- Create: `test/fixtures/decks/fenced-deck.md`
- Test: `test/loaders/deck_loader_test.dart`

**Interfaces:**
- Consumes: `Block`/`Slide`/`Lecture`/`LinkRef` (Task 2); `parseFrontmatter` from `lib/src/loaders/frontmatter.dart`
- Produces: `List<String> splitSlides(String body)`, `List<Block> parseBlocks(String src)`, `List<LinkRef> extractLinks(List<Block> blocks)`, `Lecture loadDeck(String path)`

- [ ] **Step 1: Create the fixture**

Create `test/fixtures/decks/fenced-deck.md` with exactly this content. The fenced `---` lines and the sample URL inside the fence are the traps being tested.

<pre>
---
track: ai
week: 3
title: Skills
subtitle: The Description Is the Product
---

# Opening

- First point with **bold**
- See [the spec](https://github.com/uvucs3540/engine-spec)

NOTES:
Opening script.

---

# A skill is a folder

```yaml
---
name: open-pr
homepage: https://example.com/not-a-resource
---
```

The frontmatter is the **contract**.

NOTES:
Second slide script.

---

# Closing

> A quote line

![diagram](img/x.png)

NOTES:
Third slide script.
</pre>

- [ ] **Step 2: Write the failing test**

```dart
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
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `dart test test/loaders/deck_loader_test.dart`
Expected: FAIL — `deck_loader.dart` does not exist.

- [ ] **Step 4: Write the implementation**

```dart
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
List<String> splitSlides(String body) {
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
  for (final chunk in splitSlides(fm.body)) {
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dart test test/loaders/deck_loader_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 6: Run the loader against all 28 real decks**

Create `tool/corpus_check.dart` (a repo tool, committed — it stays useful whenever decks change):

```dart
import 'dart:io';
import 'package:course_builder/src/loaders/deck_loader.dart';

void main() {
  final dir = Directory('content/cs3540/2026/lectures/slides');
  var decks = 0, slides = 0, words = 0, links = 0, unscripted = 0;

  final files = dir.listSync().whereType<File>().where(
      (f) => RegExp(r'w\d\d-.*\.md$').hasMatch(f.path)).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final d = loadDeck(f.path);
    decks++;
    slides += d.slides.length;
    words += d.wordCount;
    for (final s in d.slides) {
      links += s.links.length;
      if (s.script.isEmpty) {
        unscripted++;
        stderr.writeln('${d.id} slide ${s.index}: no script');
      }
    }
  }
  stdout.writeln('decks=$decks slides=$slides words=$words links=$links '
      'unscripted=$unscripted');
  if (unscripted > 0) exit(1);
}
```

Run: `dart run tool/corpus_check.dart`
Expected: `decks=28 slides=253 words=31946 links=<n> unscripted=0`.

Any deviation in decks/slides/words means the port is wrong — do not proceed. `links` is informational; record the number in the handoff.

- [ ] **Step 7: Commit**

```bash
git add lib/src/loaders/deck_loader.dart test/loaders/deck_loader_test.dart \
        test/fixtures/decks/fenced-deck.md tool/corpus_check.dart
git commit -m "feat(lecture): fence-aware deck parser with derived links"
```

---

### Task 4: JSON Schema

The schema is written before the emitter so the emitter can validate against it from the first run.

**Files:**
- Create: `schemas/lecture.schema.json`
- Test: covered by Task 5's validation and Task 6's ajv test

**Interfaces:**
- Consumes: the model shapes from Task 2
- Produces: the cross-language contract loaded by Task 5, Task 6, and later by ElevenLabs and Flutter.

- [ ] **Step 1: Write the schema**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://uvu.edu/schemas/lecture.schema.json",
  "title": "CS 3540 Lecture Document",
  "type": "object",
  "required": ["schema_version", "id", "week", "track", "title", "source", "slides"],
  "additionalProperties": false,
  "properties": {
    "schema_version": { "const": "1.0.0" },
    "id": { "type": "string", "pattern": "^[a-z0-9-]+$" },
    "course": { "type": "string" },
    "year": { "type": "integer" },
    "week": { "type": "integer", "minimum": 1, "maximum": 16 },
    "track": { "enum": ["game", "ai"] },
    "title": { "type": "string", "minLength": 1 },
    "subtitle": { "type": "string" },
    "source": {
      "type": "object",
      "required": ["deck", "script_hash"],
      "additionalProperties": false,
      "properties": {
        "deck": { "type": "string" },
        "script_hash": { "type": "string", "pattern": "^sha256:[0-9a-f]{64}$" }
      }
    },
    "audio": {
      "oneOf": [
        { "type": "null" },
        {
          "type": "object",
          "required": ["key", "duration_ms", "voice", "model", "script_hash", "generated_at"],
          "additionalProperties": false,
          "properties": {
            "key": { "type": "string" },
            "duration_ms": { "type": "integer", "minimum": 0 },
            "voice": { "type": "string" },
            "model": { "type": "string" },
            "script_hash": { "type": "string", "pattern": "^sha256:[0-9a-f]{64}$" },
            "generated_at": { "type": "string", "format": "date-time" }
          }
        }
      ]
    },
    "video": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "intro": { "$ref": "#/$defs/video" },
        "outro": { "$ref": "#/$defs/video" }
      }
    },
    "slides": { "type": "array", "minItems": 1, "items": { "$ref": "#/$defs/slide" } }
  },
  "$defs": {
    "link": {
      "type": "object",
      "required": ["text", "url"],
      "additionalProperties": false,
      "properties": {
        "text": { "type": "string", "minLength": 1 },
        "url": { "type": "string", "pattern": "^https?://" }
      }
    },
    "video": {
      "oneOf": [
        { "type": "null" },
        {
          "type": "object",
          "required": ["key", "mode", "audio", "duration_ms"],
          "additionalProperties": false,
          "properties": {
            "key": { "type": "string" },
            "mode": { "enum": ["pip", "fullscreen"] },
            "audio": { "enum": ["video", "narration"] },
            "position": { "enum": ["top-left", "top-right", "bottom-left", "bottom-right"] },
            "duration_ms": { "type": "integer", "minimum": 0 }
          }
        }
      ]
    },
    "slide": {
      "type": "object",
      "required": ["index", "blocks", "script"],
      "additionalProperties": false,
      "properties": {
        "index": { "type": "integer", "minimum": 1 },
        "heading": { "type": "string" },
        "blocks": { "type": "array", "items": { "$ref": "#/$defs/block" } },
        "script": { "type": "string" },
        "links": { "type": "array", "items": { "$ref": "#/$defs/link" } },
        "audio_span": {
          "type": "object",
          "required": ["start_ms", "end_ms"],
          "additionalProperties": false,
          "properties": {
            "start_ms": { "type": "integer", "minimum": 0 },
            "end_ms": { "type": "integer", "minimum": 0 }
          }
        },
        "reveals": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["block", "at_ms"],
            "additionalProperties": false,
            "properties": {
              "block": { "type": "integer", "minimum": 0 },
              "at_ms": { "type": "integer", "minimum": 0 }
            }
          }
        },
        "video": { "$ref": "#/$defs/video" }
      }
    },
    "block": {
      "oneOf": [
        {
          "type": "object",
          "required": ["type", "text"],
          "additionalProperties": false,
          "properties": {
            "type": { "enum": ["title", "subtitle", "quote", "para"] },
            "text": { "type": "string" }
          }
        },
        {
          "type": "object",
          "required": ["type", "items"],
          "additionalProperties": false,
          "properties": {
            "type": { "const": "bullets" },
            "items": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["depth", "text"],
                "additionalProperties": false,
                "properties": {
                  "depth": { "type": "integer", "minimum": 0, "maximum": 1 },
                  "text": { "type": "string" }
                }
              }
            }
          }
        },
        {
          "type": "object",
          "required": ["type", "lang", "lines"],
          "additionalProperties": false,
          "properties": {
            "type": { "const": "code" },
            "lang": { "type": "string" },
            "lines": { "type": "array", "items": { "type": "string" } }
          }
        },
        {
          "type": "object",
          "required": ["type", "src"],
          "additionalProperties": false,
          "properties": {
            "type": { "const": "image" },
            "src": { "type": "string" }
          }
        }
      ]
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add schemas/lecture.schema.json
git commit -m "feat(lecture): JSON Schema contract for lecture documents"
```

---

### Task 5: JSON emitter with validation and golden test

**Files:**
- Modify: `pubspec.yaml` (add `json_schema: ^5.1.7`)
- Create: `lib/src/emitters/lectures_json.dart`
- Create: `test/fixtures/decks/fenced-deck.golden.json`
- Test: `test/emitters/lectures_json_test.dart`

**Interfaces:**
- Consumes: `Lecture`/`Slide`/`Block` (Task 2), `loadDeck` (Task 3), `schemas/lecture.schema.json` (Task 4)
- Produces: `Map<String, dynamic> lectureToJson(Lecture l, {required String deckPath})`, `Map<String, dynamic> indexToJson(List<Lecture> lectures, {required String course, required int year})`, `String scriptHash(Lecture l)`, `void validateLecture(Map<String, dynamic> doc, {String schemaPath})` which throws `LectureSchemaException` on failure.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, add — matching `forge_ui`'s version exactly:

```yaml
  json_schema: ^5.1.7
```

Run: `dart pub get`
Expected: resolves without raising the SDK floor above `^3.0.0`.

- [ ] **Step 2: Write the failing test**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:test/test.dart';

void main() {
  const path = 'test/fixtures/decks/fenced-deck.md';

  test('lecture JSON matches the golden file', () {
    final actual = lectureToJson(loadDeck(path), deckPath: path);
    final expected = jsonDecode(
        File('test/fixtures/decks/fenced-deck.golden.json').readAsStringSync());
    expect(actual, expected);
  });

  test('generated documents validate against the schema', () {
    final doc = lectureToJson(loadDeck(path), deckPath: path);
    expect(() => validateLecture(doc), returnsNormally);
  });

  test('validation rejects an unknown block type', () {
    final doc = lectureToJson(loadDeck(path), deckPath: path);
    (doc['slides'] as List)[0]['blocks'] = [
      {'type': 'callout', 'text': 'nope'}
    ];
    expect(() => validateLecture(doc), throwsA(isA<LectureSchemaException>()));
  });

  test('script hash is stable and prefixed', () {
    final deck = loadDeck(path);
    final h = scriptHash(deck);
    expect(h, startsWith('sha256:'));
    expect(scriptHash(deck), h);
  });

  test('index carries one entry per lecture with estimated duration', () {
    final deck = loadDeck(path);
    final idx = indexToJson([deck], course: 'cs3540', year: 2026);
    expect(idx['schema_version'], '1.0.0');
    expect(idx['course'], 'cs3540');
    final entry = (idx['lectures'] as List).single as Map;
    expect(entry['id'], 'fenced-deck');
    expect(entry['file'], 'fenced-deck.json');
    expect(entry['slide_count'], 3);
    expect(entry['duration_ms'], deck.estimatedDurationMs);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `dart test test/emitters/lectures_json_test.dart`
Expected: FAIL — `lectures_json.dart` does not exist.

- [ ] **Step 4: Write the implementation**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:json_schema/json_schema.dart';

import '../models/lecture.dart';

const String schemaVersion = '1.0.0';
const String defaultSchemaPath = 'schemas/lecture.schema.json';

/// Thrown when a generated document does not conform to the schema. The
/// producer is not allowed to write a document it cannot validate.
class LectureSchemaException implements Exception {
  final String id;
  final List<String> errors;
  LectureSchemaException(this.id, this.errors);
  @override
  String toString() =>
      'Lecture "$id" failed schema validation:\n  ${errors.join('\n  ')}';
}

/// Hash of every slide script in order. Stage 2 compares this against the hash
/// the audio was generated from to decide whether a deck needs re-synthesis.
String scriptHash(Lecture l) {
  final joined = l.slides.map((s) => s.script).join('\n \n');
  return 'sha256:${sha256.convert(utf8.encode(joined))}';
}

Map<String, dynamic> lectureToJson(Lecture l, {required String deckPath}) => {
      'schema_version': schemaVersion,
      'id': l.id,
      'week': l.week,
      'track': l.track,
      'title': l.title,
      if (l.subtitle != null) 'subtitle': l.subtitle,
      'source': {'deck': deckPath, 'script_hash': scriptHash(l)},
      'audio': null,
      'video': {'intro': null, 'outro': null},
      'slides': l.slides.map((s) => s.toJson()).toList(),
    };

Map<String, dynamic> indexToJson(
  List<Lecture> lectures, {
  required String course,
  required int year,
}) {
  final sorted = [...lectures]..sort((a, b) {
      final byWeek = a.week.compareTo(b.week);
      if (byWeek != 0) return byWeek;
      // Game before AI within a week, matching the track table in slides/README.md.
      return a.track == 'game' ? -1 : 1;
    });

  return {
    'schema_version': schemaVersion,
    'course': course,
    'year': year,
    'lectures': sorted
        .map((l) => {
              'id': l.id,
              'week': l.week,
              'track': l.track,
              'title': l.title,
              if (l.subtitle != null) 'subtitle': l.subtitle,
              'slide_count': l.slides.length,
              'word_count': l.wordCount,
              'duration_ms': l.estimatedDurationMs,
              'file': '${l.id}.json',
            })
        .toList(),
  };
}

JsonSchema? _cached;

/// Validate a generated lecture document. Follows the platform pattern in
/// forge_ui/lib/com/fti/io/file_manager.dart:230.
void validateLecture(Map<String, dynamic> doc,
    {String schemaPath = defaultSchemaPath}) {
  _cached ??= JsonSchema.create(
      jsonDecode(File(schemaPath).readAsStringSync()) as Map<String, dynamic>);

  final result = _cached!.validate(doc);
  if (!result.isValid) {
    throw LectureSchemaException(
        doc['id']?.toString() ?? '<unknown>',
        result.errors.map((e) => e.toString()).toList());
  }
}
```

- [ ] **Step 5: Generate the golden file, then read it before trusting it**

Create `tool/write_golden.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';

void main() {
  const path = 'test/fixtures/decks/fenced-deck.md';
  final json = lectureToJson(loadDeck(path), deckPath: path);
  validateLecture(json);
  File('test/fixtures/decks/fenced-deck.golden.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln('golden written and validated');
}
```

Run:
```bash
dart run tool/write_golden.dart
cat test/fixtures/decks/fenced-deck.golden.json
```

Read the output before committing. Confirm: 3 slides; the yaml `code` block retains its `---` lines; `**bold**` and the raw `[the spec](...)` marker are still present in text; slide 1 has a `links` array with one entry; slides 2 and 3 have no `links` key. A golden file committed without reading it tests nothing.

- [ ] **Step 6: Run test to verify it passes**

Run: `dart test test/emitters/lectures_json_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/src/emitters/lectures_json.dart \
        test/emitters/lectures_json_test.dart \
        test/fixtures/decks/fenced-deck.golden.json tool/write_golden.dart
git commit -m "feat(lecture): emitter with json_schema validation and golden coverage"
```

---

### Task 6: build_lectures CLI

**Files:**
- Create: `bin/build_lectures.dart`
- Modify: `content/cs3540/2026/lectures/slides/.gitignore`
- Test: `test/bin/build_lectures_test.dart`

**Interfaces:**
- Consumes: `loadDeck` (Task 3), `lectureToJson`/`indexToJson`/`validateLecture` (Task 5)
- Produces: CLI `dart run bin/build_lectures.dart [--slides-dir DIR] [--out DIR] [--course C] [--year Y]`, writing `lectures.json` plus one `<id>.json` per deck. Exit 1 on any parse or validation failure.

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI emits a validated index and one file per deck', () async {
    final tmp = Directory.systemTemp.createTempSync('lectures_cli');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = await Process.run('dart', [
      'run', 'bin/build_lectures.dart',
      '--slides-dir', 'test/fixtures/decks',
      '--out', tmp.path,
      '--course', 'cs3540',
      '--year', '2026',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());

    final index = jsonDecode(File('${tmp.path}/lectures.json').readAsStringSync());
    expect(index['course'], 'cs3540');
    expect((index['lectures'] as List).length, 1);
    expect(File('${tmp.path}/fenced-deck.json').existsSync(), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/bin/build_lectures_test.dart`
Expected: FAIL — `bin/build_lectures.dart` does not exist.

- [ ] **Step 3: Write the implementation**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:course_builder/src/emitters/lectures_json.dart';
import 'package:course_builder/src/loaders/deck_loader.dart';
import 'package:course_builder/src/models/lecture.dart';
import 'package:path/path.dart' as p;

const _encoder = JsonEncoder.withIndent('  ');

String _arg(List<String> a, String flag, String fallback) {
  final i = a.indexOf(flag);
  return i == -1 || i + 1 >= a.length ? fallback : a[i + 1];
}

void main(List<String> args) {
  final slidesDir =
      _arg(args, '--slides-dir', 'content/cs3540/2026/lectures/slides');
  final outDir = _arg(args, '--out', p.join(slidesDir, '_lectures'));
  final course = _arg(args, '--course', 'cs3540');
  final year = int.parse(_arg(args, '--year', '2026'));

  final deckFiles = Directory(slidesDir)
      .listSync()
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.md')
      .where((f) => RegExp(r'^(w\d\d-|fenced-)').hasMatch(p.basename(f.path)))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (deckFiles.isEmpty) {
    stderr.writeln('No decks found in $slidesDir');
    exit(1);
  }

  Directory(outDir).createSync(recursive: true);

  final lectures = <Lecture>[];
  for (final f in deckFiles) {
    final Lecture deck;
    try {
      deck = loadDeck(f.path);
    } catch (e) {
      stderr.writeln('Failed to parse ${f.path}: $e');
      exit(1);
    }

    final doc = lectureToJson(deck, deckPath: f.path);
    try {
      validateLecture(doc);
    } on LectureSchemaException catch (e) {
      stderr.writeln(e);
      exit(1);
    }

    lectures.add(deck);
    File(p.join(outDir, '${deck.id}.json'))
        .writeAsStringSync('${_encoder.convert(doc)}\n');
  }

  File(p.join(outDir, 'lectures.json')).writeAsStringSync(
      '${_encoder.convert(indexToJson(lectures, course: course, year: year))}\n');

  final slides = lectures.fold(0, (s, l) => s + l.slides.length);
  final words = lectures.fold(0, (s, l) => s + l.wordCount);
  stdout.writeln(
      '${lectures.length} lectures, $slides slides, $words words -> $outDir');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/bin/build_lectures_test.dart`
Expected: PASS.

- [ ] **Step 5: Run against the real corpus**

Run: `dart run bin/build_lectures.dart`
Expected: `28 lectures, 253 slides, 31946 words -> content/cs3540/2026/lectures/slides/_lectures`

- [ ] **Step 6: Gitignore the output**

```bash
echo '_lectures/' >> content/cs3540/2026/lectures/slides/.gitignore
cat content/cs3540/2026/lectures/slides/.gitignore
```
Expected: `.venv/`, `*.pptx`, `_render/`, `_lectures/`.

- [ ] **Step 7: Commit**

```bash
git add bin/build_lectures.dart test/bin/build_lectures_test.dart \
        content/cs3540/2026/lectures/slides/.gitignore
git commit -m "feat(lecture): build_lectures CLI emitting validated JSON"
```

---

### Task 7: Consumer-side schema conformance in mod_node

The Dart side validates what it produces; this proves the same schema compiles and passes under `ajv`, the validator stage ② and the tracking module will use.

**Files:**
- Create: `~/code/fivex/mod_node/modules/lecture/schemas/lecture.schema.json` (copy)
- Create: `~/code/fivex/mod_node/modules/lecture/__tests__/fixtures/w03-ai-skills.json`
- Test: `~/code/fivex/mod_node/modules/lecture/__tests__/schema.test.ts`

**Interfaces:**
- Consumes: `schemas/lecture.schema.json` (Task 4), a real generated document (Task 6)
- Produces: proof the contract holds across the Dart/TypeScript boundary

- [ ] **Step 1: Copy the schema and a real fixture**

```bash
mkdir -p ~/code/fivex/mod_node/modules/lecture/schemas
mkdir -p ~/code/fivex/mod_node/modules/lecture/__tests__/fixtures
cp /Users/michael/code/uvu/tools/course_builder/schemas/lecture.schema.json \
   ~/code/fivex/mod_node/modules/lecture/schemas/lecture.schema.json
cp /Users/michael/code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides/_lectures/w03-ai-skills.json \
   ~/code/fivex/mod_node/modules/lecture/__tests__/fixtures/w03-ai-skills.json
```

- [ ] **Step 2: Write the conformance test**

```typescript
import Ajv2020 from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import * as fs from 'fs';
import * as path from 'path';

describe('lecture schema', () => {
  const ajv = addFormats(new Ajv2020({ allErrors: true }));
  const schema = JSON.parse(
    fs.readFileSync(path.join(__dirname, '../schemas/lecture.schema.json'), 'utf-8'),
  );
  const validate = ajv.compile(schema);

  const load = () =>
    JSON.parse(
      fs.readFileSync(path.join(__dirname, 'fixtures/w03-ai-skills.json'), 'utf-8'),
    );

  it('accepts a real generated lecture document', () => {
    const ok = validate(load());
    if (!ok) console.error(validate.errors);
    expect(ok).toBe(true);
  });

  it('rejects an unknown block type', () => {
    const doc = load();
    doc.slides[0].blocks = [{ type: 'callout', text: 'nope' }];
    expect(validate(doc)).toBe(false);
  });

  it('rejects a wrong schema_version', () => {
    const doc = load();
    doc.schema_version = '2.0.0';
    expect(validate(doc)).toBe(false);
  });

  it('rejects a link without a url', () => {
    const doc = load();
    doc.slides[0].links = [{ text: 'dangling' }];
    expect(validate(doc)).toBe(false);
  });
});
```

- [ ] **Step 3: Run the test**

Run: `cd ~/code/fivex/mod_node && npx jest modules/lecture/__tests__/schema.test.ts`
Expected: PASS, 4 tests.

If the real document fails validation, **fix the schema to match reality** and re-copy it to both repos — the emitter is the producer of record and the schema describes it, not the other way round.

- [ ] **Step 4: Commit**

```bash
cd ~/code/fivex/mod_node
git add modules/lecture/schemas modules/lecture/__tests__
git commit -m "test(lecture): ajv conformance for the lecture schema"
```

---

### Task 8: Parser parity against the Python build (GATE)

Proves the Dart port is faithful before the Python renderer is deleted. Throwaway harness; removed in Task 11.

**Files:**
- Create: `/tmp/parity_check.py` (throwaway, never committed)

**Interfaces:**
- Consumes: `_lectures/*.json` (Task 6); `build_pptx.py`'s existing parser
- Produces: a pass/fail verdict. No code survives this task.

- [ ] **Step 1: Write the parity harness**

```python
# /tmp/parity_check.py -- throwaway; deleted in Task 11.
import json, pathlib, sys
sys.path.insert(0, 'content/cs3540/2026/lectures/slides')
from build_pptx import split_slides            # the current parser

SLIDES = pathlib.Path('content/cs3540/2026/lectures/slides')
OUT = SLIDES / '_lectures'
fail = 0

for md in sorted(SLIDES.glob('w*.md')):
    raw = md.read_text()
    if raw.startswith('---\n'):
        raw = raw[4:].split('\n---\n', 1)[1]
    py_scripts = [c.partition('\nNOTES:')[2].strip() for c in split_slides(raw)]

    doc = json.loads((OUT / f'{md.stem}.json').read_text())
    dart_scripts = [s['script'] for s in doc['slides']]

    if len(py_scripts) != len(dart_scripts):
        print(f'{md.stem}: SLIDE COUNT python={len(py_scripts)} dart={len(dart_scripts)}')
        fail += 1
        continue
    for i, (a, b) in enumerate(zip(py_scripts, dart_scripts), 1):
        if a != b:
            print(f'{md.stem} slide {i}: SCRIPT MISMATCH')
            fail += 1

print('PARITY OK' if fail == 0 else f'PARITY FAILED ({fail} problems)')
sys.exit(1 if fail else 0)
```

- [ ] **Step 2: Run it**

Run: `python3 /tmp/parity_check.py`
Expected: `PARITY OK`, exit 0.

**If it fails:** the Dart parser is wrong, not the Python one. Fix `deck_loader.dart`, re-run `dart run bin/build_lectures.dart`, re-run this check. Do not proceed — every downstream task assumes the JSON is faithful.

- [ ] **Step 3: Record the result**

No commit. Note in the handoff that parity passed across 28 decks / 253 slides.

---

### Task 9: Java/POI renderer core

**Depends on Task 1's findings.** Use the code path the spike recorded — blank presentation, or template-loaded.

**Files:**
- Create: `~/code/fivex/mod_java/src/main/java/com/fivex/module/lecture/LectureDeckRenderer.java`
- Create: `~/code/fivex/mod_java/src/test/java/com/fivex/module/lecture/LectureDeckRendererTest.java`
- Create: `~/code/fivex/mod_java/src/test/resources/lecture/fenced-deck.json`

**Interfaces:**
- Consumes: a lecture document conforming to Task 4's schema
- Produces: `byte[] LectureDeckRenderer.render(JsonNode lecture)` — a `.pptx` with one slide per `slides[]` entry, each `script` in that slide's notes pane, and `[text](url)` markers rendered as real hyperlinks.

- [ ] **Step 1: Write the failing test**

```java
package com.fivex.module.lecture;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.poi.xslf.usermodel.*;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

class LectureDeckRendererTest {

    private XMLSlideShow render() throws Exception {
        var json = new ObjectMapper().readTree(
            Files.readString(Path.of("src/test/resources/lecture/fenced-deck.json")));
        byte[] pptx = new LectureDeckRenderer().render(json);
        return new XMLSlideShow(new ByteArrayInputStream(pptx));
    }

    private String allText(XSLFSlide slide) {
        StringBuilder sb = new StringBuilder();
        for (XSLFShape sh : slide) {
            if (sh instanceof XSLFTextShape ts) sb.append(ts.getText());
        }
        return sb.toString();
    }

    @Test
    void producesOneSlidePerJsonSlide() throws Exception {
        try (XMLSlideShow ppt = render()) {
            assertEquals(3, ppt.getSlides().size());
        }
    }

    @Test
    void everySlideCarriesItsScriptInTheNotesPane() throws Exception {
        try (XMLSlideShow ppt = render()) {
            XSLFNotes notes = ppt.getNotesSlide(ppt.getSlides().get(0));
            assertNotNull(notes);
            StringBuilder text = new StringBuilder();
            for (XSLFShape sh : notes) {
                if (sh instanceof XSLFTextShape ts) text.append(ts.getText());
            }
            assertTrue(text.toString().contains("Opening script."));
        }
    }

    @Test
    void codeBlockLinesSurviveIncludingFencedDashes() throws Exception {
        try (XMLSlideShow ppt = render()) {
            assertTrue(allText(ppt.getSlides().get(1)).contains("name: open-pr"));
        }
    }

    @Test
    void inlineLinkBecomesAHyperlinkShowingOnlyItsLabel() throws Exception {
        try (XMLSlideShow ppt = render()) {
            String text = allText(ppt.getSlides().get(0));
            assertTrue(text.contains("the spec"), "link label missing");
            assertFalse(text.contains("]("), "raw markdown marker leaked into the slide");

            boolean linked = false;
            for (XSLFShape sh : ppt.getSlides().get(0)) {
                if (sh instanceof XSLFTextShape ts) {
                    for (XSLFTextParagraph p : ts.getTextParagraphs()) {
                        for (XSLFTextRun r : p.getTextRuns()) {
                            if (r.getHyperlink() != null
                                && "the spec".equals(r.getRawText())) {
                                linked = true;
                            }
                        }
                    }
                }
            }
            assertTrue(linked, "no hyperlink run found for the link label");
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ~/code/fivex/mod_java && ./gradlew test --tests 'com.fivex.module.lecture.LectureDeckRendererTest'`
Expected: FAIL — `LectureDeckRenderer` does not exist.

- [ ] **Step 3: Write the renderer**

```java
package com.fivex.module.lecture;

import com.fasterxml.jackson.databind.JsonNode;
import org.apache.poi.sl.usermodel.TextParagraph;
import org.apache.poi.xslf.usermodel.*;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Rectangle;
import java.io.ByteArrayOutputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Renders a lecture document (schemas/lecture.schema.json) into a .pptx.
 *
 * Consumes already-parsed JSON: this class never sees deck markdown. The single
 * parser lives in course_builder (Dart).
 */
public class LectureDeckRenderer {

    private static final int W = 960;
    private static final int H = 540;
    private static final Color HEADING = new Color(0xFC, 0xD3, 0x4D);
    private static final Color BODY = Color.WHITE;
    private static final Color ACCENT = new Color(0x60, 0xA5, 0xFA);

    /** Matches **bold**, `code`, and [label](url) so each becomes its own run. */
    private static final Pattern INLINE =
        Pattern.compile("(\\*\\*.+?\\*\\*|`.+?`|\\[[^\\]]+\\]\\(https?://[^)\\s]+\\))");
    private static final Pattern LINK =
        Pattern.compile("\\[([^\\]]+)\\]\\((https?://[^)\\s]+)\\)");

    public byte[] render(JsonNode lecture) throws Exception {
        // If Task 1 found a template is required, replace this line with the
        // template-loading form recorded in the spike findings doc.
        XMLSlideShow ppt = new XMLSlideShow();
        ppt.setPageSize(new Dimension(W, H));

        for (JsonNode slideNode : lecture.get("slides")) {
            XSLFSlide slide = ppt.createSlide();
            int y = 40;
            for (JsonNode block : slideNode.get("blocks")) {
                y = renderBlock(slide, block, y);
            }

            String script = slideNode.path("script").asText("");
            if (!script.isEmpty()) {
                XSLFNotes notes = ppt.getNotesSlide(slide);
                for (XSLFShape sh : notes) {
                    if (sh instanceof XSLFTextShape ts) {
                        ts.setText(script);
                        break;
                    }
                }
            }
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ppt.write(out);
        ppt.close();
        return out.toByteArray();
    }

    private int renderBlock(XSLFSlide slide, JsonNode block, int y) {
        String type = block.get("type").asText();
        switch (type) {
            case "title" -> {
                addLine(slide, block.get("text").asText(), y, 32, HEADING, true);
                return y + 56;
            }
            case "subtitle" -> {
                addLine(slide, block.get("text").asText(), y, 24, ACCENT, true);
                return y + 40;
            }
            case "quote", "para" -> {
                addLine(slide, block.get("text").asText(), y, 18, BODY, false);
                return y + 34;
            }
            case "image" -> {
                addLine(slide, "[image: " + block.get("src").asText() + "]",
                        y, 14, BODY, false);
                return y + 28;
            }
            case "bullets" -> {
                for (JsonNode item : block.get("items")) {
                    addBullet(slide, item.get("text").asText(), y,
                              item.get("depth").asInt() * 40);
                    y += 30;
                }
                return y + 10;
            }
            case "code" -> {
                addMono(slide, block.get("lines"), y);
                return y + 24 * block.get("lines").size() + 20;
            }
            default -> throw new IllegalArgumentException("unknown block type: " + type);
        }
    }

    private void addLine(XSLFSlide slide, String text, int y, int size,
                         Color color, boolean bold) {
        XSLFTextBox box = slide.createTextBox();
        box.setAnchor(new Rectangle(60, y, W - 120, size + 12));
        addRuns(box.addNewTextParagraph(), text, size, color, bold);
    }

    private void addBullet(XSLFSlide slide, String text, int y, int indent) {
        XSLFTextBox box = slide.createTextBox();
        box.setAnchor(new Rectangle(60 + indent, y, W - 120 - indent, 28));
        XSLFTextParagraph p = box.addNewTextParagraph();
        p.setBullet(true);
        p.setTextAlign(TextParagraph.TextAlign.LEFT);
        addRuns(p, text, 18, BODY, false);
    }

    private void addMono(XSLFSlide slide, JsonNode lines, int y) {
        XSLFTextBox box = slide.createTextBox();
        box.setAnchor(new Rectangle(60, y, W - 120, 24 * lines.size() + 12));
        for (JsonNode line : lines) {
            XSLFTextRun r = box.addNewTextParagraph().addNewTextRun();
            r.setText(line.asText());
            r.setFontFamily("Menlo");
            r.setFontSize(14.0);
            r.setFontColor(ACCENT);
        }
    }

    /**
     * Renders **bold**, `code` and [label](url) as separate runs. The schema
     * keeps these markers raw in text fields; styling is the renderer's job.
     */
    private void addRuns(XSLFTextParagraph p, String text, int size,
                         Color color, boolean bold) {
        Matcher m = INLINE.matcher(text);
        int last = 0;
        while (m.find()) {
            if (m.start() > last) {
                run(p, text.substring(last, m.start()), size, color, bold, false, null);
            }
            String tok = m.group();
            if (tok.startsWith("**")) {
                run(p, tok.substring(2, tok.length() - 2), size, color, true, false, null);
            } else if (tok.startsWith("`")) {
                run(p, tok.substring(1, tok.length() - 1), size, ACCENT, bold, true, null);
            } else {
                Matcher lm = LINK.matcher(tok);
                if (lm.matches()) {
                    run(p, lm.group(1), size, ACCENT, bold, false, lm.group(2));
                }
            }
            last = m.end();
        }
        if (last < text.length()) {
            run(p, text.substring(last), size, color, bold, false, null);
        }
    }

    private void run(XSLFTextParagraph p, String text, int size, Color color,
                     boolean bold, boolean mono, String href) {
        XSLFTextRun r = p.addNewTextRun();
        r.setText(text);
        r.setFontSize((double) size);
        r.setFontColor(color);
        r.setBold(bold);
        if (mono) r.setFontFamily("Menlo");
        if (href != null) {
            r.setUnderlined(true);
            r.createHyperlink().setAddress(href);
        }
    }
}
```

- [ ] **Step 4: Copy the golden fixture and run the tests**

```bash
mkdir -p ~/code/fivex/mod_java/src/test/resources/lecture
cp /Users/michael/code/uvu/tools/course_builder/test/fixtures/decks/fenced-deck.golden.json \
   ~/code/fivex/mod_java/src/test/resources/lecture/fenced-deck.json
cd ~/code/fivex/mod_java && ./gradlew test --tests 'com.fivex.module.lecture.LectureDeckRendererTest'
```
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
cd ~/code/fivex/mod_java
git add src/main/java/com/fivex/module/lecture/LectureDeckRenderer.java \
        src/test/java/com/fivex/module/lecture/LectureDeckRendererTest.java \
        src/test/resources/lecture/fenced-deck.json
git commit -m "feat(lecture): POI renderer with hyperlink support"
```

---

### Task 10: Renderer endpoint and CLI wiring

**Files:**
- Create: `~/code/fivex/mod_java/src/main/java/com/fivex/module/lecture/LectureRenderController.java`
- Create: `~/code/fivex/mod_java/src/test/java/com/fivex/module/lecture/LectureRenderControllerTest.java`
- Modify: `tools/course_builder/bin/build_lectures.dart`

**Interfaces:**
- Consumes: `LectureDeckRenderer.render` (Task 9)
- Produces: `POST /api/lecture/render` returning `application/vnd.openxmlformats-officedocument.presentationml.presentation`. CLI flag `--render <base-url>` posts each document and writes the returned `.pptx` beside the deck.

- [ ] **Step 1: Write the failing controller test**

```java
package com.fivex.module.lecture;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class LectureRenderControllerTest {

    @Autowired MockMvc mvc;

    @Test
    void rendersPptxFromPostedLectureJson() throws Exception {
        String body = Files.readString(
            Path.of("src/test/resources/lecture/fenced-deck.json"));
        mvc.perform(post("/api/lecture/render")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
           .andExpect(status().isOk())
           .andExpect(header().string("Content-Type",
               "application/vnd.openxmlformats-officedocument.presentationml.presentation"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ~/code/fivex/mod_java && ./gradlew test --tests 'com.fivex.module.lecture.LectureRenderControllerTest'`
Expected: FAIL — 404, no such endpoint.

- [ ] **Step 3: Write the controller**

```java
package com.fivex.module.lecture;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/lecture")
public class LectureRenderController {

    private static final String PPTX =
        "application/vnd.openxmlformats-officedocument.presentationml.presentation";

    private final LectureDeckRenderer renderer = new LectureDeckRenderer();

    @PostMapping(value = "/render", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<byte[]> render(@RequestBody JsonNode lecture) throws Exception {
        String id = lecture.path("id").asText("lecture");
        byte[] pptx = renderer.render(lecture);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_TYPE, PPTX)
            .header(HttpHeaders.CONTENT_DISPOSITION,
                    "attachment; filename=\"" + id + ".pptx\"")
            .body(pptx);
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd ~/code/fivex/mod_java && ./gradlew test --tests 'com.fivex.module.lecture.LectureRenderControllerTest'`
Expected: PASS.

- [ ] **Step 5: Add the --render flag to the CLI**

In `bin/build_lectures.dart`, add this function above `main`:

```dart
Future<void> renderDecks(
  String baseUrl,
  String outDir,
  List<Lecture> lectures,
  String slidesDir,
) async {
  final client = HttpClient();
  for (final l in lectures) {
    final body = File(p.join(outDir, '${l.id}.json')).readAsStringSync();
    final req = await client.postUrl(Uri.parse('$baseUrl/api/lecture/render'));
    req.headers.contentType = ContentType.json;
    req.write(body);
    final res = await req.close();
    if (res.statusCode != 200) {
      stderr.writeln('render failed for ${l.id}: HTTP ${res.statusCode}');
      exit(1);
    }
    final bytes = await res.fold<List<int>>(<int>[], (b, d) => b..addAll(d));
    File(p.join(slidesDir, '${l.id}.pptx')).writeAsBytesSync(bytes);
    stdout.writeln('rendered ${l.id}.pptx');
  }
  client.close();
}
```

Change the signature to `Future<void> main(List<String> args) async` and insert before the final summary line:

```dart
  final renderBase = _arg(args, '--render', '');
  if (renderBase.isNotEmpty) {
    await renderDecks(renderBase, outDir, lectures, slidesDir);
  }
```

- [ ] **Step 6: Verify the CLI test still passes**

Run: `cd /Users/michael/code/uvu/tools/course_builder && dart test test/bin/build_lectures_test.dart`
Expected: PASS — the `--render` flag is absent, so rendering is skipped.

- [ ] **Step 7: Commit both repos**

```bash
cd ~/code/fivex/mod_java
git add src/main/java/com/fivex/module/lecture/LectureRenderController.java \
        src/test/java/com/fivex/module/lecture/LectureRenderControllerTest.java
git commit -m "feat(lecture): POST /api/lecture/render endpoint"

cd /Users/michael/code/uvu/tools/course_builder
git add bin/build_lectures.dart
git commit -m "feat(lecture): --render posts documents to the Java renderer"
```

---

### Task 11: pptx parity, then remove Python

**Files:**
- Delete: `content/cs3540/2026/lectures/slides/build_pptx.py`, `__pycache__/`, `.venv/`
- Delete: `content/cs3540/2026/lectures/slides/diagramkit.py` (only if Step 3 proves it unused)
- Modify: `content/cs3540/2026/lectures/slides/README.md`, `.gitignore`

**Interfaces:**
- Consumes: everything above
- Produces: a pipeline with no Python in it

- [ ] **Step 1: Capture the Python baseline**

```bash
cd content/cs3540/2026/lectures/slides
./.venv/bin/python build_pptx.py
mkdir -p /tmp/pptx-baseline && cp w*.pptx /tmp/pptx-baseline/
ls /tmp/pptx-baseline | wc -l
```
Expected: `28`

- [ ] **Step 2: Render with Java and compare notes text**

Start `mod_java` (`cd ~/code/fivex/mod_java && ./gradlew bootRun`). Then from `tools/course_builder`:

```bash
dart run bin/build_lectures.dart --render http://localhost:8080
./content/cs3540/2026/lectures/slides/.venv/bin/python - <<'EOF'
from pptx import Presentation
import pathlib, sys
fail = 0
for new in sorted(pathlib.Path('content/cs3540/2026/lectures/slides').glob('w*.pptx')):
    old = pathlib.Path('/tmp/pptx-baseline') / new.name
    a, b = Presentation(old), Presentation(new)
    if len(a.slides) != len(b.slides):
        print(f'{new.name}: SLIDE COUNT {len(a.slides)} -> {len(b.slides)}')
        fail += 1
        continue
    for i, (sa, sb) in enumerate(zip(a.slides, b.slides), 1):
        ta = sa.notes_slide.notes_text_frame.text.strip() if sa.has_notes_slide else ''
        tb = sb.notes_slide.notes_text_frame.text.strip() if sb.has_notes_slide else ''
        if ta != tb:
            print(f'{new.name} slide {i}: NOTES MISMATCH')
            fail += 1
print('PPTX PARITY OK' if not fail else f'FAILED ({fail})')
sys.exit(1 if fail else 0)
EOF
```
Expected: `PPTX PARITY OK`, exit 0. **Do not proceed if this fails** — fix the renderer.

- [ ] **Step 3: Check whether diagramkit.py is still referenced**

Run: `grep -rn "diagramkit" content/cs3540/2026/lectures/slides/`
If the only hits are inside `build_pptx.py` and the README, it dies with them. If anything else uses it, **keep it and say so in the handoff** — do not delete a file you have not proven unused.

- [ ] **Step 4: Open one rendered deck and check it by eye**

Run: `open content/cs3540/2026/lectures/slides/w03-ai-skills.pptx`
Confirm: slides render, the notes pane holds the script, and any link is clickable. Automated parity covers notes text only; layout needs a human look before the Python baseline is destroyed.

- [ ] **Step 5: Remove Python**

```bash
cd content/cs3540/2026/lectures/slides
rm -rf .venv __pycache__ build_pptx.py
rm -f diagramkit.py     # only if Step 3 proved it unused
rm -f /tmp/parity_check.py
sed -i '' '/^\.venv\/$/d' .gitignore
cat .gitignore
```
Expected: `.gitignore` now lists `*.pptx`, `_render/`, `_lectures/`.

- [ ] **Step 6: Update the README build section**

Replace the `## Build` section of `content/cs3540/2026/lectures/slides/README.md` with:

<pre>
## Build

The deck markdown is parsed by `course_builder` (Dart) -- the only parser in the
pipeline. It emits `_lectures/lectures.json` plus one JSON document per lecture,
each validated against `schemas/lecture.schema.json`. The `.pptx` is rendered from
that JSON by `mod_java` (Apache POI).

```bash
cd tools/course_builder
dart run bin/build_lectures.dart                                 # JSON only
dart run bin/build_lectures.dart --render http://localhost:8080  # JSON + .pptx
```

`_lectures/` and `*.pptx` are gitignored: the markdown is the source, everything
else is a build artifact.
</pre>

- [ ] **Step 7: Full test sweep**

```bash
cd /Users/michael/code/uvu/tools/course_builder && dart test
cd ~/code/fivex/mod_java && ./gradlew test --tests 'com.fivex.module.lecture.*'
cd ~/code/fivex/mod_node && npx jest modules/lecture
```
Expected: all green.

- [ ] **Step 8: Commit**

```bash
cd /Users/michael/code/uvu/tools/course_builder
git add -A content/cs3540/2026/lectures/slides
git commit -m "refactor(lecture): remove Python renderer, Dart parses and Java renders"
```

---

## Definition of Done

- `dart run bin/build_lectures.dart` emits 28 lecture documents + index: 253 slides, 31,946 words, zero unscripted slides.
- Every generated document validates against `schemas/lecture.schema.json` in Dart (`json_schema`) and in `mod_node` (`ajv`).
- All 28 `.pptx` render from JSON via `mod_java` with notes text identical to the Python baseline, and inline links render as real hyperlinks.
- No `.py` file and no `.venv` remains under `content/cs3540/2026/lectures/slides/`.
- No `NOTES:` text was modified by this plan.
