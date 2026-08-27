---
track: ai
week: 4
title: Writing a Spec an Agent Can Build
subtitle: The Difference Between Clear and Unambiguous
runtime: 20
---

NOTES:
Week four, AI track, and this is the lecture that names the actual skill this course exists to teach.

The syllabus claims that a complete, playable game is roughly one prompt away, and that the scarce skill is no longer typing an A-star implementation but specifying a system precisely enough that what comes back is correct. This is that lecture.

There is no class on Thursday — Campus Closure — so watch this on your own and bring it to the fifteenth. You need it before you write your section, and you are claiming that section this Sunday.

---

# What you'll know after this

- Why **clear** and **unambiguous** are different words, and only one of them is the bar
- The **second-language test**, and what it rules out
- The four things you must name **wherever a reasonable implementer could choose differently**
- Why a claim with no **conformance vector** is an opinion

NOTES:
Four things, and the first one is the whole lecture in a distinction.

Most people writing a specification are aiming at clear. Clear is about a reader understanding you. Unambiguous is about a reader having no legal alternative. Those are very different targets and only the second one survives contact with independent implementations.

---

# Clear is not the bar

**Clear** — a careful reader understands what you meant.

**Unambiguous** — a careful reader has **no other legal choice**.

> "Round the position to three decimal places."

Perfectly clear. Every one of you understood it. It is also ambiguous, and it already cost this course a bug.

NOTES:
Read the quote and notice that you understood it instantly. There is nothing confusing in that sentence. If I put it in front of a hundred engineers, a hundred would say "yes, fine, got it."

And it is ambiguous, because it does not say which way ties round. Negative zero point five: does that become negative zero, or negative one? JavaScript says one thing. Dart says another. Both are correct implementations of "round to three decimal places."

That is the whole gap. Clear is a property of understanding. Unambiguous is a property of the set of legal implementations — and it means that set has exactly one member.

You cannot get to unambiguous by writing more clearly. You get there by hunting for the choices you left open.

---

# Where ambiguity hides

![](writing-a-spec-agents-can-build-ambiguity.svg)

NOTES:
This is your cheat-sheet diagram for the week, and it is a field guide to the phrases that feel finished and are not.

Read them and notice the pattern. Every one of these is a sentence you would write without hesitating, and every one leaves a decision to whoever implements it. "Sorted" — by what, which direction, and what happens to ties. "Between" — inclusive at both ends, or neither, or one. "Some" or "any" — is zero of them allowed?

These are not sloppy sentences. They are ordinary English, which is exactly the problem: ordinary English is built for readers who will use judgement, and a specification is a promise that no judgement is required.

---

# The second-language test

![](writing-a-spec-agents-can-build-second-language.svg)

NOTES:
Here is the test S00 gives you, and it is the most useful single check in this lecture.

Could someone implement your section in a different language, from your prose alone, without reading your code?

Look at the left column. That is what most first drafts are: TypeScript with sentences between the snippets. It fails on its face — the section inherits whatever JavaScript happens to do about rounding, it says how rather than what, and someone building in Dart cannot follow it because it is not describing behavior, it is exhibiting an implementation.

The right column says the same things as behavior. The scale, the rounding mode, and the tie-break, in three sentences with no code in them at all. Two implementations in two languages cannot disagree about those.

And the line at the bottom is why the rule exists. Writing code and calling it a specification is the default failure, because code feels precise. Code is precise about what it does. It is silent about what is required.

---

# Name four things

Wherever a reasonable implementer could choose differently:

1. **The rounding** — half up, half down, half away from zero, toward zero
2. **The units and scale** — ×1000, and of what
3. **The tie-break** — two entities at equal distance: which one?
4. **The order** — iteration order, sort key, and direction

> Ambiguity is the defect this course measures.

NOTES:
So here is the checklist, and it is short enough to run over every paragraph you write.

Rounding, because languages disagree and we have the scar to prove it. Units and scale, because "position" is not a number until you say position in what. Tie-break, because equal-distance cases happen constantly in pathfinding and collision and somebody has to lose. And order, because two correct programs that iterate differently produce different hashes — which was Tuesday's third leak.

Run those four questions over every claim in your section. Most of the time the answer is "it genuinely cannot matter here," and you move on. When the answer is "hmm," you have just found the thing that would have shown up in a divergence report in October.

That last line is a sentence from S00, and it is a statement about grading. Not clarity, not elegance, not completeness. Ambiguity is the measured defect.

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
And this is the mechanism that makes all of it checkable.

A vector pins the seed, the commands, and the tick count, and states the hash that must come out. Everything that could vary is nailed down except the implementation itself.

So a disagreement is not a mystery to be investigated. It is a measurement. Two builds, one input, two answers means your prose admitted two readings, and the vector tells you which claim was the ambiguous one.

I want you to appreciate how unusual this is. You cannot compile an essay. You cannot unit-test a design document. This is the rare case where writing has a build step, and the build either agrees with itself or it does not.

---

# The loop this sits inside

![](ai-sdlc-spec-driven-pipeline.svg)

NOTES:
Step back and see where specification sits in the whole cycle, because this is also the shape of every Forge assignment and, frankly, of how you should work for the rest of your career.

Explore first, read-only, no edits — understand before proposing. Then the specification: behavior, interfaces, non-goals, acceptance criteria. Then the plan, which is the *how*, sequenced into steps small enough to verify independently. Then execution, one step at a time.

The failure everybody has is starting at execution. It feels fast, and it produces something in ten minutes, and then you spend three hours discovering the thing you asked for was not the thing you needed. Forge 06 later in the term makes you do the whole loop deliberately, but you can start now — because the section you claim this Sunday is a specification, and you are about to write one for real.

---

# Before you claim

- **Claim your section by Sun Sep 13** — `spec/OWNERS.md`, first claim wins
- Read `spec/S00-overview.md`, all 108 lines — it is the contract you are writing against
- Read one existing section (`S01`, `S02`, or `S03`) as a **model of the form**
- Read `cheatsheet-writing-a-spec-agents-can-build`

No class Thursday Sep 10. Back Tuesday the 15th: **Patterns and the Component Store**, and **Subagents**.

NOTES:
Four things before Sunday.

Claim your section. Read S00 in full. And read one of the instructor sections end to end — not for its content, for its shape. Notice how much of S02 is spent naming things that could have gone either way. That density is the target.

I will say one more thing, and it is the reason I care about this lecture more than most.

Every one of you can already write clearly. You have been graded on clear writing since you were eleven. Almost none of you have been asked to write unambiguously, because almost nothing in school measures it — a human reader fills gaps automatically and generously, and you never find out the gap was there.

An independent build does not fill gaps. It picks something. And that is the first time in your education that the difference between clear and unambiguous will show up as a number that disagrees with another number.

That is worth the semester on its own.
