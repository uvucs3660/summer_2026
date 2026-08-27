---
track: ai
week: 14
title: The Guarded Agent
subtitle: Five Threats, Five Layers, and the Difference Between Declined and Blocked
runtime: 20
---

NOTES:
Week fourteen, AI track. The last one, and it is the capstone.

Everything in this track has been a component: a briefing, a description, a work order, an exit code, a tool list, a ranking, a deliberation, a box. This lecture is what happens when you assemble them into something you would actually let run unattended.

Forge 09 is due December fourth.

---

# What you'll know after this

- The **five threats**, and why four of them are about capability rather than intent
- **Defense in depth** — five layers, each doing a job the others cannot
- The difference between **declined** and **blocked** — and why you must demonstrate both

NOTES:
Three things. The last is the capstone demonstration and it fits in one screenshot each.

---

# The five threats

![](cc-the-11-pillars-five-threats.svg)

NOTES:
Read them down.

Prompt injection. Any text the agent reads is an instruction channel. A web page, a file, an issue comment, an NPC line a player typed in your game. Treat everything fetched as data, never as authority. This is why the enum in week twelve was doing security work.

Excessive privilege. Blast radius is a function of privileges granted, not intentions held. Week seven, exactly.

Secret leakage. A key in a tracked file is a key in every clone of that repository, forever, and if you are distributing peer-to-peer there is no revocation — you cannot unpublish from a swarm.

Supply chain. Every MCP server and every plugin runs with your privileges. Read the tool list.

Unattended autonomy. A headless run has no approval gate, because nobody is there to approve. That is what hooks are for.

Now the line at the bottom, which is the pattern. Four of the five are about capability, not intent. None of them require anybody to be malicious. They require somebody to be careless once, or a model to be confidently wrong at the wrong moment.

---

# Defense in depth

![](cc-the-11-pillars-defense-in-depth.svg)

NOTES:
Five layers, and the reason there are five is that each does something the others cannot.

The soul makes it want to behave, and its unique property is that it generalises — it applies to situations you never imagined, which is exactly where your explicit rules have no coverage.

Permission modes put a human in the loop, which is excellent while a human is there and worth nothing at three in the morning.

Hooks make misbehaviour impossible rather than unlikely. Deterministic, not persuadable. But only where you installed one, and you can only install them for cases you thought of.

Least privilege makes the residue survivable. Whatever gets past everything above, if the agent cannot reach the production database, it cannot drop it.

And the audit trail is the only layer that does anything after the fact. Everything else is prevention; this is the one that lets you explain what happened.

Read the closing line. This is not redundancy — it is not five attempts at the same thing. Each layer covers a failure the others structurally cannot.

---

# Declined is not blocked

![](cc-the-11-pillars-declined-vs-blocked.svg)

NOTES:
And here is the capstone demonstration, which is one screenshot on each side.

Ask the agent to do something its soul forbids. It refuses, and it tells you why. There was reasoning. It weighed something. And — importantly — it is persuadable in principle. That is sometimes exactly right, because you want an agent that can be talked out of a rule when the rule does not fit. And it is sometimes the risk, because so does everyone else who talks to it.

Ask it to do something a hook forbids. Nothing reasoned. Nothing was weighed. The call is cancelled, exit two, reason on stderr. There is no argument that gets past it — including a correct one, which is a cost you are choosing to pay.

Those are different events with different guarantees, and running them side by side is the clearest way I know to see what each layer actually buys. The soul is judgement, which generalises and can be wrong. The hook is a wall, which does not generalise and cannot be talked around.

You need both, and after this demonstration you will know why in a way that no amount of me saying it can produce.

---

# Forge 09 — the capstone · due Sun Dec 4

- An agent with a **soul**, at least one **hook**, and a **narrowed** tool list
- Demonstrate **declined** — the soul refuses, with reasoning
- Demonstrate **blocked** — `exit 2`, and the reason on stderr
- Name which of the **five threats** each layer addresses

Read `cheatsheet-cc-the-11-pillars`.

**Capstone Dec 4 · Showcase Dec 7–11.**

NOTES:
Forge 09, December fourth, alongside everything else — so start it before the break.

The two demonstrations are the graded core, and they are cheap to produce once the thing exists. Two transcripts.

The fourth bullet is where the thinking is. For each layer you built, say which threat it addresses. You will probably find one threat with no layer against it, and that is the most useful sentence in your submission — more useful than another layer, because a known gap is manageable and an unknown one is not.

And I want to close the track properly, because this is the last one.

Eleven weeks ago we started with a claim: that a complete game is roughly one prompt away, and the scarce skill is specifying precisely enough that what comes back is correct, and knowing how to tell whether it is.

The game track has been the second half of that — building the thing well enough to know what correct looks like. This track has been the first half. A briefing that is a contract. A description that is a trigger. A work order for someone who cannot ask. An exit code that is not a request. A tool list that is a blast radius. A ranking that resolves conflicts. A deliberation that records dissent.

None of that is about typing faster. All of it is about being precise about what you want, in a form something else can act on — which is the same skill your spec section has been teaching from the other direction, and it is why the two tracks were never really separate.

Good luck at the Showcase.
