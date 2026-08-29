---
track: game
week: 3
title: Determinism
subtitle: The Command Model, the State Hash, and Why a Language Model Does Not Break Replay
runtime: 25
---

NOTES:
Week three, game track.

Last week we made the simulation stop depending on frame timing. This week we make it stop depending on anything else, and then we collect, because determinism is the one property this entire course is built on top of.

One warning before we start. This lecture contains the nastiest bug in the class specification. It is four characters long. It is invisible in single player, it is invisible in every test you would think to write, and the only reason we know about it is that two independent implementations disagreed and one of them had to be wrong.

Nobody found it by reading. Reading is not how this class of bug gets found, and that is most of what this lecture is really about.

When we get there, slow down.

---

# What you'll know after this

- The **three sources of nondeterminism** — and why the third one is the one that gets you
- Why quantization must **name its rounding mode**
- What a **state hash** buys you, and why `Math.imul` is not optional
- Why a language model in your game does **not** break replay

NOTES:
Four things.

The first three are mechanical. You can find all of them with grep and a careful read, and you should, before Thursday.

The fourth is not mechanical. It is the one that makes the hardest constraint in this course tractable. You are going to put a language model, a thing that gives you a different answer every time you ask, inside a simulation that must produce the same answer every time. That sounds impossible. It is not.

---

# One property, five features

> Same seed, plus the same commands, must produce the same state hash.

That is the entire claim. Everything technical in this course is a consequence of it.

- If it holds, replays are **free** — you already stored the inputs
- If it fails, none of the five things on the next slide exist

NOTES:
Read the quote and notice how small it is.

Same seed, same commands, same hash. One sentence, no qualifications, no unless. It has the tone of a technicality and it is actually the floor everything else stands on.

The second bullet is the part I want you to feel. These are not five features you could build separately and ship one at a time as you get to them. They are five consequences of one property. You do not implement replay. You implement determinism, and replay falls out of it for free.

Which means the failure mode is not gradual either. Determinism does not degrade. You do not get slightly worse replays when it slips. You get none of the five, all at once.

---

# What it buys

![](determinism-and-replay-one-property.svg)

NOTES:
Here they are.

Replays cost nothing, because you already have the commands. The replay file is the input log, and the input log is tiny.

Lockstep multiplayer works, because peers exchange inputs and each one computes the world itself instead of shipping state across the network.

Desync detection becomes comparing one thirty-two-bit number instead of diffing two entire worlds.

The fourth one is how you get graded, so hold on to it. A conformance vector states what the hash must be after a stated number of ticks, which makes your engine section machine-checkable. That is unusual. Most specifications are prose you argue about in a meeting.

And the fifth is the one you will care about personally, in November, at one in the morning, when something is wrong and you cannot make it happen twice. A seed and a command log reproduce it exactly, every time, on demand.

Lose the property and all five go together.

---

# The three leaks

```js
Math.random()     // different every run
Date.now()        // different every run
for (const e of entities) { ... }   // different every implementation
```

The first two are obvious the moment they are named. **The third one is not.**

NOTES:
Three ways real time and real entropy get into a simulation that is supposed to be sealed.

The first two you can find with grep, and you should, today, in the game you shipped in week one. Random numbers have to come from a seeded generator you control. We use mulberry32; it is four lines. Time has to come from the tick count, not the wall clock. Your simulation knows what tick it is on, and that is the only clock it gets.

The third line looks completely innocent. It is the one that costs a weekend.

---

# Iteration order is a leak

Two implementations, both correct, storing entities differently:

- `Map` iterates in **insertion order**
- A plain object iterates integer-like keys in **ascending numeric order**
- A `Set` rebuilt from a filter is in **whatever order the filter produced**

Same entities. Same logic. **Different hash.**

> Sort by ascending id before you iterate. Always. Even when it "cannot matter."

NOTES:
Here is why the third leak is different in kind from the other two.

Nothing about it is a bug. Both implementations store the same entities, apply the same rules, and produce the same world. Render them side by side and you cannot tell them apart. Every unit test you wrote passes in both.

