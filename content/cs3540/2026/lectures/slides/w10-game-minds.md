---
track: game
week: 10
title: Minds
subtitle: A*, the Ladder, and Why Smarter Opponents Are Worse
runtime: 22
---

NOTES:
Week ten, game track. Act three — the studio.

Two halves today. The first is pathfinding, which is mechanical and has one trap you have now met three times. The second is game AI, which is not a technical problem at all — it is a design problem wearing a technical costume, and getting it wrong makes your game worse in a way no profiler will show you.

---

# What you'll know after this

- Why A\* is Dijkstra plus a guess — and what the guess must never do
- The **tie-break**, for the fourth time this term
- The **ladder**: steering → state machine → behavior tree → utility
- Why an optimal opponent is a **bad** opponent

NOTES:
Four things. The last one is the one people argue with, and I want you to argue with it, because the argument is where it lands.

---

# A\* is Dijkstra plus a guess

`f = g + h` — expand the lowest `f` first.

- `g` — cost from the start. **Known.**
- `h` — estimated cost to the goal. **The guess.**

The guess is what stops you exploring in every direction.

> `h` must **never overestimate.** If it can, A\* confidently returns a path that is not shortest — and never tells you.

NOTES:
The whole algorithm is one formula.

Dijkstra explores outward in every direction equally, because it has no idea where the goal is. A\* adds a guess about the remaining distance, and expands whichever cell looks most promising by total estimated cost. That guess is the entire difference, and it is what turns a flood fill into something that goes roughly toward the goal.

Now the constraint, which is the part that matters. The heuristic must never overestimate the true remaining cost. If it can overestimate, A\* will confidently return a path that is not the shortest, and it will not tell you — it has no mechanism to notice. You get plausible paths that are quietly wrong.

Manhattan on a four-directional grid. Octile on an eight-directional grid. Euclidean is always safe, and sometimes slower because it underestimates more than it needs to. When in doubt, Euclidean — a slow correct answer beats a fast wrong one you cannot detect.

---

# The tie-break, again

![](pathfinding-and-navigation-tie-break.svg)

NOTES:
And here it is for the fourth time.

Two open cells with the same `f`. Which do you expand first? If your spec does not say, the answer is whatever your heap happened to do, which depends on insertion order, which depends on nothing.

Both builds return a shortest path. Both are correct. They are *different* shortest paths, so the units walk different routes, so they end up in different places, so the hash diverges.

Let me put the four together, because the pattern is the lesson now. Week three: iteration order in the hash. Week five: the component store, where that order comes from. Week six: draw order ties causing flicker. Week ten: heap ties in A-star.

Four subsystems, one defect: an order that nothing specified. And every single time the fix is the same three words — break by id.

If you own a section and you have not audited it for this, that is your afternoon this week.

---

# Then smooth it, then steer

**String-pulling** — remove every waypoint you can see past. The difference between units that walk and units that solve a maze.

**Path for the route, steering for the last two metres.** Pathfinding does not stop ten units occupying one tile. A separation force does.

NOTES:
Two quick additions that turn a working pathfinder into something that looks right.

Raw grid paths zig-zag along cell boundaries, because the grid only allows certain directions. Nobody walks like that. String-pulling fixes it: walk the path, and whenever you can see from waypoint A directly to waypoint C, delete B. A staircase becomes a straight line.

And separate the two jobs. The path is the route — the sequence of places to head toward. Steering is the last two metres: avoiding the other units, arriving smoothly, not vibrating against a wall. Pathfinding will happily route ten units to the same tile, because as far as it is concerned that tile is reachable. A separation force is what stops them stacking.

---

# The ladder

**Steering** → **State machine** → **Behavior tree** → **Utility**

Climb only when the rung you are on **actually breaks.**

- Most enemies should live on **state machine** permanently
- A twelve-state FSM is when you consider a behavior tree
- Utility is for economies and strategy AI, not for a goomba

NOTES:
Four rungs, in increasing order of power and of cost.

Steering is forces — seek, flee, separate. A few lines of vector maths, and it is enough for flocks, swarms, and anything that does not make decisions.

State machines are where the vast majority of enemies should live, forever. Idle, chase, attack, flee. Readable, debuggable, and — crucially — you can look at one and know what it will do.

Behavior trees are for when your state machine has twelve states and the transitions have become a hairball. They are composable and reusable, and they cost you legibility.

Utility is scoring every option and picking the best. It is for strategy AI and economies, where there genuinely are many competing considerations.

The instruction is the middle line. Climb when the current rung actually breaks, not when it feels unsophisticated. A state machine that works is not a failure of ambition.

---

# Smarter is not better

![](game-ai-behavior-readable.svg)

NOTES:
Now the part people argue with.

You can write an opponent that always makes the best move. In most games, that is not hard — it is often easier than writing a good one, because "optimal" is well-defined and "fun" is not.

And it is miserable to play against. Not because it is too hard. Because there is no pattern in it. Koster from week one: fun is the feeling of your brain successfully learning a pattern. An optimal opponent has no pattern — it has only correctness — so there is nothing to learn, and losing to it carries no information.

The right-hand column is what you actually want. A sight radius, so it does not know where you are through a wall. A reaction delay, so there is a moment to exploit. And a wind-up before anything dangerous, so the player can see it coming and losing feels like a lesson instead of noise.

An AI reading full world state feels like a cheater because it *is* one — it has information the player cannot get.

Read the bottom line, because it is the practical version. When a playtester says your AI is too dumb, walk it down the MDA ladder from two weeks ago. Almost always the dynamic is "I could not tell what it was about to do," and the mechanic is a missing telegraph — not intelligence at all.

---

# Before Thursday

- **Audit your section for tie-breaks.** Every ordering. This is the fourth time.
- Add a **wind-up** to your most dangerous enemy action. Then playtest it.
- Which **rung** is your AI on? Is it there because it broke, or because it felt basic?
- `cheatsheet-pathfinding-and-navigation`, `cheatsheet-game-ai-behavior`

Thursday, AI: **Spec → Plan → Execution.** Forge 06 due **Sun Nov 2.** Scope contract due **Oct 26.**

NOTES:
Three things.

Audit for tie-breaks. I keep saying it and it keeps being the answer.

Add the wind-up and playtest it — you should be able to feel the difference immediately, and so should whoever is playing.

And the third is the honest question about your AI. Most people find they climbed a rung because the lower one felt unsophisticated, not because it stopped working. That is a real cost: you now maintain a behavior tree for an enemy that walks toward you.

Two deadlines. The scope contract is due October twenty-sixth — that is where you commit to what actually ships, and it is graded on completeness against what you declared, so declaring less is a valid strategy. Forge 06 is November second.
