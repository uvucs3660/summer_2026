---
slug: lecture-w03-determinism-and-commands
week: 3
youtube_id: null
companion_sheets:
  - cheatsheet-determinism-and-replay
  - cheatsheet-conformance-vectors
  - cheatsheet-game-programming-patterns
reflection_assignment: devlog-w03
vernacular_tags:
  - "Command"
  - "seeded PRNG · mulberry32"
  - "quantization · round half away from zero"
  - "FNV-1a state hash"
  - "append-only command log"
---

# Week 3 — Determinism and the Command Model

## What you'll know after this

After this lecture you will be able to (a) list the three sources of nondeterminism that break a simulation, (b) explain why quantization must specify its rounding mode, (c) describe what a state hash buys you, and (d) explain why a language model does not break replay.

## Outline

1. **One property, five features** *(8 min)*
   Same seed plus same commands must produce the same state hash. From that single property you get replays that cost nothing, lockstep multiplayer, desync detection, a gradable engine, and reproducible bug reports. Everything this course does technically rests on it.

2. **The three leaks** *(10 min)*
   `Math.random()`, `Date.now()`, and iteration order. The first two are obvious once named. The third is not: `Map` iterates in insertion order, so two implementations storing entities in different containers hash differently while both being correct. Sort by ascending id, always.

3. **Quantize before you hash** *(12 min)*
   Raw floats do not agree across languages. So quantize to integers first — positions ×1000, health ×10. **And name the rounding mode.** JavaScript's `Math.round(-0.5)` is `-0`; Dart's is `-1`. They agree on every positive number, so this bug is invisible in single player and fatal the first time something crosses to the negative side of an axis. We found this one in the class spec before you did; it is a good example of what "unambiguous" has to mean.

4. **The hash** *(8 min)*
   32-bit FNV-1a, `Math.imul`, not `(h * prime) >>> 0` — a JS number is exact only to 2^53 and the untruncated product blows past it. Four jobs at once: desync detector, replay verifier, conformance oracle, and proof a model did not corrupt the simulation.

5. **Commands are the only way in** *(12 min)*
   Player input, a remote peer, and an LLM reply are the same thing: a command appended to an ordered log. The model is nondeterministic; the **recorded reply** is not. Replay reads the log, never the model. This is exactly how lockstep netcode handles a remote player, and it is why three catalog requirements collapse into one seam.

6. **What a conformance vector is** *(5 min)*
   Seed, commands, tick count, expected hash. Inputs fully pinned, so the only remaining variable is the implementation. Where independent builds disagree, your prose was ambiguous. See `cheatsheet-conformance-vectors`.

## Discuss in class

- **Find the nondeterminism in your Assignment 1 game.** Grep for `Math.random` and `Date.now`. How many? Could that build produce a replay?
- **What else would two languages disagree about?** We found rounding. Integer division and string comparison are two more. What is a fourth, and how would you pin it in prose?
- **Is quantizing lossy in a way that matters?** Positions are truncated to a thousandth of a unit before hashing. When would that hide a real difference?

## Further reading

- `spec/S02-determinism.md` and `spec/S03-command-model.md` — the class specifications
- `src/hash.ts` — the reference implementation, proven bit-identical to a Dart original
- [Command pattern](https://gameprogrammingpatterns.com/command.html), Nystrom
