# CC Artifact 5 — Plugin

**Due:** Sun August 2, 2026 23:59 MT
**Points:** 60
**Submission:** Commit your plugin to `cc-artifacts/05-plugin/`. Submit the commit URL.

## What to build

A Claude Code plugin that bundles **at least two** of your prior artifacts (skill, subagent, hook, MCP integration) into a single distributable package.

A plugin is the distribution unit for CC extensions. It contains a `plugin.json` manifest and one or more component types (skills, agents, hooks, MCP server configs, slash commands).

## Required form

Inside `cc-artifacts/05-plugin/`:

- `plugin.json` manifest declaring the plugin's name, version, and components.
- The bundled components (copy or reference your earlier artifacts; prefer copy for self-containment).
- `README.md` explaining what the plugin does, how to install it, and how the bundled components compose.
- (Encouraged) A `LICENSE` and a published version on a personal git repo or marketplace.

## Vernacular

README uses "plugin" precisely, distinguishes it from "skill" / "subagent" / "hook" / "MCP server", and explains the composition story (this is what plugins exist for — distribution + composition).

## Grading

LLM grader against attached rubric. Reuse from prior artifacts is encouraged; plagiarism (someone else's plugin renamed) is not.
