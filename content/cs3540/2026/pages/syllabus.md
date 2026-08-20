# Syllabus — CS 3540 · Game Programming · Fall 2026

**Instructor:** Michael Hunter (Professor Hunter)
**Email:** 10207885@uvu.edu · 801-787-6522
**Term:** Wed Aug 19, 2026 → Fri Dec 11, 2026
**Class meetings:** Tue/Thu 17:30–18:45, Smith Engineering Building 218 (first meeting Thu Aug 20)
**Office hours:** After class, by Teams, or by request

![Teaching games](images/teaching_games.jpg)

## Course philosophy

A complete, playable game is now roughly one prompt away. That is not a prediction — it is a
measurement. Two full Age-of-Empires-style 3D real-time strategy games, one in Dart and one in
TypeScript, were each produced from a single prompt plus six answered questions. They converged
independently on the same architecture.

So the scarce skill is no longer typing an A\* implementation. It is **specifying a system
precisely enough that what comes back is correct, and knowing how to tell whether it is.**

Three tenets organize the course:

1. **Play.** History, fun, story, mystery. Why a thing is worth playing at all. You will read
   Koster's *Theory of Fun*, and you will teach the class about a game you love.
2. **Craft.** Two-dimensional and three-dimensional graphics, procedural generation, game AI, and
   network programming for multiplayer — the machine underneath. Engines exist to hide exactly
   these things, which is why this course builds one instead of using one.
3. **Soul.** The 11 Pillars of Claude Code, the five archetypes, and the AI software development
   lifecycle. How the work actually gets made in 2026.

## Format

- **Weekly pre-recorded lectures** with companion 80/20 cheat sheets. Watch before class.
- **Class time is studio.** A student presentation opens each session, then discussion of the
  week's lecture, then hands-on work: builds, spec review, divergence triage, playtests.
- **Two presentation types.** *My Favorite Game* (weeks 2–8) — why it works and the technical how.
  *Game Technique* (weeks 9–16) — a 15-minute mini-lecture on the engine spec section **you own**.
- **Solo or team, your choice.** Every game project opens with a declared **scope contract**:
  deliverables, asset budget, multiplayer mode. You are graded on completeness against what you
  declared, so a team of four declaring a solo-sized game fails on scope, not on quality.

## The shared engine spec

The class writes **one** engine specification together. Each of you owns sections of it.

A scheduled agent builds the engine from that spec several times independently, then compares the
results. Where independent builds **disagree**, the prose was ambiguous — and the disagreement
points at a specific section with a specific owner. The build whose results agree with the most
others is promoted, versioned, and tagged; that tagged engine is what everyone's game runs on.

> **A section whose builds never reach consensus blocks promotion.** The engine does not ship until
> the specification is unambiguous enough that independent implementations agree.

This is the course's central idea: a specification's quality is measurable, and the measurement is
whether it produces the same thing twice.

## How work is submitted

**Push to git. That is the submission.**

```
you push  →  webhook fires  →  autograder scores against the rubric
          →  feedback arrives as a GitHub issue on your repo
```

Canvas holds the grade. Your repository holds the work and the feedback. The one exception is
Week 1's GitHub handle, which is submitted in Canvas because until it exists you have no
repository to push to.

You get **one repository**, named for your UVU username, organized by purpose: `week1/`,
`journey/`, `games/`, `presentations/`, `.claude/`. The class engine specification is the one
thing that lives elsewhere — it is shared.

Watch your repos so you see the issues: GitHub → repo → **Watch → All Activity**.

## Grade weights

| Component | Weight |
|---|---|
| Game projects | 42% |
| Engine spec section + Game Technique talk | 17% |
| Forge — Claude Code artifacts | 13% |
| Attendance | 10% |
| Divergence response | 10% |
| Codex — onboarding, devlog, Favorite Game talk | 8% |

**No exams. No peer voting.** Standard letter scale (93/90/87/83/80/77/73/70/67/63/62).

### Attendance

Worth 10%. **Two unexcused absences cost nothing.** Each additional absence removes 20% of the
attendance component. A student presentation opens nearly every session — showing up is something
you owe your classmates, not just me.

### Divergence response

When the generator's builds disagree on a vector your section owns, you fix the prose. This
component measures whether agreement on your section **improved**, not whether you ran a script.

## Required tools

| Tool | Cost | Why |
|---|---|---|
| **Claude Pro** | ~$20/month · **required** | Your textbook and your development environment |
| **Ollama Cloud key** | Free | Runtime LLM for your game |
| **GitHub account** | Free | Every submission is a commit |
| `chat.uvu.edu` (UVU AI Gateway) | Free | Reading, planning, and the Council exercise |

