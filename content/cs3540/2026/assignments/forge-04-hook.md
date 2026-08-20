# Forge 04 — A Hook

**Due:** Sun Oct 11, 2026 23:59 MT · **Points:** 60

## What to build

A `PreToolUse` hook enforcing something that must happen deterministically — not something better left to judgment.

## Evidence — half the grade

**Watch it block.** Echo a crafted event into the script, capture the exit code and the stderr. Then capture the allowed case too.

Commit the artifact to `journey/forge/04-hook/` in your repo:

```
journey/forge/04-hook/
  README.md      what it does, why, what it must not do,
                 and a LINK to its evidence
  <the artifact>

journey/evidence/forge-04-hook/
  <transcripts and output>
```

## Notes

Test the blocking case first. A guard only ever observed to allow has not been shown to guard, and a typo in a path check permits everything while looking installed. Exit 2 blocks; exit 1 is a hook error and the call proceeds.

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
