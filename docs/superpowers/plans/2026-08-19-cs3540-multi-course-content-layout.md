# Multi-Course Content Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `course_builder/content/` to `content/<course>/<year>/` and teach the fivex
rubric bundler to read every course, so CS 3540 rubrics can deploy to the 2h2.us grader without
disturbing CS 3660.

**Architecture:** `bin/build_canvas_zip.dart` already takes the content directory as an argument,
so no Dart source changes are needed — only the four test call sites that hardcode `content/2026`.
The fivex side replaces a hardcoded single-directory copy with a two-level walk that fails loudly
on filename collisions.

**Tech Stack:** Dart 3 (`dart test`), Node 20 ESM, jest + ts-jest, `js-yaml`.

**Spec:** `docs/superpowers/specs/2026-08-19-cs3540-2026-fall-design.md` (§10 Infrastructure work)

## Global Constraints

- **Rubric slugs are globally unique across all courses.** `RubricService.load(slug)` reads
  `${slug}.yaml` from a flat directory and throws if the file's `slug:` field does not equal the
  filename stem. CS 3540 rubric files and slugs are therefore prefixed `cs3540-`.
- **CS 3660 content is not edited, only moved.** Its 2026 summer term is closed; any behavior
  change to its rubrics is out of scope and a regression.
- **The rubric bundle destination stays** `modules/git-grader/rubrics` (flat).
- **Absolute path to the workspace:** `/Users/michael/code/uvu`.
- **fivex module root:** `/Users/michael/code/fivex/mod_node`.
- Never `git push` or deploy as part of these tasks. Deployment is a separate, human-run step.

---

### Task 1: Move CS 3660 content under a course directory

**Files:**
- Move: `content/2026/` → `content/cs3660/2026/`
- Modify: `test/cc_rubrics_validation_test.dart:13`
- Modify: `test/quizzes_test.dart:19`, `test/quizzes_test.dart:56`, `test/quizzes_test.dart:128`

**Interfaces:**
- Consumes: nothing.
- Produces: content root layout `content/<course>/<year>/`, consumed by Tasks 2 and 3.

- [ ] **Step 1: Record the current green baseline**

Run from `/Users/michael/code/uvu/tools/course_builder`:

```bash
dart test 2>&1 | tail -5
```

Expected: all tests pass. Write the pass count down; Step 6 must match it.

- [ ] **Step 2: Move the directory with git**

```bash
mkdir -p content/cs3660
git mv content/2026 content/cs3660/2026
git status --short | head -5
```

Expected: staged renames, no untracked leftovers under `content/2026`.

- [ ] **Step 3: Run tests to verify they now fail**

```bash
dart test 2>&1 | tail -20
```

Expected: FAIL. `cc_rubrics_validation_test.dart` and `quizzes_test.dart` raise
`FileSystemException` / `PathNotFoundException` on `content/2026/...`. This failure is the
proof that these four call sites are the only path coupling.

- [ ] **Step 4: Update the four hardcoded paths**

In `test/cc_rubrics_validation_test.dart` line 13:

```dart
      final r = loadRubric('content/cs3660/2026/rubrics/$slug.yaml');
```

In `test/quizzes_test.dart` line 19:

```dart
      final q = loadQuiz('content/cs3660/2026/quizzes/w06-eips-part1.yaml');
```

In `test/quizzes_test.dart` lines 56 and 128 (both occurrences):

```dart
      final c = loadCourse('content/cs3660/2026');
```

- [ ] **Step 5: Confirm no other references remain**

```bash
grep -rn "content/2026" . --exclude-dir=.git --exclude-dir=dist || echo "CLEAN"
```

Expected: `CLEAN`. If anything prints, fix it before continuing.

- [ ] **Step 6: Run tests to verify they pass**

```bash
dart test 2>&1 | tail -5
```

Expected: PASS, with the same count recorded in Step 1.

- [ ] **Step 7: Verify the Canvas build still produces a zip**

```bash
dart run bin/build_canvas_zip.dart content/cs3660/2026 /tmp/cs3660-verify.imscc
unzip -l /tmp/cs3660-verify.imscc | tail -3
```

