# CC Artifact 3 — Hook

**Due:** Sun June 21, 2026 23:59 MT
**Points:** 60
**Submission:** Commit your hook to `cc-artifacts/03-hook/`. Submit the commit URL.

## What to build

A Claude Code hook that automates something. Hooks are event-driven (PreToolUse, PostToolUse, Stop, SubagentStop, SessionStart, SessionEnd, UserPromptSubmit, PreCompact, Notification).

Examples:
- A `PostToolUse` hook that runs `dart format` after every file edit.
- A `PreToolUse` hook that scans command-line arguments for committed secrets.
- A `Stop` hook that prints a session-end summary of changed files and commits made.

## Required form

Inside `cc-artifacts/03-hook/`:

- The hook definition (script + settings JSON entry showing how to register it).
- `README.md` explaining the event listened to, the action taken, and why it matters.
- A demonstration showing the hook firing in a real session.

## Vernacular

`README.md` uses "hook" precisely, names the specific event correctly (e.g. "PostToolUse hook" not just "hook"), and uses event-driven-automation language correctly.

## Grading

LLM grader against attached rubric.
