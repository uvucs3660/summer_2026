---
track: ai
week: 1
title: The 11 Pillars
subtitle: The Map, and the One Axis That Runs Through It
runtime: 16
---

NOTES:
Week one, AI track.

This is the map lecture. It will not make you good at any single pillar — each of those gets its own week — but it gives you the frame that makes the rest of the term cohere, and one question that answers most design decisions you will face.

---

# What you'll know after this

- The four groups the eleven pillars sort into
- The **one axis** that runs through all of them
- Why "where does this belong?" is nearly always the same question
- Which pillar is **categorically different** from the other ten

NOTES:
Four things. The second is the one to keep; the fourth is a preview of week six.

---

# Four groups

![](cc-the-11-pillars-four-groups.svg)

NOTES:
Here is the map.

Context is what it knows — CLAUDE.md, skills, memory. Capability is what it can do — tools, MCP servers, subagents. Control is what it may do — permissions, hooks, modes. Communication is how you steer — prompts and plugins.

The grouping is useful for orientation, but it is not the interesting part. The interesting part is the line at the bottom.

---

# The axis

> **What is always in context, versus what loads on demand?**

- `CLAUDE.md` — always. Every turn, every session, **forever.**
- A skill's **description** — always. Its **body** — only on a match.
- A subagent's work — in a context you **never pay for.**

Almost every "where does this belong?" decision reduces to that one question.

NOTES:
This is the sentence to write down.

Some things are loaded before you type anything, on every single turn, forever. Your CLAUDE.md is. The description line of every skill you have installed is — not the bodies, the descriptions, but all of them, always.

Other things are conditional. A skill's body loads only when its description matched. A subagent runs in its own context window and hands back a summary, which means a twenty-thousand-token investigation can cost you two hundred tokens of result.

Once you can see that split, most design questions answer themselves. Should this be in CLAUDE.md or a skill? That is really: do I need this every turn, or only sometimes? And the honest answer is almost always only sometimes — which is why most CLAUDE.md files are three times too long.

You will hear me say this in weeks two, three, five, and nine, in four different contexts. It is the same question every time.

---

# One pillar is not like the others

Ten of the eleven are ways of **asking.**

You write a briefing and hope it is followed. A description and hope it matches. A work order and hope it was unambiguous.

**A hook is a shell script with an exit code.** `exit 2` and the tool call does not happen.

Not "is discouraged from happening." **Does not happen.**

NOTES:
And the exception, because it changes what is possible.

Ten of the eleven pillars are influence. Well-designed, high-leverage influence — but influence. You are shaping the probability that something happens.

A hook is not. It is a command that runs at a defined moment, and if it exits two, the tool call is cancelled. There is no probability involved and no argument that gets past it.

If you have used these tools and been frustrated that an instruction was sometimes ignored, week six is where that stops being your only option. I flag it now because it changes how you should think about the other ten: they are for making the right thing likely, and there is a separate mechanism for making the wrong thing impossible.

---

# What this track is

Nine artifacts, one per pillar, on your **own** repository:

`CLAUDE.md` → skill → subagent → hook → MCP → spec+plan → soul → council → **the guarded agent**

Each is due after the lecture that teaches it. The last one assembles the rest.

NOTES:
And the shape of the term.

Nine Forge artifacts, roughly one per pillar, each due after the lecture that teaches it, each built on your own game repository rather than a sandbox — because the assumptions only get tested when the thing is real.

They accumulate. The final one is the guarded agent, and it assembles the others into something you would actually let run unattended, which is a meaningfully different bar from something you would supervise.

One thing I would tell you now rather than in December: do these on the week they are assigned. They are individually small and they compound, and the capstone is much harder if the pieces do not exist yet.

---

# Before next week

- Read `cheatsheet-cc-the-11-pillars` — the map, in one page
- Run `/init` on your game repo and **read what it generates.** Do not commit it yet.
- Notice how much of it you would delete

Next Tuesday, Game: **The Loop.** Thursday, AI: **CLAUDE.md** — Forge 01, due Sep 7.

NOTES:
Two things.

Read the cheat sheet — it is the whole map on one page and it will make more sense now than it did before this lecture.

And run slash init on your game repository, then read what it produces without committing it. I want you to arrive at Thursday's lecture having seen a generated CLAUDE.md and formed an opinion about it.

Pay attention to your instinct about how much of it is worth keeping. Most people's first reaction is that it is impressively thorough. By the end of Thursday you will think most of it is a tax, and the gap between those two reactions is the whole lecture.
