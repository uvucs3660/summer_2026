# CS 3540 Persona Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite all 253 slide scripts across 28 CS 3540 decks in the balanced Torvalds/Williams/Amodei voice, in place, without changing slide structure, deadlines, or technical claims.

**Architecture:** The rewrite edits `NOTES:` blocks inside `content/cs3540/2026/lectures/slides/w*.md`. Decks remain the single source of truth; `lectures.json` regenerates from them. A guardrail tool compares each rewritten deck against its committed version and fails on any structural or factual drift, so the human review can spend its attention on voice rather than on counting slides.

**Tech Stack:** Dart 3 (guardrail tool, `package:test`), markdown editing.

**Spec:** `tools/course_builder/docs/superpowers/specs/2026-08-27-cs3540-lecture-delivery-design.md` (section 4)

## Global Constraints

**Run this plan only after the pipeline plan (`2026-08-27-cs3540-lecture-pipeline.md`) is complete.** That plan freezes script content and compares Java output against a Python baseline; rewriting scripts while it runs makes every parity failure ambiguous.

Rules from spec section 4.3, which govern every task in this plan:

1. **Never sacrifice the technical claim for the joke.** If a rewrite makes a statement less precise, the rewrite is wrong.
2. **No jokes mid-derivation.** On dense decks, wit lands at section boundaries and payoffs, never between two steps of a proof. Decks flagged DENSE below.
3. **Length runs to what the material warrants.** The ~+20% is an observed average, not a target. Do not pad, do not trim.
4. **Written to be spoken.** No parentheticals, no bullet-like prose, no constructions requiring punctuation the ear cannot hear.
5. **Keep every structural cue.** Signposting like "here is the load-bearing sentence" is a pedagogical device and survives the rewrite.
6. **Dates, deadlines, assignment names and URLs are copied verbatim**, never paraphrased.

Additional hard constraints:

- **Slide count per deck must not change.** Do not add, remove, merge or reorder slides. Slide identity is positional.
- **Do not edit anything above a `NOTES:` marker.** Slide bodies, headings, bullets, code blocks and frontmatter are out of scope.
- **Every slide must still have a script.** Zero unscripted slides at the end of every task.
- Working directory for all commands: `/Users/michael/code/uvu/tools/course_builder`.
- One commit per deck, so any deck can be reverted alone.

## The Reference Standard

The approved calibration sample, from `w03-ai-skills`. Every rewrite is measured against this:

> Mechanically? A skill is a folder. With a markdown file in it. I want you to sit with how unimpressive that is, because in about four weeks someone is going to try to sell you a course on it.
>
> Two fields matter — name, description. Below that, the body: ordinary markdown, the actual procedure.
>
> Now here is the load-bearing sentence. The frontmatter is a contract about WHEN this fires. The body is WHAT it does. And everybody — everybody — pours themselves into the body and dashes off the description in eight seconds on the way out the door.
>
> Which is exactly backwards. You have built a gorgeous room with no door. Chandeliers. Parquet floors. Sealed. Nobody is getting in there, ever, and the model walks past it for the rest of its life without knowing it existed.

The voice: **Torvalds** supplies bluntness and refusal to be impressed — short declaratives, naming what is actually dumb. **Williams** supplies escalation and imagery — a plain observation growing into a concrete, slightly absurd picture. **Amodei** supplies the pause for consequence — *sit with why this matters*, plainly and without hype.

## The Rewrite Procedure

Every deck task runs these seven steps. They are written once here; each task supplies the deck and its specifics.

**P1.** Read the whole deck first, start to finish, before editing anything. The wit has to be distributed across the deck, not applied per-slide — a joke on every slide is exhausting, and a deck with all its energy in the first three slides dies.

**P2.** For each slide, rewrite only the text after `NOTES:`. Preserve every deadline, date, assignment name and URL character-for-character. Leave slide bodies untouched.

**P3.** Read the rewritten script **aloud**. It is a recording script; anything that trips the tongue gets rewritten. This is not optional — it is the only check that catches unspeakable prose.

**P4.** Run the guardrail: `dart run tool/rewrite_check.dart <deck-id>`. It must report OK.

**P5.** Regenerate the JSON and confirm the corpus is intact: `dart run bin/build_lectures.dart`.

**P6.** Report the deck's before/after word count and estimated runtime. Do not adjust the writing to hit a number — report what it landed at.

**P7.** Commit that deck alone.

---

### Task 1: Guardrail tool

Catches structural and factual drift so human review can spend its attention on voice. Compares the working-tree deck against its committed version.

**Files:**
- Create: `tool/rewrite_check.dart`
- Test: `test/tool/rewrite_check_test.dart`
- Create: `test/fixtures/decks/rewrite-before.md`, `test/fixtures/decks/rewrite-after-ok.md`, `test/fixtures/decks/rewrite-after-bad.md`

