---
slug: lecture-w10-minds
week: 10
youtube_id: null
companion_sheets:
  - cheatsheet-pathfinding-and-navigation
  - cheatsheet-game-ai-behavior
  - cheatsheet-difficulty-and-flow
reflection_assignment: devlog-w10
vernacular_tags:
  - "A* · admissible heuristic · string-pulling"
  - "steering behaviors"
  - "FSM · behavior tree · utility AI"
  - "telegraphing · perception layer"
---

# Week 10 — Minds: Pathfinding and Game AI

## What you'll know after this

After this lecture you will be able to (a) implement A\* with a deterministic tie-break, (b) explain why an overestimating heuristic silently returns wrong paths, (c) choose the right rung of the AI ladder, and (d) explain why a smarter opponent is usually a worse one.

## Outline

1. **A\* is Dijkstra plus a guess** *(10 min)*
   `f = g + h`. Expand the lowest `f` first. The guess is what stops you exploring in every direction, and it must **never overestimate** — otherwise A\* confidently returns a path that is not shortest and never tells you. Manhattan on a 4-grid, octile on an 8-grid; Euclidean is always safe and sometimes slower.

2. **The tie-break is not optional** *(8 min)*
   Two cells with equal `f` and no specified order means two implementations return different, equally short paths — and diverge. Break by id in the heap comparator. Fourth appearance of this bug class this term, in a fourth subsystem.

3. **Then smooth it** *(6 min)*
   Raw grid paths zig-zag along cell boundaries. String-pulling — remove every waypoint you can see past — is the difference between units that walk and units that solve a maze.

4. **Path for the route, steering for the last two metres** *(6 min)*
   Pathfinding does not stop ten units occupying one tile. A separation force does.

5. **The ladder** *(12 min)*
   Steering → state machine → behavior tree → utility. Climb only when the rung you are on actually breaks. Most enemies should live on the second rung permanently; a twelve-state FSM is where you consider the third.

6. **The trap** *(10 min)*
   **Smarter is not better.** An optimal opponent is frustrating and illegible. Players enjoy an enemy whose pattern they can learn and beat — Koster, applied to AI. Most "our AI is too dumb" complaints are really "our AI is not readable."

7. **Perception and telegraphing** *(6 min)*
   An AI reading full world state feels like a cheater because it is one. Sight radius, reaction delay, rate-limited updates. And every dangerous action needs a wind-up — without one, losing is noise.

## Discuss in class

- **Repathing every tick** is the most common performance failure in student RTS projects. When *should* you repath?
- **Think of an enemy you enjoyed fighting.** What was its pattern, how long did it take to learn, and what happened after you had?
- **Reaction delay makes an AI feel like it noticed you.** What else could you add that costs nothing and buys legibility?

## Further reading

- [Amit Patel's A\* pages](https://theory.stanford.edu/~amitp/GameProgramming/) — interactive, definitive
- [Steering Behaviors](https://www.red3d.com/cwr/steer/), Reynolds
- `spec/S12-pathfinding.md` and `spec/S13-game-ai.md`
