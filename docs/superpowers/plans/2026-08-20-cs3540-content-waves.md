# CS 3540 Content Waves Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** All 39 cheat sheets and 14 lecture scripts for CS 3540, authored to `cheatsheets/SPEC.md`
and loadable by the course_builder glob loaders.

**Architecture:** Content authoring in five waves matched to the schedule. Each wave is verified by
SPEC.md §9's three checks (every referenced SVG exists, every SVG is well-formed XML, no orphans)
plus a successful cartridge build.

**Tech Stack:** Markdown, hand-authored SVG, Mermaid, `xmllint`, `dart run bin/build_canvas_zip.dart`.

**Spec:** `docs/superpowers/specs/2026-08-19-cs3540-2026-fall-design.md` (§8.3, §8.4)

## Global Constraints

- **`cheatsheets/SPEC.md` governs**, with the §8.4 amendment: hand-authored SVG for mental models,
  architecture, comparisons and anatomy; **Mermaid** for state machines, sequences, and flowcharts.
- **SVG palette is fixed** — panels `#0b1220`/`#374151`, nodes `#1f2937`/`#60a5fa`, good
  `#064e3b`/`#34d399`, warn `#7c2d12`/`#fb923c`, headings `#fcd34d`, body `#f9fafb`, mute `#9ca3af`,
  edges `#9ca3af`. `viewBox` only — never `width`/`height`. No external fonts.
- **No emoji. No preamble. No outro.** End at "When you're stuck".
- **Production-quality examples** — no stubs, no `// TODO`, no placeholder handlers.
- Every sheet: an early mental-model diagram, a `## Common gotchas`, and a `## When you're stuck`.
- Never `git push`.

## Waves

| Wave | Sheets | Needed by |
|---|---|---|
| 1 | git-collaboration · conformance-vectors · theory-of-fun · game-loop-and-time · determinism-and-replay · game-programming-patterns · cc-the-11-pillars · cc-claude-md · ai-sdlc-spec-driven · writing-a-spec-agents-can-build | Week 3 |
| 2 | entity-component-store · scene-graph-transforms · 2d-rendering · collision-and-spatial-partition · game-feel-and-juice · mda-framework · playtesting · cc-skills · cc-subagents-and-archetypes | Week 6 |
| 3 | 3d-rendering-webgl · shaders-and-materials · pathfinding-and-navigation · game-ai-behavior · difficulty-and-flow · cc-hooks · cc-mcp | Week 10 |
| 4 | procedural-generation · audio-and-procedural-music · cutscenes-and-timelines · storytelling-in-games · asset-pipeline-and-provenance · local-llm-in-games · history-of-games | Week 12 |
| 5 | netcode · p2p-pear-holepunch · performance-profiling · cc-plugins · cc-model-selection · soul-sovereign-council | Week 14 |

Then 14 lecture scripts, one per teaching week, with the frontmatter the loader requires
(`slug`, `week`, `youtube_id`, `companion_sheets`, `reflection_assignment`, `vernacular_tags`).

## Per-wave verification

- [x] Every referenced SVG resolves.
- [x] Every SVG passes `xmllint --noout`.
- [x] No orphan SVGs.
- [x] `dart test` passes.
- [x] Cartridge builds; page count rises by the wave's sheet count.

## Definition of done

- [x] 39 cheat sheets present, each with ≥1 diagram, gotchas, and "when you're stuck".
- [x] 14 lecture scripts with valid frontmatter.
- [x] All three SPEC.md §9 checks clean.
- [x] Cartridge builds with all sheets and lectures as pages/modules.
- [x] `SPEC.md` amended to record the Mermaid allowance.
