# Submission Mechanics

## There is no Canvas submission

Exactly one assignment is submitted in Canvas: **your GitHub username**, in Week 1. It has to be, because until it exists you have no repository.

Everything after that is graded from a **git push**.

```
you push  →  webhook fires  →  autograder clones and scores against the rubric
          →  feedback posted as a GitHub ISSUE on your repo
```

Your commit history is the submission. Canvas holds the grade; your repository holds the work and the feedback.

## Where feedback arrives

**As an issue on your own repository.** Not in Canvas, not by email.

Open the Issues tab after you push. You will find a scored breakdown against each rubric criterion, with the reasoning. If you think a score is wrong, comment on the issue and tell me — I review every result and can override it.

Watch your repo so you get notified. GitHub → your repo → **Watch → All Activity**.

## Your repositories

| Repo | Holds |
|---|---|
| `uvucs3540/portfolio_<username>_fall_2026` | Devlog, Forge artifacts, Codex, divergence responses, scope contract |
| `uvucs3540/engine-spec` | The class engine specification — one repo, everyone |
| `uvucs3540/game_<username-or-team>_fall_2026` | Your game |

All three are provisioned once your username is submitted. You get `maintain`; accept the invite within 24 hours.

## Tagging a milestone

For game milestones, push a tag so the autograder knows *which* commit is the submission rather than guessing at whatever is on `main`:

```bash
git tag game-sprint-1-final
git push origin game-sprint-1-final
```

## Spec work

Pull requests against `engine-spec`. The section is graded on its agreement score across the term's generator runs, not on a single submission — so a PR merged in October keeps earning until December.

## Lateness is the commit timestamp

10% per day, floor at 50% — measured by **when you committed**.

This is more forgiving than it sounds. Work committed on time but discovered late is still on time; git already recorded when it happened. There is also nothing to forget to paste.

## Before you push

```bash
./check.sh
```

In your portfolio repo. It verifies the structure and scans for committed secrets, and it is the same check the autograder starts from — a clean run means the grader can find your work.

## Never commit

API keys, tokens, `.env` files, or another student's code. If a key leaks, **rotate it first**, then clean the repo. Removing the commit does not un-publish it.

## Why this way

The autograder needs the code, the history, and the diffs. A file upload obscures all three. And feedback belongs next to the work it is about — an issue on the repo you are already looking at beats a comment in a gradebook you open once a week.
