# Offline-First & Sync Cheat Sheet (80/20)

The 20% of the offline-first model you'll touch 80% of the time. Building on `cheatsheet-shadow-dom-pwa` (which covers the service worker basics), this sheet goes deeper into the *hard part*: writes while offline, sync on reconnect, and conflict resolution that doesn't lose data.

The Perfect Framework calls offline operation a non-negotiable Application concern. WCAG-AAA-conscious capstones target it. Sprint 3 capstones that bet on offline must read this sheet.

## The three layers

```
[ User action ]
      ↓
[ App data layer (IndexedDB, localStorage, in-memory) ]
      ↓        ↑
   write    on reconnect: sync queue → server
      ↓        ↑
[ Sync queue (Background Sync) ]
      ↓        ↑
[ Server / database ]
```

1. **App data layer** — local source of truth while offline. IndexedDB for structured data, localStorage for tiny key-value, in-memory for ephemeral.
2. **Sync queue** — pending writes; flushes when online.
3. **Server** — durable truth; applies sync, resolves conflicts.

## Cache strategies — quick recap

(See `cheatsheet-shadow-dom-pwa` for the full version. Quick decision matrix:)

| Strategy | Returns | When |
|---|---|---|
| Cache-first | Cached if present, else network | Static assets (CSS, JS, images) |
| Network-first | Network if up, else cache | Dynamic data you want fresh |
| Stale-while-revalidate | Cached now, refresh in background | "Good enough now, perfect soon" |
| Network-only | Always network | Auth, payment endpoints |
| Cache-only | Never network | Pre-cached app shell |

## IndexedDB — the offline store

Native browser DB. Asynchronous, transactional, indexed. The 2026 way to use it: a small library (`idb-keyval` for simple, `dexie` for queries, `rxdb` for reactive).

### Quick patterns

```javascript
import Dexie from 'dexie';

const db = new Dexie('jobpack');
db.version(1).stores({
  drafts: '++id, jobId, status, updatedAt',  // ++id = autoincrement
  pending: '++id, type, payload, createdAt',
});

// Write a draft (fast, offline-capable):
await db.drafts.add({ jobId: 'j-123', status: 'draft', text: '...', updatedAt: Date.now() });

// Read all drafts for a job:
const drafts = await db.drafts.where('jobId').equals('j-123').toArray();
```

### Schema migrations

Bump the version, declare the new schema, optionally migrate data:

```javascript
db.version(2).stores({
  drafts: '++id, jobId, status, updatedAt, language',  // added 'language'
}).upgrade(async (tx) => {
  await tx.table('drafts').toCollection().modify(d => { d.language = 'en'; });
});
```

The Perfect Framework's *Database* concern says you handle schema changes deliberately, even in the browser.

## Background Sync API

The browser fires a `sync` event when connectivity returns. Your service worker handles it.

```javascript
// In your app: register a sync.
const reg = await navigator.serviceWorker.ready;
await reg.sync.register('flush-pending');

// In your service worker: handle the sync.
self.addEventListener('sync', (event) => {
  if (event.tag === 'flush-pending') {
    event.waitUntil(flushPendingWrites());
  }
});

async function flushPendingWrites() {
  const pending = await db.pending.toArray();
  for (const item of pending) {
    try {
      await fetch('/api/sync', { method: 'POST', body: JSON.stringify(item.payload) });
      await db.pending.delete(item.id);
    } catch {
      // leave in queue; sync event will fire again later
    }
  }
}
```

**Important**: `sync` events run in the service worker context, not the page. Page might be closed; sync still happens.

**Browser support gotcha**: Background Sync is Chromium-only as of 2026. Firefox/Safari fall back to "sync when the user opens the app" — design for both.

## Conflict resolution — the hard part

Two users edit the same draft offline. They both reconnect. What happens?

Three policies, in increasing complexity:

### Last-write-wins (LWW)
Whichever timestamp is newer wins; the older write is discarded. Simple; loses data. Right for "this is mostly mine" scenarios (per-user notes, drafts owned by the user).

```javascript
async function applyServerSync(local, server) {
  return local.updatedAt > server.updatedAt ? local : server;
}
```

### Operational Transform (OT)
Each edit is described as an operation; operations are transformed against each other to compose cleanly. Old-school collab editing (Google Docs, etherpad).

Hard to implement correctly; libraries exist (`ot.js`, `ShareDB`). Use the library; don't roll your own.

### CRDTs (Conflict-free Replicated Data Types)
Data structures designed so that any two replicas can merge without conflict. Mathematics ensures convergence. Modern collab editing (Yjs, Automerge).

Adoption pattern: pick a library (`yjs`, `automerge`), wrap your data model in it, let the library handle sync. The library handles "two users typed in the same paragraph offline" gracefully.

### Per-field policies
For mixed data: some fields are LWW, some require manual resolution, some are CRDT-merged.

```javascript
async function merge(local, server) {
  return {
    title: local.updatedAt > server.updatedAt ? local.title : server.title,  // LWW
    tags: [...new Set([...local.tags, ...server.tags])],                    // union
    body: yjsMerge(local.body, server.body),                                // CRDT
    publishedAt: server.publishedAt ?? local.publishedAt,                   // server wins
  };
}
```

The right policy is per-field. No universal "right answer."

## Optimistic UI

Show the result of an action immediately; reconcile when server responds. The pattern that makes apps feel instant.

```javascript
async function addDraft(jobId, text) {
  // Optimistic: render immediately.
  const tempId = 'temp-' + Date.now();
  state.drafts.push({ id: tempId, jobId, text, syncing: true });
  rerender();

  try {
    const draft = await api.createDraft({ jobId, text });
    const idx = state.drafts.findIndex(d => d.id === tempId);
    state.drafts[idx] = draft; // replace with server-issued id
  } catch (e) {
    // Roll back; show error.
    state.drafts = state.drafts.filter(d => d.id !== tempId);
    showToast('Save failed, please retry');
  }
  rerender();
}
```

Three rules:
- **Idempotency on the server** — if the request retries, don't create duplicates. Client sends a `Idempotency-Key` header; server dedupes.
- **Reconciliation on response** — replace optimistic state with server-issued data (real IDs, server-computed fields).
- **Visual cue for "syncing"** — let the user know the state isn't yet durable.

## What this is in vernacular

- Sync queue ≈ **Command** (GoF) at the storage level (each pending op is a Command waiting to execute).
- Background Sync ≈ EIP **Polling Consumer** + **Idempotent Receiver**.
- Optimistic UI ≈ "Apply local first, then reconcile" — same shape as **Memento** + retry on failure.
- The whole pattern = Perfect Framework's *Application > Online + Offline* concern. Sprint 3 capstones targeting it earn substantial rubric points.

## Common failure modes

- **Optimistic UI without reconciliation.** UI says "saved" when the server hasn't ack'd. User loses data on reconnect failure.
- **Sync queue without retry limit.** Bad payload retries forever; queue grows.
- **No conflict policy declared.** Last write silently wins; users discover data loss months later.
- **Indexed DB without migrations.** Schema changes break offline users; "clear site data" support burden.
- **Single-tab assumption.** User has the app open in 3 tabs; each updates IndexedDB independently. Use BroadcastChannel or storage events to keep them in sync.

## Further reading

- **`cheatsheet-shadow-dom-pwa`** — service worker lifecycle + cache strategies.
- **Workbox** (Google) — battle-tested library for caching + Background Sync. Use it.
- **Yjs** / **Automerge** — CRDT libraries for collaborative apps.
- **Dexie.js** — pleasant IndexedDB wrapper.
- **MDN: Background Sync API** — current browser support and API details.
