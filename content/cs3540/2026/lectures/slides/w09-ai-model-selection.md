---
track: ai
week: 9
title: Model Selection
subtitle: Choosing by the Cost of Being Wrong
runtime: 15
---

NOTES:
Week nine, AI track. This is the shortest lecture in the term, because the idea is small. It is also the one that will save you the most money and the most time, which is an unusual combination.

Here is the habit it is aimed at. You open a session in the morning, you pick the strongest model available to you, and then you stay there until you go to bed. Renaming a variable. Reformatting a file. Answering a question you already knew the answer to. And it works every time, so nothing ever tells you to stop.

That is exactly why the habit survives. There is no error message for spending a great deal to get an identical result.

There is no class this Thursday — fall break — so this stands alone alongside the 3D lecture.

---

# What you'll know after this

- Why "is this hard?" is the **wrong question**
- The three tiers, and what each is genuinely for
- Why a cheap model on a reversible task is **not** a compromise
- Where fan-out changes the arithmetic entirely

NOTES:
Four things. The first is a reframe, the same shape as the MCP lecture two weeks ago, where we replaced an unanswerable question with an answerable one. That move is worth more than either lecture it turns up in.

---

# The wrong question

Most people choose a model by asking **"is this task hard?"**

That is unanswerable in advance. You do not know how hard it is until it is done.

**Ask instead: what does a wrong answer cost me?**

- Cheap to detect and cheap to redo → a fast tier is **correct**, not a compromise
- Expensive to detect → spend
- Expensive to **undo** → spend, and get a second opinion

NOTES:
Here is the reframe.

Is this hard fails as a question because difficulty is only visible in retrospect. You do not know how hard a task was until it is finished. Plenty of things that look trivial turn out to carry one subtlety that eats the morning, and plenty of things that look intimidating are mechanical the moment you see the shape of them.

But you always know the cost of being wrong, and you know it before you start. That is a property of where the task sits in your system, not a property of how difficult the task is.

Take a rename across forty files. If it is wrong, the compiler tells you in four seconds and you undo it. Cheap to detect, cheap to redo.

Now take a design decision you are going to build on for a month. If it is wrong, you find out in three weeks, and unwinding it means unwinding everything that got built on top of it in the meantime. Expensive to detect, and expensive to undo.

Those two deserve different tiers. And notice that the difference between them has nothing whatsoever to do with which one is harder.

---

# The three tiers

![](cc-model-selection-cost-of-wrong.svg)

NOTES:
Read it across.

Bottom row of the reasoning, top row of the diagram: cheap to detect, cheap to redo. Mechanical edits, bulk renames, well-specified transformations with a clear right answer. A fast tier is not a compromise here. It is the correct tool, and reaching for the strongest model is simply slower and more expensive for a result you could not pick out of a lineup.

Middle: expensive to detect. Design work, ambiguous problems, anything where a plausible but wrong answer will sail through review because it reads as reasonable. This is what the strongest tier is for, and it is worth every cent, because the failure mode here is not wrong. It is wrong and convincing. Wrong gets caught. Wrong and convincing gets merged.

Bottom: expensive to undo. Schemas, public interfaces, anything other people are going to build against. Spend, and get a second opinion — which in this course means the Council, in three weeks.

---

# Fan-out changes the arithmetic

A subagent's work happens in a context **you never pay for.**

So: dispatch a **cheap** model to read ninety-five files and summarise, then hand the summary to an **expensive** one to reason over.

- The expensive tier never sees the ninety-five files
- You bought its attention for the part that needed judgement

**Tier per task, not per session.**

NOTES:
And here is where the two AI lectures compose.

Week five: a subagent's reading happens in a context you never carry. Put that together with tiers and you get the pattern that actually matters in practice.

Send a fast model to do the reading. Ninety-five files, grep and summarise, mechanical work with a clear right answer — exactly the top row we just looked at. It comes back with a paragraph.

Then hand that paragraph to the strongest tier and ask it the question that needed judgement. It never sees the ninety-five files. You bought cheap attention for the bulk and expensive attention for the decision, and the decision was the only place the expense was ever earning anything.

Read the last line, because that is the habit to build. People choose a model when they open a session and then live there all day, the way you pick a chair. The unit of choice is the task, not the session. And once you are orchestrating subagents, you choose per agent, which means the arithmetic is yours to design rather than yours to accept.

---

# Before Tuesday

- Look at your last week of work. **Which tasks were reversible?**
- Try the cheapest tier on one of those. Notice whether the result differs.
- Read `cheatsheet-cc-model-selection`

**Fall break** — Oct 15–18. Nothing is due.
Back Tuesday Oct 20: **Minds**, then **Spec → Plan → Execution** (Forge 06, due Nov 2).

NOTES:
One exercise, and it is genuinely worth ten minutes.

Look back over your last week of work and sort the tasks by reversibility instead of by difficulty. Most people find that the large majority were reversible — mechanical, checkable, cheap to redo — and that they used the strongest model on all of them out of habit rather than out of any decision they can remember making.

Then take one of the reversible ones and run it on the cheapest tier, and see whether you can tell the difference in the output. Sometimes you can, and that is worth knowing too. Usually, on that kind of task, you cannot. And having measured that for yourself is worth a great deal more than having been told it by me.

Enjoy the break. Nothing is due. When we come back it is pathfinding, and the fourth appearance of a bug you have now met three times.
