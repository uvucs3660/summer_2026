# Spec Section — Conformance Vectors

**Due:** Sun Oct 11, 2026 23:59 MT · **Points:** 100

## What to do

Ship the vectors that make your section's claims checkable. PR against `engine-spec` adding files under `conformance/vectors/<your-section>/`.

Format is in `spec/S00-overview.md`; `src/vector.ts` validates, and its error messages name the offending field.

## Writing a vector that can fail

The failure mode is a vector that passes no matter what. Three ways it happens:

- **It asserts a constant.** If your vector runs an empty world, every implementation returns the offset basis and it passes unconditionally.
- **It only covers the happy path.** A collision vector where nothing collides proves nothing.
- **It restates one implementation.** If the only way to know the expected hash is to run your own build, you wrote a snapshot, not a claim.

Include the case that is easy to get wrong: the boundary, the tie, the empty set.

## Deriving the expected hash

Quantize first, rounding **half away from zero** — not the host language's `round`. See `cheatsheet-conformance-vectors` for a one-liner that computes the hash.

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria

- Every non-trivial claim in your section has a vector.
- At least one vector covers a boundary, tie, or empty case.
- All vectors pass `npx vitest run` and sit in the directory matching their `section`.
