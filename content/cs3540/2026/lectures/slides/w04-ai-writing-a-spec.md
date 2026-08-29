---
track: ai
week: 4
title: Writing a Spec an Agent Can Build
subtitle: The Difference Between Clear and Unambiguous
runtime: 20
---

NOTES:
Week four, AI track, and this is the lecture that names the actual skill this course exists to teach.

The syllabus claims that a complete, playable game is roughly one prompt away, and that the scarce skill is no longer typing an A-star implementation from memory but specifying a system precisely enough that what comes back is correct. Everything else in this course is downstream of that claim. This is where we make good on it.

There is no class on Thursday — Campus Closure — so watch this on your own and bring it to the fifteenth. Watch it before Sunday, though, not after. You are claiming a section of the specification this Sunday, and this is the lecture that tells you what you are agreeing to write.

---

# What you'll know after this

- Why **clear** and **unambiguous** are different words, and only one of them is the bar
- The **second-language test**, and what it rules out
- The four things you must name **wherever a reasonable implementer could choose differently**
- Why a claim with no **conformance vector** is an opinion

NOTES:
Four things, and the first one is the whole lecture compressed into a distinction between two words.

Almost everyone writing a specification is aiming at clear. Clear is a fact about a reader understanding you. Unambiguous is a fact about a reader having no legal alternative. Those are different targets, they feel identical while you are writing, and only the second one survives contact with an implementation you did not supervise.

---

# Clear is not the bar

**Clear** — a careful reader understands what you meant.

**Unambiguous** — a careful reader has **no other legal choice**.

> "Round the position to three decimal places."

Perfectly clear. Every one of you understood it. It is also ambiguous, and it already cost this course a bug.

NOTES:
Read the quote and notice that you understood it instantly. There is nothing confusing in that sentence. Put it in front of a hundred engineers and a hundred of them go and implement it.

And it is ambiguous, because it never says which way ties round. Negative zero point five: does that become negative zero, or negative one? JavaScript says one thing. Dart says another. Both of them are correct implementations of round the position to three decimal places, and that is the trouble — not that one of them is wrong, but that neither of them is.

That is the whole gap. Clear is a property of understanding. Unambiguous is a property of the set of legal implementations, and it means that set has exactly one member in it.

Which tells you why the usual instinct fails. You cannot reach unambiguous by writing more clearly. Clearer prose closes no legal alternatives; it only makes the reader more confident while they pick one. You get there by hunting the choices you left open and closing them one at a time.

---

# Where ambiguity hides

![](writing-a-spec-agents-can-build-ambiguity.svg)

NOTES:
This is your cheat-sheet diagram for the week, and it is a field guide to the phrases that feel finished and are not.

Read them and notice the pattern. Every one of these is a sentence you would write without hesitating, and every one of them hands a decision to whoever implements it. Sorted — by what key, in which direction, and what happens to ties. Between — inclusive at both ends, or at neither, or at one. Some, or any — is zero of them allowed?

These are not sloppy sentences, and that is exactly what makes them dangerous. They are ordinary English, and ordinary English is built for readers who will use judgement. A specification is a promise that no judgement is required.

You will not catch these by proofreading, either, because proofreading is reading, and reading is the one activity these sentences are good at surviving.

---

# The second-language test

![](writing-a-spec-agents-can-build-second-language.svg)

NOTES:
Here is the test S00 gives you, and it is the single most useful check in this lecture.

Could someone implement your section in a different language, from your prose alone, without ever reading your code?

Look at the left column, because that is what most first drafts actually are: TypeScript with sentences in between the snippets. It fails on its face. The section quietly inherits whatever JavaScript happens to do about rounding, without ever saying so. It says how rather than what. And someone building in Dart cannot follow it at all, because it is not describing a behaviour, it is exhibiting an implementation and hoping you generalise correctly.

The right column says the same things as behaviour. The scale, the rounding mode, and the tie-break, in three sentences, with no code in them at all. Two implementations in two languages cannot disagree about those three sentences.

And the line at the bottom is why the rule exists. Writing code and calling it a specification is the default failure, and it is the default because code feels precise. Code is precise about what it does. It is completely silent about what is required, and you cannot tell those two apart by looking at it.

---

# Name four things

