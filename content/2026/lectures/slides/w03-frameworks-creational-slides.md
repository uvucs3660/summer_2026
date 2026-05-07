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

# Week 3 — Frameworks Survey
## GoF Creational Patterns

---

# What you'll know after this

1. Trade-offs: **React · Vue · Svelte · Flutter-web** for Job Pack
2. All **5 Creational patterns** + the problem each solves
3. **Recognize** which Creational pattern your code is *already* using

---

# What a framework actually does

- **Component model** — how you decompose UI
- **Reactivity model** — how state → DOM
- **Build pipeline** — what ships to the browser
- **Ecosystem** — routers, state, testing, libs

Pick by team strengths + project shape. **Not by hype.**

---

# React · Vue · Svelte · Flutter-web

|  | Component | Reactivity | Bundle | Mobile |
|---|---|---|---|---|
| **React** | JSX + hooks | hooks | medium | RN |
| **Vue** | SFC | proxy | medium | hybrid |
| **Svelte** | compiled SFC | compiled signals | small | – |
| **Flutter-web** | widgets | setState | large | first-class |

Each shines somewhere. Each annoys you somewhere.

---

# Factory Method

> Defer "which subclass" to the point of contextual decision.

```ts
function makeBackend(cfg: Config): LlmBackend {
  if (cfg.local)  return new OllamaBackend();
  if (cfg.cheap)  return new ClassBackend();
  return new ClaudeBackend();
}
```

Your `LlmBackend` factory **is** Factory Method.

---

# Abstract Factory

A factory of factories. Used when you have **families of related objects**.

`LlmBackend` + matching `PromptTemplate` + matching `ResponseParser`<br>
→ each backend ships its own template + parser → Abstract Factory keeps them in sync

---

# Builder

Step-by-step construction of complex objects.

```ts
new ResumeBuilder()
  .withSection('Experience', ...)
  .withFormatting({ font: 'Inter' })
  .withTheme('modern')
  .build();
```

Canvas's QTI emitter? Builder. Your résumé generator? Builder.

---

# Prototype

> Clone an existing object instead of constructing fresh.

```js
const baseConfig = { theme: 'dark', fontSize: 14 };
const userConfig = { ...baseConfig, fontSize: 16 };
```

JS spread is the canonical Prototype. "Like that, but with X changed."

---

# Singleton

**Exactly one** instance, globally accessible.

Often a code smell. Legitimate for:
- The LLM client connection pool
- The logger
- The config loader

Use sparingly. Most "singletons" should be DI'd objects.

---

# Pattern recognition

Look at your Sprint 1 code RIGHT NOW.

Which Creational pattern are you **accidentally** using?

- Factory? → name it.
- Builder? → name it.
- Singleton? → defend it.

**Names earn rubric points. Recognition earns sustainable code.**

---

# Discuss in class

1. **Pick a framework for Job Pack.** 60-second defense.
2. **Singleton — code smell or legitimate?** Find one in your code; defend or convict.
3. **Builder vs. constructor with options object.** When does Builder beat `{...options}`?

---

# What's next

**Week 4** — Node + REST + Auth + GoF Structural patterns

**Sprint 1 demo**: Mon Jun 1 — your team should be in deploy-and-polish mode by end of W4

**CC #1** (Skill) due Sun May 24
