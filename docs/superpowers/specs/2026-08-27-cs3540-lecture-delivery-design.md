# CS 3540 Lecture Delivery System — Design

**Date:** 2026-08-27
**Status:** Approved design, pending implementation plan
**Scope:** `tools/course_builder` (producer), `~/code/fivex/mod_java` (pptx renderer),
`~/code/fivex/mod_node` (audio + tracking), a Flutter player app

## 1. Problem

CS 3540's 28 lecture decks are fully scripted — 253 slides, 31,946 words, roughly
3.8 hours of narration at 140 wpm — but the script exists only as `NOTES:` blocks
inside deck markdown, and the only build artifact is a `.pptx`. There is no way for
a student to watch a lecture, and no way for the instructor to know whether they did.

This design turns the decks into a structured, machine-readable lecture corpus that
can be narrated by synthesized speech, rendered by a player app, and tracked.

Note: CS 3660's 13 Marp decks carry **zero** speaker notes and therefore cannot feed
this pipeline. This design is CS 3540 only.

## 2. Decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | Sequence: ① scripts + schema + JSON → ② ElevenLabs → ③ Flutter → ④ tracking | Each stage's output is the next stage's input |
| 2 | Persona voice: **balanced** Torvalds/Williams/Amodei blend, ~+20% length | Seasoned, not transformed; see §4 |
| 3 | Decks remain single source of truth; JSON is generated | Preserves `slides/README.md`'s no-drift rule |
| 4 | One mp3 per lecture + per-slide timestamps | Seamless prosody, one scrubbable timeline |
| 5 | Video: `mode: pip\|fullscreen` × `audio: video\|narration` | Two orthogonal axes cover all four useful cases |
| 6 | Dart produces, Java/POI renders — **no Python anywhere** | Platform languages only |
| 7 | Slide identity is **positional** (`index`) | Simplicity; inserted slides are unlikely |

## 3. Architecture

`lectures.json` is a contract between three languages. Exactly one component parses
deck markdown; everything else consumes already-parsed JSON.

```
                 slides/w*.md  (28 decks, persona NOTES:)
                        |
                        |  THE ONLY PARSER
                        v
        course_builder (Dart) ---> lectures.json + 28 per-lecture JSON
                                            |
              +-----------------------------+-----------------------------+
              |                             |                             |
              v                             v                             v
   mod_java + POI (Java)          mod_node module (TS)            player app (Flutter)
   JSON -> .pptx                  JSON -> ElevenLabs -> mp3       JSON + media -> UI
                                  + slide timings -> minio        + view events -> ④
```

### 3.1 Why the parser moved

`build_pptx.py` is currently both a parser and a renderer. Any consumer in another
language would have to re-implement the parsing half — including the subtle rule at
`build_pptx.py:46` that a lone `---` inside a fenced code block is **not** a slide
break. Three decks (`w03-ai-skills`, `w04-ai-writing-a-spec`, `w02-ai-claude-md`)
teach YAML frontmatter by showing it inside a fence, so a naive splitter shatters
exactly the slides that demonstrate the concept, and fails silently.

Parser ownership is expensive to reverse; renderer language is cheap once JSON sits
in between. So the parser moves to the producer, and the renderer becomes a leaf.

### 3.2 Component responsibilities

| Component | Language | Responsibility | Depends on |
|---|---|---|---|
| `course_builder` | Dart 3 | Parse decks, emit JSON, validate against schema | none |
| pptx renderer | Java 21 / POI | JSON → `.pptx` with speaker notes | `lectures.json` |
| lecture-audio module | TypeScript | JSON → ElevenLabs → mp3 + timings → minio | `lectures.json` |
| player app | Flutter | Render slides, play audio/video, emit view events | JSON + minio |
| tracking | TypeScript + postgres | Store per-student view records | player events |

## 4. Stage ① — Persona rewrite

### 4.1 The voice

A single blended narrator, not three characters. One ElevenLabs voice narrates, so
three distinct speakers would have nothing to speak through.

- **Torvalds** supplies bluntness and the refusal to be impressed. Short declaratives.
  Naming the thing that is actually dumb.
- **Williams** supplies escalation and imagery — a plain observation grows into a
  concrete, slightly absurd picture that makes the point stick.
