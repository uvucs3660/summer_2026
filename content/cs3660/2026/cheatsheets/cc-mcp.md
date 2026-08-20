# MCP Cheat Sheet (80/20)

MCP (Model Context Protocol) is how Claude Code reaches outside its own sandbox. This cheat sheet is the 20% of MCP you'll use 80% of the time — what a server is, the three transports, how to wire one up in `.mcp.json`, and which servers are worth your time. The goal: stop copy-pasting query results and PR comments into the chat, and let Claude touch your real systems directly.

Individual Claude Code Artifact #4 (rubric `cc-artifact-4-mcp`) requires you to configure and *use* at least one MCP server in your capstone. This sheet is what that means in practice.

![Claude Code as MCP host talking over the protocol to multiple servers, each exposing tools and resources to an external system](diagrams/cc-mcp.svg)

## What MCP is (and isn't)

**Is**: an open protocol that connects Claude to external services as first-class, callable tools. You run (or point at) a small **MCP server** for each system you want Claude to reach. Claude Code is the **host/client**; it speaks the same protocol to every server, no matter what's behind it.

**Isn't**: a way to give Claude magic new abilities for free. Every server is real software running on your machine (or a remote endpoint) with *your* privileges. MCP is plumbing, not a superpower — the power comes from the systems you connect.

Each MCP server exposes up to three things:

- **Tools** — functions Claude can *call* (run a SQL query, open a PR, click a button). This is the workhorse.
- **Resources** — data Claude can *read* (a file, a schema, a doc page). Read-only context, pulled on demand.
- **Prompts** — optional pre-baked prompt templates the server offers.

The shape is always the same:

```
[ Claude Code (host) ]
        │  speaks MCP (one uniform protocol)
        ▼
[ MCP server ]  ──── tools + resources ────► [ GitHub / Postgres / browser / docs / files ]
```

One protocol in the middle; many different systems behind it. That uniformity is the whole point — Claude learns the protocol once and every server plugs in the same way.

## The three transports

How Claude Code *talks* to a server. You pick one per server when you configure it.

| Transport | How it works | Use when |
|---|---|---|
| **stdio** | Claude launches the server as a local subprocess and talks over stdin/stdout | Most common. Local tools, anything you run with `npx`/`docker`. Default choice. |
| **SSE** | Server-Sent Events over HTTP to a long-running endpoint | Remote/hosted server you connect to, streaming responses |
| **HTTP** | Plain request/response to a remote HTTP endpoint | Remote/hosted server, simpler request model |

For Sprint work you'll almost always use **stdio** — the server is a package Claude spawns on demand. SSE and HTTP matter when someone *hosts* a server for the whole team.

## Common servers

| Server | What it gives Claude | Tools / resources |
|---|---|---|
| **filesystem** | Scoped file access (often a dir outside the project root) | read/write/list files |
| **github** | Issues, PRs, repos, releases | open PR, comment, create issue, read repo |
| **postgres** | Query a database directly | run SQL; read table schemas as resources |
| **playwright** | Drive a real browser | navigate, click, fill, screenshot, assert |
| **context7** | Fetch *live* docs for any library | resolve library, pull current API docs |
| **sequential-thinking** | Structured chain-of-thought scratchpad | step-by-step reasoning tool |

The payoff in one line each: query the prod DB without exporting a CSV, comment on a GitHub PR without leaving the terminal, test your app in a real browser, and read *today's* library docs instead of Claude's training-cutoff memory.

## Configuring servers in `.mcp.json`

Two places servers can live:

- **`.mcp.json` at the project root** — checked into git, shared with your team. This is what the rubric wants: your capstone repo ships a working `.mcp.json`.
- **User config** (via `claude mcp add ...`) — personal servers, not shared.

A real project `.mcp.json` with two servers — Postgres and GitHub — using environment-variable substitution for every secret:

```json
{
  "mcpServers": {
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "${DATABASE_URL}"
      ]
    },
    "github": {
      "type": "stdio",
      "command": "docker",
      "args": ["run", "-i", "--rm", "ghcr.io/github/github-mcp-server"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GH_TOKEN}"
      }
    }
  }
}
```

