# Grades, Privacy, and FERPA

## Two kinds of repository

**Your own repo — `uvucs3540/<your-uvu-username>` — is private and yours alone.**

| | |
|---|---|
| **You** | `maintain` |
| **The instructor** | `admin` |
| **The autograder** | a read-only, org-scoped token |

Nobody else. **Not your teammates.** Your journal, your evidence, and your divergence responses are your learning record, and no student has access to them.

**A team project repo — `uvucs3540/<studio>-<assignment>` — is private to the team**, and every member has **`maintain`**. You are all building in it, so you all need to write to it.

That split is deliberate. `maintain` is write access, and a team project living inside your personal repo would hand your teammates write access to your journal along with it.

## How a team project is graded

Two steps.

**1 · The project is graded once, against the rubric.** One score for the artifact — scope, playable, generative assets, LLM narrative, visible degradation, multiplayer. The rubric does not care who did what.

**2 · Participants are ranked by their contribution to those same criteria.** Not by commit count, not by lines — by which criteria you moved. Who got multiplayer syncing. Who built the asset pipeline. Who made the fallback work when the provider was down.

Your individual grade starts from the project score and is adjusted by where you land in that ranking.

## Teams see the ranking, not the grades

Your teammates see the work — obviously, they are building it — and they see the **rank order**.

They do **not** see grades. Not the project score, not your individual grade, not your standing. The ranking is a statement about a shared artifact. A grade is an education record, and it is between you and me.

> **Why show the ranking at all?** Because the alternative is a team discovering an imbalance in December, when nothing can be done. Seeing it in October is how a team fixes it while there is still term left.

Ranking against rubric criteria is also why a designer who wrote little code can rank highly: if the criterion is "the fallback degrades visibly" and you are the one who made that true, that is your contribution regardless of how it shows up in the log.

If a ranking looks wrong, **tell me** — it informs my judgment, it does not replace it.

## The shared specification is different

[`uvucs3540/engine-spec`](https://github.com/uvucs3540/engine-spec) is collaborative by design. Everyone reads it, everyone reviews pull requests against it, and your section carries your name in `OWNERS.md`.

That is a deliberate exception, and it is limited to that one repository. Your own repo stays private.

## What the autograder sees

The service at `2h2.us` receives your repository at the commit or tag that triggered it, and the rubric for that assignment. It does **not** receive your name, your student ID, or your Canvas record.

I review every result and may override it. **A grade is mine, not the model's** — if you think one is wrong, comment on the issue and tell me.

## Your work is yours

You own what you write. Keep it after the term, put it in a portfolio, show it to employers, make the repo public yourself once grades are final.

If you would rather your game not be shown at the showcase, tell me beforehand and it will not be.

## FERPA

Your education records — grades, feedback, and your standing in this course — are protected by the Family Educational Rights and Privacy Act. I do not discuss your performance with anyone, including parents and employers, without your written consent.

Course records live in the department's systems and are not published. Student repositories are archived read-only at the end of the term and removed from active workspaces.

## Academic integrity, concretely

The **shared specification** is collaborative: read it, edit it, review it.

**Your own repository is yours.** Do not seek access to another student's repo, and do not share yours outside your team. Using AI is required here — passing off work you cannot explain is the thing that is not allowed, and the Game Technique talk is where that becomes visible.

## Questions

Ask. Anything unclear in this document is a problem with the document.
