---
track: ai
week: 5
title: Subagents
subtitle: The Five Archetypes, and Why Anti-Goals Do More Work Than Goals
runtime: 20
---

NOTES:
Week five, AI track.

Tuesday ended on state machines, and on a claim I want to pick straight back up: that making a bad outcome unrepresentable beats documenting that it is unwanted. That idea is the spine of this lecture too, in a completely different domain.

Forge 03 is a subagent, due October fifth.

---

# What you'll know after this

- The **one rule** that determines how every subagent prompt is written
- The three reasons to fan work out — and the one that matters most
- Why **anti-goals** do more work than goals
- Which of the **five archetypes** your project is currently starving for

NOTES:
Four things, and the first one is a constraint rather than a technique. Everything else follows from it, the same way the accumulator followed from "hardware must not choose the timestep."

---

# The one rule

> **A subagent cannot ask a clarifying question.** It runs once, alone, and returns.

You are not starting a conversation. You are writing a **work order** for someone unreachable.

Every ambiguity you leave is a coin flip you delegated.

NOTES:
Here is the rule, and it is the whole design constraint.

When you talk to Claude directly and you are vague, it asks. That feedback loop is so reliable you have stopped noticing it — you can be lazy in a prompt because the laziness gets caught.

A subagent has no such loop. It receives one message, runs alone in its own context, and returns once. If your instruction was ambiguous, nobody stops to check. It picks something and reports as though that was what you meant.

So the mental model is not "chatting with a helper." It is writing a work order for a contractor you cannot reach for the next twenty minutes. Every question you left unanswered is a decision you handed to someone with less context than you.

---

# Answer the questions in advance

![](cc-subagents-and-archetypes-cannot-ask.svg)

NOTES:
Look at the left prompt. "Look into the collision code." I have written that. You have written that. To a person sitting next to you it is perfectly serviceable, because they will ask.

But read the three questions underneath it, and notice they are not pedantic — they are load-bearing, and it cannot ask any of them. How much of it: the directory, the whole subsystem, everything that touches collision? In what shape: prose, a table, a list of file paths? And the dangerous one — am I allowed to edit? If you did not say no, you may get a refactor you did not ask for.

The right side answers all three before sending. Scope: this directory. Output shape: a markdown table with these columns. Boundary: do not modify anything.

That is the whole craft. Scope, shape, boundary. If you would have had to answer it for a human, answer it in the prompt.

---

# Why fan out at all

Three reasons, in increasing order of how much they matter:

1. **Parallelism** — several dispatched in one turn run at once
2. **Isolation** — a bad exploration cannot pollute your main thread
3. **Context economy** — the 95 files it read **never enter your context**

The third one is the real prize.

NOTES:
Three reasons, and people usually cite the weakest one.

Parallelism is nice. Dispatch three in one turn and they run at once instead of in sequence.

Isolation is better than it sounds. A subagent that goes down a wrong path burns its own context, not yours. You get back a summary that says the path was wrong, and your main thread never had to hold the dead end.

But the third is the one that changes how you work. A subagent that reads ninety-five files to answer a question returns you a paragraph. Those ninety-five files never enter your context — you paid for the reading inside a context you are about to throw away.

That is the same three-tier shape as skills two weeks ago, pushed one step further. Description, then body, then references — and now: a whole investigation whose cost you never carry.

---

# The economics, drawn

![](cc-subagents-and-archetypes-fanout.svg)

NOTES:
This is your cheat-sheet diagram for the week.

Three isolated contexts, three summaries back. Note the phrase at the bottom about the file reads never entering the main context — that is the sentence to remember.

And note the caveat about fanning out, because it has teeth: read-only subagents are safe to dispatch aggressively. Agents that *write* are not. Two agents editing the same file will fight, and you will get whichever write landed last with no record that the other happened. Fan out reading. Serialize writing.

---

# Anti-goals do more work

An agent told to **simplify** will helpfully add a helpful abstraction.

Not because it is wrong — because "simplify" has more than one reading, and it picked one.

