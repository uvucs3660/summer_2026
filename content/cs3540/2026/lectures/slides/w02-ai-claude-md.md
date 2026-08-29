---
track: ai
week: 2
title: CLAUDE.md
subtitle: The Contractor Briefing — and the Axis Through All Eleven Pillars
runtime: 20
---

NOTES:
This is the other half of week two.

The game track this week was about a loop that has to behave identically on every machine. This one is about a file. One file, loaded into every conversation you will ever have with an agent on this project, before you type a single word, forever.

Those two things have more in common than they look. Both are about the cost of a decision you make once and then pay for continuously.

And Forge 01 is this file. It is due on September seventh, and it is the first of nine artifacts you build across the term. So this is not background. This is the assignment.

---

# What you'll know after this

- The axis that runs through all **11 Pillars**: what is *always* in context versus what loads *on demand*
- What belongs in `CLAUDE.md` — and the much longer list of what does not
- Why a do-not rule **without a reason** gets rationalized around
- The one test that tells you whether a line has earned its place

NOTES:
Four things, and the first one carries the other three.

If you take nothing else out of this half hour, take the axis. Almost every question you will ever have about Claude Code — where does this belong, why is it slow, why did it ignore my instruction — collapses into one question about what is in context and what it cost to put there.

---

# The axis through the Pillars

The eleven pillars sort into four groups — **Context, Capability, Control, Communication**.

There is one question running through all of them:

> What is **always** loaded, versus what loads **only when needed**?

- `CLAUDE.md` — always. Every turn. Every session. Forever.
- Skill **descriptions** — always. Skill **bodies** — only when the description matches.
- Subagent work — happens in a *different* context, and only a summary comes back.

NOTES:
Here is the frame.

The eleven pillars group into four families, and the full map is in the week one AI lecture if you have not watched it yet. But underneath the taxonomy there is one recurring question, and it is the one on the slide.

Some things are loaded before you type anything. CLAUDE.md is. The description line of every skill you have installed is. Those are fixed costs. You pay them on turn one and you pay them on turn four hundred, identically, whether they were relevant or not.

Other things are conditional. The body of a skill loads only when its description matched what you were doing. A subagent does its work in a completely separate context window and hands you back a summary, which means a twenty-thousand-token investigation can cost you two hundred tokens of results.

Once you can see that split, the design questions answer themselves. Asking whether something belongs in CLAUDE.md or in a skill is really asking whether you need it every single turn or only sometimes. And the honest answer is almost always: only sometimes.
---

# Two columns, one decision

![](cc-claude-md-context-cost.svg)

NOTES:
Everything in this lecture is a consequence of this picture.

Left column, loaded before you type. All of CLAUDE.md. The description line of every skill you have installed — not the bodies, the descriptions, but all of them, every time. Your tool definitions.

Right column, conditional. A skill's body loads only if its description matched. A subagent runs in its own context window and hands back a summary. Read that last line twice, because it is the best deal in the system: a twenty-thousand-token investigation costs you two hundred tokens of results.

The line at the bottom is the one to keep. Every design question you have this term — where does this go, why is it ignoring me, why is this slow — is that same question wearing a different hat.


---

# What "every turn" actually costs

A 400-line `CLAUDE.md` describing a workflow you use **once a month**:

- Loaded on all the other 29 days
- Competing for attention with the thing you actually asked for
- Never reviewed, because nobody re-reads a file that already exists

The cost is not just tokens. **It is dilution.**

NOTES:
Let me make the cost concrete, because saying it uses tokens undersells it badly.

Say you write a four-hundred-line CLAUDE.md. Buried in there is a careful description of your release process, which you run once a month. Twenty-nine days out of thirty, that section is loaded, read, and irrelevant.

The token cost is real, but it is not the interesting part. The interesting part is the second bullet. Instructions compete with each other. When you hand a model four hundred lines of standing instruction and then ask it to fix a null check, the null check is now one signal among many. Every irrelevant rule you add dilutes the relevant ones a little.

And the third bullet is why this gets worse with time instead of better. Nobody re-reads CLAUDE.md. It is a file that already exists, so it feels finished. Things get added and nothing is ever removed, and eighteen months later it is confidently describing a build system you stopped using last year — and the model is still dutifully following it.

---

# A contractor, not an intern

You are briefing someone who is **an excellent engineer** and has **never seen this repo**.

- They do not need to be taught the language
- They do not need your onboarding doc
- They **do** need to know the three things about this codebase that are surprising

> Write what a competent stranger needs on day one. Nothing else.

NOTES:
Here is the framing to hold while you write yours.

