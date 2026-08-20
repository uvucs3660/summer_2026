# Forge 04 — A Hook

**Due:** Sun Oct 11, 2026 23:59 MT · **Points:** 60

## What to build

A `PreToolUse` hook enforcing something that must happen deterministically — not something better left to judgment.

## Evidence — half the grade

**Watch it block.** Echo a crafted event into the script, capture the exit code and the stderr. Then capture the allowed case too.

Commit both the artifact and its evidence to `forge/04-hook/` in your portfolio repo:

```
forge/04-hook/
  README.md      what it does, why you built it, what it must not do
  <the artifact>
  evidence/      transcripts and output
```

Submit the commit URL.

## Notes

Test the blocking case first. A guard only ever observed to allow has not been shown to guard, and a typo in a path check permits everything while looking installed. Exit 2 blocks; exit 1 is a hook error and the call proceeds.

## Acceptance criteria

- The artifact exists and is demonstrated working in **your own** repository.
- It solves a problem you actually had — a generic version any project could use unchanged scores half.
- `evidence/` contains a record of it running, including output.
