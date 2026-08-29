---
track: game
week: 11
title: Worlds
subtitle: Derived Seeds, Four Generators, and Audio That Arrives On Time
runtime: 24
---

NOTES:
Week eleven, game track.

Two subsystems today. Terrain, and sound. They look unrelated, and they share a spine: in both of them you generate the thing rather than author it, and in both of them there is a determinism trap sitting at the front door, before you have written a single interesting line.

That is worth saying plainly. Neither of these subsystems punishes you for being unimaginative. Both punish you for being casual about time and about order.

Also, administratively: this Tuesday, October twenty-seventh, is the last day to withdraw from a full-semester course. I mention it because you should know, not because I am suggesting it.
---

# What you'll know after this

- Why chunk seeds must be **derived**, never drawn
- Four generators and the shape each one is for
- Why **infinite content gets boring faster** than authored content
- Why audio must be **scheduled ahead**, and how adaptive music actually works

NOTES:
Four things. The third one is a design warning rather than a technique, and it is the one that will save you the most wasted effort — because the effort it saves is effort you were about to spend enthusiastically.
---

# Derive the seed

![](procedural-generation-seed-derivation.svg)

NOTES:
Before any technique, the trap. This is mechanism, so I am going to take it slowly.

The natural way to write a chunk generator is this. One seeded generator, seeded once when the world is created. As the player walks and each new chunk comes into range, you generate that chunk by drawing from it. It is seeded, so it is deterministic, so it is fine.

It is not fine, and the reason is on the left. The values a chunk receives depend on how many draws happened before that chunk was generated. How many draws happened before it depends on which chunks were generated first. Which chunks were generated first depends on where the player walked. So the terrain depends on the path taken through it. Two machines that visit chunks in a different order build different worlds from the same seed, and neither machine is wrong. They simply disagree.

The fix is on the right, and it is one line. A chunk's seed is a pure function of the world seed and that chunk's own coordinates, combined through an integer hash. There is no history in that expression. Chunk seventeen-comma-four gets the same seed no matter when you arrived, whether you ever arrived, and no matter what any other peer did.

This is the same shape as every determinism defect this term: something outside the model — here, visit order — leaking in and becoming part of the answer.
---

# Four generators, four shapes

- **Noise** — smooth continuous fields. Terrain, clouds, wind. **Octaves** are where it starts looking real.
- **Cellular automata** — organic blobs. Random fill, then ~5 smoothing passes. **Always flood-fill afterwards**, or you ship an unreachable treasure room.
- **L-systems** — branching. Trees, rivers, roads.
- **Wave function collapse** — tiles that must obey adjacency rules.

NOTES:
Four tools, and I have listed them roughly in the order you will reach for them, which is the reverse of how interesting they are to read about.

Noise for anything smooth and continuous. Terrain, cloud cover, wind. One octave of noise looks like a lava lamp. It is stacking octaves — each one half the amplitude and double the frequency of the one above it — that makes it read as ground.

Cellular automata for caves and organic blobs. Fill the grid randomly, then run smoothing passes where every cell becomes whatever the majority of its neighbours already are. Five passes is usually plenty.

And the warning that travels with it. Always flood-fill afterwards. Smoothing routinely leaves disconnected pockets, and a pocket with your objective inside it is a game nobody can finish. Flood-fill from where the player starts, then either throw away what you cannot reach or connect it on purpose.

L-systems for anything that branches — trees, rivers, road networks. Wave function collapse for tiles that have to obey adjacency rules, where a road tile must meet another road tile.
---

# The design warning

> **Infinite content gets boring faster than authored content.**

A generator produces **variation**, not novelty.

- Its pattern is *smaller* than a designer's, so it is learned **sooner**
- Once learned, every new instance is the same thing again — Koster, week one
- **Generate the space. Author the moments.**

NOTES:
This is the most important slide in the procedural half, and it argues directly against the instinct that sends people to procedural generation in the first place.

The pitch is infinite content. The reality is that a generator has a pattern, and its pattern is small — a few hundred lines of rules, most of which a player will have met inside twenty minutes. So they learn it fast. And once it is learned, every subsequent instance is recognisably the same thing again, which is week one's Koster argument arriving from a new direction: fun is a pattern being learned, and when the learning finishes, so does the fun.

