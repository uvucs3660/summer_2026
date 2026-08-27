---
track: game
week: 3
title: Determinism
subtitle: The Command Model, the State Hash, and Why a Language Model Does Not Break Replay
runtime: 25
---

NOTES:
Week three, game track.

Last week we made the simulation stop depending on frame timing. This week we make it stop depending on anything else — and then we collect the payment, because determinism is the one property this entire course is built on top of.

I want to warn you up front that this lecture contains the single nastiest bug in the class specification. It is four characters long, it is invisible in single player, and we found it before any of you did only because two independent implementations disagreed about it. When we get there, slow down.

---

# What you'll know after this

- The **three sources of nondeterminism** — and why the third one is the one that gets you
- Why quantization must **name its rounding mode**
- What a **state hash** buys you, and why `Math.imul` is not optional
- Why a language model in your game does **not** break replay

NOTES:
Four things.

The first three are mechanical — you can check for all of them with grep and a careful read. The fourth is conceptual, and it is the one that makes this course's hardest constraint tractable. You are going to put a language model inside a deterministic simulation, which sounds impossible, and it is not.

---

# One property, five features

> Same seed, plus the same commands, must produce the same state hash.

That is the entire claim. Everything technical in this course is a consequence of it.

- If it holds, replays are **free** — you already stored the inputs
- If it fails, none of the five things on the next slide exist

NOTES:
Read the quote and notice how small it is.

Same seed, same commands, same hash. One sentence, no qualifications. It is the sort of statement that sounds like a technicality and is actually the foundation.

The second bullet is the part I want you to feel. These are not five independent features you could build separately and ship one at a time. They are five consequences of one property. You do not implement replay. You implement determinism, and replay falls out.

Which also means the failure mode is not gradual. You do not get slightly worse replays when determinism slips. You get none.

---

# What it buys

![](determinism-and-replay-one-property.svg)

NOTES:
Here they are.

Replays cost nothing, because you already have the commands — the replay file is the input log, and it is tiny. Lockstep multiplayer works, because peers exchange inputs and each compute the world themselves rather than shipping state across the network. Desync detection is comparing one thirty-two-bit number instead of diffing two worlds.

The fourth one is how you get graded, so pay attention to it: a conformance vector states what the hash must be after N ticks, which means your engine section is machine-checkable. That is unusual. Most specifications are prose you argue about.

And the fifth is the one you will personally care about in November, at one in the morning, when something is wrong and you cannot make it happen twice. A seed and a command log reproduce it exactly, every time.

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

The first two you can find with grep, and you should, today, in the game you shipped in week one. Random numbers must come from a seeded generator you control — we use mulberry32, it is four lines. Time must come from the tick count, not the wall clock. Your simulation knows what tick it is on; that is the only clock it gets.

The third line looks completely innocent, and it is the one that will actually cost you a weekend.

---

# Iteration order is a leak

Two implementations, both correct, storing entities differently:

- `Map` iterates in **insertion order**
- A plain object iterates integer-like keys in **ascending numeric order**
- A `Set` rebuilt from a filter is in **whatever order the filter produced**

Same entities. Same logic. **Different hash.**

> Sort by ascending id before you iterate. Always. Even when it "cannot matter."

NOTES:
Here is why the third leak is different in kind.

Nothing about this is a bug. Both implementations store the same entities, apply the same rules, and produce the same world. If you rendered them side by side you could not tell them apart, and every unit test you wrote would pass in both.

But the moment you fold that world into a hash, order matters, because a hash is a sequence of operations and sequences are ordered. Two correct programs, two different numbers.

And this is exactly the class of thing that makes independent-build comparison worth doing. You will not catch this by staring at your own code, because your code is right. You catch it when someone else's equally-right code disagrees with yours.

The rule at the bottom is absolute and I want it to be boring: sort by id. Not when you think order matters — always. The cost is one sort. The alternative is a divergence report in October pointing at your section.

---

# Three sources, one seam

![](determinism-and-replay-command-log.svg)

NOTES:
This is on your cheat sheet for the week.

The left of it is the three leaks we just covered. The right half is where we are heading in a few minutes — the reason a language model, which is about as nondeterministic a thing as exists, can sit inside this without breaking anything.

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

The trouble with floats is not that they are imprecise — they are imprecise in extremely well-defined ways. The trouble is that the last bit of a float can depend on the order operations were fused, which can depend on the compiler, the platform, and whether something got vectorized.

So we do not hash them. We multiply by a scale factor, round to an integer, and hash that. Positions to a thousandth of a unit, health to a tenth. Now we are hashing integers, and integers are exact everywhere.

That solves the float problem completely, and introduces a new one that is worse because it looks solved.

---

# The four-character bug

![](determinism-and-replay-quantize.svg)

NOTES:
Slow down here.

`Math.round` in JavaScript rounds half **up** — toward positive infinity. So negative one half becomes negative zero. Dart's `round` rounds half **away from zero**. So negative one half becomes negative one.

Both are defensible. Both are documented. They are simply different, and they differ only on the negative side of the axis, only on exact halves.

Now think about what that means for a class where fifteen people write spec sections and a scheduled agent builds them independently. Every test any of you writes with positive coordinates passes in both languages. Your game works. Your replays work. Your conformance vectors pass.

