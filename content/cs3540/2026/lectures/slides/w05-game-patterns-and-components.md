---
track: game
week: 5
title: Patterns and the Component Store
subtitle: Composition, Queries, Queues, and Why Order Is Part of Your Spec
runtime: 24
---

NOTES:
Week five, game track.

You have claimed a section by now. Several of you claimed S05, the entity and component store, or S06, the event bus. This lecture is the eighty-twenty of both, so if that is you, take notes rather than watch.

Here is what I expect from the rest of you this week. You will go back to your one-prompt game, look for the class hierarchy in it, and it will look fine. Three levels, sensible names, nothing obviously wrong. Then design asks for one more kind of thing, and the tree that looked fine turns into an afternoon of moving methods up and down it. That afternoon is not a punishment for being a bad programmer. It is a hierarchy doing the one thing a hierarchy does.

This is the week the engine stops being a loop and starts being an architecture. And it opens with a vocabulary argument that sounds like pedantry and is not.

---

# What you'll know after this

- Why **composition** beats inheritance for game entities
- How to write a **component store** and a **system query** — about fifty lines
- When to reach for an **observer** and when for an **event queue**
- Why **system order** is part of your specification, not an accident of typing

NOTES:
Four things. The last one is the one that will surprise you. System order feels like an implementation detail, the accident of which line you typed first, and it is actually behavior a player can feel. The other three are here so that one lands when it arrives.

---

# The vocabulary is worth learning

Nystrom's patterns are the shared language of engine architecture.

- "Make the collision faster" → **a guess**
- "Add a **spatial partition**" → a spatial partition

This is now true of collaborators who are **not human**. A named pattern is a precise request. A described symptom is an invitation to improvise.

NOTES:
Start with why the vocabulary matters, because I know how this sounds. It sounds like the part of a course where you memorise names for things you already do.

Ask for faster collision and you get a guess. It might be a broadphase. It might be somebody micro-optimising a distance check that was never the bottleneck. The request did not contain the answer, so something had to be invented.

Ask for a spatial partition and you get a spatial partition. The name carries the whole design with it. A grid or a tree, buckets by position, ask the neighbours instead of asking everyone.

Now here is the part that is new. This used to be advice about talking to the person at the next desk. It is now also advice about the thing writing most of your code. A model trained on the literature knows what a spatial partition is with far more precision than it knows what you meant by faster. Faster is a feeling. A spatial partition is a data structure.

Naming the pattern is the highest-leverage sentence you will type all week.

---

# Inheritance collapses at entity five

```
class Monster extends Entity {}
class FlyingMonster extends Monster {}
```

Now add a **flying prop that shoots.** Which parent?

The hierarchy can express exactly **one axis.** Games have several — flying, shooting, destructible, scriptable — and they combine freely.

NOTES:
Here is the failure nearly everyone writes once.

You start with Entity. You add Monster, because you have monsters. Flying monsters exist, so FlyingMonster extends Monster. Nothing is wrong yet. It stays fine for about four entities.

Then design asks for a flying prop that shoots. It is not a monster. It has no AI and it does not chase you. It flies, and it shoots. Where in the tree does it go?

You have three moves. Extend Prop and copy the flying code across, and now flying exists in two places and the copies begin drifting apart. Hoist flying up to Entity, and now every rock in your game carries a flying flag it will never use. Or reach for multiple inheritance and find out why several languages removed it.

None of those are bad engineering. The hierarchy is simply the wrong shape. It has room for exactly one axis, and you have four, and they combine freely.

---

# What is it, versus what does it have

![](entity-component-store-inheritance-collapse.svg)

NOTES:
Left side is the question inheritance asks. What is this thing? That question has exactly one answer, and the tree is where the answer lives.

Right side is the question composition asks. What does this thing have? A flying prop that shoots has a Transform, a Sprite, Flying, Shooter, and Health. It is not any particular kind of thing at all. It is a bag of capabilities, and the bag is the whole identity.

Now read the line at the bottom, because that is the practical difference. Adding an axis in the composition world means writing one new component, and nothing that already worked gets touched. Adding an axis in the inheritance world means rewriting the tree, and every rewrite of a tree is another chance to break something that was working this morning.

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
And the implementation is genuinely small, which is the part people do not believe until they have typed it.

One map per component type, keyed by entity id. That is the store. There is no Entity class anywhere in this design. An entity is a number, and that number appears as a key in some of the maps and not in others. Creating a flying prop that shoots means adding one id to five maps. Destroying it means removing that id from five maps.

A query is a set intersection. Give me every id present in all of these maps. That generator on the slide is the entire system, and everything you build above it is a function that takes a list of ids and does something to their components.

Now look at the sort in the middle of that loop. Every id, ascending, before anything is yielded. That is not decoration and it is not defensive style. Leave it where it is for ninety seconds and I will show you what it costs when it is missing.

---

# Store and query, drawn

![](entity-component-store-query.svg)

NOTES:
Here it is with actual entities in it.

Four entities have a Transform. Two of those also have a Velocity. Three have Health. Nothing here is a hierarchy. Entity four is not a kind of anything. It is in the Transform map and in no other map, and that is the entire truth about entity four.

