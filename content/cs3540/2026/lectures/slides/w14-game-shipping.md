---
track: game
week: 14
title: Shipping
subtitle: Builds, Provenance, and the Machine That Is Not Yours
runtime: 18
---

NOTES:
Week fourteen, game track, and this is the last new game material of the term.

After this there is Thanksgiving, then the boss-fight week, then the Showcase. So this lecture is deliberately not about technique — it is about the distance between "works" and "ships," which is larger than anybody expects and is measured entirely on machines you do not own.

---

# What you'll know after this

- What "ships" actually means — and why your machine cannot tell you
- The **provenance manifest** as a graded artifact
- Where the frame budget must be measured
- What the Showcase actually tests

NOTES:
Four things, and all four are about the same blind spot: your machine is the one place every one of these problems is invisible.

That is not carelessness. It is structural. You configured that machine, you have the repository checked out, your credentials are cached, and your network works. Every assumption you have made is true there and nowhere else — which is why the whole lecture is about getting the code onto hardware that does not love you.

---

# Ships means it runs elsewhere

![](asset-pipeline-and-provenance-ship-checklist.svg)

NOTES:
Read the quote at the top, because it is not a suggestion. It is the note attached to your final exam slot.

Now go down the rows and notice they share a property: every single one of these fails on somebody else's machine and never on yours.

No network. Your build hits the class endpoint and works, because you have credentials cached and a connection. On campus wifi during a demo, with twenty other people, it may not.

A machine with no repository. Is your build self-contained, with assets included, or does it read something from a path that only exists in your checkout?

A grader with no context. Two lines in the README. Not a tour — how to run it.

Provenance for every generated asset. Model, prompt, seed, license. Graded.

And the frame budget, measured on the worst machine you can find rather than the one you wrote it on. Your development machine is the most powerful computer that will ever run your game.

---

# The provenance manifest

One entry per generated asset: **model, prompt, seed, date, license, cost, phase.**

Four jobs at once:

- Attribution record — legally, this matters
- Cost ledger
- Supply-chain evidence
- **Graded artifact**

> Write the entry when you add the asset. Nobody reconstructs October's prompt in December.

NOTES:
I raised this in week eleven and it comes back now because this is when it gets collected.

Every asset that came out of a model gets an entry. Which model, what prompt, what seed, when, under what license, what it cost, which phase.

Four jobs. Attribution, which matters legally and increasingly so. A cost ledger. Supply-chain evidence — what came from where, which is the same question as the MCP tool list wearing different clothes. And a graded artifact in this course.

The instruction in the quote is the only hard part. Write it when you add the asset. Reconstruction in December is somewhere between painful and fiction, and a fictional provenance record is worse than none — it is a record that asserts something you do not know.

---

# Measure on the worst machine

Your development machine is the **fastest computer that will ever run your game.**

- The Showcase runs on whatever is in the room
- A grader runs it on whatever they have
- **60fps on your laptop tells you almost nothing**

Find the slowest machine you have access to. Measure there. Fix what you find.

NOTES:
Short and unwelcome.

You have been developing on a machine you chose, warm, plugged in, with your tools already loaded. Every performance number you have is from the best case that will ever exist for your game.

The Showcase runs on whatever is in the room. A grader runs it on a laptop on battery with a browser full of tabs.

Sixty frames a second on your machine tells you nearly nothing about either. And this is the week to find that out, not December.

Go find the slowest machine you have access to — a roommate's, a lab machine, your own on battery with power saving on — and run it there. Whatever you find will be more useful than another feature.

---

# What the Showcase tests

**Games run. People play them. You answer questions.**

That is three separate things, and only the first is engineering.

- It **runs** — without your network, your repo, or you standing next to it
- People **play** it — the first thirty seconds teach, or they do not
- You **answer** — about the parts you specified, not just the parts you typed

NOTES:
And what the final actually is.

Three things, and people prepare for one of them.

It runs, on a machine that is not yours, without you present to fix anything. That is the engineering half and it is the one this lecture is about.

People play it. Not watch a demo — play it. Which means the first thirty seconds have to teach the controls without you talking, and week eight's playtest protocol was the rehearsal for exactly this. If you have not watched a stranger play it in silence, you do not know what happens in those thirty seconds.

And you answer questions — including about your spec section, which you own and specified and may not have implemented yourself. That is deliberate. The claim of this course is that specifying is the skill, and the Showcase is where you demonstrate you can defend a specification you wrote.

---

# Before Thursday

- Run your build on a **machine that is not yours.** Today.
- Turn off your **network** and play it start to finish.
- Fill in **every** missing provenance entry while you can still remember
- **Thanksgiving break Nov 23–29** — nothing is due, capstone work continues

Thursday, AI: **The Guarded Agent** — Forge 09, the capstone.
Capstone due **Dec 4** · Showcase **Dec 7–11**.

NOTES:
Two things to do today, and they are both experiments rather than work.

Run it on somebody else's machine. You will find something — a missing asset, a hard-coded path, a font that only you have installed.

And play it start to finish with the network off. Not the first screen. All of it.

Then fill in the provenance entries while October is still recoverable.

Thanksgiving is the twenty-third to the twenty-ninth and nothing is due, though the capstone continues. Capstone is due December fourth, and the Showcase is your assigned final exam slot between the seventh and the eleventh.

Thursday is the last AI lecture, and it is the one that ties the whole track together.
