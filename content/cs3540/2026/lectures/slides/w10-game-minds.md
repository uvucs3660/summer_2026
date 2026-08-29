---
track: game
week: 10
title: Minds
subtitle: A*, the Ladder, and Why Smarter Opponents Are Worse
runtime: 22
---

NOTES:
Week ten, game track. Act three — the studio.

Two halves today, and they are unlike each other.

The first is pathfinding. It is mechanical. There is a formula, there is one constraint on the formula, and there is one trap you have now met three times in three different subsystems and will meet again in about four minutes.

The second half is game AI, and I want to set your expectations before we get there. It is not a technical problem. It is a design problem wearing a technical costume. Everything that makes an opponent feel intelligent is something a person deliberately engineered — a radius, a delay, an animation that plays before the damage lands. None of it emerges. And getting it wrong makes your game worse in a way no profiler will ever show you, because nothing is slow and nothing has crashed. It simply is not fun, and fun does not appear in a flame graph.

---

# What you'll know after this

- Why A\* is Dijkstra plus a guess — and what the guess must never do
- The **tie-break**, for the fourth time this term
- The **ladder**: steering → state machine → behavior tree → utility
- Why an optimal opponent is a **bad** opponent

NOTES:
Four things. The last one is the one people argue with, and I want you to argue with it, because the argument is where it lands. Nobody believes that a worse opponent makes a better game until they have lost that argument themselves.

---

# A\* is Dijkstra plus a guess

`f = g + h` — expand the lowest `f` first.

- `g` — cost from the start. **Known.**
- `h` — estimated cost to the goal. **The guess.**

The guess is what stops you exploring in every direction.

> `h` must **never overestimate.** If it can, A\* confidently returns a path that is not shortest — and never tells you.

NOTES:
The whole algorithm is one formula.

Dijkstra explores outward in every direction equally, because it has no idea where the goal is. A star adds a guess about the distance remaining and expands whichever cell looks most promising by total estimated cost. That guess is what turns a flood fill into a search that actually heads toward the goal.

Now the constraint, which is the part that matters. The heuristic must never overestimate the true remaining cost. If it can overestimate, A star will confidently return a path that is not the shortest, and it will not tell you, because it has no mechanism to notice. What you get is plausible paths that are quietly wrong, and quietly wrong is the worst category of wrong to ship.

So make the choice concrete. Manhattan on a four-directional grid. Octile on an eight-directional grid. Euclidean is always safe, and sometimes slower, because it underestimates by more than it strictly needs to. When in doubt, Euclidean. A slow correct answer beats a fast wrong one you cannot detect.

---

# The tie-break, again

![](pathfinding-and-navigation-tie-break.svg)

NOTES:
And here it is for the fourth time.

Two open cells with the same f value. Which one do you expand first? If your spec does not say, the answer is whatever your heap happened to do, which depends on insertion order, which depends on nothing.

Both builds return a shortest path. Both are correct. They are different shortest paths, so the units walk different routes, so they finish in different places, so the hash diverges on a run where nothing was actually wrong.

Let me put the four together, because the pattern is the lesson now. Week three: iteration order in the hash. Week five: the component store, which is where that order came from. Week six: draw order ties causing flicker. Week ten: heap ties in A-star.

Four subsystems, one defect: an order that nothing specified. And every single time the fix is the same three words — break by id.

If you own a section and you have not audited it for this, that is your afternoon this week. Find every place your code chooses between two things that compare equal, and write down what decides.

---

# Then smooth it, then steer

**String-pulling** — remove every waypoint you can see past. The difference between units that walk and units that solve a maze.

**Path for the route, steering for the last two metres.** Pathfinding does not stop ten units occupying one tile. A separation force does.

NOTES:
Two quick additions that turn a working pathfinder into something that looks right.

Raw grid paths zig-zag along cell boundaries, because the grid only permits certain directions. Nobody walks like that. Nothing that has ever been alive walks like that. String-pulling fixes it, and it is a few lines: walk the path, and whenever you can see from waypoint A directly to waypoint C, delete B. A staircase collapses into a straight line.

