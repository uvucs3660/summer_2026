# Forge 07 — A Soul Prompt

**Due:** Sun Nov 8, 2026 23:59 MT · **Points:** 60

## What to build

A `SOUL.md` with **ranked** values, a voice, non-negotiables, and an escalation clause.

## Evidence — half the grade

Show the agent behaving differently with it and without it, on the same request.

Commit both the artifact and its evidence to `forge/07-soul/` in your portfolio repo:

```
forge/07-soul/
  README.md      what it does, why you built it, what it must not do
  <the artifact>
  evidence/      transcripts and output
```

Submit the commit URL.

## Notes

Rank the values — an unranked list is decoration, and a conflict is exactly where you need to know which one wins. Deploy with `--append-system-prompt`, never `--system-prompt`, which replaces the safety guidance too.

## Acceptance criteria

- The artifact exists and is demonstrated working in **your own** repository.
- It solves a problem you actually had — a generic version any project could use unchanged scores half.
- `evidence/` contains a record of it running, including output.
