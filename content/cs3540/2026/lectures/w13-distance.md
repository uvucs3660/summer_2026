---
slug: lecture-w13-distance
week: 13
youtube_id: null
companion_sheets:
  - cheatsheet-netcode
  - cheatsheet-p2p-pear-holepunch
  - cheatsheet-determinism-and-replay
reflection_assignment: devlog-w13
vernacular_tags:
  - "lockstep vs snapshot"
  - "input delay"
  - "client-side prediction · reconciliation"
  - "Hyperswarm · Hypercore · NAT hole-punching"
---

# Week 13 — Distance: Netcode and Peer-to-Peer

## What you'll know after this

After this lecture you will be able to (a) choose between lockstep and snapshot and say why, (b) explain what input delay buys, (c) detect a desync with the hash you already have, and (d) explain what P2P gives up and what it gives you.

## Outline

1. **Commands or state** *(10 min)*
   Lockstep sends inputs: tiny, scales to thousands of units, and requires **perfect determinism**. Snapshot sends state: larger, tolerates imprecision, and needs an authoritative server you pay for. This course does lockstep over peer-to-peer, which is why determinism has been a hard requirement since Week 3 rather than a good practice.

2. **Input delay** *(8 min)*
   Commands are scheduled two or three ticks ahead so they arrive before they are needed. At 20Hz that is 150ms of hidden latency — which is why RTS games feel slightly heavy, and why that is deliberate.

3. **Sorted commands** *(6 min)*
   Every peer must apply the same commands in the same order. Sort by `(tick, peerId, sequence)` — never arrival order, which differs per peer by definition.

4. **Desync detection, free** *(8 min)*
   Exchange `stateHash()` every thirty ticks. The first mismatched tick is where determinism broke, and it names the subsystem. **Halt on desync** — two players confidently winning different games is a worse experience than an honest error.

5. **Peers without a server** *(12 min)*
   Hyperswarm: a 32-byte topic, a distributed hash table, NAT hole-punching, and an encrypted duplex stream. Hypercore: an append-only signed log — which is your command log and your replay file. Cost: zero.

6. **The architecture is enforced, not encouraged** *(8 min)*
   A Pear app's renderer is a sandboxed browser context that **cannot open a socket**. The only thing crossing the bridge is what you pass through it. Every RTS ever shipped invented this separation by discipline; here it is a process boundary.

7. **What we give up** *(6 min)*
   No authority means no anti-cheat. You can detect divergence, not prevent it. That is a real trade — and the best possible demonstration of why authoritative servers exist.

## Discuss in class

- **Test on two machines, on the classroom network.** Localhost has zero latency and hides every timing bug you have.
- **Your model does not know Holepunch well.** What did you put in CLAUDE.md to work anyway? This is the skill, not an obstacle.
- **Halt or continue on desync?** Make the argument for continuing, then say why we do not.

## Further reading

- [Gaffer On Games — networking](https://gafferongames.com/categories/game-networking/)
- [docs.pears.com](https://docs.pears.com/) — read it directly; do not trust recall
- `spec/S17-transport.md` — including the `LocalTransport` you should develop against first
