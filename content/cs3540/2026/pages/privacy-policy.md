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

## Teams see the work, not the grades

On the project repo, your teammates see the work — obviously, they are building it — and they see the **rank order of contribution** within the team: who contributed most, second, and so on, computed from commit history.

They do **not** see your grade. Not the project grade, not your individual grade, not your standing in the course. Rank order is a fact about a shared codebase. A grade is an education record, and it is between you and me.

> **Why show rank order at all?** Because the alternative is teams discovering an imbalance in December, when nothing can be done about it. Seeing it in October is how a team fixes it while there is still term left.

If the ordering looks wrong to you — and it sometimes will, because commit counts are a proxy and design work leaves few commits — **tell me**. It informs my judgment; it does not replace it.

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
