# Game — Sprint 1

**Due:** Thu Nov 5, 2026 23:59 MT · **Points:** 100

## What to do

A playable vertical slice on your engine. Core loop working, 2D or 3D rendering, and at least one generated asset recorded in `assets/MANIFEST.json`.

Tag the commit you want graded:

```bash
git tag game-sprint-1-final && git push origin game-sprint-1-final
```

Submit the tag URL. The grader reads the repository at that tag.

## What is checked

- **Scope.** Against your scope contract, not an absolute size.
- **Playable.** A stranger installs and plays from your README in under five minutes.
- **Provenance.** Every generated asset has a `MANIFEST.json` entry with model, prompt, license, and phase.
- **Degrades visibly.** With every remote provider unreachable, the game runs and says so. Test it with your network off — that is the graded case.
- **Determinism.** Same seed and same commands produce the same state hash.

## Demo

You present in class the week it is due. Ten minutes: play it, show one piece of code you are proud of, say what broke.
