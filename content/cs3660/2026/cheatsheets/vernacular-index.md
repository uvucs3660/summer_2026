# Vernacular Index Cheat Sheet (80/20)

The complete vocabulary list for CS 3660, organized by source domain. **You are accountable for every term here.** Reflections, sprint presentations, CC artifact READMEs, and live discussion all expect precise usage. The LLM grader rewards specificity (the *named* pattern) and penalizes the generic ("we used a pattern").

This is a **scan-and-look-up** sheet. Read it once to know what's in it; then return to it whenever you reach for a term.

## How to use this in CS 3660

| Where | What to do |
|---|---|
| **Weekly reflection** | Pick one term from this week's lecture. Use it correctly in context. Apply it to current sprint work. |
| **Sprint presentation** | Name patterns/EIPs/concerns explicitly. The rubric counts them. |
| **CC artifact README** | Use Claude Code vocabulary precisely (a "skill" is not a "hook" is not a "subagent"). |
| **Stuck on a term** | Open the cheat sheet for the source domain (`cheatsheet-agile-v2`, `cheatsheet-perfect-framework`, etc.). |
| **Worried you're misusing a term** | Ask Claude Code to define it from this index, then check yourself. |

## The five domains

1. **Agile Manifesto v2.0** (Hunter, 2024) — 4 values + 12 principles. *How the team operates.*
2. **GoF Design Patterns** — 23 named code-level patterns in 3 families. *How code is shaped.*
3. **Enterprise Integration Patterns (EIPs)** — ~65 messaging patterns in 5 categories. *How systems talk.*
4. **The Perfect Framework** (Hunter, 2024) — 7 architectural concerns. *What the framework does for you.*
5. **Claude Code Capabilities** — agentic loop + extension types. *How you leverage AI.*

When you cite a term, name **the domain** + **the term**. "Strategy pattern (GoF, Behavioral)" beats "Strategy." "Service Activator (EIP, Endpoint)" beats "Service Activator." Domain naming is what makes the vocabulary scaffold useful.

---

## Domain 1 — Agile Manifesto v2.0

