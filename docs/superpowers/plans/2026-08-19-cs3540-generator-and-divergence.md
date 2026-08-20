# CS 3540 Generator, Divergence Metric, and Promotion Gate

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The machinery that turns the class specification into a measurement — K independent
builds, a divergence report attributing every disagreement to a section and its owner, a modal
build promoted and tagged, and a hook that stops the generator editing the vectors it is tested
against.

**Architecture:** The analysis is pure functions over build results, so it is fully unit-testable
without invoking a model. The `claude -p` invocation and the cron schedule are thin shell wrappers
around that core. The guard hook is a `PreToolUse` script tested by invoking it with crafted stdin.

**Tech Stack:** TypeScript 5, vitest, POSIX shell, `jq`. Zero runtime dependencies.

**Spec:** `docs/superpowers/specs/2026-08-19-cs3540-2026-fall-design.md` (§4)

## Global Constraints

- **Zero runtime dependencies** — enforced by `test/constraints.test.ts`.
- **The generator must never be able to edit `spec/` or `conformance/`.** Without that guard the
  measurement is circular: an agent that can weaken a vector will, and divergence silently
  reports success.
- **Diagnosis follows the spec's three-way table exactly:**
  builds agree + match vector ⇒ `ok`; builds disagree ⇒ `ambiguous-prose`;
  builds agree but miss the vector ⇒ `wrong-vector`.
- **Only `ambiguous-prose` blocks promotion.** A `wrong-vector` means the engine is
  self-consistent and the spec's own test is wrong — report it loudly, do not punish the engine.
- Never `git push`. Never invoke a model as part of a test.

---

### Task 1: Divergence analysis

**Files:**
- Create: `engine-spec/src/divergence.ts`
- Create: `engine-spec/test/divergence.test.ts`

**Interfaces:**
- Consumes: `VectorResult` from `src/runner.ts`.
- Produces:
  - `interface BuildResult { buildId: string; specSha: string; results: VectorResult[] }`
  - `type Diagnosis = 'ok' | 'ambiguous-prose' | 'wrong-vector'`
  - `interface VectorDivergence { vectorId; section; modalHash; agreement; distinctHashes; diagnosis }`
  - `interface SectionReport { section; score; vectors; blocking }`
  - `analyzeDivergence(builds: BuildResult[]): { vectors: VectorDivergence[]; sections: SectionReport[] }`
  Task 2 imports all of these.

- [ ] **Step 1: Write the failing test**

Cover, at minimum:
- unanimous agreement matching the vector ⇒ `ok`, agreement `1`
- one build out of three differing ⇒ `ambiguous-prose`, agreement `2/3`
- all builds agreeing on a value the vector does not expect ⇒ `wrong-vector`, agreement `1`
- section score is the mean agreement across that section's vectors
- section is `blocking` only when it holds an `ambiguous-prose` vector
- a `wrong-vector` section is **not** blocking
- vector ids map to sections by their `<section>/` prefix
- an empty build list throws rather than reporting vacuous success

- [ ] **Step 2: Run to verify it fails**

```bash
cd /Users/michael/code/uvu/cs3540-content/engine-spec && npx vitest run test/divergence.test.ts
```

Expected: FAIL — `src/divergence.ts` does not exist.

- [ ] **Step 3: Implement `src/divergence.ts`**

Modal hash is the most frequent `actual` across builds for a vector; ties break toward the value
matching `expected`, then toward the numerically smallest so the result is deterministic.
`agreement` is modal count over build count.

- [ ] **Step 4: Run to verify it passes, typecheck, commit**

---

### Task 2: Modal build selection and the promotion gate

**Files:**
- Create: `engine-spec/src/promote.ts`
- Create: `engine-spec/test/promote.test.ts`

**Interfaces:**
- Consumes: everything from Task 1.
- Produces:
  - `selectModalBuild(builds: BuildResult[]): BuildResult` — the build agreeing with the most
    others across all vectors; ties break by `buildId` ascending.
  - `decidePromotion(builds: BuildResult[]): { promote: boolean; build: BuildResult | null; blockedBy: string[]; version: string | null }`
  - Version format: `v<YYYY.MM.DD>+spec.<sha7>`, with the date supplied by the caller — never
    read from the clock, so the function stays testable and reproducible.

- [ ] **Step 1: Write the failing test**

