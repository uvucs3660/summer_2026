# CC Artifact 2 — Subagent Recipe

**Due:** Sun June 7, 2026 23:59 MT
**Points:** 60
**Submission:** Commit your subagent definition to `cc-artifacts/02-subagent/`. Submit the commit URL.

## What to build

A Claude Code subagent definition that serves a clearly-articulated role. A subagent is an isolated execution context Claude can spawn for parallel investigation or specialized work.

Examples:
- A code reviewer for your team's stack.
- A PR-readiness checker.
- A test-coverage analyst.
- A vernacular auditor that scans a sprint's commits for correct pattern usage.

## Required form

Inside `cc-artifacts/02-subagent/`:

- The subagent definition file with frontmatter (`name`, `description`, optional `tools`).
- `README.md` explaining the role, when to dispatch the subagent, and what kind of output to expect.
- A demonstration of the subagent producing useful output.

## Vernacular

`README.md` uses "subagent" (not "agent", "skill", or "child process"). If you reference how it's dispatched, name the agentic loop concepts correctly.

## Grading

LLM grader against attached rubric.
