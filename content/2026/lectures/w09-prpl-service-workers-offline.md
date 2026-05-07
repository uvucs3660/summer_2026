---
slug: lecture-w09-prpl-service-workers-offline
week: 9
youtube_id: null
companion_sheets:
  - cheatsheet-shadow-dom-pwa
  - cheatsheet-offline-first-sync
reflection_assignment: reflection-w09
vernacular_tags:
  - "PRPL pattern"
  - "Service Worker: install, activate, fetch"
  - "Cache strategy: stale-while-revalidate"
  - "Cache strategy: cache-first"
  - "Cache strategy: network-first"
  - "Perfect Framework: Application > Offline"
---

# Week 9 — PRPL · Service Workers · Offline-First

## What you'll know after this

You'll be able to (a) explain the PRPL pattern (Push, Render, Pre-cache, Lazy-load) and what each letter buys you; (b) write a service worker with `install`, `activate`, and `fetch` handlers from memory; (c) name the three common cache strategies and pick the right one per request; (d) sketch how offline-first data sync works without losing writes during reconnect.

## Outline

1. **PRPL — the modern web app shape** *(8 min)*
   **P**ush critical resources for the initial route. **R**ender initial route ASAP. **P**re-cache remaining routes. **L**azy-load on navigation. Why this matters: time-to-first-paint is a perceptual metric; the page that appears in 800ms feels twice as fast as one that appears in 1.6s, even if both are technically usable in 2s.

2. **Service workers — the foundation** *(12 min)*
   Lifecycle: register → install → activate → idle. The fetch handler intercepts network requests. Scope rules. The "service workers can do scary things" warning: install only over HTTPS, version your cache keys, never trust user input in routing logic.

3. **Cache strategies** *(10 min)*
   - **Cache-first** — return cached, refresh in background. Right for static assets.
   - **Network-first** — try network, fall back to cache. Right for API responses you want fresh.
   - **Stale-while-revalidate** — return cached immediately, fetch fresh in background. Right for "good enough now, perfect soon."
   The Perfect Framework's *Database* concern explicitly calls these out — they're not optional architectural niceties.

4. **Offline-first sync** *(10 min)*
   The hard part: writes while offline. Write to local storage (IndexedDB), sync to server when reconnected, resolve conflicts deliberately (last-write-wins is a *choice*, not a default). Background Sync API automates the reconnect-and-flush half.

5. **Sprint 3 capstone pitch — Mon Jul 6** *(10 min)*
   The next Wednesday is also when you pitch your Sprint 3 capstone. Pitch covers: chosen scope, target Perfect Framework concern, advanced platform tech, top-3 risk register. Instructor approves or course-corrects. **You may not start coding the capstone until your pitch is approved.**

6. **The W6 quiz remediation** *(2 min)*
   If you missed any W6 quiz questions, your remediation file is due Sun Jun 14 in your portfolio repo at `reflections/quiz-w06-eips-part1-quiz-remediation.md`.

## Discuss in class

- **Cache strategy per request.** Pick three GET endpoints from your Sprint 2 system. Which cache strategy for each? Defend.
- **Offline write conflict.** Two users edit the same document while offline. They reconnect. Three different conflict-resolution policies. Which does your team prefer for which use case?
- **Capstone pitch dry-run.** In your team, take 60 seconds each to pitch your Sprint 3 capstone idea. The team votes which to bring to Mon Jul 6.

## Further reading

- **`cheatsheet-shadow-dom-pwa`** — service worker lifecycle + PWA install.
- **`cheatsheet-offline-first-sync`** — IndexedDB, Background Sync, conflict resolution patterns.
- **Workbox** — Google's library that does the right thing for cache strategies + Background Sync. Use it; don't roll your own.
- **PRPL pattern** (Polymer team, web.dev) — origin and rationale.

## What's next

Week 10 starts Sprint 3. The Perfect Framework deep-dive lecture covers i18n, accessibility, RBAC, audit trails — pick one as your capstone's Perfect Framework concern. CC #4 (MCP) due Sun Jul 12.
