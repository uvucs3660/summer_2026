# CC Artifact 4 — MCP Integration

**Due:** Sun July 13, 2026 23:59 MT
**Points:** 60
**Submission:** Commit MCP server + config to `cc-artifacts/04-mcp/`. Submit the commit URL.

## What to build

An MCP (Model Context Protocol) server that connects Claude Code to an external service. The MCP server exposes tools, resources, and/or prompts that Claude can use during a session.

Examples:
- An MCP server connecting CC to a PostgreSQL database for query/inspection.
- An MCP server wrapping the class LLM endpoint so CC can invoke Ollama directly.
- An MCP server wrapping the GitHub API with course-specific shortcuts.
- An MCP server connecting CC to a hardware device (Bluetooth, USB) for IoT-class projects.

## Required form

Inside `cc-artifacts/04-mcp/`:

- The MCP server source (Python, Node, or Dart).
- A `claude.json` or equivalent config showing how to register the server.
- `README.md` explaining what tools/resources/prompts are exposed and how to use them.
- A demonstration of CC using the MCP server.

## Vernacular

README uses MCP vocabulary precisely: "MCP server" / "tool" / "resource" / "prompt" / "stdio vs HTTP transport". Cite the protocol where relevant.

## Grading

LLM grader against attached rubric.
