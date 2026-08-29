---
track: ai
week: 7
title: MCP and Blast Radius
subtitle: The Only Pillar That Reaches Outside the Sandbox
runtime: 18
---

NOTES:
Week seven, AI track, and this is the security lecture — though I want to frame it as an engineering lecture, because the word security makes people picture an attacker, and the realistic failure here has no attacker in it at all.

The realistic failure is a well-meaning server, doing exactly what it says on the box, with a tool list nobody read.

That is the whole shape of the disaster. Nobody broke in. Nobody was clever. You installed something useful, it was useful for weeks, and then one evening it was also useful in a direction you had never thought about.
---

# What you'll know after this

- What MCP actually is, in one sentence
- Why the question is **never** "is this trustworthy"
- How to read a **tool list** and infer the blast radius
- The rule for what you give a server access to

NOTES:
Four things. The second one is the reframe, and it is the whole lecture — the same move as week nine's model selection, where an unanswerable question gets swapped for an answerable one.

The third is a skill you can practise in ten seconds against any server you are considering. And the fourth is a rule short enough that you will actually follow it at the moment you need it, which is late, when you are tired and you just want the thing installed.
---

# One sentence

**MCP is a protocol for giving a model tools it did not ship with.**

A server declares a list of tools. Claude can call them.

- Every other pillar shapes what happens **inside** the session
- This one lets the session **reach out** — your filesystem, your database, your accounts

And a server runs **with your privileges.** Not sandboxed. Yours.

NOTES:
That is the whole idea. A server advertises a list of tools; the model can call them. There is nothing more to the protocol than that.

Read the contrast, because it is the thing to hold onto. CLAUDE.md, skills, subagents, hooks. Every one of those shapes behaviour inside a session. None of them touches anything outside it. Switch them all off and the world is exactly where you left it.

MCP touches the world. It is how a model reads your database, files a ticket, sends a message, deploys something.

And the last line is the one that should make you sit up straight. A server you install runs as you. Your filesystem permissions. Your credentials. Your network access. There is no sandbox between an MCP server and everything you can reach. If you can drop that table from your own terminal, so can a tool that decides to.
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

People evaluate MCP servers the way they evaluate npm packages. Is the author reputable. Does it have stars. Does it look maintained. Those are trust heuristics and they are nearly useless here, because you are not going to read the code, and if you did read it you would not spot a subtle problem in it. That is not an insult. That is what an audit is for, and you are not doing one.

Trust is unfalsifiable. Capability is not.

Query read-only cannot drop your table. Not would not — cannot. There is no argument you can pass it that drops a table, because dropping tables is not among the things it does. That is a property of the interface, and you verify it by reading one line.

Execute SQL can do anything SQL can do, which includes every single thing you are worried about, and it does not matter in the slightest how nice the author is.

So stop asking whether you trust the server. Ask what it is able to do, and then decide whether you are comfortable with that regardless of anyone's intent.
---

# Two servers, same description

![](cc-mcp-tool-list.svg)

NOTES:
Both of these say database access. Both would show up in a directory under the same heading with the same little icon. One of them is safe to point at production and one of them is not, and the description does not tell you which.

Look at the left list. Query read-only. List tables. Describe schema. The worst case there is that it reads something it should not have read — which matters, and which is a far smaller category of harm than the alternative.

Now the right list. Execute SQL. Run migration. The worst case there is that your database is gone. Not because the author was malicious. Because a model doing its honest best to fix a failing test had execute SQL sitting in front of it and a plausible theory about the schema.

Same description, same category, wildly different blast radius. The information you needed was in the tool list the whole time, in plain text, and reading it takes ten seconds.
---

# The rule

![](cc-mcp-blast-radius.svg)

NOTES:
This is your cheat-sheet diagram, and it collapses into a rule you can actually apply.

Give a server the narrowest capability that does the job, pointed at the least valuable thing that still makes it useful.

Read-only against dev data is almost always enough to get the benefit. If you are exploring a schema, you need to read a schema. Reading a schema does not require the ability to write, and pointing it at production buys you nothing whatsoever except risk.

And the practical version, which is what I actually do. Before installing anything, read the tool list. If it contains a verb that would ruin your day, either do not install it, or point it at something that cannot ruin your day. That is the entire discipline. It takes less time than reading the README.
---

# Forge 05 — due Sun Oct 26

- An MCP server that does something **real for your game**
- The **narrowest tool list** that accomplishes it — and say why each tool is there
- Name the **blast radius** explicitly: what is the worst a caller could do?
- Read `cheatsheet-cc-mcp`

Next Tuesday, Game: **Feel** — juice, MDA, and playtesting.

NOTES:
Forge 05, due October twenty-sixth.

The third bullet is the graded one, and it is a writing exercise more than a coding one. State the worst thing a caller could do with your server, honestly. Not what it is for. What it permits. Those are two different sentences and only one of them is a claim about capability.

Most of you will discover halfway through writing that sentence that you exposed something broader than you needed, and you will stop and go narrow the tool. That is not you failing the assignment. That is the assignment working.

Next Tuesday is feel, which is the least technical lecture of the term and possibly the one that most changes your game.
