# Sprint 1 — Job Pack (Team Project)

**Duration:** 4 weeks (May 11 – June 1)
**Demo day:** Mon June 1, 2026 (in class)
**Points:** 100
**Submission:** tag the final commit on your team repo as `sprint-1-final` and submit the tag URL.

## Brief

Build a single-user web application that takes a pasted job description and a pasted candidate profile, and produces three artifacts:

1. A customized **résumé PDF** matched to the job.
2. A customized **cover letter PDF** addressed to the company.
3. A **one-page company-fit infographic** (SVG or PNG) summarizing pros/cons of working there.

The intent is that students will *actually use* this tool when applying for jobs after the term.

## Mandatory technical requirements

- **LLM backend selectable via the Strategy pattern**, supporting at least two of: hosted class Ollama (default), Claude API, raw local Ollama. Switching backend is a config-only change — zero code modification.
- **Drafts persist server-side.** Users can save, re-open, edit, and compare ≥2 drafts for the same job.
- **Deployable.** Frontend on Netlify or `uvucs.org`. Backend either embedded (single process) or split.
- **Inputs are pasted text only** — no scraping LinkedIn, Indeed, or any other third-party site (TOS).
- **Authenticated calls** to the class LLM endpoint use the student's API key from a `.env` file. The key must **never** be committed.

## Vernacular requirements

The presentation must explicitly name and explain:

- ≥2 GoF design patterns used in the codebase (Strategy is a freebie; pick another).
- ≥1 Enterprise Integration Pattern used in the LLM pipeline (Pipes-and-Filters / Pipeline is the easy one).
- ≥2 Perfect Framework concerns addressed (auth, persistence, deploy, secrets management, etc.).

The LLM grader verifies that the named patterns are *actually used* in the code, not just name-dropped in the presentation. Misuse loses rubric points.

## Stretch (rubric bonus, capped at +10%)

- Multilingual résumé output (Perfect Framework: i18n).
- Accessibility audit pass (WCAG AA).
- Automated regression test suite with non-trivial coverage.

## Demo format

12 minutes live demo + 3 minutes Q&A. Bring a job description and your own profile to demo with.

## Deliverables checklist

- [ ] Working app deployed and reachable from a public URL.
- [ ] Source code in your team's repo, with a tagged final commit `sprint-1-final`.
- [ ] README documenting setup, the LLM backend you used, and how to swap backends.
- [ ] Per-team-member individual reflection (≤500 words) committed at `sprints/sprint-1-reflection.md` in each member's personal portfolio repo, due 24 hours after demo day.

## Grading

LLM grader produces an individual grade per team member from team artifact + per-member evidence (commits, PRs, code-review comments, presentation transcript, individual reflection). See the rubric attached to this assignment for criteria.

Rationales describe your work, never your teammates' grades or rankings (FERPA / Privacy & team visibility policy).
