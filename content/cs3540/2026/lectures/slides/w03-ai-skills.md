---
track: ai
week: 3
title: Skills
subtitle: Progressive Disclosure, and Why Your First One Will Never Fire
runtime: 20
---

NOTES:
Week three, AI track.

Last week we put facts in CLAUDE.md and said procedures go somewhere else. This is somewhere else.

Before we start, an expectation. Most people's first skill does not work. And I do not mean it works badly. I mean it does not run. Not once. Ever. They write a genuinely good procedure, they install it, they use Claude every day for a week, and the thing just sits there in the folder like a rock in a field.

Then they decide skills are unreliable.

Skills are not unreliable. The skill was invisible. And the reason it was invisible is completely mechanical and completely fixable, and that reason is most of this lecture.

---

# What you'll know after this

- What a skill actually **is** — and the two halves that are billed differently
- **Progressive disclosure**: description, then body, then references
- Why selection reads your **description and nothing else**
- How to write a description that fires, and how to test that it did

NOTES:
Four things. The third one is the load-bearing one, and everything about how you write these follows from it. The other three are here so that one makes sense when it arrives.

---

# A skill is a folder

```
.claude/skills/open-pr/
  SKILL.md          # frontmatter + the procedure
  reference.md      # optional, loaded only if the body links it
```

```yaml
---
name: open-pr
description: Use when the user asks to open a pull request…
---
```

The frontmatter is the **contract**. The markdown below it is the **content**.

NOTES:
Mechanically? A skill is a folder. With a markdown file in it. I want you to sit with how unimpressive that is, because in about four weeks someone is going to try to sell you a course on it.

Two fields matter — name, description. Below that, the body: ordinary markdown, the actual procedure.

Now here is the load-bearing sentence. The frontmatter is a contract about WHEN this fires. The body is WHAT it does. And everybody — everybody — pours themselves into the body and dashes off the description in eight seconds on the way out the door.

Which is exactly backwards. You have built a gorgeous room with no door. Chandeliers. Parquet floors. Sealed. Nobody is getting in there, ever, and the model walks past it for the rest of its life without knowing it existed.

Of the two fields, the first is the one that decides whether the second ever runs. Spend your time accordingly.

---

# Billed on different schedules

![](cc-skills-anatomy.svg)

NOTES:
Here is why the two halves are not equally cheap.

The description is loaded for every installed skill, on every turn, forever. Same deal as CLAUDE.md. Fifty skills at roughly twenty tokens of description each is about a thousand tokens you are paying on every single request, whether or not any of them is relevant. You pay it while you are debugging a shader. You pay it while you are asking what day it is.

The body is different. It loads only on the turn its description matched. Two thousand tokens, occasionally, is nothing.

So the economics tell you exactly how to write each half. The description must be short, because you pay it always. It must also be specific, because a vague one never matches anything. Those two pull hard against each other, and that tension is the whole craft. The body can be as long as the procedure genuinely needs, because you almost never pay for it.

That asymmetry is progressive disclosure, and it is the same idea as the accumulator: separate the thing that happens always from the thing that happens sometimes.

---

# Progressive disclosure

![](cc-skills-progressive-disclosure.svg)

NOTES:
This is the cheat-sheet diagram for the week, and it generalises well past skills.

Three tiers. The description is tier one, always resident. The body is tier two, pulled in on a match. And anything the body links — a long reference table, a code template, an example file — is tier three, and it only arrives if the body actually points at it.

Now look at the shape. Each tier is bigger than the one above it and loaded less often than the one above it. That is the shape you want for every piece of context you ever design, not just skills.

When you get to subagents in week five it is this same shape again, pushed one step further: the work happens in a context you never pay for, and only the summary comes back.

---

# Why yours will not fire

![](cc-skills-why-it-does-not-fire.svg)

NOTES:
Now the mechanism, and this is the part people do not believe until they watch it happen to their own skill.

When Claude decides whether to use a skill, it reads the descriptions. That is the entire input. It does not read the body — the body is not loaded yet, and not loading it is the whole point. It does not look at your file tree. It does not look at your code. It has no idea whether the procedure inside is brilliant or garbage, because it never opens it.

So a skill whose description is Helps with PRs walks into that competition carrying three words. And nobody types help with PRs. Nobody has ever typed help with PRs. They type can you open a PR for this, or review this diff, or ship it. Not one of those words is in your description. Nothing matches. It never fires, and the excellent procedure underneath is never consulted, not once, no matter how good it is.

Look at the green one. It names the phrases a person actually types. That is not padding. That is the entire functional surface of the skill, and everything below it is interior decoration.

