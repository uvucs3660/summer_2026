# CS 3540 Engine Spec Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The instructor-owned core of the class engine spec — sections `S00`–`S03`, the
conformance vector format, a runner that executes vectors against any implementation, and a
TypeScript state hash proven bit-identical to the Dart original in `~/code/3dscroller`.

**Architecture:** A new TypeScript package at `cs3540-content/engine-spec/`. The state hash is
ported from `lib/sim/world.dart`, which already uses 32-bit FNV-1a with a `Math.imul` emulation
specifically so Dart VM and JS agree. The conformance runner is the artifact everything else in
the course measures against, so it is built test-first.

**Tech Stack:** TypeScript 5, `vitest`, Node 20+. Zero runtime dependencies — dev dependencies only.

**Spec:** `docs/superpowers/specs/2026-08-19-cs3540-2026-fall-design.md` (§3 Engine spec, §4 Generator)

## Global Constraints

- **Zero runtime dependencies.** `dependencies` in `package.json` stays empty. Students must be
  able to read every line that runs.
- **The state hash must be bit-identical to Dart's.** Reference: `~/code/3dscroller/lib/sim/world.dart`,
  `_fnv1a` / `_mul32` / `stateHash`. Constants: offset basis `0x811c9dc5`, prime `0x01000193`.
- **Rounding is specified, never inherited.** Dart `.round()` rounds half away from zero; JS
  `Math.round()` rounds half toward `+∞`. They disagree at `-0.5`. Every quantizer in the spec
  states **round half away from zero** and implements it explicitly.
- **Quantization before hashing**: positions ×1000, health ×10, resources ×10 — matching Dart.
- **The simulation must not know that rendering exists.** Enforced by a purity gate, ported from
  `test/sim/purity_test.dart`.
- Repo lives at `/Users/michael/code/uvu/cs3540-content/engine-spec/`. `cs3540-content` is a git
  repo on `main`; publishing to `uvucs3540/engine-spec` is Plan 4's problem.
- Never `git push`.

---

### Task 1: The state hash, proven against Dart

**Files:**
- Create: `engine-spec/package.json`, `engine-spec/tsconfig.json`, `engine-spec/vitest.config.ts`
- Create: `engine-spec/src/hash.ts`
- Create: `engine-spec/test/hash.test.ts`
- Create: `engine-spec/test/fixtures/dart-hashes.json`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `fnv1a(hash: number, value: number): number` — one FNV-1a step over `value`'s 32-bit
    representation, low byte first.
  - `FNV_OFFSET_BASIS: number` — `0x811c9dc5`.
  - `roundHalfAwayFromZero(x: number): number`
  - `quantize(x: number, scale: number): number` — `roundHalfAwayFromZero(x * scale)`
  - `hashInts(values: number[]): number` — fold from the offset basis.
  Tasks 2 and 3 import `hashInts` and `quantize`.

- [ ] **Step 1: Generate the Dart oracle**

Run against the real Dart implementation so the fixture is evidence, not a guess:

```bash
cd ~/code/3dscroller
cat > /tmp/gen_hashes.dart <<'DART'
const int _fnvOffsetBasis = 0x811c9dc5;
const int _fnvPrime = 0x01000193;
const int _fnv32Mask = 0xFFFFFFFF;

int _mul32(int a, int b) {
  final aLo = a & 0xffff;
  final aHi = (a >> 16) & 0xffff;
  return ((aLo * b) + (((aHi * b) & 0xffff) << 16)) & _fnv32Mask;
}

int _fnv1a(int hash, int value) {
  final bytes = value.toUnsigned(32);
  var h = hash;
  for (var shift = 0; shift < 32; shift += 8) {
    final byte = (bytes >> shift) & 0xFF;
    h = (h ^ byte) & _fnv32Mask;
    h = _mul32(h, _fnvPrime);
  }
  return h;
}

void main() {
  final cases = <List<int>>[
    [],
    [0],
    [1],
    [-1],
    [42, 7, 0, 1],
    [2147483647, -2147483648],
    [1000, 2000, 30, 4],
  ];
  final out = <String>[];
  for (final c in cases) {
    var h = _fnvOffsetBasis;
    for (final v in c) { h = _fnv1a(h, v); }
    out.add('{"input": ${c.toString()}, "hash": $h}');
  }
  print('[${out.join(",")}]');

  final rounds = <double>[0.5, -0.5, 1.5, -1.5, 2.5, -2.5, 0.4999, -0.4999];
  print('[${rounds.map((d) => '{"x": $d, "round": ${d.round()}}').join(",")}]');
}
DART
dart /tmp/gen_hashes.dart
```

