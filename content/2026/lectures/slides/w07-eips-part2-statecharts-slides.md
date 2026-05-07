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

# Week 7 — EIPs Part 2
## Routing · Transformation · State Charts

---

# What you'll know after this

1. **12+ routing/transformation patterns** — recognize them in real systems
2. Draw a **Pipes-and-Filters** pipeline for a concrete problem
3. Write an **XState machine** with states, events, transitions, guards, actions
4. **State machine vs. statechart** — parallel + hierarchical states

---

# Routing patterns — 1/2

**Pipes-and-Filters** — compose processing steps. The Job Pack LLM pipeline IS this.

**Content-Based Router** — route by what's in the message

**Message Filter** — drop messages that don't match a predicate

---

# Routing patterns — 2/2

**Splitter** — one message in, many out (fan-out)

**Aggregator** — many in, one out (fan-in)

**Resequencer** — restore order after async transit

**Recipient List · Routing Slip · Process Manager · Scatter-Gather** — flavors of multi-step routing

---

# Transformation patterns — 1/2

**Message Translator** — change format (JSON → Protobuf, A's schema → B's)

**Content Enricher** — add fields by lookup (`user_id` → user object)

**Content Filter** — strip fields the receiver doesn't need

**Claim Check** — payload too big? Store externally; pass a reference.

---

# Transformation patterns — 2/2

**Normalizer** — many input formats → one canonical form

**Canonical Data Model** — shared schema across systems

**Envelope Wrapper** — add headers/metadata around the payload

---

# State charts — Harel's contribution

A state chart is:

> state machine + hierarchical states + parallel regions + history

The whole purpose: make the **state of your UI or workflow** a thing you can name and reason about.

Not an emergent product of which divs are mounted.

---

# XState in 5 minutes

```ts
const machine = createMachine({
  id: 'jobPack',
  initial: 'idle',
  states: {
    idle:       { on: { GENERATE: 'generating' } },
    generating: { on: { SUCCESS: 'done', ERROR: 'failed' } },
    done:       { type: 'final' },
    failed:     { on: { RETRY: 'generating' } },
  },
});
```

States · events · transitions · guards · actions · context.

---

# Commitment lifecycle

The Perfect Framework's **Workflow** concern.

Every business workflow IS a commitment:

**Propose → Agree → Perform → Accept → Compensate**

The state chart engine is where you encode the lifecycle.

---

# Sprint 2 mid-sprint check

**Demos Mon Jun 29**

By end of W7: messaging architecture **locked**

**W8** = realtime infrastructure (MQTT/WebSocket)<br>
**W9** = polish + state chart documentation

---

# Discuss in class

1. **Pipes-and-Filters in your code** — open your Sprint 1 LLM pipeline. Identify pipes and filters. How modular is it really?
2. **State chart vs. boolean flags** — pick a UI driven by `isLoading && !error && hasData`. Re-shape as a state chart. Cleaner?
3. **Canonical Data Model** — required, or YAGNI for a 3-5 component Sprint 2?

---

# What's next

**Week 8** — MQTT · WebSockets · GraphQL Subscriptions

**CC #3 (Hook)** due Sun Jun 21
