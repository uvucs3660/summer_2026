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

## Your repository

**One repo, named for your UVU username**, with your GitHub handle granted access:

```
github.com/uvucs3540/<your-uvu-username>
```

Provisioned once you submit your GitHub handle in Week 1. You get `maintain`; accept the invite within 24 hours.

Inside it, five directories by purpose:

| Directory | What lives there |
|---|---|
| `week1/` | Onboarding evidence |
| `journey/` | Your learning record — `journal/`, `evidence/`, `divergence/`, `forge/` |
| `games/` | The pitch, the scope contract, and every project |
| `presentations/` | Your two talks |
| `.claude/` | Skills, agents, and hooks |

Assignments land under those as files or directories, depending on their size.

The one thing **not** in your repo is the class engine specification, which is shared: [`uvucs3540/engine-spec`](https://github.com/uvucs3540/engine-spec).

## Naming a project

Pick a **studio name** — solo or team, one name you keep all term — and name each project `<studio>-<assignment>`:

```
games/maverick-game1/
games/maverick-game2/
games/maverick-capstone/
```

Team members use the same studio name, so a directory says who built it without anyone maintaining a roster.

## Everything is markdown, and it links

Documentation is markdown, and anything referring to something else **links to it** — a Forge artifact to its evidence, the scope contract to the game, a journal entry to the decision it explains.

That is not tidiness. It is how a reader — the autograder, a classmate, you in December — finds the thing you are talking about.

## Tagging a milestone

For game milestones, push a tag so the autograder knows *which* commit is the submission rather than guessing at whatever is on `main`:

```bash
git tag maverick-game1-final
git push origin maverick-game1-final
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

It verifies the structure and scans for committed secrets, and it is the same check the autograder starts from — a clean run means the grader can find your work.

## Never commit

API keys, tokens, `.env` files, or another student's code. If a key leaks, **rotate it first**, then clean the repo. Removing the commit does not un-publish it.

## Why this way

The autograder needs the code, the history, and the diffs. A file upload obscures all three. And feedback belongs next to the work it is about — an issue on the repo you are already looking at beats a comment in a gradebook you open once a week.
