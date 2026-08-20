# Setting Up Claude Pro

Claude Pro is your textbook for this course. It is required.

## Subscribe and install

1. <https://claude.ai/upgrade> — Claude Pro, about $20/month. Verify current pricing.
2. Install Claude Code from <https://claude.com/claude-code>.
3. Check it:

```bash
claude --version
```

Submit a screenshot of your subscription dashboard for Onboarding 3.

## Why this and not the free UVU gateway

UVU's AI Gateway at `chat.uvu.edu` gives you ChatGPT, Claude, Gemini and Copilot through one login. It is genuinely useful — for reading, planning, comparing outputs, and the Council artifact later in the term. **Use it.**

It cannot replace this requirement, for a structural reason rather than a financial one:

> The 11 Pillars — CLAUDE.md, skills, subagents, hooks, MCP, plugins, permission modes — are **Claude Code** features. There is no hook in a chat box. You are graded on building these things, so you need the tool that has them.

## Claude Pro is not API access

Pro covers claude.ai and Claude Code. It does **not** include API credits.

| | Covered by Pro |
|---|---|
| Building your game with Claude Code | Yes |
| Generating lore, quests, and balance tables at build time with `claude -p` | Yes |
| Your shipped game calling a model while someone plays it | **No** |

That last row is what your free Ollama key is for. See the LLM setup page.

## Cost help

If $20/month is a hardship, **contact me before Week 1.** UVU and the department have discretionary funds for educational tooling. Do not quietly go without and fall behind — that is the outcome this paragraph exists to prevent.

## Getting the most from it

- Run `/init` in each repo, then **delete most of what it generates**. See `cheatsheet-cc-claude-md`.
- Set `/output-style explanatory` for this course.
- Learn `Esc-Esc`. It rewinds a session that has gone wrong, and it will.
