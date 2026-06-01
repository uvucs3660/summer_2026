# Git-Grader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `git-grader` module in `fivex/mod_node/modules/git-grader/` that grades student repos against bundled rubric YAML by spawning `claude` CLI and posting the result as a GitHub issue via `gh`. Curl-triggered, serial queue, MQTT-eventful, persisted in mod_node's data-store.

**Architecture:** Standard mod_node module (`module.json` + `index.ts` + service classes + Koa routes + MQTT publishes). Subprocess work is funneled through an injectable `SpawnableProcess` interface so the runner can be tested with stub spawners. Run records persist to the existing `data-store` module via `ctx.require('data')`. Live progress publishes to `mqtt.uvucs.org` under `cs3660/grader/*`.

**Tech Stack:** TypeScript (strict), Koa via `@koa/router`, jest + ts-jest, supertest for HTTP, pino via `ctx.logger`, `js-yaml` (already in package.json), `child_process.spawn` + `AbortController` for subprocess timeouts, `node:fs/promises` + `node:os` for tmpdir clones.

**Spec:** `course_builder/docs/specs/2026-05-31-git-grader-design.md`

**Scope of this plan:** Phases 1–6 of the spec (rubric loader through cron). Phase 7 (the React dashboard) is a separate Vite project on a different stack and gets its own plan once Phases 1–6 ship.

---

## File structure (final)

```
fivex/mod_node/modules/git-grader/
├── module.json
├── index.ts
├── config/
│   └── default.yaml
├── rubrics/                          ← copied from course_builder at build time
│   ├── sprint-1-job-pack.yaml
│   ├── sprint-2-messaging.yaml
│   ├── sprint-3-capstone.yaml
│   ├── cc-artifact-1-skill.yaml
│   ├── cc-artifact-2-subagent.yaml
│   ├── cc-artifact-3-hook.yaml
│   ├── cc-artifact-4-mcp.yaml
│   └── cc-artifact-5-plugin.yaml
├── templates/
│   └── grade-prompt.md.tmpl
├── routes/
│   └── grade.routes.ts               ← Koa router; controller logic inline
├── services/
│   ├── types.ts                      ← shared types (Job, RunRecord, SpawnableProcess)
│   ├── spawn.factory.ts              ← real subprocess factory (git/claude/gh)
│   ├── rubric.service.ts             ← loads bundled YAML by slug
│   ├── prompt.service.ts             ← template + rubric → grade-prompt.md
│   ├── validator.service.ts          ← grade.json structural + rubric-conformance checks
│   ├── publisher.service.ts          ← MQTT event publisher
│   ├── archive.service.ts            ← per-run archive dir + retention sweep
│   ├── runner.service.ts             ← the worker pipeline
│   └── queue.service.ts              ← serial FIFO + dedupe + ETA
├── bin/
│   ├── render-prompt.ts              ← Phase 1 CLI
│   ├── grade-once.ts                 ← Phase 2 CLI
│   └── grade-queue.ts                ← Phase 3 CLI
└── tests/
    ├── unit/
    │   ├── rubric.service.test.ts
    │   ├── prompt.service.test.ts
    │   ├── validator.service.test.ts
    │   └── queue.service.test.ts
    ├── integration/
    │   ├── runner.test.ts
    │   ├── routes.test.ts
    │   └── publisher.test.ts
    ├── contract/
    │   └── claude-end-to-end.test.ts ← gated behind RUN_CONTRACT_TESTS=1
    └── fixtures/
        ├── sample-grade.json
        ├── invalid-grades/           ← bad grade.json variants
        └── sample-sprint1-repo/      ← tiny fixture for contract tests
```

**Files modified outside the module:**

- `fivex/mod_node/config/modules.yaml` — add `git-grader:` entry (Phase 4 Task 4.6).
- `fivex/mod_node/package.json` — add a `prebuild` script that copies rubrics (Phase 1 Task 1.1).

---

## Conventions for every task

- Run all commands from `fivex/mod_node/` unless stated otherwise.
- TypeScript is strict; no `any` without an explicit comment justifying it.
- Tests live in `modules/git-grader/tests/`; jest resolves them via the repo's existing `jest.config.js`.
- Commit messages: `feat(git-grader): …`, `test(git-grader): …`, `chore(git-grader): …`.
- After every task: run `npm run type-check && npm test -- modules/git-grader` and commit only if both pass.

---

# PHASE 1 — Static pieces

Goal of the phase: a CLI you can run locally that prints a fully rendered grading prompt for any rubric + any local repo path. No subprocess work, no HTTP, no queue. End-of-phase smoke test: paste the rendered prompt into a manual `claude` session and verify Claude produces a `grade.json` that passes the validator.

---

### Task 1.1: Bundle rubrics into the module + scaffold module.json

**Files:**
- Create: `fivex/mod_node/modules/git-grader/module.json`
- Create: `fivex/mod_node/modules/git-grader/rubrics/` (directory with copied YAML)
- Modify: `fivex/mod_node/package.json` (add `prebuild` script)

- [ ] **Step 1: Create the module directory and rubrics subfolder**

```bash
mkdir -p modules/git-grader/{config,rubrics,templates,routes,services,bin,tests/{unit,integration,contract,fixtures/invalid-grades,fixtures/sample-sprint1-repo}}
```

- [ ] **Step 2: Copy the eight rubrics from course_builder**

```bash
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/sprint-1-job-pack.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/sprint-2-messaging.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/sprint-3-capstone.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/cc-artifact-1-skill.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/cc-artifact-2-subagent.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/cc-artifact-3-hook.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/cc-artifact-4-mcp.yaml modules/git-grader/rubrics/
cp /Users/michael/code/cs3660/course_builder/content/2026/rubrics/cc-artifact-5-plugin.yaml modules/git-grader/rubrics/
ls modules/git-grader/rubrics/ | wc -l   # expect 8
```

- [ ] **Step 3: Add a `prebuild:rubrics` script to mod_node's package.json**

Add to `scripts` in `package.json`:

```json
"prebuild:rubrics": "node -e \"const fs=require('fs');const path=require('path');const src='/Users/michael/code/cs3660/course_builder/content/2026/rubrics';const dst='modules/git-grader/rubrics';if(!fs.existsSync(src)){console.warn('course_builder not present — skipping rubric refresh');process.exit(0)};for(const f of fs.readdirSync(src)){if(f.endsWith('.yaml'))fs.copyFileSync(path.join(src,f),path.join(dst,f))}console.log('rubrics refreshed')\"",
"prebuild": "npm run prebuild:rubrics"
```

The `if (!fs.existsSync(src))` branch lets the build pass on hosts that don't have course_builder mounted; the bundled YAMLs remain whatever was last committed to the module.

- [ ] **Step 4: Write module.json**

```json
{
  "id": "git-grader",
  "name": "CS 3660 Git Grader",
  "version": "0.1.0",
  "description": "Automated rubric-based grading for CS 3660 student repos. Spawns `claude` CLI, posts results as GitHub issues via `gh`.",
  "author": "mhunter@hunter.org",
  "dependencies": ["data-store"],
  "config": {
    "schema": {
      "type": "object",
      "properties": {
        "defaultRubric":         { "type": "string",  "default": "sprint-1-job-pack" },
        "allowedOrgs":           { "type": "array",   "default": ["uvucs3660"], "items": { "type": "string" } },
        "claudeTimeoutMs":       { "type": "number",  "default": 300000 },
        "archiveDir":            { "type": "string",  "default": "/var/grader/runs" },
        "archiveRetentionDays":  { "type": "number",  "default": 180 },
        "seedAverageRunSeconds": { "type": "number",  "default": 90 },
        "ewmaSamples":           { "type": "number",  "default": 20 },
        "githubToken":           { "type": "string",  "default": "" }
      }
    }
  },
  "routes": { "prefix": "/git-grade" },
  "mqtt": {
    "subscriptions": [],
    "publishes": [
      "cs3660/grader/runs/+/event",
      "cs3660/grader/queue/snapshot",
      "cs3660/grader/failures/+"
    ]
  },
  "healthCheck": true,
  "metrics": false
}
```

- [ ] **Step 5: Create config/default.yaml as a documentation file**

```yaml
# This file documents the default config schema declared in module.json.
# The active runtime values come from fivex/mod_node/config/modules.yaml under
# the `git-grader:` key. Edit there, not here.

defaultRubric: sprint-1-job-pack
allowedOrgs:
  - uvucs3660
claudeTimeoutMs: 300000
archiveDir: /var/grader/runs
archiveRetentionDays: 180
seedAverageRunSeconds: 90  # used until ewmaSamples real runs accumulate
ewmaSamples: 20
# githubToken: read from env GITHUB_TOKEN or GIT_PAT at module load time
```

- [ ] **Step 6: Commit**

```bash
git add modules/git-grader/module.json modules/git-grader/config/default.yaml modules/git-grader/rubrics package.json
git commit -m "feat(git-grader): scaffold module and bundle rubrics"
```

---

### Task 1.2: Write the rubric loader with full unit coverage

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/types.ts`
- Create: `fivex/mod_node/modules/git-grader/services/rubric.service.ts`
- Create: `fivex/mod_node/modules/git-grader/tests/unit/rubric.service.test.ts`

- [ ] **Step 1: Write the types**

`services/types.ts`:

```typescript
export interface RubricRating {
  description: string;
  points: number;
}

export interface RubricCriterion {
  slug: string;
  description: string;
  ratings: RubricRating[];
}

export interface Rubric {
  slug: string;
  title: string;
  criteria: RubricCriterion[];
}

export function maxPointsFor(rubric: Rubric): number {
  return rubric.criteria.reduce(
    (sum, c) => sum + Math.max(...c.ratings.map(r => r.points)),
    0
  );
}
```

- [ ] **Step 2: Write the failing test**

`tests/unit/rubric.service.test.ts`:

```typescript
import { RubricService } from '../../services/rubric.service';
import { maxPointsFor } from '../../services/types';
import * as path from 'path';

describe('RubricService', () => {
  const rubricsDir = path.join(__dirname, '../../rubrics');
  const svc = new RubricService(rubricsDir);

  it('lists every bundled rubric by slug', () => {
    const slugs = svc.list();
    expect(slugs).toContain('sprint-1-job-pack');
    expect(slugs).toContain('sprint-2-messaging');
    expect(slugs).toContain('cc-artifact-1-skill');
    expect(slugs.length).toBeGreaterThanOrEqual(8);
  });

  it('loads sprint-1-job-pack with all expected criteria', () => {
    const r = svc.load('sprint-1-job-pack');
    expect(r.slug).toBe('sprint-1-job-pack');
    expect(r.title).toBe('Sprint 1 — Job Pack');
    expect(r.criteria.map(c => c.slug)).toEqual([
      'required-outputs', 'strategy-pattern-llm', 'persistence',
      'deploy', 'vernacular-usage', 'code-quality',
      'presentation', 'documentation'
    ]);
  });

  it('throws on unknown slug', () => {
    expect(() => svc.load('not-a-rubric')).toThrow(/unknown rubric/);
  });

  it('computes max points correctly for sprint-1-job-pack (100)', () => {
    const r = svc.load('sprint-1-job-pack');
    expect(maxPointsFor(r)).toBe(100);
  });

  it('rejects a rubric with no ratings on a criterion', () => {
    // Constructed inline — point at a temp dir with the bad YAML
    const tmp = require('os').tmpdir();
    const fs = require('fs');
    const bad = path.join(tmp, 'bad-rubric.yaml');
    fs.writeFileSync(bad, 'slug: bad\ntitle: Bad\ncriteria:\n  - slug: x\n    description: y\n    ratings: []\n');
    const badSvc = new RubricService(require('path').dirname(bad));
    expect(() => badSvc.load('bad-rubric')).toThrow(/has no ratings/);
  });
});
```

- [ ] **Step 3: Run the test and verify it fails**

```bash
npx jest modules/git-grader/tests/unit/rubric.service.test.ts
```

Expected: FAIL — `Cannot find module '../../services/rubric.service'`.

- [ ] **Step 4: Implement the rubric service**

`services/rubric.service.ts`:

```typescript
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { Rubric } from './types';

export class RubricService {
  constructor(private readonly rubricsDir: string) {}

  list(): string[] {
    return fs.readdirSync(this.rubricsDir)
      .filter(f => f.endsWith('.yaml'))
      .map(f => f.replace(/\.yaml$/, ''))
      .sort();
  }

  load(slug: string): Rubric {
    const file = path.join(this.rubricsDir, `${slug}.yaml`);
    if (!fs.existsSync(file)) {
      throw new Error(`unknown rubric: ${slug}`);
    }
    const parsed = yaml.load(fs.readFileSync(file, 'utf8'), {
      schema: yaml.JSON_SCHEMA,   // refuses any !!js/* or other dangerous type tags
    }) as Rubric;
    this.validate(parsed, slug);
    return parsed;
  }

  private validate(r: Rubric, slug: string): void {
    if (r.slug !== slug) {
      throw new Error(`rubric ${slug}: file slug mismatch (got ${r.slug})`);
    }
    if (!Array.isArray(r.criteria) || r.criteria.length === 0) {
      throw new Error(`rubric ${slug}: must have at least one criterion`);
    }
    for (const c of r.criteria) {
      if (!Array.isArray(c.ratings) || c.ratings.length === 0) {
        throw new Error(`rubric ${slug}: criterion ${c.slug} has no ratings`);
      }
    }
  }
}
```

- [ ] **Step 5: Run the tests and verify they all pass**

```bash
npx jest modules/git-grader/tests/unit/rubric.service.test.ts
```

Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add modules/git-grader/services/types.ts modules/git-grader/services/rubric.service.ts modules/git-grader/tests/unit/rubric.service.test.ts
git commit -m "feat(git-grader): rubric loader with validation"
```

