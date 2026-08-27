---
track: game
week: 4
title: The Engine Seams
subtitle: One Guiding Rule, Three Seams, and Nineteen Sections
runtime: 22
---

NOTES:
Week four, game track, and this one is a tour rather than a technique.

By Sunday you have to claim a section of the class engine specification. Fifteen sections, one each, first claim wins, and you will own that section for the rest of the term — you write it, you ship its conformance vectors, you fix it when independent builds disagree, and you give a fifteen-minute talk on it in the back half of the course.

So before you choose, you should know what the thing you are choosing a piece of actually looks like. That is this lecture. One rule, three seams, nineteen sections.

---

# What you'll know after this

- The **guiding rule** the entire specification is written against
- What a **seam** is here — and why it is never an `if`
- The three seams, and which implementation the **grader** runs
- How the nineteen sections stack, and how to pick yours

NOTES:
Four things, and the first one is one sentence long. If you remember nothing else from this half hour, remember that sentence, because every design argument we have between now and December resolves back to it.

---

# The guiding rule

> **The simulation must not know that rendering exists.**

Everything else in `S00` is a consequence.

- A simulation that cannot run **headless** cannot be graded
- …cannot be replayed from a log
- …cannot be synchronized between peers

This is not a style preference. It is what makes three quarters of this course possible.

NOTES:
There it is.

The simulation must not know that rendering exists. Not "should be loosely coupled to." Must not know. There is no import, no reference, no callback, no flag. From inside `tick()`, rendering is not a thing that exists in the universe.

Read the three bullets, because they are the argument. If your simulation cannot run with no renderer attached at all, then the grader cannot run it — the conformance harness has no screen. It cannot be replayed, because replay is just running the simulation with recorded input and comparing hashes. And it cannot be synchronized, because a peer running your simulation has a different screen, or none.

The last line is the part I want to be blunt about. This is not architectural taste. Every single thing this course does to check your work runs through headless execution. A simulation that needs a canvas is a simulation I cannot grade.

---

# A seam is a Strategy, not an `if`

```js
// NOT this
if (config.mode === '3d') { drawWebGL(); } else { drawCanvas(); }

// this
renderer.draw(world);     // renderer chosen once, at startup
```

The simulation calls **one interface**. Which implementation is behind it was decided by configuration before the loop started.

NOTES:
Second idea. The word "seam" gets used loosely, so here is what it means in this specification.

A seam is a point where an interface is fixed and the implementation behind it is chosen by configuration, once, at startup. It is the Strategy pattern, and we will do the pattern properly in week five.

What it is not is the top example. The moment you write that `if`, three things happen. The simulation now knows there is such a thing as 3D, which violates the guiding rule. The branch is in the hot path, evaluated forever. And adding a fourth backend means finding every one of those `if`s.

The bottom version has none of those problems. The simulation calls `draw`. It does not know or care what is on the other side, and it cannot find out.

---

# Three seams

![](game-programming-patterns-seams.svg)

NOTES:
Here are all three, with their implementations.

The renderer seam has 2D, 3D on WebGL2, and headless. Look at which one is green, because that is the one that matters most to you: headless is what conformance runs against. It draws nothing. It exists so the engine can be executed and hashed with no display attached, which is how your section gets graded.

The transport seam is local hotseat, Pear over Hyperswarm, and WebRTC. The reason this seam exists is on the slide — multiplayer with no server anywhere. Nobody is paying for a game server in December.

The generator seam is procedural, local Ollama, and the class endpoint. Procedural is green because it is the fallback that always works. Your game must still run when the network is down, the endpoint is rate-limited, or you are demoing on campus wifi in the Showcase. That is not a hypothetical — read the note on your final exam slot.

And the line at the bottom is the rule again: chosen by configuration, never by an `if` inside the simulation.

---

# The nineteen sections

![](writing-a-spec-agents-can-build-section-map.svg)

NOTES:
And here is the specification itself.

At the bottom, the instructor-owned spine. S00 is the overview — the contract everything else is written against, and the one you must read before you write a line. S01 is time and the loop, which was week two. S02 is determinism and S03 is the command model, which were Tuesday. Those four are stable before you start, deliberately, because fifteen sections depending on a moving foundation would be chaos.

Above them, the fifteen that are yours, grouped by what they touch. Core runtime is the machinery every game needs — scene graph, entity store, event bus, input. Assets and pixels is how things get on screen. World and agents is collision, pathfinding, AI, and procedural generation. Content and seams is narrative, the generator seam, the transport seam, and audio.