Picture a contractor. Genuinely good, better than you at some things. Starts Monday. Has never seen this repository.

What do you actually tell them? You do not explain what a for-loop is. You do not paste in the README, because they can read the README. You do not walk them through your git workflow, because they have been using git for years.

What you tell them is the stuff that is surprising. The test suite that needs a running Postgres. The module that looks dead and is loaded reflectively. The one function everybody tries to optimise and must not, because the slow version is the version that is correct.

That is CLAUDE.md. A briefing about what is weird here, written for somebody who is otherwise entirely capable.

The word competent in that quote is doing real work. Most bad CLAUDE.md files are bad because they were written for somebody incompetent.

---

# The hierarchy

![](cc-claude-md-hierarchy.svg)

NOTES:
This is on the cheat sheet, so do not copy it down.

Read the left column top to bottom. Enterprise policy. Then your personal file, the one in your home directory. Then the project's file, committed and shared with your team. Then a file in a subdirectory, which wins for everything underneath it.

More specific wins. Your personal preferences apply everywhere you work. The project file overrides them for this repo. A subdirectory file overrides that again for its own corner.

Use the split deliberately, because it comes down to who a line is about. A line saying you want explanations before code is about you, and it belongs in your personal file so it follows you between projects. A line saying the integration tests need Docker running is about the repository, and it belongs in the project file so your teammates get it without anybody having to tell them.

The panel on the right is your checklist for the assignment. The panel at the bottom is the argument I just made, in two sentences.

---

# Do-not rules need reasons

## Without a reason

`Do not use the cache layer directly.`

An agent that finds a case where it seems fine will **rationalize its way past this.** So would a person.

## With a reason

`Do not use the cache layer directly — it does not invalidate on write, so reads after a write return stale rows. Go through` `repo.get()`.

Now there is something to **check** instead of something to obey.

NOTES:
This is the highest-leverage thing in the lecture, so I am going to be emphatic about it.

A rule without a reason is a rule that gets broken the first time it is inconvenient.

Look at the top one. Do not use the cache layer directly. Sooner or later the agent lands in a situation where using the cache layer directly looks obviously correct. It is faster. It is fewer lines. And nothing in the instruction explains why not. So it does it, and it writes you a confident little note about why this particular case was an exception.

I want to be clear that this is not an AI failing. Hand that rule to a new hire and you get exactly the same outcome. Unexplained rules get filed as bureaucracy, and smart people route around bureaucracy. That is most of what makes them smart.

Now the second one. Same rule, plus the mechanism. The agent is no longer being asked to obey. It has been handed a fact it can reason with. When it hits the tempting case it now has something to check: does this path involve a read after a write? And if the answer is genuinely no, then maybe the exception really is fine, and it can tell you so with an argument instead of an excuse.

Reasons convert obedience into judgment. That is strictly better, and it costs you eight words.
---

# The same rule, twice

![](cc-claude-md-reason-rule.svg)

NOTES:
Same rule on both rows. The only difference between them is eight words of mechanism.

Top row. The rule arrives with nothing behind it. So when the model reaches a case where using the cache looks obviously right, there is nothing to weigh it against. It goes past, and writes you a confident note explaining why this one was fine.

Bottom row. Now the rule carries its reason. And look at what the model does with it — it turns the rule into a question it can actually answer about the code in front of it. Does this path read after a write?

That is the difference between a rule and a reason. And when an exception really is legitimate, the second version gets you a real argument instead of a silent violation.


---

# The falsification test

For every line in your file, ask:

> **Would a competent engineer who has never seen this repo actually get this wrong?**

- **No** → delete it. You are describing the obvious.
- **Yes** → keep it, and add *why*.

Applied honestly, this deletes **most of what `/init` generates.**

NOTES:
Here is how you get from a draft to a real file.

Go line by line and ask the question on the slide. Not whether it is true — most of what gets written into these files is true. Ask whether a competent stranger would actually get it wrong without being told.

This project uses TypeScript. They will see that in about four seconds. Delete it.

Run npm test to run the tests. That is what they will try before anything else. Delete it.

Tests must be run with the database URL pointing at the test database, or they will silently run against dev and wipe it. That one they would absolutely get wrong, and the consequence is somebody's whole afternoon. Keep it. And notice that it already carries its own reason, without anybody having to add one.

Be honest when you apply this. The temptation is to keep lines because they took effort to write. Effort spent is not a reason to keep a line. It is a sunk cost, and CLAUDE.md is one of the very few files where deleting your own work is usually the improvement.
---

# The test, with worked examples

![](cc-claude-md-falsification.svg)

NOTES:
Here it is with the examples attached.

