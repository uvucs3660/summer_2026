# Sprint 3 — Capstone Pitch

**Due:** Mon July 6, 2026 (pitched live in class; written pitch committed the same day)
**Points:** 100
**Submission:** commit a markdown pitch to your repo (suggested path: `sprints/sprint-3-pitch.md`) and submit the file's GitHub URL.

## Why this is its own assignment

The pitch is where the capstone succeeds or fails. A well-scoped pitch with an
honest risk register is the difference between five weeks of building and five
weeks of thrashing — so it is graded as a first-class deliverable, against its
own rubric, before a single line of capstone code is written.

**You may not start coding the capstone until your pitch is approved.** The
instructor approves or course-corrects at the July 6 checkpoint. If you miss
the checkpoint, submit the pitch in-repo anyway, acknowledge the lateness, and
explicitly request sign-off — a late-but-approved pitch earns partial credit;
an unapproved capstone earns none.

## What the pitch must contain

1. **Scope** — the system you'll build, precisely enough that an engineer could
   estimate it. If you are reusing prior work (an earlier sprint, another
   course), disclose it and draw the boundary: what exists, what is new this
   sprint. Grading lands on the new work.
2. **Perfect Framework concern** — one **not** covered in your Sprints 1–2,
   named explicitly, with a concrete implementation plan and a verification
   mechanism (an automated check in CI beats a promise).
3. **Advanced web-platform technology** — one **not** used in your Sprints 1–2
   (WebRTC, Web USB, Web Bluetooth, Camera API, PWA / service worker, WebGPU,
   WebAssembly, geolocation, accelerometer, …). Name the actual API surface you
   will call, and your fallback when a browser doesn't support it.
4. **Risk register** — your top 3 risks with likelihoods and mitigations.
   Mitigations are engineering decisions, not hopes. Generic risks ("we might
   run out of time") score generic points.
5. **Mandatory-requirements plan** — how you will satisfy the capstone's CI/CD
   requirement (tests on PR, deploy on merge) and observability requirement
   (structured logs at minimum).
6. **Vernacular preview** — the GoF patterns (≥3) and EIPs (≥2) you expect to
   appear in the implementation, each tied to a planned component. Claim only
   what you intend to point at in code.

## A note on ambition

One rubric criterion scores your pitch's **complexity relative to the cohort's
other pitches** — including how resistant your scope is to being trivially
generated from the pitch text alone. In a course where AI assistance is
encouraged and cited, a scope that a single generation pass could produce
end-to-end is, by definition, not five weeks of engineering. Integration
surfaces, hardware, live multi-device behavior, and novel engineering all
raise this score. Choose one workstream for your framework concern and a
*different* one for your platform technology — one feature doing double duty
for both criteria scores lower on each.

## Grading

Graded against the **Sprint 3 — Capstone Pitch** rubric (100 points): scope
clarity 15, framework-concern selection 15, platform-tech selection 15, risk
register 15, mandatory-requirements plan 10, vernacular preview 10, relative
complexity 10, timeliness & professionalism 10.
