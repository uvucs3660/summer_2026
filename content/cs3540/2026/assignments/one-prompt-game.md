# The One-Prompt Game

**Due:** Sun Sep 6, 2026 23:59 MT · **Points:** 100

Reproduce the experiment this course is built on, then find where it breaks.

## What to do

**1 · Ship a complete game from one prompt.** Write a single prompt describing a playable game — genre, core loop, controls, win and lose conditions, and the look you want. Answer follow-up questions, then let it build. Deploy it somewhere playable.

**2 · Commit the prompt verbatim.** `prompt.md`, exactly what you sent, plus every clarifying exchange **quoted, not summarized**.

**3 · Write the failure analysis.** `failure-analysis.md` — this is the assignment. The game is the setup.

Before you start, write down what you expect it to fail at. Then compare.

Cover: what does not work · what you tried to change and could not · **why** — trace one failure to a cause in the generated architecture · what you would have to specify differently to get it right.

## Why the analysis is the point

You are locating the ceiling. Everything after this week is about raising it — by specifying rather than prompting. "It worked great" is not a finding; neither is "the AI is bad at games." The useful answer is specific and architectural.

## How this is graded

**Push to your repository.** The autograder runs on the push and posts its
feedback as a **GitHub issue** on that repo, scored against the rubric below.
Read the issue; that is where your feedback lives.

There is nothing to submit in Canvas. Your commit history *is* the submission,
and the commit timestamp is what the late policy measures.

## Acceptance criteria

- Runs from a clean clone following your README.
- Prompt and all follow-ups committed verbatim.
- At least one failure traced to a cause, naming something you tried and could not fix.
- README states honestly what the game does and does not do.