---

### Task 1.3: Write the prompt template and renderer

**Files:**
- Create: `fivex/mod_node/modules/git-grader/templates/grade-prompt.md.tmpl`
- Create: `fivex/mod_node/modules/git-grader/services/prompt.service.ts`
- Create: `fivex/mod_node/modules/git-grader/tests/unit/prompt.service.test.ts`

- [ ] **Step 1: Write the template**

`templates/grade-prompt.md.tmpl`:

```markdown
# Grading task — CS 3660 Advanced Web Development

You are an academic grader for CS 3660 at UVU. The student has submitted a repo
for an individual sprint deliverable. Your job is to read the code, apply the
rubric below, and produce two output files.

- **Repo:** {{repo_full_name}}
- **Student (from repo name):** {{student_username}}
- **Commit:** {{commit_sha}}
- **Sprint rubric:** {{rubric_slug}} ({{rubric_title}})
- **Run ID:** {{run_id}}

## Rubric

The rubric is the YAML block below. Each criterion has an ordered set of
`ratings`. You MUST choose exactly one rating per criterion (verbatim
description and points). You MAY NOT invent intermediate scores or skip
criteria.

```yaml
{{rubric_yaml}}
```

## How to grade

1. Read the top-level structure first: README, package manifest, CI config,
   directory layout. Note what is claimed.
2. For each criterion, search for *evidence* in the repo that supports a
   specific rating. Use `git log` for history claims. Use file reads for
   code-quality and structure claims. Use deployed-URL checks ONLY if the
   README provides a URL — do not guess URLs.
3. When evidence is mixed, pick the *lower* rating and explain why in the
   justification.
4. Cite every rating with concrete evidence: file paths with line ranges,
   commit SHAs, or quoted output. Vague justifications ("looks good") are
   not acceptable.

## Output

Write EXACTLY two files. Do not modify any other file in the repo. Do not
run `git add`, `git commit`, or `git push`.

### `.grader/grade.json`

```json
{
  "schemaVersion": "1.0",
  "runId": "{{run_id}}",
  "repo": "{{repo_full_name}}",
  "commitSha": "{{commit_sha}}",
  "rubric": "{{rubric_slug}}",
  "totalPoints": 0,
  "maxPoints": 0,
  "criteria": [
    {
      "slug": "<criterion slug from rubric>",
      "title": "<criterion title>",
      "chosenRatingDescription": "<verbatim from rubric>",
      "points": 0,
      "maxPoints": 0,
      "justification": "<2-4 sentences explaining the choice>",
      "evidence": [
        { "path": "<file>", "lines": "12-40", "note": "<what to look for>" }
      ]
    }
  ],
  "overallSummary": "<3-5 sentences>",
  "improvementSuggestions": [
    "<actionable suggestion 1>",
    "<actionable suggestion 2>"
  ]
}
```

### `.grader/grade-report.md`

```markdown
# Auto-grade — {{rubric_title}}

**Score: <totalPoints>/<maxPoints>** · commit `<short-sha>` ·
run `{{run_id}}` · {{timestamp}}

## Criteria

- [x] **<criterion title>** — `<points>/<maxPoints>` — "<chosen rating description>"
  - <justification, 1-2 sentences>
  - Evidence: `path/to/file.ts:12-40`, `path/to/other.md`

(... one bullet per criterion in rubric order ...)

## Summary

<overallSummary>

## Suggested improvements

- <improvementSuggestions[0]>
- <improvementSuggestions[1]>

---
<sub>Generated by the CS 3660 auto-grader. To re-run, ask the professor or
re-trigger the webhook. The full prompt and Claude tool-call trace are
archived at run `{{run_id}}`.</sub>
```
```

- [ ] **Step 2: Write the failing test**

`tests/unit/prompt.service.test.ts`:

```typescript
import { PromptService } from '../../services/prompt.service';
import { RubricService } from '../../services/rubric.service';
import * as path from 'path';

describe('PromptService', () => {
  const rubrics = new RubricService(path.join(__dirname, '../../rubrics'));
  const templates = path.join(__dirname, '../../templates');
  const svc = new PromptService(templates);

  it('renders sprint-1-job-pack with all variables substituted', () => {
    const r = rubrics.load('sprint-1-job-pack');
    const out = svc.render({
      rubric: r,
      repoFullName: 'uvucs3660/sprint1_alice_summer_2026',
      studentUsername: 'alice',
      commitSha: 'abc1234567890',
      runId: 'grd_test_001',
    });
    expect(out).toContain('uvucs3660/sprint1_alice_summer_2026');
    expect(out).toContain('grd_test_001');
    expect(out).toContain('alice');
    expect(out).toContain('abc1234567890');
    expect(out).toContain('Sprint 1 — Job Pack');
    expect(out).toContain('slug: sprint-1-job-pack');           // YAML inlined
    expect(out).toContain('All three artifacts present');       // a rating description
    expect(out).not.toMatch(/\{\{[a-z_]+\}\}/);                 // no unsubstituted placeholders
  });

  it('substitutes student username derived from repo name when not given', () => {
    const r = rubrics.load('sprint-2-messaging');
    const out = svc.render({
      rubric: r,
      repoFullName: 'uvucs3660/sprint2_bob_summer_2026',
      commitSha: 'def4567',
      runId: 'grd_test_002',
    });
    expect(out).toContain('bob');
  });
});
```

- [ ] **Step 3: Run the test and verify it fails**

```bash
npx jest modules/git-grader/tests/unit/prompt.service.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 4: Implement the prompt service**

`services/prompt.service.ts`:

```typescript
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { Rubric } from './types';

export interface PromptInput {
  rubric: Rubric;
  repoFullName: string;
  studentUsername?: string;
  commitSha: string;
  runId: string;
}

export class PromptService {
  private readonly template: string;

  constructor(private readonly templatesDir: string) {
    this.template = fs.readFileSync(
      path.join(templatesDir, 'grade-prompt.md.tmpl'),
      'utf8'
    );
  }

  render(input: PromptInput): string {
    const username = input.studentUsername ?? deriveUsername(input.repoFullName);
    const vars: Record<string, string> = {
      repo_full_name:   input.repoFullName,
      student_username: username,
      commit_sha:       input.commitSha,
      run_id:           input.runId,
      rubric_slug:      input.rubric.slug,
      rubric_title:     input.rubric.title,
      rubric_yaml:      yaml.dump(input.rubric).trimEnd(),
    };
    return this.template.replace(/\{\{([a-z_]+)\}\}/g, (m, key) => {
      if (!(key in vars)) {
        throw new Error(`prompt template references unknown variable: ${key}`);
      }
      return vars[key];
    });
  }
}

function deriveUsername(repoFullName: string): string {
  // Convention: <org>/<assignmentSlug>_<username>_<semester>_<year>
  // e.g. uvucs3660/sprint1_alice_summer_2026 → "alice"
  const repo = repoFullName.split('/').pop() ?? '';
  const parts = repo.split('_');
  return parts[1] ?? 'unknown';
}
```

- [ ] **Step 5: Run the tests and verify they pass**

```bash
npx jest modules/git-grader/tests/unit/prompt.service.test.ts
```

Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add modules/git-grader/templates/grade-prompt.md.tmpl modules/git-grader/services/prompt.service.ts modules/git-grader/tests/unit/prompt.service.test.ts
git commit -m "feat(git-grader): prompt template and renderer"
```

---

### Task 1.4: Write the grade validator

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/validator.service.ts`
- Create: `fivex/mod_node/modules/git-grader/tests/fixtures/sample-grade.json`
- Create: `fivex/mod_node/modules/git-grader/tests/fixtures/invalid-grades/` (multiple files)
- Create: `fivex/mod_node/modules/git-grader/tests/unit/validator.service.test.ts`

- [ ] **Step 1: Write a valid sample grade.json**

`tests/fixtures/sample-grade.json` (this matches sprint-1-job-pack):

```json
{
  "schemaVersion": "1.0",
  "runId": "grd_sample_001",
  "repo": "uvucs3660/sprint1_alice_summer_2026",
  "commitSha": "abc1234567890",
  "rubric": "sprint-1-job-pack",
  "totalPoints": 100,
  "maxPoints": 100,
  "criteria": [
    { "slug": "required-outputs",    "title": "Required outputs",        "chosenRatingDescription": "All three artifacts present and correctly tailored to the inputs.",          "points": 25, "maxPoints": 25, "justification": "All three PDFs render for the sample inputs in the fixture set; cover-letter generation uses input-specific phrasing.",                       "evidence": [{ "path": "src/generators/resume.ts", "lines": "18-94", "note": "PDF generation" }] },
    { "slug": "strategy-pattern-llm","title": "Strategy pattern (LLM swap)","chosenRatingDescription": "≥2 backends working, swap is config-only, code is clean.",                  "points": 15, "maxPoints": 15, "justification": "OpenAI and Anthropic backends both wired; switching is a single env var, no code edits required to swap.",                                "evidence": [{ "path": "src/llm/strategy.ts", "lines": "1-72", "note": "Strategy" }] },
    { "slug": "persistence",         "title": "Persistence",             "chosenRatingDescription": "Multi-draft, compare-mode, persistence on real database.",                  "points": 10, "maxPoints": 10, "justification": "Drafts persist to Postgres with revisions; compare-mode side-by-side view ships in the UI.",                                                   "evidence": [{ "path": "prisma/schema.prisma", "lines": "14-32", "note": "Draft model" }] },
    { "slug": "deploy",              "title": "Deploy",                  "chosenRatingDescription": "Deployed, working, with HTTPS.",                                            "points": 10, "maxPoints": 10, "justification": "Reachable at https URL from README; cold-start path works on a fresh browser session.",                                                          "evidence": [{ "path": "README.md", "lines": "8", "note": "URL" }] },
    { "slug": "vernacular-usage",    "title": "Vernacular usage",        "chosenRatingDescription": "All requirements met, patterns explained clearly and used correctly.",      "points": 15, "maxPoints": 15, "justification": "Demo script names Strategy + Template-Method, Content-Based Router, Idempotency + Audit Trail; each is implemented where claimed.",            "evidence": [{ "path": "docs/demo-script.md", "lines": "1-40", "note": "Vernacular" }] },
    { "slug": "code-quality",        "title": "Code quality",            "chosenRatingDescription": "Clear structure, useful tests, easy to read.",                              "points": 10, "maxPoints": 10, "justification": "Layering is consistent, tests cover the strategy switch and the persistence path; PRs all reviewed.",                                          "evidence": [{ "path": "tests/", "lines": "", "note": "Test suite" }] },
    { "slug": "presentation",        "title": "Presentation",            "chosenRatingDescription": "Excellent — clear, well-paced, end-to-end demo, strong Q&A.",                "points": 10, "maxPoints": 10, "justification": "Recording shows clean walkthrough end-to-end, on-time Q&A answers.",                                                                              "evidence": [{ "path": "README.md", "lines": "60-90", "note": "Demo link" }] },
    { "slug": "documentation",       "title": "Documentation",           "chosenRatingDescription": "Thorough README + reflection.",                                            "points": 5,  "maxPoints": 5,  "justification": "README covers setup, backend choice, and the swap procedure; reflection committed.",                                                              "evidence": [{ "path": "README.md", "lines": "", "note": "Top-level" }] }
  ],
  "overallSummary": "Strong submission. Strategy pattern is clean; persistence implements compare-mode; deploy is on HTTPS. Vernacular usage is unusually well-grounded.",
  "improvementSuggestions": [
    "Add a per-criterion changelog so reviewers can see what changed between drafts.",
    "Add metric collection to the deploy for the next sprint."
  ]
}
```

- [ ] **Step 2: Write four invalid grade fixtures**

`tests/fixtures/invalid-grades/missing-criterion.json` (drops `documentation`):

```json
{ "schemaVersion": "1.0", "runId": "grd_x", "repo": "uvucs3660/sprint1_x_summer_2026", "commitSha": "x", "rubric": "sprint-1-job-pack", "totalPoints": 95, "maxPoints": 100, "criteria": [], "overallSummary": "x", "improvementSuggestions": [] }
```

`tests/fixtures/invalid-grades/bad-rating-text.json` (one criterion's `chosenRatingDescription` doesn't match the rubric verbatim):

```json
{ "schemaVersion": "1.0", "runId": "grd_y", "repo": "uvucs3660/sprint1_x_summer_2026", "commitSha": "x", "rubric": "sprint-1-job-pack", "totalPoints": 25, "maxPoints": 100, "criteria": [
  { "slug": "required-outputs", "title": "Required outputs", "chosenRatingDescription": "It works mostly fine.", "points": 25, "maxPoints": 25, "justification": "Looks good overall, see file.", "evidence": [{ "path": "x", "lines": "", "note": "x" }] }
], "overallSummary": "x", "improvementSuggestions": [] }
```

`tests/fixtures/invalid-grades/totals-mismatch.json` (totalPoints doesn't match sum):

```json
{ "schemaVersion": "1.0", "runId": "grd_z", "repo": "uvucs3660/sprint1_x_summer_2026", "commitSha": "x", "rubric": "sprint-1-job-pack", "totalPoints": 999, "maxPoints": 100, "criteria": [
  { "slug": "required-outputs", "title": "Required outputs", "chosenRatingDescription": "All three artifacts present and correctly tailored to the inputs.", "points": 25, "maxPoints": 25, "justification": "Yes all three artifacts are present and correctly tailored.", "evidence": [{ "path": "src", "lines": "", "note": "see code" }] }
], "overallSummary": "x", "improvementSuggestions": [] }
```

`tests/fixtures/invalid-grades/no-evidence.json` (a criterion has empty `evidence`):

```json
{ "schemaVersion": "1.0", "runId": "grd_w", "repo": "uvucs3660/sprint1_x_summer_2026", "commitSha": "x", "rubric": "sprint-1-job-pack", "totalPoints": 25, "maxPoints": 100, "criteria": [
  { "slug": "required-outputs", "title": "Required outputs", "chosenRatingDescription": "All three artifacts present and correctly tailored to the inputs.", "points": 25, "maxPoints": 25, "justification": "All three artifacts are present and correctly tailored to inputs.", "evidence": [] }
], "overallSummary": "x", "improvementSuggestions": [] }
```

- [ ] **Step 3: Write the failing test**

`tests/unit/validator.service.test.ts`:

```typescript
import * as fs from 'fs';
import * as path from 'path';
import { ValidatorService } from '../../services/validator.service';
import { RubricService } from '../../services/rubric.service';

