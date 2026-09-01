# SPIKE: can syllable-nuclei detection drive a teleprompter pacer?

**Date:** 2026-08-30
**Status:** spike complete. Probe code at `~/code/fivex/mod_node/modules/lecture/probe/`
(clearly marked throwaway). No production file was modified.

**Verdict in one line:** the detector is a good *rate* sensor and a bad *counter*. It
cannot free-run a word pointer across a slide, but it can interpolate between pause
landmarks — and the corpus it was measured on is synthetic, so even these numbers are an
optimistic bound.

---

## 1. What was built

Per the brief, de Jong & Wempe (2009) syllable-nuclei detection: intensity-envelope peaks,
a >= 2 dB dip on both sides, a voicing requirement, and a refractory period.

Chain: 4-pole 300–1000 Hz bandpass (cascaded RBJ biquads) → rectify → 15 Hz one-pole
smoother → decimate to a 200 Hz envelope → dB → local maxima → global silence floor
(`loud − 25 dB`) → adaptive local floor → iterative dip merge → voicing gate → 120 ms
refractory.

Two deviations from the paper, both deliberate:

- **Voicing is an injected callback, not a built-in pitch tracker.** The peak picker
  `detectNuclei(env, envelopeRate, opts, voicingProbe)` is a pure function over an
  envelope array and knows nothing about audio. The voicing test needs raw samples, which
  the envelope stage has discarded, so it arrives as an optional `(tSeconds) => 0..1`
  periodicity function. Offline the harness supplies a normalised autocorrelation over
  lags for 70–400 Hz; a live pacer would build the same probe from
  `AnalyserNode.getFloatTimeDomainData()`. This is what keeps the offline and live paths
  on the identical code.
- **Added an adaptive local floor** (peak must exceed the windowed minimum over ~2 s by
  N dB) on top of the paper's global threshold. It turned out to change nothing at any
  setting — see §6, this matters.

**Offline/live equivalence was verified, not assumed.** Pushing a clip through
`EnvelopeFollower` in 128-sample frames (the AnalyserNode case) produced a *bit-identical*
envelope to pushing it in one block: `lenDiff=0, maxAbsDiff=0.00e+0`.

**Decoder choice:** Node + `ffmpeg -f f32le -ac 1 -ar 16000` to stdout, over a headless
browser with `OfflineAudioContext`. One deterministic subprocess, no browser lifecycle to
manage, and 16 kHz is ample for a 300–1000 Hz band and a 70–400 Hz autocorrelation.

---

## 2. Corpus — and a correction to the brief

The brief says 253 slides with audio. **There are 86.** 253 is the total slide count across
all 28 CS 3540 decks; only 7 decks have rendered audio. All 86 were evaluated, in both
available variants:

| Variant | Slides | Audio | Note |
|---|---|---|---|
| `raw` | 86 | 80.4 min | narration at its natural TTS rate |
| `stretched` | 86 | 67.0 min | the same narration sped up **1.200×** to fit slide timing |

That the same 19,100 syllables exist at two tempos turned out to be the single most useful
thing in the corpus — it is a free natural experiment, and §5 turns on it.

### Ground truth from script text

Vowel-group heuristic: maximal `[aeiouy]` groups, minus silent terminal `e` (guarded
against consonant+`le`), minus silent `-es`/`-ed` (guarded against `-ces` and `-led`),
`qu` folded so its `u` is not a nucleus, plus narrow hiatus rules (`ue`+consonant outside
`qu`; `-uity`; word-final consonant+`ia`/`ea`/`ua`), non-word acronyms spelled letter by
letter (`w`=3, `y`=2), digits spelled out, and a small **disclosed** exception map for
high-frequency words the rules miss (`every`, `something`, `people`, `hundred`, …).

Spot-checked against hand counts in two rounds, the second **held out** after the rules
were fixed:

| Sample | n | per-word error | aggregate error |
|---|---|---|---|
| Frequency-weighted tokens, round 1 | 20 | 0/20 (0%) | 0.0% |
| Long word types (>7 chars), round 1 | 20 | 3/20 (15%) | −4.9% |
| Frequency-weighted tokens, **held out** | 20 | 0/20 (0%) | 0.0% |
| Long word types, **held out** | 20 | 2/20 (10%) | −3.7% |

After adding two more rules (`-ces`, consonant+`led`) both held-out samples went to 0/20.
Honest residual: ~0% on the frequent short tokens that dominate the corpus, ~±3% on
unseen long word types. Corpus aggregate: 13,583 words → 19,100 syllables (1.406
syll/word). **Ground-truth uncertainty is therefore roughly 1–3%, which is a floor under
every accuracy number below and is within ~2× of the best result achieved.**

