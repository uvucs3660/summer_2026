---
track: ai
week: 10
title: Spec, Plan, Execution
subtitle: Why Starting at Execute Feels Fast for Ten Minutes
runtime: 18
---

NOTES:
Week ten, AI track.

This is the lecture that puts the whole AI track in order. Everything you have built so far — CLAUDE.md, skills, subagents, hooks, MCP — those are components. Good ones. But a pile of good components is not a way of working, and most people who own all five of those still start a feature exactly the way they did before they had any of them. They open a session and say, build me the thing.

This is the loop the components sit inside. Four phases, three of which produce no code at all, and the one that does produce code is the shortest of the four.

Forge 06 is running that loop deliberately, and it is due November second.

---

# What you'll know after this

- The four phases, and what each one **produces**
- Why a plan step must end in something you can **run**
- Why one step per session is a **context** decision, not a discipline one
- What starting at Execute actually costs

NOTES:
Four things. The third is the one people skip, because it looks like process advice — the kind of line you nod at and then ignore. It is not process advice. It is an engineering constraint about context, and skipping it costs you output quality directly.

---

# The loop

![](ai-sdlc-spec-driven-pipeline.svg)

NOTES:
Four phases, and every one of them has an output that is not code.

Explore is read-only. No edits, deliberately. The constraint is there because the moment you are allowed to edit, you start editing, and the moment you start editing you have stopped understanding. The output of Explore is options and a decision.

Specification: behavior, interfaces, non-goals, acceptance criteria. You have been writing one of these all term for your own section, so you already know the shape of it. Notice that non-goals are on the list. That is the anti-goal idea from week five, moved out of a prompt and into a document, where it survives past the end of the session.

Plan is the how, sequenced. Execute is one step at a time.

And here is the arithmetic worth noticing. Three of the four phases produce prose. Only the last one produces code, and by the time you arrive there, most of the thinking has already happened somewhere you can read it back. That is exactly why execution goes quickly — and it is why starting at execution feels fast and is not.

---

# What makes a plan step

![](ai-sdlc-spec-driven-plan-steps.svg)

NOTES:
Now the part that separates a plan from a list of intentions.

Look at the left. Build the renderer seam. Wire it up. Both of those are true statements about what needs to happen, and both are useless as plan steps, because neither one can be checked until both are done. If step one is subtly wrong, you find out at the end, when it is already entangled with step two, and now you are debugging two things at once with no way to tell which of them lied to you.

The right side is the same work, cut differently. Step one is the interface plus a headless implementation — something that exists and runs. Step two is a vector proving that the headless run hashes stably. Each step ends in something you can execute and look at.

That is the whole test for a plan step. When it is finished, can you run something and know? If the answer is no, it is not a step. It is a wish with a number in front of it.

---

# One step per session

This is a **context** decision, not a discipline one.

- A session that ran steps 1–5 is carrying five steps of debris
- By step 6 it has stale assumptions and dead ends in context
- The model is doing its best work with your worst context

Fresh session, one step, the spec and plan as input. **Then stop.**

NOTES:
Here is the piece people treat as ceremony and skip.

If you run five steps in one session, then by the sixth step your context is carrying everything from the first five. Including the approaches you abandoned. Including the errors you fixed. Including assumptions that were true two steps ago and are not true any more.

None of that got deleted. It is all still sitting there being weighed, with equal standing to the things that are still correct. So your sixth step — the most complex work remaining, the part that most needs a clear head — happens on the worst context of the entire session. That is precisely backwards, and it is not a failure of discipline. It is arithmetic.

So start fresh. Feed in the spec and the plan, because that is what they are for, and it is why they had to be written down instead of held in your head. Do one step. Then stop.

And notice that this is the context economy from week two again, at a completely different scale. What is always loaded, against what loads on demand. A stale session is a CLAUDE.md that nobody ever edited.

---

# What Execute-first costs

It feels fast because you see code in ten minutes.

Then:

- You discover the thing you asked for is not the thing you needed
- The code you have shapes what you now believe the design should be
- **Sunk cost is a design input now.** It should not be.

Three hours to save twenty minutes of thinking.

NOTES:
And the honest accounting of the failure, because everyone has this one. I have it, regularly.

You start at Execute because it is satisfying. Something exists in ten minutes. There is a file. It runs.

Then two things happen, and the second is much worse than the first.

The first is that you discover the thing you asked for is not the thing you needed. That is ordinary and it is recoverable. You throw it away and you ask better.

The second is that the code you now have starts shaping what you believe the design should be. You have three hundred lines. Some of them are genuinely good. And you catch yourself arguing for a design because it preserves the good ones. Sunk cost has quietly become a design input, and nobody in the room can see it happening, yourself included.

Writing the spec first costs twenty minutes, and it is the only reliable way I know to hold the design conversation while there is still nothing in existence to defend.

---

# Forge 06 — due Sun Nov 2

- Run the loop on a **real feature of your game** — not a toy
- Ship the **spec**, the **plan**, and the **transcripts**
- Every plan step must end in something you can **run**
- Say where the spec was **wrong**, and what changed

Read `cheatsheet-ai-sdlc-spec-driven`.

Next Tuesday, Game: **Worlds** — procedural generation and sound. Then **Soul prompts.**

NOTES:
Forge 06, November second.

The last bullet is the graded one and it is the one people misunderstand. I am not asking you for a spec that turned out to be perfect. I am asking you where it was wrong.

Every spec is wrong somewhere. You find out during execution that a step was underspecified, or that an interface did not survive contact with the second thing that used it. The valuable artifact is not the spec. It is the difference between what you predicted and what actually happened, because that difference is calibration, and calibration is the only thing that makes the next one better than this one.

So a submission where the spec needed no changes is one of two things. Either the feature was trivial, or the spec was written afterwards. Both score badly, and they are not hard to tell apart.

Next Tuesday is procedural generation, and it is the week your seeded random number generator finally earns its keep.
