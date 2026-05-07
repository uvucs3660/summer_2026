---
slug: lecture-w06-eips-part1
week: 6
youtube_id: null
companion_sheets:
  - cheatsheet-eips-part1
  - cheatsheet-vernacular-index
reflection_assignment: reflection-w06
vernacular_tags:
  - "EIP: Publish-Subscribe Channel"
  - "EIP: Point-to-Point Channel"
  - "EIP: Document Message"
  - "EIP: Command Message"
  - "EIP: Event Message"
  - "EIP: Correlation Identifier"
  - "EIP: Return Address"
  - "EIP: Guaranteed Delivery"
  - "EIP: Dead Letter Channel"
---

# Week 6 — Enterprise Integration Patterns Part 1: Channels & Message Construction

## What you'll know after this

You'll be able to (a) name the 9 channel patterns and the 9 message-construction patterns; (b) tell Document Message apart from Command Message and Event Message in 3 seconds; (c) draw the request-reply pattern with Return Address and Correlation Identifier on a whiteboard; (d) explain why Guaranteed Delivery and Dead Letter Channel are *different* solutions to *different* problems.

## Outline

1. **Why messaging? Why patterns?** *(8 min)*
   Synchronous request-response is fine when both endpoints are up, fast, and don't share resources. Real systems aren't fine. Async messaging absorbs failure, smooths load spikes, decouples components. EIPs are the *named vocabulary* for this. Naming "Publish-Subscribe Channel" gets you a different design than naming "broadcast thingy."

2. **Channel patterns — the nine** *(15 min)*
   - **Point-to-Point Channel** — one sender, ONE receiver (even if many are listening, only one gets each message).
   - **Publish-Subscribe Channel** — one sender, all subscribers receive every message.
   - **Datatype Channel** — channel constrains message type (every message is a `OrderPlaced`).
   - **Invalid Message Channel** — destination for messages that fail validation.
   - **Dead Letter Channel** — destination for messages the system gives up on.
   - **Guaranteed Delivery** — message persists until delivered (recovers from broker restarts).
   - **Channel Adapter** — connects an external system to your messaging.
   - **Messaging Bridge** — connects two messaging systems together.
   - **Message Bus** — shared messaging substrate for many connected systems.

3. **Message construction patterns — the nine** *(15 min)*
   - **Command Message** — "do X." Verb-shaped. Receiver acts.
   - **Document Message** — "here is data." Noun-shaped. Receiver consumes.
   - **Event Message** — "X happened." Past-tense. Multiple receivers may react.
   - **Request-Reply** — bidirectional pair.
   - **Return Address** — "send the reply HERE."
   - **Correlation Identifier** — "match this reply to that request."
   - **Message Sequence** — message N of M (large messages split for transport).
   - **Message Expiration** — message goes stale at time T.
   - **Format Indicator** — the message describes its own schema version.

4. **The W6 quiz drops today** *(2 min)*
   5 questions, 1 attempt, due Sun Jun 14. Auto-paired remediation if you miss any.

5. **Sprint 2 kickoff** *(5 min)*
   Topic open; rubric requires ≥3 EIPs (one must be Publish-Subscribe via MQTT or WebSocket), ≥1 explicit state chart, audit-trail persistence. Demos Mon Jun 29.

## Discuss in class

- **Pub-Sub vs. P2P.** Pick a real system you know that uses each. What goes wrong if you swap them?
- **Document vs. Command vs. Event.** Take one HTTP API endpoint your team has. Re-shape it as each of the three message types. Which fits naturally?
- **The Return Address mistake.** Why do beginners often hardcode the reply destination instead of carrying it in the message? What goes wrong at scale?

## Further reading

- **`cheatsheet-eips-part1`** — all 18 patterns with one-line summaries and code-shape diagrams.
- **enterpriseintegrationpatterns.com/patterns/messaging/** — the canonical reference. Bookmark.
- **Hohpe & Woolf, *Enterprise Integration Patterns* (2003)** — the book. Yes, it's 22 years old. Yes, it's still right.

## What's next

Week 7 covers EIPs Part 2 (routing + transformation) and state charts. The Sprint 2 system you're designing should have its rough EIP architecture sketched by end of W7.