The query on the right asks for everything holding both a Transform and a Velocity, and it gets entities one and three. That is the movement system's input. The movement system is now a function from that list to updated positions, and it does not know what those entities are. It does not need to. Nothing in it changes when you add a new kind of entity next week.

Now read the bottom panel, because this is where that sort earns its keep.

---

# The same bug, a third time

`Map` iterates in **insertion order.**

Two implementations, both correct, that happened to insert entities in different orders will **hash differently.**

- Week 2: frame time leaked into the simulation
- Week 3: iteration order leaked into the hash
- Week 5: **the store is where that order actually comes from**

> Sort by ascending id in every query. Even when it cannot possibly matter.

NOTES:
We have now met this bug three times in five weeks, in three different subsystems, and I want to name the pattern out loud.

In week two it was frame time getting into the simulation. In week three it was iteration order getting into the hash. Today it is the container that produced that iteration order in the first place. A Map iterates in insertion order, so two implementations that are both correct, and that happened to create their entities in different orders, will hash differently. Neither of them is wrong.

It is always the same shape. Something outside the simulation's model of itself leaks in and becomes part of the answer. The clock. The hardware. The insertion history of a hash table. And it is always invisible from inside, because your build is perfectly consistent with itself. You do not find this bug. A second implementation finds it for you.

So sort in the query. Not in the systems, not on the days it seems like it might matter. In the query, once, so every system downstream inherits the guarantee and nobody has to remember anything.

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
Systems are functions over queries and they do not know about each other. That is the point. It is what makes them testable and replaceable one at a time.

But they run in an order, and the order is behavior.

Run movement and then collision, and things move and then get pushed back out of the walls they moved into. Run collision and then movement, and you resolve against where everything was last tick and then move, so a fast body can finish the tick sitting inside a wall and get ejected on the next one. Both of those ship. They are not the same game, and someone who has spent ten hours in yours can feel which one you picked.

Which means the order is not an implementation detail a second build gets to decide for itself. It is a claim your section has to make out loud, in prose, with the same seriousness you gave the rounding mode. If your spec section does not state the system order, two builds will choose differently, and the divergence report will find you.

---

# Observer or queue?

![](game-programming-patterns-observer-vs-queue.svg)

NOTES:
Next decision, and this one has a default that is right most of the time.

A synchronous observer fires the instant the event is raised, in the middle of whatever system raised it. So a listener can reach in and mutate state that another system is halfway through reading. The bug that produces depends on which system ran first, which depends on the order, which means it may not reproduce when you go looking for it.

The queue defers. Raising an event appends it. The queue is drained at a point you chose, when no system is in the middle of reading anything. That is deterministic, it is inspectable, and a queue you can log is a queue you can replay.

The rule of thumb is this. Inside the simulation, use the queue. For the interface, an observer is fine, because the interface is downstream of the simulation and cannot corrupt it. That is last week's guiding rule showing up in a new place.

And notice the last line. The drain point is part of your specification too.

---

# Write the states down

![](game-programming-patterns-state-machine.svg)

NOTES:
Last pattern, and it is the cheapest bug prevention in this lecture.

Three booleans give you eight representable combinations, and only some of them mean anything. Dead and jumping is nonsense, and nothing stops you writing it down. You will not write it deliberately. You will write it by setting the jumping flag in one place, having forgotten that the dead flag went true somewhere four hundred lines away, and then something is jumping for the rest of the match. A corpse. Airborne. On a timer nobody understands.

An explicit state machine does not have that failure available. There are four states and a set of legal transitions between them, and dead and jumping is not one of the four, so it cannot be entered. Not discouraged. Not caught by a check somebody remembered to write. Unreachable.

And notice this is the same move as anti-goals, which is Thursday in the AI track. You make the bad outcome unrepresentable rather than merely undocumented. Writing down what is forbidden is not bureaucracy. It is how you stop paying rent on everyone remembering.

---

# Before Thursday

- **Find the inheritance hierarchy in your week-one game.** How deep? What would a flying prop that shoots do to it?
- **Your systems have an order** — currently whatever you typed. What *should* it be, and how would you write that so another build matches?
- Read `spec/S05-entity-and-component-store.md` and `spec/S06-event-bus.md`
- Nystrom, *Game Programming Patterns* — free online, better than any summary

Thursday, AI: **Subagents and the Five Archetypes** — and why anti-goals matter more than goals.

NOTES:
Two things to bring, and the second one is the discussion.

Find your hierarchy and tell me how deep it goes. Some of you will find none at all, because whatever generated your one-prompt game reached for composition on its own without being asked. That is worth knowing too, and worth asking why, because if a model defaulted to the better architecture that tells you something about what the literature is mostly made of.

Then the order question, which is real work. Write down the order your systems currently run in. Decide whether it is the order you actually want. Then write one sentence that would force a completely different implementation to match it. That sentence is much harder than it sounds, and it is exactly the kind of sentence your spec section is made of.

Thursday is subagents, and it lands on the same idea this lecture just ended on, that naming what is forbidden does more work than naming what is wanted. Forge 03 is due October fifth.