But the moment you fold that world into a hash, order starts to matter, because a hash is a sequence of operations and a sequence is ordered by definition. Two correct programs, two different numbers.

This is exactly the class of thing that makes independent-build comparison worth doing at all. You will not catch it by staring at your own code, because your code is right, and staring harder at correct code does not produce a bug report. You catch it when somebody else's equally right code disagrees with yours and one of you has to explain why.

The rule at the bottom is absolute, and I want it to be boring. Sort by ascending id before you iterate. Not when you think order matters. Always. The cost is one sort. The alternative is a divergence report in October with your section named on it.

---

# Three sources, one seam

![](determinism-and-replay-command-log.svg)

NOTES:
This is on your cheat sheet for the week.

The left of it is the three leaks we just covered. The right half is where we are going in a few minutes, and it is the reason a language model, which is about as nondeterministic a thing as we have ever built on purpose, can sit inside this without breaking any of it.

Hold that thought. First we have to deal with numbers.

---

# Quantize before you hash

Raw floats do not agree across languages, across compilers, or sometimes across optimization levels.

So do not hash floats. **Hash integers.**

```js
const qx = Math.round(x * 1000);   // positions to a thousandth
const qh = Math.round(hp * 10);    // health to a tenth
```

Then hash `qx`. Never `x`.

NOTES:
Floating point is the next thing to pin down.

The trouble with floats is not that they are imprecise. They are imprecise in extremely well-defined ways. The trouble is that the last bit of a float can depend on the order the operations were fused in, and that can depend on the compiler, the platform, and whether something got vectorized on the way through.

So we do not hash them. We multiply by a scale factor, round to an integer, and hash the integer. Positions to a thousandth of a unit, health to a tenth. Integers are exact everywhere, in every language, on every machine.

That solves the float problem completely. And it introduces a new one, which is worse, because it looks solved.

---

# The four-character bug

![](determinism-and-replay-quantize.svg)

NOTES:
Slow down here.

JavaScript's round function rounds half up, toward positive infinity. So negative zero point five becomes negative zero. Dart's round rounds half away from zero. So negative zero point five becomes negative one.

Both are defensible. Both are documented. They are simply different, and they differ only on the negative side of the axis, and only on exact halves.

Now think about what that means for a class where fifteen people write spec sections and a scheduled agent builds them independently. Every test any of you writes with positive coordinates passes in both languages. Your game works. Your replays work. Your conformance vectors pass. The bug is not hiding from you. It has just never been asked the one question that reveals it.

Then something walks to the left of the origin, the two builds produce different hashes, and the divergence report points at whoever wrote the section that said round without saying which way.

That is the best example I have of what unambiguous has to mean in a specification. Not clear to a careful reader. Leaves no legal choice. Saying round leaves a legal choice. Saying round half away from zero does not.

---

# The hash itself

32-bit FNV-1a. Two lines, one trap.

```js
let h = 0x811c9dc5;
for (const b of bytes) {
  h ^= b;
  h = Math.imul(h, 16777619) >>> 0;   // NOT h * 16777619
}
```

NOTES:
The hash function is FNV-1a, thirty-two bit. It is not cryptographic and it does not need to be. We are detecting accidental divergence between honest implementations, not defending against an attacker.

It is two lines. Exclusive-or the byte in, multiply by the prime, truncate back to thirty-two bits. And there is exactly one place in those two lines to get it wrong, which is the multiply.

---

# Why `Math.imul`

![](determinism-and-replay-hash.svg)

NOTES:
Here is the trap drawn out.

A JavaScript number is a double. It represents integers exactly up to two to the fifty-three, and past that it starts rounding. Now multiply a thirty-two-bit hash by a thirty-two-bit prime. The true product needs up to sixty-four bits, which is well past fifty-three.

So the naive version has already lost the low bits by the time you apply the shift that truncates. And the low bits are precisely the ones the truncation was going to keep. What comes back is a number. It has the shape of a hash. It is stable within one runtime, so every test you write passes. It is simply not FNV-1a, and it will never match anyone else's.

