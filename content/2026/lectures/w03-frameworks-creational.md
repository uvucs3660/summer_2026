---
slug: lecture-w03-frameworks-creational
week: 3
youtube_id: null
companion_sheets:
  - cheatsheet-frameworks-survey
  - cheatsheet-gof-creational
reflection_assignment: reflection-w03
vernacular_tags:
  - "GoF: Factory Method"
  - "GoF: Abstract Factory"
  - "GoF: Builder"
  - "GoF: Prototype"
  - "GoF: Singleton"
  - "Perfect Framework: Application"
---

# Week 3 — Frameworks Survey · GoF Creational Patterns

## What you'll know after this

You'll be able to (a) name the trade-offs between React, Vue, Svelte, and Flutter-web for a project like the Job Pack; (b) name all five GoF Creational patterns and explain what problem each solves; (c) recognize which Creational pattern your Sprint 1 code is actually using, even when it wasn't planned that way.

## Outline

1. **What a "framework" actually does** *(8 min)*
   Component model, reactivity model, build pipeline, ecosystem. Frameworks differ on which of these they're opinionated about. Pick by your team's strengths and the project's shape, not by hype.

2. **React, Vue, Svelte, Flutter-web — head-to-head** *(15 min)*
   Component syntax (JSX vs. SFC vs. compiled), reactivity (hooks vs. proxy vs. compiled signals vs. setState), bundle size, learning curve, mobile story. Where each shines; where each annoys you.

3. **Creational patterns — Factory Method** *(7 min)*
   You have a class hierarchy and want to defer "which subclass to instantiate" to the point where the decision is contextual. Example: your `LlmBackend` factory picks the right concrete backend from config.

4. **Abstract Factory** *(5 min)*
   A factory of factories. When you have FAMILIES of related objects (LlmBackend + matching PromptTemplate + matching ResponseParser), an Abstract Factory keeps them in sync.

5. **Builder** *(5 min)*
   Step-by-step construction of complex objects. Document generation in Job Pack: `ResumeBuilder().withSection(...).withFormatting(...).build()` is a Builder; Canvas's QTI emitter is a Builder.

6. **Prototype** *(3 min)*
   Clone an existing object instead of constructing fresh. Useful when "make me one like that, but with X changed" is faster than re-running construction. JS spread `{...obj, x: 'new'}` is the canonical example.

7. **Singleton** *(3 min)*
   Exactly one instance, globally accessible. Often a code smell — but legitimate for genuinely-singular things (the LLM client connection pool, the logger, the config loader). Use sparingly.

8. **Pattern recognition** *(4 min)*
   Look at your Sprint 1 code RIGHT NOW. Which Creational pattern are you accidentally using? Names earn rubric points; recognition earns sustainable code.

## Discuss in class

- **Pick a framework for Job Pack.** If you were starting Sprint 1 fresh today, which framework? Defend it in 60 seconds — bundle size and team familiarity are both legitimate criteria.
- **Singleton — code smell or legitimate?** Find one Singleton in your Sprint 1 code (or one you'd add). Defend it as either a real Singleton or a misnamed Service Locator.
- **Builder vs. constructor with options object.** When does a Builder beat a constructor with `{...options}`? Bring an example.

## Further reading

- **`cheatsheet-frameworks-survey`** — the side-by-side framework comparison.
- **`cheatsheet-gof-creational`** — all five patterns with code-shape diagrams.
- **refactoring.guru/design-patterns/creational-patterns** — canonical reference.
- **Original GoF book**: *Design Patterns* by Gamma/Helm/Johnson/Vlissides (1994). Not light reading; chapter 3 is creational.

## What's next

Week 4 covers Node + REST + auth and GoF Structural patterns. Sprint 1 demos are Mon Jun 1 — your team should be in deploy-and-polish mode by end of Week 4. CC #1 (Skill) is due Sun May 24.