---

## 3. Accuracy at the literature defaults (dip 2 dB, refractory 120 ms, voicing 0.35)

| | `raw` (natural rate) | `stretched` (1.2×) |
|---|---|---|
| MAPE | **18.5%** | **27.3%** |
| median \|error\| | 18.8% | 26.8% |
| signed bias | **−18.5%** | **−27.3%** |
| within 5% | 0 / 86 | 0 / 86 |
| within 10% | 4 / 86 | 0 / 86 |
| within 20% | 55 / 86 | 6 / 86 |
| worse than 20% | 31 / 86 | 80 / 86 |

The error is **almost entirely systematic undercount**: MAPE ≈ |bias| to one decimal in
both variants, meaning essentially every slide errs in the same direction. The detector is
not noisy. It is consistently missing about one syllable in five.

### Syllables per second

| | detected median | detected p10–p90 | expected median | expected p10–p90 | inside 3–8 Hz |
|---|---|---|---|---|---|
| `raw` | 3.26 Hz | 2.94–3.46 | 3.96 Hz | 3.60–4.39 | **72 / 86** |
| `stretched` | 3.48 Hz | 3.17–3.67 | 4.75 Hz | 4.32–5.26 | 85 / 86 |

Every slide's *true* rate is comfortably inside the plausible 3–8 Hz band. The *detected*
rate is pushed to the very bottom of it, and on natural-rate audio **14 of 86 slides fall
out of the band entirely** (below 3 Hz). That is a useful self-diagnostic: a detector
reporting sub-3 Hz for ordinary lecture delivery is telling you it is dropping syllables.

### After one global scale factor

A pacer does not strictly need the absolute count — a per-speaker calibration constant can
absorb a *constant* scale error. Fitting a single k = Σdetected/Σexpected:

| | k | MAPE | median | within 5% | within 10% | within 20% | worse 20% |
|---|---|---|---|---|---|---|---|
| `raw` | 0.8163 | **4.8%** | 3.6% | 53 / 86 | 76 / 86 | 86 / 86 | 0 |
| `stretched` | 0.7269 | **5.4%** | 4.6% | 43 / 86 | 75 / 86 | 86 / 86 | 0 |

Cross-validated leave-one-**deck**-out (fit k on 6 decks, score the 7th) gives 4.8% / 5.5%
— i.e. not an artefact of in-sample fitting. Per-deck k varies only 0.799–0.836 (`raw`)
and 0.710–0.745 (`stretched`).

**This is the real result: the detector's recall ratio is stable to ~±2% across decks,
while its absolute count is off by 18–27%.**

---

## 4. Worst 5 slides

`raw` variant, at the literature defaults:

| Deck | Slide | Expected | Detected | Error | Duration | True rate |
|---|---|---|---|---|---|---|
| w01-ai-eleven-pillars | 2 | 33 | 23 | −30.3% | 8.5 s | 3.89 Hz |
| w03-ai-skills | 10 | 228 | 160 | −29.8% | 53.2 s | 4.29 Hz |
| w02-game-the-loop | 12 | 200 | 142 | −29.0% | 46.6 s | 4.29 Hz |
| w04-game-engine-seams | 10 | 205 | 146 | −28.8% | 45.7 s | 4.49 Hz |
| w02-ai-claude-md | 1 | 155 | 111 | −28.4% | 37.4 s | 4.15 Hz |

`stretched` variant (worse, and the same slides):

| Deck | Slide | Expected | Detected | Error | True rate |
|---|---|---|---|---|---|
| w04-game-engine-seams | 10 | 205 | 123 | −40.0% | 5.38 Hz |
| w02-ai-claude-md | 1 | 155 | 97 | −37.4% | 4.98 Hz |
| w02-game-the-loop | 12 | 200 | 127 | −36.5% | 5.14 Hz |
| w03-ai-skills | 10 | 228 | 145 | −36.4% | 5.14 Hz |
| w01-game-first-contact | 3 | 268 | 171 | −36.2% | 5.40 Hz |

**Diagnosis: it is one mechanism, not five.** The worst slides are the *fastest* slides.
Sort by true speech rate and the error sorts with it. Every slide in the `stretched` worst
list is at or above 4.98 Hz against a corpus median of 4.75 Hz;
`w04-game-engine-seams` slide 10 ("Read S00 in full. It is a hundred and eight lines…") is
a fast administrative run of short function words and spelled numerals, the exact material
where unstressed syllables are 60–90 ms apart and get merged by the dip rule and swallowed
by the refractory period.

