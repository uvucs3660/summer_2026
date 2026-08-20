# Forge 03 — A Subagent

**Due:** Sun Oct 4, 2026 23:59 MT · **Points:** 60

## What to build

An agent in `.claude/agents/` written as one of the five archetypes, with a mission, principles, and **anti-goals**.

## Evidence — half the grade

Show it in `/agents`, dispatch it on a real task, and capture the summary it returned.

Commit both the artifact and its evidence to `forge/03-subagent/` in your portfolio repo:

```
forge/03-subagent/
  README.md      what it does, why you built it, what it must not do
  <the artifact>
  evidence/      transcripts and output
```

Submit the commit URL.

## Notes

The anti-goals are the part that matters. An agent told to simplify will helpfully add a helpful abstraction unless you forbid it. And the prompt must be self-contained — a subagent cannot ask you a clarifying question.

## Acceptance criteria

- The artifact exists and is demonstrated working in **your own** repository.
- It solves a problem you actually had — a generic version any project could use unchanged scores half.
- `evidence/` contains a record of it running, including output.
