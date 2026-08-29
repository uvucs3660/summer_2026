---
track: game
week: 14
title: Shipping
subtitle: Builds, Provenance, and the Machine That Is Not Yours
runtime: 18
---

NOTES:
Week fourteen, game track, and this is the last new game material of the term.

After this there is Thanksgiving, then the boss-fight week, then the Showcase. So this lecture is deliberately not about technique. It is about the distance between works and ships, which is much larger than anybody expects, and which is measured entirely on machines you do not own.

Everything up to today you could verify for yourself. From here you cannot, and that is the whole subject.

---

# What you'll know after this

- What "ships" actually means — and why your machine cannot tell you
- The **provenance manifest** as a graded artifact
- Where the frame budget must be measured
- What the Showcase actually tests

NOTES:
Four things, and all four are about the same blind spot. Your machine is the one place in the world where every one of these problems is invisible.

That is not carelessness. It is structural. You configured that machine. You have the repository checked out. Your credentials are cached, your fonts are installed, your network works, and the build has run there so many times that it has stopped counting as evidence. Every assumption you have made is true there and nowhere else.

Which is why this whole lecture is about getting the code onto hardware that does not love you.

---

# Ships means it runs elsewhere

![](asset-pipeline-and-provenance-ship-checklist.svg)

NOTES:
Read the quote at the top, because it is not a suggestion. It is the note attached to your final exam slot.

Now go down the rows and notice what they have in common. Every single one of these fails on somebody else's machine and never on yours. That is not a coincidence. That is the selection criterion — the failures that survive to a demo are exactly the ones your own machine cannot show you.

No network. Your build hits the class endpoint and works, because your credentials are cached and your connection is good. On campus wifi, in a room with twenty other people demoing at the same time, it may not.

A machine with no repository. Is your build self-contained, assets and all, or does something in it read a path that exists only in your checkout?

A grader with no context. Two lines in the README. Not a tour of your architecture. How to run it.

Provenance for every generated asset. Model, prompt, seed, license. Graded.

And the frame budget, measured somewhere other than here. That one gets its own slide.

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
I raised this in week eleven, and it comes back now because this is the week it gets collected.

Every asset that came out of a model gets an entry. Which model, what prompt, what seed, when, under what license, what it cost, and which phase of the project it belongs to.

That one entry is doing four jobs. It is an attribution record, which matters legally and matters more every year. It is a cost ledger. It is supply-chain evidence — what came from where, which is the MCP tool list question asked about art instead of tools. And in this course it is a graded artifact.

The instruction in the quote is the only genuinely hard part of any of it. Write the entry when you add the asset. Reconstructing it in December is somewhere between painful and fictional, and a fictional provenance record is worse than an absent one, because a blank field is honest and a guess is a claim.

---

# Measure on the worst machine

Your development machine is the **fastest computer that will ever run your game.**

- The Showcase runs on whatever is in the room
- A grader runs it on whatever they have
- **60fps on your laptop tells you almost nothing**

Find the slowest machine you have access to. Measure there. Fix what you find.

NOTES:
Short, and unwelcome.

You have been developing on a machine you chose, warm, plugged in, tools already loaded, everything already compiled once. Every performance number you own comes from the best case that will ever exist for your game.

The Showcase runs on whatever is in the room. A grader runs it on a laptop, on battery, with a browser full of tabs and something else already using the GPU.

Sixty frames a second on your machine tells you very nearly nothing about either of those, and the gap is not a small multiplier. It can be the entire margin.

So go and find the slowest machine you have access to. A roommate's, a lab machine, your own on battery with power saving switched on. Run it there. Whatever you find will be worth more to you this week than another feature, because a feature that nobody in the room can run at a playable frame rate is not a feature. It is a rumour.

---

# What the Showcase tests

**Games run. People play them. You answer questions.**

That is three separate things, and only the first is engineering.

- It **runs** — without your network, your repo, or you standing next to it
- People **play** it — the first thirty seconds teach, or they do not
- You **answer** — about the parts you specified, not just the parts you typed

NOTES:
And here is what the final actually is.

Three things, and people prepare for one of them.

It runs, on a machine that is not yours, with you not standing beside it. That is the engineering half, and it is what this entire lecture has been about.

People play it. Not watch a demo — play it. Which means the first thirty seconds have to teach the controls while you say nothing, and week eight's playtest protocol was the rehearsal for exactly this moment. If you have never watched a stranger play your game in silence, you do not know what happens in those thirty seconds. You have a hypothesis.

And you answer questions, including questions about your spec section, which you own and specified and may not have written a line of. That is deliberate. You wrote a section of a specification that independent builds had to obey, and defending it out loud is the only test I have that shows whether you understood what you wrote.

---

# Before Thursday

- Run your build on a **machine that is not yours.** Today.
- Turn off your **network** and play it start to finish.
- Fill in **every** missing provenance entry while you can still remember
- **Thanksgiving break Nov 23–29** — nothing is due, capstone work continues

Thursday, AI: **The Guarded Agent** — Forge 09, the capstone.
Capstone due **Dec 4** · Showcase **Dec 7–11**.

NOTES:
Two things to do today, and both of them are experiments rather than work.

Run your build on somebody else's machine. You will find something — a missing asset, a hard-coded path, a font that only you have installed. Everybody finds something. The people who find it this week are the ones who are relaxed in December.

Then play it start to finish with the network off. Not the first screen. All of it.

And fill in the provenance entries while October is still recoverable.

Thanksgiving is the twenty-third to the twenty-ninth and nothing is due, though the capstone continues. Capstone is due December fourth, and the Showcase is your assigned final exam slot between the seventh and the eleventh.

That is the last new game material of this course. What is left is your game, a room you have never demoed in, and a machine that has never heard of either of you. Go and meet one of those machines this week, while there is still time to change your mind about anything.

Thursday is the last AI lecture, and it is the one that ties that track together.