Math dot imul exists for exactly this. It performs a real thirty-two-bit multiply with wraparound, the way C would. Our reference implementation of the hash was proven bit-identical against a Dart original, and that proof is the reason cross-language conformance is possible at all.

---

# Commands are the only way in

Nothing mutates simulation state except an applied command.

- A key press → a command
- A remote peer's input → a command
- A language model's reply → **a command**

All three go into one **ordered, append-only log**.

> If it did not come through the log, it did not happen.

NOTES:
Now the structural idea, and this is the one that makes everything else in the lecture collapse together.

Your simulation has exactly one door. Things do not happen to the world. Commands are appended to a log, and the log is applied. Player input becomes a command. A remote peer's input arrives as a command. And a language model's reply, the text it produced, whenever it happened to arrive, becomes a command too.

The quote at the bottom is the invariant, and it is not a guideline. If some code somewhere reaches into the world and sets a health value directly, without going through the log, then your replay will not reproduce it and your peers will never hear about it. That is a hole in the hull, and the hull does not care how small the hole is.

One door.

---

# Why the model does not break replay

The model is nondeterministic. **The recorded reply is not.**

- Live: ask the model, get text, **append it to the log** as a command
- Replay: read the command out of the log. The model is never called.
- The simulation only ever sees the recorded text — which is fixed

This is **exactly** how lockstep handles a remote player: you do not simulate them, you receive what they did.

NOTES:
And here is the payoff.

Everyone assumes a language model inside a game destroys reproducibility, because models are nondeterministic. Same prompt, different answer, and you cannot even lean on temperature zero holding still across versions.

But look at what actually crosses the boundary. During live play you call the model, it returns some text, and you append that text to the command log. What the simulation consumed was the text. Not the model. Not the call. Not the sampling.

During replay you do not call the model at all. You read the recorded reply out of the log and apply it exactly as it was. The simulation cannot tell the difference, because from inside the simulation there is no difference to tell.

Now read the last line, because this is the elegant part. This is not a special mechanism somebody invented for language models. It is identical to how lockstep netcode handles a remote human being. You never simulate the other player. You receive what they did and you apply it. A remote peer and a language model are the same shape of problem, and the command log solves both without knowing that either one exists.

Three requirements in the course catalogue, replay and multiplayer and a generative model, collapse into one seam. That is what good architecture looks like from the inside. It does not feel clever. It feels like there was never another way to do it.

---

# What a conformance vector is

![](conformance-vectors-anatomy.svg)

NOTES:
Last piece, and it is how your spec section gets graded.

A vector pins every input. A seed, an ordered list of commands, a number of ticks, and the state hash that must result. Inputs fully specified means the only remaining variable in the entire system is the implementation.

So when two independent builds run the same vector and produce different hashes, that is not a mystery to investigate. Exactly one thing differed, and it was how each build read your prose. The disagreement is evidence that your section permitted two readings.

That is why I keep saying divergence is not blame. It is the only feedback loop that will ever tell you whether what you wrote says what you meant. Nothing else in writing does this. You cannot compile an essay.

---

# Before Thursday

- **Grep your week-one game** for `Math.random` and `Date.now`. Count them.
- Could that build produce a replay? Be honest.
- We found **rounding**. Integer division and string comparison are two more. **What is a fourth** — and how would you pin it in prose?
- Read `spec/S02-determinism.md` and `spec/S03-command-model.md`

Thursday, AI: **Skills** — and why your first one will never fire.

NOTES:
Three things.

Grep your game and count. Every hit is a place where the simulation can see something the replay has no way to reproduce. I am not expecting zero. I am expecting you to know the number.

The third bullet is the actual homework, and it is what we open with. We pinned rounding. Integer division on negatives is another, because some languages truncate toward zero and some floor. String comparison is a third, because sort order depends on collation. I want a fourth from you. And more than the leak itself, I want the sentence you would write in a spec to kill it. That sentence is the skill this whole course is teaching; everything else is scaffolding around it.

Thursday is skills, the Claude Code kind. Forge 02 is due on the twenty-first, and the reason most first attempts never fire once is worth half an hour of your evening.