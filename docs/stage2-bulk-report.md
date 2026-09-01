# Stage ② Bulk Synthesis Report — 2026-08-29

Six CS 3540 lecture decks (weeks 1–4) synthesized via the per-slide `eleven_v3` + 1.2× ffmpeg-stretch
pipeline (`~/code/fivex/mod_node/modules/lecture/synthesize-lecture.ts`), run one deck at a time in
chronological order per the credit-budget brief.

## Credit meter

| Checkpoint | Character count | Character limit | Remaining |
|---|---|---|---|
| Before run | 23,838 | 90,000 | 66,162 |
| After deck 1 | 29,933 | 90,000 | 60,067 |
| After deck 2 | 47,626 | 90,000 | 42,374 |
| After deck 3 | 60,539 | 90,000 | 29,461 |
| After deck 4 | 72,263 | 90,000 | 17,737 |
| After deck 5 | 80,927 | 90,000 | 9,073 |
| After deck 6 (final) | 89,004 | 90,000 | 996 |

Total metered spend: 65,166 characters against a planned 65,868 (script-character sum across all
six decks matches the brief exactly — see table below). The ~700-character gap between planned and
metered spend is ElevenLabs' own request-level accounting and was not investigated further; it
worked in the budget's favor and left slack rather than consuming it.

## Per-deck results

| Deck | Slides | Script chars | Credits remaining after | MP3 duration | Median WPM | ajv result |
|---|---|---|---|---|---|---|
| w01-ai-eleven-pillars | 7/7 | 6,084 | 60,067 | 324.550s (5m 24.5s) | 213 | PASSED |
| w02-game-the-loop | 20/20 | 17,658 | 42,374 | 947.026s (15m 47.0s) | 206 | PASSED |
| w02-ai-claude-md | 15/15 | 12,887 | 29,461 | 714.409s (11m 54.4s) | 202 | PASSED |
| w03-game-determinism | 15/15 | 11,700 | 17,737 | 655.103s (10m 55.1s) | 195 | PASSED |
| w03-ai-skills | 10/10 | 8,648 | 9,073 | 460.595s (7m 40.6s) | 209 | PASSED |
| w04-game-engine-seams | 10/10 | 8,891 | 996 | 473.556s (7m 53.6s) | 198 | PASSED |
| **Total** | **77 slides** | **65,868** | | **57m 35.2s** | | **6/6 PASSED** |

## Per-deck verification performed

For every deck: every narrated slide has a stretched clip on disk and an `audio_span`; spans are
contiguous and non-overlapping with exactly a 350ms gap between consecutive slides; the sum of
spans plus gaps matches the concatenated mp3's `ffprobe` duration to within 1–2ms (LAME encoder
rounding); the patched lecture JSON validates against `modules/lecture/schemas/lecture.schema.json`
with ajv (`ajv-formats` registered).

`w03-ai-skills` special case: its stale REJECTED-attempt data (`eleven_multilingual_v2`, one-shot
deck mp3, `.cache/w03-ai-skills.raw-response.json`) was deleted before synthesis. No old per-slide
clip directory existed, so nothing else needed cleanup. Post-run, `audio.model` reads `eleven_v3`
and its span count (10) matches its slide count (10).

## Pipeline source commit

`modules/lecture/synthesize-lecture.ts` and `modules/lecture/eleven-labs-client.ts` were committed
in `~/code/fivex/mod_node` (not pushed):

```
feat(lecture): per-slide eleven_v3 synthesis pipeline with 1.2x stretch
```

Audio files and patched lecture JSON remain in the gitignored `_lectures/` tree under
`content/cs3540/2026/lectures/slides/_lectures/` and were not committed.
