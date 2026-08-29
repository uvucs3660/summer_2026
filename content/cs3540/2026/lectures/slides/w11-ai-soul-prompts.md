---
track: ai
week: 11
title: Soul Prompts
subtitle: Ranked Values, and Why an Unranked List Decides Nothing
runtime: 16
---

NOTES:
Week eleven, AI track.

Short one, and it is mostly a single idea: a list of values that does not rank them has not said anything. It has expressed a mood.

That sounds like a small point. It is the difference between a document that changes what an agent does and a document that sits at the top of every context window being agreeable.

Forge 07 is a soul prompt, due November ninth.
---

# What you'll know after this

- What an agent **without** a point of view drifts toward
- Why values must be **ranked**, not listed
- How to write a ranking that actually resolves something
- Where a soul sits relative to hooks — and what each can and cannot do

NOTES:
Four things. The last one connects this back to hooks in week six, and it sets up the capstone in three weeks, where you have to show the difference working.
---

# Without a point of view

An agent with no stated values drifts toward **the average of its training data.**

- Helpful, generic, reasonable
- Aligned with **no one in particular**
- Fine for a one-off question

Inadequate for anything acting on your behalf **repeatedly.**

NOTES:
Start with what you get by default, because default is not neutral. People say an agent without a soul prompt has no values. It has values. They are somebody else's, averaged.

An agent with no stated point of view lands near the centre of everything it was trained on, and that centre is a describable position: helpful, hedging, fond of the conventional option, agreeable, more likely to add a caveat than to make a call.

For a one-off question that is exactly right. You want the consensus answer, because on a question you know nothing about, consensus is the best estimate available.

For something acting on your behalf repeatedly it is inadequate, and the reason is arithmetic rather than philosophy. Your project is not the average project. Your codebase has a house style that most codebases do not have. Your course has a standard — unambiguous over clear — which is the default preference nowhere.

A soul prompt is how you say which particular thing this agent is, instead of accepting the average of all of them.
---

# Rank them

![](soul-sovereign-council-ranked-values.svg)

NOTES:
Here is the central move, and it is the whole lecture, so I am going to sit on it.

Look at the left column. Clarity, elegance, speed, rigour. Every one of those is agreeable, and I would guess every one of you would sign up for all four. Which is exactly the problem. A list nobody would disagree with cannot decide anything.

Because the moment a decision is hard, it is hard precisely because two of those are in conflict. The precise sentence is the ugly one — clarity against elegance. The rigorous approach takes three days — rigour against speed. If both are merely listed, the agent has nothing to choose with, so it chooses by feel, and choosing by feel means choosing by training-data average, which is the exact thing the document was written to escape.

The right column resolves it. Unambiguous beats rigorous beats clear beats elegant. Now unambiguous over elegant is an instruction with teeth: when the precise sentence is the ugly one, ship the ugly sentence.

The whole purpose of a value system is resolving conflicts, and a tie is precisely the case where you needed an answer. An unranked list is decoration.
---

# Writing one that works

For each pair that could conflict, write the sentence that resolves it:

- "**Unambiguous over elegant** — ship the ugly sentence."
- "**Correct over fast** — except in a spike, where the reverse holds."
- "**Say what you did not do.** Silence about scope is a failure."

Test it: find a decision you made recently that felt hard. **Does the ranking predict what you chose?**

NOTES:
The practical method, and it is mechanical.

Do not write a values list. Write the resolutions. For every pair of things you care about that can pull in opposite directions, write the one sentence that says what happens when they do. That sentence is the unit. The adjective never was.

Notice the second example has an exception inside it, and that is not a weakness. Exceptions are how you encode context. Correct over fast, except during a spike, where the whole point is learning per hour rather than shipped code — which is the Prototyper archetype from week five, arriving as a subordinate clause.

The third example is a different species. It is a value about reporting rather than about building. Say what you did not do. That is an anti-goal in disguise, and it exists to prevent one specific and extremely plausible failure: a confident summary, every sentence of which is true, that never mentions the part that got skipped.

Then test it, and this is the step that turns the document into something real. Take a decision you actually made in the last month that felt hard at the time. Run the ranking against it. If the ranking does not predict what you chose, then either the ranking is wrong or the choice was, and either way you now know something you did not know before you wrote it down.
---

# A soul is not a hook

**Soul** — makes it *want* to behave. Reasoning, persuadable in principle, applies everywhere.

**Hook** — makes misbehaviour *impossible*. Deterministic, not persuadable, applies where you installed it.

You need both. A soul with no hooks is a hope. Hooks with no soul is a maze of walls with no map.

NOTES:
And the boundary, because people reach for one of these when the situation called for the other.

A soul shapes what an agent wants. It applies everywhere, including to situations you never anticipated, and that is its one great advantage: you cannot write a hook for a case you did not imagine, but a well-ranked value system will generalise into it.

It is influence, though, and influence is not enforcement. A sufficiently good argument can talk past a soul. Sometimes it should.

A hook is the opposite on every axis. Deterministic. Not persuadable. And it applies exactly where you installed it and nowhere else. Exit two, and the call does not happen, no matter how good the reasoning was.

You need both, and the last line says why. A soul with no hooks is a statement of intent with nothing behind it. Hooks with no soul is a set of walls with no explanation, and an agent that hits one learns only that it cannot go that way. Never what you wanted.

In three weeks the capstone makes you demonstrate exactly this: one thing declined by the soul, one thing blocked by a hook, side by side.
---

# Forge 07 — due Sun Nov 9

- A soul prompt for **an agent you actually use**
- Values **ranked**, with the conflict-resolving sentence for each pair that can conflict
- Test it against a **real decision** you already made — does it predict your choice?
- Read `cheatsheet-soul-sovereign-council`

Next Tuesday, Game: **Story** — narrative, and a model inside a frame budget.

NOTES:
Forge 07, November ninth.

Write it for an agent you actually use, so that the conflicts in it are conflicts you have actually had. Souls written for imaginary agents come out as inspirational posters — true, uplifting, and incapable of deciding anything.

And do the test in the third bullet honestly. The interesting outcome is not the one where the ranking predicts your choice. It is the one where it does not, because then you have found either a value you hold and never wrote down, or a decision worth revisiting.

Next Tuesday is narrative, and it carries the hardest engineering constraint in this course: a language model that takes two seconds, running inside a budget of sixteen milliseconds.