---
marp: true
theme: default
class: invert
paginate: true
size: 16:9
style: |
  section { font-size: 28px; }
  h1 { font-size: 56px; color: #fcd34d; }
  h2 { font-size: 42px; color: #60a5fa; }
  code { background: #1f2937; padding: 2px 6px; border-radius: 4px; }
---

# Week 8 — Realtime Web
## MQTT · WebSockets · GraphQL Subscriptions

---

# What you'll know after this

1. Connect to `mqtt.uvucs.org`, publish/subscribe in JS
2. Three **MQTT QoS levels** — and which one's right
3. **MQTT vs. WebSocket vs. SSE vs. GraphQL subscriptions** — pick correctly
4. **Reconnect-with-backoff** + **offline queueing** — without writing it from scratch

---

# Four substrates · one per use case

| | MQTT | WebSocket | SSE | GraphQL Sub |
|---|---|---|---|---|
| **Direction** | duplex | duplex | server→client | server→client |
| **Protocol** | own | TCP/WS | HTTP | over WS |
| **Browser native** | via JS lib | yes | yes | via library |
| **IoT-friendly** | yes | no | no | no |

---

# MQTT — the protocol Sprint 2 expects

Class broker: `mqtt.uvucs.org`

JS client: `mqtt.js`

Concepts:
- **Topics** (slash-delimited)
- **Retained messages** (last value sticks)
- **QoS 0 / 1 / 2** (delivery guarantees)
- **Last-will** (auto-publish on disconnect)
- **Persistent sessions** (offline catch-up)

---

# QoS levels — which to use

| QoS | Guarantee | Use for |
|---|---|---|
| **0** | at-most-once · fire-and-forget | telemetry, "nice to have" |
| **1** | at-least-once · may dupe | chat messages, important events |
| **2** | exactly-once · slow | financial / contractual |

**Default to QoS 1.** Idempotent receivers handle the rare dupe.

---

# WebSocket — full duplex when you need it

- Frames · ping/pong · close codes
- Browser-native (`new WebSocket(...)`)

**WebSocket beats MQTT when:**
- Browser-only system
- Full-duplex required
- Backpressure matters

**Reconnect-with-backoff is on YOU.** Libraries help (Socket.io, ws).

---

# Server-Sent Events — the forgotten one

```js
const es = new EventSource('/api/notifications');
es.onmessage = (e) => console.log(e.data);
```

- HTTP-streaming
- Browser auto-reconnects
- One-line API

Use when: **server-to-client only**, want **zero infrastructure**.

---

# GraphQL subscriptions

- Push updates over a typed schema
- Apollo + urql both ship subscription support
- Heavier than MQTT/WS for IoT-style work
- **Right when you already have a GraphQL stack**

---

# The decision matrix

- Browser↔server full-duplex? → **WebSocket**
- Many devices, lossy networks, retained state? → **MQTT**
- Server pushes, client doesn't reply? → **SSE**
- Already have GraphQL? → **subscriptions**

---

# Realtime IS Pub-Sub Channel + Guaranteed Delivery

Every realtime system you ship is an EIP-named structure.

- **MQTT QoS 1** = Guaranteed Delivery + Idempotent Receiver
- **MQTT persistent session** = Durable Subscriber

**Naming this in your Sprint 2 demo earns rubric points.**

---

# Discuss in class

1. **Pick a substrate for Sprint 2** — WebSocket or MQTT? 60-second defense.
2. **QoS 0 vs. 1 vs. 2** — for "user posted a chat in multiplayer game"? For "telemetry every 100ms"?
3. **Reconnect-with-backoff** — three reasonable behaviors. What does your code do today?

---

# What's next

**Week 9** — PRPL · Service Workers · Offline-First

**Sprint 2 demos Mon Jun 29** — by W9 your team should be in stabilize-and-document mode

**CC #3 (Hook)** due Sun Jun 21
