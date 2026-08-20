---
slug: lecture-w04-writing-a-spec
week: 4
youtube_id: null
companion_sheets:
  - cheatsheet-writing-a-spec-agents-can-build
  - cheatsheet-ai-sdlc-spec-driven
  - cheatsheet-conformance-vectors
reflection_assignment: devlog-w04
vernacular_tags:
  - "AI SDLC: Brainstorm → Specification → Dev Plan → Execute"
  - "the second-language test"
  - "non-goals"
  - "divergence: ambiguous prose vs wrong vector"
---

# Week 4 — Writing a Spec an Agent Can Build

## What you'll know after this

After this lecture you will be able to (a) apply the five ambiguity questions to your own prose, (b) explain the second-language test and why it is the guard against writing code and calling it a spec, (c) read a divergence report and know which of two things to fix, and (d) sequence the four stages of the AI SDLC.

## Outline

1. **The standard** *(6 min)*
   Two agents, no conversation, same document — do they build the same thing? That is a much higher bar than "a reasonable person would understand this," because a reasonable person asks a follow-up question and an independent build does not.

2. **The five questions** *(14 min)*
   Order, units, boundary, ties, empty. Run them over one paragraph of your section and watch how many changes fall out. "Sort the entities" fails four of the five. The empty case is the one most often missed and most often crashes.

3. **What languages disagree about** *(8 min)*
   Rounding, sort stability, integer division, string collation, iteration order. Each is a place where two competent implementers produce different, correct-by-their-reading behavior. Naming them is not pedantry — it is most of what makes a spec buildable.

4. **The second-language test** *(8 min)*
   Could someone implement this in Rust, without asking you anything, and get the same state hash? This is the guard against the most common failure, which is writing TypeScript and putting prose around it. Count your code blocks — more than two or three, and you are probably specifying an implementation.

5. **Non-goals are load-bearing** *(6 min)*
   An agent told "render sprites" may helpfully implement z-ordering, batching, and particles. Saying what is *not* true is how you stop that, and it is the section students skip.

6. **Reading your divergence report** *(10 min)*
   Three outcomes. Builds agree and match your vector: fine. Builds **disagree with each other**: your prose was ambiguous, and promotion is blocked until you fix it. Builds agree but miss your vector: the engine is self-consistent and **your test was wrong**. Different defects, different fixes, both attributable.

7. **The pipeline** *(5 min)*
   Brainstorm, Specification, Dev Plan, Execute. And the rule that holds it together: reality disagrees? **Amend the spec, not the vibe.** A spec that drifts from what was built is worse than none, because it is confidently wrong.

## Discuss in class

- **Hand your section to the person beside you** and have them describe what they would build. Where their description surprises you — that is the sentence.
- **When builds disagree, the instinct is to explain why the other build was wrong.** It read your words and did something they permitted. What does that instinct cost you?
- **Where should a spec stop?** There is a point past which more precision is pedantry. Where is it, and how do you know you have passed it?

## Further reading

- `spec/S00-overview.md` — the contract every section is written against
- `docs/superpowers/specs/` in the course repos — real specs, including two ambiguities found the hard way
- `cheatsheet-writing-a-spec-agents-can-build`
