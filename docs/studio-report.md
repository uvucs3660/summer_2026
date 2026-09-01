# CS 3540 recording studio + slide player — build report

**Date:** 2026-08-29
**Source:** `~/code/fivex/mod_node/modules/lecture/` (committable; nothing under `_lectures/` is touched by git)
**Context:** spec §16 — TTS is a bootstrap, the instructor records the remaining decks himself.

## Run it

```bash
cd ~/code/fivex/mod_node
npx ts-node modules/lecture/studio-server.ts
```

* Studio: <http://localhost:8532/studio>
* Player: <http://localhost:8532/player>

Flags: `--port N`, `--content-dir DIR` (default
`~/code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides`). Binds `127.0.0.1` only.
Use **Chrome** and the **`http://localhost`** URL — `getUserMedia` is refused on `file://`, which is
why this server exists at all.

## Files created

| Path | Purpose |
|---|---|
| `modules/lecture/studio-server.ts` | static + API server (554 lines) |
| `modules/lecture/web/studio.html` | recording studio, self-contained (no framework, no CDN) |
| `modules/lecture/web/player.html` | slide-image player with speed control |
| `modules/lecture/README.md` | run command, keyboard map, storage layout, API |

Untouched, as required: `synthesize-lecture.ts`, `eleven-labs-client.ts`, `render-slides.ts`,
`build-player.ts`, every deck markdown, the schema, and every lecture JSON.

## Studio

Top to bottom: the **rendered slide webp**, the **teleprompter** (centred, ≤58 characters a line,
clamp(20px, 2.6vw, 34px), current line lit and the rest dimmed, smooth upward scroll), and the
**single-word pacer** (clamp(38px, 8vw, 110px), one word at a time, with a progress bar).

Both views read the same float cursor `S.pos`, advanced once per animation frame from `dt`, so they
cannot disagree; start, pause and reset move them together. Word durations are weighted by length
and by punctuation (commas + ~0.35 beat, sentence ends + ~0.65, paragraph ends + ~0.9) and then
**normalised per slide**, so "140 wpm" delivers that slide's words at 140 a minute while longer
words and sentence ends still get proportionally more time. Pace is live-adjustable mid-take with
the slider or `−`/`+`.

### Keyboard map (also on screen under `?`)

| Key | Action |
|---|---|
| `Space` | start / stop recording (starts the prompter and pacer with it) |
| `Enter` | keep the take — uploads it, then advances to the next slide |
| `D` | discard the take, stay on the slide (redo) |
| `U` | restore the take just discarded |
| `L` | listen back to the current take |
| `P` | prompter without recording (practice) / pause |
| `0` | reset prompter to the top of the slide |
| `←` `→` (`[` `]`) | previous / next slide |
| `−` `+` | pace ∓5 wpm |
| `F` | fullscreen |
| `?` / `Esc` | help overlay |

### Losing a take is designed against

* Keeping a take never overwrites: the existing `slide-NN.<ext>` is renamed to the next free
  `slide-NN-takeK.<ext>` before the new file is written, so the canonical name is always the newest
  take and every earlier take survives on disk.
* Discarding is undoable in-session (`U`) — the discarded blob is held in memory.
* Navigating away or closing the tab with an unkept take prompts first.
* A failed upload keeps the blob in the browser and says so in red; pressing `Enter` retries.
* A live input-level meter (dBFS, peak hold) runs whenever the mic is open; three seconds below
  −45 dBFS while recording raises a red **NO SIGNAL** banner, and a take under 2 KB is flagged
  before it can be kept.

Per-deck status: a clickable slide strip marks recorded slides green, and the header shows
`Recorded n/m` plus total recorded duration.

### Where recordings land

```
_lectures/audio/<deck-id>/recorded/slide-NN.webm        newest kept take
_lectures/audio/<deck-id>/recorded/slide-NN-take2.webm  the one it replaced (-take3, …)
_lectures/audio/<deck-id>/recorded/takes.json           file, duration_ms, recorded_at, bytes
```

Format is whatever MediaRecorder supports, preferring `audio/webm;codecs=opus` (extension follows:
`.webm`, `.ogg`, `.m4a`). If `takes.json` is missing or corrupt the studio still reports a slide as
recorded from the files themselves, and a corrupt manifest is parked as `takes.json.corrupt-<ts>`
rather than dropped.

