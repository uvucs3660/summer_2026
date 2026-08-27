# Lecture Decks — CS 3540

**Instructor materials, not Canvas content.** They live one level below `lectures/` because the
course-builder's lecture loader globs `lectures/*.md` non-recursively, so anything in here is
invisible to the `.imscc` export. Same trick as CS 3660.

**28 decks — two per week, W1–W14**, following the course's two tracks:

| | |
|---|---|
| `wNN-game-<slug>.md` | The craft — loop, determinism, rendering, collision, AI, netcode |
| `wNN-ai-<slug>.md` | Claude Code — pillars, CLAUDE.md, skills, subagents, hooks, MCP, soul |

The AI track is sequenced so **every Forge artifact is taught 1–3 weeks before it is due**. Two
Game decks are new material rather than a re-cut of `lectures/wNN-*.md`: W4 *The Engine Seams*
(written against `spec/S00-overview.md`, landing before the Sep 13 claim deadline) and
W14 *Shipping*.

Lectures are pre-recorded, so the deck count is independent of the meeting calendar — W4 and W9
meet once and W15 not at all, but each of the fourteen weeks still gets both recordings.

Lectures are **pre-recorded and watched before class**, so the deck's speaker notes *are the
recording script*. There is deliberately no separate script file — a sibling `wNN-script.md` would
drift from the slides the first time either was edited alone.

## Build

```bash
python3 -m venv .venv && ./.venv/bin/pip install python-pptx   # once
./.venv/bin/python build_pptx.py                               # all decks
./.venv/bin/python build_pptx.py w02-game-the-loop.md          # just one
```

Output is a real, editable `.pptx` — native text boxes, not slide images — with each slide's script
in the PowerPoint speaker-notes pane. The build prints a word count and an estimated runtime at
140 wpm.

`.pptx` output is gitignored: the markdown is the source, the deck is a build artifact.

## Source format

Frontmatter, then slides separated by a line containing only `---`. The first slide is the title
slide. `NOTES:` ends a slide and everything after it becomes that slide's script.

````markdown
---
track: game
week: 2
title: The Loop
subtitle: Fixed Timestep, the Accumulator, and Why 20Hz
runtime: 30
---

# Slide heading

- A bullet with **emphasis** and `inline_code`
  - An indented sub-point

## A blue sub-heading

> A pull-quote, rendered in amber italic

```js
const STEP = 0.05;
```

![](game-loop-and-time-accumulator.svg)

NOTES:
Spoken script for this slide.
````

Body font size auto-shrinks as a slide gets busier. Put a diagram and text on the same slide and the
text takes a narrower column with the diagram beside it; a diagram alone gets the full width.

## Diagrams

Author new diagrams with `diagramkit.py`, which writes straight into
`../../cheatsheets/diagrams/` — lecture artwork is shared with the Canvas cheat sheets rather than
kept deck-local, so students get every figure too. Name a new diagram `<cheatsheet-stem>-<aspect>`
and reference it from that cheat sheet.

The kit refuses to save a diagram with any of four defects, each of which shipped by hand at least
once before the check existed:

| Guard | Catches |
|---|---|
| clipping | a text baseline within a descender of its panel's bottom edge |
| glyphs | characters the sans stack lacks (`∝ ↯ ⇢ …`) — they render as tofu |
| light-on-dark | near-white text with no dark rectangle behind it, invisible on Canvas's white page |
| width | text whose estimated extent overruns its container |

The first three are exact. The width check is an estimate at 0.52em/char and is the only one that
can be wrong in either direction.

Every diagram carries a full-bleed `#0b1220` background. Without it the artwork renders as floating
panels on Canvas's white page, where the amber titles sit near 1.4:1 contrast.

Reference any file from `../../cheatsheets/diagrams/` by bare filename. SVGs are rasterized at
2000px through `rsvg-convert` into `_render/` (gitignored, rebuilt when the SVG is newer).

The diagrams are already dark-themed on `#0b1220` with amber/blue/green accents, which is why the
decks use that palette — the artwork drops in without recoloring.
