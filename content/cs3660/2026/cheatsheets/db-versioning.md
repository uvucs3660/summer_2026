# Database Versioning Cheat Sheet (80/20)

Why DB-as-VCS matters: schemas change every time the application changes, and ad-hoc SQL deploys ruin your weekend (and your data). The Perfect Framework's *Database* concern says this is non-negotiable. The 20% you need: how to use a migration tool (Liquibase / Flyway / Prisma Migrate / Alembic) to make schema changes versioned, reversible, and automated.

## What "versioned database" means

A migration tool makes the database behave like code:

- **Reproducible** — anyone can run `migrate up` and get the same schema.
- **Versioned** — every change is a numbered file in source control.
- **Automated** — running app boots → tool checks current version → applies missing migrations.
- **Reversible** (sometimes) — `migrate down` rolls back.

```
v1 → v2 → v3 → v4 → v5
                    ↑ current
[migration files in version control]
```

The `db_changelog` (or `schema_migrations`) table records which migrations have been applied. The tool diffs against the migration files; applies missing ones.

## The four common tools

| Tool | Lang/ecosystem | Flavor | When to pick |
|---|---|---|---|
| **Liquibase** | JVM, but works anywhere | XML/YAML/JSON/SQL changesets | Polyglot teams; rich preconditions |
| **Flyway** | JVM, but standalone | Versioned SQL files | Pure SQL preference; simpler than Liquibase |
| **Prisma Migrate** | Node.js | Schema-driven; generates SQL | Already on Prisma ORM |
| **Alembic** | Python | Schema-driven | Python apps with SQLAlchemy |

For Sprint 2 / Sprint 3 with a Node + Postgres stack: **Prisma Migrate** is the path of least resistance. With raw SQL and many engines: **Flyway**.

## Forward-only vs. reversible

Two philosophies:

### Forward-only

Every migration goes forward. To "undo," you write a NEW migration that reverses the change. Production-grade systems mostly do this — `down` migrations are buggy in practice and rarely tested.

```
v1: create users table
v2: add 'email' column to users
v3: backfill 'email' from 'username + @example.com'
v4: make 'email' NOT NULL
v5: oh no, undo v4? → write v6: make 'email' NULLABLE again
```

### Reversible

Each migration has `up` and `down` halves. Easy to test locally; tricky in production (data loss on `down`).

The right answer for most teams: **forward-only in production, reversible during development for fast iteration**.

## Migration patterns — the key ones

### The expand/contract pattern (zero-downtime schema change)

For changes that would otherwise require downtime: rename a column, change a column type, split a table.

**Naive rename** (causes downtime):
```sql
ALTER TABLE users RENAME COLUMN username TO handle;
```
Existing app code breaks until redeploy.

**Expand/contract** (zero downtime):
1. **Expand**: add the new column alongside the old.
   ```sql
   ALTER TABLE users ADD COLUMN handle TEXT;
   ```
2. **Backfill**: populate the new column.
   ```sql
   UPDATE users SET handle = username;
   ```
3. **Dual-write**: app writes to both columns.
4. **Migrate reads**: app reads from new column, falls back to old.
5. **Cut over**: stop writing to old column.
6. **Contract**: drop the old column (in a later release).
   ```sql
   ALTER TABLE users DROP COLUMN username;
   ```

Each step is its own migration. App code coordinates with the schema state.

### Adding NOT NULL columns to existing tables

```sql
-- Don't do this on a 50M-row table:
ALTER TABLE invoices ADD COLUMN status TEXT NOT NULL DEFAULT 'pending';
-- ^ Locks the table for the duration of the rewrite. Bad.

-- Do this instead:
-- Migration A: add nullable column with default.
ALTER TABLE invoices ADD COLUMN status TEXT;

-- Migration B (gradual, possibly in batches): backfill in production.
UPDATE invoices SET status = 'pending' WHERE status IS NULL AND id BETWEEN 1 AND 100000;
-- ... batched backfill ...

-- Migration C: enforce NOT NULL.
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
```

