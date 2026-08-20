# Forge 01 — CLAUDE.md

**Due:** Sun Sep 6, 2026 23:59 MT · **Points:** 60

## What to build

A `CLAUDE.md` in your repo that makes a **fresh session** use the right commands unprompted.

## Evidence — half the grade

Start a new session and ask for something that needs the knowledge — "run the tests." Capture the transcript showing it used your command without being told.

Commit the artifact to `journey/forge/01-claude-md/` in your repo:

```
journey/forge/01-claude-md/
  README.md      what it does, why, what it must not do,
                 and a LINK to its evidence
  <the artifact>

journey/evidence/forge-01-claude-md/
  <transcripts and output>
```

## Notes

Write what is true, not what you wish were true. A file describing conventions the repo does not follow teaches the model to trust something that lies. And keep it short: every byte is paid for on every turn, forever.

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria

- The artifact exists and is demonstrated working in **your own** repository.
- It solves a problem you actually had — a generic version any project could use unchanged scores half.
- `evidence/` contains a record of it running, including output.