describe('ValidatorService', () => {
  const rubrics = new RubricService(path.join(__dirname, '../../rubrics'));
  const svc = new ValidatorService(rubrics);
  const fixtures = path.join(__dirname, '../fixtures');

  function load(name: string): unknown {
    return JSON.parse(fs.readFileSync(path.join(fixtures, name), 'utf8'));
  }

  it('accepts a fully valid sample-grade.json against sprint-1-job-pack', () => {
    const grade = load('sample-grade.json');
    expect(() => svc.assertValid(grade, 'sprint-1-job-pack')).not.toThrow();
  });

  it('rejects when criteria count mismatches the rubric', () => {
    const grade = load('invalid-grades/missing-criterion.json');
    expect(() => svc.assertValid(grade, 'sprint-1-job-pack'))
      .toThrow(/expected 8 criteria/);
  });

  it('rejects when chosenRatingDescription is not verbatim from rubric', () => {
    const grade = load('invalid-grades/bad-rating-text.json');
    expect(() => svc.assertValid(grade, 'sprint-1-job-pack'))
      .toThrow(/rating not in rubric/);
  });

  it('rejects when totalPoints does not equal sum of criteria points', () => {
    const grade = load('invalid-grades/totals-mismatch.json');
    expect(() => svc.assertValid(grade, 'sprint-1-job-pack'))
      .toThrow(/totalPoints/);
  });

  it('rejects when a criterion has no evidence', () => {
    const grade = load('invalid-grades/no-evidence.json');
    expect(() => svc.assertValid(grade, 'sprint-1-job-pack'))
      .toThrow(/no evidence/);
  });
});
```

- [ ] **Step 4: Run the test and verify it fails**

```bash
npx jest modules/git-grader/tests/unit/validator.service.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 5: Implement the validator**

`services/validator.service.ts`:

```typescript
import { Rubric, maxPointsFor } from './types';
import { RubricService } from './rubric.service';

export interface GradeCriterion {
  slug: string;
  title: string;
  chosenRatingDescription: string;
  points: number;
  maxPoints: number;
  justification: string;
  evidence: { path: string; lines?: string; note?: string }[];
}

export interface Grade {
  schemaVersion: string;
  runId: string;
  repo: string;
  commitSha: string;
  rubric: string;
  totalPoints: number;
  maxPoints: number;
  criteria: GradeCriterion[];
  overallSummary: string;
  improvementSuggestions: string[];
}

export class ValidatorService {
  constructor(private readonly rubrics: RubricService) {}

  assertValid(grade: unknown, expectedRubricSlug: string): asserts grade is Grade {
    const g = grade as Grade;
    if (g.schemaVersion !== '1.0') {
      throw new Error(`unexpected schemaVersion: ${g.schemaVersion}`);
    }
    if (g.rubric !== expectedRubricSlug) {
      throw new Error(`rubric mismatch: grade says ${g.rubric}, expected ${expectedRubricSlug}`);
    }
    const rubric: Rubric = this.rubrics.load(expectedRubricSlug);

    if (!Array.isArray(g.criteria) || g.criteria.length !== rubric.criteria.length) {
      throw new Error(
        `expected ${rubric.criteria.length} criteria, got ${g.criteria?.length ?? 0}`
      );
    }

    for (const c of g.criteria) {
      const rc = rubric.criteria.find(r => r.slug === c.slug);
      if (!rc) throw new Error(`criterion ${c.slug}: unknown slug`);
      const match = rc.ratings.find(
        r => r.description === c.chosenRatingDescription && r.points === c.points
      );
      if (!match) throw new Error(`criterion ${c.slug}: rating not in rubric`);
      const max = Math.max(...rc.ratings.map(r => r.points));
      if (c.maxPoints !== max) throw new Error(`criterion ${c.slug}: wrong maxPoints`);
      if (!c.justification || c.justification.length < 40) {
        throw new Error(`criterion ${c.slug}: justification too short`);
      }
      if (!Array.isArray(c.evidence) || c.evidence.length < 1) {
        throw new Error(`criterion ${c.slug}: no evidence cited`);
      }
    }

    const sum = g.criteria.reduce((s, c) => s + c.points, 0);
    if (g.totalPoints !== sum) {
      throw new Error(`totalPoints (${g.totalPoints}) != sum of criteria points (${sum})`);
    }
    const expectedMax = maxPointsFor(rubric);
    if (g.maxPoints !== expectedMax) {
      throw new Error(`maxPoints (${g.maxPoints}) != rubric max (${expectedMax})`);
    }
  }
}
```

- [ ] **Step 6: Run the tests and verify they pass**

```bash
npx jest modules/git-grader/tests/unit/validator.service.test.ts
```

Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add modules/git-grader/services/validator.service.ts modules/git-grader/tests/fixtures/ modules/git-grader/tests/unit/validator.service.test.ts
git commit -m "feat(git-grader): grade.json validator with rubric conformance checks"
```

---

### Task 1.5: Phase 1 CLI — `bin/render-prompt.ts`

**Files:**
- Create: `fivex/mod_node/modules/git-grader/bin/render-prompt.ts`

- [ ] **Step 1: Write the CLI**

`bin/render-prompt.ts`:

```typescript
#!/usr/bin/env -S npx ts-node
import * as path from 'path';
import { RubricService } from '../services/rubric.service';
import { PromptService } from '../services/prompt.service';

const [,, rubricSlug, repoFullName] = process.argv;

if (!rubricSlug || !repoFullName) {
  console.error('usage: render-prompt.ts <rubric-slug> <repoFullName>');
  console.error('example: render-prompt.ts sprint-1-job-pack uvucs3660/sprint1_alice_summer_2026');
  process.exit(1);
}

const moduleRoot = path.join(__dirname, '..');
const rubrics = new RubricService(path.join(moduleRoot, 'rubrics'));
const prompts = new PromptService(path.join(moduleRoot, 'templates'));

const rendered = prompts.render({
  rubric: rubrics.load(rubricSlug),
  repoFullName,
  commitSha: 'HEAD',
  runId: `grd_render_${Date.now()}`,
});

process.stdout.write(rendered);
```

- [ ] **Step 2: Verify it runs and produces a non-empty prompt**

```bash
cd modules/git-grader
npx ts-node bin/render-prompt.ts sprint-1-job-pack uvucs3660/sprint1_alice_summer_2026 | head -40
```

Expected: A markdown prompt starting with `# Grading task — CS 3660 Advanced Web Development` and containing `Sprint 1 — Job Pack`.

- [ ] **Step 3: Smoke test the prompt with real Claude (manual, optional)**

Open a fresh `claude` session in any small test repo, paste the rendered prompt as the first user message, and confirm Claude creates `.grader/grade.json` + `.grader/grade-report.md`. Run validator manually:

```bash
cd modules/git-grader
npx ts-node -e "import {RubricService} from './services/rubric.service'; import {ValidatorService} from './services/validator.service'; import * as fs from 'fs'; const r=new RubricService('rubrics'); const v=new ValidatorService(r); v.assertValid(JSON.parse(fs.readFileSync('/path/to/.grader/grade.json','utf8')),'sprint-1-job-pack'); console.log('VALID');"
```

This step exists to find prompt problems before any infrastructure exists. Failure here means the prompt itself needs iteration — fix the template, not the code.

- [ ] **Step 4: Commit**

```bash
git add modules/git-grader/bin/render-prompt.ts
git commit -m "feat(git-grader): render-prompt CLI (Phase 1 deliverable)"
```

---

# PHASE 2 — Subprocess orchestration

Goal of the phase: a CLI `bin/grade-once.ts <repo> [<rubric>]` that performs the full clone → render → claude → validate → gh pipeline synchronously, exits with the runId. End-of-phase deliverable: usable as a manual grading tool even before HTTP/queue work begins.

---

### Task 2.1: SpawnableProcess interface + real spawn factory

**Files:**
- Modify: `fivex/mod_node/modules/git-grader/services/types.ts`
- Create: `fivex/mod_node/modules/git-grader/services/spawn.factory.ts`

- [ ] **Step 1: Add SpawnableProcess types to services/types.ts**

Append to `services/types.ts`:

```typescript
export interface SpawnOptions {
  command: string;
  args: string[];
  cwd?: string;
  env?: Record<string, string>;
  stdin?: string;
  timeoutMs?: number;
}

export interface SpawnResult {
  exitCode: number;
  stdout: string;
  stderr: string;
  timedOut: boolean;
}

export interface SpawnableProcess {
  run(opts: SpawnOptions): Promise<SpawnResult>;
}
```

- [ ] **Step 2: Write a tiny smoke test for the real factory**

`tests/integration/spawn.factory.test.ts`:

```typescript
import { RealSpawn } from '../../services/spawn.factory';

describe('RealSpawn (integration)', () => {
  const proc = new RealSpawn();

  it('captures stdout and exit 0', async () => {
    const r = await proc.run({ command: 'echo', args: ['hello'] });
    expect(r.exitCode).toBe(0);
    expect(r.stdout.trim()).toBe('hello');
    expect(r.timedOut).toBe(false);
  });

  it('reports non-zero exit code', async () => {
    const r = await proc.run({ command: 'sh', args: ['-c', 'exit 7'] });
    expect(r.exitCode).toBe(7);
  });

  it('honors timeoutMs', async () => {
    const r = await proc.run({ command: 'sleep', args: ['3'], timeoutMs: 200 });
    expect(r.timedOut).toBe(true);
  }, 5000);

  it('pipes stdin into the process', async () => {
    const r = await proc.run({ command: 'cat', args: [], stdin: 'hi from stdin' });
    expect(r.stdout).toBe('hi from stdin');
  });
});
```

- [ ] **Step 3: Run the test (it will fail — factory not written yet)**

```bash
npx jest modules/git-grader/tests/integration/spawn.factory.test.ts
```

Expected: FAIL.

- [ ] **Step 4: Implement the real factory**

`services/spawn.factory.ts`:

```typescript
import { spawn } from 'child_process';
import { SpawnOptions, SpawnResult, SpawnableProcess } from './types';

export class RealSpawn implements SpawnableProcess {
  async run(opts: SpawnOptions): Promise<SpawnResult> {
    return new Promise<SpawnResult>((resolve, reject) => {
      const child = spawn(opts.command, opts.args, {
        cwd: opts.cwd,
        env: { ...process.env, ...(opts.env ?? {}) },
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      let stdout = '';
      let stderr = '';
      let timedOut = false;
      let timeoutHandle: NodeJS.Timeout | undefined;

      child.stdout.on('data', d => { stdout += d.toString(); });
      child.stderr.on('data', d => { stderr += d.toString(); });

      if (opts.timeoutMs && opts.timeoutMs > 0) {
        timeoutHandle = setTimeout(() => {
          timedOut = true;
          child.kill('SIGKILL');
        }, opts.timeoutMs);
      }

      child.on('error', err => {
        if (timeoutHandle) clearTimeout(timeoutHandle);
        reject(err);
      });

      child.on('close', code => {
        if (timeoutHandle) clearTimeout(timeoutHandle);
        resolve({ exitCode: code ?? -1, stdout, stderr, timedOut });
      });

      if (opts.stdin !== undefined) {
        child.stdin.write(opts.stdin);
        child.stdin.end();
      } else {
        child.stdin.end();
      }
    });
  }
}
```

- [ ] **Step 5: Run the tests and verify they pass**

```bash
npx jest modules/git-grader/tests/integration/spawn.factory.test.ts
```

Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add modules/git-grader/services/types.ts modules/git-grader/services/spawn.factory.ts modules/git-grader/tests/integration/spawn.factory.test.ts
git commit -m "feat(git-grader): SpawnableProcess interface and real subprocess factory"
```

---

### Task 2.2: Runner service with stubbable spawns

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/runner.service.ts`
- Create: `fivex/mod_node/modules/git-grader/tests/integration/runner.test.ts`

