---
track: ai
week: 10
title: Spec, Plan, Execution
subtitle: Why Starting at Execute Feels Fast for Ten Minutes
runtime: 18
---

NOTES:
Week ten, AI track.

This is the lecture that puts the whole AI track in order. Everything you have built — CLAUDE.md, skills, subagents, hooks, MCP — are components. This is the loop they sit inside.

Forge 06 is running that loop deliberately, and it is due November second.

---

# What you'll know after this

- The four phases, and what each one **produces**
- Why a plan step must end in something you can **run**
- Why one step per session is a **context** decision, not a discipline one
- What starting at Execute actually costs

NOTES:
Four things, and the third one is the piece people usually miss, because it looks like process advice and is actually an engineering constraint.

---

# The loop

![](ai-sdlc-spec-driven-pipeline.svg)

NOTES:
Four phases, and each one has an output that is not code.

Explore is read-only. No edits, deliberately — the constraint exists because the moment you can edit, you start editing, and you stop understanding. Output is options and a decision.

Specification: behavior, interfaces, non-goals, acceptance criteria. You have been writing one of these all term, so you know the shape. Notice non-goals are in the list — that is the anti-goal idea from week five, in a document instead of a prompt.

Plan is the *how*, sequenced. And Execute is one step at a time.

The thing to notice is that three of the four phases produce prose. Only the last one produces code, and by the time you reach it most of the thinking is already done — which is exactly why it goes quickly.

---

# What makes a plan step

![](ai-sdlc-spec-driven-plan-steps.svg)

NOTES:
Now the part that separates a plan from a list of intentions.

Look at the left. "Build the renderer seam. Wire it up." Those are true statements about what needs to happen and they are useless as a plan, because neither can be checked until both are done. If step one is subtly wrong, you find out at the end, when it is entangled with step two.

The right side is the same work cut differently. Step one is the interface plus a headless implementation — something that exists and runs. Step two is a vector proving the headless run hashes stably. Each step ends in something you can execute and check.

That is the actual test for a plan step: when it is done, can you run something and know? If not, it is not a step, it is a wish with a number in front of it.

---

# One step per session

This is a **context** decision, not a discipline one.

- A session that ran steps 1–5 is carrying five steps of debris
- By step 6 it has stale assumptions and dead ends in context
- The model is doing its best work with your worst context

Fresh session, one step, the spec and plan as input. **Then stop.**

NOTES:
Here is the piece people treat as ceremony and skip.

If you run five steps in one session, by the sixth step the context contains everything from the first five — including approaches you abandoned, errors you fixed, and assumptions that were true two steps ago and are not now.

None of that got deleted. It is all still there, being weighed. So your sixth step happens with the worst context of the session, on the most complex remaining work. That is exactly backwards.

Start fresh. Feed in the spec and the plan — that is what they are for, and it is why they had to be written down. Do one step. Stop.

Notice this is the context economy from week two again, at a completely different scale. What is always loaded versus what loads on demand. A stale session is a CLAUDE.md nobody edited.

---

# What Execute-first costs

It feels fast because you see code in ten minutes.

Then:

- You discover the thing you asked for is not the thing you needed
- The code you have shapes what you now believe the design should be
- **Sunk cost is a design input now.** It should not be.

Three hours to save twenty minutes of thinking.

NOTES:
And the honest accounting of the failure, because everyone has this one — I have it, regularly.

You start at Execute because it is satisfying. Something exists in ten minutes.

Then two things happen, and the second is worse than the first.

The first is that you discover the thing you asked for is not the thing you needed. That is ordinary and recoverable.

The second is that the code you now have starts shaping what you believe the design should be. You have three hundred lines. Some of them are good. And you find yourself arguing for a design because it preserves the good ones. Sunk cost has quietly become a design input.

Writing the spec first costs twenty minutes and it is the only reliable way I know to keep the design conversation happening while nothing yet exists to defend.

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

The last bullet is the graded one and it is the one people misunderstand. I am not asking you to write a spec that turned out perfect. I am asking where it was wrong.

Every spec is wrong somewhere — you find out during execution that a step was underspecified, or an interface did not survive contact. The valuable artifact is not the spec, it is the diff between what you predicted and what happened, because that diff is calibration and calibration is what makes the next one better.

A Forge 06 submission where the spec needed no changes is one of two things: a trivial feature, or a spec written afterwards. Both score badly.

Next Tuesday is procedural generation, and it is the week your seeded random number generator finally earns its keep.
