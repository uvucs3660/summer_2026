---
track: ai
week: 8
title: Reading the Divergence Report
subtitle: What It Means When Independent Builds Disagree
runtime: 18
---

NOTES:
Week eight, AI track, and this one is about your own words coming back with a number attached.

By now the scheduled agent has been building the specification independently, several times over, and comparing results. Where builds disagree, there is a report. Your Act Two response to that report is due on Sunday the nineteenth.

This lecture is how to read it, and — more importantly — what it is actually telling you, because the natural reading is the wrong one.

---

# What you'll know after this

- What the report **measures** — and what it does not
- Why a disagreement is **evidence about your prose**, not about a build
- The four questions to ask of a failing vector
- What a good response looks like, and what a bad one looks like

NOTES:
Four things. The second is the reframe and it is the one people resist, so I will spend the most time there.

---

# What the report is

![](conformance-vectors-divergence-report.svg)

NOTES:
Here is the mechanism.

The same vector runs against several independent builds of the specification. A vector pins the seed, the commands, and the tick count, so the only thing that can vary is the implementation.

Three builds agree. One does not. The majority is promoted, versioned, and tagged, and that tagged engine is what everyone's game runs on.

And then the loop closes: the failing vector belongs to a section, and the section has an owner. That is not a search or an investigation — it is a lookup.

---

# It is a measurement, not a verdict

The natural reading: **"build D has a bug."**

The correct reading: **"the prose permitted two readings, and D took the other one."**

- Every build implemented your section faithfully
- They disagree because **your section allowed them to**
- A build cannot be wrong about an unspecified thing — there is nothing to be wrong about

NOTES:
Now the reframe, and I want to be emphatic because the instinct is strong and it is wrong.

When you see three builds agreeing and one disagreeing, the overwhelming instinct is that the odd one out is broken. Three against one. Majority rules.

But think about what actually happened. Four independent implementations read your prose and each did what it said. Three interpreted an ambiguous sentence the same way — probably because it is the more natural reading, or the more common convention — and one took the other reading.

The minority build is not wrong. It is *legal*. It did something your specification permitted. The fact that it is outnumbered is a fact about which reading is more popular, not about which is correct, because you never said which was correct.

That is why we call it divergence rather than failure. It is a measurement of ambiguity, and the number of builds that agree is a measure of how obvious the intended reading was — not whether there was one.

---

# Four questions for a failing vector

1. **What exactly diverged?** Which claim, at which tick, in which quantity
2. **What are the two legal readings?** Name both. If you cannot name the second, you have not found the ambiguity yet
3. **Which one did you mean?** Decide. This is a design decision, not a lookup
4. **What sentence forecloses the other?** Write it. That sentence is the fix

Question 2 is where the work is.

NOTES:
Here is the procedure.

One: what diverged. Not "S11 failed" — which claim, at which tick, in which quantity. Usually the hash diverges at a specific tick and you can bisect to it.

Two, and this is the whole job: name both legal readings. If you cannot articulate what the other build thought you meant, you have not found the ambiguity. You are still assuming it made a mistake. Keep reading your own sentence until you can see the second interpretation — and it will be there, because a build found it.

Three: decide which you meant. This is a genuine design decision. Sometimes the minority reading is better and you should adopt it.

Four: write the sentence that forecloses the other reading. Not clearer — narrower. "Round" becomes "round half away from zero." "The boxes overlap" becomes "overlap is non-strict; touching edges collide." "Resolve each pair" becomes "resolve pairs in ascending order of the lower id, then the higher."

---

# Good and bad responses

**Bad**

- "Build D is broken." — you were not asked about the build
- "Fixed the prose." — which sentence, permitting what?
- "There was no real ambiguity." — the report says otherwise, and it is a measurement

**Good**

- Names both readings, picks one, quotes the **new sentence**, and adds the **vector** that would now catch it

NOTES:
What the rubric is looking for.

The three bad ones are the three I see most. Blaming the build sidesteps the question. "Fixed the prose" with no detail is unassessable — I cannot tell whether you understood the ambiguity or reworded something at random until it passed. And claiming there was no real ambiguity when a build demonstrably found one scores zero, because the report is evidence and the assertion is not.

A good response has four parts and fits in a paragraph. Both readings, named. The one you chose. The exact new sentence, quoted. And the vector that would now catch this — because if it could happen once it can happen again, and a fix with no test is a hope.

That last part should be familiar. It is the same standard as an anti-goal you can show firing and a hook you have seen block. A claim with no vector is an opinion, three weeks running.

---

# Divergence Response · Act II — due Sun Oct 19

- One response per divergence attributed to **your** section
- Both readings named; the sentence quoted; the new vector included
- If your section had **no** divergence: say what you pinned that others did not

Read `cheatsheet-conformance-vectors` and `cheatsheet-writing-a-spec-agents-can-build`.

Next Tuesday, Game: **Space** — the 3D pipeline.

NOTES:
Due Sunday the nineteenth.

The third bullet is for the few of you whose sections came through clean. That is a real result and it deserves a real answer: what did you pin that other sections did not? Go find a sentence in your section that names a rounding, an order, or a tie-break, and explain what would have happened without it. That is the same intellectual work as fixing a divergence, done in advance.

One last thing, and it is the reason this assignment exists at all.

Nothing else in your education does this. You have written hundreds of pages of prose and never once received a machine-generated report saying "this sentence had two meanings and here is proof." Human readers patch gaps automatically and silently, and you never find out the gap was there.

Read the report as the rarest thing you will get all semester: unambiguous feedback about ambiguity.