**Interfaces:**
- Consumes: `loadDeck` from `lib/src/loaders/deck_loader.dart` (pipeline plan, Task 3)
- Produces: `RewriteReport compareDecks(String beforePath, String afterPath)` with fields `slideCountChanged`, `unscriptedSlides`, `bodyChanges`, `missingTokens`, `beforeWords`, `afterWords`, and `bool get ok`. CLI `dart run tool/rewrite_check.dart <deck-id>` exits 1 when not ok.

- [ ] **Step 1: Create the fixtures**

`test/fixtures/decks/rewrite-before.md`:

<pre>
---
track: ai
week: 9
title: Fixture
---

# One

- A bullet

NOTES:
Plain script. Due Sun Sep 21. See https://example.com/x

---

# Two

NOTES:
Second plain script.
</pre>

`test/fixtures/decks/rewrite-after-ok.md` — same body, rewritten scripts, deadline and URL intact:

<pre>
---
track: ai
week: 9
title: Fixture
---

# One

- A bullet

NOTES:
Rewritten script with more life in it. Due Sun Sep 21. See https://example.com/x

---

# Two

NOTES:
Second rewritten script, also livelier.
</pre>

`test/fixtures/decks/rewrite-after-bad.md` — deadline dropped, URL mangled, a bullet edited:

<pre>
---
track: ai
week: 9
title: Fixture
---

# One

- A bullet that was edited

NOTES:
Rewritten script that forgot when it is due.

---

# Two

NOTES:
Second rewritten script.
</pre>

- [ ] **Step 2: Write the failing test**

```dart
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `dart test test/tool/rewrite_check_test.dart`
Expected: FAIL — `tool/rewrite_check.dart` does not exist.

- [ ] **Step 4: Write the implementation**

```dart
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dart test test/tool/rewrite_check_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 6: Sanity-check against an unmodified real deck**

Run: `dart run tool/rewrite_check.dart w13-ai-plugins`
Expected: `OK`, with `words 552 -> 552 (+0%)`. A clean deck must pass — if it does not, the tool is wrong.

- [ ] **Step 7: Commit**

```bash
git add tool/rewrite_check.dart test/tool/rewrite_check_test.dart \
        test/fixtures/decks/rewrite-before.md \
        test/fixtures/decks/rewrite-after-ok.md \
        test/fixtures/decks/rewrite-after-bad.md
git commit -m "feat(lecture): guardrail comparing rewritten decks against HEAD"
```

---

### Task 2: Pilot deck — w03-ai-skills (HUMAN REVIEW GATE)

10 slides, 1,281 words, ~9.2 min. This deck is the pilot because the approved reference sample was written from its slide 4.

**Files:**
- Modify: `content/cs3540/2026/lectures/slides/w03-ai-skills.md`

**Interfaces:**
- Consumes: the guardrail from Task 1
- Produces: the calibrated voice every subsequent deck matches, plus the human's confirmation that it is right

- [ ] **Step 1: Run procedure P1** — read all 10 slides start to finish before editing.

- [ ] **Step 2: Run procedure P2** — rewrite each `NOTES:` block. Slide 4's script must match the approved reference sample in this plan. Preserve the Forge 02 deadline on the final slide verbatim.

- [ ] **Step 3: Run procedure P3** — read the whole deck aloud.

- [ ] **Step 4: Run procedure P4**

Run: `dart run tool/rewrite_check.dart w03-ai-skills`
Expected: `OK`. Investigate any missing-token report before continuing — a dropped deadline is a factual error reaching students.

- [ ] **Step 5: Run procedure P5**

Run: `dart run bin/build_lectures.dart`
Expected: `28 lectures, 253 slides, <n> words` with the word total risen and slide count still 253.

- [ ] **Step 6: STOP for human review**

Present to the human: the full rewritten deck, its before/after word count, and its new estimated runtime.

**Do not proceed to Task 3 until the human approves the voice.** This is the entire purpose of a pilot — 27 decks rewritten in a voice that turns out to be wrong is 27 decks of rework. If the human asks for adjustment, revise this deck and re-present. Update the Reference Standard section of this plan with the corrected sample so later tasks calibrate against what was actually approved.

- [ ] **Step 7: Commit**

```bash
git add content/cs3540/2026/lectures/slides/w03-ai-skills.md
git commit -m "content(cs3540): persona rewrite of w03-ai-skills (pilot)"
```

---

### Tasks 3-16: The remaining 27 decks

Each task rewrites one week's decks using **The Rewrite Procedure** (P1-P7 above) and the approved Reference Standard. Every task independently runs the guardrail and commits per deck.

Decks marked **DENSE** carry technical derivations. On those, apply rule 2 strictly: wit at section boundaries and payoffs only, never between two steps of a derivation. When in doubt on a dense deck, choose clarity — a lecture that is slightly less funny is recoverable; a student who lost the thread of the fixed-timestep derivation is not.

