---
slug: lecture-w13-cicd-observability
week: 13
youtube_id: null
companion_sheets:
  - cheatsheet-cicd-github-actions
  - cheatsheet-observability-logs-metrics-traces
reflection_assignment: reflection-w13
vernacular_tags:
  - "CI/CD: trigger, deploy gate, blue-green, canary"
  - "Observability: structured log, span, metric"
  - "SRE: SLI, SLO, error budget"
  - "Perfect Framework: CI/CD"
  - "Perfect Framework: Observability"
---

# Week 13 — CI/CD · Observability · Production-Readiness

## What you'll know after this

You'll be able to (a) write a GitHub Actions workflow that runs tests on PR and deploys on merge to main; (b) name three deploy strategies (blue-green, canary, rolling) and pick the right one for your capstone; (c) emit structured logs with the right fields (correlation_id, user_id, timestamp, event); (d) define one SLO and an error budget for your capstone.

## Outline

1. **CI/CD — the principle** *(6 min)*
   Continuous Integration: every change runs the full test suite. Continuous Delivery: every passing change is *ready* to deploy. Continuous Deployment: every passing change *does* deploy. Pick the one that matches your team's risk tolerance and rollback story.

2. **GitHub Actions in 12 minutes** *(12 min)*
   Workflows, jobs, steps, runners, secrets. The `.github/workflows/ci.yaml` file. Caching dependencies (huge speed win). Matrix builds (test on 3 Node versions). Required for capstone; the rubric checks for it.

3. **Deploy strategies** *(8 min)*
   - **Rolling** — replace instances one at a time. Default for most.
   - **Blue-green** — run both old and new; flip traffic atomically. Fast rollback.
   - **Canary** — route a small fraction of traffic to new; widen if metrics look good.
   - **Feature flags** — code-level deploy decoupled from rollout.

4. **Structured logging** *(8 min)*
   Logs as data, not strings. JSON, one event per line, schema'd. Required fields: timestamp, level, message, correlation_id, user_id (when meaningful), service, env. Why correlation IDs matter: tracing one user's request across 5 services is impossible without them.

5. **Metrics — the RED method** *(6 min)*
   **R**ate (requests per second). **E**rrors (request failures per second). **D**uration (latency distribution, focus on p50/p95/p99). For each service, expose RED metrics. Prometheus + Grafana is the boring-but-correct stack.

6. **Distributed tracing** *(5 min)*
   OpenTelemetry. A *trace* is a tree of spans across services. When a request hits 4 microservices, the trace lets you see which one was slow. Bonus rubric points for any tracing in your capstone.

7. **SLI / SLO / error budget** *(5 min)*
   Service Level Indicator (a metric you measure). Service Level Objective (the target). Error budget (1 - SLO; how much downtime/errors you "spend"). Forces teams to balance "ship features" vs. "protect reliability."

8. **Final demo logistics** *(5 min)*
   Wed Aug 5. 20-minute live demo + 10-minute Q&A per team. Demo plan: 2 min framing, 12 min showing the system handling real input, 4 min architecture and Perfect Framework concern, 2 min retrospective. Bring real data; failures during the demo are fine if you handle them gracefully.

## Discuss in class

- **The CI/CD gate.** Your capstone's `main` branch — what runs on PR? what runs on merge? what blocks deploy if it fails?
- **One log line, eight fields.** Take one place in your code that calls `console.log`. Convert to a structured JSON log line with the right fields. Show the team.
- **One SLO for your capstone.** Define one SLI and an SLO. What's the error budget? How would you spend it?

## Further reading

- **`cheatsheet-cicd-github-actions`** — workflow syntax, common patterns.
- **`cheatsheet-observability-logs-metrics-traces`** — structured logging, RED, OpenTelemetry.
- **Google SRE book** — `sre.google` — the canonical reference for SLI/SLO/error budgets.
- **The Twelve-Factor App** — `12factor.net` — the production-readiness checklist that aged remarkably well.

## What's next

Week 14 is final demos — Mon Aug 3 rehearsal, Wed Aug 5 final. CC #5 (Plugin) is due Sun Aug 2. The W13 quiz is due Sun Aug 2 alongside it. After that, the course is done; your capstone is your portfolio piece.