Full sheet: `cheatsheet-agile-v2`. Source: [The Agile Manifesto v2.0 — Michael Hunter](https://www.linkedin.com/pulse/agile-manifesto-v20-michael-hunter/).

### v2 values (the lens — added by Hunter)

- **Collaboration and Idea Exchange**
- **Working Software**
- **Fun**
- **Resilience**

### v1 value-pairs (retained — left preferred over right; right has merit)

- Individuals and interactions / Processes and tools
- Working software / Comprehensive documentation
- Customer collaboration / Contract negotiation
- Responding to change / Following a plan

### 12 principles in 3 categories

- **Software (3)** — A1 Customer satisfaction · A2 Frequent working software · A3 Self-organizing teams
- **Team (4)** — B1 Motivated individuals · B2 Face-to-face conversation · B3 Daily collaboration · B4 Regular reflection
- **Agility (5)** — C1 Welcome change · C2 Simplicity · C3 Technical excellence · C4 Sustainable pace · C5 Constant velocity

---

## Domain 2 — GoF Design Patterns

Full reference: [refactoring.guru/design-patterns/catalog](https://refactoring.guru/design-patterns/catalog). 23 patterns in 3 families.

### Creational (5) — *how objects come into being*

- **Factory Method** — defer instantiation to subclasses.
- **Abstract Factory** — families of related objects without specifying their classes.
- **Builder** — construct complex objects step by step.
- **Prototype** — clone instead of construct.
- **Singleton** — exactly one instance, globally accessible.

### Structural (7) — *how objects compose*

- **Adapter** — incompatible interfaces work together.
- **Bridge** — decouple abstraction from implementation.
- **Composite** — uniform tree of leaves and branches.
- **Decorator** — add responsibilities dynamically.
- **Facade** — simpler interface to a complex subsystem.
- **Flyweight** — share common parts of many similar objects.
- **Proxy** — placeholder for another object.

### Behavioral (11) — *how objects communicate*

- **Chain of Responsibility** — pass a request along a chain.
- **Command** — encapsulate a request as an object.
- **Iterator** — sequential access without exposing the underlying.
- **Mediator** — central object coordinates loose-coupled peers.
- **Memento** — capture and restore an object's internal state.
- **Observer** — one-to-many notification.
- **State** — alter behavior when internal state changes.
- **Strategy** — encapsulate a family of algorithms; swap at runtime.
- **Template Method** — skeleton with steps subclasses override.
- **Visitor** — operation across an object structure.
- **Interpreter** — grammar + interpreter for a language.

---

## Domain 3 — Enterprise Integration Patterns (EIPs)

Full reference: [enterpriseintegrationpatterns.com/patterns/messaging/](https://www.enterpriseintegrationpatterns.com/patterns/messaging/). ~65 patterns in 5 categories.

### Channels (~9)

- **Point-to-Point Channel** — one sender, one receiver.
- **Publish-Subscribe Channel** — one sender, many receivers.
- **Datatype Channel** — channel carries one message type.
- **Invalid Message Channel** — bad messages go here, not to subscribers.
- **Dead Letter Channel** — undeliverable messages go here.
- **Guaranteed Delivery** — message persists until delivered.
- **Channel Adapter** — connect a system to a channel.
- **Messaging Bridge** — connect two messaging systems.
- **Message Bus** — shared infrastructure for many connected systems.

### Message construction (~9)

- **Command Message** — invoke an action remotely.
- **Document Message** — transfer data between systems.
- **Event Message** — announce something happened.
- **Request-Reply** — bidirectional pattern.
- **Return Address** — where the reply goes.
- **Correlation Identifier** — match reply to request.
- **Message Sequence** — ordered set spanning multiple messages.
- **Message Expiration** — message goes stale at time T.
- **Format Indicator** — message describes its own schema version.

### Routing (~14)

- **Pipes-and-Filters** — compose processing steps.
- **Message Router** — direct messages by criteria.
- **Content-Based Router** — route by message content.
- **Message Filter** — drop unwanted messages.
- **Dynamic Router** — recipient self-registers.
- **Recipient List** — fan out to a computed set.
- **Splitter** — break one message into many.
- **Aggregator** — combine many into one.
- **Resequencer** — reorder out-of-order messages.
- **Composed Message Processor** — split, process pieces, recombine.
- **Scatter-Gather** — broadcast and aggregate replies.
- **Routing Slip** — message carries its own route.
- **Process Manager** — central routing logic.
- **Message Broker** — decouple senders from receivers via a hub.

### Transformation (~7)

- **Message Translator** — change message format.
- **Envelope Wrapper** — add metadata around the payload.
- **Content Enricher** — add fields the receiver needs.
- **Content Filter** — strip fields the receiver doesn't need.
- **Claim Check** — store payload externally; pass a reference.
- **Normalizer** — many input formats → one canonical.
- **Canonical Data Model** — shared schema across systems.

### Endpoint (~12)

- **Message Endpoint** — application's connection to messaging.
- **Messaging Gateway** — abstract messaging from the app.
- **Messaging Mapper** — move data between domain and messages.
- **Transactional Client** — coordinate with a transaction.
- **Polling Consumer** — pull messages on a schedule.
- **Event-Driven Consumer** — pushed messages.
- **Competing Consumers** — multiple consumers share a queue.
- **Message Dispatcher** — one receiver, many handlers.
- **Selective Consumer** — receiver picks what to consume.
- **Durable Subscriber** — receives even when offline.
- **Idempotent Receiver** — safe to receive the same message twice.
- **Service Activator** — bridge messaging to a service interface.

---

## Domain 4 — The Perfect Framework

Full sheet: `cheatsheet-perfect-framework`. 7 concerns; this index lists the sub-concerns you can name explicitly.

### 1. Scale

- horizontal scaling · vertical scaling · stateless workers · stateful infrastructure

### 2. Database

- audit trail · point-in-time · archive table · streaming database · DB-as-VCS · migration · auto-increment · enforced foreign key · ACID · document store · Postgres JSONB

### 3. Enterprise Messaging

- push not poll · MQTT · RabbitMQ · ActiveMQ

### 4. Security

- single sign-on · authorization · authentication · data permission · row-level security · RBAC (role-based access control) · menu-level control · form-level control · field-level control

### 5. Application

- platform support (Android · iOS · desktop · web) · model-driven architecture · field positioning · form design · field-level validation · user preferences · system preferences · online · offline · localization · internationalization · accessibility · WCAG · screen reader · in-app help · analytics · units of measure

### 6. Workflow

- state chart · state · event · transition · guard · action · hierarchical state · parallel state · commitment lifecycle · propose · agree · perform · accept · compensate · counter-proposal

### 7. Ops / Documentation / Feedback

- multi-environment · staging · production · versioned build artifact · one-button build · code documentation · user documentation · in-product feedback

---

## Domain 5 — Claude Code Capabilities

Full reference: `docs/reference/claude-code-capabilities.md` and Anthropic's docs. The vocabulary CC artifacts (Track 3) are graded against.

### Agentic loop

- **Agentic loop** — context gathering · action · verification (the cycle Claude runs through every turn).
- **Context gathering** — searching files, reading terminal output, querying tools.
- **Action** — editing files, running commands.
- **Verification** — running tests, reading linter output.

### Models and tools

- **Model** — Opus, Sonnet, Haiku (the brains that reason and plan).
- **Tools** — file ops, bash, git, MCP-provided tools (the capabilities Claude has).

### Context management

- **CLAUDE.md** — project-specific instructions, always loaded.
- **MEMORY.md** — auto-saved learnings across sessions.
- **/compact** — summarize conversation, free up context.

### Command interface

- **Slash command** — built-in or custom command (`/clear`, `/help`).
- **Skill** — reusable prompt-based workflow with `SKILL.md`.
- **Keyboard shortcut** — IDE-level rapid action.

### Extension features

- **MCP (Model Context Protocol)** — connects Claude to external services.
- **MCP server** — exposes tools, resources, prompts.
- **Tool / resource / prompt** — three things an MCP server can expose.
- **Subagent** — isolated execution context Claude can spawn.
- **Hook** — automated script triggered on event (PreToolUse, PostToolUse, Stop, SubagentStop, SessionStart, SessionEnd, UserPromptSubmit, PreCompact, Notification).
- **Plugin** — distributable bundle of skills, agents, hooks, MCP configs.
- **LSP (Language Server Protocol)** — semantic code intelligence.

### Permission and safety

- **Normal mode** — ask permission per file edit / command.
- **Auto-accept mode** — approve common edits automatically.
- **Plan mode** — read-only; propose changes for review.

---

## Common confusions (don't say X when you mean Y)

| Don't say | Say instead | Why |
|---|---|---|
| "tool" (when describing your CC extension) | skill / hook / subagent / MCP server / plugin | "Tool" is what an MCP server exposes; the wrapping artifact has a more specific name. |
| "agent" (for a CC subagent) | subagent | The Claude Code term is *subagent*; "agent" is ambiguous. |
| "hook" (without the event) | "PreToolUse hook" / "Stop hook" / etc. | Always name the specific event. |
| "pattern" (without naming it) | "Strategy pattern" / "Adapter pattern" / etc. | Generic "pattern" is what novices say. |
| "messaging" (without the EIP) | "Publish-Subscribe channel" / "Content-Based Router" / etc. | EIPs have names. Use them. |
| "framework concern" (without naming it) | "Perfect Framework: Audit trails" / "Perfect Framework: i18n" / etc. | Specificity is the whole point. |
| "agile" (the buzzword) | "Agile v2 / Team / B2 face-to-face" / etc. | Cite the category and principle. |

---

## Cross-reference: where each domain shows up in CS 3660

| Week | Lecture topic | Domains in play |
|---|---|---|
| 1 | Course intro · Agile v2 · Perfect Framework · vernacular | Agile v2 · Perfect Framework |
| 2 | HTML/CSS/JS · Job Pack kickoff · LLM endpoint | Perfect Framework (Security 4, Scale 1) · Claude Code (skills) |
| 3 | Frameworks · GoF Creational | GoF Creational |
| 4 | Node · REST · auth · GoF Structural | GoF Structural · Perfect Framework (Security 4) |
| 5 | SQL · document stores · DB versioning · GoF Behavioral | GoF Behavioral · Perfect Framework (Database 2) |
| 6 | EIPs Part 1 — channels, message construction | EIPs Channel + Construction |
| 7 | EIPs Part 2 — routing, transformation · state charts | EIPs Routing + Transformation · Perfect Framework (Workflow 6) |
| 8 | Realtime web — MQTT, WebSockets, GraphQL subs | Perfect Framework (Messaging 3) · EIPs Channels |
| 9 | PRPL · service workers · offline | Perfect Framework (Application 5: offline) |
| 10 | Perfect Framework deep-dive | Perfect Framework (5: i18n, a11y, RBAC) |
| 11 | Advanced web platform | Perfect Framework (Application 5: platform support) |
| 12 | PKI · OWASP · security | Perfect Framework (Security 4) |
| 13 | CI/CD · observability · production-readiness | Perfect Framework (Ops 7) |

By Week 13, you should be using vocabulary from all 5 domains in the same sentence without effort. That's the goal.

---

## When in doubt

- **Forgot what something means?** Open the source-domain cheat sheet (`cheatsheet-agile-v2`, `cheatsheet-perfect-framework`, etc.) or ask Claude Code: "Define {term} in the context of {domain}."
- **Pretty sure but not 100%?** Use it anyway, then ask the LLM grader's reflection feedback to confirm. Better to use a term and learn from the correction than to avoid all jargon and never grow.
- **Convinced you don't need this vocabulary?** This course is built on the premise that you do. Disagree? Talk to the instructor — but the rubric is non-negotiable.
