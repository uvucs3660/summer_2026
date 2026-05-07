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

# Week 6 — Enterprise Integration Patterns
## Part 1: Channels & Message Construction

---

# What you'll know after this

1. Name the **9 channel patterns** + **9 message-construction patterns**
2. Tell **Document · Command · Event** apart in 3 seconds
3. Draw **request-reply** with Return Address + Correlation ID
4. Why **Guaranteed Delivery** ≠ **Dead Letter Channel**

---

# Why messaging? Why patterns?

Synchronous request-response is fine when:
- both endpoints are up
- both are fast
- they don't share resources

**Real systems aren't fine.**

Async messaging absorbs failure, smooths spikes, decouples components.

**EIPs name the structures.**

---

# Naming earns better designs

> "A broadcast thingy"

vs.

> "A **Publish-Subscribe Channel**"

These produce different code. The vocabulary is the design.

---

# Channel patterns — 1/3

**Point-to-Point Channel** — one sender, ONE receiver

**Publish-Subscribe Channel** — one sender, ALL subscribers

**Datatype Channel** — channel constrains message type

---

# Channel patterns — 2/3

**Invalid Message Channel** — failed validation goes here

**Dead Letter Channel** — system gave up; goes here

**Guaranteed Delivery** — message persists until delivered

---

# Channel patterns — 3/3

**Channel Adapter** — connects external system to your messaging

**Messaging Bridge** — connects two messaging systems

**Message Bus** — shared substrate for many connected systems

---

# Message construction — 1/3

**Command Message** — "do X" · verb-shaped · receiver acts

**Document Message** — "here is data" · noun-shaped · receiver consumes

**Event Message** — "X happened" · past-tense · many may react

---

# Message construction — 2/3

**Request-Reply** — bidirectional pair

**Return Address** — "send the reply HERE"

**Correlation Identifier** — "match this reply to that request"

---

# Message construction — 3/3

**Message Sequence** — message N of M (large messages split)

**Message Expiration** — message goes stale at time T

**Format Indicator** — message describes its own schema version

---

# The W6 quiz drops today

5 questions · 1 attempt · due Sun Jun 14

Auto-paired remediation if you miss any (50% point recovery for written explanations)

This is **comprehension**, not memorization. Open the cheat sheet.

---

# Sprint 2 kickoff

**Topic open.** Rubric requires:
- ≥3 EIPs (one must be **Publish-Subscribe** via MQTT or WebSocket)
- ≥1 explicit **state chart**
- **Audit-trail** persistence

**Demos Mon Jun 29.**

---

# Discuss in class

1. **Pub-Sub vs. P2P** — pick a real system using each. What goes wrong if you swap them?
2. **Document vs. Command vs. Event** — take one of your team's HTTP endpoints. Re-shape as each. Which fits naturally?
3. **The Return Address mistake** — why do beginners hardcode the reply destination? What goes wrong at scale?

---

# What's next

**Week 7** — EIPs Part 2 (routing + transformation) + state charts

By end of W7: rough EIP architecture sketched

**CC #3 (Hook)** due Sun Jun 21