## Player

Replaces the block-rendering player: it shows `slides/<deck>/slide-NN.webp`, plays the deck mp3, and
advances slides from `audio_span`. Speed control is 0.75×–2.0× in 0.05 steps with the rate displayed
and `preservesPitch = true` (plus the `moz`/`webkit` aliases). The slide's script sits beneath the
image; thumbnails with their start times jump to any slide; `←`/`→` step, `Space` plays, `−`/`+`
change speed, `0` resets to 1×. The deck picker lists all 28 decks and marks which have audio (`♪`)
or recorded takes (`●n`). Decks with neither open in manual step-through mode with an explanatory
note instead of an error; a deck with recorded takes but no mp3 plays the takes slide by slide.

## Verification

Server started for real and exercised with curl (port 8532 against the live content dir; port 8533
against a scratch content dir so no write test touched `_lectures/`), plus a headless Chromium
session driving both pages.

| Check | Evidence |
|---|---|
| studio page loads | `GET /studio` → 200, `text/html; charset=utf-8`, 30215 bytes |
| player page loads | `GET /player` → 200, `text/html; charset=utf-8`, 14475 bytes |
| `lectures.json` served | `GET /media/lectures.json` → 200 `application/json`, 28 lectures parsed |
| webp served correctly | `GET /media/slides/w01-ai-eleven-pillars/slide-01.webp` → 200 `image/webp`, 22434 bytes, `file` reports `Web/P … 1600x901` |
| mp3 range requests | `Range: bytes=0-99` → 206, `Content-Range: bytes 0-99/4063376` (so `<audio>` can seek) |
| `/api/decks` | 28 decks with `has_audio` / `slide_images` / `recorded_slides` |
| `/api/status` | correct per-slide state, take history and totals |
| upload writes the right path | POST → `…/_lectures/audio/w01-ai-eleven-pillars/recorded/slide-03.webm` (scratch tree), 200 JSON receipt |
| no take is ever lost | second POST to the same slide → first file byte-identical at `slide-03-take2.webm` (`cmp` = IDENTICAL), new file is the newest bytes, `takes.json` lists both |
| upload rejects bad input | empty body → 400; slide 99 of a 7-slide deck → 400; unknown deck → 404 |
| path traversal | `/media/%2e%2e%2f…/etc/passwd` → 400; normalised `../` → 404 |
| end-to-end record → keep | headless Chromium with a synthetic MediaStream: recorded 1.8 s, blob 28310 bytes, uploaded, auto-advanced 5→6, counter went 1→2, total duration updated; `ffprobe` reports the written file is `matroska,webm`, duration 1.68 s |
| denied microphone | stubbed `NotAllowedError` → "mic: blocked" + instructions banner, `startRecording()` returns cleanly, page stays usable |
| missing lecture JSON | deck whose JSON is absent → banner, no exception |
| missing slide image | `onerror` placeholder naming the expected file, in both pages |
| teleprompter clock | pos advanced 3.97 words in 2 s at 140 wpm and 7.54 in 2 s at 200 wpm; word view, line highlight and scroll all tracked the same index; pause held position |
| player playback | real mp3 played (duration 5:24), rate 1.35× with `preservesPitch true`, slide auto-advanced on `audio_span`, thumbnail click seeked to 32.43 s = slide 2's `start_ms` exactly |
| no-audio deck | `w09-ai-model-selection` → Play disabled, explanatory note, slides still stepped and rendered |
| type safety | `npx tsc --noEmit` over the whole `mod_node` project — clean |
| console | no page errors beyond 404s deliberately provoked in the scratch tree |

### Not verified

* **No microphone was used.** Recording was proven with a synthetic `MediaStream` (an oscillator via
  `createMediaStreamDestination`), which exercises `MediaRecorder`, the blob, the upload and the file
  on disk — but not a real capture device, real levels, or Chrome's permission prompt. Audio quality,
  the meter's calibration against a real voice, and the "allow microphone" flow are unverified.
