---
track: game
week: 1
title: First Contact
subtitle: What a Game Costs Now, and What Is Left to Learn
runtime: 20
---

NOTES:
Welcome to CS 3540.

I want to open with a measurement rather than a claim. Partly because you have spent the last two years being told things about artificial intelligence by people who were selling something, and a measurement is the one kind of statement you can go and check for yourself.

And partly because the measurement is the reason this course is shaped the way it is. This is not the shape a game programming course had five years ago. It is not the shape the catalog description implies. Something moved. And I would rather show you the thing that moved than stand up here and assert that it did.

So, no manifesto today. A number, and what follows from it.

---

# What you'll know after this

- What a complete game **actually costs** to produce right now
- Why **two independent builds converging** is the interesting result
- What the scarce skill is, if it is no longer typing an algorithm
- Koster's claim about fun, and its three consequences

NOTES:
Four things. The second one is the one that changed how I teach this course, and it is not the one anybody expects, because the impressive result on the next slide is not the interesting result. Hold on to that for two slides.

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

Two real-time strategy games, in the Age of Empires mould. One written in Dart against Flutter GPU. One in TypeScript against three.js. Each one produced from a single prompt plus six answered clarifying questions.

And this is the moment where a demo normally turns out to be a rectangle sliding around on a grey background. These were not that. Pathfinding. An AI opponent that adapts to how you play. Four ages of unit progression. Deployed, playable, tested. About four thousand lines each.

Now the honest part, because the honest part is where a number stops being a sales pitch. These were not finished games. They were not even good games. Nobody is going to pay money for either of them. What the measurement says is narrower than that, and worse. The distance from nothing at all to a playable three-dimensional strategy game is now roughly one well-formed prompt. That distance used to be a semester. It used to be this semester.

And you will reproduce it yourself in two weeks, in the one-prompt game assignment. I am not asking anybody to take my word for any of this. You are going to run it.

---

# The interesting part is that they agreed

![](history-of-games-two-builds-converged.svg)

NOTES:
But the games working is not the result. If both of them had worked and looked nothing alike, I would have shown you one, said something encouraging about the future, and moved on.

Here is the result. They converged. Independently. Two languages with nothing in common, two rendering stacks with nothing in common, no shared code, no shared prompt beyond the description of the game itself — and both of them arrived at the same four layers. A pure simulation. A renderer that reads that simulation and never writes back to it. A user interface layer. And a thin strip of wiring holding the three of them together.

Read the line along the bottom of that diagram, because it is the load-bearing claim of this entire course. That convergence is evidence the boundary is real rather than stylistic.

I want to be precise about why that carries weight. Almost every architecture argument you have ever sat through was taste. Somebody senior preferred it that way, and the room agreed because arguing was expensive. This is not that. Two processes that could not talk to each other went looking for the seam, and they found the same seam. That is the kind of evidence you get in physics and almost never in software, and when you are handed evidence like that, the correct response is to take it seriously rather than to assume you are cleverer than it.

That boundary — simulation on one side, everything else on the other — is what the next fourteen weeks are organised around. In week four it hardens into a rule in the specification. In week thirteen it becomes a process boundary you could not cross even if you wanted to.

---

# So what is left to learn?

Not typing an A\* implementation.

> The scarce skill is **specifying a system precisely enough that what comes back is correct** — and knowing how to tell whether it is.

Everything in this course follows from taking that seriously:

- You will write a **specification that agents build from**
- Where independent builds **disagree**, your prose was ambiguous
- That is measurable, and it is how your section is graded

NOTES:
So if the code is cheap, what exactly are you here for?

It is the sentence in that quote, and it has two halves. People remember the first half and quietly drop the second one, and the second one is where all the difficulty actually lives.

Specifying a system precisely enough that what comes back is correct. That is the first half, and it is genuinely hard.

And knowing how to tell whether it is. That is the second half. A specification you cannot check is not a specification. It is a wish.

Which is why this course does something I have not seen another course do. The class writes one engine specification. Together. Each of you owns sections of it, with your name attached. Then a scheduled agent builds that specification from scratch, several times over, independently, and those builds get compared against each other.

And where two independent builds disagree, your prose was ambiguous.

Not wrong. Ambiguous. Which means there is no argument to have, because the disagreement points at a section, and the section has an owner, and the owner is one of you.

That is the central idea of this course and I will repeat it until you are sick of hearing it. The quality of a specification is measurable, and the measurement is whether it produces the same thing twice.

---

# Three tracks

**Play** — history, fun, story, mystery. Why a thing is worth playing at all.

**Craft** — 2D, 3D, procedural generation, game AI, networking. The machine underneath.

**Soul** — the 11 Pillars, the archetypes, the AI SDLC. How the work actually gets made in 2026.

