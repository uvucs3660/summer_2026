# New this term: automated sprint grading on your GitHub repo

**TL;DR:** Each sprint's grade now starts with an automated read of your
repo by Claude against the published rubric. The result lands as a
comment on a single GitHub issue titled **"CS3660 Summer 2026"** in
*your* repo. The first comment shows up at the sprint deadline; the
professor may also trigger a re-run by hand at any time. The auto-grade
is the **starting point** for your sprint grade, not the final word —
the professor reviews and signs off.

---

## What you'll see

Within a few minutes of each sprint deadline, a GitHub issue will appear
in your sprint repo with the title **"CS3660 Summer 2026"**. Open it.
The body — or the latest comment, if the issue already existed — is your
auto-grade report.

It looks roughly like this:

```markdown
# Auto-grade — Sprint 1 — Job Pack

**Score: 87/100** · commit `abc1234` · run `grd_…` · 2026-06-15

## Criteria

- [x] **Required outputs** — `25/25` — "All three artifacts present and correctly tailored to the inputs."
  - All three PDFs render for the sample inputs in `tests/fixtures/`.
  - Evidence: `src/generators/resume.ts:18-94`, `tests/integration/pdf.test.ts:1-60`
- [x] **Strategy pattern (LLM swap)** — `15/15` — "≥2 backends working, swap is config-only, code is clean."
  - …
… (one entry per rubric criterion)

## Summary

Strong submission overall. …

## Suggested improvements

- Add a compare-view to the draft list to reach the top tier of the
  persistence criterion (+4 pts).
- …
```

Every criterion lists the rating it picked (verbatim from the rubric),
the points awarded, a 1–2 sentence justification, and concrete evidence
(file paths, line ranges, commit SHAs) you can click to.

You'll get a GitHub notification for the issue automatically, as will
the professor (every repo grants him admin).

---

## What gets graded

Whatever is on `main` (or `master`) in your sprint repo at the moment
the auto-grader runs. The grader:

1. Clones your repo at the latest commit on the default branch.
2. Reads your README, source files, tests, CI config, and git history
   the same way a human reviewer would.
3. Picks one rating per rubric criterion and explains why.
4. Posts the result back to your repo as a comment on the
   "CS3660 Summer 2026" issue.

There is **no separate "submit" step**. Your repo is your submission.
Make sure your latest work is merged to `main` before the deadline.

---

## When it runs

- **Automatically:** at every sprint deadline (Sprint 1: 2026-06-15,
  Sprint 2: 2026-06-29, Sprint 3: 2026-07-13 — all 23:59 Mountain).
- **On-demand:** the professor may trigger a re-run after a deadline
  (for example, after you push a fix during the appeal window). You'll
  see a new comment appear on the same issue.

You cannot trigger a run yourself — runs cost real money in API calls.
If you have a legitimate reason for an extra run, email the professor.

---

## The rubric

The rubric for each sprint is published in advance — same as the rubric
the professor uses for the eval portion of your grade. The auto-grader
is reading the **same rubric**; nothing hidden. You can find them
under each sprint's assignment in Canvas, or in the course content
repo at `course_builder/content/2026/rubrics/`.

---

## When you disagree with the auto-grade

Auto-grades will be wrong sometimes. They are AI judgments and they
miss context, misread code, or apply the wrong rating to mixed evidence.
**That's expected, and the professor reviews every grade before it
becomes final.**

When you think the auto-grader got it wrong:

1. **Comment on the issue.** Point at the criterion, explain what you
   think the right rating is, and cite evidence. Be specific and brief.
   Example: *"On 'persistence' the grader rated 'multi-draft persistence
   but no compare', but `src/components/DraftCompare.tsx:1-180` ships a
   working side-by-side compare view that's reachable from the draft
   list. Suggesting the top-tier rating."*
2. **Don't edit the issue body.** Always comment.
3. The professor reviews comments before signing off the sprint grade
   in Canvas.

If your appeal is supported by evidence in the repo, the final grade
will reflect that — the auto-grade is advisory, not authoritative.

---

## AI use citation reminder

The syllabus rule still stands: **if you used an LLM to write code,
cite it at the top of the affected file**. The auto-grader does not
check or penalize AI usage — but unattributed AI work is still an
academic integrity violation that the human review process will flag.

Citation format is whatever's clear: a one-line comment naming the
model and what it produced is enough.

---

## Common questions

**Will the auto-grader see my AI-citation comments?**
Yes, it reads every file. It does not currently use the citations to
adjust scoring — but they're visible in the evidence trail.

**What if my repo wasn't reachable when the grader ran?**
You'll see a `failed:clone` record (no issue gets posted on a clone
failure). The professor will retry. The most common causes are
mis-typed repo names and private-visibility settings on the wrong repo.

**What if Claude misread my code?**
Comment on the issue with the correct interpretation and a pointer to
the file. The professor reviews comments.

**What happens to my grade if there's a tie between two ratings?**
The grader is instructed to pick the *lower* rating and explain why,
then surface "what would unlock the higher rating" as an improvement
suggestion. So mixed-evidence cases skew slightly conservative — you
can push back via comment if you disagree.

**Will the grader leak my code anywhere?**
No. Your repo is cloned into a temporary directory on the grader's
host, read by Claude inside that directory, and the directory is wiped
after each run. The grader does not push to your repo or any other
repo. The only output that escapes the host is the GitHub issue
comment.

**Can I see the grader's full reasoning?**
Each run is assigned a `run` ID (visible in every comment). The
professor has access to the full prompt the grader received and the
full conversation Claude had with itself — these are archived on the
grader host. If you have a contested grade and want the professor to
review the trace, mention the run ID in your comment.

**Is this how my whole grade is computed?**
No. Auto-grade is one of three inputs to your sprint grade. The
professor's eval, peer review, and the auto-grade together determine
the final number per the grading model in the syllabus.

---

## What to do right now

Nothing extra. Keep merging work to `main` as you always have. The
auto-grade issue will appear at the sprint deadline. When it does:

1. Read it.
2. If anything looks wrong, comment on it with evidence.
3. Wait for the professor's sign-off.

If you don't see the issue within 30 minutes of the deadline, ping
the professor.

— mhunter@hunter.org