Left side, the deletions. Every one of those is true. That is exactly what makes them tempting. But a competent engineer discovers all three within a minute of opening the repository, so writing them down buys you nothing and costs you on every turn forever.

Right side, the keeper. Notice three things about it. It is severe — you lose your dev database. It is invisible — nothing in the code warns you. And it carries its own reason without anybody bolting one on, because that is what a real invariant looks like when you write it down honestly.

If your file is mostly left-column entries, you have a generated file, not an authored one.


---

# `/init`, then delete

```
/init          # generates a draft by reading your repo
```

- It is a **starting point**, not an answer
- It reliably over-produces — it describes structure, not surprises
- Expect to cut **half or more**

The graded artifact is not the file `/init` gave you. It is what you decided to keep.

NOTES:
Practical mechanics.

Run slash init. It reads your repository and generates a draft CLAUDE.md. It is genuinely useful and it will save you twenty minutes.

It also over-produces, every time, and it over-produces in one specific direction. It describes structure, because structure is what it can see. It will tell you there is a source directory and a tests directory. It cannot tell you that one file in that tests directory has to run before all the others, because that is not visible anywhere in the file tree.

So treat it as a first draft written by somebody who has read every line of your code and never once run it. Cut hard, then add the things only you know.

That last line on the slide is aimed at the rubric. I am not grading whether you have a CLAUDE.md. Generating one takes four seconds. I am grading the editing.

---

# What goes in a skill instead

If it is a **procedure** rather than a **fact** about the repo, it is probably a skill:

- "How we cut a release" → skill
- "Releases must bump `version` in two places" → `CLAUDE.md`
- "How to add a new spec section" → skill
- "Spec sections are numbered `S04`–`S18` and owned in `OWNERS.md`" → `CLAUDE.md`

Facts are cheap and always relevant. **Procedures are expensive and rarely relevant.**

NOTES:
Last idea, and it is the bridge to next week.

The reliable test is facts versus procedures.

A fact about the repository is short and it is true on every turn. Releases bump the version in two places — that is a fact. It costs you one line, and any turn that touches a release needs it.

A procedure is long, it goes step by step, and it is relevant maybe two percent of the time. How we cut a release is a procedure. It is fifteen lines minimum, and on the other ninety-eight percent of turns it is pure dilution.

Procedures belong in skills, which load only when they match. That is what next Tuesday's AI lecture is about, and it includes the reason most first attempts at a skill never fire at all.

Now notice the shape of the two lists. The CLAUDE.md entries are one line each. The skill entries are titles of documents. If something you are writing for CLAUDE.md runs past three or four lines, that is your signal that it wants to be a skill.
---

# Facts stay, procedures move

![](cc-claude-md-fact-vs-procedure.svg)

NOTES:
The sorting rule, with the shapes made visible.

Look at the left boxes and the right boxes and notice that the difference between them is physical. The facts fit on one line. The procedures are not sentences at all — how we cut a release is a heading, with fifteen lines underneath it.

That shape difference is the whole test, and it is why the rule at the bottom works as a mechanical check. You never have to reason about whether something is conceptually a fact or conceptually a procedure. You look at how long it got. If a CLAUDE.md entry has grown a numbered list, it stopped being a fact somewhere around step two.

Next Thursday we build the other side of this picture.


---

# Forge 01 — due Sun Sep 7

- Write `CLAUDE.md` for **your own game repo**, not a toy
- Every do-not rule carries its reason
- Apply the falsification test and be able to say **what you deleted and why**
- Read `cheatsheet-cc-claude-md`

Next Tuesday, Game: **Determinism and the Command Model.**
Next Thursday, AI: **Skills** — and why your first one will not fire.

NOTES:
Forge 01 is due Sunday the seventh.

Write it for your actual game repository, not a toy. This matters more than it sounds. A CLAUDE.md for a repo with three files in it cannot demonstrate judgment, because there is nothing in there to leave out. Your game repo has a pitch in it, and by then it will have your one-prompt game too. That is enough surface for real decisions.

Two things the rubric looks hard at. Every do-not rule needs its reason attached, for the argument I made earlier. And I want you to be able to tell me what you cut. If you run slash init and hand back what it gave you, that is visible from across the room, and it scores accordingly.

Next week: determinism on Tuesday, which is the deepest technical material in the course so far, and skills on Thursday.

And one thing to do before Tuesday, if you do nothing else. Go and read the CLAUDE.md in the class engine spec repository. It is short. Ask yourself, line by line, whether each one survives the falsification test. A couple of them are arguable, and I would like somebody to come and argue with me about it.
