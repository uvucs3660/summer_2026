---
track: game
week: 11
title: Worlds
subtitle: Derived Seeds, Four Generators, and Audio That Arrives On Time
runtime: 24
---

NOTES:
Week eleven, game track.

Two subsystems today that look unrelated and share a spine: both are places where you generate something rather than author it, and both have a determinism trap at the front door.

Also — this Tuesday, October twenty-seventh, is the last day to withdraw from a full-semester course. I mention it because you should know, not because I am suggesting it.

---

# What you'll know after this

- Why chunk seeds must be **derived**, never drawn
- Four generators and the shape each one is for
- Why **infinite content gets boring faster** than authored content
- Why audio must be **scheduled ahead**, and how adaptive music actually works

NOTES:
Four things. The third one is a design warning and it is the one that will save you the most wasted effort.

---

# Derive the seed

![](procedural-generation-seed-derivation.svg)

NOTES:
Before any technique, the trap.

The natural way to write a chunk generator is to have a seeded generator and call it as you generate each chunk. It is seeded, so it is deterministic, so it is fine. Right?

It is not, and the reason is on the left. The values a chunk receives depend on how many draws happened before it — which depends on the order chunks were visited, which depends on where the player walked. Two machines that visited chunks in different orders generate different worlds from the same seed.

The fix is on the right and it is one line. Each chunk's seed is a pure function of the world seed and the chunk's coordinates, through an integer hash. Now chunk seventeen-comma-four has the same seed no matter when you got there, whether you got there at all, or what anyone else did.

This is the same shape as everything else this term: something outside the model — visit order — leaking in and becoming part of the answer.

---

# Four generators, four shapes

- **Noise** — smooth continuous fields. Terrain, clouds, wind. **Octaves** are where it starts looking real.
- **Cellular automata** — organic blobs. Random fill, then ~5 smoothing passes. **Always flood-fill afterwards**, or you ship an unreachable treasure room.
- **L-systems** — branching. Trees, rivers, roads.
- **Wave function collapse** — tiles that must obey adjacency rules.

NOTES:
Four tools. Pick by the shape of the thing you want, not by which is most interesting.

Noise for anything smooth and continuous. One octave looks like a lava lamp; it is stacking octaves — each half the amplitude and double the frequency — that makes it read as terrain.

Cellular automata for caves and organic blobs. Fill randomly, then run smoothing passes where each cell becomes whatever the majority of its neighbours are. Five passes is usually plenty.

And the warning attached to it: always flood-fill afterwards. Smoothing routinely produces disconnected pockets, and a pocket with your objective in it is a game nobody can finish. Flood-fill from the start, discard anything unreachable — or connect it deliberately.

L-systems for branching. Wave function collapse when tiles have adjacency rules — a road tile must meet another road tile.

---

# The design warning

> **Infinite content gets boring faster than authored content.**

A generator produces **variation**, not novelty.

- Its pattern is *smaller* than a designer's, so it is learned **sooner**
- Once learned, every new instance is the same thing again — Koster, week one
- **Generate the space. Author the moments.**

NOTES:
This is the most important slide in the procedural half, and it goes against the instinct that drives people to procedural generation in the first place.

The pitch is infinite content. The reality is that a generator has a pattern, and its pattern is much smaller than a human designer's, because it is a few hundred lines of rules. Players learn it fast. And once they have learned it, every subsequent instance is recognisably the same thing — which is week one's Koster argument exactly: when the pattern is learned, the reward stops.

Authored content has a much larger pattern space, because a designer is not constrained to be self-consistent. That is why a hand-made level can stay interesting after a procedural one has gone flat.

So the rule at the bottom. Generate the space — the terrain, the layout, the filler that would be tedious to author. Author the moments — the encounters, the reveals, the things you want a player to talk about afterwards. Almost every good procedural game is that hybrid, and almost every disappointing one generated the moments too.

---

# Audio: schedule ahead

![](audio-and-procedural-music-scheduling.svg)

NOTES:
Audio now, and it has the same shape as the game loop: separate when you decide from when it happens.

`setTimeout` and frame callbacks jitter by tens of milliseconds, because they run on the main thread and the main thread is busy doing your game. Tens of milliseconds is audible — not as lateness, as sloppiness. Rhythmic audio triggered this way sounds slightly wrong in a way people notice and cannot name.

WebAudio has a sample-accurate clock running independently. You do not tell it to play now; you tell it to play at a time, and it hits that time regardless of what the main thread is doing.

And the note at the bottom is the single most common audio bug: the audio context starts suspended, and only resumes after a user gesture. Silent audio that works on your machine — because you clicked something during testing — and is silent for a grader who did not. Resume it on first input, explicitly.

---

# Adaptive music with gain

Several layers of **one loop.** All of them playing, always. Fade **gain** with intensity.

> **Never start and stop layers.** A layer started mid-song lands out of phase and stays there.

Two lines of ramp and it sounds professional.

NOTES:
Adaptive music sounds like a big feature and is about six lines.

Take one loop, bounced as several layers — drums, bass, pads, lead. Start them all at the same instant, and leave them all playing forever. What changes is gain: fade the lead up when combat starts, fade it down when it ends.

The rule in the quote is the whole trick. Never start and stop layers. If you start the lead layer when combat begins, it starts at its own beginning while everything else is thirty seconds in, and it is out of phase for the rest of the song. There is no fixing it after the fact.

All layers always playing, gain ramps only. Two lines with `linearRampToValueAtTime` and it sounds like something with a budget.

---

# Provenance, as you go

One entry per generated asset: **model, prompt, seed, date, license, cost, phase.**

Four things at once:

- Attribution record · cost ledger · supply-chain evidence · **graded artifact**

> Write the entry when you add the asset. Nobody remembers October's prompt in December.

NOTES:
Last thing, and it is administrative but it is graded.

Every generated asset gets a manifest entry: which model, what prompt, what seed, when, under what license, what it cost, and which phase of the project it belongs to.

That one file is doing four jobs. It is your attribution record, which matters legally. It is a cost ledger. It is supply-chain evidence — what came from where. And it is a graded artifact in this course.

The instruction in the quote is the only part that requires discipline. Write it when you add the asset. In December, reconstructing which prompt produced which sprite in October is somewhere between painful and impossible, and the reconstruction will be partly fictional — which defeats the point of a provenance record.

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

Check your seeding. If you are drawing from a global generator, you have a desync that will appear the first time two peers explore in different orders, and it will look like a networking bug rather than a generation bug — which is what makes it expensive.

Flood-fill your caves and find out what is unreachable. People are always surprised.

And add one music layer, because it is six lines and it changes how the whole thing feels.

Thursday is soul prompts, and Forge 07 is due November ninth.
