# Forge 09 — The Guarded Agent

**Due:** Thu Dec 3, 2026 23:59 MT · **Points:** 60

## What to build

Everything composed: a soul at the top of a subagent definition, narrowed `tools:`, a `PreToolUse` guard on your two scariest operations, a scoped connection, and a spec for one small mission. Bundled plugin-style.

## Evidence — half the grade

**The declined-versus-blocked demo.** Ask it to do something the SOUL forbids — it refuses, with reasoning. Ask it to do something the HOOK forbids — the call is cancelled, exit 2, reason on stderr. Capture both.

Commit both the artifact and its evidence to `forge/09-guarded-agent/` in your portfolio repo:

```
forge/09-guarded-agent/
  README.md      what it does, why you built it, what it must not do
  <the artifact>
  evidence/      transcripts and output
```

Submit the commit URL.

## Notes

That difference is the whole point. The soul makes it *want* to behave and is persuadable in principle; the hook makes misbehavior *impossible*. Observe both or the artifact is incomplete.

## Acceptance criteria

- The artifact exists and is demonstrated working in **your own** repository.
- It solves a problem you actually had — a generic version any project could use unchanged scores half.
- `evidence/` contains a record of it running, including output.
