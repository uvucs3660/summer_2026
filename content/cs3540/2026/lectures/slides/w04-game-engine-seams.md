---
track: game
week: 4
title: The Engine Seams
subtitle: One Guiding Rule, Three Seams, and Nineteen Sections
runtime: 22
---

NOTES:
Week four, game track, and this one is a tour rather than a technique.

By Sunday you have to claim a section of the class engine specification. Fifteen sections, one each, first claim wins, and you own that section for the rest of the term. You write it. You ship its conformance vectors. You fix it when independent builds disagree about what you meant. And you give a fifteen-minute talk on it in the back half of the course.

That is a long marriage to enter into on a Sunday night by picking whichever name on the list looks least alarming. So before you choose, you should know what the thing you are choosing a piece of actually looks like.

That is this lecture. One rule, three seams, nineteen sections.

---

# What you'll know after this

- The **guiding rule** the entire specification is written against
- What a **seam** is here — and why it is never an `if`
- The three seams, and which implementation the **grader** runs
- How the nineteen sections stack, and how to pick yours

NOTES:
Four things, and the first one is a single sentence long. If you remember nothing else from this half hour, remember that sentence. Every design argument we have between now and December resolves back to it, and I mean that literally, not as encouragement.

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

The simulation must not know that rendering exists. Not should be loosely coupled to. Not should minimise its dependencies on. Must not know. There is no import, no reference, no callback, no flag. From inside the tick function, rendering is not a thing that exists in the universe.

Read the three bullets, because they are the argument, and they are not three restatements of one point. If your simulation cannot run with no renderer attached at all, the grader cannot run it, because the conformance harness has no screen. It cannot be replayed, because replay is just the simulation fed recorded input with the hashes compared. And it cannot be synchronized, because a peer running your simulation has a different screen, or none at all.

The last line is where I want to be blunt. This is not architectural taste and it is not a house style you can argue me out of. Every single thing this course does to check your work runs through headless execution. A simulation that needs a canvas is a simulation I cannot grade.

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
Second idea. The word seam gets thrown around loosely, so here is what it means in this specification, precisely.

A seam is a point where an interface is fixed and the implementation behind it is chosen by configuration, once, at startup. It is the Strategy pattern, and we will do the pattern properly in week five.

What it is not is the top example. The moment you write that if statement, three things happen to you. The simulation now knows that a thing called 3D exists, which violates the guiding rule on the slide before this one. The branch sits in the hot path and gets evaluated forever, on every frame, to reach the same answer it reached the first time. And adding a fourth backend means hunting down every one of those if statements, and you will miss one.

The bottom version has none of those problems. The simulation calls draw. It does not know what is on the other side, it does not care, and it has no way to find out.

---

# Three seams

![](game-programming-patterns-seams.svg)

NOTES:
Here are all three, with their implementations.

The renderer seam has 2D, 3D on WebGL2, and headless. Look at which one is green, because that is the one that matters most to you. Headless draws nothing. It exists so the engine can be executed and hashed with no display attached anywhere, which is exactly how your section gets graded.

The transport seam is local hotseat, Pear over Hyperswarm, and WebRTC. The reason this seam exists is written on the slide: multiplayer with no server anywhere. Nobody is paying for a game server in December.

The generator seam is procedural, local Ollama, and the class endpoint. Procedural is green because it is the fallback that always works. Your game has to still run when the network is down, when the endpoint is rate-limited, or when you are demoing on campus wifi at the Showcase. That is not a hypothetical worry. Read the note on your final exam slot.

And the line at the bottom is the rule again: chosen by configuration, never by an if inside the simulation.

---

# The nineteen sections

![](writing-a-spec-agents-can-build-section-map.svg)

NOTES:
And here is the specification itself.

At the bottom, the instructor-owned spine. S00 is the overview, the contract everything else is written against, and the one you must read before you write a line of your own. S01 is time and the loop, which was week two. S02 is determinism and S03 is the command model, which were Tuesday. Those four are stable before you start, deliberately. Fifteen sections resting on a foundation that moves underneath them would be a semester of nobody's fault.

Above them, the fifteen that are yours, grouped by what they touch. Core runtime is the machinery every game needs whatever it is: scene graph, entity store, event bus, input. Assets and pixels is how anything gets on screen. World and agents is collision, pathfinding, AI, and procedural generation. Content and seams is narrative, the generator seam, the transport seam, and audio.

