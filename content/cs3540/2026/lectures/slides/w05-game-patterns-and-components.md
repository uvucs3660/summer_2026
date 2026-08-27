---
track: game
week: 5
title: Patterns and the Component Store
subtitle: Composition, Queries, Queues, and Why Order Is Part of Your Spec
runtime: 24
---

NOTES:
Week five, game track.

You have claimed a section by now. Several of you claimed S05, the entity and component store, or S06, the event bus — this lecture is the eighty-twenty of both, so if that is you, take notes rather than watching.

For everyone else, this is the week the engine stops being a loop and starts being an architecture. And it opens with a vocabulary argument that sounds like pedantry and is not.

---

# What you'll know after this

- Why **composition** beats inheritance for game entities
- How to write a **component store** and a **system query** — about fifty lines
- When to reach for an **observer** and when for an **event queue**
- Why **system order** is part of your specification, not an accident of typing

NOTES:
Four things. The last one is the one that will surprise you, because system order feels like an implementation detail and it is actually observable behavior.

---

# The vocabulary is worth learning

Nystrom's patterns are the shared language of engine architecture.

- "Make the collision faster" → **a guess**
- "Add a **spatial partition**" → a spatial partition

This is now true of collaborators who are **not human**. A named pattern is a precise request. A described symptom is an invitation to improvise.

NOTES:
Start with why the vocabulary matters, because I know how this sounds.

If you ask for faster collision, you get a guess. It might be a broadphase. It might be caching. It might be micro-optimising a distance check that was never the bottleneck. The request did not contain the answer, so something had to be invented.

If you ask for a spatial partition, you get a spatial partition. The name carries the whole design — a grid or a tree, buckets by position, query the neighbours instead of everything.

And here is the part that is new. This used to be advice about talking to teammates. It is now also advice about the thing writing most of your code. A model trained on the literature knows what a spatial partition is with far more precision than it knows what you meant by "faster." Naming the pattern is the highest-leverage sentence you can type.

---

# Inheritance collapses at entity five

```
class Monster extends Entity {}
class FlyingMonster extends Monster {}
```

Now add a **flying prop that shoots.** Which parent?

The hierarchy can express exactly **one axis.** Games have several — flying, shooting, destructible, scriptable — and they combine freely.

NOTES:
Here is the failure everyone writes once.

You start with Entity. You add Monster. Flying monsters exist, so FlyingMonster extends Monster. This is fine. It is fine for about four entities.

Then design asks for a flying prop that shoots. It is not a monster — it has no AI, it does not chase you. It flies, and it shoots. Where does it go?

You can extend Prop and duplicate the flying code. You can hoist flying up to Entity and now rocks can fly. Or you can add multiple inheritance and find out why languages removed it.

None of those are bad engineering. The hierarchy is simply the wrong shape: it has room for one axis, and you have four that combine freely.

---

# What is it, versus what does it have

![](entity-component-store-inheritance-collapse.svg)

NOTES:
Left side is the question inheritance asks: what *is* this thing? That question has one answer, and the tree encodes it.

Right side is the question composition asks: what does it *have*? A flying prop that shoots has a Transform, a Sprite, Flying, Shooter, and Health. It is not any particular thing. It is a bag of capabilities.

Read the line at the bottom, because it is the practical difference. Adding an axis in the composition world means writing one new component. Adding an axis in the inheritance world means rewriting the tree — and every rewrite is a chance to break something that was working.

---

# The store is about fifty lines

```js
const transforms = new Map();   // entityId -> Transform
const velocities = new Map();
const healths    = new Map();

function* query(...types) {
  for (const id of [...allIds].sort((a, b) => a - b))
    if (types.every(t => t.has(id))) yield id;
}
```

One map per component type. An id per entity. A query is a **set intersection.**

NOTES:
And the implementation is genuinely small, which is the part people do not believe.

One map per component type, keyed by entity id. An entity is not an object at all — it is just a number that appears as a key in some maps and not others. Creating a flying prop that shoots means adding that id to five maps.

A query is a set intersection: give me every id present in all of these maps. That is it. That generator is the whole system.

Now look at the sort in the middle of that loop, because it is not decoration and we will come back to it in ninety seconds.

---

# Store and query, drawn

![](entity-component-store-query.svg)

NOTES:
Here it is with actual entities in it.

Four entities have a Transform. Two have a Velocity. Three have Health. Nothing about this is a hierarchy — entity 4 is not a kind of anything, it just happens to be in the Transform map and no others.

The query on the right asks for everything with both a Transform and a Velocity, and gets entities one and three. That is the movement system's input, and the movement system is now a function from that list to updated positions. It does not know what those entities *are*. It does not need to.