* **Nothing was listened to.** The written `.webm` was checked structurally with `ffprobe`, not heard.
* **No writes were made to the real `_lectures/` tree.** Upload tests ran against a scratch content
  dir with the same layout; the code path and the resulting relative path are identical, but the
  first real take will be the first file written there.
* **Chrome specifically was not driven** — the headless browser was Chromium via Playwright. Safari
  is untested (it would fall back to `audio/mp4` takes).
* Only one deck's worth of decks were opened by hand; the other 26 were exercised only through
  `/api/decks`.

## Concerns

1. Slide images exist for all 28 decks, but a deck re-rendered later could drift from the JSON slide
   count; the studio shows a per-slide placeholder rather than failing, and `render-slides.ts`
   already checks counts at render time.
2. Takes are opus-in-webm. Whatever assembles a deck mp3 from recorded takes will need an ffmpeg
   transcode step — that assembler does not exist yet and is out of scope here.
3. `duration_ms` in `takes.json` is the browser's wall-clock measurement of the recording, not a
   demuxed duration; the sample above measured 1.80 s for a 1.68 s file. Good enough for a progress
   counter, not for computing `audio_span` — spans must be measured from the assembled audio.

## Studio ↔ Player switch + readable script pane (2026-08-29)

### Change 1 — real Studio ↔ Player switch

The old `<a href="/player" target="_blank">` (studio) / `<a href="/studio">` (player) links opened
a new tab and carried no position. Both pages now navigate **in the same tab** and take the current
deck + slide with them.

**URL parameter contract:** both pages read `?deck=<id>&slide=<n>` on load.
- `deck` must match a known deck id (from `/api/decks`); `slide` must be an integer in
  `1..slide_count` for that deck.
- If either is missing or invalid, the page falls back to its normal `localStorage`-remembered
  deck/slide (verified — see below) rather than erroring.
- Once consumed on the initial load, the params are cleared in memory; subsequent deck/slide
  changes (arrows, deck picker, thumbnail clicks) update the address bar via
  `history.replaceState` (no new history entries), so the URL always reflects the current position
  and a reload lands back where you were.
- The switch link's `href` and the keyboard shortcut both target `/player?deck=…&slide=…` (from
  studio) or `/studio?deck=…&slide=…` (from player), built from the same live state.

**Keyboard shortcut:** `S` on both pages. Checked both existing keymaps first — studio uses
Space, Enter, D, U, L, P, 0, arrows/`[`/`]`, `+`/`-`, F, `?`/`/`; player uses Space, arrows, `+`/`-`,
0. `S` was free on both, so it means the same thing everywhere: "go to the other page."

**Recording-in-progress guard (studio only):** pressing `S` (or clicking the link) while
`S.mode === 'recording'` is blocked outright — no navigation happens, a banner explains why
("Stop the recording (Space) before switching to the Player — the take would be lost."), and a
toast echoes it. If there's a **stopped but unkept** take sitting in the browser, switching asks
`confirm()` first (same pattern `gotoSlide` already used for changing slides), and cancelling
leaves the take and the page untouched. `beforeunload` was also extended to guard `mode ===
'recording'`, not just an unkept blob, so a hard close/refresh mid-take now prompts too.

### Change 2 — readable script pane (studio only)

A new collapsible section sits between the slide strip and the main stage: a header bar (always
visible) showing `<toggle> Script` plus the current slide's word count and estimated read time at
175 wpm, and a body (shown only when open) with the script rendered as ordinary `<p>` paragraphs —
split on the source's blank lines, generous line-height, ~72ch measure, capped at `34vh` and
scrollable. It reuses the word list `layoutScript()` already built for the prompter, so the count
always matches what the prompter/pacer are using.

Toggle: click the header, or press `R` (free on both keymaps). Open/closed state is stored in
`localStorage` under `studio.scriptOpen` and restored before the first slide renders, so it's
consistent across slides and page loads. Collapsed, it's a thin bar; it never overlaps or shrinks
the prompter/word-pacer panes below a usable size — when open it takes a capped, scrollable slice
instead of fighting the grid.

### Verified (Playwright/Chromium against the already-running server on :8532)

