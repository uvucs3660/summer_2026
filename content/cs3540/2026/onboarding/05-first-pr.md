# Onboarding 5/5 — Your First PR to the Class Engine Spec

**Due:** Sun Aug 30, 2026 23:59 MT
**Points:** 1 (pass/fail)
**Prerequisites:** Assignments 1 and 2.

## What to do

You have been assigned a starter section of the class engine spec at
<https://github.com/uvucs3540/engine-spec>. Your assignment appears in `spec/OWNERS.md`.

1. Branch: `git checkout -b <your-username>/<section-slug>`
2. Edit your assigned section. Fill in the parts marked for you — a definition, an invariant, an
   example. Small is fine; this is about the workflow, not the prose.
3. Push and open a pull request against `main`.
4. **Review one classmate's open PR.** Leave at least one substantive comment — a question about
   something genuinely ambiguous counts, and is in fact the point.
5. Get your PR merged.

## Expect a merge conflict

Some of you have been given **deliberately overlapping edits**. This is not a mistake.

Merge conflicts are the part of git that the training course covers least well and that a shared
repository guarantees you will meet. Better that you meet your first one this week, in class, where
I am standing right there — than alone at 2 a.m. in Week 9 with a capstone deadline.

If you hit one:

```bash
git fetch origin
git rebase origin/main
# resolve the marked sections, then:
git add <file>
git rebase --continue
git push --force-with-lease
```

Bring it to class if it fights you.

## Why the spec is one shared repository

Every section of that document will be read by an agent and turned into a working engine — several
times over, independently. Where those builds disagree, the prose was ambiguous, and the ambiguity
belongs to whoever wrote it.

That is the feedback loop this course runs on, and it only works if the document is genuinely
shared. You are not writing your own spec. You are writing one section of the class's spec, and
everyone's game will run on what it produces.

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria

- A pull request authored by you is **merged** into `main`.
- You left at least one substantive review comment on a classmate's PR.
- Your edit is confined to the section assigned to you in `spec/OWNERS.md`.
