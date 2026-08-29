---
track: ai
week: 6
title: Hooks
subtitle: The Only Deterministic Pillar
runtime: 18
---

NOTES:
Week six, AI track, and this is the odd one out.

Every other pillar in this course is a request to a model. You write a CLAUDE.md and hope it is followed. You write a skill description and hope it matches. You write a subagent prompt and hope it was unambiguous. All of it is influence. And influence is what you have when you put do not touch this file in capital letters at the top of a document and then watch that file get touched.

A hook is not influence. A hook is a shell script with an exit code, and when it exits two, the tool call does not happen. Not is discouraged from happening. Not usually does not happen. Does not happen. There is no model anywhere in that sentence — your script decides, before the call is issued, and nothing downstream gets a vote.

If you have been quietly frustrated that instructions are sometimes ignored, this is the lecture where that stops being your only option.

---

# What you'll know after this

- Why a hook is **categorically different** from every other pillar
- What `exit 2` does, and where your **stderr** goes
- Which lifecycle event to hang a guard on
- Why a guard you have only seen **allow** has not been shown to guard

NOTES:
Four things. The last one is a testing discipline rather than a mechanism, and it is the one people skip, because a guard that has never fired looks identical to a guard that works.

---

# Not a request

![](cc-hooks-exit-two.svg)

NOTES:
Here is the whole mechanism, and it is worth being exact about, because each of these numbers means a specific thing.

A hook is a command. It runs at a defined point, it gets the context on standard input, and what matters is the number it exits with.

Zero means allow. The tool call proceeds, and silence is consent — you never have to say yes, you only have to not say no.

One means something went wrong inside your hook itself. A missing file, a typo, a command that was not installed. It gets logged, and the tool call proceeds anyway. That is the right default, because a broken guard should degrade into no guard rather than into a session you cannot use.

Two is the one that blocks. The tool call never runs. And here is the part people miss: whatever your script wrote to standard error comes back as the reason. So a hook is not just a veto. It is a veto with an explanation attached, and the model reads that explanation and gets to try something else.

Which is a categorically different object from a line in CLAUDE.md that says do not do X. That line is advice. This is a wall with a sign on it.

---

# The lifecycle

![](cc-hooks-lifecycle.svg)

NOTES:
This is the cheat-sheet diagram, and it is simply where the events sit.

The two you will actually use are PreToolUse and PostToolUse. Pre runs before the call and can block it, and that is where every guard lives. Post runs after, and cannot block anything, because the tool has already run. Post is for reacting: format the file that was just written, run the linter, append to a log.

UserPromptSubmit fires before your message is processed and can inject context into it. SessionStart and SessionEnd bookend the whole thing.

The rule for choosing is one sentence. If you want to prevent something, it has to be Pre, because Post is too late by definition. If you want to react to something, use Post, and do not try to fake blocking from there. You cannot, and the attempt produces behavior that is miserable to debug later.

---

# The conformance guard

The thing this course actually needs:

```bash
#!/usr/bin/env bash
# PreToolUse — block edits to a committed conformance vector
if grep -q '"expect"' "$CLAUDE_FILE_PATH" 2>/dev/null; then
  echo "Refusing to edit a conformance vector. \
Vectors are the oracle — change the implementation, not the test." >&2
  exit 2
fi
exit 0
```

The stderr line is the part that does the work.

NOTES:
Here is a guard worth having in this specific course, and I will write it live in class.

The failure it prevents is one you are genuinely going to hit. Your implementation disagrees with a conformance vector. The vector says the hash should be one number and you are producing a different one. And there is a five-second fix sitting right there, which is to edit the expected number until it matches what you already produce.

That is not a fix. That is deleting the oracle. Your build passes afterwards and it agrees with nothing at all, because a test written after the answer is guaranteed to pass and guarantees nothing.

So: a PreToolUse hook that notices you are editing a file containing an expectation, and refuses. Exit two, and the standard error line explains why, including what to do instead, which is change the implementation.

Notice how much work that message is doing. It does not only block, it redirects. A guard that says no produces a retry — the same edit, phrased slightly differently. A guard that says no, and here is the actual problem, produces the right change.

---

# Show it blocking

A guard you have only ever seen **allow** has not been shown to guard.

1. Write the hook
2. **Deliberately attempt the forbidden thing**
3. See it blocked, and read the reason that came back
4. Then confirm the allowed path still works

Step 2 is the test. Steps 1, 3, and 4 are bookkeeping.

NOTES:
And here is the discipline, which is the skills lecture's trap wearing different clothes.

With skills, the trap was seeing a good answer and concluding your skill had fired. Here the trap is installing a hook, working normally for a day, nothing breaking, and concluding it works. What you observed was a guard exiting zero a few hundred times. You have not observed it guarding once.

So go and deliberately do the forbidden thing. Try to edit a vector. Watch it get blocked, and read the message that came back, because that is also how you discover your message was unhelpful, or that your matching condition was wrong and it is blocking far more than you meant it to.

Then check the allowed path still works, because the second failure mode of guards is that they are too broad, and you have quietly made ordinary work impossible for yourself in a way you will not connect back to the hook three days from now.

Same standard as a conformance vector. Same standard as an anti-goal you can show firing. A check you have never seen fail is not yet evidence of anything.

---

# Forge 04 — due Sun Oct 12

- A `PreToolUse` hook that **guards something real in your repo**
- `exit 2`, with a **stderr message that says what to do instead**
- Show it **blocking**, and show the allowed path still working
- Read `cheatsheet-cc-hooks`

Next Tuesday, Game: **Contact** — collision, budgets, and profiling.

NOTES:
Forge 04, due October twelfth.

Guard something real. Conformance vectors are the obvious candidate for this course, but there are others and some will fit your repository better — blocking a commit straight to main, blocking a secret being written into a tracked file, blocking edits to generated output that the next build is going to overwrite anyway.

And the third bullet is the graded one, for all the reasons I just gave. Two transcripts. One where it blocked, one where it allowed. Both, because with only the second one I cannot tell a guard from a file you created.

Next Tuesday is collision, and it opens with a number I want you to sit with before you watch it. How many pairs are there among five thousand bodies? Guess before Tuesday, write the guess down, and bring it with you. Most people are off by three orders of magnitude, and that gap is the entire reason broadphase exists.
