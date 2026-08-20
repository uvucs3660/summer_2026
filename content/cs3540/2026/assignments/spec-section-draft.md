# Spec Section — First Draft

**Due:** Sun Sep 27, 2026 23:59 MT · **Points:** 100

## What to do

Write your section. PR against `engine-spec`, submit the PR URL.

Structure, per `spec/S00-overview.md`:

```
## Claim          one sentence — what is true when this is implemented correctly
## Invariants     numbered; things that must always hold
## Behavior       what happens, in what order, with units named
## Non-goals      what this deliberately does NOT do
## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria    concrete and checkable
```

## Before you submit

Run the five questions over every paragraph: **order · units · boundary · ties · empty.** Most sentences fail at least one on the first pass.

Then the second-language test: could someone implement this in Rust, without asking you anything, and get the same state hash? If your section leans on a JavaScript idiom, an implementer in another language cannot follow it — and neither can an agent that chose a different one.

> **Count your code blocks.** More than two or three and you are specifying an implementation rather than a behavior.

## Review

Review at least one classmate's section PR. A question about something genuinely ambiguous is the most valuable comment you can leave — it is a divergence prevented before a build had to find it.

## Acceptance criteria

- All five sections present.
- Non-goals are real, not empty.
- Rounding, units, ordering, and tie-breaks named wherever an implementer could choose differently.
- One substantive review left on someone else's PR.
