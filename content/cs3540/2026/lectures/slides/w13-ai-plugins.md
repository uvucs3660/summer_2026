---
track: ai
week: 13
title: Plugins
subtitle: Packaging the Studio
runtime: 14
---

NOTES:
Week thirteen, AI track, and this is a short one, because it is mostly assembly.

You have now built nine of the eleven pillars separately. A plugin is the box they go in. That really is most of what a plugin is, and I am not going to spend twenty minutes pretending otherwise.

---

# What you'll know after this

- What a plugin actually **bundles**
- Why the unit of distribution matters more than any single piece
- What changes when your tooling has **users** who are not you

NOTES:
Three things. The first two are inventory. The third is where all the design pressure comes from.

---

# The other nine pillars, in a box

![](cc-plugins-what-ships.svg)

NOTES:
Here is what goes in the box.

Skills, with their descriptions and their bodies. Subagents, with their anti-goals — and note that the anti-goals travel. That matters more than it looks, because a subagent that arrives without them is a different subagent in somebody else's hands, and it will not mention that to them.

Hooks, already wired. This is the one with the most leverage in the bundle. A plugin that installs a guard means every person who installs it gets the guard, without ever having to decide about it. You made that decision once, on behalf of everyone who ever runs it.

MCP servers and their tool lists — and by now that phrase should make you want to read the list before you install anything.

Slash commands. And CLAUDE.md fragments, carrying the facts about this domain.

Now the line at the bottom, because it governs the last two weeks of this course. A plugin is the unit of distribution, and in a governed setup it is the unit a Council ratifies. Not a skill. Not a hook. The box.

---

# Everything changes when it has users

Your own tooling forgives a lot. A plugin does not.

- A skill description that only **you** would type will never fire for anyone else
- A hook that assumes **your** directory layout blocks their legitimate work
- An MCP server pointed at **your** database is not a tool, it is an incident

> Every assumption you left implicit becomes someone else's bug report.

NOTES:
And here is why packaging is not zipping.

Tooling that is only ever yours is full of assumptions, and every one of them is true, because you are the person who made them true. The moment somebody else installs it, each of those assumptions turns into a defect that you will never see fail.

Your skill description says run the grader, because that is what you call it. They say score the submissions, and nothing fires. That is the trigger phrase problem from week three, except now there is a stranger on the other end who does not know a skill exists to be triggered, so they will not debug it. They will decide your plugin does nothing.

Your hook checks a path that only exists in your layout. So either it never fires, which is merely useless, or it fires on the wrong thing and blocks legitimate work in a repository you have never seen.

And your MCP server pointed at a database only you can reach is not a tool. It is an incident with a nice description.

Read the line at the bottom. This is the subagent that cannot ask a clarifying question, one level up. Everything you left implicit is now somebody else's problem, and they cannot ask you either.

---

# So the design pressure is the same

The three questions, again:

- **Scope** — what is this for, in words a stranger would use?
- **Shape** — what does it produce, and where?
- **Boundary** — what does it touch, and what must it never touch?

If you answered these for a subagent, you already know how to package.

NOTES:
Which means the work is already familiar.

Scope, shape, boundary. The same three questions from week five's subagent prompt, and the same three from the MCP tool list two weeks after that. They do not change, because the underlying problem does not change. You are handing capability to something that will act on it without checking back with you.

Scope, in words a stranger would use rather than the words you use. Shape, so they know what comes out and where it lands. Boundary, so the blast radius is legible before they install rather than afterwards.

If you have been doing the Forge assignments properly, packaging is mostly gathering up things you already wrote and auditing each one for assumptions that were only ever true on your machine.

---

# Before Tuesday

- Take **one** Forge artifact and ask: would this work for someone who is not you?
- Fix the assumption you find. There will be one.
- Read `cheatsheet-cc-plugins`

Next Tuesday, Game: **Shipping.** Thursday, AI: **The Guarded Agent** — Forge 09, the capstone.
**Divergence Act IIIa** due Sun Nov 16.

NOTES:
One exercise, and it takes ten minutes.

Take a single Forge artifact and read it as a stranger. Not is this good. Would this work for somebody with a different directory layout, a different vocabulary for the same job, and different data on the other end of it.

There will be an assumption. There is always an assumption. Finding it tonight costs you ten minutes. Finding it at the Showcase, with somebody standing in front of you trying to run your thing, costs you rather more than that.

Next week is the last teaching week before Thanksgiving. Shipping on Tuesday, and the capstone Forge on Thursday — the guarded agent, which is where the whole AI track lands.
