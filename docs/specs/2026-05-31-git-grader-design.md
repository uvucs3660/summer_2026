# CS 3660 Git-Grader — design

**Date:** 2026-05-31
**Author:** mhunter@hunter.org (with Claude Code)
**Status:** approved for implementation

## Purpose

Grade student sprint deliverables automatically by cloning each student's
GitHub repository, running a Claude analysis against the sprint's rubric
YAML (from `course_builder/content/2026/rubrics/`), and posting the
resulting grade + justification as a GitHub issue on the student's repo.
Runs are triggered on demand by curl and on a cron at each sprint's due
date. State, history, and live progress are exposed via REST and MQTT for
a small dashboard.

## Scope

In scope:

- A new `git-grader` module in `mod_node` (fivex polyglot monorepo).
- HTTP endpoints under `2h2.us/git-grade-web-hook` and `2h2.us/git-grade/*`.
- A serial in-memory job queue with dedupe.
- Pipeline: clone → render prompt → spawn `claude` CLI → validate output
  → post GitHub issue via `gh` CLI → persist run record.
- Run records persisted in mod_node's existing data-store.
- MQTT event stream on `mqtt.uvucs.org` for live observability.
- A small React dashboard served from `mod_node/html/grader/`.
- Cron entries on sprint due dates.

Out of scope (parking lot):

- Per-author grading inside a shared team repo (sprint 3, TBD).
- Re-grading on every push (GitHub webhook receiver doing real work).
- Canvas gradebook write-back.
- Authentication on the trigger or dashboard.

## Decisions made during brainstorming

| Decision | Choice | Notes |
|---|---|---|
| Trigger | curl on-demand + cron at sprint deadline | No GitHub webhook driving analysis in v1; the existing `2h2.us/git-grade-web-hook` URL becomes the curl endpoint. |
| Grade granularity | Individual | Sprints 1 & 2 are individual deliverables in 2026 — one repo per student. Sprint 3 TBD. |
| Rubric selection | Default in module config; curl can override | Default like `defaultRubric: sprint-1-job-pack`. Curl: `{"repo":"…","rubric":"sprint-2-messaging"}`. |
| Rubric source | Bundled into the module at build time | Copy `course_builder/content/2026/rubrics/*.yaml` into `modules/git-grader/rubrics/` during the mod_node build. |
| Delivery | GitHub issues | One issue per `(repo, rubric)` discovered by label; subsequent runs add comments. Uses existing `GIT_PAT`. |
| Trigger auth | None; org allowlist only | Reject (HTTP 400) any repo not under `uvucs3660` (configurable to add `uvucs3540` for fall). |
| Workspace | Fresh tmpdir clone per run, deleted after | Stateless, no cleanup logic. |
| Same-repo collisions | Dedupe — return the existing runId | In-memory `Map<repo, runId>` cleared at run end. |
| Global concurrency | Serial — one run at a time | Response includes queue position + ETA. |
| Failure retries | Network failures auto-retry; model/validate failures do not | `republish` endpoint covers the surgical retry case. |
| Spec home | `course_builder/docs/specs/` | Sibling to the 2026 redesign spec. |
| Implementation home | `fivex/mod_node/modules/git-grader/` | Follows mod_node's modular plugin pattern. |

## Architecture

### Module shape

```
fivex/mod_node/modules/git-grader/
├── module.json              # declares routes + mqtt publishes
├── index.ts                 # lifecycle: onStart spawns the worker; onStop drains
├── config/
│   └── default.yaml         # defaultRubric, allowedOrgs, archiveRetentionDays,
│                            # claudeTimeoutMs (default 300_000),
│                            # seedAverageRunSeconds (default 90 — used until
│                            # 5 real runs accumulate, then EWMA takes over)
├── rubrics/                 # copied from course_builder at build time
│   ├── sprint-1-job-pack.yaml
│   ├── sprint-2-messaging.yaml
│   └── …
├── templates/
│   └── grade-prompt.md.tmpl # the fixed "grade this project" instructions
├── routes/
│   ├── grade.routes.ts
│   └── grade.controller.ts
├── services/
│   ├── queue.service.ts     # serial in-memory queue + dedupe map
│   ├── runner.service.ts    # one-job-at-a-time worker
│   ├── rubric.service.ts    # loads bundled YAML by slug
│   ├── prompt.service.ts    # renders template + rubric → grade-prompt.md
│   ├── validator.service.ts # checks grade.json against rubric
│   ├── publisher.service.ts # mqtt event emitter
│   └── archive.service.ts   # per-run archive dir + retention sweep
├── html/                    # built dashboard SPA (vite dist output)
└── tests/
    ├── unit/
    ├── integration/
    └── contract/            # gated behind RUN_CONTRACT_TESTS=1
```