- `GET /studio` and `GET /player` → 200, with and without query params.
- `?deck=w03-ai-skills&slide=7` honoured on load on **both** pages (confirmed slide number, deck
  selector value, and the switch link's `href`).
- Full round trip: studio slide 7 → `S` → player lands on slide 7 of the same deck → `S` → studio
  lands back on slide 7 of the same deck. URL bar correct at every hop.
- Invalid params (`deck=not-a-real-deck&slide=9999`) → silently ignored, falls back to the
  `localStorage`-remembered deck/slide (no error, no crash).
- Script pane: toggled open, full script text present with 4 correctly-split paragraphs; word
  count + duration shown in the header even while collapsed; `studio.scriptOpen=1` persisted and
  the pane was still open after a fresh navigation to a different slide/page load.
- Recording guard: started a real `MediaRecorder` take against a synthetic `MediaStreamDestination`
  tone (getUserMedia mocked, since headless Chromium has no mic), pressed `S` mid-recording — blocked,
  banner shown, URL unchanged, still recording. Stopped, tried `S` again with the unkept take —
  `confirm()` fired with the expected message, cancelling left everything in place.
- End-to-end record flow: Record → Stop → Keep uploaded a real file to
  `_lectures/audio/w03-ai-skills/recorded/slide-08.webm` (confirmed on disk), then recorded again
  on the same slide and kept — server rotated the old file to `slide-08-take2.webm` as designed.
  Both existing keyboard shortcuts (arrows, Space, Enter) and the new ones exercised in the same
  session without collision. Test recordings deleted afterward so no synthetic audio was left in
  the real content tree.
- No console errors/warnings on either page across the session.
- Player's `preservesPitch`/rate control, deck picker, and thumbnail navigation still functioned
  (checked via existing localStorage-persisted rate and slide navigation).

### Could NOT verify

- Real microphone capture/permission flow (headless Chromium has no mic; used a synthetic
  `MediaStreamDestination` tone instead, as the task allowed).
- Audio playback correctness/quality by ear — nothing was listened to.
- Behavior in Safari (only Chromium was driven).
- The player's mid-audio-seek precision when `?slide=` deep-links past slide 1 before the deck
  mp3's metadata has finished loading — the slide/image/script/thumbnail all update correctly in
  this case (verified), but a same-tick `audio.currentTime` seek before `loadedmetadata` can be
  browser-dependent; this is not a regression (deep-linking to slide>1 did not exist before this
  change) but is worth a quick manual check with real audio.

---

## 2026-08-29 — Three-word pacer + teleprompter/pacer view toggle

**Scope:** `web/studio.html` only (plus this README's keymap). Did not touch player.html,
studio-server.ts, synthesize-lecture.ts, eleven-labs-client.ts, render-slides.ts, schema, deck
markdown, or `_lectures/`.

### New keyboard shortcut

`V` — toggles between the two mutually-exclusive views (teleprompter / pacer). Chosen because the
existing keymap (Space, Enter, D, U, L, P, S, R, 0, arrows, `[` `]`, `+` `-`, F, ?) had no `V`
binding; it also reads mnemonically as "View". Also exposed as a "View: Teleprompter"/"View: Pacer"
button in the control row. Persisted to `localStorage.studio.view` across slide changes and reloads.

### Change 1 — three-word pacer

Replaced the single centred word (`#word`) with three elements (`#wordPrev`, `#wordCur`,
`#wordNext`) sharing the same `S.pos`/`idx` clock as the teleprompter (`paintPrompter()` updates
both on every index change; no separate state, so they cannot disagree). Current word: large,
`#e5e7eb`, full contrast. Previous/next: smaller (`clamp(16px,3.4vw,42px)`), `#9ca3af`, `opacity`
via dimmer color only (no separate opacity layer needed). A short (`.12s ease-out`) scale+opacity
"tick" keyframe plays on the current word on every index change — it animates `scale` only, never
`translate`, so it cannot move the anchor point. First/last word: the missing neighbour's
textContent is set to `''`, leaving that slot empty rather than re-centring.

**Centring technique used — two-part, both parts necessary:**
1. The current word's own centring is pure CSS, no JS measurement: `#wordCur{ left:50%;
   transform:translate(-50%,-50%) }`. The browser recomputes the `-50%` offset from the element's
   own rendered width on every layout pass, so its geometric centre is pinned to the container's
   horizontal midpoint on every tick regardless of word length. This alone satisfies "the centre
   never moves."
2. Previous/next are positioned relative to that same centre line, offset by half of the
   **current** word's `offsetWidth` (measured via forced reflow, reusing a reflow the tick-animation
   restart already does) plus a fixed 22px gap. This was necessary — a first pass that hung
   prev/next off a *fixed* `em`-based offset from the centre line caused a visible overlap
   ("02" rendered on top of "Forge" when the current word was wide and the neighbour font was
   small); screenshotted, diagnosed, and fixed by measuring the current word's width instead. This
   measurement only ever repositions the neighbours — it has no path back into the current word's
   own position — so it cannot reintroduce jitter into the anchor.

**Measured centre variance:** two separate 14-sample runs at 220 wpm, in Chromium via Playwright,
words ranging in rendered width from ~63px ("it") to ~592px ("twenty-first."). Current word's
bounding-box centre-x stayed at 756px for all samples in both runs, with a max deviation of
**~0.00003px** (float rounding noise, not real motion) — effectively zero. Also confirmed
separately: at the first word, `#wordPrev` renders empty with no shift; at the last word,
`#wordNext` renders empty with no shift; centre-x unchanged in both cases.

### Change 2 — mutually exclusive views

`main`'s grid went from 3 rows (stage/prompter/word, 50/31/19fr) to 2 rows (stage/view, 50/50fr),
with `#prompter` and `#wordbox` both pinned to `grid-row:2` and toggled via `display:none` —
confirmed via `getBoundingClientRect()` that the hidden view is a zero-size, no-layout-impact
element while the visible one occupies the full second row. Both views are still painted every
tick from the same `S.pos` regardless of which is visible, so switching mid-take doesn't move or
reset anything — confirmed by fast-forwarding to a specific word in pacer view, switching to
teleprompter, and reading `.w.cur` — it was the identical word ("bed.") the pacer had shown.

### Verified (Playwright/Chromium against the already-running server on :8532; did not start or
kill it)