The symmetric failure confirms it: the two slides that *over*-count after calibration
(`w02-game-the-loop` slide 8, +19.7%; `w01-ai-eleven-pillars` slide 3, +13.5%) are the
*slowest*, most deliberate slides — 4.46 and 4.26 Hz. They are not over-detected; the
global k is simply too small for them.

Quantified: **corr(true rate, calibrated error) = −0.68 (`stretched`), −0.55 (`raw`);
slope −13.1 and −11.3 percentage points of error per +1 Hz of speech rate.** Removing that
single linear trend drops calibrated MAPE from 5.4% → 3.9% and 4.8% → 4.0%. Roughly a
third of the remaining error is pure speech-rate dependence.

Binned recall (`stretched`):

| True rate | n | mean detected/expected |
|---|---|---|
| < 4.4 Hz | 10 | 0.773 |
| 4.4–4.8 Hz | 36 | 0.751 |
| 4.8–5.2 Hz | 30 | 0.705 |
| > 5.2 Hz | 10 | 0.664 |

And the cleanest evidence of all, because it holds the words constant: **the same 19,100
syllables played 1.2× faster drop the recall ratio from 0.816 to 0.727 — an 11% relative
loss of recall from a 20% tempo change alone.**

---

## 5. Sensitivity

35-cell grid, `minDipDb` × `refractoryMs`, each cell `rawMAPE% / MAPE% after one global scale factor`.

`raw` (natural rate):

| dip \ refr | 40 ms | 60 | 80 | 100 | 120 | 150 | 180 |
|---|---|---|---|---|---|---|---|
| 1.0 dB | 17.2/5.8 | 11.1/5.5 | **5.1**/5.0 | 8.3/5.1 | 15.9/5.3 | 27.2/5.6 | 36.8/5.9 |
| 1.5 | 8.9/5.4 | 6.2/5.1 | **5.1**/4.8 | 10.2/4.9 | 17.3/4.8 | 27.8/5.4 | 37.3/5.7 |
| 2.0 | 5.4/5.0 | **5.0**/5.0 | 6.7/4.9 | 11.8/4.8 | 18.5/4.8 | 28.5/5.4 | 37.7/5.6 |
| 3.0 | 6.9/4.7 | 7.9/4.6 | 10.4/4.6 | 15.1/4.4 | 20.7/4.6 | 29.7/5.4 | 38.4/5.7 |
| 4.0 | 11.2/4.5 | 12.1/4.6 | 14.1/4.5 | 17.9/4.5 | 22.8/4.7 | 31.1/5.5 | 39.2/5.8 |

`stretched` (1.2×):

| dip \ refr | 40 ms | 60 | 80 | 100 | 120 | 150 | 180 |
|---|---|---|---|---|---|---|---|
| 1.0 dB | 10.0/5.5 | **5.1**/4.9 | 8.8/5.3 | 17.5/5.4 | 25.8/5.5 | 36.6/5.7 | 45.4/6.2 |
| 1.5 | 5.5/5.1 | 5.2/4.8 | 10.7/4.9 | 18.9/5.1 | 26.6/5.5 | 37.1/5.7 | 45.7/6.0 |
| 2.0 | **5.1**/4.7 | 7.0/4.4 | 12.7/4.5 | 20.0/4.9 | 27.3/5.4 | 37.5/5.5 | 46.0/5.9 |
| 3.0 | 9.6/4.6 | 11.4/4.5 | 15.9/4.4 | 22.2/4.7 | 28.7/5.2 | 38.3/5.6 | 46.5/5.8 |
| 4.0 | 14.0/4.6 | 15.3/4.5 | 18.8/4.5 | 24.2/4.9 | 30.1/5.2 | 39.2/5.8 | 47.2/5.8 |

**The finding, and it is the most important one in this report:**

- **Raw MAPE across the grid: 5.0% → 47.2%.** Nearly tenfold. Threshold choice is
  everything.
- **Scale-corrected MAPE across the same 35 cells: 4.4% → 6.2%.** Essentially flat. The
  fitted k moves 0.529 → 1.088 to compensate.

Whatever thresholds you pick, the detector finds the same *shape*; the thresholds only set
the constant. Any single-cell "5.1% MAPE" headline is a tuned number and does not
generalise — it is the fitted scale factor wearing a disguise.

**And the optimum moves with tempo.** On the same words, the raw-MAPE minimum sits at
dip 1–1.5 / refr 80 ms at natural rate but at dip 1 / refr 60 ms and dip 2 / refr 40 ms at
1.2×. A parameter set tuned to one speaker's tempo is wrong for the same speaker going
faster.

Other parameters, `raw` variant (raw MAPE / scale-corrected MAPE):

