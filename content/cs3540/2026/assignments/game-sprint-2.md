# Game — Sprint 2

**Due:** Thu Nov 19, 2026 23:59 MT · **Points:** 100

## What to do

Depth. Game AI or procedural generation working, narrative or dialogue present, and the LLM path recorded into the command log.

Tag the commit you want graded:

```bash
# in your project repo, uvucs3540/<studio>-game2
git tag game2-final
git push origin game2-final
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

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.