The dashboard SPA source lives in a sibling Vite project; its `dist/`
output is copied into `html/` at build time, then served by mod_node's
existing static file handler at `2h2.us/grader/`.

### HTTP surface

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/git-grade-web-hook` | Enqueue a grading run. Body: `{ "repo": "uvucs3660/foo", "rubric"?: "sprint-1-job-pack" }`. |
| `GET`  | `/git-grade/runs/:runId` | Status + grade + issue URL once available. |
| `GET`  | `/git-grade/runs?repo=org/repo` | All runs for one repo (for history view). |
| `GET`  | `/git-grade/queue` | Current job + pending list with ETAs. |
| `GET`  | `/git-grade/failures?since=24h` | Failure digest grouped by phase. |
| `POST` | `/git-grade/runs/:runId/republish` | Re-post the existing report; no model invocation. |
| `GET`  | `/git-grade/runs/:runId/files/*` | Per-run archive files (prompt, trace, grade.json, report.md). |

### `POST /git-grade-web-hook` response

```json
{
  "runId": "grd_2026-05-31T18-22-04Z_a1b2c3",
  "repo": "uvucs3660/sprint1_alice_summer_2026",
  "rubric": "sprint-1-job-pack",
  "status": "queued",
  "queuePosition": 7,
  "queueSize": 12,
  "etaSeconds": 630,
  "statusUrl": "https://2h2.us/git-grade/runs/grd_…",
  "deduped": false
}
```

`deduped: true` signals that the same repo was already in flight; the
`runId` and `statusUrl` point at the existing run, and no new work is
started.

### Worker pipeline (one job, end-to-end)

```
job: { runId, repo, rubric }
  │
  ▼
1. ENTER
   • update data-store /grades/<runId>: status=running, startedAt=now
   • inFlight.set(repo, runId)
   • mqtt: cs3660/grader/runs/<runId>/event { phase: "queued" → "running" }
  │
  ▼
2. CLONE
   tmpDir = await mkdtemp("/tmp/grader-")
   git clone --depth=50 https://<token>@github.com/<repo>.git <tmpDir>/repo
   commitSha = git -C <tmpDir>/repo rev-parse HEAD
  │
  ▼
3. RENDER PROMPT
   mkdir <tmpDir>/repo/.grader
   render templates/grade-prompt.md.tmpl with:
     {{rubric_yaml}}, {{repo_full_name}}, {{commit_sha}},
     {{run_id}}, {{student_username}} (parsed from repo name)
   write to <tmpDir>/repo/.grader/grade-prompt.md
  │
  ▼
4. RUN CLAUDE
   cwd = <tmpDir>/repo
   spawn: claude --print --dangerously-skip-permissions \
                 --output-format=stream-json \
                 < .grader/grade-prompt.md
   timeout: 5 min hard kill via AbortController
   capture stream-json to <tmpDir>/repo/.grader/claude-trace.jsonl
   expect on exit:
     • .grader/grade-report.md
     • .grader/grade.json
  │
  ▼
5. VALIDATE
   parse grade.json; assert against schema and rubric:
     - schemaVersion == "1.0"
     - rubric matches job.rubric
     - one criterion per rubric criterion
     - chosenRatingDescription verbatim-matches a rubric rating
     - points matches that rating's points
     - justification length >= 40
     - evidence length >= 1
     - totalPoints == sum(criteria.points)
     - maxPoints == sum(rubric criteria max points)
  │
  ▼
6. POST TO GITHUB
   label = "auto-grade:" + rubric
   existing = gh issue list --repo <repo> --label <label> --state open --json number,title
   if existing.length > 0:
     gh issue comment <number> --body-file .grader/grade-report.md
   else:
     gh issue create --title "Auto-grade: <rubric> — <date>" \
                     --label <label> --body-file .grader/grade-report.md
  │
  ▼
7. PERSIST + ARCHIVE
   copy .grader/{grade-prompt.md, grade-report.md, grade.json,
                 claude-trace.jsonl} → /var/grader/runs/<runId>/
   PUT data-store /grades/<runId> ← full run record (see schema below)
   update rolling averageRunSeconds (EWMA over last 20 runs)
   mqtt: cs3660/grader/runs/<runId>/event { phase: "done", status: "ok" }
   mqtt: cs3660/grader/queue/snapshot
  │
  ▼
8. EXIT
   inFlight.delete(repo)
   rm -rf tmpDir
   worker loops to next job
```

Every phase transition publishes an MQTT event before moving on; the
`try/finally` around the whole step guarantees `inFlight.delete` and
`rm -rf tmpDir` always run.

## Prompt template and grade contract

### Prompt template

The template at `templates/grade-prompt.md.tmpl` is rendered into the
clone's `.grader/grade-prompt.md` and fed to `claude --print` via stdin.
It declares the role, inlines the full rubric YAML, gives explicit
grading instructions, and pins the exact output contract.

Key constraints the prompt imposes on the model:

- For each criterion, choose **exactly one** rating verbatim from the
  rubric. No interpolated scores, no skipped criteria.
- When evidence is mixed, pick the **lower** rating and explain why.
- Cite every rating with concrete evidence: file paths with line ranges,
  commit SHAs, or quoted output. No vague justifications.
- Write **exactly two files**: `.grader/grade.json` and
  `.grader/grade-report.md`. Do not modify any other file. Do not run
  `git add`, `git commit`, or `git push`.

### `grade.json` schema

```json
{
  "schemaVersion": "1.0",
  "runId": "grd_…",
  "repo": "uvucs3660/sprint1_alice_summer_2026",
  "commitSha": "abc1234567890",
  "rubric": "sprint-1-job-pack",
  "totalPoints": 87,
  "maxPoints": 100,
  "criteria": [
    {
      "slug": "required-outputs",
      "title": "Required outputs",
      "chosenRatingDescription": "All three artifacts present and correctly tailored to the inputs.",
      "points": 25,
      "maxPoints": 25,
      "justification": "All three PDFs render for the sample inputs in tests/fixtures/; cover-letter generation uses input-specific phrasing.",
      "evidence": [
        { "path": "src/generators/resume.ts", "lines": "18-94", "note": "PDF generation pipeline" },
        { "path": "tests/integration/pdf.test.ts", "lines": "1-60", "note": "End-to-end render test" }
      ]
    }
  ],
  "overallSummary": "Strong submission. Strategy pattern is clean; persistence is implemented but compare-mode is missing.",
  "improvementSuggestions": [
    "Add a compare view for drafts to reach the top tier of the persistence criterion.",
    "Put the deploy behind HTTPS to reach the top tier of the deploy criterion."
  ]
}
```

### `grade-report.md` structure (issue body)

```markdown
# Auto-grade — <rubric title>

**Score: <totalPoints>/<maxPoints>** · commit `<short-sha>` ·
run `<runId>` · <timestamp>

## Criteria

- [x] **<criterion title>** — `<points>/<maxPoints>` — "<chosen rating>"
  - <justification, 1-2 sentences>
  - Evidence: `path/to/file.ts:12-40`, `path/to/other.md`

…

## Summary

<overallSummary>

## Suggested improvements

- <improvementSuggestions[0]>
- …

---
<sub>Generated by the CS 3660 auto-grader. The full prompt and Claude
tool-call trace are archived at run `<runId>`.</sub>
```

## Run record schema (data-store at `/grades/<runId>`)

```json
{
  "runId": "grd_…",
  "repo": "uvucs3660/sprint1_alice_summer_2026",
  "rubric": "sprint-1-job-pack",
  "commitSha": "abc1234567890",
  "status": "ok",
  "startedAt": "2026-05-31T18:22:04Z",
  "finishedAt": "2026-05-31T18:23:51Z",
  "durationSeconds": 107,
  "queuedFor": "00:01:32",
  "deduped": false,
  "grade": { /* full grade.json */ },
  "issueUrl": "https://github.com/uvucs3660/sprint1_alice_summer_2026/issues/3",
  "issueAction": "commented",
  "artifacts": {
    "promptUrl":  "/git-grade/runs/grd_…/files/grade-prompt.md",
    "traceUrl":   "/git-grade/runs/grd_…/files/claude-trace.jsonl",
    "gradeUrl":   "/git-grade/runs/grd_…/files/grade.json",
    "reportUrl":  "/git-grade/runs/grd_…/files/grade-report.md"
  },
  "republishUrl": null
}
```

For failed runs, `status` becomes `failed:<phase>`, `grade` and
`issueUrl` may be null, an `error: { phase, message, exitCode?, stderrTail? }`
field is populated, and (for `failed:post` only) a `republishUrl` is
included.

## Error handling

### Failure taxonomy

| `status` | Where it fires | Auto-retry? | Issue posted? |
|---|---|---|---|
| `failed:clone` | step 2 | once after 5s | no |
| `failed:claude` | step 4 (non-zero exit or 5-min timeout) | **no** | no |
| `failed:validate` | step 5 | **no** | no |
| `failed:post` | step 6 (`gh` call) | once after 5s, then once after 60s | maybe |
| `failed:interrupted` | startup recovery sweep | no | no |
| `ok` | step 8 | n/a | yes |

The hard rule: only **network-shaped** failures auto-retry. Anything
that involves Claude or the rubric never auto-retries — the cost of
running again ($) and the cost of posting the wrong thing (a wrong
grade in a student's repo) are both high.

### Republish endpoint

```
POST /git-grade/runs/:runId/republish
```

For `failed:post` only. Re-reads the archived `grade-report.md` and
re-runs the `gh` find-or-create block. No model invocation, no clone.

### Startup recovery

On `index.ts#onStart`, scan `/grades/*` for `status: "running"` with no
`finishedAt`. Mark those as `failed:interrupted`, log the runIds,
publish `cs3660/grader/failures/<rubric>` events for each. Prevents
stale in-flight entries from blocking dedupe forever.

