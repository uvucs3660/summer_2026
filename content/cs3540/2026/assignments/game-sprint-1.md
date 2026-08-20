# Game — Sprint 1

**Due:** Thu Nov 5, 2026 23:59 MT · **Points:** 100

## What to do

A playable vertical slice on your engine. Core loop working, 2D or 3D rendering, and at least one generated asset recorded in `assets/MANIFEST.json`.

Tag the commit you want graded:

```bash
# in your project repo, uvucs3540/<studio>-game1
git tag game1-final
git push origin game1-final
```

The autograder reads the **project repo** at that tag.

## What is checked

- **Scope.** Against your scope contract, not an absolute size.
- **Playable.** A stranger installs and plays from your README in under five minutes.
- **Provenance.** Every generated asset has a `MANIFEST.json` entry with model, prompt, license, and phase.
- **Degrades visibly.** With every remote provider unreachable, the game runs and says so. Test it with your network off — that is the graded case.
- **Determinism.** Same seed and same commands produce the same state hash.

## Demo

You present in class the week it is due. Ten minutes: play it, show one piece of code you are proud of, say what broke.

## Working as a team

The project is scored **once** against the rubric below. Then each member is **ranked by their contribution to those same criteria** — who got multiplayer syncing, who built the asset pipeline, who made the fallback work with the provider down.

Your individual grade starts from the project score and is adjusted by that ranking.

Because the ranking is against rubric criteria and not commit counts, design and integration work counts as much as code. Teammates see the ranking; nobody sees anyone else's grade.

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.
