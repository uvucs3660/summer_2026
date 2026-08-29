---
track: game
week: 13
title: Distance
subtitle: Lockstep, Input Delay, and Multiplayer With No Server
runtime: 22
---

NOTES:
Week thirteen, game track. This is the week the bill comes due, and for once that is good news.

Since week three I have been telling you that determinism is a hard requirement rather than a good practice, and that the reason for it arrives in week thirteen. Some of you have been taking that on faith for ten weeks. Sorting entity lists you were fairly sure did not need sorting. Quantizing before hashing. Pushing everything through one door.

This is week thirteen. Today you find out what you were paying for.

---

# What you'll know after this

- **Commands or state** — and why this course can only do one of them
- Why **input delay** exists, and why RTS games feel slightly heavy
- Desync detection for **four bytes, twice a second**
- How peers find each other with **no server and no cost**

NOTES:
Four things. The first is a fork in the road, and every multiplayer game ever made has taken one side of it or the other. Which side you take decides almost everything downstream — the bandwidth, the feel in the player's hands, whether there is a server, and whether determinism was ever worth the trouble.

---

# Commands or state

**Lockstep** sends **inputs.**
Tiny. Scales to thousands of units. Requires **perfect determinism.**

**Snapshot** sends **state.**
Larger. Tolerates imprecision. Requires an **authoritative server you pay for.**

> This course does lockstep over peer-to-peer. That is why determinism has been a hard requirement since Week 3.

NOTES:
Two architectures, and the trade between them is unusually clean.

Lockstep sends inputs. Every peer runs the identical simulation from the identical commands. The bandwidth is a few key presses per tick, and it does not matter whether there are ten units on screen or ten thousand, because units are not the thing you are sending. That is why real-time strategy has historically been lockstep. A thousand-unit battle costs the network exactly what one unit costs.

The price is that every peer must compute bit-identically. Any divergence at all compounds. Not degrades — compounds. Within a few seconds the two players are in different worlds.

Snapshot sends state. Positions, health, whatever your world is made of. It tolerates imprecision, because every snapshot corrects the one before it, and that forgiveness is why most action games use it. The price is bandwidth proportional to the size of the world, and an authoritative server, which is a machine somebody rents forever.

We do lockstep, peer to peer, because there is no budget for that machine. And that single decision is why determinism has been non-negotiable since week three instead of being advice.

---

# Input delay

![](netcode-input-delay.svg)

NOTES:
Now the consequence players actually feel, and it follows directly from what we just said.

Every peer must apply the same command on the same tick. But a command has to travel, and travel takes time. So you do not schedule a command for the tick on which it was pressed. You schedule it a few ticks ahead — far enough ahead that it will have arrived at every peer before that tick comes around.

Read the row. You press during tick forty. The command goes out marked for tick forty-three. It reaches every peer before forty-three arrives, and then everybody applies it at forty-three, together.

At twenty hertz, three ticks is a hundred and fifty milliseconds between your key press and anything happening on screen.

That is why a real-time strategy game feels slightly heavy next to a shooter. It is not a defect somebody failed to optimise away. It is the standing charge for every peer computing the same world with nobody in charge of it. Once you know the number is there, you will feel it in every RTS you have ever played, and I am sorry about that.

---

# Sorted commands

Every peer must apply the same commands in the **same order.**

```js
cmds.sort(byTick, byPeerId, bySequence);   // never arrival order
```

Arrival order differs per peer **by definition** — that is what a network is.

NOTES:
Short slide. It is the same tie-break for the fifth time.

Two commands land on the same tick from two different peers. Which one applies first?

If the answer is whichever arrived first, you have already written a desync. Arrival order differs at every peer by definition — that is not a flaw in your network, that is what a network is. Peer A hears from itself instantly and from peer B forty milliseconds later. Peer B experiences the exact reverse, and there is no vantage point anywhere in the system from which one of those is the true ordering.

So sort. By tick, then by peer id, then by sequence number. The same total order everywhere, no matter when anything actually showed up.

Week three, five, six, ten, and now thirteen. One defect, five subsystems, one fix.

---

# Desync detection is nearly free

![](netcode-desync-halt.svg)

NOTES:
And this is the payoff for having built a state hash at all.

Exchange the hash every thirty ticks. Four bytes, twice a second, on top of a protocol that was already almost nothing. If the hashes match, every peer is in the same world and you know that continuously. If they do not match, you know the exact thirty-tick window in which determinism broke, and because you know the tick, you can usually name the subsystem before you open a single file.

The instruction on the right is the one people resist. Halt. Stop the game and say so.