Expected: the zip is written and lists `imsmanifest.xml` among its entries.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "refactor(content): move CS 3660 under content/cs3660/2026

bin/build_canvas_zip.dart takes the content dir as an argument, so only
the four hardcoded test paths needed updating. Makes room for CS 3540
without sharing a directory."
```

---

### Task 2: Teach the fivex rubric bundler to walk every course

**Files:**
- Create: `/Users/michael/code/fivex/mod_node/scripts/refresh-rubrics.mjs`
- Create: `/Users/michael/code/fivex/mod_node/modules/git-grader/tests/unit/refresh-rubrics.test.ts`
- Modify: `/Users/michael/code/fivex/mod_node/package.json:73` (the `prebuild:rubrics` script)

**Interfaces:**
- Consumes: content root layout from Task 1.
- Produces: `npm run prebuild:rubrics` copying from `content/*/*/rubrics`, exiting non-zero on a
  filename collision. Task 3 relies on this to bundle a `cs3540-` rubric.

- [ ] **Step 1: Record the current green baseline**

```bash
cd /Users/michael/code/fivex/mod_node
npm run prebuild:rubrics
ls modules/git-grader/rubrics/*.yaml | wc -l
```

Expected: `rubrics refreshed`, and a count of 12 (CS 3660's rubric set). Record the count.

- [ ] **Step 2: Write the failing test**

Create `/Users/michael/code/fivex/mod_node/modules/git-grader/tests/unit/refresh-rubrics.test.ts`:

```ts
import { execFileSync } from 'child_process';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

const repoRoot = path.join(__dirname, '../../../..');
const script = path.join(repoRoot, 'scripts/refresh-rubrics.mjs');

const RUBRIC = (slug: string) =>
  `slug: ${slug}\ncriteria:\n  - slug: c\n    ratings:\n      - description: ok\n        points: 1\n`;

function fixture(layout: Record<string, string>): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'rubric-src-'));
  for (const [rel, body] of Object.entries(layout)) {
    const full = path.join(root, rel);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, body);
  }
  return root;
}

const tmpDest = () => fs.mkdtempSync(path.join(os.tmpdir(), 'rubric-dst-'));

describe('refresh-rubrics', () => {
  it('copies rubrics from every content/<course>/<year> directory', () => {
    const src = fixture({
      'cs3540/2026/rubrics/cs3540-pass-fail.yaml': RUBRIC('cs3540-pass-fail'),
      'cs3660/2026/rubrics/pass-fail.yaml': RUBRIC('pass-fail'),
    });
    const dst = tmpDest();

    execFileSync('node', [script], {
      cwd: repoRoot,
      env: { ...process.env, COURSE_BUILDER_CONTENT: src, RUBRIC_DEST: dst },
    });

    expect(fs.readdirSync(dst).sort()).toEqual([
      'cs3540-pass-fail.yaml',
      'pass-fail.yaml',
    ]);
  });

  it('exits non-zero when two courses ship the same rubric filename', () => {
    const src = fixture({
      'cs3540/2026/rubrics/pass-fail.yaml': RUBRIC('pass-fail'),
      'cs3660/2026/rubrics/pass-fail.yaml': RUBRIC('pass-fail'),
    });
    const dst = tmpDest();

    expect(() =>
      execFileSync('node', [script], {
        cwd: repoRoot,
        env: { ...process.env, COURSE_BUILDER_CONTENT: src, RUBRIC_DEST: dst },
        stdio: 'pipe',
      }),
    ).toThrow();
  });

  it('skips silently when the content root is absent', () => {
    const dst = tmpDest();
    const out = execFileSync('node', [script], {
      cwd: repoRoot,
      env: { ...process.env, COURSE_BUILDER_CONTENT: '/nonexistent/content', RUBRIC_DEST: dst },
    }).toString();

    expect(out).toContain('skipping rubric refresh');
    expect(fs.readdirSync(dst)).toEqual([]);
  });
});
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd /Users/michael/code/fivex/mod_node
npx jest modules/git-grader/tests/unit/refresh-rubrics.test.ts
```

Expected: all three FAIL — `scripts/refresh-rubrics.mjs` does not exist yet.

- [ ] **Step 4: Write the bundler script**

Create `/Users/michael/code/fivex/mod_node/scripts/refresh-rubrics.mjs`:

```js
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.env.COURSE_BUILDER_CONTENT
  ?? '/Users/michael/code/uvu/tools/course_builder/content';
const DST = process.env.RUBRIC_DEST ?? 'modules/git-grader/rubrics';

if (!fs.existsSync(ROOT)) {
  console.warn('course_builder not present — skipping rubric refresh');
  process.exit(0);
}

const seen = new Map();
let copied = 0;

for (const course of fs.readdirSync(ROOT).sort()) {
  const courseDir = path.join(ROOT, course);
  if (!fs.statSync(courseDir).isDirectory()) continue;

  for (const year of fs.readdirSync(courseDir).sort()) {
    const rubricsDir = path.join(courseDir, year, 'rubrics');
    if (!fs.existsSync(rubricsDir)) continue;

    for (const file of fs.readdirSync(rubricsDir).sort()) {
      if (!file.endsWith('.yaml')) continue;
      const origin = `${course}/${year}`;

      if (seen.has(file)) {
        console.error(
          `FATAL: rubric filename collision: ${file} appears in ` +
          `${seen.get(file)} and ${origin}. The grader keys rubrics by filename ` +
          `in a flat directory, so slugs must be globally unique across courses.`);
        process.exit(1);
      }

      seen.set(file, origin);
      fs.copyFileSync(path.join(rubricsDir, file), path.join(DST, file));
      copied++;
    }
  }
}

const origins = [...new Set(seen.values())].sort().join(', ');
console.log(`rubrics refreshed: ${copied} file(s) from ${origins || 'nothing'}`);
```

- [ ] **Step 5: Point package.json at the script**

Replace the `prebuild:rubrics` value on line 73 of
`/Users/michael/code/fivex/mod_node/package.json` with:

```json
    "prebuild:rubrics": "node scripts/refresh-rubrics.mjs",
```

Leave `"prebuild": "npm run prebuild:rubrics"` on line 74 unchanged.

- [ ] **Step 6: Run the test to verify it passes**

```bash
cd /Users/michael/code/fivex/mod_node
npx jest modules/git-grader/tests/unit/refresh-rubrics.test.ts
```

Expected: all three PASS. The second test is the collision guard firing — a guard you have not
watched fire is not done.

- [ ] **Step 7: Verify the real bundle reproduces the baseline**

```bash
cd /Users/michael/code/fivex/mod_node
npm run prebuild:rubrics
ls modules/git-grader/rubrics/*.yaml | wc -l
```

Expected: `rubrics refreshed: 12 file(s) from cs3660/2026`, and the same count recorded in Step 1.

- [ ] **Step 8: Verify the existing grader tests still pass**

```bash
npx jest modules/git-grader/tests/unit
```

Expected: PASS, including the pre-existing `rubric.service.test.ts`.

- [ ] **Step 9: Commit**

```bash
cd /Users/michael/code/fivex/mod_node
git add scripts/refresh-rubrics.mjs package.json modules/git-grader/tests/unit/refresh-rubrics.test.ts
git commit -m "feat(git-grader): bundle rubrics from every course directory

Walks content/<course>/<year>/rubrics instead of a single hardcoded
path, and fails loudly on filename collisions — the grader keys rubrics
by filename in a flat directory, so slugs must be globally unique."
```

---

### Task 3: Prove the pipeline end-to-end with a CS 3540 rubric

**Files:**
- Create: `content/cs3540/2026/rubrics/cs3540-pass-fail.yaml`
- Create: `content/cs3540/2026/course.yaml`
- Create: `content/cs3540/2026/pages/.gitkeep`, `onboarding/.gitkeep`, `cheatsheets/.gitkeep`,
  `lectures/.gitkeep`

**Interfaces:**
- Consumes: the content layout from Task 1, the bundler from Task 2.
- Produces: a CS 3540 content root that `loadCourse()` accepts, and the slug `cs3540-pass-fail`
  resolvable by `RubricService.load()`. Every later CS 3540 rubric follows this file's shape.

- [ ] **Step 1: Write the failing test**

Append to `test/cc_rubrics_validation_test.dart` (course_builder), inside the existing top-level
`main()`:

```dart
  group('cs3540 rubrics', () {
    test('cs3540-pass-fail parses and its slug matches its filename', () {
      final r = loadRubric('content/cs3540/2026/rubrics/cs3540-pass-fail.yaml');
      expect(r.slug, 'cs3540-pass-fail');
      expect(r.criteria, isNotEmpty);
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/michael/code/uvu/tools/course_builder
dart test test/cc_rubrics_validation_test.dart 2>&1 | tail -10
```

Expected: FAIL — path does not exist.

- [ ] **Step 3: Create the CS 3540 content skeleton**

```bash
cd /Users/michael/code/uvu/tools/course_builder
mkdir -p content/cs3540/2026/{rubrics,pages,onboarding,cheatsheets,lectures}
touch content/cs3540/2026/{pages,onboarding,cheatsheets,lectures}/.gitkeep
```

- [ ] **Step 4: Write the rubric**

Create `content/cs3540/2026/rubrics/cs3540-pass-fail.yaml`:

```yaml
slug: cs3540-pass-fail
title: Pass/Fail
criteria:
  - slug: complete
    description: Submission satisfies the assignment's stated acceptance criteria.
    ratings:
      - description: Submitted as instructed; criteria met.
        points: 1
      - description: Missing or does not meet criteria.
        points: 0
```

- [ ] **Step 5: Write the minimal course.yaml**

Create `content/cs3540/2026/course.yaml`:

```yaml
title: "CS 3540 001 | 2026 Fall - Game Programming"
course_code: "CS 3540 001 | 2026 Fall"
start_at: "2026-08-19T00:00:00"
end_at: "2026-12-11T23:59:59"
front_page: syllabus
grading_scheme: letter

late_policy:
  daily_deduction_percent: 10
  floor_percent: 50

assignment_groups:
  - slug: onboarding
    title: Onboarding (Week 1)
    weight: 5

rubrics:
  - rubrics/cs3540-pass-fail.yaml

pages: []
assignments: []
```

> `pages` and `assignments` are empty on purpose. This task proves the *pipeline*; the course
> shell is built in a later plan. An empty list is a real value, not a placeholder.

- [ ] **Step 6: Run the test to verify it passes**

```bash
dart test test/cc_rubrics_validation_test.dart 2>&1 | tail -5
```

Expected: PASS.

- [ ] **Step 7: Verify the full course_builder suite is still green**

```bash
dart test 2>&1 | tail -5
```

Expected: PASS, one test more than Task 1 Step 6.

- [ ] **Step 8: Verify the bundler now picks up both courses**

```bash
cd /Users/michael/code/fivex/mod_node
npm run prebuild:rubrics
```

Expected: `rubrics refreshed: 13 file(s) from cs3540/2026, cs3660/2026`.

- [ ] **Step 9: Verify the grader resolves the new slug**

```bash
cd /Users/michael/code/fivex/mod_node
node -e "const {RubricService}=require('./dist/modules/git-grader/services/rubric.service');" 2>/dev/null || true
npx jest modules/git-grader/tests/unit
```

Expected: PASS. Then confirm the slug resolves directly:

```bash
npx ts-node -e "import {RubricService} from './modules/git-grader/services/rubric.service'; \
  const r = new RubricService('modules/git-grader/rubrics').load('cs3540-pass-fail'); \
  console.log('resolved:', r.slug, r.criteria.length, 'criterion(s)');"
```

Expected: `resolved: cs3540-pass-fail 1 criterion(s)`. If `ts-node` is unavailable, the jest run
above is sufficient evidence.

- [ ] **Step 10: Commit both repos**

```bash
cd /Users/michael/code/uvu/tools/course_builder
git add content/cs3540 test/cc_rubrics_validation_test.dart
git commit -m "feat(cs3540): content skeleton and first rubric

Proves the content/<course>/<year> pipeline end-to-end: course_builder
loads it, the fivex bundler copies it, RubricService resolves the slug."

cd /Users/michael/code/fivex/mod_node
git add modules/git-grader/rubrics/cs3540-pass-fail.yaml
git commit -m "chore(git-grader): bundle cs3540-pass-fail"
```

---

### Task 4: Record the coupling so the next person does not break it

**Files:**
- Modify: `/Users/michael/code/uvu/CLAUDE.md` (the `tools/course_builder` row of the Tools table)
- Modify: `/Users/michael/code/uvu/tools/course_builder/CLAUDE.md`

**Interfaces:**
- Consumes: the behavior established in Tasks 1–3.
- Produces: documentation only. No code depends on this task.

- [ ] **Step 1: Update the workspace CLAUDE.md**

In `/Users/michael/code/uvu/CLAUDE.md`, the Tools table currently says rubrics are authored in
`tools/course_builder/content/<year>/rubrics/` and warns that moving that dir requires updating
fivex's `prebuild:rubrics` path. Replace that sentence with:

```
Dart CLI generating the Canvas `.imscc` course shell from YAML+Markdown under
`content/<course>/<year>/`; also the rubric source for the 2h2.us grader. fivex's
`prebuild:rubrics` (`mod_node/scripts/refresh-rubrics.mjs`) walks every
`content/*/*/rubrics` and copies into the grader's **flat** rubric directory — so
**rubric slugs must be globally unique across all courses** and every filename must
match its `slug:` field. CS 3540 slugs are prefixed `cs3540-`. Remote: `uvucs3660/summer_2026`.
```