- **Amodei** supplies the pause for consequence: *sit with why this matters*, stated
  plainly and without hype.

### 4.2 Reference standard

The approved calibration sample, rewritten from `w03-ai-skills`:

> Mechanically? A skill is a folder. With a markdown file in it. I want you to sit
> with how unimpressive that is, because in about four weeks someone is going to try
> to sell you a course on it.
>
> Two fields matter — name, description. Below that, the body: ordinary markdown,
> the actual procedure.
>
> Now here is the load-bearing sentence. The frontmatter is a contract about WHEN
> this fires. The body is WHAT it does. And everybody — everybody — pours themselves
> into the body and dashes off the description in eight seconds on the way out the door.
>
> Which is exactly backwards. You have built a gorgeous room with no door.
> Chandeliers. Parquet floors. Sealed. Nobody is getting in there, ever, and the model
> walks past it for the rest of its life without knowing it existed.

### 4.3 Rules

1. **Never sacrifice the technical claim for the joke.** If a rewrite makes a
   statement less precise, the rewrite is wrong.
2. **No jokes mid-derivation.** On dense decks (`w02-game-the-loop`,
   `w03-game-determinism`), wit lands at section boundaries and payoffs, never
   between two steps of a proof.
3. **Length runs to what the material warrants** — the +20% is an observed average,
   not a target. Do not pad and do not trim to hit it.
4. **Written to be spoken.** No parentheticals, no bullet-like prose, no constructions
   that require punctuation the ear cannot hear.
5. **Keep every existing structural cue** — the "here is the load-bearing sentence"
   style signposting is a pedagogical device and survives the rewrite.
6. **Dates, deadlines, and assignment references are copied verbatim**, never
   paraphrased.

### 4.4 Method

Rewrite is in place, one deck at a time, replacing each `NOTES:` block. The neutral
original stays recoverable from git history. Regenerate the `.pptx` after each deck
and confirm slide count is unchanged.

## 5. Stage ① — Artifacts

```
tools/course_builder/
  lib/src/loaders/deck_loader.dart      NEW  fence-aware split + typed blocks
  lib/src/models/lecture.dart           NEW  Lecture / Slide / Block
  lib/src/emitters/lectures_json.dart   NEW  index + per-lecture emission
  bin/build_lectures.dart               NEW  CLI (mirrors build_canvas_zip.dart)
  schemas/lecture.schema.json           NEW  the cross-language contract
  test/deck_loader_test.dart            NEW  fenced-code regression tests

  content/cs3540/2026/lectures/slides/
    w*.md                               MOD  persona NOTES:
    _lectures/                          NEW  generated output, gitignored
      lectures.json
      w01-game-first-contact.json  … (28 files)
    build_pptx.py                       DELETE (replaced by Java renderer)
    .venv/                              DELETE
```

`_lectures/` follows the existing `_render/` convention — leading underscore signals
build output. Add `_lectures/` to `slides/.gitignore`, which already carries
`.venv/`, `*.pptx`, `_render/`.

Audio and video are **never** committed: ~4.6 hours of mp3 is several hundred MB.
They live in minio and are referenced by object key.

## 6. The schema

Canonical location `tools/course_builder/schemas/lecture.schema.json`. Per the root
`CLAUDE.md` rule "Change JSON schemas producer-first", `course_builder` owns it;
`mod_node` (via `ajv`, already a dependency) and the Flutter app hold copies that
must match.

### 6.1 Index — `lectures.json`

```json
{
  "schema_version": "1.0.0",
  "course": "cs3540",
  "year": 2026,
  "lectures": [
    {
      "id": "w03-ai-skills",
      "week": 3,
      "track": "ai",
      "title": "Skills",
      "subtitle": "The Description Is the Product",
      "slide_count": 10,
      "word_count": 1281,
      "duration_ms": 549000,
      "file": "w03-ai-skills.json"
    }
  ]
}
```

`duration_ms` is the estimate at 140 wpm until stage ② replaces it with the measured
value from synthesis.

### 6.2 Per-lecture document

