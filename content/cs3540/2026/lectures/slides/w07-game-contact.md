---
track: game
week: 7
title: Contact
subtitle: Pair Explosion, the Grid, and Measuring Instead of Guessing
runtime: 22
---

NOTES:
Week seven, game track.

I asked you on Tuesday to guess how many pairs there are among five thousand bodies. Hold your number. We open with it.

---

# What you'll know after this

- Why the naive loop **passes every test** and still fails
- The one **AABB choice** you must state in prose
- The grid, and the two details that bite — **dedupe** and **cell size**
- Why **resolution order** is specification, and how to measure instead of guess

NOTES:
Four things. Two of them are pinned choices — you should be counting these by now; this is weeks three, five, six and now seven, and the same class of defect every time.

---

# The number

![](collision-and-spatial-partition-pair-explosion.svg)

NOTES:
Here is your answer. Twelve million, four hundred and ninety-seven thousand, five hundred.

If you guessed in the millions, well done. Most people say something like fifty thousand, because the jump from a hundred bodies to five thousand feels like fifty times more work. It is not fifty times. It is two and a half thousand times, because pairs grow as the square.

Now read the line at the bottom, because it is the interesting part pedagogically. A naive double loop is *correct*. It finds every collision. It passes every unit test you would write, including the tricky ones. There is no bug in it.

It just does twelve and a half million comparisons per frame against a budget of sixteen milliseconds, and no amount of correctness testing will ever tell you that.

This is the one optimisation you write before profiling — the only one I will ever tell you to do that with. Everywhere else, measure first. Here the maths is the measurement.

---

# The choice inside four comparisons

![](collision-and-spatial-partition-aabb.svg)

NOTES:
An axis-aligned bounding box test is four comparisons. It is the simplest thing in the engine and it still contains an unpinned decision.

Two boxes whose edges are exactly equal. Does that count as a collision?

With strict inequality, no — they are touching, not overlapping. With non-strict, yes. Both are defensible. Neither is a bug.

And exact equality is not a rare floating-point curiosity here, because we quantize. Bodies snap to thousandths, they rest against walls, they stack. Edges land exactly equal constantly.

So if your section says "the boxes overlap" without saying which inequality, two builds will differ on every resting contact in the game. That is the kind of divergence that shows up as a pile of crates that is stable in one build and slowly vibrating in the other.

---

# The grid

Bucket by cell. Check only bodies sharing a cell.

Two details that will bite you:

- A body **larger than a cell** lands in several — **dedupe the pairs**, or you apply the impulse twice and things launch
- **Cell size ≈ average body size.** Too small and you pay for buckets; too large and you are back to the double loop with extra steps

NOTES:
The fix is spatial partitioning, and a uniform grid is the one to write first — a quadtree is more elegant and, for the body counts in your games, usually slower.

Bucket every body by which cell it is in. To find collisions, only check bodies that share a cell. Twelve million comparisons becomes a few thousand.

Two details. First, a body bigger than one cell occupies several, so the same pair can be generated more than once. If you resolve both, you apply the separation impulse twice, and things launch across the level. That bug looks like physics going insane and is actually an arithmetic bug in your broadphase.

Second, cell size. About your average body size. Too small and you spend all your time managing buckets that hold one thing. Too large and every body is in the same cell — which is the naive double loop with extra bookkeeping and worse cache behavior.

---

# Resolution order is specification

Separate along the axis of **least penetration.** Fine.

But resolving pairs in a different **order** produces a different final state.

```js
pairs.sort((a, b) => a.minId - b.minId || a.maxId - b.maxId);
```

Two correct implementations diverge after any pile-up unless you sort.

NOTES:
And here is the fifth pinned choice of the term.

Resolving a collision means pushing bodies apart along the axis of least penetration. That part is uncontroversial.

But real games have pile-ups. Three crates in a corner, each touching the others. Resolve A-against-B first and B moves, which changes the penetration depth of B-against-C, which changes where C ends up. Resolve them in the other order and you get a different final arrangement.

Neither is wrong. But they are different, and the difference goes into the hash.

Sort the pairs before resolving — by lower id, then higher id. Same tie-break we have used for queries and for draw order, and by now I hope it is reflex.

---

# Measure, do not guess

You will guess wrong. **Everyone does.**

`performance.mark` puts your timings next to the browser's.

The order of suspicion:

1. **O(n²)** hiding somewhere
2. **Allocation inside the loop** — a memory sawtooth means garbage
3. **Draw calls** — see last week
4. **Layout thrash** — reading a DOM measurement after writing

NOTES:
Last piece, and it is a habit rather than a technique.

You will guess wrong about performance. I still guess wrong, and I have been doing this a long time. The intuition that serves you well for correctness is actively misleading for speed, because the expensive thing is usually not the complicated thing.

So measure. `performance.mark` and `performance.measure` put your own timings in the same timeline as the browser's, which means you can see your simulation next to layout and paint rather than guessing which one is the problem.

The list is my order of suspicion, roughly by how often each turns out to be the answer. Quadratic behavior first, always. Then allocation in the hot loop — if your memory graph is a sawtooth, you are producing garbage every frame and the collector is the cost. Then draw calls. Then layout thrash, which is a DOM problem rather than a game problem but will absolutely eat your frame.

And notice the discipline is the same one from Thursday's hooks lecture and from skills before it: write down what you expect, then check. The gap between guess and measurement is the entire value.

---

# Before Thursday

- **What did you guess** for 5,000 bodies? Bring the number, honestly.
- Find the **O(n²)** in your own game. There is one.
- Profile one frame with `performance.mark` before you change anything
- Read `spec/S11`, `cheatsheet-collision-and-spatial-partition`, `cheatsheet-performance-profiling`

Thursday, AI: **MCP and blast radius** — the only pillar that reaches outside the sandbox.

NOTES:
Bring your guess. I am genuinely interested in the spread, and being wrong in public about a number is a cheap way to remember it.

Find your quadratic. Every one of your games has one somewhere — collision if you have collision, or a nested search over entities, or something that scans all of them to find the nearest.

And profile before you change anything, so you have a baseline to compare against. Optimising without a before-number is just rearranging code and hoping.

Thursday is MCP, and it is the one part of this system that can reach out of the sandbox and touch things you care about.
