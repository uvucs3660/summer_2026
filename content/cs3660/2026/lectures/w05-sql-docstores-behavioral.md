---
slug: lecture-w05-sql-docstores-behavioral
week: 5
youtube_id: null
companion_sheets:
  - cheatsheet-sql
  - cheatsheet-document-stores
  - cheatsheet-db-versioning
  - cheatsheet-gof-behavioral
reflection_assignment: reflection-w05
vernacular_tags:
  - "GoF: Strategy"
  - "GoF: Observer"
  - "GoF: Command"
  - "GoF: State"
  - "Perfect Framework: Database"
  - "Perfect Framework: Audit Trails"
---

# Week 5 — SQL · Document Stores · DB Versioning · GoF Behavioral Patterns

## What you'll know after this

You'll be able to (a) write a join across three tables with the right index hints; (b) decide between Postgres JSONB and MongoDB for a given workload; (c) name what DB-as-VCS gives you and how Liquibase/Flyway manages it; (d) name 8+ GoF Behavioral patterns and identify the one driving your team's most complex code path.

## Outline

1. **SQL — the 20% you'll write 80% of the time** *(12 min)*
   SELECT/JOIN/INSERT/UPDATE/DELETE. Indexes (when they help, when they hurt). Query plans (read EXPLAIN, don't just trust the optimizer). Three kinds of subqueries. When to use a CTE vs. a JOIN.

2. **Document stores — Postgres JSONB vs. MongoDB** *(8 min)*
   When the schema IS the data (per-tenant or per-record variation). JSONB inside Postgres gives you ACID + relational + document; MongoDB gives you horizontal scale + a richer query language for nested docs. Don't pick "NoSQL" because it's hip.

3. **DB-as-VCS — schema migrations done right** *(8 min)*
   Migration tools (Liquibase, Flyway, Prisma Migrate). Why ad-hoc SQL deploys ruin your weekend. The two migration patterns (forward-only vs. reversible). The Perfect Framework's *Database* concern says this is non-negotiable.

4. **Behavioral pattern — Strategy** *(4 min)*
   You met Strategy in Sprint 1. It's the most-used GoF pattern in modern code: any "swap algorithm at runtime" is a Strategy. Your `LlmBackend` is a Strategy.

5. **Observer** *(4 min)*
   One-to-many notification. Every event-emitter, every reactive framework's reactivity, every MQTT subscriber is Observer. (Note: the *Channel*-flavored Observer is also EIP Publish-Subscribe — same pattern, different scale.)

6. **Command** *(4 min)*
   Encapsulate a request as an object. Foundation for undo/redo, queueing, audit logs. Sprint 2's messaging-rich systems will use Command Messages (EIP) which are this pattern at the wire level.

7. **State, Template Method, Iterator, Mediator, Memento, Visitor, Chain of Responsibility, Interpreter** *(15 min)*
   Brisk tour. State = behavior changes when state changes (drives state charts). Template Method = skeleton in base class, steps in subclass. Iterator = sequential access (every modern language has it). Mediator = central object coordinates loose-coupled peers (Redux, Vuex). Memento = capture/restore state (undo). Visitor = operation across a tree. Chain of Responsibility = pass-along chain (middleware!). Interpreter = grammar + interpreter (when you build a DSL).

8. **Sprint 1 demo logistics** *(5 min)*
   Mon Jun 1 demos. 12 min live + 3 min Q&A per team. Bring real input data; your demo will be graded on actually-working-end-to-end, not slideware.

## Discuss in class

- **JSONB vs. Mongo for Sprint 2.** Pick the right datastore for the messaging-rich system you're proposing. One technical reason and one operational reason.
- **Find a Strategy in your code.** Open the repo. Show one Strategy. If you find none, you might not actually have a swappable backend yet.
- **Schema migration discipline.** What's your team's policy when someone needs to rename a column? Walk through the steps a Liquibase changelog would generate.

## Further reading

- **`cheatsheet-sql`** — SELECT/JOIN/etc. plus query-plan reading.
- **`cheatsheet-document-stores`** — JSONB vs. Mongo decision tree.
- **`cheatsheet-db-versioning`** — migration tool comparison.
- **`cheatsheet-gof-behavioral`** — all 11 Behavioral patterns.
- **Use the Index, Luke!** — `use-the-index-luke.com` — best free SQL indexing reference.

## What's next

Week 6 starts Sprint 2 with Enterprise Integration Patterns. The W6 quiz (5 questions, 1 attempt, paired remediation) drops alongside the lecture. Sprint 1 demos Mon Jun 1; Sprint 2 kickoff Wed Jun 3.