And then something walks to the left of the origin and the two builds produce different hashes, and the divergence report points at whoever wrote the section that said "round" without saying which way.

We found this one before any of you did. It is the best example I have of what "unambiguous" has to mean in a specification: not "clear to a careful reader" but "leaves no legal choice." Saying "round" leaves a legal choice. Saying "round half away from zero" does not.

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
The hash function is FNV-1a, thirty-two bit. It is not cryptographic and does not need to be — we are detecting accidental divergence, not defending against an attacker.

It is two lines. Exclusive-or the byte in, multiply by the prime, truncate to thirty-two bits. And there is exactly one place to get it wrong, which is the multiply.

---

# Why `Math.imul`

![](determinism-and-replay-hash.svg)

NOTES:
Here is the trap drawn out.

A JavaScript number is a double. It represents integers exactly up to two to the fifty-three, and above that it starts rounding. Now multiply a thirty-two-bit hash by a thirty-two-bit prime. The true product needs up to sixty-four bits — well past fifty-three.

So the naive version has already lost the low bits by the time you apply the shift to truncate. And the low bits are precisely the ones the truncation was going to keep. You get a number. It looks like a hash. It is stable within one runtime, so all your tests pass. It just is not FNV-1a, and it will not match anyone else's.

`Math.imul` exists for exactly this. It does a real thirty-two-bit multiply with wraparound, the way C would. Our reference implementation in `src/hash.ts` was proven bit-identical against a Dart original, and that proof is what makes cross-language conformance possible at all.

---

# Commands are the only way in

Nothing mutates simulation state except an applied command.

- A key press → a command
- A remote peer's input → a command
- A language model's reply → **a command**

All three go into one **ordered, append-only log**.

> If it did not come through the log, it did not happen.

NOTES:
Now the structural idea, and it is the one that makes everything else collapse together.

Your simulation has exactly one door. Things do not happen to the world; commands are appended to a log and the log is applied. Player input becomes a command. A remote peer's input arrives as a command. And a language model's reply — the text it generated, whenever it happened to arrive — becomes a command too.

The quote at the bottom is the invariant. If some code somewhere reaches in and sets a health value directly, without going through the log, then your replay will not reproduce it and your peers will not know about it. One door.

---

# Why the model does not break replay

The model is nondeterministic. **The recorded reply is not.**

- Live: ask the model, get text, **append it to the log** as a command
- Replay: read the command out of the log. The model is never called.
- The simulation only ever sees the recorded text — which is fixed

This is **exactly** how lockstep handles a remote player: you do not simulate them, you receive what they did.

NOTES:
And here is the payoff.

People assume a language model inside a game destroys reproducibility, because models are nondeterministic — same prompt, different answer, and you cannot even rely on temperature zero across versions.

But look at what actually crosses the boundary. During live play you call the model, it returns some text, and you append that text to the command log. What the simulation consumed was the text — not the model, not the call, not the sampling.

During replay you do not call the model at all. You read the recorded reply out of the log and apply it, exactly as it was. The simulation cannot tell the difference, because from inside the simulation there is no difference.

Now read the last line, because this is the elegant part. This is not a special mechanism invented for language models. It is identical to how lockstep netcode handles a remote human: you never simulate the other player, you receive what they did and apply it. A remote peer and a language model are the same shape of problem, and the command log solves both at once.

Three requirements in the course catalogue — replay, multiplayer, and a generative model — collapse into one seam. That is what good architecture looks like from the inside.

---

# What a conformance vector is

![](conformance-vectors-anatomy.svg)

NOTES:
Last piece, and it is how your spec section gets graded.

A vector pins every input: a seed, an ordered list of commands, a number of ticks, and the state hash that must result. Inputs fully specified means the only remaining variable is the implementation.

So when two independent builds run the same vector and produce different hashes, that is not a mystery. Exactly one thing differed — how each build read your prose. The disagreement is evidence that your section permitted two readings.

That is why I keep saying divergence is not blame. It is the only feedback loop that tells you whether what you wrote says what you meant. Nothing else in writing does this. You cannot compile an essay.

---

# Before Thursday

- **Grep your week-one game** for `Math.random` and `Date.now`. Count them.
- Could that build produce a replay? Be honest.
- We found **rounding**. Integer division and string comparison are two more. **What is a fourth** — and how would you pin it in prose?
- Read `spec/S02-determinism.md` and `spec/S03-command-model.md`

Thursday, AI: **Skills** — and why your first one will never fire.

NOTES:
Three things.

Grep your game and count. Every one of those is a place the simulation can see something the replay cannot reproduce. I am not expecting zero — I am expecting you to know the number.

The third one is the actual homework, and it is the discussion we open with. We pinned rounding. Integer division on negatives is another — some languages truncate toward zero, some floor. String comparison is a third, because sort order depends on collation. I want a fourth from you, and more importantly I want the sentence you would write in a spec to eliminate it. That sentence is the skill this whole course is teaching.

Thursday is skills — the Claude Code kind. Forge 02 is due on the twenty-first, and the reason most first attempts never fire once is worth half an hour.
