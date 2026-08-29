---
track: game
week: 7
title: Contact
subtitle: Pair Explosion, the Grid, and Measuring Instead of Guessing
runtime: 22
---

NOTES:
Week seven, game track.

On Tuesday I asked you to guess how many pairs there are among five thousand bodies. Hold your number. Do not quietly revise it now that you have had two days to feel uneasy about it. We open with it.

And I will tell you the shape of the hour up front, because it is unusual. Every failure we have looked at so far has been a bug. Today the code is correct. It is correct and it is unplayable. Correct and unplayable is a category most of you have never had to think about, and it is the whole lecture.
---

# What you'll know after this

- Why the naive loop **passes every test** and still fails
- The one **AABB choice** you must state in prose
- The grid, and the two details that bite — **dedupe** and **cell size**
- Why **resolution order** is specification, and how to measure instead of guess

NOTES:
Four things. Two of them are pinned choices, and you should be counting these by now — weeks three, five, six, and now seven, the same class of defect every time. Not a bug. A sentence that permitted two answers.
---

# The number

![](collision-and-spatial-partition-pair-explosion.svg)

NOTES:
Here is your answer. Twelve million, four hundred and ninety-seven thousand, five hundred.

If you guessed in the millions, well done. Most people say something like fifty thousand, and that is not carelessness. It is the arithmetic your intuition actually performs. A hundred bodies to five thousand bodies is fifty times more bodies, so it feels like fifty times more work. It is not fifty times. Pairs grow as the square, so fifty times the bodies is two and a half thousand times the pairs.

Now read the line at the bottom, because that is the interesting part pedagogically. A naive double loop is correct. It finds every collision. It passes every unit test you would write, including the tricky ones you are proud of. There is no bug in it.

It just does twelve and a half million comparisons per frame against a budget of sixteen milliseconds. No amount of correctness testing will ever tell you that. Your suite is green and your game is a slideshow, and those two facts have no way of reaching each other.

This is the one optimisation you write before profiling. The only one I will ever tell you to do that with. Everywhere else, measure first. Here the maths is the measurement.
---

# The choice inside four comparisons

![](collision-and-spatial-partition-aabb.svg)

NOTES:
An axis-aligned bounding box test is four comparisons. It is the simplest thing in the entire engine, and it still contains a decision nobody has pinned.

Two boxes whose edges are exactly equal. Does that count as a collision?

With strict inequality, no — they are touching, not overlapping. With non-strict, yes. Both are defensible. Neither is a bug.

And exact equality is not a rare floating-point curiosity here, because we quantize. Bodies snap to thousandths. They rest against walls. They stack. Edges land exactly equal constantly, and in a platformer they land exactly equal on almost every frame, because the player is standing on something.

So if your section says the boxes overlap and never says which inequality, two builds will differ on every resting contact in the game. That is the kind of divergence that shows up as a pile of crates that sits still in one build and hums quietly in the other.
---

# The grid

Bucket by cell. Check only bodies sharing a cell.

Two details that will bite you:

- A body **larger than a cell** lands in several — **dedupe the pairs**, or you apply the impulse twice and things launch
- **Cell size ≈ average body size.** Too small and you pay for buckets; too large and you are back to the double loop with extra steps

NOTES:
The fix is spatial partitioning, and a uniform grid is the one to write first. A quadtree is more elegant and, at the body counts in your games, usually slower.

Bucket every body by which cell it sits in. To find collisions, only check bodies that share a cell. Twelve million comparisons becomes a few thousand.

Two details, and both of them will bite you.

First, a body bigger than one cell occupies several cells, so the same pair gets generated more than once. If you resolve both copies, you apply the separation impulse twice and things launch across the level. That one is worth naming carefully because of how it presents. It looks like your physics has lost its mind. It is an arithmetic mistake in your broadphase, and you will spend an evening in the wrong file.

Second, cell size. Roughly the size of your average body. Too small and you spend all your time managing buckets that hold one thing each. Too large and every body lands in the same cell, which is the naive double loop with extra bookkeeping and worse cache behaviour.
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

Resolving a collision means pushing the two bodies apart along the axis of least penetration. That part is uncontroversial.

But real games have pile-ups. Three crates in a corner, each one touching the other two. Resolve A against B first and B moves, which changes the penetration depth of B against C, which changes where C ends up. Resolve the same three in the other order and you get a different final arrangement.

Neither arrangement is wrong. But they are different, and the difference goes into the hash, and the hash is the thing the divergence report reads.

So sort the pairs before you resolve them. Lower id, then higher id. Same tie-break as queries, same tie-break as draw order, and by week seven I would like it to be reflex rather than something you look up.
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

You will guess wrong about performance. I still guess wrong, and I have been doing this a long time. The intuition that serves you well for correctness is actively misleading for speed, because the expensive thing is almost never the complicated thing. The complicated thing runs once. The boring thing runs eight hundred thousand times.

So measure. Performance dot mark and performance dot measure put your own timings into the same timeline as the browser's, which means you can see your simulation sitting next to layout and paint instead of guessing which of the three is eating the frame.

The list is my order of suspicion, roughly by how often each one turns out to be the answer. Quadratic behaviour first, always. Then allocation in the hot loop — if your memory graph is a sawtooth, you are producing garbage every frame and the collector is the bill. Then draw calls, which was last week. Then layout thrash, which is a DOM problem rather than a game problem and will eat your frame anyway.

And notice the discipline is the same one from Thursday's hooks lecture and from skills before it. Write down what you expect, then check. The gap between the guess and the measurement is the entire value.
---

# Before Thursday

- **What did you guess** for 5,000 bodies? Bring the number, honestly.
- Find the **O(n²)** in your own game. There is one.
- Profile one frame with `performance.mark` before you change anything
- Read `spec/S11`, `cheatsheet-collision-and-spatial-partition`, `cheatsheet-performance-profiling`

Thursday, AI: **MCP and blast radius** — the only pillar that reaches outside the sandbox.

NOTES:
Bring your guess. I am genuinely interested in the spread, and being wrong out loud about a number is a cheap way to remember the number for good.

Find your quadratic. Every one of your games has one. Collision, if you have collision. Or a nested search over entities. Or something that walks the whole list to find the nearest thing. It is in there and it is patient.

Profile one frame before you change anything, so that you have a before-number. Optimising without a before-number is not optimising. It is rearranging code and hoping, and hoping does not show up on a flame graph.

Thursday is MCP, and it is the one part of this system that can reach out of the sandbox and touch things you actually care about.
