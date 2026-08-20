# Submission Mechanics

## The short version

**Every submission is a git commit.** You paste the commit URL into Canvas; the grader clones your repository and reads it.

Canvas stores a link. Your repository is the submission.

## Your repositories

| Repo | What |
|---|---|
| `uvucs3540/portfolio_<username>_fall_2026` | Devlog, Forge artifacts, Codex, scope contract |
| `uvucs3540/engine-spec` | The class engine specification — one repo, everyone |
| `uvucs3540/game_<username-or-team>_fall_2026` | Your game |

All three are provisioned after Onboarding 1. You get `maintain`; accept the invite within 24 hours.

## Submitting

**Individual work** — commit, copy the commit URL, paste it:

```
https://github.com/uvucs3540/portfolio_you_fall_2026/commit/a3f9c21
```

**Spec work** — the pull request URL.

**Game milestones** — tag the commit you want graded, then submit the tag URL:

```bash
git tag game-sprint-1-final
git push origin game-sprint-1-final
```

Tagging matters: it says *this* commit is the submission, not whatever happens to be on `main` when the grader runs.

## Lateness is the commit timestamp

10% per day, floor at 50% — measured by **when you committed**, not when you pasted.

This cuts both ways. A submission discovered 24 hours late is still gradable with the deduction. And backdating a Canvas paste does nothing, because git already recorded when the work happened.

## Before you commit

```bash
./check.sh
```

In your portfolio repo. It verifies the structure and scans for committed secrets, and it is the same check the grader starts from — so a clean run means the grader can find your work.

## Never commit

API keys, tokens, `.env` files, or another student's code. If a key leaks, **rotate it first**, then clean the repo. Removing the commit does not un-publish it — anyone could already have fetched.

## Why git and not file upload

The grader needs the code, the history, and the review threads. A zip obscures all three. And it is how professional work is submitted, which is the other half of the point.
