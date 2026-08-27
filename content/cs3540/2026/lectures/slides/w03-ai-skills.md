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

I want to set an expectation before we start. Most people's first skill does not work. Not "works badly" — does not run at all, ever, not once. They write a genuinely good procedure, install it, use Claude for a week, and it never fires. Then they conclude skills are unreliable.

They are not unreliable. The skill was invisible, for a reason that is completely mechanical and completely fixable, and that reason is most of this lecture.

---

# What you'll know after this

- What a skill actually **is** — and the two halves that are billed differently
- **Progressive disclosure**: description, then body, then references
- Why selection reads your **description and nothing else**
- How to write a description that fires, and how to test that it did

NOTES:
Four things. The third one is the load-bearing one, and everything about how you write these follows from it.

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
Mechanically a skill is a directory with a markdown file in it, and the markdown file has YAML frontmatter with two fields that matter: a name and a description.

Below the frontmatter is the body — ordinary markdown, the actual procedure. And a skill can link to further files, which load only if the body references them and the body itself got loaded.

The distinction I want you to hold is the last line. The frontmatter is a contract about *when this should be used*. The body is *what to do*. People spend all their effort on the second one and almost none on the first, and the first is the one that decides whether the second ever runs.

---

# Billed on different schedules

![](cc-skills-anatomy.svg)

NOTES:
Here is why the two halves are not equally cheap.

The description is loaded for every installed skill, on every turn, forever — same deal as CLAUDE.md. Fifty skills at roughly twenty tokens of description each is about a thousand tokens you are paying on every single request, whether or not any of them is relevant.

The body is different. It loads only on the turn its description matched. Two thousand tokens, occasionally, is nothing.

So the economics tell you exactly how to write each half. The description must be short, because you pay it always — but it must also be *specific*, and those pull against each other, which is the whole craft. The body can be as long as the procedure genuinely needs, because you almost never pay for it.

That asymmetry is progressive disclosure, and it is the same idea as the accumulator: separate the thing that happens always from the thing that happens sometimes.

---

# Progressive disclosure

![](cc-skills-progressive-disclosure.svg)

NOTES:
This is the cheat-sheet diagram for the week, and it generalises the point.

Three tiers. The description is tier one and always resident. The body is tier two, pulled in on a match. Anything the body links — a long reference table, a code template, an example file — is tier three, and only arrives if the body actually points at it.

Each tier is bigger than the last and loaded less often than the last. That is the shape you want for every piece of context you design, not just skills. When you get to subagents in week five it is the same shape again, pushed further: the work happens in a context you never pay for, and only the summary comes back.

---

# Why yours will not fire

![](cc-skills-why-it-does-not-fire.svg)

NOTES:
Now the mechanism, and this is the part people do not believe until they see it.

When Claude decides whether to use a skill, it reads the descriptions. That is the entire input. It does not read the body — the body is not loaded yet, that is the point of not loading it. It does not look at your file tree, or your code, or how well-written the procedure is.

So a skill whose description is "Helps with PRs" is competing for selection with nothing but those three words. Nobody types "help with PRs." They type "can you open a PR for this" or "review this diff" or "ship it." None of those words appear in your description, so nothing matches, so it never fires — no matter how excellent the body is.

Look at the green one. It names the phrases a person actually types. That is not padding, it is the entire functional surface of the skill.

This is also why "my skill is really good" and "my skill fires" are unrelated statements. You can have either without the other.

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
So here is the working practice, and it inverts how everyone naturally writes these.

Write the description first, before you write a single step of the procedure. It feels backwards. It is a design constraint doing its job: if you cannot say when this thing should run, you have not decided what it is.

I have watched people spend an hour on a beautiful procedure and thirty seconds on the description, and the result is an hour wasted. Spend the thirty seconds first and you will often discover the skill is actually two skills, or that it is really a CLAUDE.md fact, or that it does not exist.

Look at the three bad ones and notice they get worse in a specific direction. The first is vague. The second is a category — categories are how you organise a library, not how anyone asks for something. And the third describes what the author was feeling. None of them contain a sentence a user would say.

---

# Name the moment, not the capability

**Capability** — what it can do. Useless for selection.

**Moment** — when a person would want it. That is the trigger.

- `Runs the deploy` → `Use when the user says deploy, ship, push to prod, or asks to cut a release`
- `Grades student repos` → `Use when asked to grade a repo, score a submission, or run the rubric on a student's work`

Include the **synonyms your users actually use**, including the sloppy ones.

NOTES:
The reliable transformation is capability to moment.

"Runs the deploy" states a capability. It is true, and it is useless, because selection is a matching problem and there is almost nothing there to match. Now read the arrow: same skill, described by the moments it belongs to, and listing the four different words people use for the same act.

Include the sloppy synonyms. Nobody says "initiate a deployment." They say "ship it." If "ship it" is not in your description, "ship it" will not find your skill.

The second example is one of mine — it is roughly the description on the grading skill I use for this course, and the word "rubric" in there is load-bearing, because that is what I actually type at eleven at night.

---

# Test that it fires

Do not assume. **Check.**

1. Open a fresh session — descriptions are read at the start
2. Type the trigger phrase the way a user would, not the way you wrote it
3. Confirm the skill was actually invoked, not that a plausible answer appeared
4. Try a **paraphrase** you did not put in the description

Step 4 is the real test. Step 3 is where most people fool themselves.

NOTES:
Testing a skill is not optional and it is not hard, but there is a specific trap in it.

Step three is where people go wrong. Claude is capable. It will often produce a perfectly good answer to "open a PR" without using your skill at all, because it knows how to open a PR. You see a good answer and conclude the skill fired. It did not. You have tested nothing.

So confirm the invocation itself, not the quality of the output.

And step four is the actual measurement. Anyone can make a skill fire on the exact sentence they put in the description — that is a tautology, not a test. The question is whether it fires on a sentence you did not anticipate, because that is every real use after the first day.

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

Make it something you will actually use on your own game. A skill that scaffolds a new entity type, or runs your conformance vectors, or sets up a playtest build. If it is a demo you will never run again, the description will be fictional, because you will be guessing at triggers instead of remembering them.

The third bullet is the graded one. Show me it firing on a phrasing you did not plant. That is the difference between a skill and a magic word.

And the reminder that matters more than either: claim your spec section by September thirteenth. That is next Sunday. Fifteen sections, first claim wins, and Tuesday's lecture is a tour of all fifteen so you can choose with your eyes open. If you already know what your game needs, open the pull request tonight and stop thinking about it.