The pattern matters more than the tool — every tool can do this; doing it CORRECTLY requires understanding what locks each operation takes.

### Renaming and type changes

Same expand/contract approach. Never rename in place on a live table; always add new + backfill + drop old.

### Dropping a column

Two-stage: stop using it (release N), drop it (release N+1). Don't drop while old code might still write to it.

## Tool examples

### Liquibase changeset (XML)

```xml
<changeSet id="20260506-add-email-to-users" author="instructor">
  <addColumn tableName="users">
    <column name="email" type="text"/>
  </addColumn>
</changeSet>
```

### Flyway (versioned SQL)

```
db/migration/V1__create_users.sql
db/migration/V2__add_email_to_users.sql
db/migration/V3__backfill_email.sql
```

```sql
-- V2__add_email_to_users.sql
ALTER TABLE users ADD COLUMN email TEXT;
```

### Prisma Migrate

Edit `schema.prisma`:

```prisma
model User {
  id    Int    @id @default(autoincrement())
  email String? // (added)
  name  String
}
```

Run:
```bash
npx prisma migrate dev --name add_email_to_users
```

Prisma generates the SQL and stores it under `prisma/migrations/`. In production: `npx prisma migrate deploy`.

### Alembic

```bash
alembic revision -m "add email to users" --autogenerate
# edit the generated file if needed
alembic upgrade head
```

## Boot-time integration

The standard pattern: the app's startup script runs `migrate` before serving traffic.

```bash
#!/bin/bash
# Boot script for deployment
prisma migrate deploy   # apply any new migrations
node dist/server.js     # then start the app
```

In Kubernetes: an `initContainer` runs migrations before the main pod starts.

**Anti-pattern**: migrations run from one developer's laptop manually. Forget once → broken environment.

## Production checklist

Before running a migration in production:

1. **Test it on a copy of production data.** Schema changes that work on dev's 100-row table can lock prod's 100M-row table for hours.
2. **Run in a transaction if possible.** Postgres supports DDL in transactions (mostly); some statements like `CREATE INDEX CONCURRENTLY` cannot.
3. **Watch lock contention.** `pg_locks`, `pg_stat_activity` during the migration.
4. **Have a rollback plan.** Even if forward-only, know what NEW migration would reverse this.
5. **Coordinate with deploy.** Migration usually goes BEFORE app code that depends on it; for column drops, AFTER app code stops using them.

## What this is in vernacular

- DB-as-VCS = the Perfect Framework's *Database > DB VCS* sub-concern.
- Migrations = **Command** (GoF) at the schema level — each migration is a Command applied to the DB.
- The expand/contract pattern ≈ the EIP **Format Indicator** + **Message Translator** combination — different "schema versions" coexist for a transition window.

## Common failure modes

- **Edited an applied migration** instead of writing a new one. The tool now thinks reality differs from the changelog. Manual surgery in the changelog table required.
- **Renamed a column in place** on a live table. Old app instances throw errors until they redeploy.
- **Migration includes a long `UPDATE`** that locks the table during a deploy. Outage.
- **No CI test for migrations.** First time the migration runs is in production.
- **Two engineers write different `v5__` migrations** in parallel branches. Tool refuses to merge them. Use timestamp-based filenames if your team's parallelism is high.

## Further reading

- **Liquibase docs** (liquibase.com), **Flyway docs** (flywaydb.org).
- **Prisma Migrate docs** (prisma.io/docs/orm/prisma-migrate).
- **Alembic docs** (alembic.sqlalchemy.org).
- **Strong Migrations** (Ruby gem, but the pattern catalog is universal): forbids dangerous operations in migrations until you opt in.
- **`cheatsheet-sql`** — the SQL fundamentals migrations are made of.
- **`cheatsheet-document-stores`** — schema versioning at the document layer (different problem, similar shape).
