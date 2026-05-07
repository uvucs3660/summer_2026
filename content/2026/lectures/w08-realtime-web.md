---
slug: lecture-w08-realtime-web
week: 8
youtube_id: null
companion_sheets:
  - cheatsheet-realtime-web
  - cheatsheet-eips-part1
reflection_assignment: reflection-w08
vernacular_tags:
  - "EIP: Publish-Subscribe Channel"
  - "EIP: Guaranteed Delivery"
  - "EIP: Durable Subscriber"
  - "EIP: Message Bus"
  - "Realtime: MQTT QoS"
  - "Realtime: WebSocket"
  - "Realtime: GraphQL Subscription"
  - "Perfect Framework: Enterprise Messaging"
---

# Week 8 — Realtime Web: MQTT · WebSockets · GraphQL Subscriptions

## What you'll know after this

You'll be able to (a) connect to `mqtt.uvucs.org` and publish/subscribe in JS; (b) explain the three MQTT QoS levels and pick the right one; (c) decide between MQTT, WebSocket, Server-Sent Events, and GraphQL subscriptions for a given workload; (d) handle reconnect-with-backoff and offline queueing without writing it from scratch.

## Outline

1. **The realtime web — three substrates** *(8 min)*
   MQTT (lightweight pub/sub, IoT-flavored), WebSocket (full-duplex, browser-native), Server-Sent Events (server-to-client only, dead simple), GraphQL subscriptions (typed, schema-first). One per use case.

2. **MQTT — the protocol Sprint 2 expects** *(15 min)*
   Topics, retained messages, QoS 0/1/2, last-will, persistent sessions. The class broker `mqtt.uvucs.org`. JavaScript client (`mqtt.js`). Live demo: publish-subscribe across two browser tabs.

3. **WebSocket — full duplex, when you need it** *(10 min)*
   Frames, ping/pong, close codes. When WebSocket beats MQTT (browser-only systems, full-duplex required, backpressure matters). Reconnect-with-backoff is on YOU; libraries help (Socket.io, ws).

4. **Server-Sent Events** *(5 min)*
   The forgotten one. HTTP-streaming; the browser auto-reconnects; it's a one-line `EventSource` API. Use when you only need server-to-client and want zero infrastructure.

5. **GraphQL subscriptions** *(5 min)*
   Push updates over a typed schema. Apollo and urql both ship subscription support. Heavier than MQTT/WS for IoT-style workloads but right when you already have a GraphQL stack.

6. **The decision matrix** *(5 min)*
   Need browser↔server full-duplex? → WebSocket. Many devices, lossy networks, retained state? → MQTT. Server pushes notifications, client doesn't reply? → SSE. Already have GraphQL? → subscriptions.

7. **Realtime as Pub-Sub Channel + Guaranteed Delivery** *(2 min)*
   Every realtime system you ship is an EIP-named structure. MQTT QoS 1 = Guaranteed Delivery + Idempotent Receiver. MQTT persistent session = Durable Subscriber. Naming this in your Sprint 2 demo earns rubric points.

## Discuss in class

- **Pick a substrate for Sprint 2.** Your team's project — WebSocket or MQTT? Defend in 60 seconds.
- **QoS 0 vs. QoS 1 vs. QoS 2 — pick.** For "user posted a chat message in a multiplayer game," what's right? For "telemetry from a sensor every 100ms," what's right?
- **Reconnect-with-backoff.** Three reasonable behaviors when the connection drops. What does your team's code do today?

## Further reading

- **`cheatsheet-realtime-web`** — MQTT, WebSocket, SSE, GraphQL subscription comparison.
- **MQTT v5 spec** — long but well-organized; QoS chapter is essential reading.
- **Socket.io vs. raw WebSocket** — when the abstraction earns its weight.
- **Apollo subscriptions** — if your team picked GraphQL.

## What's next

Week 9 covers PRPL, service workers, and offline-first. Sprint 2 demos are Mon Jun 29 — by W9 your team should be in stabilize-and-document mode. CC #3 (Hook) due Sun Jun 21.