Then separate the two jobs, because they are two jobs. The path is the route — the sequence of places to head toward. Steering is the last two metres: avoiding the other units, arriving smoothly, not vibrating against a wall. Pathfinding will happily route ten units onto the same tile, because as far as it is concerned that tile is reachable, and reachable is the only question it was asked. A separation force is the thing that stops them stacking into one shimmering pile.

---

# The ladder

**Steering** → **State machine** → **Behavior tree** → **Utility**

Climb only when the rung you are on **actually breaks.**

- Most enemies should live on **state machine** permanently
- A twelve-state FSM is when you consider a behavior tree
- Utility is for economies and strategy AI, not for a goomba

NOTES:
Four rungs, in increasing order of power and of cost.

Steering is forces. Seek, flee, separate. A few lines of vector arithmetic, and it is enough for flocks, swarms, and anything that does not make decisions.

State machines are where the vast majority of enemies should live, permanently. Idle, chase, attack, flee. Readable, debuggable, and — this is the property that matters — you can look at one and know what it will do before you run it.

Behavior trees are for when your state machine has twelve states and the transitions have become a hairball. They are composable and reusable, and they cost you legibility. That is a trade, not an upgrade.

Utility is scoring every available option and taking the highest. It belongs to strategy AI and economies, where there genuinely are many competing considerations to weigh.

The instruction is the middle line. Climb when the rung you are standing on actually breaks, not when it starts to feel unsophisticated. A state machine that works is not a failure of ambition.

---

# Smarter is not better

![](game-ai-behavior-readable.svg)

NOTES:
Now the part people argue with.

You can write an opponent that always makes the best available move. In most games that is not hard — it is often easier than writing a good one, because optimal is well-defined and fun is not.

And it is miserable to play against. Not because it is too hard. Because there is no pattern in it. Koster from week one: fun is the feeling of your brain successfully learning a pattern. An optimal opponent has no pattern, only correctness. Nothing to learn, and losing to it carries no information.

The right-hand column is what you actually want, and every item on it is a number a person types in. A sight radius, so it does not know where you are through a wall. A reaction delay, so there is a window to exploit. A wind-up before anything dangerous, so the player can see it coming and losing feels like a lesson instead of noise. None of that is the AI becoming smart. It is three deliberate imperfections, measured in metres and in milliseconds. An AI reading full world state feels like a cheater because it is one — it holds information the player has no way to get.

Read the bottom line, because it is the practical version. When a playtester says your AI is too dumb, walk it down the MDA ladder from two weeks ago. Almost always the dynamic is that they could not tell what it was about to do, and the mechanic is a missing telegraph. Not intelligence at all. An animation.

---

# Before Thursday

- **Audit your section for tie-breaks.** Every ordering. This is the fourth time.
- Add a **wind-up** to your most dangerous enemy action. Then playtest it.
- Which **rung** is your AI on? Is it there because it broke, or because it felt basic?
- `cheatsheet-pathfinding-and-navigation`, `cheatsheet-game-ai-behavior`

Thursday, AI: **Spec → Plan → Execution.** Forge 06 due **Sun Nov 2.** Scope contract due **Oct 26.**

NOTES:
Three things.

Audit for tie-breaks. I keep saying it and it keeps being the answer. Every ordering, every place two things compare equal.

Add the wind-up to your most dangerous enemy action and then playtest it. You should feel the difference immediately, and so should whoever is holding the controller, and neither of you should need a frame counter to see it.

And the third is the honest question about your own AI. Which rung is it on, and why is it there? Most people find they climbed because the lower rung felt unsophisticated, not because it stopped working. That is a real cost and you pay it every week: you now maintain a behavior tree for an enemy whose entire job is to walk toward you.

Two deadlines. The scope contract is due October twenty-sixth. That is where you commit to what actually ships, and it is graded on completeness against what you declared, so declaring less is a valid strategy. Forge 06 is November second.
