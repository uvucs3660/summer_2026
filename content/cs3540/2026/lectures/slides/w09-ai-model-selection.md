---
track: ai
week: 9
title: Model Selection
subtitle: Choosing by the Cost of Being Wrong
runtime: 15
---

NOTES:
Week nine, AI track, and this is the shortest lecture in the term because the idea is small. It is also the one that will save you the most money and the most time, which is an unusual combination.

There is no class this Thursday — fall break — so this stands alone alongside the 3D lecture.

---

# What you'll know after this

- Why "is this hard?" is the **wrong question**
- The three tiers, and what each is genuinely for
- Why a cheap model on a reversible task is **not** a compromise
- Where fan-out changes the arithmetic entirely

NOTES:
Four things. The first is a reframe, same shape as the MCP lecture two weeks ago — replace an unanswerable question with an answerable one.

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

"Is this hard" fails because difficulty is only visible in retrospect. Plenty of tasks that look trivial turn out to have a subtlety, and plenty that look intimidating are mechanical once you see them.

But you always know the cost of being wrong, before you start. That is a property of the task's position in your system, not of the task's difficulty.

A rename across forty files: if it is wrong, the compiler tells you in four seconds and you undo it. Cheap to detect, cheap to redo.

A design decision you will build on for a month: if it is wrong, you find out in three weeks, when unwinding it means unwinding everything built on top. Expensive to detect *and* expensive to undo.

Those two deserve different tiers, and the difference has nothing to do with which is harder.

---

# The three tiers

![](cc-model-selection-cost-of-wrong.svg)

NOTES:
Read it across.

Bottom row of the reasoning, top row of the diagram: cheap to detect, cheap to redo. Mechanical edits, bulk renames, well-specified transformations with a clear right answer. A fast tier is not a compromise here — it is the correct tool, and using the strongest model is simply slower and more expensive for an identical result.

Middle: expensive to detect. Design work, ambiguous problems, anything where a plausible-but-wrong answer will survive review because it looks reasonable. This is what the strongest tier is for, and it is worth every cent, because the failure mode is not "wrong" — it is "wrong and convincing."

Bottom: expensive to undo. Schemas, public interfaces, anything other people will build against. Spend, and get a second opinion — which in this course means the Council, in three weeks.

---

# Fan-out changes the arithmetic

A subagent's work happens in a context **you never pay for.**

So: dispatch a **cheap** model to read ninety-five files and summarise, then hand the summary to an **expensive** one to reason over.

- The expensive tier never sees the ninety-five files
- You bought its attention for the part that needed judgement

**Tier per task, not per session.**

NOTES:
And here is where the two AI lectures compose.

Week five: a subagent's reading happens in a context you never carry. Combine that with tiers and you get the pattern that actually matters in practice.

Send a fast model to do the reading. Ninety-five files, grep-and-summarise, mechanical work with a clear right answer — exactly the top row. It returns a paragraph.

Then hand that paragraph to the strongest tier and ask the question that needs judgement. It never sees the ninety-five files. You paid for cheap attention on the bulk and expensive attention on the decision.

Read the last line, because it is the habit to build. People pick a model when they start a session and stay there all day. The unit of choice is the task, not the session — and when you are orchestrating subagents, you get to choose per agent.

---

# Before Tuesday

- Look at your last week of work. **Which tasks were reversible?**
- Try the cheapest tier on one of those. Notice whether the result differs.
- Read `cheatsheet-cc-model-selection`

**Fall break** — Oct 15–18. Nothing is due.
Back Tuesday Oct 20: **Minds**, then **Spec → Plan → Execution** (Forge 06, due Nov 2).

NOTES:
One exercise, and it is genuinely worth ten minutes.

Look back at your last week and sort the tasks by reversibility rather than difficulty. Most people find that the large majority were reversible — mechanical, checkable, cheap to redo — and that they used the strongest model for all of them out of habit.

Then try the cheapest tier on one of the reversible ones and see whether you can tell the difference in the output. Sometimes you can. Usually, on that kind of task, you cannot, and that is a useful thing to have measured for yourself rather than been told.

Enjoy the break. Nothing is due. When we come back it is pathfinding, and the fourth appearance of a bug you have now met three times.
