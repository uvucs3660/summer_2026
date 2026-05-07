# Document Stores Cheat Sheet (80/20)

When the schema *is* the data — different per-tenant, per-record, or per-version — relational tables get awkward. Document stores hold JSON-shaped records natively. The 20% you need: when to choose document, **Postgres JSONB vs. MongoDB**, and the patterns for indexing, validation, and migration that keep document data manageable.

Sprint 2's audit-trail requirement and Sprint 3 capstones with multi-tenant data are the natural use cases.

## When document beats relational

| Use document when... | Use relational when... |
|---|---|
| Schema varies per record (config, custom forms) | Schema is uniform across all records |
| Reads are mostly "give me this whole thing" | Reads are mostly "join across many things" |
| You'd otherwise have 30+ optional columns | You have well-bounded, stable fields |
| Multi-tenant SaaS where each tenant defines fields | Single-tenant or shared-tenant fixed schema |
| You need to evolve schema fast without migrations | Strict referential integrity is critical |

**Hybrid is normal**: most production systems use relational for core entities (users, orders) and document for variable data (settings, custom forms, audit logs).

## Postgres JSONB

Postgres has had JSON columns since 9.2 (2012). `JSONB` (binary, indexed) since 9.4. In 2026 it's the default answer for "I need document storage" unless you have specific scale or query requirements that demand MongoDB.

### Storing & querying

```sql
CREATE TABLE drafts (
  id        SERIAL PRIMARY KEY,
  user_id   INTEGER NOT NULL REFERENCES users(id),
  data      JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO drafts (user_id, data) VALUES
  (42, '{"title": "Resume", "sections": ["summary", "experience"], "version": 3}');

-- Path queries:
SELECT data->>'title' FROM drafts WHERE user_id = 42;
SELECT * FROM drafts WHERE data->>'title' = 'Resume';
SELECT * FROM drafts WHERE data @> '{"version": 3}';     -- contains
SELECT * FROM drafts WHERE data ? 'sections';            -- has key
SELECT * FROM drafts WHERE data #>> '{sections,0}' = 'summary';  -- nested path
```

The operators:
- `->` returns JSON (preserves type).
- `->>` returns text.
- `@>` "contains" — left side contains right side as a sub-document.
- `?` "has key."
- `#>` / `#>>` for deep paths.

### Indexing JSONB

Path indexes for fast lookups:

```sql
-- Index a specific path:
CREATE INDEX drafts_title_idx ON drafts ((data->>'title'));

-- GIN index for general @> containment queries:
CREATE INDEX drafts_data_gin ON drafts USING GIN (data);

-- jsonb_path_ops — smaller, faster for @> only:
CREATE INDEX drafts_data_gin_path ON drafts USING GIN (data jsonb_path_ops);
```

GIN indexes are big (~30-50% of data size) but make `@>`, `?`, `?&`, `?|` queries fast.

### Validation

JSONB doesn't enforce structure. Add CHECK constraints or use a library that validates against JSON Schema before insert:

```sql
ALTER TABLE drafts ADD CONSTRAINT drafts_has_title
  CHECK ((data->>'title') IS NOT NULL);
```