Then in your shell (or a gitignored `.env` your shell loads):

```bash
export DATABASE_URL="postgres://app:secret@localhost:5432/capstone"
export GH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
```

The rule that keeps you out of trouble: **`${ENV_VAR}` for every secret, never the literal token.** `.mcp.json` is committed; a hardcoded token is a committed credential leak. Scope the token to the minimum it needs (a read-only PAT, a DB user with only the grants you use).

### Adding from the CLI

```bash
# Add context7 for the whole project (writes to .mcp.json)
claude mcp add --scope project context7 -- npx -y @upstash/context7-mcp

# Add a personal server (user scope, not shared)
claude mcp add github -- docker run -i --rm ghcr.io/github/github-mcp-server

claude mcp list           # see what's configured
```

### Verify it loaded

Inside Claude Code:

```
/mcp
```

`/mcp` lists every configured server and its status (connected / failed). Once a server is connected, its tools show up and Claude can call them. If a server isn't in this list, Claude can't use it — fix the config first.

## A typical capstone setup

The rubric line is satisfied by actually *using* a server in your demo or write-up. A common combination:

- **github** — Claude opens issues from your TODO list, reviews and comments on teammate PRs.
- **postgres** — Claude inspects your real schema and writes queries against it instead of guessing column names.
- **context7** — Claude pulls current docs for whatever framework you chose, avoiding stale-API hallucinations.

Show one of these working end to end (ask → tool call → result → action taken) and you've cleared `cc-artifact-4-mcp`.

## What this is in vernacular

- MCP ≈ **Adapter** (GoF) — a uniform interface (tools + resources) wrapping disparate external systems so Claude treats GitHub, Postgres, and a browser identically.
- The protocol channel ≈ **Message Channel** (EIP) — a defined conduit carrying typed messages between Claude (the host) and each service.
- Tools vs. resources ≈ **command vs. query** — tools *do* things (side effects); resources *read* things (no side effects).
- A server registry (`/mcp`) ≈ **Service Locator** — Claude discovers available capabilities at runtime instead of having them hardcoded.

## Security: read this before adding a server

MCP servers run **with your privileges** and can read and write real systems. Treat every server like installing software, because it is.

- **Only add servers you trust.** A malicious server can exfiltrate files, push to your repos, or drop tables.
- **Scope tokens minimally.** Read-only PAT if you only read. DB user with only the grants you use. Never a god-mode token "to be safe."
- **Point Postgres at a dev/staging DB**, not production, while you're learning. A bad generated `DELETE` is a real `DELETE`.
- **Never commit the secret.** `${ENV_VAR}` in `.mcp.json`; the real value in a gitignored `.env` or your shell.
- **Review what the server can do** before connecting — its tool list is its blast radius.

## Common failure modes

- **Server not in `/mcp`.** It failed to start. Check the command/args run on their own in a terminal; check the env vars are exported in the shell that launched Claude Code.
- **Hardcoded token in `.mcp.json`.** Works locally, leaks the moment you push. Use `${ENV_VAR}` and rotate any token you already committed.
- **`${VAR}` is empty.** You exported it in a different shell than the one running Claude Code, or your `.env` isn't loaded. `echo $DATABASE_URL` to confirm.
- **Over-privileged token.** A full-access PAT for a server that only reads issues. Minimize scope; the blast radius is whatever you grant.
- **Pointing Postgres at prod "just to demo."** Generated SQL runs for real. Use a throwaway DB until you trust the workflow.
- **Adding ten servers you don't use.** Each one is more attack surface and more tool noise in context. Add what the task needs, nothing more.
- **Expecting tools without restart.** New `.mcp.json` entries load on session start. After editing it, restart Claude Code (or re-run `/mcp`) so the server connects.

## Further reading

- **`modelcontextprotocol.io`** — the open spec, transports, and server catalog.
- **`code.claude.com/docs/en/mcp`** — Claude Code's MCP setup, `.mcp.json` scopes, and the `claude mcp` CLI.
- **`cheatsheet-claude-code-capabilities`** — where MCP sits among hooks, sub-agents, and skills.
- **`cheatsheet-git-workflow`** — what the `github` server automates on your behalf.
