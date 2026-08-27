---
track: ai
week: 13
title: Plugins
subtitle: Packaging the Studio
runtime: 14
---

NOTES:
Week thirteen, AI track, and this is a short one because it is mostly assembly.

You have now built nine of the eleven pillars separately. A plugin is the box they go in.

---

# What you'll know after this

- What a plugin actually **bundles**
- Why the unit of distribution matters more than any single piece
- What changes when your tooling has **users** who are not you

NOTES:
Three things, and the third is the interesting one, because it is where most of the design pressure comes from.

---

# The other nine pillars, in a box

![](cc-plugins-what-ships.svg)

NOTES:
Here is what goes in.

Skills, with their descriptions and bodies. Subagents, with their anti-goals — and note that the anti-goals travel, which matters, because a subagent without them behaves differently in somebody else's hands.

Hooks, already wired. This is the one with the most leverage: a plugin that installs a guard means every person who installs it gets the guard, without knowing it was a decision.

MCP servers and their tool lists — and by now that phrase should make you want to read the list.

Slash commands, and CLAUDE.md fragments carrying the facts about this domain.

The line at the bottom matters for the last two weeks of this course: a plugin is the unit of distribution, and in a governed setup it is the unit a Council ratifies. Not a skill, not a hook — the box.

---

# Everything changes when it has users

Your own tooling forgives a lot. A plugin does not.

- A skill description that only **you** would type will never fire for anyone else
- A hook that assumes **your** directory layout blocks their legitimate work
- An MCP server pointed at **your** database is not a tool, it is an incident

> Every assumption you left implicit becomes someone else's bug report.

NOTES:
And here is why packaging is not just zipping.

When tooling is yours alone, it is full of assumptions that are all true, because you are the one who made them. The moment somebody else installs it, each of those becomes a defect.

Your skill description says "run the grader" because that is what you call it. Somebody else says "score the submissions" and nothing fires — the trigger phrase problem from week three, now with a stranger on the other end who does not know a skill exists to be triggered.

Your hook checks a path that only exists in your layout, so it either never fires or blocks work it should not.

And your MCP server pointed at a database that only you can reach is, at best, useless to them.

Read the line at the bottom. It is the same lesson as the subagent that cannot ask a clarifying question, one level up: everything you left implicit is now somebody else's problem, and they cannot ask you either.

---

# So the design pressure is the same

The three questions, again:

- **Scope** — what is this for, in words a stranger would use?
- **Shape** — what does it produce, and where?
- **Boundary** — what does it touch, and what must it never touch?

If you answered these for a subagent, you already know how to package.

NOTES:
Which means the work is familiar.

Scope, shape, boundary — the same three questions from week five's subagent prompt, and the same three from the MCP tool list two weeks after that.

Scope in words a stranger would use, not words you use. Shape, so they know what to expect. Boundary, so the blast radius is legible before they install rather than after.

If you have been doing the Forge assignments properly, packaging is mostly collecting things you already wrote and checking each one for assumptions that were only ever true on your machine.

---

# Before Tuesday

- Take **one** Forge artifact and ask: would this work for someone who is not you?
- Fix the assumption you find. There will be one.
- Read `cheatsheet-cc-plugins`

Next Tuesday, Game: **Shipping.** Thursday, AI: **The Guarded Agent** — Forge 09, the capstone.
**Divergence Act IIIa** due Sun Nov 16.

NOTES:
One exercise, and it takes ten minutes.

Pick a single Forge artifact and read it as a stranger. Not "is it good" — would it work for somebody with a different directory layout, different vocabulary, different data?

There will be an assumption. There always is. Finding it now is much cheaper than finding it in the Showcase when someone tries to run your thing.

Next week is the last teaching week before Thanksgiving. Shipping on Tuesday, and the capstone Forge on Thursday — the guarded agent, which is where the whole AI track lands.
