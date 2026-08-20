---
slug: lecture-w07-contact
week: 7
youtube_id: null
companion_sheets:
  - cheatsheet-collision-and-spatial-partition
  - cheatsheet-performance-profiling
  - cheatsheet-cc-mcp
reflection_assignment: devlog-w07
vernacular_tags:
  - "AABB · broadphase · narrowphase"
  - "Spatial Partition"
  - "frame budget"
  - "Claude Code: MCP · blast radius"
---

# Week 7 — Contact: Collision, Budgets, and Profiling

## What you'll know after this

After this lecture you will be able to (a) explain why a spatial partition is not "optimize later," (b) implement AABB overlap and grid broadphase, (c) read a flame chart, and (d) evaluate an MCP server's blast radius before installing it.

## Outline

1. **The number that decides it** *(8 min)*
   100 bodies is 4,950 pairs. 5,000 bodies is **12,497,500**. The class budget is 5,000 at 60fps, and a naive double loop **passes every correctness test** while failing that budget. This is the one optimization you write before profiling, and the budget exists precisely to force it.

2. **AABB, and a choice you must state** *(6 min)*
   Four comparisons. But strict versus non-strict inequality decides whether touching edges count as overlapping — a real choice, equally defensible either way, and two builds will differ on it if you do not say which.

3. **The grid** *(12 min)*
   Bucket by cell, check only bodies sharing one. Two details matter: a body larger than a cell lands in several, so **dedupe pairs** or you apply the impulse twice and things launch. And cell size should be about your average body size.

4. **Resolution order is specification** *(8 min)*
   Separate along the axis of least penetration. But resolving pairs in a different order produces a different final state — so sort by `(minId, maxId)` before resolving, or two correct implementations diverge after any pile-up.

5. **Measure, do not guess** *(10 min)*
   You will guess wrong; everyone does. `performance.mark` puts your own timings next to the browser's. The order of suspicion: O(n²), then allocation in the loop, then draw calls, then layout thrash. A memory sawtooth means garbage.

6. **MCP and blast radius** *(10 min)*
   The only pillar that reaches outside the sandbox — and a server runs **with your privileges**. The question is never "is this trustworthy" but "what is in its tool list." `query_readonly` cannot drop a table; `execute_sql` can. Read the list before you install.

## Discuss in class

- **Bring a flame chart of your game.** Widest bar wins. Was it where you expected?
- **Your budget test.** Write one this week: 5,000 bodies, 60 iterations, assert the mean. What does it feel like to have a test that fails for being slow rather than wrong?
- **Prompt injection through MCP.** A server returns a GitHub issue body containing instructions. What in your setup stops that from being followed?

## Further reading

- `spec/S11-collision.md` — the specification and its performance budget
- [Spatial Partition](https://gameprogrammingpatterns.com/spatial-partition.html), Nystrom
- [modelcontextprotocol.io](https://modelcontextprotocol.io)