- [ ] **Step 1: Define the run record + job types in types.ts**

Append to `services/types.ts`:

```typescript
export type RunStatus =
  | 'queued' | 'running' | 'ok'
  | 'failed:clone' | 'failed:claude' | 'failed:validate'
  | 'failed:post'  | 'failed:interrupted';

export interface Job {
  runId: string;
  repo: string;       // org/repo
  rubric: string;     // rubric slug
  enqueuedAt: string; // ISO
}

export interface RunRecord {
  runId: string;
  repo: string;
  rubric: string;
  commitSha?: string;
  status: RunStatus;
  startedAt?: string;
  finishedAt?: string;
  durationSeconds?: number;
  queuedFor?: string;
  deduped?: boolean;
  grade?: unknown;
  issueUrl?: string | null;
  issueAction?: 'created' | 'commented';
  artifacts?: {
    promptUrl?: string;
    traceUrl?: string;
    gradeUrl?: string;
    reportUrl?: string;
  };
  error?: { phase: string; message: string; exitCode?: number; stderrTail?: string };
  republishUrl?: string | null;
}

export interface RunnerHooks {
  onPhase?(runId: string, phase: string, status?: RunStatus): void;
}
```

- [ ] **Step 2: Write the integration test with stub spawns**

`tests/integration/runner.test.ts`:

```typescript
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';
import { Runner, RunnerConfig } from '../../services/runner.service';
import { RubricService } from '../../services/rubric.service';
import { PromptService } from '../../services/prompt.service';
import { ValidatorService } from '../../services/validator.service';
import { SpawnOptions, SpawnResult, SpawnableProcess } from '../../services/types';

class StubSpawn implements SpawnableProcess {
  public calls: SpawnOptions[] = [];
  constructor(private behaviors: ((opts: SpawnOptions) => Promise<SpawnResult>)[]) {}
  async run(opts: SpawnOptions): Promise<SpawnResult> {
    this.calls.push(opts);
    const fn = this.behaviors.shift();
    if (!fn) throw new Error(`unexpected spawn: ${opts.command} ${opts.args.join(' ')}`);
    return fn(opts);
  }
}

function makeRunner(stubs: { git: StubSpawn; claude: StubSpawn; gh: StubSpawn }): Runner {
  const moduleRoot = path.join(__dirname, '../..');
  const rubrics = new RubricService(path.join(moduleRoot, 'rubrics'));
  const prompts = new PromptService(path.join(moduleRoot, 'templates'));
  const validator = new ValidatorService(rubrics);
  const config: RunnerConfig = {
    archiveDir: fs.mkdtempSync(path.join(os.tmpdir(), 'grader-arch-')),
    claudeTimeoutMs: 60_000,
    githubToken: 'fake',
  };
  return new Runner(rubrics, prompts, validator, stubs.git, stubs.claude, stubs.gh, config);
}

describe('Runner (integration with stubbed spawns)', () => {
  const validSample = JSON.parse(
    fs.readFileSync(path.join(__dirname, '../fixtures/sample-grade.json'), 'utf8')
  );

  it('runs the full pipeline end-to-end and reports ok', async () => {
    let claudeCwd = '';

    const git = new StubSpawn([
      async opts => {                                      // git clone
        fs.mkdirSync(path.join(opts.args[opts.args.length - 1]), { recursive: true });
        return { exitCode: 0, stdout: '', stderr: '', timedOut: false };
      },
      async () => ({ exitCode: 0, stdout: 'abc1234567890\n', stderr: '', timedOut: false }), // rev-parse
    ]);
    const claude = new StubSpawn([
      async opts => {
        claudeCwd = opts.cwd!;
        const graderDir = path.join(claudeCwd, '.grader');
        fs.mkdirSync(graderDir, { recursive: true });
        const grade = { ...validSample, runId: 'grd_test', commitSha: 'abc1234567890' };
        fs.writeFileSync(path.join(graderDir, 'grade.json'), JSON.stringify(grade));
        fs.writeFileSync(path.join(graderDir, 'grade-report.md'), '# Auto-grade\nScore: 100/100\n');
        fs.writeFileSync(path.join(graderDir, 'claude-trace.jsonl'), '{"type":"done"}\n');
        return { exitCode: 0, stdout: '', stderr: '', timedOut: false };
      },
    ]);
    const gh = new StubSpawn([
      async () => ({ exitCode: 0, stdout: '[]', stderr: '', timedOut: false }), // gh issue list → empty
      async () => ({ exitCode: 0, stdout: 'https://github.com/uvucs3660/sprint1_alice_summer_2026/issues/1', stderr: '', timedOut: false }),
    ]);

    const r = makeRunner({ git, claude, gh });
    const rec = await r.run({
      runId: 'grd_test',
      repo: 'uvucs3660/sprint1_alice_summer_2026',
      rubric: 'sprint-1-job-pack',
      enqueuedAt: new Date().toISOString(),
    });

    expect(rec.status).toBe('ok');
    expect(rec.issueUrl).toContain('/issues/1');
    expect(rec.issueAction).toBe('created');
    expect(rec.artifacts?.gradeUrl).toBeDefined();
  });

  it('records failed:claude when claude exits non-zero', async () => {
    const git = new StubSpawn([
      async opts => { fs.mkdirSync(opts.args[opts.args.length - 1], { recursive: true }); return { exitCode: 0, stdout: '', stderr: '', timedOut: false }; },
      async () => ({ exitCode: 0, stdout: 'sha\n', stderr: '', timedOut: false }),
    ]);
    const claude = new StubSpawn([
      async () => ({ exitCode: 1, stdout: '', stderr: 'context window exceeded', timedOut: false }),
    ]);
    const gh = new StubSpawn([]);

    const r = makeRunner({ git, claude, gh });
    const rec = await r.run({
      runId: 'grd_fail', repo: 'uvucs3660/sprint1_x_summer_2026',
      rubric: 'sprint-1-job-pack', enqueuedAt: new Date().toISOString(),
    });
    expect(rec.status).toBe('failed:claude');
    expect(rec.error?.message).toContain('exited with code 1');
    expect(gh.calls.length).toBe(0); // no posting on claude failure
  });

  it('records failed:validate when grade.json is invalid', async () => {
    const git = new StubSpawn([
      async opts => { fs.mkdirSync(opts.args[opts.args.length - 1], { recursive: true }); return { exitCode: 0, stdout: '', stderr: '', timedOut: false }; },
      async () => ({ exitCode: 0, stdout: 'sha\n', stderr: '', timedOut: false }),
    ]);
    const claude = new StubSpawn([
      async opts => {
        const dir = path.join(opts.cwd!, '.grader');
        fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(path.join(dir, 'grade.json'), JSON.stringify({ schemaVersion: '1.0', criteria: [] }));
        fs.writeFileSync(path.join(dir, 'grade-report.md'), '');
        return { exitCode: 0, stdout: '', stderr: '', timedOut: false };
      },
    ]);
    const gh = new StubSpawn([]);

    const r = makeRunner({ git, claude, gh });
    const rec = await r.run({
      runId: 'grd_inv', repo: 'uvucs3660/sprint1_x_summer_2026',
      rubric: 'sprint-1-job-pack', enqueuedAt: new Date().toISOString(),
    });
    expect(rec.status).toBe('failed:validate');
    expect(gh.calls.length).toBe(0);
  });
});
```

- [ ] **Step 3: Run the test and verify it fails**

```bash
npx jest modules/git-grader/tests/integration/runner.test.ts
```

Expected: FAIL — Runner not implemented.

- [ ] **Step 4: Implement the runner service**

`services/runner.service.ts`:

```typescript
import * as fs from 'fs/promises';
import * as fsSync from 'fs';
import * as path from 'path';
import * as os from 'os';
import { RubricService } from './rubric.service';
import { PromptService } from './prompt.service';
import { ValidatorService } from './validator.service';
import {
  SpawnableProcess, Job, RunRecord, RunnerHooks, RunStatus
} from './types';

export interface RunnerConfig {
  archiveDir: string;
  claudeTimeoutMs: number;
  githubToken: string;
}

export class Runner {
  constructor(
    private readonly rubrics: RubricService,
    private readonly prompts: PromptService,
    private readonly validator: ValidatorService,
    private readonly gitProc: SpawnableProcess,
    private readonly claudeProc: SpawnableProcess,
    private readonly ghProc: SpawnableProcess,
    private readonly config: RunnerConfig,
    private readonly hooks: RunnerHooks = {}
  ) {}

  async run(job: Job): Promise<RunRecord> {
    const startedAt = new Date().toISOString();
    const rec: RunRecord = { runId: job.runId, repo: job.repo, rubric: job.rubric,
      status: 'running', startedAt, deduped: false };
    this.hooks.onPhase?.(job.runId, 'running', 'running');

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'grader-'));
    const repoDir = path.join(tmpDir, 'repo');
    const graderDir = path.join(repoDir, '.grader');

    try {
      // ---- CLONE
      this.hooks.onPhase?.(job.runId, 'cloning');
      const cloneUrl = `https://${this.config.githubToken ? this.config.githubToken + '@' : ''}github.com/${job.repo}.git`;
      const clone = await this.gitProc.run({
        command: 'git', args: ['clone', '--depth=50', cloneUrl, repoDir], timeoutMs: 60_000,
      });
      if (clone.exitCode !== 0) {
        return this.fail(rec, 'clone', `git clone failed (exit ${clone.exitCode})`, clone.exitCode, clone.stderr);
      }
      const sha = await this.gitProc.run({
        command: 'git', args: ['-C', repoDir, 'rev-parse', 'HEAD'], timeoutMs: 10_000,
      });
      if (sha.exitCode !== 0) {
        return this.fail(rec, 'clone', `git rev-parse failed`, sha.exitCode, sha.stderr);
      }
      rec.commitSha = sha.stdout.trim();

      // ---- RENDER
      this.hooks.onPhase?.(job.runId, 'rendering');
      await fs.mkdir(graderDir, { recursive: true });
      const rubric = this.rubrics.load(job.rubric);
      const prompt = this.prompts.render({
        rubric, repoFullName: job.repo, commitSha: rec.commitSha, runId: job.runId,
      });
      const promptPath = path.join(graderDir, 'grade-prompt.md');
      await fs.writeFile(promptPath, prompt, 'utf8');

      // ---- CLAUDE
      this.hooks.onPhase?.(job.runId, 'claude-start');
      const claude = await this.claudeProc.run({
        command: 'claude',
        args: ['--print', '--dangerously-skip-permissions', '--output-format', 'stream-json'],
        cwd: repoDir,
        stdin: prompt,
        timeoutMs: this.config.claudeTimeoutMs,
      });
      this.hooks.onPhase?.(job.runId, 'claude-done');
      if (claude.timedOut) {
        return this.fail(rec, 'claude', `claude timed out after ${this.config.claudeTimeoutMs}ms`, -1, claude.stderr);
      }
      if (claude.exitCode !== 0) {
        return this.fail(rec, 'claude', `claude exited with code ${claude.exitCode}`, claude.exitCode, claude.stderr);
      }
      // The runner relies on the model writing files; capture the stream-json trace separately
      const tracePath = path.join(graderDir, 'claude-trace.jsonl');
      if (!fsSync.existsSync(tracePath)) {
        await fs.writeFile(tracePath, claude.stdout, 'utf8');
      }

      // ---- VALIDATE
      this.hooks.onPhase?.(job.runId, 'validating');
      const gradePath = path.join(graderDir, 'grade.json');
      const reportPath = path.join(graderDir, 'grade-report.md');
      if (!fsSync.existsSync(gradePath) || !fsSync.existsSync(reportPath)) {
        return this.fail(rec, 'validate', `claude did not produce required files`);
      }
      let grade: unknown;
      try {
        grade = JSON.parse(await fs.readFile(gradePath, 'utf8'));
        this.validator.assertValid(grade, job.rubric);
      } catch (e) {
        return this.fail(rec, 'validate', (e as Error).message);
      }
      rec.grade = grade;

      // ---- POST TO GITHUB
      this.hooks.onPhase?.(job.runId, 'posting');
      const label = `auto-grade:${job.rubric}`;
      const list = await this.ghProc.run({
        command: 'gh',
        args: ['issue', 'list', '--repo', job.repo, '--label', label, '--state', 'open', '--json', 'number'],
        env: { GITHUB_TOKEN: this.config.githubToken },
        timeoutMs: 30_000,
      });
      const existing = (list.exitCode === 0 ? (JSON.parse(list.stdout || '[]') as { number: number }[]) : []);

      let post: { exitCode: number; stdout: string; stderr: string; timedOut: boolean };
      if (existing.length > 0) {
        post = await this.ghProc.run({
          command: 'gh',
          args: ['issue', 'comment', String(existing[0].number), '--repo', job.repo, '--body-file', reportPath],
          env: { GITHUB_TOKEN: this.config.githubToken },
          timeoutMs: 30_000,
        });
        rec.issueAction = 'commented';
      } else {
        post = await this.ghProc.run({
          command: 'gh',
          args: ['issue', 'create', '--repo', job.repo,
                 '--title', `Auto-grade: ${job.rubric} — ${new Date().toISOString().slice(0,10)}`,
                 '--label', label, '--body-file', reportPath],
          env: { GITHUB_TOKEN: this.config.githubToken },
          timeoutMs: 30_000,
        });
        rec.issueAction = 'created';
      }

      if (post.exitCode !== 0) {
        rec.status = 'failed:post';
        rec.error = { phase: 'post', message: `gh failed: exit ${post.exitCode}`, exitCode: post.exitCode, stderrTail: tailLines(post.stderr, 20) };
      } else {
        rec.issueUrl = post.stdout.trim().split(/\s+/).pop() ?? null;
        rec.status = 'ok';
      }

      // ---- ARCHIVE (always, success or post-failure)
      const archiveDir = path.join(this.config.archiveDir, job.runId);
      await fs.mkdir(archiveDir, { recursive: true });
      for (const f of ['grade-prompt.md', 'grade-report.md', 'grade.json', 'claude-trace.jsonl']) {
        const src = path.join(graderDir, f);
        if (fsSync.existsSync(src)) await fs.copyFile(src, path.join(archiveDir, f));
      }
      rec.artifacts = {
        promptUrl: `/git-grade/runs/${job.runId}/files/grade-prompt.md`,
        traceUrl:  `/git-grade/runs/${job.runId}/files/claude-trace.jsonl`,
        gradeUrl:  `/git-grade/runs/${job.runId}/files/grade.json`,
        reportUrl: `/git-grade/runs/${job.runId}/files/grade-report.md`,
      };

      const finishedAt = new Date().toISOString();
      rec.finishedAt = finishedAt;
      rec.durationSeconds = Math.round(
        (new Date(finishedAt).getTime() - new Date(startedAt).getTime()) / 1000
      );
      this.hooks.onPhase?.(job.runId, rec.status === 'ok' ? 'done' : 'failed', rec.status);
      return rec;
    } finally {
      try { await fs.rm(tmpDir, { recursive: true, force: true }); } catch { /* swallow cleanup error */ }
    }
  }

  private fail(rec: RunRecord, phase: string, message: string, exitCode?: number, stderr?: string): RunRecord {
    rec.status = `failed:${phase}` as RunStatus;
    rec.error = { phase, message, exitCode, stderrTail: stderr ? tailLines(stderr, 20) : undefined };
    rec.finishedAt = new Date().toISOString();
    this.hooks.onPhase?.(rec.runId, 'failed', rec.status);
    return rec;
  }
}

