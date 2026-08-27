---
track: ai
week: 7
title: MCP and Blast Radius
subtitle: The Only Pillar That Reaches Outside the Sandbox
runtime: 18
---

NOTES:
Week seven, AI track, and this is the security lecture — though I want to frame it as an engineering lecture, because "security" makes people think about attackers and the realistic failure here is not an attacker.

The realistic failure is a well-meaning server, doing what it says on the box, with a tool list nobody read.

---

# What you'll know after this

- What MCP actually is, in one sentence
- Why the question is **never** "is this trustworthy"
- How to read a **tool list** and infer the blast radius
- The rule for what you give a server access to

NOTES:
Four things. The second one is the reframe, and it is the whole lecture — the same move as week nine's model selection, where an unanswerable question gets replaced by an answerable one.

The third is a skill you can practise in ten seconds on any server you are considering, and the fourth is a rule short enough to actually follow when you are tired and want the thing installed.

---

# One sentence

**MCP is a protocol for giving a model tools it did not ship with.**

A server declares a list of tools. Claude can call them.

- Every other pillar shapes what happens **inside** the session
- This one lets the session **reach out** — your filesystem, your database, your accounts

And a server runs **with your privileges.** Not sandboxed. Yours.

NOTES:
That is the whole idea. A server advertises tools; the model can call them.

Read the contrast, because it is the thing to hold onto. CLAUDE.md, skills, subagents, hooks — all of those shape behavior inside a session. Nothing about them touches the world.

MCP touches the world. It is how a model reads your database, files a ticket, sends a message, or deploys something.

And the last line is the one that should make you sit up. A server you install runs as you. It has your filesystem permissions, your credentials, your network access. There is no sandbox between an MCP server and the things you can reach. If you can drop that table from your terminal, so can a tool that decides to.

---

# The wrong question

"Is this server trustworthy?"

That question has no answer you can act on. You do not audit the code. You would not catch it if you did.

**The question is: what is in its tool list?**

- `query_readonly` **cannot** drop a table
- `execute_sql` **can**

That is not a trust judgement. It is a capability fact.

NOTES:
Here is the reframe.

People evaluate MCP servers the way they evaluate npm packages: is the author reputable, does it have stars, does it look maintained. Those are trust heuristics and they are nearly useless here, because you are not going to read the code, and if you did you would not spot a subtle problem in it.

Trust is unfalsifiable. Capability is not.

`query_readonly` cannot drop your table. Not "would not" — cannot. There is no argument you can pass it that drops a table, because dropping tables is not a thing it does. That is a property of the interface, and you can verify it by reading one line.

`execute_sql` can do anything SQL can do, including everything you are worried about, and it does not matter at all how nice the author is.

So stop asking whether you trust the server. Ask what it is able to do, and then decide whether you are comfortable with that regardless of intent.

---

# Two servers, same description

![](cc-mcp-tool-list.svg)

NOTES:
Both of these say "database access." Both would appear in a directory under the same heading. One of them is safe to point at production and one of them is not, and the description does not tell you which.

Look at the left list. Query read-only, list tables, describe schema. The worst case is that it reads something it should not have — which matters, and is a much smaller category of harm than the alternative.

Now the right list. Execute SQL and run migration. The worst case is your database is gone. Not because the author was malicious — because a model, doing its best to fix a failing test at eleven at night, had `execute_sql` available and a plausible theory.

Same description, same category, wildly different blast radius. The information you needed was in the tool list the whole time, and it takes ten seconds to read.

---

# The rule

![](cc-mcp-blast-radius.svg)

NOTES:
This is your cheat-sheet diagram, and it generalises to a rule you can actually apply.

Give a server the narrowest capability that does the job, pointed at the least valuable thing that makes it useful.

Read-only against dev data is almost always enough to get the benefit. If you are exploring a schema, you need to read a schema. You do not need write access to do that, and pointing it at production buys you nothing except risk.

And the practical version, which is what I actually do: before installing anything, read the tool list. If it contains a verb that would ruin your day, either do not install it or point it somewhere that cannot ruin your day. That is the entire discipline, and it takes less time than reading the README.

---

# Forge 05 — due Sun Oct 26

- An MCP server that does something **real for your game**
- The **narrowest tool list** that accomplishes it — and say why each tool is there
- Name the **blast radius** explicitly: what is the worst a caller could do?
- Read `cheatsheet-cc-mcp`

Next Tuesday, Game: **Feel** — juice, MDA, and playtesting.

NOTES:
Forge 05, due October twenty-sixth.

The third bullet is the graded one and it is a writing exercise more than a coding one. State the worst thing a caller could do with your server, honestly. Not what it is for — what it *permits*.

Most of you will discover while writing that sentence that you exposed something broader than you needed, and you will go narrow the tool. That is the assignment working.

Next Tuesday is feel, which is the least technical lecture of the term and possibly the one that most changes your game.
