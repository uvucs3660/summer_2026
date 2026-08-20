---
slug: lecture-w01-first-contact
week: 1
youtube_id: null
companion_sheets:
  - cheatsheet-theory-of-fun
  - cheatsheet-cc-the-11-pillars
  - cheatsheet-git-collaboration
reflection_assignment: devlog-w01
vernacular_tags:
  - "Theory of Fun: pattern learning"
  - "Theory of Fun: the boredom/noise bracket"
  - "Claude Code: the 11 Pillars"
  - "Specification: the second-language test"
---

# Week 1 — First Contact · What a Game Costs Now

## What you'll know after this

After this lecture you will be able to (a) state the measured claim this course is built on and the evidence behind it, (b) explain why specification and verification replaced implementation as the scarce skill, (c) describe the three tracks and what each one measures, and (d) name Koster's definition of fun and the two ways a game stops being fun.

## Outline

1. **A complete game is one prompt away** *(8 min)*
   Two full Age-of-Empires-style 3D real-time strategy games — one in Dart with Flutter GPU, one in TypeScript with three.js — each produced from a single prompt plus six answered questions. Pathfinding, an adaptive AI opponent, four ages of units, deployed and tested. Roughly 4,000 lines each. This is not a prediction; it is a measurement, and you will reproduce it in the next two weeks.

2. **The two builds agreed with each other** *(7 min)*
   The interesting result is not that either worked. It is that they **converged on the same architecture** independently: a pure simulation, a renderer that reads it, a UI layer, and a thin wiring layer. Two languages, two rendering stacks, one decomposition. That convergence is evidence the boundary is real rather than stylistic — and it is the boundary this whole course is organized around.

3. **So what is left to learn?** *(10 min)*
   Not typing an A\* implementation. The scarce skill is **specifying a system precisely enough that what comes back is correct, and knowing how to tell whether it is.** Everything in this course follows from taking that seriously: you will write a specification that agents build from, and where independent builds disagree, your prose was ambiguous.

4. **Three tracks** *(8 min)*
   **Play** — history, fun, story, mystery; why a thing is worth playing. **Craft** — 2D, 3D, procedural generation, game AI, networking; the machine underneath. **Soul** — the 11 Pillars, the archetypes, the AI SDLC; how the work gets made. They converge on the game, which carries 42% of your grade.

5. **Koster's claim** *(10 min)*
   Fun is the feeling of your brain successfully learning a pattern. Three consequences: every mechanic has a **shelf life** — when the pattern is learned, the reward stops; **noise is not difficulty** — if the pattern cannot be found, it is not hard, it is unfair; and the curve must track **rising skill**, so constant difficulty slides into boredom on its own. See `cheatsheet-theory-of-fun`.

6. **Why we build the engine instead of using one** *(7 min)*
   Unity's job is to make sure you never think about a fixed-timestep accumulator, a broadphase, or snapshot interpolation. The course catalog requires exactly those. A course taught in a mature engine ends up teaching *around* the tool. So we build one — small, in the browser, entirely readable.

7. **What's due this week** *(5 min)*
   Five onboarding assignments. **Assignment 1 — your GitHub username — is due Friday** and gates everything else: your portfolio repo, your spec repo access, and your grading webhook. Git training and Claude Pro proof are due Sunday. The Ollama key and your first pull request follow next week.

## Discuss in class

- **Where does the one-prompt claim break?** You will test it directly in Assignment 1. Before you do: predict what it will fail at. Write the prediction down, then compare. The gap between your prediction and the result is worth more than either alone.
- **Constraint as identity.** Space Invaders' escalating difficulty was a CPU running out of headroom. Silent Hill's fog was a draw-distance limit. Your constraints this term are a small local model, an unpublished free-tier quota, and no server. Which game do those make possible that a bigger budget would not?
- **Is Koster too strong?** He claims games are *nothing but* pattern learning. What does that fail to explain about a game you love?

## Further reading

- **A Theory of Fun for Game Design**, Raph Koster, 10th Anniversary Edition — an evening, half of it pictures
- [Game Programming Patterns](https://gameprogrammingpatterns.com/), Robert Nystrom — free online, the vocabulary for the Craft track
- `cheatsheet-cc-the-11-pillars` — the map for the Soul track, and the index to eight more sheets
