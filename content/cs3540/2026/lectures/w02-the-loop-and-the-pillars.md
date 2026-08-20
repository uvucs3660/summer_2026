---
slug: lecture-w02-loop-and-pillars
week: 2
youtube_id: null
companion_sheets:
  - cheatsheet-game-loop-and-time
  - cheatsheet-cc-claude-md
  - cheatsheet-cc-skills
reflection_assignment: devlog-w02
vernacular_tags:
  - "Game Loop"
  - "Update Method"
  - "fixed timestep · accumulator · interpolation alpha"
  - "Claude Code: CLAUDE.md"
  - "Claude Code: skill"
  - "progressive disclosure"
---

# Week 2 — The Loop and the 11 Pillars

## What you'll know after this

After this lecture you will be able to (a) explain why using frame time as your timestep makes a game unshippable, (b) write a fixed-timestep accumulator with a spiral-of-death clamp, (c) say what belongs in CLAUDE.md and what does not, and (d) explain progressive disclosure and why a skill's description is the entire game.

## Outline

1. **The bug in the obvious loop** *(10 min)*
   `player.x += vx * dt` looks correct and is not. On a 144Hz monitor `dt` is 7ms; on a struggling laptop it is 33. Same code, different game — jumps reach different heights and fast bodies tunnel through walls. Every one of replay, multiplayer, and conformance testing dies here, because the simulation now depends on hardware.

2. **The accumulator** *(12 min)*
   Separate *when the simulation advances* from *when you draw*. Add elapsed time to an accumulator; while it holds a full step, tick and subtract. `tick()` takes **no time argument** — that is the point. What is left over is the interpolation alpha, which goes to the renderer and never comes back. See `cheatsheet-game-loop-and-time`.

3. **The spiral of death, and why clamping is correct** *(6 min)*
   A stalled tab hands you 8,000ms. Without a clamp you run 160 ticks, which takes longer than a frame, which makes the next frame worse. Dropping simulated time is correct behavior; falling permanently behind is not.

4. **Why 20Hz** *(4 min)*
   The class engine steps at 50ms. Not because it looks better — because lockstep multiplayer sends twenty command batches per second instead of sixty. A rendering decision made for a networking reason, three months early.

5. **The 11 Pillars, and the axis through them** *(12 min)*
   Four groups: Context, Capability, Control, Communication. The recurring question is **what is always in context versus what loads on demand**. `CLAUDE.md` and skill *descriptions* are paid for on every turn, forever; skill *bodies* and subagent work are not. Almost every "where does this belong?" decision reduces to that.

6. **CLAUDE.md — the contractor briefing** *(8 min)*
   Build and test commands, architecture in three sentences, invariants that are easy to violate, do-not-do rules **with reasons**. Not a tutorial, not a workflow, not a copy of the README. Generate with `/init`, then delete most of it.

7. **Skills, and why yours will not fire** *(8 min)*
   Claude picks a skill by reading descriptions and nothing else. "Helps with PRs" never fires; naming the phrases a user actually types does. Write the description **first** — if you cannot state the trigger, you do not yet know what the skill is for.

## Discuss in class

- **Where did your one-prompt game hide its timestep?** Open the build from Assignment 1 and find the loop. Did it use a fixed step? If not, what would break first?
- **What is in your CLAUDE.md that should be a skill?** Bring the file. We will cut it live.
- **Is 20Hz a rendering decision or a networking decision?** It was made for a constraint that does not arrive until Week 13. What else in your design should be decided that early — and what should not be?

## Further reading

- [Fix Your Timestep!](https://gafferongames.com/post/fix_your_timestep/), Glenn Fiedler — the canonical article
- `spec/S01-time-and-loop.md` — the class specification, with its conformance vector
- `cheatsheet-cc-the-11-pillars` — the map, if you have not read it yet
