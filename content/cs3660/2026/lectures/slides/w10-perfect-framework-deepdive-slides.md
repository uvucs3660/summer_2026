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

# Week 10 — Perfect Framework Deep-Dive
## Scale · i18n · a11y · RBAC · Audit Trails

---

# What you'll know after this

1. Pick **one Perfect Framework concern** as your capstone's required concern
2. Implement it to earn **"fully implemented"** on the rubric
3. **Explain to a non-CS user** what each concern actually does for them

---

# Scale — the disappearing concern

> Engineering shouldn't have to *think* about scale.<br>
> The framework should be set to scale by default.

- Stateless workers
- Horizontal scaling
- DB that handles vertical scaling

**Avoid premature scaling.** Design so adding servers later isn't a rewrite.

---

# i18n — not just translation

- **Strings out of code** (engineering substrate)
- **Locale-aware formatting** (date / number / currency)
- **Pluralization rules** (Russian: 4 forms; English: 2)
- **Right-to-left layout** (Arabic, Hebrew, Persian, Urdu)
- **ICU MessageFormat**

> Test by switching to **Hebrew** or **Japanese**.<br>
> Not by reading English-with-different-words.

---

# Accessibility (WCAG AA)

- **Keyboard navigation** — tab order, focus mgmt, no traps
- **ARIA** roles + labels for screen readers
- **Color contrast** ≥ 4.5:1 (normal text)
- **Never** information by color alone
- **Captions** on every video

The first 3 failure modes most apps have:
1. Tab traps in modals
2. Low-contrast disabled buttons
3. "Click the red icon" instructions

---

# RBAC + data permissions

**Authentication ≠ Authorization.**

- Roles → permissions
- Permissions gate **operations**
- **Row-level (data) permissions** are different from operation perms
- Menu/form/field visibility computed from RBAC

Sprint 3 rubric checks:

> "non-admin user can't even **see** the admin menu"<br>
> not just "non-admin gets 403 when they click"

---

# Audit trails — the database concern

Every change recorded with **who / what / when / why**.

**Two patterns:**

| Pattern | Storage | Strength |
|---|---|---|
| **Append-only event log** | events; state = fold | replay |
| **Point-in-time tables** | rows + valid_from/to | query "as of" |

**Picking one is a 5-year decision.** Switch costs are real.

---

# Observability — the cross-cutting concern

- **Logs** — structured, correlation-id'd
- **Metrics** — RED method (Rate · Errors · Duration)
- **Traces** — OpenTelemetry spans

**Capstone rubric:** structured logs **minimum**; bonus for metrics/traces.

---

# Capstone pitch checkpoint — TODAY

**Mon Jul 6.** Each team presents 5 min:

1. Chosen scope
2. Targeted Perfect Framework concern
3. Chosen advanced platform tech (W11)
4. **Top-3 risk register**

Approve or course-correct on the spot.

> No coding the capstone until pitch is approved.

---

# Discuss in class

1. **Pick your concern** — TODAY. Defend the choice.
2. **a11y testing** — pick a tool combo (axe + screen reader + keyboard-only + manual contrast). Schedule it.
3. **Audit trail vs. log file** — what's the difference? Why does Perfect Framework care?

---

# What's next

**Week 11** — advanced web platform APIs (WebRTC · USB · Bluetooth · Camera)

Pick **one** for capstone's required "advanced tech."

**W10 quiz** drops alongside this lecture.