The instinct is to recover. Resync, or let it ride and hope the two worlds drift back together. They do not drift back together. Divergence compounds, which is the first thing we said today.

So look at what you are actually choosing between. An error message, or two players each confidently winning a different game for the next ten minutes and finding out at the end that neither result was real. The error message is not the disappointing option. It is also the only one of the two that produces a bug report rather than an argument.

---

# Peers without a server

**Hyperswarm** — a 32-byte topic, a distributed hash table, NAT hole-punching, and an encrypted duplex stream.

**Hypercore** — an append-only signed log. Which is **your command log, and your replay file.**

Cost: **zero.** No server, no relay, no monthly bill.

NOTES:
How peers find each other with nobody in the middle.

Hyperswarm first. You both join a topic — thirty-two bytes, usually the hash of your game's name plus a room code. A distributed hash table lets you discover each other. Then it punches through both your NATs, and what you are left with is an encrypted duplex stream. No server. No relay with somebody's name on the invoice.

Hypercore is the part that should make you smile. It is an append-only signed log. Which is precisely what your command log already is. The data structure the networking library wanted, you were made to build in week three for an entirely unrelated reason, and you have been carrying it around ever since. Your command log, your replay file, and your network transport are one object with three names.

Determinism keeps doing this. You implement one property, and things you never built show up already finished.

And the cost is zero. Not cheap. Zero. There is no machine.

---

# The architecture is enforced

A Pear app's renderer is a sandboxed browser context that **cannot open a socket.**

- The only thing crossing the bridge is what you pass through it
- Every RTS ever shipped invented this separation **by discipline**
- Here it is a **process boundary**

The correct design becomes the path of least resistance.

NOTES:
And the part I find genuinely elegant.

In a Pear application the renderer is a sandboxed browser context, and the networking lives in a separate Bare runtime. The renderer cannot open a socket. Not should not — cannot. There is no call it could make on its worst day.

So the only thing that crosses between the two is what you deliberately hand over the bridge, and what you hand over is commands.

Every real-time strategy game ever shipped had to invent that separation between simulation and network by hand, then defend it in code review, then watch it erode one deadline at a time until somebody reaches for the socket inside the update loop because the alternative was missing a ship date. Here the runtime holds the line, and there is nothing to erode, because a rule you are incapable of breaking is not a rule anybody has to maintain.

This is week four's guiding rule — the simulation must not know that rendering exists — promoted from a promise into a process boundary.

---

# What we give up

**No authority means no anti-cheat.**

You can **detect** divergence. You cannot **prevent** it.

A peer running modified code produces a different hash, and you will see that — but nothing stops them, and nothing decides who was right.

> This is the best possible demonstration of why authoritative servers exist.

NOTES:
And the honest cost, because I am not going to sell you peer to peer as free.

With no authoritative server, nobody is the referee. A peer running modified code produces a different hash and you will see it immediately — the desync check catches cheating exactly as well as it catches bugs, because to the protocol those are the same event. It cannot tell them apart, and it does not need to.

But detection is all of what you get. You can halt. You cannot rule, because there is no principal to say which of the two worlds was the real one. With three peers you can take a majority and feel reasonably good about it. With two peers you have two claims and no tiebreak, and that is not a hard problem. It is an unanswerable one.

That is a real trade, and it is why every competitive online game you have played runs an authoritative server that costs somebody money every month, forever. You have now built the alternative, so you know exactly what that money buys. It is not speed and it is not bandwidth. It buys somebody who gets to be right.

---

# Before Thursday

- **Audit your command ordering.** Arrival order anywhere is a desync.
- Add the **hash exchange** — it is four bytes and it will find bugs you do not know you have
- Read `spec/S17`, `cheatsheet-netcode`, `cheatsheet-p2p-pear-holepunch`
- **Game · Sprint 2** due Sun Nov 20 · **Divergence Act IIIa** due Sun Nov 16

Thursday, AI: **Plugins** — packaging the studio.

NOTES:
Two things.

Audit your ordering. If arrival order appears anywhere in how you apply commands — anywhere — that is a desync sitting quietly and waiting for its first real network. It will not show up in testing, because testing is one machine and one machine always agrees with itself.

And add the hash exchange even if you have no intention of doing multiplayer. Four bytes, twice a second. It is the best bug detector you will ever install in this engine, and it will find nondeterminism in single player, today, before the bug has anywhere left to hide.

Two deadlines. Sprint 2 on the twentieth, and the Act three-A divergence response on the sixteenth. The divergence response is the earlier of the two, and it is the one listed second.
