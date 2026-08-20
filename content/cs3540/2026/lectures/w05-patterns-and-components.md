---
slug: lecture-w05-patterns-and-components
week: 5
youtube_id: null
companion_sheets:
  - cheatsheet-game-programming-patterns
  - cheatsheet-entity-component-store
  - cheatsheet-cc-subagents-and-archetypes
reflection_assignment: devlog-w05
vernacular_tags:
  - "Component"
  - "Observer · Event Queue"
  - "State"
  - "Flyweight · Object Pool"
  - "the five archetypes"
---

# Week 5 — Patterns and the Component Store

## What you'll know after this

After this lecture you will be able to (a) explain why composition beats inheritance for game entities, (b) write a component store and a system query, (c) choose between an observer and an event queue, and (d) write a subagent with anti-goals.

## Outline

1. **The vocabulary, and why it is worth learning** *(6 min)*
   Nystrom's patterns are the shared language of engine architecture. Naming *Spatial Partition* to a collaborator — human or model — gets you a spatial partition. Saying "make the collision faster" gets you a guess.

2. **Inheritance collapses at entity five** *(10 min)*
   `FlyingMonster extends Monster`. Now a flying prop that shoots. Which parent? The hierarchy can only express one axis, and games have several. Composition asks *what does it have*, not *what is it*.

3. **The store** *(12 min)*
   One map per component type, an id per entity, a query that yields entities having a given set. Fifty lines. Systems are functions over those queries, they do not know about each other, and their **order is part of your specification** — swap movement and collision and you have a different game.

4. **The determinism trap in the store** *(6 min)*
   `Map` iterates in insertion order. Two implementations that store entities differently will hash differently while both being correct. Sort by ascending id in every query. This is the third time this term the same class of bug has appeared in a different subsystem; it will not be the last.

5. **Observer versus event queue** *(8 min)*
   A synchronous observer fires mid-tick, so a listener can mutate state another system is halfway through reading. The resulting bug is order-dependent and nearly unreproducible. Prefer the queue in the simulation; keep observers for UI.

6. **State machines, explicitly** *(6 min)*
   A pile of booleans can encode `isJumping && isDead`. A state machine cannot. Write the transitions down and illegal states stop being possible rather than merely undocumented.

7. **The five archetypes as subagents** *(10 min)*
   Prototyper, Builder, Sweeper, Grower, Maintainer — each with a mission and, more importantly, **anti-goals**. An agent told to simplify will helpfully add a helpful abstraction unless you tell it not to. Same principle as the state machine: name what is forbidden.

## Discuss in class

- **Find the inheritance hierarchy in your Assignment 1 game.** How deep? What would a flying prop that shoots do to it?
- **Which archetype is your project starving for right now?** Write that one as a subagent this week.
- **Systems have an order.** Yours is currently whatever you happened to type. What should it be, and how would you specify it so another implementation matches?

## Further reading

- [Game Programming Patterns](https://gameprogrammingpatterns.com/), Nystrom — free, and better than any summary
- `spec/S05-entity-and-component-store.md` and `spec/S06-event-bus.md`
- `cheatsheet-cc-subagents-and-archetypes` — the archetype definitions with their anti-goals