> **Claude Pro is not API access, and the AI Gateway is not a substitute for it.** Pro covers
> claude.ai and Claude Code. The 11 Pillars — CLAUDE.md, skills, subagents, hooks, MCP, plugins,
> permission modes — are *Claude Code* features. No chat window, however many vendors it fronts,
> can provide a hook. And a game that calls an LLM at runtime needs its own key, which Pro does
> not include; that is what the Ollama Cloud key is for.

If the $20/month is a hardship, **contact me before Week 1.** UVU and the CS department have
discretionary funds for educational tooling. Do not silently go without.

### Everything else is free, on purpose

Images, music, speech, 3D meshes, and multiplayer networking in this course cost nothing. Textures
and music are generated procedurally in your own engine — which is also a catalog requirement.
Speech runs in the browser. Multiplayer is peer-to-peer, with no server to pay for.

The constraint is deliberate. A small local model that must reliably return structured output
forces you into schema-constrained decoding, caching, context budgeting, and graceful degradation.
An unlimited budget would teach you none of that.

There is a **$45 lab fee** for computers, set by the university.

## Late policy

10% per day, floor at 50%.

**Lateness is measured by the commit timestamp in git**, not by when you paste a link into Canvas.
This cuts both ways: a submission discovered 24 hours after the deadline is still gradable, with
the deduction — and backdating a Canvas paste does nothing.

## Semester calendar

27 class meetings, Aug 20 – Dec 3, plus a showcase during finals week.

| | |
|---|---|
| **Thu Sep 10** | No class — Campus Closure (A Day for Healing, Service, and Connection) |
| **Thu Oct 15** | No class — Fall Break (Oct 15–18) |
| **Tue Oct 27** | Last day to withdraw, full semester |
| **Nov 23–29** | No class — Thanksgiving Break (both sessions) |
| **Thu Dec 3** | All individual tracks close |
| **Dec 7–11** | Showcase, in the assigned final exam slot |

## AI use policy

**Using AI is required in this course, not merely permitted.** That is the subject matter.

What that does *not* change:

- **You are responsible for everything you submit.** "The AI wrote it" is not a defense for code
  that does not work, a specification that contradicts itself, or an asset you had no right to use.
- **Cite what generated what.** Every generated asset carries an entry in `assets/MANIFEST.json`
  recording the model, prompt, seed, date, license, and whether it was produced at build time or
  at runtime. This is an engineering artifact and an attribution record at once.
- **You must be able to explain your own work.** Your Game Technique talk is 15 minutes on the
  spec section you own, in front of the class. You cannot specify what you cannot explain.
- **Your repository is private.** Only you, the instructor, the autograder, and — while you are on
  a team together — your teammates can see it. Do not seek access to anyone else's, and do not
  share yours outside your team. The shared engine specification is the one deliberate exception.
- **Teammates see the work and the rank order of contribution, never the grades.** See the
  privacy page.

If you are unsure whether something is acceptable, ask me before you submit it.

## Accessibility & Accommodations

Students needing accommodations due to a disability, including temporary and pregnancy
accommodations, should contact Accessibility Services at
[accessibilityservices@uvu.edu](mailto:accessibilityservices@uvu.edu) or 801-863-8747, located in
LC 312. To request ASL interpreters, please contact Katie Palmer at
[kateip@uvu.edu](mailto:kateip@uvu.edu).

## Title IX

Title IX makes it clear that violence and harassment based on sex and gender (which includes
sexual orientation and gender identity/expression) is a civil rights offense subject to the same
kinds of accountability and the same kinds of support applied to offenses against other protected
categories such as race, national origin, color, religion, age, status as a person with a
disability, veteran's status or genetic information. If you or someone you know has experienced or
experiences harassment or sexual assault including dating and domestic violence, stalking or
sexual exploitation, you are encouraged to report it to the Title IX Coordinator in the Office for
Equal Opportunity and Affirmative Action, BA-203, (801) 863-7999.

Please be aware that all faculty members and university employees are considered "Responsible
Employees" and are required to report incidents of sexual misconduct and relationship violence and
thus cannot guarantee confidentiality. Please know that you can seek confidential resources at UVU
Student Health Services, SC-221, (801) 863-8876. Please visit
<https://www.uvu.edu/equalopportunity/> for more information.

## Ethics and Conduct

Review the department's Ethics and Conduct Policy at <https://www.uvu.edu/cs/ethics.html> and the
university's Student Conduct & Conflict Resolution at
<https://www.uvu.edu/studentconduct/students.html>. You are required to abide by these policies.
Violation will result in college disciplinary actions and possible civil liabilities.
