# Design: the 2h2.us grader, for two courses and team projects

**Status:** proposed
**Date:** 2026-08-20
**Component:** `~/code/fivex/mod_node/modules/git-grader`

---

## Summary

The hosted grader works for small rubrics and times out on large ones. The
`grade-repos` skill records the consequence bluntly:

> `2h2.us` times out at ~300s on the sprint rubrics (whole-project reads),
> returning `failed:claude` with a null `errorMessage` and no archived trace.
> Every verified grade in this semester's `provenance.json` is a local
> `grd_local_*` run. This skill is the grading path of record; the webhook is
> not a fallback for sprint rubrics.

CS 3540 makes that unacceptable. Its whole submission model is *push → webhook →
issue*, promised to students in the syllabus, the submission-mechanics page, and
all 48 assignment bodies. A grader that cannot finish a `cs3540-game-project`
run is a grader that cannot grade 42% of the course.

This spec covers four changes: **scope the file universe**, **budget per
rubric**, **preserve the trace on failure**, and **support team ranking**. Plus
one small operational fix in `grading-ops`.

---

## 1. The timeout is a symptom; the file universe is the cause

`runner.service.ts` runs one `claude --print` per (repo, rubric) with
`claudeTimeoutMs: 300_000`, in `cwd: repoDir`, with no constraint on what the
agent may read.

The local skill, which succeeds where the hosted grader fails, does constrain it:

> **Scope to source first.** The file universe for grading is `git ls-files`
> (tracked files only). Never read, cite as evidence, or assess dependency and
> build artifacts: `node_modules/`, `dist/`, `build/`, `out/`, `.next/`,
> `coverage/`, `vendor/`, `__pycache__/`, `.dart_tool/`, minified bundles.

A student game repo with `node_modules/` committed or a Flutter `build/` tree is
not a hard grading problem — it is tens of thousands of files the agent has no
reason to open. Raising the timeout buys time to read more of what should never
have been read.

**Change.** The rendered prompt carries the file universe explicitly:

- Run `git ls-files` in `repoDir`, filter the exclusion list above, and inject
  the result into the prompt as the authoritative file list.
- State in the prompt that files outside that list must not be read.
- When the filtered list exceeds a threshold (say 2,000 files), include a
  directory-level summary plus the list, and say so.

This is the highest-value change and it is independent of the rest.

## 2. Budget per rubric, not per installation

`claudeTimeoutMs` is a single number for every rubric. `cs3540-devlog` grades one
markdown file; `cs3540-game-project` grades a whole game against six criteria.

**Change.** Timeout becomes per-rubric, declared in the rubric YAML with a
conservative default:

```yaml
slug: cs3540-game-project
title: Game Project
timeout_seconds: 900        # optional; default 300
criteria: [...]
```

`RubricService` already validates rubric shape; extend it to read the optional
field. `runner.service.ts` uses `rubric.timeoutSeconds ?? config.claudeTimeoutMs`.

Rationale for keeping the default: a rubric that needs fifteen minutes should
say so, and the declaration is a useful signal to whoever writes the next one.

## 3. A failure with no trace is not diagnosable

Today a timeout returns `failed:claude` with a null `errorMessage` and **no
archived trace**, because the trace is only written after a successful run:

```ts
if (claude.timedOut) { return await this.fail(...); }
...
const tracePath = path.join(graderDir, 'claude-trace.jsonl');
if (!fsSync.existsSync(tracePath)) await fs.writeFile(tracePath, claude.stdout, 'utf8');
```

The partial stdout is exactly what would show whether the agent was reading
`node_modules/` when the clock ran out.

**Change.** Write the trace **before** the timeout check, always, and include
in `errorMessage`: the elapsed time, the file count in scope, and the last tool
call observed in the trace. A failure should tell you what it was doing.

## 4. Team ranking

`cs3540-game-project` grades a shared repo and must yield one project score plus
an ordering of contributors.

**Change.** After a successful project-rubric run, a second pass over the same
criteria attributes each to the members who moved it, and emits
`.grader/<rubric>_contributions.json` — schema in the `grade-repos` skill.

Two constraints, both load-bearing:

- **Rank by criteria, never by commit count.** Commit volume answers a different
  question and systematically under-credits design, integration, and debugging.
- **Never write an individual grade into the shared project repo.** The ranking
  is visible to the team; grades are not. Individual grades go to the semester
  directory and to Canvas.

Where evidence does not separate two members, rank them equal. A fabricated
ordering is worse than an honest tie.

## 5. Prompt injection screening

The local skill screens every repo with a cheap model before any grading agent
reads it, and carries the verdict into the grading prompt as **data, not
instruction**. The hosted grader does not.

Student repos in CS 3540 contain a security module by design — students build a
guarded agent and write about prompt injection — so "text that looks like an
injection attempt" will be common and usually legitimate coursework.

**Change.** Port the screening sweep into the runner as a pre-phase. A `flagged`
verdict never blocks grading and never auto-zeroes anyone; it forewarns the
grading prompt and surfaces in the issue for the instructor to judge.

## 6. Course-scoping in grading-ops

`grade_all.sh` hardcodes the MQTT topics:

```bash
-t 'cs3660/grader/runs/+/event'
-t 'cs3660/grader/failures/+'
```

`ORG` is already env-overridable; the topics are not. Running it for CS 3540
enqueues the right repos and then watches a topic nothing publishes to.

**Change.** `COURSE="${COURSE:-cs3660}"`, topics become `$COURSE/grader/...`,
and the publisher side is scoped to match. Same for the two references in
`create_webhooks.sh` and one in `autograde.sh`.

---

## Out of scope

- **Replacing the local skill.** It stays the path of record for bulk end-of-term
  grading, where a human is already in the loop. The webhook is for the
  per-push feedback loop students see.
- **`tools/git_grader/`.** It computes contribution from commit stats, which is
  the model this course explicitly rejects. Leave it; do not extend it.
- **Grade posting to Canvas.** Needs an API token and is a separate piece.

## Success criteria

1. A `cs3540-game-project` run over a realistic game repo completes inside its
   declared budget.
2. A timeout produces an archived trace and an `errorMessage` naming the elapsed
   time, the file count in scope, and the last tool call.
3. `git ls-files` scoping is observable in the rendered prompt.
4. A team project produces one score and a criteria-attributed ranking, with no
   individual grade written into the shared repo.
5. `COURSE=cs3540 ./grade_all.sh` watches a topic that receives events.
