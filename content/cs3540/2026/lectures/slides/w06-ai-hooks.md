---
track: ai
week: 6
title: Hooks
subtitle: The Only Deterministic Pillar
runtime: 18
---

NOTES:
Week six, AI track, and this is the odd one out.

Every other pillar in this course is a request to a model. You write a CLAUDE.md and hope it is followed. You write a skill description and hope it matches. You write a subagent prompt and hope it was unambiguous. All of it is influence.

A hook is not influence. A hook is a shell script with an exit code, and when it exits two, the tool call does not happen. Not "is discouraged from happening." Does not happen.

If you have been frustrated that instructions are sometimes ignored, this is the lecture where that stops being the only option.

---

# What you'll know after this

- Why a hook is **categorically different** from every other pillar
- What `exit 2` does, and where your **stderr** goes
- Which lifecycle event to hang a guard on
- Why a guard you have only seen **allow** has not been shown to guard

NOTES:
Four things. The last one is a testing discipline and it is the one people skip.

---

# Not a request

![](cc-hooks-exit-two.svg)

NOTES:
Here is the whole mechanism.

A hook is a command. It runs at a defined point, it gets the context on stdin, and what matters is the number it exits with.

Zero means allow — the tool call proceeds, and silence is consent. One means something went wrong in your hook itself: it gets logged, and the call proceeds anyway, which is the right default because a broken guard should not brick the session.

Two is the interesting one. Two blocks. The tool call never runs, and — this is the part people miss — whatever your script wrote to stderr is handed back as the reason. So a hook is not just a veto, it is a veto with an explanation attached, and the model gets to read that explanation and try something else.

That is a very different thing from a rule in CLAUDE.md that says "do not do X." That rule is advice. This is a wall with a sign on it.

---

# The lifecycle

![](cc-hooks-lifecycle.svg)

NOTES:
This is the cheat-sheet diagram — where the events sit.

The two you will use are `PreToolUse` and `PostToolUse`. Pre runs before the call and can block it, which is where guards live. Post runs after and cannot block anything — it is for reacting: formatting a file that was just written, running a linter, appending to a log.

`UserPromptSubmit` fires before your message is processed and can inject context. `SessionStart` and `SessionEnd` bookend the whole thing.

The rule for choosing is simple. If you want to prevent something, it has to be Pre, because Post is too late — the tool already ran. If you want to react to something, use Post, because blocking in Post is not available and trying to fake it produces confusing behavior.

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

The failure it prevents is one you will genuinely hit. Your implementation disagrees with a conformance vector. The vector says the hash should be one number and you produce another. There is a very tempting five-second fix, which is to edit the expected number.

That is not a fix. That is deleting the oracle. Now your build passes and it agrees with nothing.

So: a PreToolUse hook that notices you are editing a file containing an expectation and refuses. Exit two, and the stderr line explains why — including what to do instead, which is change the implementation.

Notice how much work that message is doing. It does not just block; it redirects. A guard that says "no" produces a retry. A guard that says "no, and here is the actual problem" produces the right change.

---

# Show it blocking

A guard you have only ever seen **allow** has not been shown to guard.

1. Write the hook
2. **Deliberately attempt the forbidden thing**
3. See it blocked, and read the reason that came back
4. Then confirm the allowed path still works

Step 2 is the test. Steps 1, 3, and 4 are bookkeeping.

NOTES:
And here is the discipline, which is the same one from the skills lecture wearing different clothes.

With skills, the trap was seeing a good answer and assuming your skill fired. Here the trap is installing a hook, working normally for a day, nothing breaks, and concluding it works. You have observed a guard exiting zero. You have not observed it guarding.

So deliberately do the forbidden thing. Try to edit a vector. Watch it get blocked, and read the message that came back — because that is also how you find out your message was unhelpful, or that your matching condition was wrong and it blocks more than you meant.

Then check the allowed path still works, because the second failure mode of guards is that they are too broad and you have quietly made ordinary work impossible.

This is the same standard as a conformance vector, and the same as an anti-goal you can show firing. A check you have never seen fail is not yet evidence of anything.

---

# Forge 04 — due Sun Oct 12

- A `PreToolUse` hook that **guards something real in your repo**
- `exit 2`, with a **stderr message that says what to do instead**
- Show it **blocking**, and show the allowed path still working
- Read `cheatsheet-cc-hooks`

Next Tuesday, Game: **Contact** — collision, budgets, and profiling.

NOTES:
Forge 04, due October twelfth.

Guard something real. Conformance vectors are the obvious candidate for this course, but there are others — blocking commits straight to main, blocking a secret being written into a tracked file, blocking edits to generated output that will be overwritten anyway.

And the third bullet is the graded one, for all the reasons I just gave. Two transcripts: one where it blocked, one where it allowed.

Next Tuesday is collision, and it opens with a number I want you to sit with before you watch it — how many pairs are there among five thousand bodies? Guess before Tuesday. Most people are off by three orders of magnitude.