Which is also why a skill being really good and a skill actually firing are two unrelated claims. You can have either one without the other, and most people have the first one.

---

# Write the description first

Before the body. Before you know the steps.

- If you can state the trigger, you know what the skill is for
- If you **cannot**, you do not have a skill yet — you have a topic

Bad, in order of increasing badness:

- `Helps with testing` — no trigger, no phrases
- `Testing utilities` — a category, not a moment
- `Various helpful commands` — describes the author's intent, not the user's

NOTES:
So here is the working practice, and it inverts the order everyone naturally writes these in.

Write the description first. Before the body. Before you know a single step of the procedure. It feels backwards, and it is a design constraint doing its job: if you cannot say when this thing should run, you have not yet decided what it is.

I have watched people spend an hour on a beautiful procedure and thirty seconds on the description, and the result is an hour wasted. Spend the thirty seconds first and you will often discover that the skill is really two skills, or that it is really a CLAUDE.md fact, or that it does not exist at all and you were about to spend an afternoon building a monument to it.

Now look at the three bad ones, because they get worse in a specific direction. Helps with testing is vague — no trigger, no phrases, nothing to match against. Testing utilities is a category, and categories are how you organise a library, not how any human being has ever asked for anything. And the third one, various helpful commands, describes what the author was feeling at the time. Not one of the three contains a sentence a user would say out loud.

---

# Name the moment, not the capability

**Capability** — what it can do. Useless for selection.

**Moment** — when a person would want it. That is the trigger.

- `Runs the deploy` → `Use when the user says deploy, ship, push to prod, or asks to cut a release`
- `Grades student repos` → `Use when asked to grade a repo, score a submission, or run the rubric on a student's work`

Include the **synonyms your users actually use**, including the sloppy ones.

NOTES:
The reliable transformation is capability to moment.

Runs the deploy. That states a capability. It is true. It is also useless, because selection is a matching problem and there is almost nothing there to match. Now read across the arrow. Same skill, described by the moments it belongs to, listing the four different words people actually use for the one act.

Include the sloppy synonyms. Nobody says initiate a deployment. Nobody has said that out loud in a room with other people in it. They say ship it. And if ship it is not in your description, then ship it will never find your skill, and your skill will sit there being correct and unused.

The second example there is one of mine. It is roughly the description on the grading skill I use for this course, and the word rubric in it is load-bearing, because rubric is the word I actually type at eleven at night when I want the grading to be over.

---

# Test that it fires

Do not assume. **Check.**

1. Open a fresh session — descriptions are read at the start
2. Type the trigger phrase the way a user would, not the way you wrote it
3. Confirm the skill was actually invoked, not that a plausible answer appeared
4. Try a **paraphrase** you did not put in the description

Step 4 is the real test. Step 3 is where most people fool themselves.

NOTES:
Testing a skill is not optional and it is not hard, but there is one specific trap in it and nearly everybody walks into it.

Step three is where people go wrong. Claude is capable. It will cheerfully produce a perfectly good answer to open a PR without touching your skill at all, because it already knows how to open a PR. You see a good answer, you feel good about yourself, and you conclude that the skill fired. It did not. You have tested nothing. You have confirmed that a competent model is competent.

So confirm the invocation itself, not the quality of the output. The output was never the question.

And step four is the actual measurement. Anyone can make a skill fire on the exact sentence they wrote into the description — that is a tautology wearing a lab coat. The real question is whether it fires on a sentence you did not anticipate, because a sentence you did not anticipate is every single use of that skill after the first day.

---

# Forge 02 — due Sun Sep 21

- A skill that does something **real for your game**, not a demo
- Description written **first**, and say so in your commit
- Show it firing on a **paraphrase** you did not write into the description
- Read `cheatsheet-cc-skills`

Next Tuesday, Game: **The Engine Seams** — how the fifteen sections fit together.
Claim your section by **Sun Sep 13**.

NOTES:
Forge 02 is due on the twenty-first.

Make it something you will actually use on your own game. A skill that scaffolds a new entity type, or runs your conformance vectors, or sets up a playtest build. If it is a demo you will never run again, the description will be fictional — because you will be guessing at triggers instead of remembering them, and a guess never sounds like what a tired person types at midnight.

The third bullet is the graded one. Show me it firing on a phrasing you did not plant. That is the difference between a skill and a magic word.

And the reminder that matters more than either of those: claim your spec section by September thirteenth. That is next Sunday. Fifteen sections, first claim wins, and Tuesday's lecture is a tour of all fifteen so you can choose with your eyes open. If you already know what your game needs, open the pull request tonight and go to bed.
