# Lecture assembler — implementation report

**Date:** 2026-08-30
**Script:** `~/code/fivex/mod_node/modules/lecture/assemble-lecture.ts`
**Also touched:** `~/code/fivex/mod_node/modules/lecture/studio-server.ts`,
`~/code/fivex/mod_node/modules/lecture/web/studio.html`

## What it does

`assemble-lecture.ts` closes the last gap in the pipeline: it turns whatever
audio exists for a deck — any mix of instructor-recorded takes and
ElevenLabs-synthesized bootstrap clips — into one playable deck mp3, and
patches `audio{}` / every slide's `audio_span` back into
`_lectures/<deck>.json` in place. It is the missing link between
`studio-server.ts` (writes per-slide takes) and a deck a student can play.

## Run command

```bash
cd ~/code/fivex/mod_node
npx ts-node modules/lecture/assemble-lecture.ts <lecture-id> [--content-dir DIR] [--gap-ms 350]
```

Example used for verification:

```bash
npx ts-node modules/lecture/assemble-lecture.ts w03-ai-skills
```

## Source-priority rule

For each narrated slide (i.e. `video.audio !== "video"`, same exclusion
`synthesize-lecture.ts` already applies):

1. **Recorded** — if `_lectures/audio/<deck>/recorded/slide-NN.<ext>` exists
   (the canonical, non-`-takeK` file the studio writes), it is transcoded
   with a real `ffmpeg -c:a libmp3lame` call into
   `_lectures/audio/<deck>/recorded-mp3/slide-NN.mp3`.
2. **Synthesized** — otherwise, if `_lectures/audio/<deck>/stretched/slide-NN.mp3`
   exists (from `synthesize-lecture.ts`), it's used as-is.
3. **Missing** — otherwise the slide is excluded from the concatenation and
   left with **no** `audio_span`. Every run first clears every slide's
   `audio_span`, so a slide that loses its only audio source since the last
   run correctly loses its span too, rather than keeping a stale one.

This mixing is the point: record 3 of 10 slides today and the deck plays
end-to-end with those 3 in the instructor's voice and the rest still
synthesized. If **no** slide in a deck has any audio at all, no mp3 is
written and `audio` is set to `null` (a valid schema state) rather than
producing a bogus empty file.

Both timing defects are handled directly: (1) every clip — recorded or
synthesized — is measured with `ffprobe` on the real post-transcode/
post-stretch file, never estimated; `takes.json`'s browser wall-clock
duration is never read anywhere in this script. (2) `audio_span` is computed
from the same cumulative concatenation timeline the mp3 is built from (clip
durations + fixed 350ms gaps), so spans are contiguous by construction.

## Mixed-deck labelling

`lecture.schema.json` v1.0.0's `audio.voice` / `audio.model` are plain
strings with no `format`/`pattern` constraint, so a mixed deck is labelled
honestly **without a schema change**:

| Deck state | `voice` | `model` |
|---|---|---|
| all slides recorded | `"michael"` | `"recorded"` |
| all slides synthesized | `"michael"` | `"eleven_v3"` (unchanged from `synthesize-lecture.ts`) |
| mixed | `"michael+recorded"` | `"mixed:eleven_v3+recorded(recorded_slides=1,5,9)"` |

The `recorded_slides=` list is honest and machine-parseable
(`/recorded_slides=([\d,]+)/`) — a mixed deck is never silently labelled
`eleven_v3`.

**Did the schema need changing? No, not to satisfy the letter of the
requirement** — string fields with no format constraint can carry this. A
**better** representation would be a first-class field, e.g. an optional
`audio.recorded_slides: integer[]` or a per-slide `audio_source` enum
(`"recorded" | "synthesized"`), instead of string-encoding it. I did **not**
make that change: `lecture.schema.json` is a three-language contract (Dart
producer, Java/POI renderer, mod_node, Flutter player) owned producer-first
by `course_builder` per its `CLAUDE.md`, and changing it from this script —
without also updating the Dart producer and every consumer's copy — would
put the contract out of sync. **Proposed smallest schema change**, for
whoever next touches `course_builder`'s copy of the schema: add optional
`audio.recorded_slides: { type: "array", items: { type: "integer", minimum: 1 } }`
to the `audio` object's `properties` (still listed, so `additionalProperties: false`
keeps rejecting anything else). That turns today's regex-parseable convention
into a real, typed field with no other change needed.

