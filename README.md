# course_builder

Builds a Canvas Common Cartridge `.imscc` zip for **CS 3660 Advanced Web Development** (UVU) from structured YAML+Markdown source.

## Build

```bash
dart pub get
dart run bin/build_canvas_zip.dart content/cs3660/2026 dist/cs-3660-001-summer-2026.imscc
```

Output: `dist/cs-3660-001-summer-2026.imscc` — importable as Canvas Common Cartridge 1.x.

## Test

```bash
dart test
```

Runs the model + loader + emitter + packager + content-validation test suite.

## Layout

```
bin/build_canvas_zip.dart    CLI entry point
lib/src/
  ims_id.dart                Stable Canvas-style identifier generator
  models/                    Plain Dart model classes
  loaders/                   YAML + markdown ingestion
  emitters/                  Per-Canvas-file XML/HTML emitters
  packager.dart              Zip assembly
content/<year>/              Course content for that year
  course.yaml                Top-level config (groups, rubrics, pages, assignments, modules)
  pages/                     Wiki pages (markdown)
  onboarding/                Week-1 assignment briefs
  reflections/               Weekly lecture reflection prompts
  sprints/                   Team sprint briefs
  cc-artifacts/              Individual Claude Code artifact briefs
  rubrics/                   Per-assignment rubric YAMLs
test/                        Unit tests + content validation
dist/                        Output zips (gitignored)
docs/                        Design spec + implementation plan + reference materials
```

## Adding a new year

1. Copy `content/<course>/<year>/` to `content/<course>/<new-year>/`.
2. Edit `content/<new-year>/course.yaml` for the new dates and any structural changes.
3. Update markdown bodies for content changes.
4. Build: `dart run bin/build_canvas_zip.dart content/<new-year> dist/<new-year>.imscc`.

## Design context

- Spec: [`docs/specs/2026-05-06-cs3660-2026-redesign-design.md`](docs/specs/2026-05-06-cs3660-2026-redesign-design.md)
- Implementation plan: [`docs/plans/2026-05-06-cs3660-2026-canvas-zip.md`](docs/plans/2026-05-06-cs3660-2026-canvas-zip.md)
- Reference inputs: [`docs/reference/`](docs/reference/) — Perfect Framework, Claude Code capabilities, syllabus, calendars

## What's deliberately out of scope

- The hosted LLM service (`llm.uvucs.org`) infra setup
- The LLM grader implementation that consumes student submissions
- The team-generation algorithm with no-repeat invariant
- Recording the YouTube lectures referenced in the schedule

These are separate workstreams referenced from the spec.
