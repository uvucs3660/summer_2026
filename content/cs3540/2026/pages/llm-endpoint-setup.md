# LLM Setup — Runtime Models for Your Game

![Code and controller](images/code_controller.jpg)

Your game needs a language model at runtime, for NPC dialogue that responds to the player. This is **separate** from Claude Pro, which is your development environment.

## Get a free key

1. Sign up at <https://ollama.com> — no credit card.
2. Create a key at <https://ollama.com/settings/keys>.
3. Export it:

```bash
export OLLAMA_API_KEY='<your-key>'
```

Add it to your `.zshrc` or `.bashrc`. **Never commit it.**

## Smoke test

```bash
curl -s https://ollama.com/api/chat \
  -H "Authorization: Bearer $OLLAMA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma3:4b","messages":[{"role":"user","content":"Say hello in one word."}],"stream":false}'
```

That is Onboarding 4.

## One client, four endpoints

The same API and the same client code reach all of these by changing one environment variable:

| `LLM_BASE` | What |
|---|---|
| `http://localhost:11434` | Ollama on your machine — offline, unmetered |
| `https://ollama.com/api` | Ollama Cloud free tier |
| `https://llm.uvucs.org` | the class endpoint |
| `http://<teammate>:11434` | a LAN machine during a playtest |

That is the `Generator` seam in your engine, and it is why the swap requirement is genuinely config-only.

## The limits are the lesson

The free tier is metered by **GPU time**, with limits Ollama does not publish and can change, and one concurrent model.

> **No graded deliverable in this course may depend on a remote provider being reachable.** A conformance vector kills every provider and checks that your game still runs and *says so*. Design for that first.

Cache aggressively. Queue rather than parallelize. Push everything you can to build time — see `cheatsheet-local-llm-in-games`.

## Running locally

```bash
brew install ollama && ollama serve
ollama pull gemma3:4b
```

Then point `LLM_BASE` at `http://localhost:11434`. Free, offline, unmetered, and it is the fallback that will save your showcase.