Save the first array to `engine-spec/test/fixtures/dart-hashes.json` and record the second
array's values — they pin the rounding-mode difference the TS port must reproduce.

- [ ] **Step 2: Scaffold the package**

```bash
mkdir -p /Users/michael/code/uvu/cs3540-content/engine-spec/{src,test/fixtures}
cd /Users/michael/code/uvu/cs3540-content/engine-spec
```

`package.json`:

```json
{
  "name": "@uvucs3540/engine-spec",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "description": "CS 3540 class engine specification, conformance vectors, and runner",
  "scripts": {
    "test": "vitest run",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {},
  "devDependencies": {
    "typescript": "^5.6.0",
    "vitest": "^2.1.0"
  }
}
```

`tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "types": ["vitest/globals"]
  },
  "include": ["src", "test"]
}
```

`vitest.config.ts`:

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: { globals: true, include: ['test/**/*.test.ts'] },
});
```

Then `npm install`.

- [ ] **Step 3: Write the failing test**

`test/hash.test.ts`:

```ts
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  FNV_OFFSET_BASIS,
  fnv1a,
  hashInts,
  quantize,
  roundHalfAwayFromZero,
} from '../src/hash.js';

type Oracle = { input: number[]; hash: number };

const oracle: Oracle[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./fixtures/dart-hashes.json', import.meta.url)), 'utf8'),
);

describe('roundHalfAwayFromZero', () => {
  // Math.round(-0.5) === -0 in JS but (-0.5).round() === -1 in Dart.
  // The quantizer is the whole basis of cross-language hash agreement, so
  // the rounding mode is specified rather than inherited.
  it.each([
    [0.5, 1],
    [-0.5, -1],
    [1.5, 2],
    [-1.5, -2],
    [2.5, 3],
    [-2.5, -3],
    [0.4999, 0],
    [-0.4999, -0],
  ])('rounds %p to %p', (input, expected) => {
    expect(roundHalfAwayFromZero(input)).toBe(expected);
  });

  it('differs from Math.round exactly where Dart does', () => {
    expect(Math.round(-0.5)).toBe(-0);
    expect(roundHalfAwayFromZero(-0.5)).toBe(-1);
  });
});

describe('quantize', () => {
  it('scales then rounds half away from zero', () => {
    expect(quantize(1.2345, 1000)).toBe(1235);
    expect(quantize(-1.2345, 1000)).toBe(-1235);
    expect(quantize(-0.0005, 1000)).toBe(-1);
    expect(quantize(9.95, 10)).toBe(100);
  });
});

describe('fnv1a', () => {
  it('starts from the FNV-1a 32-bit offset basis', () => {
    expect(FNV_OFFSET_BASIS).toBe(0x811c9dc5);
  });

  it('stays inside 32 bits for every step', () => {
    let h = FNV_OFFSET_BASIS;
    for (const v of [0, -1, 2147483647, -2147483648, 123456]) {
      h = fnv1a(h, v);
      expect(Number.isInteger(h)).toBe(true);
      expect(h).toBeGreaterThanOrEqual(0);
      expect(h).toBeLessThanOrEqual(0xffffffff);
    }
  });

  it('is order-sensitive', () => {
    expect(hashInts([1, 2])).not.toBe(hashInts([2, 1]));
  });
});

