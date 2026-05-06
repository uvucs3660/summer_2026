# Class LLM Endpoint Setup & API Keys

The class operates a hosted Ollama LLM service for student project use. This is **separate** from your Claude Pro account — Claude Pro is your "textbook" / dev assistant; the class endpoint is your "production" LLM infrastructure for project work.

## Endpoint

- **Base URL:** `https://llm.uvucs.org` (subject to change at infra setup; check this page for the current URL)
- **Auth:** Bearer token (your personal API key)
- **Models available:** `llama3.2:1b` (fast), `llama3.3:70b` (high quality). Other models may be added; check `/api/models`.
- **Status page:** `https://llm.uvucs.org/status`

## Getting your API key

Your key is issued automatically when you complete onboarding assignment 4 (GitHub username submission). It arrives via Canvas direct message.

**Keep it private.** Save it as the env var `CS3660_LLM_KEY` in your shell. Never commit it to a repo.

## Smoke test

See [Onboarding 5/5](#) for the required first call.

## Rate limits

- 60 requests / minute / key (rolling window)
- 4 concurrent requests / key

If you hit a limit, you'll get HTTP 429 with a `Retry-After` header. Don't fight it — use it as the prompt to think about caching, batching, or backoff.

## What this is, in vernacular

The endpoint is an instance of:

- **Service Activator** (Enterprise Integration Pattern) — incoming HTTP requests trigger model inference.
- **Adapter** (GoF) — wraps Ollama's native API as a stable HTTP contract.
- **Perfect Framework: Security** — API keys, auth, rate limiting.
- **Perfect Framework: Scale** — shared resource with quotas.
- **Perfect Framework: Application > Workflow** — async / streaming response handling.

You'll discuss these in your W2 reflection.

## Outage policy

When the endpoint is down, fall back to Claude API (your Claude Pro account) via the Strategy pattern in your code. This is one of the reasons Sprint 1 requires the Strategy pattern for LLM backend selection.

## Key rotation / abuse

If you suspect your key has leaked, DM the instructor immediately. Old key revoked, new key issued.