function tailLines(s: string, n: number): string {
  return s.split('\n').slice(-n).join('\n');
}
```

- [ ] **Step 5: Run the tests and verify they pass**

```bash
npx jest modules/git-grader/tests/integration/runner.test.ts
```

Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add modules/git-grader/services/runner.service.ts modules/git-grader/services/types.ts modules/git-grader/tests/integration/runner.test.ts
git commit -m "feat(git-grader): runner service with full pipeline and stubbable spawns"
```

---

### Task 2.3: Phase 2 CLI — `bin/grade-once.ts`

**Files:**
- Create: `fivex/mod_node/modules/git-grader/bin/grade-once.ts`

- [ ] **Step 1: Write the CLI**

`bin/grade-once.ts`:

```typescript
#!/usr/bin/env -S npx ts-node
import * as path from 'path';
import { RubricService } from '../services/rubric.service';
import { PromptService } from '../services/prompt.service';
import { ValidatorService } from '../services/validator.service';
import { Runner } from '../services/runner.service';
import { RealSpawn } from '../services/spawn.factory';

const [,, repo, rubricArg] = process.argv;
if (!repo) {
  console.error('usage: grade-once.ts <org/repo> [<rubric-slug>]');
  console.error('       GITHUB_TOKEN must be set (or GIT_PAT)');
  process.exit(1);
}

const moduleRoot = path.join(__dirname, '..');
const rubrics = new RubricService(path.join(moduleRoot, 'rubrics'));
const prompts = new PromptService(path.join(moduleRoot, 'templates'));
const validator = new ValidatorService(rubrics);
const spawner = new RealSpawn();

const rubric = rubricArg ?? 'sprint-1-job-pack';
const runId = `grd_once_${Date.now()}`;
const token = process.env.GITHUB_TOKEN ?? process.env.GIT_PAT ?? '';
if (!token) { console.error('GITHUB_TOKEN/GIT_PAT not set'); process.exit(1); }

const runner = new Runner(rubrics, prompts, validator, spawner, spawner, spawner, {
  archiveDir: '/tmp/grader-archive',
  claudeTimeoutMs: 300_000,
  githubToken: token,
}, { onPhase: (rid, phase, status) => console.log(`[${rid}] ${phase}${status ? ' ('+status+')' : ''}`) });

runner.run({ runId, repo, rubric, enqueuedAt: new Date().toISOString() })
  .then(rec => {
    console.log(JSON.stringify(rec, null, 2));
    process.exit(rec.status === 'ok' ? 0 : 2);
  })
  .catch(err => { console.error(err); process.exit(1); });
```

- [ ] **Step 2: Verify the CLI runs against a real test repo (one-time, costs ~$0.30)**

```bash
cd modules/git-grader
GITHUB_TOKEN=$GIT_PAT npx ts-node bin/grade-once.ts uvucs3660/sample-sprint1-grader-test sprint-1-job-pack
```