Wherever a reasonable implementer could choose differently:

1. **The rounding** — half up, half down, half away from zero, toward zero
2. **The units and scale** — ×1000, and of what
3. **The tie-break** — two entities at equal distance: which one?
4. **The order** — iteration order, sort key, and direction

> Ambiguity is the defect this course measures.

NOTES:
So here is the checklist, and it is short enough to run over every paragraph you write, which is the only reason anybody ever actually runs it.

Rounding, because languages disagree and we already have the scar to prove it. Units and scale, because position is not a number until you say position in what. Tie-break, because two entities at equal distance happen constantly in pathfinding and in collision, and somebody has to lose. And order, because two correct programs that iterate differently produce different hashes, which was Tuesday's third leak.

Run those four questions over every claim in your section. Most of the time the answer is that it genuinely cannot matter here, and you move on in four seconds. When the answer is hmm, stop. You have just found the thing that would otherwise have arrived as a divergence report in October, with your name on it.

That last line is a sentence from S00, and it is a statement about grading. Not clarity. Not elegance. Not completeness. Ambiguity is the measured defect.

---

# A claim with no vector is an opinion

Every normative statement needs an executable one.

```json
{ "id": "S01/fixed-timestep-accumulator",
  "seed": 12345, "commands": [], "ticks": 5,
  "expect": { "stateHash": 4229369801 } }
```

Inputs fully pinned → the **only** remaining variable is the implementation.

So when two builds disagree, exactly one thing differed: **how each read your prose.**

NOTES:
And this is the mechanism that makes all of it checkable, which is the part that makes the course possible at all.

A vector pins the seed, the commands, and the tick count, and states the hash that must come out the other end. Everything that could vary is nailed down except the implementation itself.

So a disagreement is not a mystery to be investigated. It is a measurement. Two builds, one input, two answers means your prose admitted two readings, and the vector tells you which claim was the ambiguous one.

I want you to sit with how unusual that is. You cannot compile an essay. You cannot unit-test a design document. Nobody has ever run your writing and handed you back a number saying it was wrong. This is the rare case where writing has a build step, and the build either agrees with itself or it does not.

---

# The loop this sits inside

![](ai-sdlc-spec-driven-pipeline.svg)

NOTES:
Step back and see where specification sits in the whole cycle, because this is also the shape of every Forge assignment and, frankly, of how you should work for the rest of your career.

Explore first. Read-only, no edits, understand before proposing anything. Then the specification: behaviour, interfaces, non-goals, acceptance criteria. Then the plan, which is the how, sequenced into steps small enough to verify one at a time. Then execution, one step, then the next one.

The failure everybody has is starting at execution. It feels fast. It produces something in ten minutes. Then you spend three hours discovering that the thing you asked for was not the thing you needed, and the three hours are not the real cost. The real cost is that you now have working code you are attached to, pointed in the wrong direction.

Forge 06 later in the term makes you walk the whole loop deliberately. But you can start this week, because the section you claim on Sunday is a specification, and you are about to write one for real.

---

# Before you claim

- **Claim your section by Sun Sep 13** — `spec/OWNERS.md`, first claim wins
- Read `spec/S00-overview.md`, all 108 lines — it is the contract you are writing against
- Read one existing section (`S01`, `S02`, or `S03`) as a **model of the form**
- Read `cheatsheet-writing-a-spec-agents-can-build`

No class Thursday Sep 10. Back Tuesday the 15th: **Patterns and the Component Store**, and **Subagents**.

NOTES:
Four things before Sunday.

Claim your section. Read S00 in full. And read one of the instructor sections end to end — not for what it says, for the shape of it. Notice how much of S02 is spent naming things that could have gone either way and then closing them. That density is the target, and it will feel excessive while you are writing your own. It is not.

I will say one more thing, and it is the reason I care about this lecture more than most of the others.

Every one of you can already write clearly. You have been graded on clear writing since you were eleven, by readers who were filling in your gaps on purpose. Almost none of you have been asked to write unambiguously, because almost nothing in school measures it. A human reader closes the gap automatically, silently, and generously, and you never find out the gap was there.

An independent build does not fill gaps. It picks something. And that is the first time in your education that the difference between clear and unambiguous will show up as a number that disagrees with another number.

That is worth the semester on its own.