- [ ] **Step 2: Update the course_builder CLAUDE.md**

Add this section to `/Users/michael/code/uvu/tools/course_builder/CLAUDE.md`:

```markdown
## Content layout

One directory per course per year: `content/<course>/<year>/`.

`bin/build_canvas_zip.dart <content-dir> <output-file>` takes the directory as an
argument — there is no hardcoded year. Tests do hardcode paths; grep for
`content/cs` before moving anything.

### Rubric slugs are globally unique

The 2h2.us grader's `RubricService.load(slug)` reads `${slug}.yaml` from one flat
directory and throws if the file's `slug:` field differs from the filename stem.
fivex's bundler copies every course's rubrics into that flat directory and **exits
non-zero on a filename collision**. Prefix per course: CS 3540 uses `cs3540-`.
```

- [ ] **Step 3: Verify the documented commands actually work**

```bash
cd /Users/michael/code/uvu/tools/course_builder
grep -rn "content/cs" test/ | wc -l
dart run bin/build_canvas_zip.dart content/cs3540/2026 /tmp/cs3540-verify.imscc && echo BUILD_OK
```

Expected: a non-zero grep count, and `BUILD_OK`.

- [ ] **Step 4: Commit**

```bash
cd /Users/michael/code/uvu/tools/course_builder
git add CLAUDE.md
git commit -m "docs: record the content layout and global rubric slug namespace"
```

> The workspace root `/Users/michael/code/uvu` is **not** a git repository and must never become
> one. Its `CLAUDE.md` edit from Step 1 is saved but not committed anywhere. This is expected.

---

## Definition of done

- [ ] `dart test` passes in `course_builder` with one more test than the Task 1 baseline.
- [ ] `npm run prebuild:rubrics` reports 13 files from both course namespaces.
- [ ] The collision guard has been observed exiting 1.
- [ ] `npx jest modules/git-grader/tests/unit` passes, including the three new refresh-rubrics tests.
- [ ] `grep -rn "content/2026" tools/course_builder` returns nothing.
- [ ] Both CLAUDE.md files describe the flat-namespace constraint.

## Not in this plan

Deploying to 2h2.us. `./deploy.sh` from fivex is a human-run step, and until it runs the
production grader still has the old rubric set. Run it before any CS 3540 grading is attempted,
then confirm with a `render-prompt` call against `cs3540-pass-fail`.
