---
track: game
week: 13
title: Distance
subtitle: Lockstep, Input Delay, and Multiplayer With No Server
runtime: 22
---

NOTES:
Week thirteen, game track, and this is the week the bill comes due — in a good way.

Since week three I have been telling you that determinism is a hard requirement rather than a good practice, and that the reason arrives in week thirteen. This is week thirteen.

---

# What you'll know after this

- **Commands or state** — and why this course can only do one of them
- Why **input delay** exists, and why RTS games feel slightly heavy
- Desync detection for **four bytes, twice a second**
- How peers find each other with **no server and no cost**

NOTES:
Four things. The first is the fork in the road that every multiplayer game takes, and which side you take determines almost everything else.

---

# Commands or state

**Lockstep** sends **inputs.**
Tiny. Scales to thousands of units. Requires **perfect determinism.**

**Snapshot** sends **state.**
Larger. Tolerates imprecision. Requires an **authoritative server you pay for.**

> This course does lockstep over peer-to-peer. That is why determinism has been a hard requirement since Week 3.

NOTES:
Two architectures, and the trade is clean.

Lockstep sends only inputs. Every peer runs the identical simulation from the identical commands. The bandwidth is trivial — a few key presses per tick, regardless of whether there are ten units on screen or ten thousand. That is why real-time strategy games have historically been lockstep: the unit count does not affect the network cost at all.

The price is that every peer must compute bit-identically. Any divergence at all compounds, and within seconds the two players are in different worlds.

Snapshot sends state — positions, health, whatever. It tolerates imprecision, because each snapshot corrects the last. It is what most action games use. The price is bandwidth proportional to world size, and an authoritative server, which is a machine somebody rents forever.

We do lockstep, over peer-to-peer, because there is no budget for a server. And that choice is why determinism has been non-negotiable since week three rather than a nice property.

---

# Input delay

![](netcode-input-delay.svg)

NOTES:
Now the consequence that players actually feel.

Every peer must apply the same command on the same tick. But a command has to travel, and travel takes time. So you do not schedule a command for the tick it was pressed — you schedule it a few ticks ahead, far enough that it will have arrived everywhere before that tick comes around.

Read the row. You press during tick forty. The command goes out marked for tick forty-three. It arrives at every peer before forty-three, and everybody applies it at forty-three.

At twenty hertz, three ticks is a hundred and fifty milliseconds between your key press and anything happening.

That is why real-time strategy games feel slightly heavy compared to a shooter, and it is not a defect anybody failed to optimise. It is the price of every peer computing the same world with no authority. Once you know it is there you can feel it in every RTS you have played.

---

# Sorted commands

Every peer must apply the same commands in the **same order.**

```js
cmds.sort(byTick, byPeerId, bySequence);   // never arrival order
```

Arrival order differs per peer **by definition** — that is what a network is.

NOTES:
Short, and it is the tie-break for the fifth time.

Two commands land on the same tick from two different peers. Which applies first?

If you say "whichever arrived first," you have guaranteed a desync, because arrival order is different at every peer by definition. That is what a network is. Peer A hears from itself instantly and from peer B in forty milliseconds; peer B experiences the exact opposite.

Sort by tick, then peer id, then sequence number. Same total order everywhere, regardless of when anything showed up.

Week three, five, six, ten, and now thirteen. Same defect, five subsystems.

---

# Desync detection is nearly free

![](netcode-desync-halt.svg)

NOTES:
And this is the payoff for having a state hash at all.

Exchange the hash every thirty ticks. Four bytes, twice a second, on top of a protocol that is already tiny. If the hashes match, every peer is in the same world and you know it. If they do not, you know the exact window in which determinism broke — and because you know the tick, you can usually name the subsystem.

The instruction on the right is the one people resist: halt. Stop the game and say so.

The instinct is to try to recover — resync, or let it ride and hope it converges. It will not converge. And the alternative to halting is two players each confidently winning a different game, discovering at the end that neither result was real. An honest error message is a far better experience than that, and it is also the only one that gets the bug reported.

---

# Peers without a server

**Hyperswarm** — a 32-byte topic, a distributed hash table, NAT hole-punching, and an encrypted duplex stream.

**Hypercore** — an append-only signed log. Which is **your command log, and your replay file.**

Cost: **zero.** No server, no relay, no monthly bill.

NOTES:
How peers find each other with nobody in the middle.

Hyperswarm: you both join a topic — thirty-two bytes, usually the hash of your game's name plus a room code. A distributed hash table lets you discover each other, then it punches through NAT, and you end up with an encrypted duplex stream. No server. No relay you pay for.

Hypercore is the part that should make you smile. It is an append-only signed log — and that is exactly what your command log already is. The data structure the networking library wanted is the data structure determinism forced you to build in week three. Your command log, your replay file, and your network transport are one thing.

And the cost is zero. Not cheap — zero. There is no machine to rent.

---

# The architecture is enforced

A Pear app's renderer is a sandboxed browser context that **cannot open a socket.**

- The only thing crossing the bridge is what you pass through it
- Every RTS ever shipped invented this separation **by discipline**
- Here it is a **process boundary**

The correct design becomes the path of least resistance.

NOTES:
And the part I find genuinely elegant.

In a Pear application the renderer is a sandboxed browser context, and the networking lives in a separate Bare runtime. The renderer literally cannot open a socket. Not "should not" — cannot.

So the only thing that can cross between them is what you deliberately pass over the bridge, which is commands.

Every real-time strategy game ever shipped had to invent the separation between simulation and network by discipline, and enforce it by code review, and lose it slowly over three years as deadlines arrived. Here the runtime enforces it and there is nothing to erode.

This is the week-four guiding rule — the simulation must not know that rendering exists — turned into a process boundary instead of a promise.

---

# What we give up

**No authority means no anti-cheat.**

You can **detect** divergence. You cannot **prevent** it.

A peer running modified code produces a different hash, and you will see that — but nothing stops them, and nothing decides who was right.

> This is the best possible demonstration of why authoritative servers exist.

NOTES:
And the honest cost, because I am not going to sell you peer-to-peer as free.

With no authoritative server, nobody is the referee. A peer running modified code will produce a different hash and you will detect that immediately — the desync check catches cheating as readily as it catches bugs, because to the protocol they are the same event.

But detection is all you get. You can halt. You cannot rule, because there is no principal to say which world was the real one. With three peers you can take a majority, and with two you have nothing.

That is a real trade, and it is why every competitive online game you have played runs an authoritative server that costs somebody money every month. Having built the alternative, you now understand exactly what that money buys.

---

# Before Thursday

- **Audit your command ordering.** Arrival order anywhere is a desync.
- Add the **hash exchange** — it is four bytes and it will find bugs you do not know you have
- Read `spec/S17`, `cheatsheet-netcode`, `cheatsheet-p2p-pear-holepunch`
- **Game · Sprint 2** due Sun Nov 20 · **Divergence Act IIIa** due Sun Nov 16

Thursday, AI: **Plugins** — packaging the studio.

NOTES:
Two things.

Audit your ordering. If arrival order appears anywhere in how you apply commands, that is a desync waiting for its first real network.

And add the hash exchange even if you are not doing multiplayer yet. It is four bytes twice a second and it is the single best bug detector in your engine — it will find nondeterminism in single player, today, before it has anywhere to hide.

Two deadlines: Sprint 2 on the twentieth, and the Act three-A divergence response on the sixteenth.