| Parameter | Sweep | Raw MAPE | Corrected |
|---|---|---|---|
| `voicingMin` | 0 → 0.65 | 17.0% → 29.0% | 4.8% → 5.2% |
| `envelopeHz` | 8 → 40 | 22.4% → 13.1% (monotone better) | 4.6% → 4.9% |
| `adaptiveDropDb` | off, 6, 9, 12, 16, 20 | **18.5% at every setting** | 4.8% at every setting |

### Which thresholds look most fragile on real human speech

1. **`refractoryMs` — by far the most fragile.** It dominates the grid, and its optimum
   already shifts under a 20% tempo change on identical words. Humans vary their rate far
   more than that within a single sentence. A fixed refractory is not viable; it needs to
   adapt to a running rate estimate, which is circular and needs designing.
2. **`voicingMin` — most likely to behave differently in kind.** On clean TTS, raising it
   from 0 to 0.35 costs 1.5 points of recall, because synthetic voicing is unnaturally
   strong and consistent. Real speakers go creaky at phrase ends and devoice unstressed
   final syllables, exactly the positions a pacer must not miss, and room noise depresses
   normalised autocorrelation everywhere. Expect this to cost far more than 1.5 points.
3. **`envelopeHz` — improvement is monotone here and will not stay monotone.** Wider
   smoother bandwidth helps on TTS (30.1% → 23.9% going 8 → 40 Hz) because the only thing
   extra bandwidth admits is more real syllable structure. On human audio it also admits
   breath noise, lip smacks and page rustle. The 15 Hz default is defensible; the apparent
   win from 40 Hz is a synthetic-corpus artefact and should not be taken.
4. **`minDipDb` — least fragile.** 1 → 4 dB moves corrected MAPE by ~1 point. The paper's
   2 dB is fine and is the one parameter this spike would carry forward unchanged.
5. **`adaptiveDropDb` — completely untested, and dangerous for that reason.** It produced
   *bit-identical* results at every setting from 6 to 20 dB and with the whole stage
   disabled. This corpus has no level drift for an adaptive floor to fix. Real audio — a
   speaker turning their head, walking away from a fixed mic, an AGC pumping — has plenty.
   There is zero evidence here about whether this stage helps or hurts.

---

## 6. The synthetic-corpus caveat, stated plainly

**Every number above is an optimistic bound, and the report should be read that way.**

ElevenLabs narration has: a cleaner envelope with deeper inter-syllable dips than a human
produces; near-uniform pacing (the whole 86-slide corpus spans only 3.6–4.4 Hz at p10–p90,
where a human lecturer routinely spans 2–7 Hz within one talk); no breaths; no
disfluencies; no false starts; no filled pauses; no laughter; no lip noise; a fixed
distance from a nonexistent microphone; and no room.

Concretely, the things this corpus cannot test:

- **Breaths and lip noise** will produce envelope peaks. They are unvoiced, so criterion 3
  is the only defence, and criterion 3 is the parameter I have the least confidence in.
- **Filled pauses** ("uhh") are voiced, sustained and loud. They will register as one to
  three syllables that are not in the script — a *positive* error source that is entirely
  absent here, where every error is negative.
- **False starts and repairs** put syllables in the audio that the script does not contain
  at all. A pacer's script-anchored pointer has no representation for them.
- **Level drift** — see `adaptiveDropDb` above.
- **The scale factor k itself is speaker-specific and rate-specific.** It is 0.816 for this
  voice at 3.96 Hz and 0.727 for the same voice at 4.75 Hz. There is no reason to expect a
  human's k to be either number, and every reason to expect it to move during a talk.

The narrow rate range is the specific reason the "calibrated MAPE 4.8%" number flatters the
technique. A global k works here *because* the corpus barely varies in tempo. Widen the
tempo range and the −11 pp/Hz slope eats the calibration.

---

## 7. Can this advance a word pointer? Quantified.

The corpus averages 1.406 syllables per word, so **a 200-word slide is ~281 syllables.**

| Regime | Per-slide error | Drift at slide end | In words |
|---|---|---|---|
| Literature defaults, no calibration | −18.5% | −52 syllables | **−37 words** |
| Calibrated, median slide | 3.6% | 10 syllables | **7 words** |
| Calibrated, p90 slide (10%) | 28 syllables | | **20 words** |
| Calibrated, worst slide (16.3%) | 46 syllables | | **33 words** |
| Calibrated, but speaker 1 Hz faster than calibration | +11.3 pp | 32 extra syllables | **23 words** |

Read that table as the answer:

- **Uncalibrated free-running: no. Not close.** A 37-word drift on a 200-word slide means
  the pointer is roughly two sentences behind by the end. Unusable at any granularity.