- Toggle switches exactly one view at a time; hidden view's `getBoundingClientRect()` is
  `{x:0,y:0,width:0,height:0}`.
- `studio.view` persists across a slide change (`ArrowRight`) and across a full page reload.
- Pacer shows prev/current/next with current highlighted; first-word and last-word cases leave the
  missing slot empty without moving the current word.
- Centre-pin variance: ~0.00003px across 28 total advances in two runs spanning ~63–592px word
  widths (see above). The overlap bug from the first implementation pass was caught by screenshot,
  fixed, and re-verified with the same variance test (unchanged, still ~0.00003px).
- Switching views mid-run keeps the same word position (teleprompter's `.w.cur` matched pacer's
  `#wordCur` text after a live switch).
- Re-exercised existing shortcuts in the same session: `R` (script pane open/close), `+` (wpm
  140→145), `?`/`Escape` (help modal, now includes the `V` row), `0`/`P` (reset/practice, still
  drive both views' shared clock). No collision with the new `V` binding (`grep`-verified: no other
  `case 'v'`/`'V'` in the keydown switch). Zero console errors/warnings throughout.

### Could NOT verify

- Anything by ear — no microphone in this environment; `initMic()` correctly reported "mic:
  blocked"/banner and the rest of the page (including the new pacer) worked normally around that,
  same as before this change.
- Did not re-exercise the full record → stop → keep → take-rotation flow in this session (no mic);
  relying on the prior session's report above plus the fact that this change touched no code paths
  in `startRecording`/`stopRecording`/`keepTake`/`restoreDiscarded`.
- Real-world "does it feel steady" to a human narrator — only pixel-level centre-drift was
  measured; subjective pacing feel during an actual 28-lecture recording session is unverifiable
  without recording one.

### Concerns

- The 22px fixed gap plus current-word-width offset is tuned by eye at the studio's normal window
  size; on a much narrower window a very long current word could still push prev/next off-screen
  (they'd clip via `overflow:hidden`/ellipsis, not overlap) — not a regression from the old
  single-word view, which had the same `max-width`/ellipsis escape hatch.
