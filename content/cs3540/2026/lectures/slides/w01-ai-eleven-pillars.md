---
track: ai
week: 1
title: The 11 Pillars
subtitle: The Map, and the One Axis That Runs Through It
runtime: 16
---

NOTES:
Week one, AI track.

This is the map lecture, and I want to be straight about what a map lecture can and cannot do, because otherwise you leave here having heard eleven things and retained none of them.

It will not make you good at any single pillar. Each of them gets its own week later in the term, with its own artifact and its own particular way of going wrong. What today gives you is the frame — where the eleven things sit relative to each other, so that when we spend a whole week inside one of them you know which part of the machine you are standing in.

And it gives you one question, which answers most of the design decisions you will ever make with these tools and fits on an index card.

---

# What you'll know after this

- The four groups the eleven pillars sort into
- The **one axis** that runs through all of them
- Why "where does this belong?" is nearly always the same question
- Which pillar is **categorically different** from the other ten

NOTES:
Four things. The second one is the one to keep — the other three are scaffolding holding it up. And the fourth is a preview of week six.

---

# Four groups

![](cc-the-11-pillars-four-groups.svg)

NOTES:
Here is the map.

Four groups. Context is what it knows — your CLAUDE.md, your skills, memory. Capability is what it can do — tools, MCP servers, subagents. Control is what it may do — permissions, hooks, modes. And Communication is how you steer it — prompts and plugins.

That grouping is genuinely useful for finding your bearings. It is also the least interesting thing on this slide. A grouping is how you file something, and nobody was ever made good at anything by filing it correctly.

The interesting part is the line along the bottom. All eleven of those things are decisions about the same single axis, and that axis is the next slide.

---

# The axis

> **What is always in context, versus what loads on demand?**

- `CLAUDE.md` — always. Every turn, every session, **forever.**
- A skill's **description** — always. Its **body** — only on a match.
- A subagent's work — in a context you **never pay for.**

Almost every "where does this belong?" decision reduces to that one question.

NOTES:
This is the sentence to write down.

What is always in context, versus what loads on demand.

Some things are loaded before you have typed a single character. Every turn. Every session. Forever. Your CLAUDE.md is one of them. The description line of every skill you have installed is another — not the bodies, the descriptions, but all of them, every time, whether or not any of them has anything to do with what you are working on.

Other things are conditional. A skill's body arrives only on the turn its description matched. A subagent does its work inside a context window you never pay for and hands back a summary, which means a twenty-thousand-token investigation can cost you two hundred tokens of result. That is not an optimisation. That is a different shape of budget.

Once you can see that split, most design questions stop being matters of opinion. Should this go in CLAUDE.md, or should it be a skill? That is really: do I need this every turn, or only sometimes? The honest answer is almost always only sometimes — which is why most CLAUDE.md files are three times longer than they should be, including the one you are going to generate tonight.

You will hear me ask that same question in weeks two, three, five, and nine, in four contexts that will not look related. I am not repeating myself when I do that. I am showing you it is one question.

---

# One pillar is not like the others

Ten of the eleven are ways of **asking.**

You write a briefing and hope it is followed. A description and hope it matches. A work order and hope it was unambiguous.

**A hook is a shell script with an exit code.** `exit 2` and the tool call does not happen.

Not "is discouraged from happening." **Does not happen.**

NOTES:
And now the exception, because it changes what is possible rather than what is merely likely.

Ten of the eleven pillars are influence. Well-designed, high-leverage influence — but influence. You write a briefing and hope it gets read. A description and hope it matches. A work order and hope it was unambiguous. In every one of those cases you are moving a probability around.

A hook is not that. A hook is a shell script. It runs at a defined moment, and if it exits two, the tool call does not happen. There is no probability anywhere in that sentence. A process that has already returned an exit code is not available for discussion.

So if you have used these tools and been quietly furious that a clear instruction got ignored on the one occasion it mattered, week six is where that stops being something you live with.

I am flagging it in week one because it should change how you think about the other ten. Those ten are for making the right thing likely. There is exactly one mechanism in the box for making the wrong thing impossible, and you should know it is there long before you need it.

---

# What this track is

Nine artifacts, one per pillar, on your **own** repository:

`CLAUDE.md` → skill → subagent → hook → MCP → spec+plan → soul → council → **the guarded agent**

Each is due after the lecture that teaches it. The last one assembles the rest.

NOTES:
And here is the shape of the term on this side.

Nine Forge artifacts, roughly one per pillar. Each is due after the lecture that teaches it, and each is built on your own game repository rather than in a sandbox I prepared for you. That is deliberate. A CLAUDE.md written for a toy repository is a writing exercise. A CLAUDE.md written for the repository you will be fighting with in November is a load-bearing document.

They accumulate. Follow the arrow to the end. The guarded agent is not one more topic bolted on — it is the others assembled into something you would be willing to let run while you are not watching. That is a meaningfully higher bar than something you would supervise, and the gap between those two bars is most of what this track is teaching you.

One piece of advice I would rather give you in week one than in December. Do these in the week they are assigned. Individually they are small, and that is the trap, because small things are easy to defer and these ones compound. Arrive at the capstone with the pieces missing and you are not assembling nine artifacts. You are writing nine artifacts and then assembling them, during finals.

---

# Before next week

- Read `cheatsheet-cc-the-11-pillars` — the map, in one page
- Run `/init` on your game repo and **read what it generates.** Do not commit it yet.
- Notice how much of it you would delete

Next Tuesday, Game: **The Loop.** Thursday, AI: **CLAUDE.md** — Forge 01, due Sep 7.

NOTES:
Two things before Thursday, and the second one is the one that will do the work.

Read the cheat sheet. It is the entire map on one page, and it will make considerably more sense now than it would have an hour ago.

Then run slash init on your game repository, and read what it produces. Read it line by line, the way you would read a contract. Do not commit it. I want you arriving on Thursday having seen a generated CLAUDE.md with your own eyes and having formed an opinion about it.

And pay attention to that opinion, because it is going to move. Almost everybody's first reaction is that the thing is impressively thorough. It found the build commands. It found the directory layout. It is very tidy. By the end of Thursday you will look at the same file and see a bill you are paying on every single turn for the rest of the project.

The distance between those two reactions is the whole lecture, and I would rather you travelled it yourself before I explain it.