describe('cross-language agreement with the Dart implementation', () => {
  it('reproduces every hash the Dart oracle produced', () => {
    expect(oracle.length).toBeGreaterThan(0);
    for (const c of oracle) {
      expect(hashInts(c.input)).toBe(c.hash);
    }
  });
});
```

- [ ] **Step 4: Run the test to verify it fails**

```bash
cd /Users/michael/code/uvu/cs3540-content/engine-spec
npx vitest run
```

Expected: FAIL — `src/hash.ts` does not exist.

- [ ] **Step 5: Write the implementation**

`src/hash.ts`:

```ts
/**
 * 32-bit FNV-1a, ported from 3dscroller's `lib/sim/world.dart`.
 *
 * 32-bit rather than 64-bit on purpose: a JS number represents integers
 * exactly only to 2^53, and a 64-bit FNV's per-step `hash * prime` overflows
 * that. Every intermediate value here stays inside 32 bits, so the result is
 * bit-identical across Dart VM, dart2js, and Node.
 *
 * `Math.imul` is the native form of the 16-bit-halves emulation Dart's
 * `_mul32` performs by hand — a bare `(a * b) >>> 0` is NOT equivalent,
 * because the untruncated product can exceed 2^53 and round before the mask.
 */
export const FNV_OFFSET_BASIS = 0x811c9dc5;
export const FNV_PRIME = 0x01000193;

export function fnv1a(hash: number, value: number): number {
  const bytes = value >>> 0;
  let h = hash >>> 0;
  for (let shift = 0; shift < 32; shift += 8) {
    const byte = (bytes >>> shift) & 0xff;
    h = (h ^ byte) >>> 0;
    h = Math.imul(h, FNV_PRIME) >>> 0;
  }
  return h;
}

export function hashInts(values: readonly number[]): number {
  let h = FNV_OFFSET_BASIS;
  for (const v of values) h = fnv1a(h, v);
  return h;
}

/**
 * Round half away from zero — Dart's `num.round()`, NOT JavaScript's
 * `Math.round()`. They disagree on negative halves: `Math.round(-0.5)` is
 * `-0`, while Dart's `(-0.5).round()` is `-1`.
 */
export function roundHalfAwayFromZero(x: number): number {
  return x < 0 ? -Math.round(-x) : Math.round(x);
}

/** Scale then quantize. Positions use 1000; health and resources use 10. */
export function quantize(x: number, scale: number): number {
  return roundHalfAwayFromZero(x * scale);
}
```

- [ ] **Step 6: Run the test to verify it passes**

```bash
npx vitest run && npx tsc --noEmit
```

Expected: all tests PASS, typecheck clean.

- [ ] **Step 7: Commit**

```bash
cd /Users/michael/code/uvu/cs3540-content
git add engine-spec
git commit -m "feat(engine-spec): state hash proven bit-identical to the Dart original

32-bit FNV-1a ported from 3dscroller's world.dart. Rounding is specified
as half-away-from-zero rather than inherited from Math.round, which
disagrees with Dart at negative halves — and the quantizer is the whole
basis of cross-language hash agreement."
```

---

### Task 2: Conformance vector format

**Files:**
- Create: `engine-spec/src/vector.ts`
- Create: `engine-spec/test/vector.test.ts`
- Create: `engine-spec/conformance/vectors/S01/fixed-timestep-accumulator.json`

**Interfaces:**
- Consumes: `quantize`, `hashInts` from Task 1.
- Produces:
  - `type Vector = { id, section, title, seed, commands: Command[], ticks: number, expect: { stateHash: number } }`
  - `type Command = { tick: number; kind: string; args: Record<string, number | string> }`
  - `parseVector(json: unknown): Vector` — throws with the offending field on malformed input.
  Task 3 imports both.

- [ ] **Step 1: Write the failing test**

`test/vector.test.ts`:

```ts
import { parseVector } from '../src/vector.js';