### Process and disk hygiene

- Subprocess: `claude` spawned with `detached: false` and a 5-min hard
  kill via `AbortController`.
- Tmpdir: `try/finally` around the whole worker step guarantees
  `rm -rf /tmp/grader-*`.
- Archive: daily sweep deletes per-run dirs older than
  `archiveRetentionDays` (default 180).

## MQTT events

Broker: `mqtt.uvucs.org` (the class broker, already used by Project 1
and Project 3 work). QoS 0. Payloads <500 bytes.

| Topic | Fires when | Payload shape |
|---|---|---|
| `cs3660/grader/runs/<runId>/event` | Every phase transition | `{ runId, repo, rubric, phase, status, ts, ...phase-specific fields }` |
| `cs3660/grader/queue/snapshot` | Enqueue, dequeue, drain | `{ size, currentRunId, pending: [{ runId, repo, etaSeconds }] }` |
| `cs3660/grader/failures/<rubric>` | Any `failed:*` status | `{ runId, repo, rubric, phase, errorMessage }` |

`phase` values: `queued`, `running`, `cloning`, `rendering`,
`claude-start`, `claude-done`, `validating`, `posting`, `persisting`,
`done`, `failed`. When `phase: "failed"`, the payload's `status` field
carries the full taxonomy value (e.g. `failed:claude`) so subscribers
can dispatch on it without parsing the topic.