| Task | Week | Decks | Slides | Words | Notes |
|---|---|---|---|---|---|
| 3 | 1 | `w01-game-first-contact`, `w01-ai-eleven-pillars` | 9, 7 | 1119, 647 | First impression of the course — the voice students meet first |
| 4 | 2 | `w02-game-the-loop`, `w02-ai-claude-md` | 20, 15 | 3099, 2274 | **DENSE** (the-loop: fixed timestep + accumulator derivation). Largest task in the plan |
| 5 | 3 | `w03-game-determinism` | 15 | 1842 | **DENSE**. The AI deck for W3 was the pilot |
| 6 | 4 | `w04-game-engine-seams`, `w04-ai-writing-a-spec` | 10, 9 | 1415, 1150 | engine-seams references the Sep 13 claim deadline — preserve verbatim |
| 7 | 5 | `w05-game-patterns-and-components`, `w05-ai-subagents` | 12, 10 | 1457, 1245 | **DENSE** (patterns-and-components) |
| 8 | 6 | `w06-game-pixels`, `w06-ai-hooks` | 8, 7 | 973, 858 | **DENSE** (pixels) |
| 9 | 7 | `w07-game-contact`, `w07-ai-mcp` | 8, 7 | 933, 792 | **DENSE** (contact: collision math) |
| 10 | 8 | `w08-game-feel`, `w08-ai-divergence` | 8, 7 | 1179, 835 | |
| 11 | 9 | `w09-game-space`, `w09-ai-model-selection` | 9, 6 | 1069, 635 | **DENSE** (space) |
| 12 | 10 | `w10-game-minds`, `w10-ai-spec-plan-execution` | 8, 7 | 1043, 785 | |
| 13 | 11 | `w11-game-worlds`, `w11-ai-soul-prompts` | 9, 7 | 1103, 824 | |
| 14 | 12 | `w12-game-story`, `w12-ai-the-council` | 10, 6 | 1279, 678 | |
| 15 | 13 | `w13-game-distance`, `w13-ai-plugins` | 10, 6 | 1139, 552 | **DENSE** (distance: netcode) |
| 16 | 14 | `w14-game-shipping`, `w14-ai-guarded-agent` | 7, 6 | 825, 915 | Final decks — both close out their track; keep the callbacks |

For each deck in a task:

- [ ] **Step 1: P1** — read the whole deck before editing.
- [ ] **Step 2: P2** — rewrite every `NOTES:` block; bodies and frontmatter untouched; deadlines, dates, assignment names and URLs verbatim.
- [ ] **Step 3: P3** — read it aloud.
- [ ] **Step 4: P4** — `dart run tool/rewrite_check.dart <deck-id>` must report `OK`.
- [ ] **Step 5: P5** — `dart run bin/build_lectures.dart` must still report 28 lectures and 253 slides.
- [ ] **Step 6: P6** — report before/after words and estimated runtime for the deck.
- [ ] **Step 7: P7** — commit that deck alone:

```bash
git add content/cs3540/2026/lectures/slides/<deck-id>.md
git commit -m "content(cs3540): persona rewrite of <deck-id>"
```

---

### Task 17: Corpus verification and regeneration

**Files:**
- Modify: none (verification only)

**Interfaces:**
- Consumes: all 28 rewritten decks
- Produces: the final corpus figures for the record

- [ ] **Step 1: Verify every deck against its pre-rewrite state**

```bash
for f in content/cs3540/2026/lectures/slides/w*.md; do
  id=$(basename "$f" .md)
  git diff --quiet "$f" || echo "UNCOMMITTED: $id"
done
```
Expected: no output — every deck committed.

- [ ] **Step 2: Confirm structure survived across the whole corpus**

Run: `dart run tool/corpus_check.dart`
Expected: `decks=28 slides=253 words=<new total> links=<n> unscripted=0`

**Slides must still be 253 and unscripted must be 0.** Any other value means a deck lost or gained structure and must be found and fixed before proceeding.

- [ ] **Step 3: Regenerate JSON and pptx**

Start `mod_java`, then:

```bash
dart run bin/build_lectures.dart --render http://localhost:8080
```
Expected: 28 lectures emitted and 28 `.pptx` rendered, no validation errors.

- [ ] **Step 4: Spot-check two decks by eye**

Run:
```bash
open content/cs3540/2026/lectures/slides/w02-game-the-loop.pptx
open content/cs3540/2026/lectures/slides/w13-ai-plugins.pptx
```
Confirm the notes pane holds the rewritten script on the longest DENSE deck and on the shortest deck.

- [ ] **Step 5: Report the final figures**

Report: total words before (31,946) and after, percent change, new estimated total runtime at 140 wpm, and the per-deck runtime table. Per spec section 4.3 rule 3, report what the material landed at — do not adjust writing to hit a number.

---

## Definition of Done

- All 28 decks rewritten in the approved voice, one commit each.
- `dart run tool/corpus_check.dart` reports 253 slides and 0 unscripted slides.
- `dart run tool/rewrite_check.dart` reported OK for every deck, with no missing verbatim tokens.
- No slide body, heading, code block or frontmatter was modified.
- JSON and `.pptx` regenerate cleanly from the rewritten decks.
- Final word count and runtime reported per deck and in total.
