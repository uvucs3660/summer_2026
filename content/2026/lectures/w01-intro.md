---
slug: lecture-w01-intro
week: 1
youtube_id: null
companion_sheets:
  - cheatsheet-agile-v2
  - cheatsheet-perfect-framework
  - cheatsheet-vernacular-index
reflection_assignment: reflection-w01
vernacular_tags:
  - "Agile Manifesto v2.0"
  - "Perfect Framework: Scale"
  - "Perfect Framework: Database"
  - "Perfect Framework: Workflow"
  - "Claude Code: agentic loop"
  - "Claude Code: skill"
---

# Week 1 — Course Intro · Agile v2 · Perfect Framework · Vernacular

## What you'll know after this

After this lecture you will be able to (a) describe the three-track shape of CS 3660 and what each track measures, (b) name the four v2 values and three principle categories from the Agile Manifesto v2.0, (c) name all seven concerns of the Perfect Framework and explain why "engineering shouldn't have to worry about scale," and (d) explain why a Claude Pro subscription replaces a textbook in this course.

## Outline

1. **Welcome and the shape of this course** *(5 min)*
   This is *Advanced* Web Development. The deliverable bar is production-quality real systems, not classroom toys. Three tracks run in parallel: a coverage spine of weekly lectures (15%), three team sprints (50%), and five individual Claude Code artifacts (30%) — plus 5% for Week 1 onboarding. The capstone *is* the final.

2. **Why vernacular is the foundation now** *(10 min)*
   In 2026, you don't write code by yourself. You write code *with* an LLM. The constraint on your output isn't typing speed — it's the precision of the words you use to describe what you want. Vague vocabulary in your prompt produces vague code. Naming a *Strategy pattern* gets you Strategy. Naming "swappable thing" gets you a mess. **The vocabulary is the API to your AI collaborator.** This is the one slide you should be ready to defend in conversation.

3. **The Agile Manifesto v2.0 — what changed** *(12 min)*
   The 2001 manifesto still works. Hunter's v2 (2024) keeps everything and adds: four new values (Collaboration & Idea Exchange, Working Software, Fun, Resilience) and a regrouping of the 12 principles into three categories (Software 3, Team 4, Agility 5). The new values are *the lens through which you read the originals.* Software development is "a mentored collaborative team art form" — read companion cheat sheet `cheatsheet-agile-v2` for the full list.

4. **The Perfect Framework — seven concerns** *(12 min)*
   What should the framework do for you so you don't redo it on every project? Seven layers: **Scale · Database · Enterprise Messaging · Security · Application · Workflow · Ops/Documentation/Feedback**. Each has named sub-concerns (audit trails, RBAC, model-driven architecture, commitment lifecycle, etc.) — see `cheatsheet-perfect-framework`. Every architectural decision in your sprints maps to one of these concerns. Naming the concern *out loud* during a presentation is what turns a generic "we did good engineering" claim into one the rubric can credit.

5. **Claude Pro is your textbook** *(5 min)*
   No paid book this year. You will use Claude Code (and via it, Anthropic's models) every day of this course. The "Claude Pro is your textbook" page in the course shell explains how to subscribe and install. The five Claude Code artifacts you'll ship over the term are *how you prove* you've absorbed the textbook — by building skills, subagents, hooks, an MCP integration, and a plugin.

6. **The five vocabulary domains** *(5 min)*
   Agile v2.0 (4 + 12) · GoF Design Patterns (23 in 3 families) · Enterprise Integration Patterns (~65 in 5 categories) · Perfect Framework (7 concerns + sub-concerns) · Claude Code Capabilities (agentic loop + 5 extension types). Together that's a few hundred named concepts. You are not memorizing them — you are learning to *recognize* them in your sprint work and *cite* them with precision. `cheatsheet-vernacular-index` is your lookup table.

7. **What's due Sunday May 10** *(5 min)*
   Five Week 1 assignments, all small, all individually-submitted: (1) LinkedIn Learning Git training, (2) watch and reflect on Randy Pausch's Last Lecture, (3) proof of Claude Pro subscription, (4) submit your GitHub username (this is the bootstrap — it triggers your portfolio repo and LLM API key), (5) class LLM smoke test. Plus the Week 1 reflection. The first four are independent; the fifth requires #4 to complete first.

## Discuss in class

Three prompts for live Mon/Wed discussion. Pick one and come ready to engage.

- **The vocabulary bet.** This course is gambling that vocabulary fluency matters more than syntax fluency in 2026. Where do you see this playing out (or not) in your prior CS work? Where do you think it will fail to predict success, and what would you replace it with?
- **Hunter v. 2001.** The original Agile Manifesto was written by 17 engineers in 2001 in a snowy lodge in Utah. v2 has one author and a 2024 perspective on AI-as-teammate. Which of Hunter's four added values would you push back on, if any? Which would you add a fifth?
- **Perfect Framework reality check.** No real framework hits 100% of the seven concerns. Pick one popular framework you've used (Rails, Django, Next.js, Flutter, Spring Boot) and rate it on each concern: where does it lead, and where does it leave you on your own?

## Further reading

- **The Agile Manifesto v2.0** — [Michael Hunter, LinkedIn (2024)](https://www.linkedin.com/pulse/agile-manifesto-v20-michael-hunter/) — the source for §3.
- **The Original Agile Manifesto** — [agilemanifesto.org](https://agilemanifesto.org/) — the 2001 document Hunter builds on.
- **The Perfect Framework** — `docs/reference/The-Perfect-Framework.md` in this repo — the source for §4.
- **GoF Design Patterns** — [refactoring.guru/design-patterns/catalog](https://refactoring.guru/design-patterns/catalog) — the canonical 23-pattern reference. Bookmark this; it shows up every other week.
- **Enterprise Integration Patterns** — [enterpriseintegrationpatterns.com](https://www.enterpriseintegrationpatterns.com/patterns/messaging/) — the canonical EIP reference. Sprint 2 lives here.
- **Claude Code documentation** — [claude.com/claude-code](https://claude.com/claude-code) — official docs. The five CC artifact assignments use the vocabulary from these pages.

## What's next

Week 2 picks up on Monday May 11. Lecture topic: HTML/CSS/JS refresh + Job Pack kickoff + LLM endpoint primer. By Wednesday May 13 you'll have your team for Sprint 1 (Job Pack, due Mon June 1). Reach out via Canvas if any of the Week 1 onboarding fails — *especially* the GitHub username + API key handshake, since those gate everything else.