Declared in `module.json` under `mqtt.publishes`. No subscriptions in
v1. Bridge to the dashboard is the broker's standard `wss://` interface;
no per-event REST polling needed for live views.

## Dashboard

Small React + Vite SPA shipped from `mod_node/html/grader/`. Served by
mod_node's existing static file handler at `2h2.us/grader/`. No auth
(matches the trigger's auth model — read-only views of public
issue-shaped data).

| Path | Source endpoint | Live updates via |
|---|---|---|
| `/grader/` (queue) | `GET /git-grade/queue` | MQTT `cs3660/grader/queue/snapshot` |
| `/grader/runs/:runId` | `GET /git-grade/runs/:runId` | MQTT `cs3660/grader/runs/<runId>/event` |
| `/grader/failures` | `GET /git-grade/failures?since=24h` | MQTT `cs3660/grader/failures/+` |
| `/grader/repos/:org/:repo` | `GET /git-grade/runs?repo=org/repo` | polled (rare view) |

Stack: plain React, Vite, MQTT.js (browser WebSocket transport). No
router beyond hash-routes; no state library. ~500 LOC target.

## Testing strategy

### Testable seams

External boundaries are exposed as injectable factories:

```ts
export interface SpawnableProcess {
  run(opts: { command: string; args: string[]; cwd?: string;
              stdin?: string; timeoutMs?: number; })
    : Promise<{ exitCode: number; stdout: string; stderr: string }>;
}
```