Three are marked heavy in orange — the 3D backend, game AI, and transport. They carry more work and they pair well, so take one with somebody if you would rather.

---

# Choosing yours

Pick the one **your own game needs.**

- If your game leans on procedural terrain, `S14` is not a chore — it is the thing you were going to build anyway
- …except now it has a specification, and a grader reading it

The heavy three pair well. Taking one with someone is encouraged, not a concession.

> First claim wins. `spec/OWNERS.md`, by **Sun Sep 13**.

NOTES:
How to choose.

The honest answer is: pick the one your own game needs, because you are going to build that thing regardless. If your pitch involves generated terrain, then you are writing procedural generation code this semester no matter what. Claiming S14 means the work you were already doing now also satisfies a specification and gets read by a grader. That is the same work, counted twice, and you should take that deal.

The inverse is also true and worth saying. If you claim a section your game never touches, you will be maintaining it out of duty, in October, while your actual game needs attention. That is a bad trade and it is entirely avoidable this week.

And the mechanics: a pull request against `spec/OWNERS.md` with your name next to a section. First claim wins, so if you know, go do it tonight.

---

# The two nobody looks at

`S16` — the **generator** seam. `S17` — the **transport** seam.

This is where the course's two hardest constraints live:

- A **language model inside a frame budget**
- **Multiplayer with no server**

Both look like plumbing on the list. Neither is. If you want the section that will teach you the most, it is one of these two.

NOTES:
A recommendation, and you can ignore it.

S16 and S17 sit at the bottom of the list with boring names, and they get claimed last every time. They are the two most interesting problems in the specification.

S16 is a language model inside a frame budget. You have fifty milliseconds a tick and a model that takes two seconds to answer. Solving that is not prompt engineering; it is an architecture problem about what work happens off the simulation thread and how the answer gets back in as a command without breaking determinism. We built the seam for that on Tuesday and you may not have noticed.

S17 is multiplayer with no server. No authoritative host, no relay you pay for. Peers find each other, exchange commands, and stay in lockstep, and the whole thing only works because of the determinism property.

If you want the section you will still be thinking about in five years, it is one of those.

---

# What you are signing up for

Not just writing prose. Four commitments:

1. Writing it so **independent builds agree**
2. Shipping **conformance vectors** that actually test the claims
3. **Fixing the prose** when the divergence report says builds disagreed
4. A fifteen-minute **talk** on it, weeks 9–16

> A section whose builds never reach consensus **blocks promotion.** The engine does not ship until the spec is unambiguous enough that independent implementations agree.

NOTES:
Be clear-eyed about what claiming a section commits you to, because it is more than a document.

One: writing it so independent builds agree. That is the actual bar, and it is higher than "clear" — Thursday's lecture is entirely about the gap between those two words.

Two: conformance vectors. A claim with no vector is an opinion. S00 says that in those words.

Three: fixing it when builds diverge. The divergence report names a section and its owner. That is not blame — it is the only feedback loop in writing that tells you whether your prose said what you meant. You cannot compile an essay, but you can compile this.

Four: a talk on it, and by then you will know the material better than anyone in the room, because you specified it.

Now read the quote, because it is the part with teeth. Consensus is not a nice-to-have. A section that never converges blocks promotion of the whole engine — everyone's engine, including the one your game runs on. That is a real dependency between your prose and fourteen other people's games, and it is the closest thing to industry this course can simulate.

---

# Before Thursday

- **Read `spec/S00-overview.md`.** All of it. It is 108 lines.
- Skim the cheat sheet for two or three sections you might want
- **Claim by Sun Sep 13** — `spec/OWNERS.md`, first claim wins
- No class Thursday Sep 10 — Campus Closure

Thursday's AI lecture: **Writing a Spec an Agent Can Build** — the difference between clear and unambiguous.

NOTES:
Three things, and one calendar note.

Read S00 in full. It is a hundred and eight lines and it is the contract your section is written against. Every rule in it exists because something went wrong once.

Skim two or three candidate cheat sheets before you pick. Each of the fifteen sections has one, and it is the eighty-twenty of the topic you would be specifying.

Claim by Sunday the thirteenth.

And note the calendar: there is no class on Thursday the tenth, Campus Closure — A Day for Healing, Service, and Connection. The AI lecture still goes up, and you should still watch it, because it is the one that tells you how to write the section you are about to claim. We will discuss it when we are back together on the fifteenth.
