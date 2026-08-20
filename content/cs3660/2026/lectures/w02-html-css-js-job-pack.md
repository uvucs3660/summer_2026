---
slug: lecture-w02-html-css-js-job-pack
week: 2
youtube_id: null
companion_sheets:
  - cheatsheet-html
  - cheatsheet-css
  - cheatsheet-typescript
  - cheatsheet-llm-endpoint-usage
reflection_assignment: reflection-w02
vernacular_tags:
  - "GoF: Strategy"
  - "EIP: Service Activator"
  - "Perfect Framework: Scale"
  - "Perfect Framework: Security"
  - "Claude Code: skill"
---

# Week 2 — HTML/CSS/JS Refresh · Job Pack Kickoff · LLM Endpoint Primer

## What you'll know after this

You'll be able to (a) sketch the document tree, box model, and one flexbox layout from memory; (b) name three TypeScript narrowings and when each fires; (c) hit the class LLM endpoint with a `curl` command, explain how API auth and rate limiting work in this kind of service, and (d) describe the Strategy pattern for swapping LLM backends inside the Job Pack project.

## Outline

1. **Web platform refresh — the 80/20** *(15 min)*
   Document skeleton (`<!doctype html>`, `<head>`, `<body>`), the box model, flexbox vs. grid (when to use each), the four most useful selectors. Skim, don't memorize — the cheat sheets are reference material.

2. **TypeScript in 10 minutes** *(10 min)*
   Why types: contracts at module boundaries. Primitives → unions → narrowing. Generics for the Strategy pattern (a `LlmBackend<T>` typed interface). Don't memorize keywords; understand the *shape* of the type system.

3. **Job Pack — the project brief** *(8 min)*
   Three artifacts: résumé PDF + cover letter PDF + one-page company-fit infographic. Pasted-text inputs only (no scraping). Strategy-pattern LLM backend (class endpoint vs. Claude API vs. local Ollama).

4. **The class LLM endpoint** *(8 min)*
   Where it lives (`https://llm.uvucs.org`), how auth works (per-student API key), how rate limiting protects the shared service. Read it as a real production system: it's an instance of *Service Activator* (EIP), *Adapter* (GoF), and the Perfect Framework's *Security* + *Scale* concerns.

5. **The Strategy pattern in your code** *(8 min)*
   Demo: a `LlmBackend` interface with three implementations (class endpoint, Claude API, local Ollama). One config flip switches all three. This is the architectural muscle the rubric grades you on.

6. **Sprint 1 logistics** *(5 min)*
   Teams shipped. Repos provisioned. Pitch your team's tool choice during Wednesday's live discussion. Demo day Mon Jun 1.

## Discuss in class

- **Pasted text vs. scraping.** Why is "no scraping LinkedIn/Indeed" in the rubric? What's the legal-pragmatic argument, and how does it shape your input UX?
- **Three backends, one interface.** Sketch the `LlmBackend` interface for your team's Job Pack. What methods? What does the return type look like?
- **Rate limit handling.** When the class endpoint returns HTTP 429, what should your app do? Three reasonable answers, in priority order.

## Further reading

- **`cheatsheet-html`** · **`cheatsheet-css`** · **`cheatsheet-typescript`** — the three reference sheets for the platform layer.
- **`cheatsheet-llm-endpoint-usage`** — auth, streaming, error handling, rate limit etiquette.
- **MDN: HTTP rate limiting headers** — `Retry-After`, `RateLimit-Limit`, `RateLimit-Remaining`.
- **TypeScript Handbook: Narrowing** — `typeof`, `instanceof`, `in`, type predicates.

## What's next

Week 3 covers JavaScript framework choice and GoF Creational patterns. By Sprint 1 demo (Mon Jun 1) your Job Pack must ship deployed, the Strategy backend swap must work, and your presentation must name the patterns you used. The CC #1 (Skill) artifact is also due Sun May 24 — write a skill that helps your Sprint 1 team work.
