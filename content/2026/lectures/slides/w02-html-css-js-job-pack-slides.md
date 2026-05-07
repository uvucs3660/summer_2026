---
marp: true
theme: default
class: invert
paginate: true
size: 16:9
style: |
  section { font-size: 28px; }
  h1 { font-size: 56px; color: #fcd34d; }
  h2 { font-size: 42px; color: #60a5fa; }
  code { background: #1f2937; padding: 2px 6px; border-radius: 4px; }
---

# Week 2 — HTML/CSS/JS Refresh
## Job Pack Kickoff · LLM Endpoint Primer

---

# What you'll know after this

1. Document tree · box model · one flexbox layout — **from memory**
2. Three TypeScript narrowings and when each fires
3. Hit the class LLM endpoint with `curl`
4. The **Strategy pattern** for swapping LLM backends

---

# Web platform refresh — 80/20

- Document skeleton: `<!doctype html>` · `<head>` · `<body>`
- The box model — content / padding / border / margin
- **Flexbox** — one axis, gets you 80% of layouts
- **Grid** — two axes, the other 20%
- The four useful selectors — `tag`, `.class`, `#id`, `[attr]`

Skim. Don't memorize. Cheat sheets are reference.

---

# TypeScript in 10 minutes

**Why types**: contracts at module boundaries.

```ts
type Backend = 'class' | 'claude' | 'ollama';

function pick(b: Backend): LlmClient {
  switch (b) {
    case 'class':  return new ClassClient();
    case 'claude': return new ClaudeClient();
    case 'ollama': return new OllamaClient();
  }
}
```

Primitives → unions → narrowing → generics for Strategy.

---

# Job Pack — the project brief

**Three artifacts** for one job application:

1. Résumé PDF (LLM-tailored to the role)
2. Cover letter PDF
3. One-page **company-fit infographic**

Inputs: pasted text only. **No scraping** (LinkedIn / Indeed).

Strategy-pattern LLM backend → flip one config → 3 backends.

---

# The class LLM endpoint

`https://llm.uvucs.org`

- **Auth**: per-student API key
- **Rate limit**: protects shared service
- Read it as a real production system

This is one instance of:
- **Service Activator** (EIP)
- **Adapter** (GoF)
- Perfect Framework's Security + Scale

---

# Strategy pattern in your code

```ts
interface LlmBackend {
  generate(prompt: string): Promise<string>;
}

class ClassEndpoint implements LlmBackend { ... }
class ClaudeApi      implements LlmBackend { ... }
class LocalOllama    implements LlmBackend { ... }

const llm: LlmBackend = pickFromConfig();
```

**One interface, three implementations, one config flip.**<br>
This is what the rubric grades.

---

# Sprint 1 logistics

- Teams shipped today
- Repos provisioned by Wed
- **Pitch your tool choice** in Wednesday's discussion
- Demo Day: **Mon Jun 1**

---

# Discuss in class

1. **Pasted text vs. scraping** — why is scraping in the rubric prohibition list? Legal-pragmatic argument?
2. **Three backends, one interface** — sketch your `LlmBackend` interface. What methods? Return type?
3. **HTTP 429 handling** — the class endpoint says you're over limit. Three reasonable responses, in priority order.

---

# What's next

**Week 3** — JavaScript framework choice + GoF Creational

By **Sun May 24**: CC #1 (Skill) due — write a skill that helps your team

By **Mon Jun 1**: Sprint 1 demo — Job Pack must ship deployed, name patterns
