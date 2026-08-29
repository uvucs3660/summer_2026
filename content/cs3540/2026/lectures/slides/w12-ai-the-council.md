---
track: ai
week: 12
title: The Council
subtitle: Deliberation, Recorded Dissent, and Where Authority Actually Lives
runtime: 16
---

NOTES:
Week twelve, AI track.

Last week you gave one agent a point of view. This week is what happens when you run several of them and arrange for them to disagree on purpose — and why the disagreement is the product rather than a problem to be minimised.

Hold on to that sentence, because the natural instinct with a Council is to tune it until the members agree. Every hour spent doing that is an hour spent destroying the only thing it was built to make.

Forge 08 is a Council run, due November sixteenth.
---

# What you'll know after this

- Why a **single** agent with a good soul is still not enough
- The three Council norms, and which one is most often broken
- Why **authority does not transfer** from a vote
- Why **dissent** must be recorded, not just outcomes

NOTES:
Four things, and the third is the one that keeps this from becoming a genuinely bad idea. It is a question about authority rather than about agents.
---

# Why more than one

An agent with a ranked soul is **consistent.** It is not **checked.**

- It will pursue its ranking into a bad conclusion just as confidently as a good one
- A second agent with a different vantage point is the cheapest possible review
- The value is in the **disagreement** — agreement tells you almost nothing

> If your Council always agrees, you built one agent and ran it four times.

NOTES:
Start with the case for it, because more agents is not automatically better and usually is not. Usually it is just more expensive.

A soul makes an agent consistent, and consistency is worth having — it is what last week bought you. But consistency is not correctness. A well-ranked agent will follow its ranking into a wrong conclusion with exactly the confidence it follows it into a right one, and nothing inside it distinguishes the two cases. The confidence is a property of the ranking, not of the answer.

So a second perspective is the cheapest check available. Not a better model. Not a longer prompt. A different vantage point, which costs you one more call.

And read the quote, because that is the failure mode and it is the common one. If your Council members are near-identical — same prompt, same framing, same role, four times over — they will agree, and the agreement will feel like validation while carrying no information at all. You have run one agent four times and paid for it four times. Divergence is the product. If nothing diverged, nothing was tested.
---

# The norms

![](soul-sovereign-council-norms.svg)

NOTES:
Three norms, and I will tell you in advance which one gets broken.

Fresh perspective. Each round starts without deferring to what the last round concluded. Without that, a Council converges on round two and stays converged for the rest of its life, because the first opinion anchors everything after it — and once it has anchored, further rounds are cost with no yield.

Good faith. Steelman the position before you attack it. An objection to a weak version of an argument is not an objection to the argument. It is an objection to a version you built in order to knock down.

And equal consideration, which is the one that actually gets broken. The strength of an argument decides, not the identity of whoever made it. In practice people quietly weight the output of whichever model they think is strongest, and the moment you do that you have turned a Council into one opinion with three witnesses.

Now the right-hand panel, which is the guardrail over all of it. Equality applies to deliberation. It does not mean the conclusion is authorised. The Council agreed, so it is fine, is exactly the reasoning this structure exists to prevent. Authority stays with the unamendable human above all three branches. A vote is advice. It is never permission.
---

# Record the dissent

![](soul-sovereign-council-dissent.svg)

NOTES:
And here is the part almost everybody skips, because it looks like paperwork.

A log that records only what was adopted cannot tell you why anything was rejected. So six months from now somebody proposes the rejected option again — reasonably, because there is no record of it ever having been considered — and the whole argument runs a second time at full cost, possibly landing somewhere different for no reason anybody could name.

Recording the dissent fixes that, and then it does something better.

Almost every rejection depends on a constraint that was true at the time. The library was broken. The budget was not there. The platform did not support it. Constraints change, and when one changes you want to find every decision that hinged on it in a single search, instead of rediscovering them one at a time over the following year.

A decision log without dissent cannot answer the question what would we do differently now. A log with dissent answers it directly.

Take the last line at face value. Today's minority opinion may be tomorrow's governing principle, and the only thing standing between those two states is whether anybody wrote it down.
---

# Forge 08 — due Sun Nov 16

- One **real** decision from your project — not a hypothetical
- Council members with **genuinely different** vantage points
- Ship the **dissent**, not only the conclusion
- Say what you did with it — including "overruled the Council, here is why"

Read `cheatsheet-soul-sovereign-council`.

Next Tuesday, Game: **Distance** — netcode and peer-to-peer.

NOTES:
Forge 08, November sixteenth.

Use a real decision. Councils run on invented questions produce polite agreement, because there is nothing at stake and no context to disagree about — and it is audible in the transcript.

Give the members genuinely different vantage points. The archetypes from week five are a good source: a Prototyper and a Maintainer disagree about nearly everything, and both are right about something.

And the last bullet is deliberately there. Overruling the Council is a legitimate outcome, and I want to see it if it happened, because it is the clearest demonstration available that you understood where authority sits. A submission where the Council decided and the human implemented has the structure exactly backwards.

Next Tuesday is netcode — the week the determinism requirement from week three finally cashes out.