Cover: modal selection with a clear majority; tie-breaking by `buildId`; promotion blocked when
any section is `ambiguous-prose`, naming the blocking sections; promotion **allowed** when the
only defect is `wrong-vector`; version string format; and that a blocked decision returns
`build: null` rather than a build nobody should ship.

- [ ] **Step 2: Run to verify it fails**
- [ ] **Step 3: Implement `src/promote.ts`**
- [ ] **Step 4: Run to verify it passes, typecheck, commit**

---

### Task 3: The conformance guard hook

**Files:**
- Create: `engine-spec/.claude/hooks/protect-conformance.sh`
- Create: `engine-spec/.claude/settings.json`
- Create: `engine-spec/test/guard-hook.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: a `PreToolUse` hook that exits `2` for any `Edit`/`Write` whose `file_path` falls under
  `spec/` or `conformance/`, and `0` otherwise.

- [ ] **Step 1: Write the failing test**

Invoke the script with `spawnSync`, feeding Claude Code's `PreToolUse` event JSON on stdin. Assert:
exit `2` and a stderr message naming the path for `spec/S01-time-and-loop.md`,
`conformance/vectors/S01/x.json`, and a nested path; exit `0` for `src/hash.ts` and `README.md`;
exit `0` for a `Read` of a protected path, since reading is not the risk.

> Test the **blocking** cases first. A guard that has only been watched to allow has not been
> shown to guard.

- [ ] **Step 2: Run to verify it fails** — the script does not exist.

- [ ] **Step 3: Write the hook**

Parse stdin with `jq`, match `tool_name` against `Edit|Write|NotebookEdit`, extract
`.tool_input.file_path`, normalize it relative to the repo root, and exit `2` with an explanatory
stderr message when it is under a protected directory.

- [ ] **Step 4: Register it in `.claude/settings.json`** as a `PreToolUse` hook with matcher
`Edit|Write|NotebookEdit`.

- [ ] **Step 5: Run to verify it passes, then commit**

---

### Task 4: Generator wiring and the schedule

**Files:**
- Create: `engine-spec/generator/PROMPT.md`
- Create: `engine-spec/generator/build.sh`
- Create: `engine-spec/generator/verify.sh`
- Create: `engine-spec/generator/analyze.ts`
- Create: `engine-spec/generator/README.md`

**Interfaces:**
- Consumes: `analyzeDivergence`, `decidePromotion`.
- Produces: `build.sh <n>` writing `out/build-<n>/`; `verify.sh <n>` writing
  `out/build-<n>/results.json`; `analyze.ts` reading every `results.json` and writing
  `reports/<date>/divergence.json` plus a markdown summary.

- [ ] **Step 1: Write `PROMPT.md`** — the build prompt, with an explicit instruction that the
      agent may write only under `out/`, and that `spec/` and `conformance/` are read-only. The
      hook enforces this; the prompt states it so a compliant agent never tries.

- [ ] **Step 2: Write `build.sh`** — `claude -p` with `--append-system-prompt` carrying the scope
      and stop conditions, narrowed tools, output to `out/build-<n>/`.

- [ ] **Step 3: Write `verify.sh`** — load every vector, run it against the built engine via
      `runAll`, write `results.json`.

- [ ] **Step 4: Write `analyze.ts`** — glob `out/build-*/results.json`, call `analyzeDivergence`
      and `decidePromotion`, emit the report.

- [ ] **Step 5: Document the schedule in `generator/README.md`** — K=3, the night before each
      class session, with the note that K is raised if the sample looks noisy and that this is an
      unattended agent committing code, so its guard hook is not optional.

> Task 4 is wiring around tested logic. It is verified by running it end-to-end against a
> deliberately broken hand-written engine, not by unit tests of shell scripts.

---

## Definition of done

- [ ] `npx vitest run` passes in `engine-spec`.
- [ ] `npx tsc --noEmit` is clean.
- [ ] The three-way diagnosis matches the spec table, proven by test.
- [ ] `wrong-vector` does not block promotion; `ambiguous-prose` does.
- [ ] The guard hook has been **observed exiting 2** for `spec/` and `conformance/` writes.
- [ ] `decidePromotion` never returns a build when blocked.
- [ ] Zero runtime dependencies still asserted.

## Not in this plan

Running an actual `claude -p` build (needs student sections to exist), registering the cron
schedule on the instructor account, and pushing to `uvucs3540/engine`.
