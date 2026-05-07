---
marp: true
theme: default
class: invert
paginate: true
size: 16:9
style: |
  section { font-size: 28px; }
  h1 { font-size: 56px; color: #fcd34d; }
  h2 { font-size: 42px; color: #60a5fa; }
  code { background: #1f2937; padding: 2px 6px; border-radius: 4px; }
---

# Week 5 — SQL · Document Stores · DB Versioning
## GoF Behavioral Patterns

---

# What you'll know after this

1. Three-table **JOIN** with right index hints
2. **Postgres JSONB vs. MongoDB** — pick the right tool
3. **DB-as-VCS** — what Liquibase/Flyway gives you
4. **8+ Behavioral patterns** — and the one driving your most complex code path

---

# SQL — the 20% you'll write 80% of the time

```sql
SELECT u.name, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > '2026-01-01'
GROUP BY u.id, u.name
HAVING COUNT(o.id) > 5
ORDER BY order_count DESC
LIMIT 50;
```

- **Indexes** — when they help, when they hurt
- **EXPLAIN** — read it, don't trust the optimizer
- **CTE vs. JOIN** — readability vs. plan

---

# Document stores — JSONB vs. Mongo

**When the schema IS the data** (per-tenant variation):

| | Postgres + JSONB | MongoDB |
|---|---|---|
| ACID | yes | document-level |
| Relational JOINs | yes | aggregation pipeline |
| Horizontal scale | hard | first-class |
| Query language | SQL + JSONB ops | rich nested |

**Don't pick "NoSQL" because it's hip.**

---

# DB-as-VCS — schema migrations done right

- **Liquibase** — XML/YAML, multi-DB
- **Flyway** — SQL-first, simple
- **Prisma Migrate** — TS-first, generates client

**Forward-only vs. reversible.**

> Ad-hoc SQL deploys are how weekends get ruined.

Perfect Framework's *Database* concern says this is **non-negotiable.**

---

# Strategy

You met it in Sprint 1. **Most-used GoF pattern in modern code.**

Any "swap algorithm at runtime" is Strategy.

Your `LlmBackend`? Strategy.<br>
Your sort comparator? Strategy.<br>
Your auth provider abstraction? Strategy.

---

# Observer

> One-to-many notification.

- Every event-emitter
- Every reactive framework's reactivity
- Every MQTT subscriber

The **Channel-flavored Observer** = EIP **Publish-Subscribe Channel**.<br>
Same pattern, different scale.

---

# Command

> Encapsulate a request as an object.

Foundation for:
- **Undo / redo**
- **Queueing**
- **Audit logs**

Sprint 2's **Command Messages** (EIP) are this pattern at the wire level.

---

# State, Template, Iterator, Mediator, Memento

- **State** — behavior changes when state changes (state charts!)
- **Template Method** — skeleton in base class, steps in subclass
- **Iterator** — sequential access (every modern language has it)
- **Mediator** — central object coordinates loose-coupled peers (Redux, Vuex)
- **Memento** — capture/restore state (undo)

---

# Visitor, Chain of Responsibility, Interpreter

- **Visitor** — operation across a tree (compiler passes)
- **Chain of Responsibility** — pass-along chain (**middleware!**)
- **Interpreter** — grammar + interpreter (when you build a DSL)

---

# Sprint 1 demo logistics

**Mon Jun 1**

- 12 min live + 3 min Q&A per team
- **Bring real input data**
- Graded on actually-working-end-to-end, not slideware

---

# Discuss in class

1. **JSONB vs. Mongo for Sprint 2** — pick your messaging-system datastore. One tech reason + one ops reason.
2. **Find a Strategy** in your code. Show one. If you can't, you may not have a swappable backend yet.
3. **Schema migration discipline** — your team's policy when someone needs to rename a column?

---

# What's next

**Week 6** — Sprint 2 starts · Enterprise Integration Patterns Part 1

**W6 quiz** drops alongside lecture (5 Q · 1 attempt · paired remediation)

**Sprint 1** demos Mon Jun 1 · **Sprint 2** kickoff Wed Jun 3