```json
{
  "schema_version": "1.0.0",
  "id": "w03-ai-skills",
  "course": "cs3540",
  "year": 2026,
  "week": 3,
  "track": "ai",
  "title": "Skills",
  "subtitle": "The Description Is the Product",
  "source": {
    "deck": "content/cs3540/2026/lectures/slides/w03-ai-skills.md",
    "script_hash": "sha256:9f2c1e…"
  },
  "audio": {
    "key": "cs3540/2026/lectures/w03-ai-skills.mp3",
    "duration_ms": 549000,
    "voice": "michael",
    "model": "eleven_v3",
    "script_hash": "sha256:9f2c1e…",
    "generated_at": "2026-08-27T18:04:11Z"
  },
  "video": {
    "intro": null,
    "outro": null
  },
  "slides": [
    {
      "index": 7,
      "heading": "Progressive disclosure",
      "blocks": [
        {
          "type": "bullets",
          "items": [
            { "depth": 0, "text": "The frontmatter is the **contract**" },
            { "depth": 1, "text": "The body is the **content**" }
          ]
        },
        { "type": "code", "lang": "yaml", "lines": ["name: open-pr"] }
      ],
      "script": "Now here is the load-bearing sentence…",
      "audio_span": { "start_ms": 411200, "end_ms": 452400 },
      "reveals": [ { "block": 0, "at_ms": 3100 } ],
      "video": {
        "key": "cs3540/2026/lectures/w03/s07.mp4",
        "mode": "pip",
        "audio": "narration",
        "position": "bottom-right",
        "duration_ms": 134000
      }
    }
  ]
}
```

### 6.3 Block types

Mirrors `parse_blocks` exactly — no invented vocabulary.

| `type` | Fields |
|---|---|
| `title` | `text` |
| `subtitle` | `text` |
| `bullets` | `items[]` of `{depth: 0\|1, text}` |
| `code` | `lang`, `lines[]` |
| `image` | `src` |
| `quote` | `text` |
| `para` | `text` |

Inline `**bold**` and `` `code` `` markers are preserved raw in `text`; each renderer
decides how to style them, as `build_pptx.py:135` does today with its run splitter.

### 6.4 Field semantics that carry weight

- **`script_hash`** appears twice — once under `source` (hash of the script as it is
  now) and once under `audio` (hash of the script the audio was generated from).
  When they differ, the audio is stale. Without this, "one mp3 per deck" would have
  no way to know a 3,099-word deck needs re-synthesis except by memory.
- **`key`, not `path`** — media resolves against a minio base URL at runtime, so the
  same JSON works locally, in dev, and in prod.
- **`heading` beside `index`** — slide identity is positional, so a consumer that
  stores both can detect after the fact that slides shifted. Costs nothing.
- **`reveals` references a block index** rather than embedding timing inside blocks,
  keeping the block array a faithful mirror of the parser output for renderers that
  do not animate.
- **`video.mode` × `video.audio`** are independent:

  | mode | audio | Result |
  |---|---|---|
  | `pip` | `narration` | Muted demo footage in the corner, TTS narrates over it |
  | `pip` | `video` | Talking head speaks; narration suspends |
  | `fullscreen` | `video` | Video takes the screen and the floor |
  | `fullscreen` | `narration` | Full-bleed silent footage under TTS |

  Any slide whose effective audio source is `video` is **excluded from synthesis**,
  so the narration track carries a gap there and the player suspends the timeline.

### 6.5 Validation

`build_lectures.dart` validates its own output against the schema before writing.
The `mod_node` module re-validates on read via `ajv`. A `schema_version` mismatch is
a hard failure, never a silent degrade.

## 7. Stage ① — pptx renderer (Java / POI)

`build_pptx.py` is deleted and replaced by a Java renderer consuming `lectures.json`.

**Placement.** `mod_java` follows a `com/fivex/module/<name>/` convention (existing
siblings include `anvil`, `build`, `docs`, `estimator`, `git`), so the renderer lands
as `com.fivex.module.lecture`. Apache POI is **not** currently a `build.gradle`
dependency and must be added.

**Invocation.** `mod_java` is a Spring Boot server, not a batch CLI, so the renderer
is exposed as an endpoint that accepts a lecture document and returns a `.pptx`.
Deck rendering becomes a platform capability rather than a local script; the
`course_builder` CLI calls it after emitting JSON.

**Verified POI capability:** `XMLSlideShow` → `createSlide()` → `createTextBox()` →
`XSLFTextParagraph` → `XSLFTextRun` with `setFontColor`, `setFontSize`, `setBold`,
`setItalic` covers the styled-run rendering `build_pptx.py:135` does today. Slide
size is settable in points.

