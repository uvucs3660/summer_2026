---
track: ai
week: 11
title: Soul Prompts
subtitle: Ranked Values, and Why an Unranked List Decides Nothing
runtime: 16
---

NOTES:
Week eleven, AI track.

This one is short and it is mostly about one idea: that a list of values which does not rank them has not said anything.

Forge 07 is a soul prompt, due November ninth.

---

# What you'll know after this

- What an agent **without** a point of view drifts toward
- Why values must be **ranked**, not listed
- How to write a ranking that actually resolves something
- Where a soul sits relative to hooks — and what each can and cannot do

NOTES:
Four things. The last one connects this to week six and sets up the capstone in three weeks.

---

# Without a point of view

An agent with no stated values drifts toward **the average of its training data.**

- Helpful, generic, reasonable
- Aligned with **no one in particular**
- Fine for a one-off question

Inadequate for anything acting on your behalf **repeatedly.**

NOTES:
Start with what you get by default, because default is not neutral.

An agent with no stated point of view lands somewhere near the centre of everything it was trained on. That is a real position — it is helpful, it hedges, it prefers the conventional option, it is agreeable.

For a one-off question that is exactly right. You want the consensus answer.

For something acting on your behalf repeatedly, it is inadequate, because your project is not the average project. Your codebase has a house style. Your course has a standard — unambiguous over clear, which is not the default preference anywhere.

A soul prompt is how you say which particular thing this agent is, rather than accepting the average.

---

# Rank them

![](soul-sovereign-council-ranked-values.svg)

NOTES:
Here is the central move.

Look at the left column. Clarity, elegance, speed, rigour. Every one of those is agreeable, and I would guess most of you would sign up for all four. That is exactly the problem: a list nobody would disagree with cannot decide anything.

Because the moment a decision is hard, it is hard *precisely because* two of those are in conflict. The precise sentence is ugly — clarity versus elegance. The rigorous approach is slow — rigour versus speed. If both are simply listed, the agent has no basis to choose, so it picks by feel, which means it picks by training-data average, which is what we were trying to avoid.

The right column resolves it. Unambiguous beats rigorous beats clear beats elegant. Now "unambiguous over elegant" is an instruction with teeth: when the precise sentence is ugly, ship the ugly sentence.

The whole purpose is resolving conflicts, and a tie is exactly where you needed an answer. An unranked list is decoration.

---

# Writing one that works

For each pair that could conflict, write the sentence that resolves it:

- "**Unambiguous over elegant** — ship the ugly sentence."
- "**Correct over fast** — except in a spike, where the reverse holds."
- "**Say what you did not do.** Silence about scope is a failure."

Test it: find a decision you made recently that felt hard. **Does the ranking predict what you chose?**

NOTES:
The practical method.

Do not write a values list. Write the resolutions — the sentences that say what happens when two things you care about pull apart.

Notice the second one has an exception in it, and that is fine. Exceptions are how you encode context. Correct over fast, except during a spike where the whole point is learning per hour — which is the Prototyper archetype from week five, showing up as a clause.

And the third example is a different kind: a value about reporting rather than building. "Say what you did not do" is an anti-goal in disguise, and it prevents the specific plausible failure of a confident summary that omits the part that was skipped.

Then test it, and this is the step that makes it real. Take a decision you actually made in the last month that felt hard. Run your ranking against it. If the ranking does not predict what you chose, then either the ranking is wrong or your choice was — and either way you have learned something you did not know before you wrote it down.

---

# A soul is not a hook

**Soul** — makes it *want* to behave. Reasoning, persuadable in principle, applies everywhere.

**Hook** — makes misbehaviour *impossible*. Deterministic, not persuadable, applies where you installed it.

You need both. A soul with no hooks is a hope. Hooks with no soul is a maze of walls with no map.

NOTES:
And the boundary, which matters because people reach for one when they need the other.

A soul shapes what an agent wants. It applies to everything, including situations you never anticipated, which is its great strength — you cannot write a hook for a case you did not imagine, but a well-ranked value system will generalise to it.

And it is influence. A sufficiently good argument can talk past it, and sometimes should.

A hook is the opposite on every axis. It is deterministic, it is not persuadable, and it only applies exactly where you installed it. Exit two and the call does not happen, no matter how good the reasoning was.

You need both, and the last line is why. A soul with no hooks is a statement of intent with nothing enforcing it. Hooks with no soul is a set of walls with no explanation, and an agent that hits one has no idea what you actually wanted — it just knows it cannot go that way.

In three weeks the capstone makes you demonstrate exactly this difference: something declined by the soul, and something blocked by a hook, side by side.

---

# Forge 07 — due Sun Nov 9

- A soul prompt for **an agent you actually use**
- Values **ranked**, with the conflict-resolving sentence for each pair that can conflict
- Test it against a **real decision** you already made — does it predict your choice?
- Read `cheatsheet-soul-sovereign-council`

Next Tuesday, Game: **Story** — narrative, and a model inside a frame budget.

NOTES:
Forge 07, November ninth.

Write it for an agent you actually use, so that the conflicts are real conflicts and not hypotheticals. Souls written for imaginary agents come out as inspirational posters.

And do the test in the third bullet honestly. The interesting outcome is when the ranking does not predict your choice, because then you have found either a value you hold and did not write down, or a decision you should revisit.

Next Tuesday is narrative, and it contains the hardest engineering constraint in the course: a language model that takes two seconds, inside a budget of sixteen milliseconds.
