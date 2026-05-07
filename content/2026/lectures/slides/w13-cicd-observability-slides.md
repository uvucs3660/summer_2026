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

# Week 13 — CI/CD · Observability · Production-Readiness

---

# What you'll know after this

1. Write a **GitHub Actions** workflow that tests on PR and deploys on main
2. **Three deploy strategies** — pick the right one for your capstone
3. Emit **structured logs** with the right fields
4. Define **one SLO + error budget** for your capstone

---

# CI/CD — the principle

| | Definition |
|---|---|
| **Continuous Integration** | every change runs the full test suite |
| **Continuous Delivery** | every passing change is **ready** to deploy |
| **Continuous Deployment** | every passing change **does** deploy |

Pick the one that matches your team's risk tolerance + rollback story.

---

# GitHub Actions in 12 minutes

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm test
```

Workflows · jobs · steps · runners · secrets.

**Required for capstone.** The rubric checks for it.

---

# Deploy strategies

- **Rolling** — replace instances one at a time. Default.
- **Blue-green** — both run; flip atomically. Fast rollback.
- **Canary** — small fraction of traffic; widen if metrics OK.
- **Feature flags** — code-level deploy decoupled from rollout.

---

# Structured logging

**Logs as data, not strings.** JSON, one event per line, schema'd.

**Required fields:**
- `timestamp` (ISO 8601)
- `level` (info / warn / error)
- `message`
- `correlation_id`
- `user_id` (when meaningful)
- `service` · `env`

> Tracing one user's request across 5 services is **impossible** without correlation IDs.

---

# RED method — metrics every web service needs

| Letter | Meaning |
|---|---|
| **R**ate | requests per second |
| **E**rrors | request failures per second |
| **D**uration | latency distribution → **p50 / p95 / p99** |

**Average latency is a lie.** Look at the distribution.

Prometheus + Grafana = boring-but-correct.

---

# Distributed tracing

A **trace** is a tree of spans across services.

When a request hits 4 microservices, the trace lets you see **which one was slow**.

**OpenTelemetry** is the standard.

> Bonus rubric points for any tracing in your capstone.

---

# SLI · SLO · error budget

- **SLI** (Service Level Indicator) — a metric you measure
- **SLO** (Service Level Objective) — the target
- **Error budget** = 1 - SLO; how much downtime/errors you "spend"

> Forces teams to balance "ship features" vs. "protect reliability"

**Example:** 99.9% availability → 43.8 min/month error budget

---

# Final demo logistics

**Wed Aug 5.** 20 min live + 10 min Q&A per team.

**Demo plan:**
- 2 min framing
- 12 min showing the system handling **real input**
- 4 min architecture + Perfect Framework concern
- 2 min retrospective

**Bring real data.** Failures during demo are fine **if you handle them gracefully**.

---

# Discuss in class

1. **The CI/CD gate** — your capstone's `main` branch. What runs on PR? On merge? What blocks deploy?
2. **One log line, eight fields** — take one `console.log`. Convert to structured JSON. Show the team.
3. **One SLO** for your capstone — define an SLI + SLO. What's the error budget? How would you spend it?

---

# What's next — final week

**Mon Aug 3** — final rehearsal

**Wed Aug 5** — final demos

**Sun Aug 2** — CC #5 (Plugin) + W13 quiz both due

After that: course is done. **Your capstone is your portfolio piece.**

---

# Thank you

CS 3660 · Summer 2026 · UVU

> Good code is the language you want to read in 5 years.<br>
> Vocabulary fluency makes that language exist.

Go ship.