**Unverified and therefore a prerequisite spike:** creating a *notes slide* on a
presentation built from scratch. POI's `XSLFNotes` is documented mainly for reading;
the `setNotes()` API found in the docs belongs to `HSLFSlide` (legacy binary `.ppt`).
`python-pptx` auto-creates the notes slide, which is what the current build relies on
at `build_pptx.py:301`. Since the speaker notes **are** the script, this must be
proven before the rewrite.

**Spike:** build a deck with POI and set speaker notes on a slide. If it requires a
notes master, produce a minimal template `.pptx` carrying one and load it as the
starting point. Deliverable: a one-slide `.pptx` whose notes pane opens correctly in
PowerPoint and Keynote. If neither path works, the renderer decision is revisited
before any rewrite is done — not after.

**Acceptance:** all 28 decks regenerate from JSON with slide counts and notes text
identical to the current Python output.

## 8. Stage ② — ElevenLabs (sketch)

New `mod_node` module following the `docreview-ingestion` pattern: external call into
a temp workdir, normalize, `putObject` to storage, buffers off the request path.

- Concatenate a deck's slide scripts, tracking each slide's character range.
- One synthesis request per deck using the `michael` voice.
- Use character-level alignment from the response to map each slide's character range
  onto `start_ms` / `end_ms`.
- Skip slides whose effective audio source is `video`.
- Write mp3 to minio; patch `audio{}` and every `audio_span` back into the JSON.
- Re-synthesize only decks whose `source.script_hash` differs from `audio.script_hash`.

**Stage ② prerequisites (verify at the time, not now):** the exact ElevenLabs
timestamped-synthesis endpoint and its alignment field names; the model to use (the
`eleven_v3` value in §6.2 is an illustrative placeholder, not a decision); the voice
ID for `michael`; per-character cost against 32k words plus re-synthesis. Credentials come
from env vars, never hardcoded.

## 9. Stage ③ — Flutter player (sketch)

Reads the index for the lecture list, then one lecture document on open. Single audio
player over the whole deck; slide changes are seeks against `audio_span`. Blocks
render natively from the typed block array.

`forge_ui` — the platform's JSON-driven dynamic Flutter UI framework and a git
dependency of `fivex_ui` — is evaluated for the slide renderer before anything is
hand-rolled, since a JSON-defined slide with reveal steps is close to what it already
does. App location under `uvu` to be decided at stage ③; note that fivex treats
standalone apps as `webdav-apps/*` and never as `fivex_ui` modules.

## 10. Stage ④ — Tracking (sketch)

Player emits `lecture_started`, `slide_viewed`, `lecture_completed` to the `mod_node`
module; records persist in fivex postgres. Identity via `fivex_core` JWT.

**FERPA constraint, non-negotiable:** view records are per-student behavioral data.
They live in the fivex database and **never** in `tools/`, `*-content/`, or any
git repository in the uvu workspace. The lecture JSON itself stays PII-free and
publishable.

## 11. Verification

| What | How |
|---|---|
| Deck parser | Dart unit tests, including a fenced-code fixture that a naive splitter fails |
| Parser parity | Slide counts and notes text per deck match the current Python output before deletion |
| pptx renderer | All 28 decks byte-comparable in slide count and notes text |
| Schema | Every generated file validates; a deliberately malformed fixture is rejected |
| Persona rewrite | Slide count unchanged; deadlines and assignment references unchanged |

## 12. Risks

| Risk | Mitigation |
|---|---|
| POI cannot create notes slides from scratch | Prerequisite spike (§7) before any rewrite |
| Persona voice does not survive 253 slides | Rewrite deck-by-deck; first deck reviewed before continuing |
| Positional slide identity shifts on insert | `heading` stored alongside `index` makes drift detectable |
| Full-deck re-synthesis cost | `script_hash` gating; only changed decks re-synthesize |
| Schema drift across three languages | Producer-first rule; `ajv` validation on read; `schema_version` hard failure |

## 13. Out of scope

- CS 3660 (no speaker notes exist)
- Live in-class presentation workflow
- Captions and transcripts (derivable from `script` later)
- Any student-facing grading integration
