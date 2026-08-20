# Forge 05 — An MCP Server

**Due:** Sun Oct 25, 2026 23:59 MT · **Points:** 60

## What to build

A configured MCP server in `.mcp.json`, scoped to the minimum the task needs.

## Evidence — half the grade

`/mcp` showing it connected, plus one real tool call and its result.

Commit the artifact to `journey/forge/05-mcp/` in your repo:

```
journey/forge/05-mcp/
  README.md      what it does, why, what it must not do,
                 and a LINK to its evidence
  <the artifact>

journey/evidence/forge-05-mcp/
  <transcripts and output>
```

## Notes

Read the tool list before you install — a server runs with your privileges and its tool list is its blast radius. `${ENV_VAR}` for every secret: `.mcp.json` is committed.

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
