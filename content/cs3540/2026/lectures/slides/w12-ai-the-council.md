---
track: ai
week: 12
title: The Council
subtitle: Deliberation, Recorded Dissent, and Where Authority Actually Lives
runtime: 16
---

NOTES:
Week twelve, AI track.

Last week you gave one agent a point of view. This week is what happens when several of them disagree on purpose — and why the disagreement is the product rather than a problem to be minimised.

Forge 08 is a Council run, due November sixteenth.

---

# What you'll know after this

- Why a **single** agent with a good soul is still not enough
- The three Council norms, and which one is most often broken
- Why **authority does not transfer** from a vote
- Why **dissent** must be recorded, not just outcomes

NOTES:
Four things, and the third one is the one that keeps this from becoming a bad idea.

---

# Why more than one

An agent with a ranked soul is **consistent.** It is not **checked.**

- It will pursue its ranking into a bad conclusion just as confidently as a good one
- A second agent with a different vantage point is the cheapest possible review
- The value is in the **disagreement** — agreement tells you almost nothing

> If your Council always agrees, you built one agent and ran it four times.

NOTES:
Start with the case for it, because "more agents" is not automatically better and usually is not.

A soul makes an agent consistent. That is genuinely valuable and it is what last week bought you. But consistency is not correctness — a well-ranked agent will follow its ranking into a wrong conclusion with exactly the same confidence it follows it into a right one, and nothing internal flags the difference.

A second perspective is the cheapest check available. Not a better model, not a longer prompt — a different vantage point.

And read the quote, because it is the failure mode. If your Council members are near-identical, they will agree, and that agreement will feel like validation while carrying no information. You have run one agent four times and paid four times. Divergence is the product. If nothing diverged, nothing was tested.

---

# The norms

![](soul-sovereign-council-norms.svg)

NOTES:
Three norms, and I will tell you which one gets broken.

Fresh perspective — each round starts without deferring to what the last round concluded. Without this the Council converges immediately and stays converged, because the first opinion anchors everything after it.

Good faith — steelman the position before you attack it. An objection to a weak version of an argument is not an objection.

And equal consideration, which is the one that actually gets broken. The strength of an argument decides, not the identity of whoever made it. In practice people weight the output of the model they consider strongest, which quietly turns a Council into one opinion with three witnesses.

Now the right-hand panel, which is the guardrail. Equality applies to *deliberation*. It does not mean the Council's conclusion is authorised. "The Council agreed, so it is fine" is exactly the reasoning this structure exists to prevent — authority stays with the unamendable human above all three branches, and a vote is advice, not permission.

---

# Record the dissent

![](soul-sovereign-council-dissent.svg)

NOTES:
And here is the part almost everybody skips, because it feels like paperwork.

A log that records only what was adopted cannot tell you why anything was rejected. Six months later somebody proposes the rejected option again — reasonably, because there is no record of it having been considered — and the entire argument runs a second time, at full cost, possibly reaching a different answer for no reason.

Recording the dissent fixes that, and it does something better. Most rejections depend on a constraint that was true at the time. When the constraint changes — the library gets fixed, the budget arrives, the platform adds the feature — you want to be able to find every decision that hinged on it.

A decision log without dissent cannot answer "what would we do differently now." A log with dissent can.

Read the last line, and take it at face value. Today's minority opinion may be tomorrow's governing principle, and the only thing standing between those two states is whether anybody wrote it down.

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

Use a real decision. Council runs on invented questions produce polite agreement, because there is nothing at stake and no context to disagree about.

Give the members genuinely different vantage points — the archetypes from week five are a good source. A Prototyper and a Maintainer will disagree about almost everything, and both will be right about something.

And the last bullet is deliberately there. Overruling the Council is a legitimate outcome and I want to see it if it happened, because it is the clearest possible demonstration that you understood where authority lives. A submission where the Council decided and the human implemented has the structure exactly backwards.

Next Tuesday is netcode — the week the determinism requirement from week three finally cashes out.
