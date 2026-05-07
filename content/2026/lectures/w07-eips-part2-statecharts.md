---
slug: lecture-w07-eips-part2-statecharts
week: 7
youtube_id: null
companion_sheets:
  - cheatsheet-eips-part2
  - cheatsheet-state-charts
  - cheatsheet-vernacular-index
reflection_assignment: reflection-w07
vernacular_tags:
  - "EIP: Pipes-and-Filters"
  - "EIP: Content-Based Router"
  - "EIP: Splitter"
  - "EIP: Aggregator"
  - "EIP: Message Translator"
  - "EIP: Content Enricher"
  - "EIP: Canonical Data Model"
  - "Perfect Framework: Workflow"
  - "Statechart: state, event, transition, guard, action"
---

# Week 7 — EIPs Part 2: Routing, Transformation · State Charts

## What you'll know after this

You'll be able to (a) name 12+ routing and transformation patterns and recognize them in real systems; (b) draw a Pipes-and-Filters pipeline that solves a concrete problem; (c) write an XState machine with states, events, transitions, guards, and actions; (d) tell the difference between a state machine and a statechart (parallel and hierarchical states).

## Outline

1. **Routing patterns** *(15 min)*
   - **Pipes-and-Filters** — compose processing steps. The Job Pack's LLM pipeline IS this.
   - **Content-Based Router** — route by what's in the message.
   - **Message Filter** — drop messages that don't match a predicate.
   - **Splitter** — one message in, many out (fan-out).
   - **Aggregator** — many messages in, one out (fan-in).
   - **Resequencer** — restore ordering after async transit.
   - **Recipient List, Routing Slip, Process Manager, Scatter-Gather** — flavors of multi-step routing.

2. **Transformation patterns** *(10 min)*
   - **Message Translator** — change format (JSON → Protobuf, A's schema → B's schema).
   - **Content Enricher** — add fields the receiver needs by lookup (user_id → user object).
   - **Content Filter** — strip fields the receiver doesn't need.
   - **Claim Check** — payload too big? Store externally; pass a reference.
   - **Normalizer** — many input formats → one canonical form.
   - **Canonical Data Model** — shared schema across systems.
   - **Envelope Wrapper** — add headers/metadata around the payload.

3. **State charts — David Harel's contribution to web dev** *(10 min)*
   A state chart is a state machine + hierarchical states + parallel regions + history. The whole purpose: make the *state of your UI or workflow* a thing you can name and reason about, not an emergent product of which divs are mounted.

4. **XState in 5 minutes** *(8 min)*
   States, events, transitions, guards, actions, context. The actor model: state machines as actors. Why this is the right substrate for Sprint 2's mandatory state chart requirement.

5. **Commitment lifecycle (Perfect Framework)** *(5 min)*
   Propose → Agree → Perform → Accept → Compensate. Every business workflow IS a commitment. The state chart engine is where you encode the lifecycle.

6. **Sprint 2 mid-sprint check** *(2 min)*
   Demos Mon Jun 29. Your messaging architecture should be locked by end of W7; W8 is for realtime infrastructure (MQTT/WebSocket); W9 is polish + state chart documentation.

## Discuss in class

- **Pipes-and-Filters in your code.** Open your Sprint 1 LLM pipeline. Identify the pipes and the filters. How modular is it really?
- **State chart vs. boolean flags.** Pick a UI in your team's code that's currently driven by a tangle of `isLoading && !error && hasData`. Re-shape as a state chart. Is it cleaner?
- **Canonical Data Model — required or YAGNI?** When does a Canonical Data Model help, and when is it premature engineering? Your team's Sprint 2 has 3-5 components — does it need one?

## Further reading

- **`cheatsheet-eips-part2`** — all 21 routing/transformation patterns.
- **`cheatsheet-state-charts`** — XState API + statechart vs. machine vs. workflow.
- **stately.ai/docs** — XState documentation, with the visual state chart editor.
- **Harel (1987), "Statecharts: A Visual Formalism for Complex Systems"** — the original paper. Surprisingly readable.

## What's next

Week 8 covers MQTT, WebSockets, and GraphQL subscriptions — the realtime substrate Sprint 2 demands. CC #3 (Hook) is due Sun Jun 21.
