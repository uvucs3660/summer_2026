---
slug: lecture-w10-perfect-framework-deepdive
week: 10
youtube_id: null
companion_sheets:
  - cheatsheet-perfect-framework
  - cheatsheet-perfect-framework-concerns
reflection_assignment: reflection-w10
vernacular_tags:
  - "Perfect Framework: Scale"
  - "Perfect Framework: i18n"
  - "Perfect Framework: Accessibility"
  - "Perfect Framework: RBAC"
  - "Perfect Framework: Audit trails"
  - "Perfect Framework: Observability"
---

# Week 10 — Perfect Framework Deep-Dive: Scale · i18n · Accessibility · RBAC · Audit Trails

## What you'll know after this

You'll have enough depth on each of the major Perfect Framework "Application" concerns to (a) pick one as your Sprint 3 capstone's required concern; (b) implement it in a way that earns the rubric's "fully implemented" rating; (c) explain to a non-CS-major user what each concern actually does for them.

## Outline

1. **Scale — the framework concern that disappears when done right** *(6 min)*
   Engineering shouldn't have to *think* about scale; the framework should be set to scale by default. Stateless workers + horizontal scaling + a database that handles vertical scaling. Avoid premature scaling; design so adding servers later isn't a rewrite.

2. **i18n — internationalization is not just translation** *(10 min)*
   Strings out of code. Locale-aware date/number/currency formatting. Pluralization rules (Russian has 4 plural forms; English has 2). Right-to-left layout for Arabic/Hebrew. ICU MessageFormat. The trap: bidirectional text rendering. Test your i18n by switching locale to Hebrew or Japanese, not by reading English-with-different-words.

3. **Accessibility (WCAG AA)** *(10 min)*
   Keyboard navigation (tab order, focus management, no traps). ARIA roles and labels for screen readers. Color-contrast minimums (4.5:1 normal text). Never information conveyed by color alone. Captions on every video. The first three failure modes most apps have: tab traps, low-contrast disabled buttons, "just click this red icon" instructions.

4. **RBAC + data permissions** *(8 min)*
   Authentication ≠ Authorization. Roles map to permissions; permissions gate operations. Row-level (data) permissions are different from operation permissions. Menu/form/field-level visibility is computed from RBAC, not hardcoded. The Sprint 3 rubric will check that "non-admin user can't even see the admin menu," not just "non-admin user gets 403 when they click."

5. **Audit trails — the database concern** *(8 min)*
   Every change recorded with who/what/when/why. Two implementation patterns: append-only event log (state = fold of events) vs. point-in-time tables (rows have valid_from/valid_to). Picking one is a 5-year decision; switch costs are real.

6. **Observability — the cross-cutting concern** *(5 min)*
   Logs (structured, correlation-id'd), metrics (RED method: Rate, Errors, Duration), traces (OpenTelemetry spans). The capstone rubric requires structured logs minimum; bonus for metrics or traces.

7. **Capstone pitch checkpoint** *(8 min)*
   Today's class IS the pitch checkpoint (Mon Jul 6). Each team presents 5 min:
   1. Chosen scope.
   2. Targeted Perfect Framework concern (one of the above).
   3. Chosen advanced platform technology (next week).
   4. Top-3 risk register.
   I approve or course-correct on the spot.

## Discuss in class

- **Pick your concern.** Each capstone team commits to one Perfect Framework concern from this list TODAY. Defend the choice.
- **Accessibility testing — how, with what?** Pick a tool combo for your capstone (axe + screen reader + keyboard-only + manual contrast check). Schedule it.
- **Audit trail vs. log file.** What's the difference? Why does the Perfect Framework care about the distinction?

## Further reading

- **`cheatsheet-perfect-framework`** — the seven concerns at-a-glance.
- **`cheatsheet-perfect-framework-concerns`** — deep dives on i18n, accessibility, RBAC, audit trails.
- **WCAG 2.1 quick reference** — the checklist you should run against your capstone.
- **Martin Fowler, "Event Sourcing"** — the article that made event-sourced audit trails mainstream.

## What's next

Week 11 covers advanced web platform APIs (WebRTC, USB, Bluetooth, Camera). Pick one for your capstone's required "advanced tech." The W10 quiz drops alongside this lecture.