## Studio UI change

`studio-server.ts`'s `/api/status` now reports a `status` field per slide —
`"recorded" | "synthesized" | "empty"` — by checking
`_lectures/audio/<deck>/recorded/` (already checked) and, when no recorded
take exists, `_lectures/audio/<deck>/stretched/` for a synthesized clip. Same
priority order the assembler uses, so the studio never shows a state the
assembler wouldn't also produce.

`studio.html`'s per-slide strip now has three visual states (green =
recorded, blue = synthesized, default = empty) plus a small legend row above
the strip, and each button's tooltip says which. Everything else in the
studio (take rotation, level meter, S studio/player switch with deck+slide
in the URL, R script pane, V teleprompter/pacer toggle, three-word pacer
centring) is untouched.

## Verification

Both `assemble-lecture.ts` and the `studio-server.ts` edit type-check clean
(`npx tsc --noEmit --skipLibCheck`).

**Setup:** generated a 6.0s sine-tone webm (opus, matching
`MediaRecorder`'s codec) with `ffmpeg -f lavfi -i sine=... -c:a libopus`,
written to `_lectures/audio/w03-ai-skills/recorded/slide-05.webm` — w03-ai-skills
was fully synthesized (10/10 slides) beforehand.

**Run 1** (`assemble-lecture.ts w03-ai-skills`):
- Slide 5: `transcoding recorded take slide-05.webm -> mp3` → real ffmpeg
  transcode ran; `recorded-mp3/slide-05.mp3` measured by ffprobe at exactly
  `6.000000s` (the true encoded duration, not a browser estimate).
- Slides 1–4 and 6–10: `source=synthesized`, using the existing stretched
  clips, untouched.
- `audio.voice = "michael+recorded"`, `audio.model =
  "mixed:eleven_v3+recorded(recorded_slides=5)"`.
- Spans: contiguous (`start_ms`/`end_ms` chain with fixed 350ms gaps,
  verified programmatically — no overlaps, no gaps besides the 350ms
  separator). `finalDurationMs = 430180`; `ffprobe` on the built
  `w03-ai-skills.mp3` independently measured `430.179569s` → rounds to the
  same `430180`. Span sum (`430179`) is 1ms off the whole-file ffprobe figure
  from independent per-clip rounding — same class of ≤1ms rounding
  `synthesize-lecture.ts` already exhibits.
- `ajv validation PASSED.`
- `/api/status?deck=w03-ai-skills` (studio server, started against this
  content dir) confirmed: slide 5 → `"status": "recorded"`; slides
  1–4, 6–10 → `"status": "synthesized"`.

**Cleanup:** deleted `recorded/slide-05.webm` and `recorded-mp3/`, then
re-ran the assembler. Result: `voice = "michael"`, `model = "eleven_v3"`,
`finalDurationMs = 460595` (matches the original fully-synthesized
`duration_ms`). Diffed the restored JSON against a pre-test backup: **every
field identical except `generated_at`** (both `audio` and `slides` compared
programmatically, byte-identical). `recorded/` directory confirmed empty. No
test audio left in the corpus.

## Concerns / follow-ups

- The mixed-deck `model` string convention (`mixed:eleven_v3+recorded(recorded_slides=…)`)
  works today but is a workaround, not a proper contract — see the proposed
  schema addition above. Any consumer (Flutter player, future analytics)
  that wants per-slide provenance has to regex-parse `model` until that
  lands.
- `assemble-lecture.ts` leaves a small `silence-350ms-assemble.mp3` cache
  file per deck in `audio/<deck>/` (parallel to `synthesize-lecture.ts`'s own
  `silence-350ms.mp3`) — intentional reusable build artifact, not test data,
  but flagging it since it's a new file this script introduces.
- Re-running the assembler on a deck that has never been synthesized *and*
  has zero recorded takes for every slide is handled (writes `audio: null`,
  no mp3) but was not exercised end-to-end against a truly empty deck since
  every existing CS 3540 deck already has full or partial synthesis.