const valid = {
  id: 'S01/fixed-timestep-accumulator',
  section: 'S01',
  title: 'A 250ms frame at 20Hz advances exactly 5 ticks',
  seed: 12345,
  commands: [{ tick: 0, kind: 'noop', args: {} }],
  ticks: 5,
  expect: { stateHash: 2166136261 },
};

describe('parseVector', () => {
  it('accepts a well-formed vector', () => {
    const v = parseVector(valid);
    expect(v.section).toBe('S01');
    expect(v.commands).toHaveLength(1);
  });

  it.each([
    ['id', { ...valid, id: undefined }],
    ['section', { ...valid, section: undefined }],
    ['seed', { ...valid, seed: 'not-a-number' }],
    ['ticks', { ...valid, ticks: -1 }],
    ['expect.stateHash', { ...valid, expect: {} }],
  ])('rejects a vector with a bad %s, naming the field', (field, bad) => {
    expect(() => parseVector(bad)).toThrow(new RegExp(field.split('.')[0]));
  });

  it('rejects a state hash outside 32 bits', () => {
    expect(() => parseVector({ ...valid, expect: { stateHash: 2 ** 32 } })).toThrow(/32/);
  });

  it('rejects commands that are not sorted by tick', () => {
    expect(() =>
      parseVector({
        ...valid,
        commands: [
          { tick: 3, kind: 'noop', args: {} },
          { tick: 1, kind: 'noop', args: {} },
        ],
      }),
    ).toThrow(/sorted/);
  });
});
```

- [ ] **Step 2: Run to verify it fails**

```bash
npx vitest run test/vector.test.ts
```

Expected: FAIL — `src/vector.ts` does not exist.

- [ ] **Step 3: Implement `src/vector.ts`**

Write a hand-rolled validator (no dependency). It must:
- Require `id`, `section`, `title` as non-empty strings; `seed` and `ticks` as non-negative
  integers; `expect.stateHash` as an integer in `[0, 0xffffffff]`.
- Require `commands` to be an array, each with an integer `tick >= 0`, a non-empty `kind`, and an
  `args` object whose values are numbers or strings.
- Require `commands` sorted by non-decreasing `tick`, throwing a message containing `sorted`.
- Throw `Error` messages that name the offending field.

- [ ] **Step 4: Write the first real vector**

`conformance/vectors/S01/fixed-timestep-accumulator.json` — a vector asserting that a 250ms frame
at a 50ms fixed step advances exactly 5 ticks and leaves 0ms in the accumulator. Its `stateHash`
is filled in once Task 3's runner can produce one; until then it is a **known-failing vector**,
which is the correct state for a spec whose implementation does not exist yet.

- [ ] **Step 5: Run to verify it passes, then commit**

```bash
npx vitest run && npx tsc --noEmit
cd /Users/michael/code/uvu/cs3540-content
git add engine-spec && git commit -m "feat(engine-spec): conformance vector format and validator"
```

---

### Task 3: The conformance runner

**Files:**
- Create: `engine-spec/src/runner.ts`
- Create: `engine-spec/test/runner.test.ts`

**Interfaces:**
- Consumes: `Vector`, `parseVector` (Task 2); `hashInts` (Task 1).
- Produces:
  - `type Engine = { reset(seed: number): void; apply(c: Command): void; tick(): void; stateHash(): number }`
  - `runVector(engine: Engine, v: Vector): { pass: boolean; actual: number; expected: number }`
  - `runAll(engine: Engine, vectors: Vector[]): { passed: number; failed: string[] }`

- [ ] **Step 1: Write the failing test**

`test/runner.test.ts` — build two in-test fake engines, both trivially implementing `Engine`:
a **correct** one that hashes seed plus applied commands plus tick count, and a **wrong** one that
ignores commands. Assert that `runVector` passes the first and fails the second, that `runAll`
names the failing vector ids, and that commands are applied at their declared tick and not before.

> Two fakes, not one. A runner tested only against a correct engine cannot prove it detects
> failure, and detecting failure is its entire job.

- [ ] **Step 2: Run to verify it fails**

```bash
npx vitest run test/runner.test.ts
```

Expected: FAIL — `src/runner.ts` does not exist.

- [ ] **Step 3: Implement `src/runner.ts`**

`runVector` resets the engine with the vector's seed, then for each tick from 0 to `v.ticks - 1`
applies every command whose `tick` equals the current tick, then calls `tick()`. Afterwards it
compares `engine.stateHash()` to `v.expect.stateHash`.

- [ ] **Step 4: Run to verify it passes, then commit**

```bash
npx vitest run && npx tsc --noEmit
cd /Users/michael/code/uvu/cs3540-content
git add engine-spec && git commit -m "feat(engine-spec): conformance runner"
```

---

### Task 4: Spec sections S00–S03 and ownership

**Files:**
- Create: `engine-spec/spec/S00-overview.md`
- Create: `engine-spec/spec/S01-time-and-loop.md`
- Create: `engine-spec/spec/S02-determinism.md`
- Create: `engine-spec/spec/S03-command-model.md`
- Create: `engine-spec/spec/OWNERS.md`
- Create: `engine-spec/README.md`

**Interfaces:**
- Consumes: the vector format from Task 2 (S00 documents it).
- Produces: `spec/OWNERS.md`, which onboarding assignment 5 tells students to read.

- [ ] **Step 1: S00 — Overview**

Must contain: the guiding rule (*the simulation must not know that rendering exists*); the three
seams (`Renderer`, `Transport`, `Generator`); the conformance vector format with a worked example;
**the rounding mode, stated explicitly**; the quantization scales; and the rule that every section
must be implementable in a second language.

- [ ] **Step 2: S01 — Time and the fixed-timestep loop**

Fixed step at 50ms (20Hz), accumulator, interpolation alpha for rendering. Invariant: a given
elapsed-time sequence produces exactly one tick count, independent of frame pacing.

- [ ] **Step 3: S02 — Determinism**

Seeded PRNG (mulberry32, as in `ts_game/src/sim/rng.ts`), the world-state hash, quantize-before-hash,
and the requirement that identical seed plus identical command sequence yields an identical hash.

- [ ] **Step 4: S03 — Command model**

Commands as the single seam through which *anything* nondeterministic enters the simulation —
player input, remote peers, and LLM output alike. Append-only log, sorted by tick, replayable.

- [ ] **Step 5: OWNERS.md**

A table of every section, its owner, and its status. `S00`–`S03` are instructor-owned. `S04`–`S18`
are listed as `UNASSIGNED` pending enrollment, with a note that assignment happens in Week 2.

- [ ] **Step 6: Verify and commit**

```bash
npx vitest run && npx tsc --noEmit
ls engine-spec/spec/*.md | wc -l   # expect 5
cd /Users/michael/code/uvu/cs3540-content
git add engine-spec && git commit -m "docs(engine-spec): sections S00-S03 and ownership table"
```

---

## Definition of done

- [ ] `npx vitest run` passes in `engine-spec`.
- [ ] `npx tsc --noEmit` is clean.
- [ ] Every hash in `test/fixtures/dart-hashes.json` was produced by running real Dart, and the
      TypeScript port reproduces all of them.
- [ ] `roundHalfAwayFromZero(-0.5) === -1` and the test asserts it differs from `Math.round`.
- [ ] The runner is proven to *fail* a wrong engine, not merely pass a correct one.
- [x] `package.json` declares zero runtime dependencies — asserted by `test/constraints.test.ts`, since npm strips an empty `dependencies` object on install.
- [ ] `spec/OWNERS.md` exists — onboarding assignment 5 points at it.

## Not in this plan

The 15 student-owned sections `S04`–`S18` (authored by students in Week 2), the generator and cron
(Plan 6), publishing to `uvucs3540/engine-spec` (Plan 4), and the TypeScript purity gate — which
needs a `src/sim` tree to police and therefore waits until sections exist.
