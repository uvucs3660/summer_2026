# Onboarding 4/5 — Ollama Cloud Key + Smoke Test

**Due:** Wed Aug 26, 2026 23:59 MT
**Points:** 1 (pass/fail)
**Prerequisite:** Assignment 1 (portfolio repo provisioned).

## What to do

1. Create a free account at <https://ollama.com> and generate an API key at
   <https://ollama.com/settings/keys>. No credit card required.
2. Export it in your shell (add to `.zshrc` or `.bashrc`):

```bash
export OLLAMA_API_KEY='<your-key-here>'
```

3. Run a real call:

```bash
curl -s https://ollama.com/api/chat \
  -H "Authorization: Bearer $OLLAMA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma3:4b","messages":[{"role":"user","content":"Say hello in one word."}],"stream":false}'
```

Expected: JSON containing the model's one-word greeting.

## How to submit

Commit `week1/ollama-smoke-test.md` to your portfolio repo containing:

- The exact command you ran, with the key replaced by `<REDACTED>`.
- The full JSON response.
- Two or three sentences on what surprised you — latency, output quality, anything.

Submit the commit URL here.

> **Never commit the key itself.** If you think you have leaked it, revoke it at
> <https://ollama.com/settings/keys> immediately and generate a new one.

## Why Ollama specifically

The same client code and the same API reach four different places by changing one environment
variable: your laptop (`localhost:11434`), Ollama's cloud, the class endpoint, and a teammate's
machine on the LAN during a playtest. You will build that swap as a real seam in your engine, and
it must be swappable by configuration alone.

## The limits are the lesson

The free tier is metered by **GPU time**, with limits Ollama does not publish and can change. One
concurrent model.

Design for that from the start. **No graded deliverable in this course may depend on a remote
provider being reachable** — the engine spec requires a working local or procedural fallback, and
there is a conformance test that kills every remote provider and checks that your game still runs
and degrades visibly. A quota exhausted the night before the showcase must be survivable.

## Acceptance criteria

- Command shown, key redacted.
- Response JSON included and non-empty.
- Note is present.
- The key does not appear anywhere in the repository.

## Troubleshooting

- **401 Unauthorized** — key wrong, not exported, or revoked. Check `echo $OLLAMA_API_KEY`.
- **429 / quota** — you have hit the free-tier ceiling. Wait for the session window to reset, or
  install Ollama locally and point at `http://localhost:11434`. Both are valid submissions.
