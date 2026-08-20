# Onboarding 3/5 — Proof of Claude Pro Subscription

**Due:** Sun Aug 23, 2026 23:59 MT
**Points:** 1 (pass/fail)

## What to do

1. Subscribe to Claude Pro at <https://claude.ai/upgrade> (~$20/month — verify current pricing).
2. Install Claude Code from <https://claude.com/claude-code>.
3. Verify the install:

```bash
claude --version
```

4. Commit a screenshot of your subscription dashboard to `week1/claude-pro-proof.png` in your
   repo here.

## Why a subscription and not the free UVU gateway

UVU's AI Gateway at `chat.uvu.edu` gives you ChatGPT, Claude, Gemini, and Copilot through one
login, and it is genuinely useful — for reading, planning, comparing model outputs, and the Council
exercise later in the term. Use it.

It cannot replace this requirement, and the reason is structural rather than financial:

> The 11 Pillars of Claude Code — CLAUDE.md, skills, subagents, hooks, MCP servers, plugins,
> model selection, output styles, permission modes — are **Claude Code** features. There is no hook
> in a chat box. You will be graded on building these things, which means you need the tool that
> has them.

Note also that **Claude Pro is not API access.** Pro covers claude.ai and Claude Code. A game that
calls a language model while someone is playing it needs its own key — that is assignment 4.

## Cost help

If $20/month is a hardship, **contact me before Week 1.** UVU and the CS department have
discretionary funds for educational tooling. Do not quietly go without and fall behind.

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria

- Screenshot shows an active Claude Pro subscription.
- `claude --version` produces output (paste it into the commit message or the file).
- Committed to `week1/claude-pro-proof.png` and the commit URL submitted here.
