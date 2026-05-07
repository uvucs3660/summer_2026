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

# Week 9 — PRPL · Service Workers · Offline-First

---

# What you'll know after this

1. **PRPL** — what each letter buys you
2. Write a service worker (`install`, `activate`, `fetch`) **from memory**
3. Three **cache strategies** — pick the right one per request
4. **Offline-first sync** without losing writes during reconnect

---

# PRPL — the modern web app shape

- **P**ush critical resources for the initial route
- **R**ender initial route ASAP
- **P**re-cache remaining routes
- **L**azy-load on navigation

> Time-to-first-paint is a **perceptual** metric.<br>
> 800ms feels twice as fast as 1.6s, even if both are usable in 2s.

---

# Service workers — the foundation

**Lifecycle:** register → install → activate → idle

```js
self.addEventListener('install', (e) => { ... });
self.addEventListener('activate', (e) => { ... });
self.addEventListener('fetch', (e) => {
  e.respondWith(caches.match(e.request) || fetch(e.request));
});
```

The fetch handler **intercepts every network request**.

---

# Service workers can do scary things

- Install **only over HTTPS**
- **Version your cache keys** (`v3-static`)
- **Never trust user input** in routing logic
- A bad SW can break your site for users until they clear caches

---

# Cache strategies — three patterns

**Cache-first** — return cached, refresh in background<br>
→ Right for **static assets**

**Network-first** — try network, fall back to cache<br>
→ Right for **API responses you want fresh**

**Stale-while-revalidate** — return cached now, fetch fresh in background<br>
→ Right for **"good enough now, perfect soon"**

---

# Offline-first sync

The hard part: writes while offline.

1. Write to **local storage** (IndexedDB)
2. Sync to **server** when reconnected
3. **Resolve conflicts deliberately** (last-write-wins is a *choice*)

**Background Sync API** automates the reconnect-and-flush half.

---

# Sprint 3 capstone pitch — Mon Jul 6

Pitch covers:
- Chosen scope
- Target Perfect Framework concern
- Advanced platform tech
- **Top-3 risk register**

> You may not start coding the capstone until your pitch is approved.

---

# The W6 quiz remediation

If you missed any W6 quiz questions:

→ remediation file due **Sun Jun 14**<br>
→ in your portfolio repo<br>
→ at `reflections/quiz-w06-eips-part1-quiz-remediation.md`

50% point recovery if your written explanations show real understanding.

---

# Discuss in class

1. **Cache strategy per request** — three GET endpoints from your Sprint 2 system. Which strategy for each? Defend.
2. **Offline write conflict** — two users edit the same doc while offline. Three resolution policies. Which for which use case?
3. **Capstone pitch dry-run** — 60-second pitches in your team. Vote which to bring Mon Jul 6.

---

# What's next

**Week 10** — Sprint 3 begins

Perfect Framework deep-dive: i18n · a11y · RBAC · audit trails

Pick **one** as your capstone's Perfect Framework concern.

**CC #4 (MCP)** due Sun Jul 12
