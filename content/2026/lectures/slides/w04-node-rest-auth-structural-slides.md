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

# Week 4 — Node · REST · Auth
## GoF Structural Patterns

---

# What you'll know after this

1. **Minimal Node + Koa server** — middleware in the right order
2. **Sessions vs. JWT vs. OAuth** — when to use which
3. All **7 Structural patterns** with a real-world example each
4. **Recognize** which Structural pattern your auth middleware is

---

# Node + Koa in 8 minutes

- The event loop · async/await
- The middleware **onion**
- Why Koa > Express: composition, error handling, `ctx`

```ts
app
  .use(loggerMiddleware)      // outer
  .use(corsMiddleware)
  .use(authMiddleware)
  .use(rateLimitMiddleware)
  .use(routes);                // inner
```

Each wraps the next. This is **Decorator at scale**.

---

# REST that ages well

**The four signs of bad REST:**
- Verbs in URLs (`/getUserById`)
- Deeply-nested routes (`/users/12/orders/34/items/5/refund`)
- `200 OK` errors (success status, error body)
- Action-shaped endpoints (`/processOrder`)

**The three signs of good REST:**
- Predictable URL shape (`GET /orders/34`)
- Meaningful status codes
- Hypermedia where it helps

---

# Auth — three flavors

| | Mechanism | Stateful? | Scales? | Invalidation |
|---|---|---|---|---|
| **Sessions** | cookie + server store | yes | hard | trivial |
| **JWT** | signed token | no | yes | hard |
| **OAuth/OIDC** | delegate identity | no | yes | provider-handled |

**Don't roll your own.** Use a library.

---

# Sessions vs. JWT — decision tree

- One service? → **Sessions**
- Multi-service mesh, short tokens OK? → **JWT**
- "Login with Google/GitHub"? → **OAuth/OIDC**
- Multi-tenant SaaS? → **OIDC + claims**

---

# Adapter

> Reshape an existing interface to match what you need.

Concrete example for Sprint 1:

```ts
// class endpoint speaks /v1/messages
class ClassEndpointAdapter implements LlmBackend {
  async generate(prompt: string) {
    const r = await fetch(/v1/messages, ...);
    return r.json().content[0].text;  // reshape
  }
}
```

Your code stops caring which backend it called.

---

# Decorator

> Add behavior without changing the underlying.

**Middleware IS Decorator at scale.**

`logger(auth(rateLimit(routes)))` — each wraps the next, same interface in/out.

---

# Facade

> A simpler interface to a complex subsystem.

`auth.middleware` is a Facade over:
- JWT verification
- Session lookup
- RBAC checks
- Audit logging

One import, one function, opaque internals.

---

# Bridge · Composite · Flyweight · Proxy

- **Bridge** — decouple abstraction from implementation. Enables independent evolution.
- **Composite** — uniform interface for tree structures (DOM, file system).
- **Flyweight** — share common parts of many similar objects (font glyphs).
- **Proxy** — stand-in object: auth proxy, lazy-load proxy, caching proxy.

---

# Sprint 1 demo prep

**Mon Jun 1**

Your presentation must **name ≥ 2 GoF patterns** you actually used.

Generic "good engineering" → vague rubric grade<br>
Named pattern → specific rubric grade

---

# Discuss in class

1. **Sessions vs. JWT for Sprint 1** — your team's choice. Defend in 60 seconds.
2. **Find a Decorator** in your code. Show it. Or write one in 10 minutes.
3. **Facade or god-object?** When is Facade *correct* vs. *secretly hiding too much*?

---

# What's next

**Week 5** — SQL + Document Stores + GoF Behavioral

**Sprint 1 demo** Mon Jun 1 — tag final commit `sprint-1-final`

**CC #2 (Subagent)** due Sun Jun 7