And read the bottom panel, because this is the third time.

---

# The same bug, a third time

`Map` iterates in **insertion order.**

Two implementations, both correct, that happened to insert entities in different orders will **hash differently.**

- Week 2: frame time leaked into the simulation
- Week 3: iteration order leaked into the hash
- Week 5: **the store is where that order actually comes from**

> Sort by ascending id in every query. Even when it cannot possibly matter.

NOTES:
We have now met this bug three times in five weeks, in three different subsystems, and I want to name that pattern explicitly.

In week two it was frame time getting into the simulation. In week three it was iteration order getting into the hash. Today it is the container that produces that order in the first place.

It is always the same shape: something outside the simulation's model of itself — the clock, the hardware, the insertion history of a hash map — leaks in and becomes part of the answer. And it is always invisible, because your build is self-consistent. You only find it when a second implementation disagrees.

Sort in the query. Not in the systems, not sometimes — in the query, so that every system downstream inherits the guarantee and nobody has to remember.

---

# System order is observable behavior

```js
movement(world);
collision(world);   // swap these two
damage(world);
```

Swap movement and collision and you have **a different game** — bodies resolve against last tick's positions instead of this tick's.

That is not a bug or a fix. It is a **decision**, and it belongs in your specification.

NOTES:
Systems are functions over queries and they do not know about each other. That is the point — it is what makes them testable and replaceable.

But they run in an order, and the order is behavior.

Run movement then collision and things move, then get pushed out of walls. Run collision then movement and you resolve against where everything was last tick, then move — so a fast body can end the tick inside a wall and get ejected next frame. Both are shippable. They are different games, and players can feel the difference.

Which means the order is not an implementation detail that a second build gets to choose. It is a claim your section has to make out loud, in prose, with the same seriousness as the rounding mode. If your spec section does not state the system order, two builds will pick differently and the divergence report will find you.

---

# Observer or queue?

![](game-programming-patterns-observer-vs-queue.svg)

NOTES:
Next decision, and it has a default that is right most of the time.

A synchronous observer fires the instant the event is raised — in the middle of whatever system raised it. So a listener can mutate state that another system is halfway through reading. The resulting bug depends on which system ran first, which depends on order, which means it may not reproduce.

The queue defers. Raising an event appends it; the queue is drained at a point you chose, when no system is mid-read. Deterministic, inspectable, and — usefully — a queue you can log is a queue you can replay.

The rule of thumb: inside the simulation, use the queue. For UI, an observer is fine, because UI is downstream of the simulation and cannot corrupt it. That is the same boundary as last week's guiding rule, showing up in a new place.

And notice the last line: the drain point is part of your specification too. Same argument as system order.

---

# Write the states down

![](game-programming-patterns-state-machine.svg)

NOTES:
Last pattern, and it is the cheapest bug prevention in this lecture.

Three booleans give you eight representable combinations, and only some of them mean anything. Dead and jumping is nonsense, and nothing stops you writing it. You will not write it deliberately — you will write it by setting `isJumping` in one place and forgetting that `isDead` was already true, and then something jumps for the rest of the match.

An explicit state machine does not have that failure available. There are four states and a set of legal transitions, and "dead and jumping" is not a state, so it cannot be entered.

Notice this is the same move as anti-goals, which is the AI lecture on Thursday: you make the bad outcome *unrepresentable* rather than merely *undocumented*. Writing down what is forbidden is not bureaucracy, it is how you stop relying on everyone remembering.

---

# Before Thursday

- **Find the inheritance hierarchy in your week-one game.** How deep? What would a flying prop that shoots do to it?
- **Your systems have an order** — currently whatever you typed. What *should* it be, and how would you write that so another build matches?
- Read `spec/S05-entity-and-component-store.md` and `spec/S06-event-bus.md`
- Nystrom, *Game Programming Patterns* — free online, better than any summary

Thursday, AI: **Subagents and the Five Archetypes** — and why anti-goals matter more than goals.

NOTES:
Two things to bring, and the second one is the discussion.

Find your hierarchy and tell me how deep it goes. Some of you will find none at all, because whatever generated your one-prompt game used composition on its own — that is worth knowing too, and worth asking why.

Then the order question, which is real work. Write down the order your systems currently run in, decide whether it is the order you want, and then try to write one sentence that would force another implementation to match. That sentence is harder than it sounds, and it is exactly the kind of sentence your spec section is made of.

Thursday is subagents, and it lands on the same idea this lecture ended on — that naming what is forbidden is more powerful than naming what is wanted. Forge 03 is due October fifth.
