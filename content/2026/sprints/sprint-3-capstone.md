# Sprint 3 — Capstone (Team Project)

**Duration:** 5 weeks (July 1 – August 5)
**Pitch checkpoint:** Mon July 6, 2026 (in class)
**Final demo:** Wed August 5, 2026 (last class meeting)
**Points:** 230 (plus the pitch, a separate 100-point assignment)
**Submission:** tag the final commit as `sprint-3-final`.

## Brief

Open-ended capstone. Teams pitch and deliver a system of their choosing. The capstone must demonstrate breadth across the course — vernacular, frameworks, messaging, and at least one previously-unused capability.

## Mandatory technical requirements

- **A Perfect Framework concern not covered in Sprints 1–2** — explicitly named in the pitch and visible in the implementation. Examples: i18n, accessibility (WCAG AA), offline operation, audit trails (if you didn't already in S2), RBAC, observability, units of measure, units of currency.
- **≥1 advanced web-platform technology not used in Sprints 1–2.** Choose: WebRTC, Web USB, Web Bluetooth, Camera API, PWA / service-worker offline, WebGPU, WebAssembly, geolocation, accelerometer, etc.
- **A working CI/CD pipeline.** GitHub Actions or equivalent. Tests run on PR, deploy on merge to main.
- **Observability hooks.** Structured logs at minimum. Bonus for metrics or distributed tracing.

## Pitch checkpoint (Mon July 6)

Each team gives a 5-minute pitch covering:
- Chosen scope and the system you'll build.
- The Perfect Framework concern targeted.
- The advanced platform technology chosen.
- Risk register: top 3 risks and your mitigations.

Instructor approves or course-corrects. **You may not start coding the capstone until your pitch is approved.**

The pitch is a **separate 100-point assignment** (*Sprint 3 — Capstone Pitch*) graded against its own rubric: scope clarity, concern selection, technology selection, risk-register quality, your CI/CD + observability plan, a vernacular preview, **relative complexity versus the cohort's other pitches** (ambitious scopes that can't be trivially generated from the pitch text score higher), and timeliness. See that assignment for the full requirements. Approval at the checkpoint still gates capstone coding regardless of the pitch grade.

## Final demo (Wed August 5)

20-minute live demo + 10-minute Q&A.

## Vernacular requirements

By Sprint 3, vernacular usage should be habitual. Presentation names and explains:

- The chosen Perfect Framework concern, with concrete code references.
- The advanced platform technology, with the API surface used.
- ≥3 GoF patterns and ≥2 EIPs that appear in the codebase.
- The CI/CD pipeline, named as the Perfect Framework's "CI/CD" concern.

## Deliverables

- [ ] Working system deployed and reachable.
- [ ] CI/CD pipeline visible (GitHub Actions URL).
- [ ] Source code with `sprint-3-final` tag.
- [ ] README documenting concern targeted, platform tech used, and pipeline.
- [ ] Per-team-member individual reflection at `sprints/sprint-3-reflection.md`, due 24h after final demo.
