# CC Artifact 1 — Custom Claude Code Skill

**Due:** Sun May 24, 2026 23:59 MT
**Points:** 60
**Submission:** Commit your skill to your portfolio repo at `cc-artifacts/01-skill/`. Submit the commit URL.

## What to build

A Claude Code skill (`SKILL.md` with YAML frontmatter and a markdown body) that helps with your Sprint 1 work. The skill must earn its keep — it should automate something you actually do repeatedly, not be a toy.

Examples that would qualify:
- `/review-resume` — checks a résumé draft for ATS compatibility (passes a job description, scans for keyword coverage and red flags).
- `/lint-prompt` — given an Ollama prompt template, suggests improvements for clarity, output structure, and token efficiency.
- `/swap-llm-backend` — guided refactor that moves your code between class-Ollama / Claude API / local backends.

## Required form

Inside `cc-artifacts/01-skill/`:

- `SKILL.md` with YAML frontmatter (`name`, `description`, optional `tools`) followed by markdown instructions.
- `README.md` explaining when to invoke the skill and why it helps.
- A short demonstration showing the skill in use (transcript snippet, screenshot, or recorded video link).

## Vernacular

Your `README.md` must use Claude Code vocabulary precisely: the word "skill" (not "tool" or "command" or "prompt"), and any related concepts (progressive disclosure, agentic loop, context injection) used correctly.

## Grading

LLM grader scores against the attached rubric. Misuse of CC vocabulary (e.g. calling your skill a "hook") will lose rubric points.