Three are marked heavy in orange. The 3D backend, game AI, and transport. They carry more work than the others and they pair well, so take one with somebody if you would rather.

---

# Choosing yours

Pick the one **your own game needs.**

- If your game leans on procedural terrain, `S14` is not a chore — it is the thing you were going to build anyway
- …except now it has a specification, and a grader reading it

The heavy three pair well. Taking one with someone is encouraged, not a concession.

> First claim wins. `spec/OWNERS.md`, by **Sun Sep 13**.

NOTES:
How to choose.

The honest answer is to pick the one your own game needs, because you are going to build that thing regardless. If your pitch involves generated terrain, you are writing procedural generation code this semester no matter which section you claim. Claiming S14 means the work you were already doing now also satisfies a specification and gets read by a grader. Same work, counted twice. Take that deal.

The inverse is true and worth saying out loud. If you claim a section your game never touches, you will be maintaining it out of duty in October, at exactly the moment your actual game needs you. That is a bad trade, and unlike most bad trades in this course it is entirely avoidable this week, for free, by thinking about it for ten minutes.

The mechanics are a pull request against the owners file with your name next to a section. First claim wins. So if you already know, go and do it tonight.

---

# The two nobody looks at

`S16` — the **generator** seam. `S17` — the **transport** seam.

This is where the course's two hardest constraints live:

- A **language model inside a frame budget**
- **Multiplayer with no server**

Both look like plumbing on the list. Neither is. If you want the section that will teach you the most, it is one of these two.

NOTES:
A recommendation, and you are free to ignore it.

S16 and S17 sit near the bottom of the list with boring names, and they get claimed last every time. They are the two most interesting problems in the specification.

S16 is a language model inside a frame budget. You have about fifty milliseconds a tick and a model that takes two seconds to answer. That is not a prompt engineering problem. It is an architecture problem about what work happens off the simulation thread and how the answer comes back in as a command without breaking determinism. We built the seam for that on Tuesday, and I do not think most of you noticed it go past.

S17 is multiplayer with no server. No authoritative host, no relay anybody pays for. Peers find each other, exchange commands, and stay in lockstep, and the whole arrangement only works because of the determinism property.

If you want the section you will still be thinking about in five years, it is one of those two.

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

One: writing it so independent builds agree. That is the actual bar, and it sits a long way above clear. Thursday's lecture is entirely about the gap between those two words.

Two: conformance vectors. A claim with no vector is an opinion. S00 says that in those words, and I did not soften it.

Three: fixing the prose when builds diverge. The divergence report names a section and it names its owner. That is not blame. It is the only feedback loop in writing that tells you whether your prose said what you meant. You cannot compile an essay. You can compile this.

Four: a talk on it. By then you will know that material better than anyone else in the room, because you are the one who specified it.

Now read the quote, because that is the part with teeth. Consensus is not a nice-to-have. A section that never converges blocks promotion of the whole engine. Everyone's engine, including the one your own game runs on. That is a real dependency between your prose and fourteen other people's games, and it is the closest thing to industry this course can honestly simulate.

---

# Before Thursday

- **Read `spec/S00-overview.md`.** All of it. It is 108 lines.
- Skim the cheat sheet for two or three sections you might want
- **Claim by Sun Sep 13** — `spec/OWNERS.md`, first claim wins
- No class Thursday Sep 10 — Campus Closure

Thursday's AI lecture: **Writing a Spec an Agent Can Build** — the difference between clear and unambiguous.

NOTES:
Three things, and one calendar note.

Read S00 in full. It is a hundred and eight lines, and it is the contract your section is written against. Every rule in it is there because something went wrong once and somebody had to write a sentence to stop it happening twice.

Skim two or three candidate cheat sheets before you pick. Each of the fifteen sections has one, and it is the eighty-twenty of the topic you would be spending the rest of the term specifying.

Claim by Sunday the thirteenth.

And the calendar note. There is no class on Thursday the tenth, Campus Closure — A Day for Healing, Service, and Connection. The AI lecture still goes up and you should still watch it, because it is the one that tells you how to write the section you are about to claim. We will discuss it when we are back together on the fifteenth.