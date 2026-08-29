---
track: ai
week: 14
title: The Guarded Agent
subtitle: Five Threats, Five Layers, and the Difference Between Declined and Blocked
runtime: 20
---

NOTES:
Week fourteen, AI track. The last one, and it is the capstone.

Everything in this track has been a component. A briefing. A description. A work order. An exit code. A tool list. A ranking. A deliberation. A box. Each of those was one Thursday, and each was small enough to hold in one hand.

This lecture is what happens when you assemble them into something you would actually leave running while you are asleep.

Forge 09 is due December fourth.

---

# What you'll know after this

- The **five threats**, and why four of them are about capability rather than intent
- **Defense in depth** — five layers, each doing a job the others cannot
- The difference between **declined** and **blocked** — and why you must demonstrate both

NOTES:
Three things. The third is the capstone demonstration, and the whole of it fits in two screenshots, one for each half. That is not a low bar. It is a very exact one.

---

# The five threats

![](cc-the-11-pillars-five-threats.svg)

NOTES:
Read them down.

Prompt injection. Any text the agent reads is an instruction channel. A web page, a file, an issue comment, a line a player typed into your game. Treat everything fetched as data and never as authority. This is why the enum in week twelve's dialogue system was doing security work.

Excessive privilege. Blast radius is a function of the privileges granted, not the intentions held. Week seven, exactly.

Secret leakage. A key in a tracked file is a key in every clone of that repository, forever. And peer to peer there is no revocation, because there is nobody to revoke it. You cannot unpublish from a swarm.

Supply chain. Every MCP server and every plugin runs with your privileges. Read the tool list.

Unattended autonomy. A headless run has no approval gate, because nobody is there to approve. That is what hooks are for.

Now the line at the bottom, which is the pattern. Four of the five are about capability, not intent. Not one of them requires anybody to be malicious. They require somebody to be careless once, or a model to be confidently wrong at a moment when nothing was standing in front of it.

---

# Defense in depth

![](cc-the-11-pillars-defense-in-depth.svg)

NOTES:
Five layers, and the reason there are five is that each does something the other four structurally cannot.

The soul makes it want to behave, and its unique property is that it generalises. It applies to situations you never imagined, which is exactly where your explicit rules have no coverage.

Permission modes put a human in the loop. Excellent while a human is there, worth nothing at three in the morning.

Hooks make misbehaviour impossible rather than unlikely. Deterministic, not persuadable. But only where you installed one, and you can only install them for cases you thought of.

Least privilege makes the residue survivable. Whatever gets past everything above, if the agent cannot reach the production database then it cannot drop the production database. That is not a mitigation. That is arithmetic.

And the audit trail is the only layer that does anything after the fact. The other four are prevention. This one lets you say what happened, which you will need on the day prevention did not.

Read the closing line. This is not redundancy — not five attempts at the same job. Each layer covers a failure the others cannot see.

---

# Declined is not blocked

![](cc-the-11-pillars-declined-vs-blocked.svg)

NOTES:
And here is the capstone demonstration, which is one screenshot on each side.

Ask the agent to do something its soul forbids. It refuses, and it tells you why. There was reasoning. Something got weighed. And it is persuadable in principle, which is sometimes exactly what you want, because a rule that does not fit the case should be arguable. It is also the risk, because so is everybody else who talks to it.

Now ask it to do something a hook forbids. Nothing reasoned. Nothing weighed. The call is cancelled, exit two, the reason on standard error. No argument gets past that — including a correct one, which is a cost you are choosing on purpose.

Two different events with two different guarantees, and running them back to back is the clearest way I know to see what each layer actually buys. The soul is judgement. It generalises, and it can be wrong. The hook is a wall. It does not generalise, and it cannot be talked around.

You need both. And after you have watched the same request meet each of them, you will know why in a way that no amount of me saying it can produce.

---

# Forge 09 — the capstone · due Sun Dec 4

- An agent with a **soul**, at least one **hook**, and a **narrowed** tool list
- Demonstrate **declined** — the soul refuses, with reasoning
- Demonstrate **blocked** — `exit 2`, and the reason on stderr
- Name which of the **five threats** each layer addresses

Read `cheatsheet-cc-the-11-pillars`.

**Capstone Dec 4 · Showcase Dec 7–11.**

NOTES:
Forge 09, December fourth, alongside everything else that lands then. Start it before the break.

The two demonstrations are the graded core, and they are cheap once the thing exists. Two transcripts.

The fourth bullet is where the real thinking is. For each layer, name the threat it addresses. You will probably find a threat with nothing standing against it, and that sentence is worth more than another layer, because a known gap is something you manage and an unknown one is something that happens to you.

And I want to close the track properly, because this is the last one.

Eleven weeks ago we started with a claim: that a complete game is roughly one prompt away, and the scarce skill is specifying precisely enough that what comes back is correct, and knowing how to tell whether it is.

The game track has been the second half of that — building the thing well enough to recognise correct when you see it. This track has been the first half. A briefing that is a contract. A description that is a trigger. A work order for somebody who cannot ask you a question. An exit code that is not a request. A tool list that is a blast radius. A ranking that resolves its own conflicts. A deliberation that records what it rejected. A box a stranger can open.

None of that is about typing faster. All of it is about being precise about what you want, in a form something else can act on — which is the same skill your spec section has been teaching you from the other side, and it is why the two tracks were never really separate.

Good luck at the Showcase.
