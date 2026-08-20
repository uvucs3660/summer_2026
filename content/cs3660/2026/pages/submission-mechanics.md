# Submission Mechanics & Personal Portfolio Repos

## TL;DR

**Submissions are git commits.** Across the course, individual deliverables are committed to your personal portfolio repo, and you submit the commit URL in Canvas. Team deliverables are submitted by tagging a specific commit on your team repo as `sprint-{N}-final` and submitting the tag URL.

Canvas does **not** store your artifacts directly — it stores commit URLs, and the LLM grader pulls grading inputs from git.

## Your personal portfolio repo

One repo per student, provisioned automatically when you complete onboarding assignment 4 (GitHub username submission):

```
https://github.com/uvucs3660/portfolio_<your-username>_summer_2026
```

You're added as `maintain` collaborator. The starter template seeds:

```
week1/
  git-training-cert.{pdf,png}    ← Onboarding 1
  pausch-reflection.md            ← Onboarding 2
  claude-pro-proof.png            ← Onboarding 3
  api-smoke-test.md               ← Onboarding 5
reflections/
  w01.md ... w13.md               ← Weekly reflections (Track 1)
cc-artifacts/
  01-skill/
  02-subagent/
  03-hook/
  04-mcp/
  05-plugin/                      ← 5 individual CC artifacts (Track 3)
sprints/
  sprint-1-reflection.md
  sprint-2-reflection.md
  sprint-3-reflection.md          ← Per-sprint individual reflections (Track 2)
```

## Per-sprint team repo

One repo per (sprint, team), provisioned at sprint kickoff after team assignments are computed:

```
https://github.com/uvucs3660/project<N>_team<M>_summer_2026
```

Your team's full sprint work lives here.

## Why git, not Canvas upload

- The LLM grader needs structured access to code, commit history, and review threads. Canvas file uploads obscure all of that.
- Industry submission patterns are git-based — you're learning what professional work looks like.
- Single source of truth (the repo) is easier to grade fairly and audit later.
- Late-policy adjudication and version history are intrinsic to git.

## Permissions

- You: `maintain` on your portfolio repo and on each team repo you're a member of.
- Instructor (`hunterino`): `admin` on every repo in `uvucs3660`.
- LLM grader: read-only fine-grained PAT scoped to the org.

## API keys

Your class LLM API key is delivered via Canvas DM. **Never commit it to any repo.** Store it as `CS3660_LLM_KEY` in your shell environment. If you suspect a leak, DM the instructor for rotation.

## Late submissions

10%/day deduction, floor at 50%. The submitted-at timestamp is the **commit timestamp** in git, not the Canvas-paste timestamp. This means: late discoveries 24h after the deadline are still gradable, but with the deduction.
