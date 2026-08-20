---
slug: lecture-w14-soul
week: 14
youtube_id: null
companion_sheets:
  - cheatsheet-soul-sovereign-council
  - cheatsheet-cc-plugins
  - cheatsheet-cc-model-selection
reflection_assignment: devlog-w14
vernacular_tags:
  - "Soul · Sovereign · Council"
  - "ranked values"
  - "prompt injection · excessive privilege · unattended autonomy"
  - "declined vs blocked"
---

# Week 14 — Soul: Governance, Security, and the Guarded Agent

## What you'll know after this

After this lecture you will be able to (a) write a soul whose ranked values resolve a real conflict, (b) name the five agentic threats and their mitigations, (c) explain defense in depth for an agent, and (d) demonstrate declined versus blocked.

## Outline

1. **An agent without a point of view** *(8 min)*
   Drifts toward the average of its training data — helpful, generic, aligned with no one. Fine for a one-off question; inadequate for anything acting on your behalf repeatedly.

2. **Rank the values** *(10 min)*
   An unranked list is decoration. The entire purpose is resolving conflicts, and a conflict is exactly where you need to know which value wins. "Unambiguous over elegant" tells an agent what to do when the precise sentence is ugly. Ties hide the hard choices.

3. **Sovereign and Council** *(10 min)*
   Three branches under an unamendable human. The unit of governance is a ratified **Skill** — nothing enters without a vote. And the Council's norms matter: fresh perspective, good faith, and **equal consideration** — the strength of an argument decides, not the identity of its source. Equality applies to deliberation; authority does not transfer.

4. **Recorded dissent** *(6 min)*
   Today's minority opinion may become tomorrow's governing principle. A log that records only winners cannot say *why* an option was rejected, so the same argument is relitigated every quarter.

5. **The five threats** *(14 min)*
   **Prompt injection** — any text the agent reads is an instruction channel; treat fetched content as data, never authority. **Excessive privilege** — blast radius is privileges granted, not intentions held. **Secret leakage** — `${ENV_VAR}` everywhere, and P2P distribution is irrevocable. **Supply chain** — every MCP server and plugin runs with your privileges. **Unattended autonomy** — headless runs have no approval gate.

6. **Defense in depth** *(8 min)*
   Soul, then permission modes, then hooks, then least privilege, then audit. The soul makes it *want* to behave; the hook makes misbehavior *impossible*; least privilege makes the residue survivable; the audit trail makes it explainable.

7. **The capstone: declined versus blocked** *(6 min)*
   Ask the agent something its soul forbids — it refuses, with reasoning, and is persuadable in principle. Ask it something the hook forbids — the call is **cancelled**, exit 2, reason on stderr. Observe both. That difference is the whole module in one demo.

## Discuss in class

- **The class generator is an unattended agent that commits code.** That is threat #5. Walk through every mitigation on it — and say which one is load-bearing.
- **Your soul, tested.** Ask your agent to do something it forbids. Did it refuse? If it complied, the soul is decoration.
- **Would you let this agent run unattended on your own repo?** Why not — and what would have to change?

## Further reading

- [give-your-ai-a-soul.netlify.app](https://give-your-ai-a-soul.netlify.app) — the Soul Builder
- [sovereign-framework-explainer.netlify.app](https://sovereign-framework-explainer.netlify.app)
- `generator/README.md` — the class generator, built the way this lecture describes