- **Goal**: what you want. Necessary, and not sufficient.
- **Anti-goal**: what would count as failure *even though it looks like success*.

> Same move as the state machine on Tuesday: name what is forbidden, and it stops being reachable.

NOTES:
Now the part I think is genuinely underrated.

Tell an agent to simplify a module. It comes back having introduced a base class, a factory, and a shared helper. Line count went down. Is that simpler?

It is not wrong, exactly. "Simplify" is genuinely ambiguous — fewer lines, fewer concepts, fewer files, fewer branches — and those pull against each other. It picked one reading and pursued it well.

The fix is not a better goal. The fix is an anti-goal: do not introduce new abstractions; if the result has more concepts than it started with, that is failure even if it has fewer lines.

Read the definition on the slide again. An anti-goal names the failure that *looks like success*. Those are the only failures worth writing down, because the ones that look like failure get caught for free.

And this is Tuesday's state machine argument again. Booleans let you represent "dead and jumping." A goal without an anti-goal lets an agent represent "simplified by adding architecture." In both cases the fix is to say out loud what is not allowed.

---

# The five archetypes

![](cc-subagents-and-archetypes-five.svg)

NOTES:
The claim behind this table is that engineering roles are collapsing into five shapes. Whether or not you buy the sociology, the five make excellent subagents, and the reason is the right-hand column.

Read them across. Prototyper maximises learning per hour, and its anti-goal is never extend past the question — because a spike that turns into a feature has stopped being a spike and you have lost the thing you were buying, which was speed.

Builder takes "works on my machine" to production, and must not gold-plate or ship untested. Sweeper reduces complexity while preserving behaviour, and must not add features mid-sweep — that anti-goal alone would prevent most bad refactor pull requests I have ever reviewed.

Grower moves activation and retention, and its output is metric movement, not pull requests. Maintainer holds availability, integrity and confidentiality, and must not become the department of no.

Notice every anti-goal describes a plausible, well-intentioned failure. Nobody sets out to gold-plate. That is precisely why it needs writing down.

---

# Which one are you starving for?

Look at your project honestly this week:

- Drowning in half-finished spikes? You need a **Sweeper.**
- Nothing ever ships? You need a **Builder.**
- Building confidently in a direction nobody validated? You need a **Prototyper.**
- Everything works and nobody plays it? **Grower.**
- One outage from losing the term's work? **Maintainer.**

Write that one. This week. It is Forge 03.

NOTES:
Here is the practical exercise, and it is also the discussion we open class with.

Look at your project and diagnose it. Most of you will find you have been playing one archetype exclusively, because it is the one you enjoy.

If your repository is full of half-finished experiments, you have been Prototyping for three weeks and you need a Sweeper. If nothing ever reaches a state you would show someone, you need a Builder. If you are eight commits into a system nobody has validated is worth having, you skipped Prototyper and need to go back.

The starving archetype is the one to write as a subagent, because a subagent is exactly a way to make yourself do the work you keep not doing. It has a mission you did not feel like adopting and anti-goals that stop it drifting back toward the thing you would rather be doing.

---

# Forge 03 — due Sun Oct 5

- A subagent for the archetype **your project is starving for**
- **Explicit anti-goals** — and at least one that names a plausible failure
- Scope, output shape, boundary — all answered before it runs
- Show a run where the anti-goal **actually changed the output**

Read `cheatsheet-cc-subagents-and-archetypes`.

Next Tuesday, Game: **Pixels** — transforms and 2D rendering.

NOTES:
Forge 03, due October fifth.

The fourth bullet is the graded one and it is the hard one. Show me a run where an anti-goal changed the result — where without it you would have got something worse, and you can show me both.

That is harder than writing the subagent, and it is the whole point. An anti-goal you never see fire is an anti-goal you guessed at. An anti-goal that visibly stopped a plausible wrong turn is evidence you understood the failure mode before it happened.

That is the same standard as the conformance vector, incidentally. A claim with no vector is an opinion. An anti-goal with no run that exercises it is a wish.

Next Tuesday we start rendering, which is the first week where things appear on screen and the course briefly looks like a game programming course.
