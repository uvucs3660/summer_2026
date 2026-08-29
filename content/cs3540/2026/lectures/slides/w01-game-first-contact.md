---
track: game
week: 1
title: First Contact
subtitle: What a Game Costs Now, and What Is Left to Learn
runtime: 20
---

NOTES:
Welcome to CS 3540.

I want to open with a measurement rather than a claim. Partly because you have spent two years being told things about artificial intelligence by people who were selling something, and a measurement is the one statement you can go and check for yourself.

And partly because it is the reason this course is shaped the way it is, and it is not the shape a game programming course had five years ago. Something moved, and I would rather show you the thing that moved than assert that it did.

---

# What you'll know after this

- What a complete game **actually costs** to produce right now
- Why **two independent builds converging** is the interesting result
- What the scarce skill is, if it is no longer typing an algorithm
- Koster's claim about fun, and its three consequences

NOTES:
Four things. The second one is the one that changed how I teach this course, and it is not the one anybody expects — the impressive result on the next slide is not the interesting result.

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

Now the honest part, because the honest part is where a number stops being a sales pitch. These were not finished games, and nobody is going to pay money for either of them. What the measurement says is narrower than that, and worse. The distance from nothing at all to a playable three-dimensional strategy game is now roughly one well-formed prompt. That distance used to be a semester. It used to be this semester.

And you will reproduce it yourself in two weeks, in the one-prompt game assignment. You are not being asked to take my word for it.

---

# The interesting part is that they agreed

![](history-of-games-two-builds-converged.svg)

NOTES:
But the games working is not the result. If both had worked and looked nothing alike, I would have shown you one, said something encouraging about the future, and moved on.

Here is the result. They converged. Independently. Two languages with nothing in common, two rendering stacks with nothing in common, no shared code — and both arrived at the same four layers. A pure simulation. A renderer that reads it and never writes back to it. A user interface layer. And a thin strip of wiring holding the three together.

Read the line at the bottom, because it is the load-bearing claim of this entire course. That convergence is evidence the boundary is real rather than stylistic.

Almost every architecture argument you have ever sat through was taste. Somebody senior preferred it that way, and the room agreed because arguing was expensive. This is not that. Two processes that could not talk to each other went looking for the seam and found the same seam. That is the kind of evidence you get in physics and almost never in software, and the correct response is not to assume you are cleverer than it.

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

It is the sentence in that quote, and it has two halves. Everyone remembers the front half and quietly loses the back half, which is where all the difficulty lives.

Specifying a system precisely enough that what comes back is correct. That part is genuinely hard.

And knowing how to tell whether it is. A specification you cannot check is a wish.

Which is why this course does something unusual. The class writes one engine specification. Together. Each of you owns sections of it. Then a scheduled agent builds that specification independently, several times over, and the builds get compared.

And where two independent builds disagree, your prose was ambiguous.

Not wrong. Ambiguous. Which means there is no argument to have, because the disagreement points at a section, and the section has an owner, and the owner is one of you.

That is the central idea, and I will repeat it all term. The quality of a specification is measurable, and the measurement is whether it produces the same thing twice.

---

# Three tracks

**Play** — history, fun, story, mystery. Why a thing is worth playing at all.

**Craft** — 2D, 3D, procedural generation, game AI, networking. The machine underneath.

**Soul** — the 11 Pillars, the archetypes, the AI SDLC. How the work actually gets made in 2026.

They converge on **your game**, which carries **42%** of your grade.

NOTES:
Three tracks, and they run in parallel all semester.

Play is why any of this is worth doing at all. You will read Koster's Theory of Fun, and you will stand up and teach this class about a game you love. That is not a warm-up exercise. It is where the design vocabulary for the whole term comes from, and it has to come out of games you have genuinely felt something about, which is why I am not picking them for you.

Craft is the machine underneath. Rendering in two dimensions and in three, procedural generation, game AI, networking for multiplayer. Engines exist to hide every one of those things from you, which is why this course builds one instead of using one.

Soul is how the work actually gets made now — the eleven pillars of Claude Code, the five archetypes, the AI software development lifecycle.

And all three converge on your game, which carries forty-two percent of your grade. Every tier assignment is a slice of the same game rather than a fresh start. So choose something you actually care about. You will still be looking at it in December, and a topic you picked in August because it seemed safe will not carry you that far.

---

# Koster's claim

> **Fun is the feeling of your brain successfully learning a pattern.**

![](theory-of-fun-shelf-life.svg)

NOTES:
And here is the idea the Play track hangs from.

Fun is the feeling of your brain successfully learning a pattern. That is it. Not challenge. Not reward. Not story. Pattern acquisition, felt from the inside.

Three consequences, and every one of them is uncomfortable.

The first consequence. Every mechanic has a shelf life. Once the pattern is learned, the reward stops. Not fades. Stops. Which means your best mechanic is on a timer from the moment the player first meets it, and most of what we call game design is deciding what happens when that timer runs out.

The second consequence. Noise is not difficulty. If there is no pattern to find, the game is not hard, it is unfair. Players detect this instantly, long before they can explain it, which is why the review says the game feels cheap and never quite manages to say why.

And the third consequence is the one with teeth. The curve has to track a rising skill. Look at the line under that chart. A game that never raises its demands is not holding steady. It is falling, because the player underneath it is climbing. Standing still is a decision to become boring.

That third one comes back in week ten, when we build enemies a human being can actually learn.

---

# Why we build the engine

Unity's job is to make sure you **never think about** a fixed-timestep accumulator, a broadphase, or snapshot interpolation.

The course catalog requires exactly those.

- A course taught in a mature engine ends up teaching **around** the tool
- So we build one — small, in the browser, entirely readable

NOTES:
One question I get every year, so let me answer it before it has time to fester. Why not Unity. Why not Godot. They are free and they are superb.

Because a mature engine's entire value proposition is that you never have to think about the precise set of things this course is required to cover. A fixed-timestep accumulator. A collision broadphase. Snapshot interpolation. Unity has all three, they are beautifully done, and their job is to never once surface.

That is excellent engineering. It is also exactly wrong for this room. Teach networking inside an engine that already does the networking and you are not teaching networking, you are teaching around the tool. What comes out the other end is a student who can confidently tick the right box in an inspector panel and cannot tell you what the box does. I have graded that student.

So we build one instead. Small, in the browser, small enough to hold in your head all at once — which is not true of any engine you would ship a real game in, and it is the only condition under which the machine underneath is genuinely visible.

You are not building this engine because it will be better than Unity. It will be worse in every measurable respect. You are building it because you can see through it.

---

# Due this week

Five onboarding assignments.

- **Assignment 1 — your GitHub username — is due Friday.** It gates everything: your portfolio repo, spec repo access, and your grading webhook.
- Git training and Claude Pro proof — **Sunday**
- The Ollama key and your first pull request — next week

Then: **The Pitch**, due Sun Aug 30.

NOTES:
Housekeeping, and the first item matters considerably more than it looks.

Your GitHub username is due Friday. That is the entire assignment. A username. It also gates every other thing in this course, because until I have it I cannot create your portfolio repository, I cannot give you access to the specification repository, and I cannot wire up your grading webhook. So every hour of delay on a one-word assignment is an hour you cannot spend on any of the real ones.

Git training and proof of Claude Pro by Sunday. The Ollama key and your first pull request come next week.

And then the Pitch, due August thirtieth. One page, naming the game you are going to grow all semester.

Pick something you care about rather than something safe. Ambition is fine here, because this is not the assignment where you promise what ships. The scope contract in week ten is where you get honest about scope. This is only where you decide what the thing is.