They converge on **your game**, which carries **42%** of your grade.

NOTES:
Three tracks. They run in parallel all semester and they do not take turns.

Play is why any of this is worth doing at all. You will read Koster's Theory of Fun, and you will stand up and teach this class about a game you love. That is not a warm-up and it is not a participation exercise. It is where the design vocabulary for the whole term comes from, and that vocabulary has to come out of games you have genuinely felt something about, which is why I am not picking them for you.

Craft is the machine underneath. Rendering in two dimensions and in three, procedural generation, game AI, networking for multiplayer. Engines exist in order to hide every single one of those things from you. Which is precisely why this course builds one instead of using one, and I will come back to that in a moment.

Soul is how the work actually gets made now — the eleven pillars of Claude Code, the five archetypes, the AI software development lifecycle.

And all three converge on your game, which carries forty-two percent of your grade. Every tier assignment is a slice of the same game rather than a fresh start. So choose something you actually care about, not something that sounds defensible. You will still be looking at it in December, in a cold room, at the end of a long semester, and a topic you picked in August because it seemed safe will not carry you that far.

---

# Koster's claim

> **Fun is the feeling of your brain successfully learning a pattern.**

![](theory-of-fun-shelf-life.svg)

NOTES:
And here is the idea the entire Play track hangs from.

Fun is the feeling of your brain successfully learning a pattern. That is the whole claim. Not challenge. Not reward. Not story. Pattern acquisition, felt from the inside.

It is a small sentence, and it has three consequences, and every one of them is uncomfortable.

The first consequence. Every mechanic has a shelf life. Once the pattern is learned, the reward stops. Not fades. Stops. Which means your best mechanic is on a timer from the moment the player first meets it, and most of what we call game design is deciding what happens when that timer runs out.

The second consequence. Noise is not difficulty. If there is no pattern available to be found, the game is not hard, it is unfair. Randomness a player cannot read is not challenge, and players detect this instantly, long before they can explain it — which is why the review says the game feels cheap and never quite manages to say why.

And the third consequence is the one with teeth. The curve has to track a rising skill. Look at the line under that chart. A game that never raises its demands is not holding steady. It is falling, because the player underneath it is climbing. Standing still is a decision to become boring.

That third one comes back in week ten, when we build enemies a human being can actually learn.

---

# Why we build the engine

Unity's job is to make sure you **never think about** a fixed-timestep accumulator, a broadphase, or snapshot interpolation.

The course catalog requires exactly those.

- A course taught in a mature engine ends up teaching **around** the tool
- So we build one — small, in the browser, entirely readable

NOTES:
One question I get every single year, so let me answer it before it has time to fester. Why not Unity. Why not Godot. They are free, they are superb, and everybody uses them.

Because a mature engine's entire value proposition is that you never have to think about the precise set of things this course is required to cover. A fixed-timestep accumulator. A collision broadphase. Snapshot interpolation. Unity has all three, all three are beautifully done, and their job is to never once surface. You can ship a commercial title without ever learning those three phrases.

That is excellent engineering. It is also exactly wrong for this room. Teach networking inside an engine that already does the networking and you are not teaching networking, you are teaching around the tool. What comes out the other end is a student who can confidently tick the right box in an inspector panel and cannot tell you what the box does. Every instructor in this building has graded that student.

So we build one instead. Small, in the browser, entirely readable. Small enough that you can hold the whole thing in your head at one time, which is not true of any engine you would ship a real game in, and it is the only condition under which the machine underneath is genuinely visible.

You are not building this engine because it will be better than Unity. It will be worse than Unity in every measurable respect. You are building it because you can see through it.

---

# Due this week

Five onboarding assignments.

- **Assignment 1 — your GitHub username — is due Friday.** It gates everything: your portfolio repo, spec repo access, and your grading webhook.
- Git training and Claude Pro proof — **Sunday**
- The Ollama key and your first pull request — next week

Then: **The Pitch**, due Sun Aug 30.

NOTES:
Housekeeping, and the first item matters considerably more than it looks like it matters.

Your GitHub username is due Friday. That is the entire assignment. A username. It also gates every other thing in this course, because until I have it I cannot create your portfolio repository, I cannot give you access to the specification repository, and I cannot wire up your grading webhook. So every hour of delay on a one-word assignment is an hour you cannot spend on any of the real ones. Do it tonight, from your phone, before you have finished thinking about this sentence.

Git training and proof of Claude Pro by Sunday. The Ollama key and your first pull request come next week.

And then the Pitch, due August thirtieth. One page, naming the game you are going to grow all semester.

Pick something you care about rather than something safe. Ambition is fine here, because this is not the assignment where you promise what ships. The scope contract in week ten is where you get honest about scope. This is only where you decide what the thing is.