For richer validation, use [jsonschema](https://json-schema.org/) at the application layer, OR Postgres extensions like `pg_jsonschema`.

### When JSONB shines

- ACID alongside relational columns. Update a JSONB doc and a related row in the same transaction.
- Joins between document and relational data.
- One database to operate, monitor, back up.
- Free with Postgres; you probably already have it.

### When JSONB falls short

- Horizontal scaling beyond what one Postgres instance handles (10s of TB).
- Complex aggregations across millions of documents (Postgres can do it, but Mongo's query engine is more idiomatic).
- Genuinely schemaless multi-tenant where there are *no* shared columns.

## MongoDB

The dedicated document store. BSON (binary JSON), document-native query language, horizontal scaling via sharding.

### Storing & querying

```javascript
import { MongoClient } from 'mongodb';

const client = new MongoClient(process.env.MONGO_URL);
await client.connect();
const db = client.db('jobpack');
const drafts = db.collection('drafts');

// Insert:
await drafts.insertOne({
  userId: 42,
  title: 'Resume',
  sections: ['summary', 'experience'],
  version: 3,
  createdAt: new Date(),
});

// Query:
const all = await drafts.find({ userId: 42 }).toArray();
const titled = await drafts.find({ title: 'Resume' }).toArray();
const versions = await drafts.find({ version: { $gte: 3 } }).toArray();

// Nested:
const withSummary = await drafts.find({ sections: 'summary' }).toArray();

// Updates:
await drafts.updateOne({ _id: id }, { $set: { version: 4 } });
await drafts.updateOne({ _id: id }, { $push: { sections: 'skills' } });

// Aggregation pipeline:
const counts = await drafts.aggregate([
  { $match: { userId: 42 } },
  { $group: { _id: '$version', count: { $sum: 1 } } },
]).toArray();
```

### Indexing

```javascript
await drafts.createIndex({ userId: 1 });
await drafts.createIndex({ userId: 1, createdAt: -1 });  // compound
await drafts.createIndex({ title: 'text' });             // full-text
await drafts.createIndex({ data: 'hashed' });            // for sharding
```

Indexes work much like SQL: build them; query plans use them; expensive on writes if you have too many.

### When MongoDB shines

- Horizontal scaling via sharding is built in.
- Document is the *primary* data model; you rarely need relational alongside.
- The MongoDB query language is your team's mental model.
- Atlas-style managed offerings make ops easy.

### When MongoDB falls short

- ACID across multiple collections requires multi-document transactions (added in 4.0; less ergonomic than Postgres).
- Joins (`$lookup`) are doable but feel awkward; if you join often, you didn't want a document store.
- Two databases to operate (probably still need a relational somewhere).

## The decision

For most Sprint 2 / Sprint 3 capstones: **Postgres JSONB.**

You probably already have Postgres for users/auth/etc. JSONB columns for variable data avoid a second operational footprint, allow ACID across both worlds, and Postgres's query engine is excellent.

**Pick MongoDB when**:
- The whole app's primary data is documents (event log, IoT telemetry, analytics).
- You'll genuinely shard horizontally (10+ TB, 100+ thousand QPS).
- The team is more productive in MongoDB's query model.

## Schema migration for documents

Even document stores have schemas (just implicit). Versioning patterns:

### Version field per document

```javascript
{ schemaVersion: 1, title: '...', sections: [...] }
```

When the loader reads a document, it checks `schemaVersion` and runs lazy migrations:

```javascript
function migrate(doc) {
  if (!doc.schemaVersion) doc.schemaVersion = 1;
  if (doc.schemaVersion < 2) {
    doc.tags = doc.tags ?? [];
    doc.schemaVersion = 2;
  }
  if (doc.schemaVersion < 3) {
    doc.publishedAt = doc.publishedAt ?? null;
    doc.schemaVersion = 3;
  }
  return doc;
}
```

Cheap to add migrations; expensive to read old data over and over. Periodically batch-rewrite to current version.

### Bulk migration scripts

For schema changes that should be applied to all documents at once:

```sql
-- Postgres JSONB:
UPDATE drafts SET data = data || '{"language": "en"}'::jsonb WHERE NOT data ? 'language';
```

```javascript
// MongoDB:
await drafts.updateMany({ language: { $exists: false } }, { $set: { language: 'en' } });
```

## What this is in vernacular

- Document stores instantiate the Perfect Framework's *Database > Document Database* sub-concern.
- Lazy migration with `schemaVersion` ≈ **Format Indicator** (EIP) applied to storage.
- JSONB ≈ Postgres's "I want both" answer to the relational-vs-document tension.
- Multi-tenant variable schemas ≈ the **Strategy** (GoF) pattern at the data shape level.

## Further reading

- **Postgres JSON Functions and Operators** docs.
- **MongoDB documentation** (mongodb.com/docs).
- **`cheatsheet-sql`** — relational SQL fundamentals (you'll use both alongside).
- **`cheatsheet-db-versioning`** — schema migration tooling.
- **The "Use the Index, Luke!" site** for Postgres index reasoning that applies to JSONB too.
