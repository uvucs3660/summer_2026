---
track: game
week: 1
title: First Contact
subtitle: What a Game Costs Now, and What Is Left to Learn
runtime: 20
---

NOTES:
Welcome to CS 3540.

I want to open with a measurement rather than a claim, because the measurement is the reason this course is shaped the way it is — and it is not the shape a game programming course had five years ago.

---

# What you'll know after this

- What a complete game **actually costs** to produce right now
- Why **two independent builds converging** is the interesting result
- What the scarce skill is, if it is no longer typing an algorithm
- Koster's claim about fun, and its three consequences

NOTES:
Four things. The second is the one that changed my mind about how to teach this.

---

# A complete game is one prompt away

Two full **Age-of-Empires-style 3D real-time strategy games.**

- One in **Dart** with Flutter GPU. One in **TypeScript** with three.js.
- Each from **a single prompt plus six answered questions.**
- Pathfinding, an adaptive AI opponent, four ages of units, deployed and tested.
- Roughly **4,000 lines** each.

This is not a prediction. It is a measurement — and you will reproduce it in two weeks.

NOTES:
Here is the measurement.

Two real-time strategy games, in the Age of Empires mould. One written in Dart against Flutter GPU, one in TypeScript against three.js. Each produced from a single prompt plus six answered clarifying questions.

Not toys. Pathfinding, an AI opponent that adapts, four ages of unit progression, deployed and playable and tested. About four thousand lines each.

I want to be precise about what that does and does not mean. It does not mean the games were finished products — they were not. It means the distance from nothing to a playable 3D RTS is now roughly one well-formed prompt, and that distance used to be a semester.

And you will reproduce this yourself in two weeks, in the one-prompt game assignment. I am not asking you to take it on faith.

---

# The interesting part is that they agreed

![](history-of-games-two-builds-converged.svg)

NOTES:
But here is the result that actually matters, and it is not that either build worked.

They converged on the same architecture. Independently. Two different languages, two completely different rendering stacks, no shared code, and both arrived at the same four layers: a pure simulation, a renderer that reads it, a UI layer, and a thin wiring layer between them.

Read the line at the bottom, because it is the load-bearing claim of this entire course. That convergence is evidence the boundary is real rather than stylistic. It is not a taste I am imposing on you. Two independent processes found the same seam, which is the kind of evidence you get in physics and almost never in software architecture.

That boundary — simulation on one side, everything else on the other — is what the next fourteen weeks are organised around. In week four it becomes a rule in the specification. In week thirteen it becomes a process boundary you cannot cross even if you want to.

---

# So what is left to learn?

Not typing an A\* implementation.

> The scarce skill is **specifying a system precisely enough that what comes back is correct** — and knowing how to tell whether it is.

Everything in this course follows from taking that seriously:

- You will write a **specification that agents build from**
- Where independent builds **disagree**, your prose was ambiguous
- That is measurable, and it is how your section is graded

NOTES:
So if the code is cheap, what is the course?

It is the sentence in the quote, and it has two halves that are equally important.

Specifying precisely enough that what comes back is correct. And — the half people forget — knowing how to tell whether it is. A specification you cannot check is a wish.

Which is why this course does something unusual. The class writes one engine specification together. Each of you owns sections of it. A scheduled agent builds that specification independently, several times, and compares the results.

Where independent builds disagree, your prose was ambiguous. Not wrong — ambiguous. And the disagreement points at a specific section with a specific owner.

That is the central idea, and I will repeat it all term: a specification's quality is measurable, and the measurement is whether it produces the same thing twice.

---

# Three tracks

**Play** — history, fun, story, mystery. Why a thing is worth playing at all.

**Craft** — 2D, 3D, procedural generation, game AI, networking. The machine underneath.

**Soul** — the 11 Pillars, the archetypes, the AI SDLC. How the work actually gets made in 2026.

They converge on **your game**, which carries **42%** of your grade.

NOTES:
Three tracks, and they run in parallel all semester.

Play is why any of this is worth doing. You will read Koster's Theory of Fun, and you will teach the class about a game you love — which is not a warm-up exercise, it is where the design vocabulary comes from.

Craft is the machine underneath: rendering in two and three dimensions, procedural generation, game AI, networking for multiplayer. Engines exist precisely to hide these things, which is why this course builds one instead of using one.

Soul is how the work gets made now — the eleven pillars of Claude Code, the five archetypes, the AI software development lifecycle.

And all three converge on your game, which is forty-two percent of your grade. Every tier assignment is a slice of the same game, so pick something you care about — you will be looking at it in December.

---

# Koster's claim

> **Fun is the feeling of your brain successfully learning a pattern.**

![](theory-of-fun-shelf-life.svg)

NOTES:
And here is the idea that underpins the Play track.

Fun is the feeling of your brain successfully learning a pattern. That is it. Not challenge, not reward, not story — pattern acquisition, felt from the inside.

Three consequences, and they are all uncomfortable.

Every mechanic has a shelf life. Once the pattern is learned, the reward stops. Not diminishes — stops. So your best mechanic is on a timer from the moment the player meets it, and design is largely about what you do when that timer runs out.

Noise is not difficulty. If the pattern cannot be found at all, the game is not hard, it is unfair. Randomness that cannot be read is not challenge, and players can tell the difference instantly even when they cannot articulate it.

And the curve must track rising skill. Read the line underneath: a game that never changes its demands does not stay level, it falls — because the player is rising underneath it. Standing still is a decision to become boring.

That third one comes back in week ten, when we build enemies you can actually learn.

---

# Why we build the engine

Unity's job is to make sure you **never think about** a fixed-timestep accumulator, a broadphase, or snapshot interpolation.

The course catalog requires exactly those.

- A course taught in a mature engine ends up teaching **around** the tool
- So we build one — small, in the browser, entirely readable

NOTES:
One question I get every year, up front: why not Unity or Godot?

Because a mature engine's entire value proposition is that you never have to think about the things this course is required to cover. A fixed-timestep accumulator, a collision broadphase, snapshot interpolation — Unity has all of them and its job is to make sure they never surface.

That is excellent engineering and it is exactly wrong for this course. Teaching networking inside an engine that handles networking means teaching around the tool, and students come out able to configure something without knowing what it does.

So we build one. Small, in the browser, entirely readable. You can hold the whole thing in your head, which is not true of any engine you would ship a commercial game in — and it is the only condition under which the machine underneath is visible.

---

# Due this week

Five onboarding assignments.

- **Assignment 1 — your GitHub username — is due Friday.** It gates everything: your portfolio repo, spec repo access, and your grading webhook.
- Git training and Claude Pro proof — **Sunday**
- The Ollama key and your first pull request — next week

Then: **The Pitch**, due Sun Aug 30.

NOTES:
Housekeeping, and the first item genuinely matters more than it looks.

Your GitHub username is due Friday, and it gates everything downstream — I cannot create your portfolio repository, give you access to the spec repository, or wire up your grading webhook without it. Every hour you delay that is an hour you cannot start anything else.

Git training and proof of Claude Pro by Sunday. The Ollama key and your first pull request come next week.

And then the Pitch, due August thirtieth: one page naming the game you will grow all semester.

Pick something you care about rather than something safe. Ambition is fine here — the scope contract in week ten is where you commit to what actually ships. This is where you commit to what it is.
