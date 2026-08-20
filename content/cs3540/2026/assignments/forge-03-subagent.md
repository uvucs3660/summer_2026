# Forge 03 — A Subagent

**Due:** Sun Oct 4, 2026 23:59 MT · **Points:** 60

## What to build

An agent in `.claude/agents/` written as one of the five archetypes, with a mission, principles, and **anti-goals**.

## Evidence — half the grade

Show it in `/agents`, dispatch it on a real task, and capture the summary it returned.

Commit the artifact to `journey/forge/03-subagent/` in your repo:

```
journey/forge/03-subagent/
  README.md      what it does, why, what it must not do,
                 and a LINK to its evidence
  <the artifact>

journey/evidence/forge-03-subagent/
  <transcripts and output>
```

## Notes

The anti-goals are the part that matters. An agent told to simplify will helpfully add a helpful abstraction unless you forbid it. And the prompt must be self-contained — a subagent cannot ask you a clarifying question.

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