- **Calibrated free-running: no, for word-level highlighting.** 7 words of drift at the
  median is already past the point where a highlighted word is the wrong word, and the
  p90 slide is 20 words out. It would be *marginally* acceptable for a coarse
  "you are somewhere in this paragraph" band of ±1–2 lines, and only for a speaker whose
  rate stays where it was calibrated.
- **The rate dependence is what actually kills free-running.** A speaker who accelerates
  1 Hz mid-slide — utterly ordinary — adds 23 words of drift on top of everything else,
  and the pacer has no way to know it happened, because the quantity that changed is the
  quantity being measured.

### Would pause-based resync save it?

Partly, and it changes the design rather than rescuing the original one.

Gaps between detected nuclei, against the 1,153 sentence-ends in the scripts:

| Gap threshold | `raw`: gaps found | per sentence-end | `stretched`: gaps | per sentence-end |
|---|---|---|---|---|
| > 300 ms | 4,692 | 4.07 | 3,696 | 3.21 |
| > 400 ms | 2,555 | **2.22** | 2,079 | **1.80** |
| > 500 ms | 1,781 | 1.54 | 1,504 | 1.30 |
| > 600 ms | 1,441 | **1.25** | 1,209 | **1.05** |
| > 800 ms | 952 | 0.83 | 608 | 0.53 |
| > 1000 ms | 458 | 0.40 | 215 | 0.19 |

**The brief's proposed 400 ms threshold is not a sentence boundary detector.** It fires
2.22 times per sentence on natural-rate audio — most of what it finds is clause-internal,
a comma, or an unrecovered unvoiced stretch that the detector merely failed to bridge.
Treating each hit as "new sentence" and snapping the pointer would inject a large jump
error roughly every other landmark.

Two things follow, and one of them is good news:

- **Bad news: a gap is not a unique landmark.** These counts are *counts only* — this spike
  did not verify that a >600 ms gap lands at the same *place* as a sentence end, only that
  there are about as many of each. A hard "gap ⇒ jump to next sentence" rule is not
  supportable on this evidence.
- **Good news: landmarks are dense.** Gaps > 400 ms occur every ~6.1 detected syllables
  (`raw`) — about every 4 words. Between two landmarks only 6 syllables elapse, so even at
  a 20% count error the accumulated drift between landmarks is ~1.2 syllables. **Drift is
  only a problem because it integrates; with a landmark every 4 words it never gets the
  chance to.**

So the design this spike actually supports is not "count syllables and advance", it is
**align, don't integrate**: treat the observed sequence of (inter-pause interval,
syllables-in-that-interval) as a fingerprint and match it against the same sequence derived
from the script — a DTW or Viterbi alignment over ~6-syllable segments, resynchronising
continuously and never accumulating. The detector's job in that design is producing a
locally-correct *rate and rhythm*, which §3 shows it does well (recall stable to ±2% across
decks), rather than a globally-correct *count*, which §3 shows it does badly.

---

## 8. What I would need from real human audio to be confident

In priority order:

1. **20–30 minutes of the actual lecturer reading actual teleprompter text**, recorded on
   the actual microphone in the actual room, with the script known exactly. Everything here
   is an ElevenLabs voice; not one number transfers without this.
2. **Syllable-level hand annotation of ~3 minutes of it** (~750 nuclei). Everything above
   scores aggregate counts per slide, which cannot distinguish "missed 20% of syllables"
   from "missed 30% and hallucinated 10%". Those two failure modes want opposite fixes, and
   this corpus cannot tell them apart. This is the single biggest evidential gap.
3. **Deliberate rate variation** — the same passage read slow, normal and fast. The −11 to
   −13 pp/Hz slope is the finding most likely to decide the whole question, and it was
   measured on a 1.2× resampling artefact rather than on a human genuinely speaking faster.
   Those are not the same thing: resampling shifts formants, a faster human reduces vowels.
4. **Recordings containing the things the synthetic corpus has none of**: breaths, filled
   pauses, false starts, a cough, a sip of water, page turns. Specifically to measure the
   *false positive* rate, which this spike literally could not measure — every single error
   here is an undercount.
5. **A second speaker.** k = 0.816 is one voice. Whether per-speaker calibration is a
   30-second one-off or something that must run continuously depends entirely on how much
   k varies across people, and n=1 says nothing.

Until at least (1) and (2) exist, the defensible position is: **syllable-nuclei detection
is a viable local rhythm sensor for a pause-anchored aligner, and is not viable as a
free-running word counter.** Building the pacer as an aligner is worth doing; building it
as an integrator is not.