`runner.service.ts` depends on three: `gitProc`, `claudeProc`, `ghProc`.
Default factories shell out to the real binaries; tests swap in doubles.
**No internal service is ever stubbed** — queue, validator, prompt
renderer, rubric loader, publisher all run real in tests.

### Test layers

| Layer | Lives in | Covers | External cost |
|---|---|---|---|
| Unit | `tests/unit/` | rubric loader, prompt renderer (snapshot), grade validator (table of valid + invalid fixtures), queue (with stub runner) | zero |
| Integration | `tests/integration/` | runner with stubbed factories exercises full pipeline; HTTP routes via supertest; MQTT publisher with stub client | zero |
| Contract | `tests/contract/` | real `claude --print` against a baked-in tiny fixture repo; asserts both output files exist, `grade.json` validates, score in sane band. Gated behind `RUN_CONTRACT_TESTS=1`. | ~$0.20 per run, ~2 min |
| Manual smoke | `bin/grade-once.ts` | one-shot CLI for manual grading or post-deploy verification | $0.20–$0.50 |

### Regression test commitments

- Every bad `grade.json` Claude produces in the wild → `tests/fixtures/invalid-grades/`.
- Every repo Claude misgrades → `tests/fixtures/contract-cases/` with rubric and expected score band.
- Every `gh` error path that bites → `tests/integration/post.test.ts` with stubbed `ghProc`.

## Build order

```
PHASE 1  — Static pieces                                  ~1 day
  Deliverable: bin/render-prompt.ts <rubric-slug> <repo-path>
  Includes:    rubric.service, prompt.service, validator.service + unit tests.
  Smoke test:  paste rendered prompt into a manual claude session;
               verify grade.json is producible and validates.

PHASE 2  — Subprocess orchestration                       ~1 day
  Deliverable: bin/grade-once.ts <repo> [<rubric>]
               full clone → render → claude → validate → gh, synchronous.
  Includes:    runner.service with real spawn factories
               + integration tests with stubbed factories.

PHASE 3  — Queue + dedupe                                 ~½ day
  Deliverable: queue.service wrapping the runner.
  Includes:    bin/grade-queue.ts enqueues a list of repos and drains.

PHASE 4  — HTTP module                                    ~1 day
  Deliverable: modules/git-grader/ registered; POST /git-grade-web-hook
               live behind caddy at 2h2.us; GET endpoints for queue, runs,
               failures; republish endpoint.

PHASE 5  — Persistence + MQTT                             ~1 day
  Deliverable: run records written to data-store; archive directory;
               startup recovery; MQTT events published at every phase
               transition; queue snapshots on every change.

PHASE 6  — Cron + sprint deadlines                        ~½ day
  Deliverable: cron entries that fire curls for every student repo
               at each sprint's due date.

PHASE 7  — Dashboard                                      ~1 day
  Deliverable: React + Vite SPA in mod_node/html/grader/.
               Queue, run-detail, failures, per-repo history views.
               Live updates via MQTT WebSocket.
```

Total: ~6 working days. Phases 1 and 2 each ship a real CLI, so even
if Phase 4 slips you still have manual grading capability.

## Open questions for implementation time (not blockers)

- **Repo-name → student-username parsing rule.** The 2026 naming
  convention isn't documented in `examples/gittools` yet. Decide once
  the first sprint's repos are created.
- **Sprint→rubric→date map for cron.** Could be a YAML alongside the
  module config, or derived from `course_builder/content/2026/sprints/`
  metadata. Defer until Phase 6.
- **Whether to copy rubrics during `npm build` or via a sibling script.**
  Either works; pick whichever fits the mod_node build conventions when
  Phase 1 starts.