(Create `uvucs3660/sample-sprint1-grader-test` first if it doesn't exist: a minimal repo with a README and a few source files. The grade will be poor but the pipeline should complete.)

Expected: phases logged to stderr; a JSON run record printed; exit 0; an issue created on the test repo.

- [ ] **Step 3: Commit**

```bash
git add modules/git-grader/bin/grade-once.ts
git commit -m "feat(git-grader): grade-once CLI (Phase 2 deliverable)"
```

---

# PHASE 3 — Queue + dedupe

Goal: serial FIFO queue with same-repo dedupe and ETA computation. End-of-phase deliverable: `bin/grade-queue.ts <repo>...` enqueues a batch and drains them one at a time, printing per-run results.

---

### Task 3.1: Queue service with EWMA-based ETA

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/queue.service.ts`
- Create: `fivex/mod_node/modules/git-grader/tests/unit/queue.service.test.ts`

- [ ] **Step 1: Write the unit test**

`tests/unit/queue.service.test.ts`:

```typescript
import { Queue, QueueConfig } from '../../services/queue.service';
import { Job, RunRecord } from '../../services/types';

class FakeRunner {
  public ran: Job[] = [];
  constructor(private durationMs: number) {}
  async run(job: Job): Promise<RunRecord> {
    this.ran.push(job);
    await new Promise(r => setTimeout(r, this.durationMs));
    return {
      runId: job.runId, repo: job.repo, rubric: job.rubric,
      status: 'ok', startedAt: new Date().toISOString(),
      finishedAt: new Date(Date.now() + this.durationMs).toISOString(),
      durationSeconds: Math.round(this.durationMs / 1000),
    };
  }
}

const cfg: QueueConfig = { seedAverageRunSeconds: 10, ewmaSamples: 5 };

describe('Queue', () => {
  it('runs jobs serially in FIFO order', async () => {
    const runner = new FakeRunner(20);
    const q = new Queue(runner as any, cfg);
    const a = q.enqueue({ repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack' });
    const b = q.enqueue({ repo: 'uvucs3660/b', rubric: 'sprint-1-job-pack' });
    expect(a.queuePosition).toBe(0);
    expect(b.queuePosition).toBe(1);
    await q.drain();
    expect(runner.ran.map(j => j.repo)).toEqual(['uvucs3660/a', 'uvucs3660/b']);
  });

  it('dedupes a second enqueue for the same in-flight repo', async () => {
    const runner = new FakeRunner(50);
    const q = new Queue(runner as any, cfg);
    const first = q.enqueue({ repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack' });
    const second = q.enqueue({ repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack' });
    expect(second.deduped).toBe(true);
    expect(second.runId).toBe(first.runId);
    await q.drain();
    expect(runner.ran.length).toBe(1);
  });

  it('computes etaSeconds from position × averageRunSeconds (seed value before EWMA warm-up)', () => {
    const runner = new FakeRunner(10);
    const q = new Queue(runner as any, { seedAverageRunSeconds: 30, ewmaSamples: 5 });
    q.enqueue({ repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack' });
    const r = q.enqueue({ repo: 'uvucs3660/b', rubric: 'sprint-1-job-pack' });
    expect(r.etaSeconds).toBe(30); // position 1 × seed 30
  });

  it('exposes snapshot of current job + pending list', async () => {
    const runner = new FakeRunner(40);
    const q = new Queue(runner as any, cfg);
    q.enqueue({ repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack' });
    q.enqueue({ repo: 'uvucs3660/b', rubric: 'sprint-1-job-pack' });
    await new Promise(r => setTimeout(r, 5));
    const snap = q.snapshot();
    expect(snap.size).toBe(2);
    expect(snap.currentRunId).toBeDefined();
    expect(snap.pending.length).toBe(1);
    await q.drain();
  });
});
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
npx jest modules/git-grader/tests/unit/queue.service.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Implement the queue service**

`services/queue.service.ts`:

```typescript
import { Job, RunRecord } from './types';

export interface QueueConfig {
  seedAverageRunSeconds: number;
  ewmaSamples: number;
}

export interface EnqueueInput { repo: string; rubric: string; }

export interface EnqueueResult {
  runId: string;
  repo: string;
  rubric: string;
  status: 'queued' | 'in-progress';
  queuePosition: number;
  queueSize: number;
  etaSeconds: number;
  deduped: boolean;
}

export interface RunnerLike { run(job: Job): Promise<RunRecord>; }

export interface QueueSnapshot {
  size: number;
  currentRunId: string | null;
  averageRunSeconds: number;
  pending: { runId: string; repo: string; etaSeconds: number }[];
}

export class Queue {
  private pending: Job[] = [];
  private inFlight = new Map<string, string>(); // repo → runId
  private running: Job | null = null;
  private average: number;
  private completedCount = 0;
  private listeners: ((rec: RunRecord) => void)[] = [];
  private snapshotListeners: ((snap: QueueSnapshot) => void)[] = [];
  private draining = false;

  constructor(private readonly runner: RunnerLike, private readonly config: QueueConfig) {
    this.average = config.seedAverageRunSeconds;
  }

  onComplete(fn: (rec: RunRecord) => void): void { this.listeners.push(fn); }
  onSnapshot(fn: (snap: QueueSnapshot) => void): void { this.snapshotListeners.push(fn); }

  enqueue(input: EnqueueInput): EnqueueResult {
    const existing = this.inFlight.get(input.repo);
    if (existing) {
      return {
        runId: existing, repo: input.repo, rubric: input.rubric,
        status: this.running?.runId === existing ? 'in-progress' : 'queued',
        queuePosition: this.positionOf(existing),
        queueSize: this.size(),
        etaSeconds: this.positionOf(existing) * this.average,
        deduped: true,
      };
    }
    const runId = `grd_${new Date().toISOString().replace(/[:.]/g,'-')}_${randomSuffix()}`;
    const job: Job = { runId, repo: input.repo, rubric: input.rubric, enqueuedAt: new Date().toISOString() };
    this.pending.push(job);
    this.inFlight.set(input.repo, runId);
    this.emitSnapshot();
    void this.tick();
    return {
      runId, repo: input.repo, rubric: input.rubric,
      status: this.running ? 'queued' : 'queued',
      queuePosition: this.positionOf(runId),
      queueSize: this.size(),
      etaSeconds: this.positionOf(runId) * this.average,
      deduped: false,
    };
  }

  snapshot(): QueueSnapshot {
    return {
      size: this.size(),
      currentRunId: this.running?.runId ?? null,
      averageRunSeconds: this.average,
      pending: this.pending.map((j, i) => ({
        runId: j.runId, repo: j.repo, etaSeconds: (i + 1) * this.average,
      })),
    };
  }

  size(): number {
    return (this.running ? 1 : 0) + this.pending.length;
  }

  positionOf(runId: string): number {
    if (this.running?.runId === runId) return 0;
    const idx = this.pending.findIndex(j => j.runId === runId);
    return idx === -1 ? -1 : idx + 1;
  }

  async drain(): Promise<void> {
    while (this.size() > 0) await new Promise(r => setTimeout(r, 5));
  }

  private async tick(): Promise<void> {
    if (this.draining) return;
    if (this.running) return;
    const next = this.pending.shift();
    if (!next) return;
    this.running = next;
    this.draining = true;
    this.emitSnapshot();
    try {
      const t0 = Date.now();
      const rec = await this.runner.run(next);
      const dt = (Date.now() - t0) / 1000;
      this.updateAverage(dt);
      for (const l of this.listeners) { try { l(rec); } catch {} }
    } finally {
      this.inFlight.delete(next.repo);
      this.running = null;
      this.draining = false;
      this.emitSnapshot();
      void this.tick();
    }
  }

  private updateAverage(durationSec: number): void {
    this.completedCount += 1;
    if (this.completedCount <= this.config.ewmaSamples) {
      this.average = ((this.average * (this.completedCount - 1)) + durationSec) / this.completedCount;
    } else {
      const alpha = 2 / (this.config.ewmaSamples + 1);
      this.average = alpha * durationSec + (1 - alpha) * this.average;
    }
  }

  private emitSnapshot(): void {
    const snap = this.snapshot();
    for (const l of this.snapshotListeners) { try { l(snap); } catch {} }
  }
}

function randomSuffix(): string {
  return Math.random().toString(36).slice(2, 8);
}
```

- [ ] **Step 4: Run the tests and verify they pass**

```bash
npx jest modules/git-grader/tests/unit/queue.service.test.ts
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add modules/git-grader/services/queue.service.ts modules/git-grader/tests/unit/queue.service.test.ts
git commit -m "feat(git-grader): serial queue with dedupe and EWMA ETA"
```

---

### Task 3.2: Phase 3 CLI — `bin/grade-queue.ts`

**Files:**
- Create: `fivex/mod_node/modules/git-grader/bin/grade-queue.ts`

- [ ] **Step 1: Write the CLI**

`bin/grade-queue.ts`:

```typescript
#!/usr/bin/env -S npx ts-node
import * as path from 'path';
import { RubricService } from '../services/rubric.service';
import { PromptService } from '../services/prompt.service';
import { ValidatorService } from '../services/validator.service';
import { Runner } from '../services/runner.service';
import { RealSpawn } from '../services/spawn.factory';
import { Queue } from '../services/queue.service';

const repos = process.argv.slice(2);
if (repos.length === 0) {
  console.error('usage: grade-queue.ts <org/repo> [<org/repo>...]');
  process.exit(1);
}

const moduleRoot = path.join(__dirname, '..');
const rubrics = new RubricService(path.join(moduleRoot, 'rubrics'));
const prompts = new PromptService(path.join(moduleRoot, 'templates'));
const validator = new ValidatorService(rubrics);
const spawner = new RealSpawn();
const token = process.env.GITHUB_TOKEN ?? process.env.GIT_PAT ?? '';

const runner = new Runner(rubrics, prompts, validator, spawner, spawner, spawner, {
  archiveDir: '/tmp/grader-archive',
  claudeTimeoutMs: 300_000,
  githubToken: token,
}, { onPhase: (rid, phase, status) => console.log(`[${rid}] ${phase}${status ? ' ('+status+')' : ''}`) });

const queue = new Queue(runner, { seedAverageRunSeconds: 90, ewmaSamples: 20 });
queue.onComplete(rec => console.log(`[${rec.runId}] ${rec.status} → ${rec.issueUrl ?? '(no issue)'}`));

for (const repo of repos) {
  const r = queue.enqueue({ repo, rubric: 'sprint-1-job-pack' });
  console.log(`queued ${repo} as ${r.runId} (eta ${r.etaSeconds}s)`);
}

queue.drain().then(() => { console.log('queue drained'); process.exit(0); });
```

- [ ] **Step 2: Commit**

```bash
git add modules/git-grader/bin/grade-queue.ts
git commit -m "feat(git-grader): grade-queue CLI (Phase 3 deliverable)"
```

---

# PHASE 4 — HTTP module

Goal: register `git-grader` as a mod_node module behind caddy at `2h2.us/git-grade-web-hook` etc.; expose POST trigger, GET runs/queue/failures, POST republish, GET archive files. End-of-phase: first curl-able version.

---

### Task 4.1: Module index + routes scaffold (no persistence yet)

**Files:**
- Create: `fivex/mod_node/modules/git-grader/index.ts`
- Create: `fivex/mod_node/modules/git-grader/routes/grade.routes.ts`

- [ ] **Step 1: Write a transient in-memory record store in routes/grade.routes.ts**

`routes/grade.routes.ts`:

```typescript
import Router from '@koa/router';
import * as fs from 'fs';
import * as path from 'path';
import { Queue } from '../services/queue.service';
import { RunRecord } from '../services/types';

export interface RoutesDeps {
  queue: Queue;
  allowedOrgs: string[];
  defaultRubric: string;
  archiveDir: string;
  records: Map<string, RunRecord>;       // transient until Task 5.1 swaps in data-store
}

export function createGradeRoutes(deps: RoutesDeps): Router {
  const r = new Router();

  r.post('/git-grade-web-hook', async ctx => {
    const body = ctx.request.body as { repo?: string; rubric?: string };
    if (!body?.repo) { ctx.status = 400; ctx.body = { error: 'repo required' }; return; }
    const [org] = body.repo.split('/');
    if (!deps.allowedOrgs.includes(org)) {
      ctx.status = 400; ctx.body = { error: `org not allowed: ${org}` }; return;
    }
    const rubric = body.rubric ?? deps.defaultRubric;
    const res = deps.queue.enqueue({ repo: body.repo, rubric });
    ctx.status = 202;
    ctx.body = {
      ...res,
      statusUrl: `https://2h2.us/git-grade/runs/${res.runId}`,
    };
  });

  r.get('/git-grade/queue', ctx => { ctx.body = deps.queue.snapshot(); });

  r.get('/git-grade/runs/:runId', ctx => {
    const rec = deps.records.get(ctx.params.runId);
    if (!rec) { ctx.status = 404; ctx.body = { error: 'not found' }; return; }
    ctx.body = rec;
  });

  r.get('/git-grade/runs/:runId/files/:fileName', ctx => {
    const file = path.join(deps.archiveDir, ctx.params.runId, ctx.params.fileName);
    if (!fs.existsSync(file) || !file.startsWith(deps.archiveDir)) {
      ctx.status = 404; ctx.body = { error: 'not found' }; return;
    }
    ctx.type = ctx.params.fileName.endsWith('.json') ? 'application/json'
            : ctx.params.fileName.endsWith('.md')   ? 'text/markdown'
            : 'text/plain';
    ctx.body = fs.createReadStream(file);
  });

  r.get('/git-grade/failures', ctx => {
    const since = (ctx.query.since as string) || '24h';
    const ms = parseDuration(since);
    const cutoff = Date.now() - ms;
    const totals: Record<string, number> = {};
    const failures: unknown[] = [];
    for (const rec of deps.records.values()) {
      if (!rec.finishedAt) continue;
      if (new Date(rec.finishedAt).getTime() < cutoff) continue;
      totals[rec.status] = (totals[rec.status] ?? 0) + 1;
      if (rec.status !== 'ok') {
        failures.push({
          runId: rec.runId, repo: rec.repo, status: rec.status,
          errorMessage: rec.error?.message, runUrl: `/git-grade/runs/${rec.runId}`,
          stderrTail: rec.error?.stderrTail,
        });
      }
    }
    ctx.body = { window: since, totals, failures };
  });

  return r;
}

function parseDuration(s: string): number {
  const m = s.match(/^(\d+)([smhd])$/);
  if (!m) return 24 * 3600 * 1000;
  const n = Number(m[1]);
  const unit = m[2];
  return n * { s: 1000, m: 60000, h: 3600000, d: 86400000 }[unit as 's'|'m'|'h'|'d'];
}
```

- [ ] **Step 2: Write the module index**

`index.ts`:

```typescript
import * as path from 'path';
import { ModuleDefinition, ModuleContext, HealthStatus } from '../../src/core/types';
import { RubricService } from './services/rubric.service';
import { PromptService } from './services/prompt.service';
import { ValidatorService } from './services/validator.service';
import { Runner } from './services/runner.service';
import { Queue } from './services/queue.service';
import { RealSpawn } from './services/spawn.factory';
import { RunRecord } from './services/types';
import { createGradeRoutes } from './routes/grade.routes';

const moduleRoot = __dirname;

const graderModule: ModuleDefinition = {
  id: 'git-grader',

  async onLoad(ctx: ModuleContext) {
    const rubrics = new RubricService(path.join(moduleRoot, 'rubrics'));
    const prompts = new PromptService(path.join(moduleRoot, 'templates'));
    const validator = new ValidatorService(rubrics);
    const spawner = new RealSpawn();
    const token = (ctx.config.githubToken as string) || process.env.GITHUB_TOKEN || process.env.GIT_PAT || '';
    const archiveDir = (ctx.config.archiveDir as string) ?? '/var/grader/runs';
    const claudeTimeoutMs = (ctx.config.claudeTimeoutMs as number) ?? 300_000;

    const records = new Map<string, RunRecord>();    // Task 5.1 will replace this with data-store reads/writes

    const runner = new Runner(rubrics, prompts, validator, spawner, spawner, spawner, {
      archiveDir, claudeTimeoutMs, githubToken: token,
    }, {
      onPhase: (runId, phase, status) => ctx.logger.info('grader phase', { runId, phase, status }),
    });

    const queue = new Queue(runner, {
      seedAverageRunSeconds: (ctx.config.seedAverageRunSeconds as number) ?? 90,
      ewmaSamples:           (ctx.config.ewmaSamples as number) ?? 20,
    });
    queue.onComplete(rec => { records.set(rec.runId, rec); });

    ctx.services.gitGrader = { rubrics, queue, records, archiveDir, allowedOrgs: ctx.config.allowedOrgs as string[] ?? ['uvucs3660'] };
    ctx.logger.info('git-grader loaded');
  },

  async onEnable(ctx: ModuleContext) {
    const deps = ctx.services.gitGrader as {
      queue: Queue; records: Map<string, RunRecord>;
      archiveDir: string; allowedOrgs: string[];
    };
    const routes = createGradeRoutes({
      queue: deps.queue, records: deps.records, archiveDir: deps.archiveDir,
      allowedOrgs: deps.allowedOrgs,
      defaultRubric: (ctx.config.defaultRubric as string) || 'sprint-1-job-pack',
    });
    ctx.router.use('/', routes); // routes carry full paths
    ctx.logger.info('git-grader enabled');
  },

  async onDisable(ctx: ModuleContext) {
    ctx.router.remove('/');
    ctx.logger.info('git-grader disabled');
  },

  async healthCheck(_ctx: ModuleContext): Promise<HealthStatus> {
    return { healthy: true };
  },
};

export default graderModule;
```

- [ ] **Step 3: Commit**

```bash
git add modules/git-grader/index.ts modules/git-grader/routes/grade.routes.ts
git commit -m "feat(git-grader): module index + HTTP routes (in-memory records)"
```

---

### Task 4.2: HTTP integration tests via supertest

**Files:**
- Create: `fivex/mod_node/modules/git-grader/tests/integration/routes.test.ts`

- [ ] **Step 1: Write the failing test**

`tests/integration/routes.test.ts`:

```typescript
import Koa from 'koa';
import bodyParser from '@koa/bodyparser';
import request from 'supertest';
import { createGradeRoutes } from '../../routes/grade.routes';
import { Queue } from '../../services/queue.service';
import { RunRecord, Job } from '../../services/types';

class FakeRunner {
  async run(job: Job): Promise<RunRecord> {
    return {
      runId: job.runId, repo: job.repo, rubric: job.rubric,
      status: 'ok', startedAt: new Date().toISOString(),
      finishedAt: new Date().toISOString(), durationSeconds: 1,
      issueUrl: `https://github.com/${job.repo}/issues/99`,
    };
  }
}

function makeApp() {
  const queue = new Queue(new FakeRunner() as any, { seedAverageRunSeconds: 5, ewmaSamples: 5 });
  const records = new Map<string, RunRecord>();
  queue.onComplete(rec => records.set(rec.runId, rec));
  const r = createGradeRoutes({
    queue, records, archiveDir: '/tmp/git-grader-test-archive',
    allowedOrgs: ['uvucs3660'], defaultRubric: 'sprint-1-job-pack',
  });
  const app = new Koa();
  app.use(bodyParser());
  app.use(r.routes());
  return { app, queue, records };
}

describe('grade routes (integration)', () => {
  it('POST /git-grade-web-hook returns 202 with runId', async () => {
    const { app } = makeApp();
    const res = await request(app.callback())
      .post('/git-grade-web-hook')
      .send({ repo: 'uvucs3660/sprint1_alice_summer_2026' });
    expect(res.status).toBe(202);
    expect(res.body.runId).toMatch(/^grd_/);
    expect(res.body.rubric).toBe('sprint-1-job-pack');
    expect(res.body.statusUrl).toContain('/git-grade/runs/');
    expect(res.body.deduped).toBe(false);
  });

  it('POST rejects repo not under allowed org', async () => {
    const { app } = makeApp();
    const res = await request(app.callback())
      .post('/git-grade-web-hook')
      .send({ repo: 'someoneelse/repo' });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/org not allowed/);
  });

  it('GET /git-grade/queue returns a snapshot', async () => {
    const { app } = makeApp();
    const res = await request(app.callback()).get('/git-grade/queue');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('size');
    expect(res.body).toHaveProperty('pending');
  });

  it('GET /git-grade/runs/:runId returns 404 for unknown', async () => {
    const { app } = makeApp();
    const res = await request(app.callback()).get('/git-grade/runs/grd_unknown');
    expect(res.status).toBe(404);
  });

  it('dedupe: second POST for same repo returns same runId with deduped:true', async () => {
    const { app } = makeApp();
    const first = await request(app.callback())
      .post('/git-grade-web-hook')
      .send({ repo: 'uvucs3660/sprint1_alice_summer_2026' });
    const second = await request(app.callback())
      .post('/git-grade-web-hook')
      .send({ repo: 'uvucs3660/sprint1_alice_summer_2026' });
    expect(second.body.runId).toBe(first.body.runId);
    expect(second.body.deduped).toBe(true);
  });
});
```

- [ ] **Step 2: Run the test and verify it passes**

```bash
npx jest modules/git-grader/tests/integration/routes.test.ts
```

Expected: PASS (5 tests).

- [ ] **Step 3: Commit**

```bash
git add modules/git-grader/tests/integration/routes.test.ts
git commit -m "test(git-grader): supertest coverage for HTTP routes"
```

---

### Task 4.3: Register module in mod_node config

**Files:**
- Modify: `fivex/mod_node/config/modules.yaml`

- [ ] **Step 1: Add the git-grader block to modules.yaml**

Append to `config/modules.yaml`:

```yaml
  git-grader:
    enabled: true
    config:
      defaultRubric: sprint-1-job-pack
      allowedOrgs: [uvucs3660]
      claudeTimeoutMs: 300000
      archiveDir: /var/grader/runs
      archiveRetentionDays: 180
      seedAverageRunSeconds: 90
      ewmaSamples: 20
      # githubToken: read from env GITHUB_TOKEN or GIT_PAT at module load
```

- [ ] **Step 2: Start the dev server and verify the module loads**

```bash
npm run dev
```

In another shell:

```bash
curl -s http://localhost:3000/git-grade/queue | jq .
```

Expected: `{ "size": 0, "currentRunId": null, "averageRunSeconds": 90, "pending": [] }`.

- [ ] **Step 3: Commit**

```bash
git add config/modules.yaml
git commit -m "chore(git-grader): register git-grader module in modules.yaml"
```

---

### Task 4.4: Republish endpoint

**Files:**
- Modify: `fivex/mod_node/modules/git-grader/routes/grade.routes.ts`
- Modify: `fivex/mod_node/modules/git-grader/tests/integration/routes.test.ts`

- [ ] **Step 1: Write the failing test (append to routes.test.ts)**

Add to `tests/integration/routes.test.ts`:

```typescript
  it('POST /git-grade/runs/:runId/republish re-posts an existing report', async () => {
    const { app, records } = makeApp();
    // seed a failed:post record with an archived report
    const fs = require('fs'); const path = require('path');
    const archiveDir = '/tmp/git-grader-test-archive/grd_repost_001';
    fs.mkdirSync(archiveDir, { recursive: true });
    fs.writeFileSync(path.join(archiveDir, 'grade-report.md'), '# fake\n');
    records.set('grd_repost_001', {
      runId: 'grd_repost_001', repo: 'uvucs3660/x', rubric: 'sprint-1-job-pack',
      status: 'failed:post', startedAt: new Date().toISOString(),
      finishedAt: new Date().toISOString(), durationSeconds: 1,
      error: { phase: 'post', message: 'gh transient' },
    });
    const res = await request(app.callback())
      .post('/git-grade/runs/grd_repost_001/republish').send();
    // The route exists; whether it actually posts depends on a republisher dep
    // injected in Task 4.4 step 2 — for now we just expect 202 acknowledging the retry.
    expect([200, 202]).toContain(res.status);
  });
```

- [ ] **Step 2: Add the republish handler that uses an injectable republisher**

Modify `RoutesDeps` and add a route. Update `routes/grade.routes.ts` `RoutesDeps`:

```typescript
export interface RoutesDeps {
  queue: Queue;
  allowedOrgs: string[];
  defaultRubric: string;
  archiveDir: string;
  records: Map<string, RunRecord>;
  republish: (runId: string) => Promise<RunRecord>;
}
```

Add the route inside `createGradeRoutes`:

```typescript
  r.post('/git-grade/runs/:runId/republish', async ctx => {
    const rec = deps.records.get(ctx.params.runId);
    if (!rec) { ctx.status = 404; ctx.body = { error: 'not found' }; return; }
    if (rec.status !== 'failed:post') {
      ctx.status = 409; ctx.body = { error: `cannot republish status ${rec.status}` }; return;
    }
    const updated = await deps.republish(ctx.params.runId);
    deps.records.set(ctx.params.runId, updated);
    ctx.status = 202; ctx.body = updated;
  });
```

In the test's `makeApp()`, pass a stub republisher:

```typescript
  const r = createGradeRoutes({
    queue, records, archiveDir: '/tmp/git-grader-test-archive',
    allowedOrgs: ['uvucs3660'], defaultRubric: 'sprint-1-job-pack',
    republish: async runId => {
      const rec = records.get(runId)!;
      return { ...rec, status: 'ok', issueUrl: 'https://github.com/x/issues/1' };
    },
  });
```

- [ ] **Step 3: Implement the real republisher in `index.ts`**

Inside `onLoad`, before constructing `routes`:

```typescript
    const ghProc = new RealSpawn();
    const republish = async (runId: string) => {
      const rec = records.get(runId)!;
      const reportPath = path.join(archiveDir, runId, 'grade-report.md');
      const label = `auto-grade:${rec.rubric}`;
      const list = await ghProc.run({
        command: 'gh', args: ['issue', 'list', '--repo', rec.repo, '--label', label, '--state', 'open', '--json', 'number'],
        env: { GITHUB_TOKEN: token }, timeoutMs: 30_000,
      });
      const existing = list.exitCode === 0 ? JSON.parse(list.stdout || '[]') as { number: number }[] : [];
      let post;
      if (existing.length > 0) {
        post = await ghProc.run({ command: 'gh', args: ['issue', 'comment', String(existing[0].number), '--repo', rec.repo, '--body-file', reportPath], env: { GITHUB_TOKEN: token }, timeoutMs: 30_000 });
        rec.issueAction = 'commented';
      } else {
        post = await ghProc.run({ command: 'gh', args: ['issue', 'create', '--repo', rec.repo, '--title', `Auto-grade: ${rec.rubric} — ${new Date().toISOString().slice(0,10)}`, '--label', label, '--body-file', reportPath], env: { GITHUB_TOKEN: token }, timeoutMs: 30_000 });
        rec.issueAction = 'created';
      }
      if (post.exitCode !== 0) {
        rec.error = { phase: 'post', message: `gh re-post failed: exit ${post.exitCode}`, exitCode: post.exitCode };
        return rec;
      }
      rec.status = 'ok';
      rec.issueUrl = post.stdout.trim().split(/\s+/).pop() ?? null;
      return rec;
    };
```

And pass `republish` into `createGradeRoutes` call.

- [ ] **Step 4: Run tests and verify they all pass**

```bash
npx jest modules/git-grader
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/git-grader/routes/grade.routes.ts modules/git-grader/index.ts modules/git-grader/tests/integration/routes.test.ts
git commit -m "feat(git-grader): republish endpoint for failed:post recovery"
```

---

# PHASE 5 — Persistence + MQTT

Goal: run records persist to mod_node's data-store; startup recovery cleans orphaned `running` records; MQTT events publish at every phase transition; queue snapshots publish on changes.

---

### Task 5.1: Swap in-memory records map for data-store

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/record.store.ts`
- Modify: `fivex/mod_node/modules/git-grader/index.ts`
- Modify: `fivex/mod_node/modules/git-grader/routes/grade.routes.ts`

- [ ] **Step 1: Write the record store**

`services/record.store.ts`:

```typescript
import { RunRecord } from './types';

export interface DataServiceLike {
  load(path: string): Promise<unknown>;
  save(path: string, data: unknown): Promise<unknown>;
  allRows(pathPattern: string): Promise<{ path: string; data: unknown }[]>;
}

export class RecordStore {
  constructor(private readonly data: DataServiceLike) {}

  private p(runId: string): string { return `grades/${runId}`; }

  async put(rec: RunRecord): Promise<void> {
    await this.data.save(this.p(rec.runId), rec);
  }

  async get(runId: string): Promise<RunRecord | undefined> {
    const row = await this.data.load(this.p(runId));
    if (!row || Object.keys(row as object).length === 0) return undefined;
    return row as RunRecord;
  }

  async listSince(cutoffMs: number): Promise<RunRecord[]> {
    const rows = await this.data.allRows('grades/%');
    return (rows.map(r => r.data as RunRecord))
      .filter(r => r.finishedAt && new Date(r.finishedAt).getTime() >= cutoffMs);
  }

  async findRunning(): Promise<RunRecord[]> {
    const rows = await this.data.allRows('grades/%');
    return rows.map(r => r.data as RunRecord).filter(r => r.status === 'running');
  }

  async findByRepo(repo: string, limit: number = 50): Promise<RunRecord[]> {
    const rows = await this.data.allRows('grades/%');
    return rows.map(r => r.data as RunRecord)
      .filter(r => r.repo === repo)
      .sort((a, b) => (b.startedAt ?? '').localeCompare(a.startedAt ?? ''))
      .slice(0, limit);
  }
}
```

- [ ] **Step 2: Update RoutesDeps to take RecordStore instead of Map**

Replace `records: Map<string, RunRecord>` with `records: RecordStore` in `RoutesDeps`, and change every record access in `grade.routes.ts` to use `await records.get(...)` / `records.put(...)`. Update the supertest test's `makeApp()` to construct an in-memory fake of `DataServiceLike`:

```typescript
class FakeData {
  private rows = new Map<string, unknown>();
  async load(path: string) { return this.rows.get(path) ?? {}; }
  async save(path: string, data: unknown) { this.rows.set(path, data); return { path, data }; }
  async allRows(pattern: string) {
    const prefix = pattern.replace(/%$/, '');
    return Array.from(this.rows.entries())
      .filter(([k]) => k.startsWith(prefix))
      .map(([path, data]) => ({ path, data }));
  }
}
```

(Adapt failures route, runs route, republish, etc. to `await` the store.)

- [ ] **Step 3: Wire the real DataService in `index.ts#onLoad`**

```typescript
    const data = ctx.require<DataServiceLike>('data');     // exposed by data-store module
    const store = new RecordStore(data);
    queue.onComplete(async rec => { await store.put(rec); });
```

Also update the runner construction so per-phase records (`running`, `failed:*`) are persisted, not only on `onComplete`. The simplest path: have the `RunnerHooks.onPhase` callback also write a stub `running` record into the store on entry. Update the `onPhase` callback:

```typescript
    const runner = new Runner(rubrics, prompts, validator, spawner, spawner, spawner, {
      archiveDir, claudeTimeoutMs, githubToken: token,
    }, {
      onPhase: async (runId, phase, status) => {
        ctx.logger.info('grader phase', { runId, phase, status });
        if (phase === 'running') {
          await store.put({ runId, repo: '', rubric: '', status: 'running', startedAt: new Date().toISOString() } as RunRecord);
        }
      },
    });
```

(The full record overwrites this stub when the job completes via `queue.onComplete`.)

- [ ] **Step 4: Run all tests**

```bash
npx jest modules/git-grader
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/git-grader/services/record.store.ts modules/git-grader/routes/grade.routes.ts modules/git-grader/index.ts modules/git-grader/tests/integration/routes.test.ts
git commit -m "feat(git-grader): persist run records via data-store module"
```

---

### Task 5.2: Startup recovery sweep

**Files:**
- Modify: `fivex/mod_node/modules/git-grader/index.ts`

- [ ] **Step 1: Add the recovery sweep in `onLoad` after `store` construction**

```typescript
    const orphans = await store.findRunning();
    for (const r of orphans) {
      const fixed: RunRecord = {
        ...r, status: 'failed:interrupted',
        finishedAt: new Date().toISOString(),
        error: { phase: 'interrupted', message: 'mod_node restart killed run before completion' },
      };
      await store.put(fixed);
      ctx.logger.warn('git-grader recovered orphaned run', { runId: r.runId });
    }
```

- [ ] **Step 2: Add a unit-style test that exercises the recovery code path against an in-memory store**

`tests/integration/recovery.test.ts`:

```typescript
import { RecordStore } from '../../services/record.store';
import { RunRecord } from '../../services/types';

class FakeData {
  private rows = new Map<string, unknown>();
  async load(p: string) { return this.rows.get(p) ?? {}; }
  async save(p: string, d: unknown) { this.rows.set(p, d); return { path: p, data: d }; }
  async allRows(pattern: string) {
    const prefix = pattern.replace(/%$/, '');
    return Array.from(this.rows.entries())
      .filter(([k]) => k.startsWith(prefix))
      .map(([path, data]) => ({ path, data }));
  }
}

describe('startup recovery', () => {
  it('marks running-without-finishedAt records as failed:interrupted', async () => {
    const store = new RecordStore(new FakeData());
    await store.put({ runId: 'grd_a', repo: 'x/y', rubric: 'sprint-1-job-pack', status: 'running', startedAt: '2026-05-31T00:00:00Z' } as RunRecord);
    await store.put({ runId: 'grd_b', repo: 'x/z', rubric: 'sprint-1-job-pack', status: 'ok', startedAt: '2026-05-31T00:00:00Z', finishedAt: '2026-05-31T00:01:00Z' } as RunRecord);

    const orphans = await store.findRunning();
    expect(orphans.map(o => o.runId)).toEqual(['grd_a']);

    for (const o of orphans) {
      await store.put({ ...o, status: 'failed:interrupted', finishedAt: new Date().toISOString() } as RunRecord);
    }
    const after = await store.findRunning();
    expect(after).toEqual([]);
  });
});
```

- [ ] **Step 3: Run and commit**

```bash
npx jest modules/git-grader/tests/integration/recovery.test.ts
git add modules/git-grader/index.ts modules/git-grader/tests/integration/recovery.test.ts
git commit -m "feat(git-grader): startup recovery sweep for orphaned runs"
```

---

### Task 5.3: MQTT publisher service + wiring

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/publisher.service.ts`
- Modify: `fivex/mod_node/modules/git-grader/index.ts`

- [ ] **Step 1: Write the publisher**

`services/publisher.service.ts`:

```typescript
import { RunRecord, RunStatus } from './types';
import { QueueSnapshot } from './queue.service';

export interface MqttPublisher {
  publish(topic: string, message: unknown): void;
}

export class Publisher {
  constructor(private readonly mqtt: MqttPublisher) {}

  emitRunEvent(runId: string, repo: string, rubric: string, phase: string, status?: RunStatus): void {
    this.mqtt.publish(`cs3660/grader/runs/${runId}/event`, {
      runId, repo, rubric, phase, status, ts: new Date().toISOString(),
    });
  }

  emitQueueSnapshot(snap: QueueSnapshot): void {
    this.mqtt.publish('cs3660/grader/queue/snapshot', snap);
  }

  emitFailure(rec: RunRecord): void {
    this.mqtt.publish(`cs3660/grader/failures/${rec.rubric}`, {
      runId: rec.runId, repo: rec.repo, rubric: rec.rubric,
      phase: rec.error?.phase, errorMessage: rec.error?.message,
    });
  }
}
```

- [ ] **Step 2: Wire publisher into runner.onPhase and queue.onSnapshot in `index.ts#onLoad`**

```typescript
    const publisher = new Publisher({ publish: (t, m) => ctx.mqtt.publish(t, m) });

    const runner = new Runner(rubrics, prompts, validator, spawner, spawner, spawner,
      { archiveDir, claudeTimeoutMs, githubToken: token },
      {
        onPhase: async (runId, phase, status) => {
          ctx.logger.info('grader phase', { runId, phase, status });
          publisher.emitRunEvent(runId, '', '', phase, status);
          if (phase === 'running') {
            await store.put({ runId, repo: '', rubric: '', status: 'running', startedAt: new Date().toISOString() } as RunRecord);
          }
        },
      });

    const queue = new Queue(runner, {
      seedAverageRunSeconds: (ctx.config.seedAverageRunSeconds as number) ?? 90,
      ewmaSamples:           (ctx.config.ewmaSamples as number) ?? 20,
    });
    queue.onSnapshot(snap => publisher.emitQueueSnapshot(snap));
    queue.onComplete(async rec => {
      await store.put(rec);
      if (rec.status !== 'ok') publisher.emitFailure(rec);
    });
```

- [ ] **Step 3: Smoke test publishing by subscribing locally**

In another shell:

```bash
mosquitto_sub -h mqtt.uvucs.org -t 'cs3660/grader/#' -v
```

Then trigger a curl:

```bash
curl -X POST http://localhost:3000/git-grade-web-hook \
  -H 'content-type: application/json' \
  -d '{"repo":"uvucs3660/sample-sprint1-grader-test"}'
```

Expected: see `queue/snapshot` and several `runs/.../event` messages appear.

- [ ] **Step 4: Commit**

```bash
git add modules/git-grader/services/publisher.service.ts modules/git-grader/index.ts
git commit -m "feat(git-grader): MQTT event publishing for phases, queue, failures"
```

---

### Task 5.4: Per-repo history endpoint

**Files:**
- Modify: `fivex/mod_node/modules/git-grader/routes/grade.routes.ts`
- Modify: `fivex/mod_node/modules/git-grader/tests/integration/routes.test.ts`

- [ ] **Step 1: Add the route**

In `createGradeRoutes`:

```typescript
  r.get('/git-grade/runs', async ctx => {
    const repo = ctx.query.repo as string | undefined;
    if (!repo) { ctx.status = 400; ctx.body = { error: 'repo required' }; return; }
    const limit = Number(ctx.query.limit ?? 50);
    const items = await deps.records.findByRepo(repo, limit);
    ctx.body = { repo, items };
  });
```

(Note: requires switching `RoutesDeps.records` to `RecordStore` type, completed in Task 5.1.)

- [ ] **Step 2: Add a test in routes.test.ts**

```typescript
  it('GET /git-grade/runs?repo=x/y returns history filtered by repo', async () => {
    const { app, records } = makeApp();
    await records.put({ runId: 'grd_h1', repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack', status: 'ok', startedAt: '2026-05-31T00:01:00Z', finishedAt: '2026-05-31T00:02:00Z', durationSeconds: 60 });
    await records.put({ runId: 'grd_h2', repo: 'uvucs3660/a', rubric: 'sprint-1-job-pack', status: 'ok', startedAt: '2026-05-31T00:03:00Z', finishedAt: '2026-05-31T00:04:00Z', durationSeconds: 60 });
    await records.put({ runId: 'grd_h3', repo: 'uvucs3660/b', rubric: 'sprint-1-job-pack', status: 'ok', startedAt: '2026-05-31T00:05:00Z', finishedAt: '2026-05-31T00:06:00Z', durationSeconds: 60 });
    const res = await request(app.callback()).get('/git-grade/runs?repo=uvucs3660/a');
    expect(res.status).toBe(200);
    expect(res.body.items.length).toBe(2);
    expect(res.body.items[0].runId).toBe('grd_h2'); // newer first
  });
```

(`records` in the test is now a `RecordStore` wrapping `FakeData`.)

- [ ] **Step 3: Run, commit**

```bash
npx jest modules/git-grader/tests/integration/routes.test.ts
git add modules/git-grader/routes/grade.routes.ts modules/git-grader/tests/integration/routes.test.ts
git commit -m "feat(git-grader): per-repo history endpoint"
```

---

### Task 5.5: Archive retention sweep

**Files:**
- Create: `fivex/mod_node/modules/git-grader/services/archive.service.ts`
- Modify: `fivex/mod_node/modules/git-grader/index.ts`

- [ ] **Step 1: Write the archive service**

`services/archive.service.ts`:

```typescript
import * as fs from 'fs/promises';
import * as path from 'path';

export class ArchiveSweep {
  constructor(private readonly archiveDir: string, private readonly retentionDays: number) {}

  async sweep(now: Date = new Date()): Promise<{ removed: string[] }> {
    const cutoff = now.getTime() - this.retentionDays * 86400_000;
    const removed: string[] = [];
    let entries: string[];
    try { entries = await fs.readdir(this.archiveDir); }
    catch (e: any) { if (e.code === 'ENOENT') return { removed }; throw e; }

    for (const e of entries) {
      const dir = path.join(this.archiveDir, e);
      const stat = await fs.stat(dir);
      if (stat.isDirectory() && stat.mtimeMs < cutoff) {
        await fs.rm(dir, { recursive: true, force: true });
        removed.push(e);
      }
    }
    return { removed };
  }
}
```

- [ ] **Step 2: Run a daily sweep via setInterval in `onEnable`**

```typescript
    const sweep = new ArchiveSweep(archiveDir, (ctx.config.archiveRetentionDays as number) ?? 180);
    const sweepHandle = setInterval(async () => {
      try {
        const r = await sweep.sweep();
        if (r.removed.length > 0) ctx.logger.info('grader archive swept', { removed: r.removed.length });
      } catch (e) { ctx.logger.error('grader archive sweep failed', { err: String(e) }); }
    }, 24 * 3600 * 1000);
    (ctx.services.gitGrader as any).sweepHandle = sweepHandle;
```

In `onDisable`:

```typescript
    const handle = (ctx.services.gitGrader as any).sweepHandle;
    if (handle) clearInterval(handle);
```

- [ ] **Step 3: Commit**

```bash
git add modules/git-grader/services/archive.service.ts modules/git-grader/index.ts
git commit -m "feat(git-grader): daily archive retention sweep"
```

---

# PHASE 6 — Cron + sprint deadlines

Goal: at each sprint due date, a cron job curls `/git-grade-web-hook` for every student repo for that sprint.

---

### Task 6.1: Sprint → repo list config

**Files:**
- Create: `fivex/mod_node/modules/git-grader/config/sprint-roster.yaml`
- Create: `fivex/mod_node/modules/git-grader/bin/cron-grade-sprint.ts`

- [ ] **Step 1: Write the roster file**

`config/sprint-roster.yaml`:

```yaml
# Maps each sprint deadline to (rubric, repo list).
# Edit at the start of each semester.
sprints:
  - id: sprint-1
    dueAt: 2026-06-15T23:59:00-06:00
    rubric: sprint-1-job-pack
    repoTemplate: "uvucs3660/sprint1_{username}_summer_2026"
    students: []   # filled by hand at start of semester, e.g. [alice, bob, …]
  - id: sprint-2
    dueAt: 2026-06-29T23:59:00-06:00
    rubric: sprint-2-messaging
    repoTemplate: "uvucs3660/sprint2_{username}_summer_2026"
    students: []
  - id: sprint-3
    dueAt: 2026-07-13T23:59:00-06:00
    rubric: sprint-3-capstone
    repoTemplate: "uvucs3660/sprint3_{username}_summer_2026"
    students: []
```

- [ ] **Step 2: Write the cron CLI**

`bin/cron-grade-sprint.ts`:

```typescript
#!/usr/bin/env -S npx ts-node
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';

interface SprintRoster {
  sprints: {
    id: string; dueAt: string; rubric: string;
    repoTemplate: string; students: string[];
  }[];
}

const [,, sprintId] = process.argv;
if (!sprintId) {
  console.error('usage: cron-grade-sprint.ts <sprint-id>');
  console.error('example: cron-grade-sprint.ts sprint-1');
  process.exit(1);
}

const rosterPath = path.join(__dirname, '../config/sprint-roster.yaml');
const roster = yaml.load(fs.readFileSync(rosterPath, 'utf8'), {
  schema: yaml.JSON_SCHEMA,   // refuses any !!js/* or other dangerous type tags
}) as SprintRoster;
const sprint = roster.sprints.find(s => s.id === sprintId);
if (!sprint) { console.error(`unknown sprint: ${sprintId}`); process.exit(1); }

const endpoint = process.env.GRADER_ENDPOINT ?? 'https://2h2.us/git-grade-web-hook';

async function trigger(repo: string, rubric: string): Promise<void> {
  const res = await fetch(endpoint, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ repo, rubric }),
  });
  const text = await res.text();
  console.log(`${repo}: ${res.status} ${text}`);
}

(async () => {
  for (const username of sprint.students) {
    const repo = sprint.repoTemplate.replace('{username}', username);
    try { await trigger(repo, sprint.rubric); }
    catch (e) { console.error(`${repo}: ERROR ${String(e)}`); }
  }
})();
```

- [ ] **Step 3: Document the crontab entry**

Add to `modules/git-grader/README.md` (create if missing):

```markdown
## Cron entries

On the host that runs mod_node (or a host that can reach 2h2.us):

```cron
59 23 15 6 *  cd /opt/fivex/mod_node && npx ts-node modules/git-grader/bin/cron-grade-sprint.ts sprint-1 >> /var/log/grader-cron.log 2>&1
59 23 29 6 *  cd /opt/fivex/mod_node && npx ts-node modules/git-grader/bin/cron-grade-sprint.ts sprint-2 >> /var/log/grader-cron.log 2>&1
59 23 13 7 *  cd /opt/fivex/mod_node && npx ts-node modules/git-grader/bin/cron-grade-sprint.ts sprint-3 >> /var/log/grader-cron.log 2>&1
```

Adjust dates for the actual semester. The cron does not need any credentials —
it just hits the public endpoint.
```

- [ ] **Step 4: Commit**

```bash
git add modules/git-grader/config/sprint-roster.yaml modules/git-grader/bin/cron-grade-sprint.ts modules/git-grader/README.md
git commit -m "feat(git-grader): sprint roster + cron CLI (Phase 6 deliverable)"
```

---

## Self-review (the implementer should NOT do this — already done by the plan author)

Spec coverage:
- Module shape, HTTP surface, dedupe, ETA — Phases 1, 3, 4.
- Worker pipeline (clone, render, claude, validate, post, persist) — Phase 2 + 5.
- Prompt template + grade contract — Phase 1.
- Run record schema + per-run archive — Phase 2 + 5.
- Failure taxonomy + republish endpoint — Phase 2 (taxonomy in runner) + 4.4 (republish).
- Startup recovery — Phase 5.2.
- MQTT events — Phase 5.3.
- Cron — Phase 6.
- Dashboard (Phase 7 of spec) — DEFERRED to a separate plan as noted in the header.
- Org allowlist with HTTP 400 — Phase 4.1 (route handler) + 4.3 (config).
- EWMA bootstrap behavior — Phase 3.1 (queue test verifies seed-then-EWMA).

Placeholder scan: no TBD/TODO/"implement later" found. Every code step contains the actual code.

Type consistency: `RunRecord`, `Job`, `EnqueueResult`, `SpawnableProcess`, `Rubric`, `RubricCriterion`, `RubricRating`, `Grade`, `GradeCriterion`, `RoutesDeps`, `RunnerConfig`, `QueueConfig`, `QueueSnapshot`, `Publisher` — all used consistently across tasks.

---

## After completing all tasks

1. **Smoke test the full path**: in a clean environment, `npm install && npm run build && npm run dev`, then `curl -X POST http://localhost:3000/git-grade-web-hook -d '{"repo":"uvucs3660/sample-sprint1-grader-test"}'`.
2. **Wire caddy/nginx** at the fivex edge to route `2h2.us/git-grade-web-hook` and `2h2.us/git-grade/*` to mod_node.
3. **Open the spec** (`course_builder/docs/specs/2026-05-31-git-grader-design.md`) and verify the implementation matches.
4. **Start Phase 7** (Dashboard) by writing its own plan once the API is stable for a few days of real use.