A human designer has a far larger pattern space, for an unglamorous reason. A designer is not required to be self-consistent. A generator is nothing but its consistency.

So the rule at the bottom. Generate the space — the terrain, the layout, the filler that would be tedious to place by hand. Author the moments — the encounter, the reveal, the thing a player describes to somebody else afterwards. Almost every good procedural game is that hybrid. Almost every disappointing one generated the moments too.
---

# Audio: schedule ahead

![](audio-and-procedural-music-scheduling.svg)

NOTES:
Audio now, and it has the same shape as the game loop: separate when you decide from when it happens.

Set timeout and frame callbacks jitter by tens of milliseconds, because they run on the main thread and the main thread is busy running your game. Tens of milliseconds is audible. Not as lateness — nobody hears thirty milliseconds as late. It is audible as sloppiness, and a rhythmic sound triggered this way is wrong in a way people notice and cannot name.

Web Audio has its own clock, sample-accurate, running independently of anything you are doing. So you do not tell it to play now. You tell it a time to play at, and it lands on that time regardless of what the main thread was busy with.

And the note at the bottom is the single most common audio bug I see. The audio context starts suspended and only resumes after a user gesture. Which gives you silent audio that works on your machine, because you clicked something while testing, and is silent for a grader who pressed nothing. Resume it on first input, explicitly.
---

# Adaptive music with gain

Several layers of **one loop.** All of them playing, always. Fade **gain** with intensity.

> **Never start and stop layers.** A layer started mid-song lands out of phase and stays there.

Two lines of ramp and it sounds professional.

NOTES:
Adaptive music sounds like a feature and it is about six lines.

Take one loop and bounce it as several layers. Drums, bass, pads, lead. Start all of them at the same instant and leave all of them playing forever. Nothing ever stops. What changes is gain: fade the lead up when combat starts, fade it back down when it ends.

The rule in the quote is the entire trick. Never start and stop layers. If you start the lead when combat begins, it starts at its own beginning while everything else is thirty seconds in, and it is out of phase for the rest of the song. There is no correcting that afterwards. You cannot nudge it back into place; the only fix was available before you started.

So: all layers always playing, gain ramps only. Two lines of linear ramp to value at time, and it sounds like something with a budget behind it.
---

# Provenance, as you go

One entry per generated asset: **model, prompt, seed, date, license, cost, phase.**

Four things at once:

- Attribution record · cost ledger · supply-chain evidence · **graded artifact**

> Write the entry when you add the asset. Nobody remembers October's prompt in December.

NOTES:
Last thing, and it is administrative, and it is graded.

Every generated asset gets one manifest entry. Which model made it, what prompt, what seed, on what date, under what license, what it cost, and which phase of the project it belongs to.

That one file is doing four jobs at once. It is your attribution record, which is a legal question and not a tidiness question. It is a cost ledger. It is supply-chain evidence — what came from where, which is the thing somebody asks for afterwards and never in advance. And it is a graded artifact in this course.

The instruction in the quote is the only part that takes any discipline. Write the entry when you add the asset. In December, working out which prompt produced which sprite in October is somewhere between painful and impossible, and whatever you reconstruct will be part fiction — which is the one thing a provenance record cannot be and still be a provenance record.
---

# Before Thursday

- **Check your chunk seeding.** Derived, or drawn? If drawn, that is a desync.
- If you use cellular automata, **flood-fill.** Find out whether anything is unreachable.
- Add **one** adaptive music layer. Gain only.
- `cheatsheet-procedural-generation`, `cheatsheet-audio-and-procedural-music`, `cheatsheet-asset-pipeline-and-provenance`

Thursday, AI: **Soul prompts.** Forge 07 due **Sun Nov 9.**
**Tue Oct 27** is the last day to withdraw from a full-semester course.

NOTES:
Three things, and the first is not optional if you generate a world.

Check your seeding. Derived, or drawn? If you are drawing from a global generator as you go, you have a desync, and here is what makes it expensive. It will not arrive looking like a generation bug. It will arrive the first time two peers explore in different orders, and it will present as a networking bug — so you will go looking for it in your netcode, which is the one place it is not.

Flood-fill your caves and find out what is unreachable. People are always surprised.

And add one music layer, because it is six lines and it changes how the whole thing feels.

Thursday is soul prompts, and Forge 07 is due November ninth.