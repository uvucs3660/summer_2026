---
slug: lecture-w04-node-rest-auth-structural
week: 4
youtube_id: null
companion_sheets:
  - cheatsheet-client-server-db
  - cheatsheet-auth
  - cheatsheet-gof-structural
reflection_assignment: reflection-w04
vernacular_tags:
  - "GoF: Adapter"
  - "GoF: Decorator"
  - "GoF: Facade"
  - "GoF: Proxy"
  - "EIP: Service Activator"
  - "EIP: Channel Adapter"
  - "Perfect Framework: Security"
---

# Week 4 — Node · REST · Auth · GoF Structural Patterns

## What you'll know after this

You'll be able to (a) sketch a minimal Node + Koa server with three middleware in the right order; (b) name and explain the difference between session-based auth, JWT, and OAuth/OIDC; (c) name all seven GoF Structural patterns and describe one real-world use of each; (d) recognize which Structural pattern your team's auth middleware is.

## Outline

1. **Node + Koa in 8 minutes** *(8 min)*
   The event loop, async/await, the middleware onion. Why Koa over Express (composition, error handling, `ctx`). One minimal `app.use(...)` chain for the Job Pack backend.

2. **REST — design that ages well** *(10 min)*
   Resources, methods, status codes. Idempotency. The four patterns of bad REST (verbs in URLs, deeply-nested routes, `200 OK` errors, action-shaped endpoints). The three signals of good REST (predictable URL shape, meaningful status codes, hypermedia where it helps).

3. **Auth — three flavors** *(15 min)*
   - **Sessions** — cookie + server-side store. Simple, stateful, hard to scale across services.
   - **JWT** — signed token, stateless, scales, but invalidation is hard. Don't roll your own; use a library.
   - **OAuth / OIDC** — delegate identity to a provider. Right answer for "log in with Google/GitHub" and most multi-tenant SaaS.
   Which to use when? Decision tree, with the Sprint 2 use case as the worked example.

4. **Structural Pattern — Adapter** *(5 min)*
   Reshape an existing interface to match what you need. Concrete: wrapping the class LLM endpoint behind a Claude-API-compatible interface so your code stops caring which backend it's calling.

5. **Decorator** *(4 min)*
   Add behavior without changing the underlying. Middleware IS Decorator at scale (logging, auth, rate limit, body parsing — each wraps the next).

6. **Facade** *(4 min)*
   A simpler interface to a complex subsystem. The whole `auth.middleware` you import? It's a Facade over JWT verification, session lookup, RBAC checks, and audit logging.

7. **Bridge, Composite, Flyweight, Proxy** *(8 min)*
   Briefer tour. Bridge = decouple abstraction from implementation. Composite = uniform tree. Flyweight = share common parts of many similar objects. Proxy = stand-in object (auth, lazy load, caching).

8. **Sprint 1 demo prep** *(2 min)*
   Demo day Mon Jun 1. Your presentation must name ≥2 GoF patterns you actually used.

## Discuss in class

- **Sessions vs. JWT for Sprint 1 — make the call.** Which does your team's Job Pack use? Defend it in one minute. Bonus: which would you switch to for Sprint 2's multiplayer system?
- **Find a Decorator in your code.** Open your team's repo. Show one place that's actually using the Decorator pattern. If you can't find one, write one in the next 10 minutes.
- **Facade or god-object?** When is a Facade *correct* and when is it secretly a god-object hiding too much?

## Further reading

- **`cheatsheet-client-server-db`** — Koa middleware onion, request lifecycle, connection pool.
- **`cheatsheet-auth`** — sessions vs. JWT vs. OAuth, with decision-tree diagram.
- **`cheatsheet-gof-structural`** — all seven Structural patterns.
- **OWASP Authentication Cheat Sheet** — what NOT to do with passwords, tokens, sessions.

## What's next

Week 5 closes Sprint 1 with databases and GoF Behavioral patterns. Sprint 1 demos are Mon Jun 1; final commit must be tagged `sprint-1-final`. CC #2 (Subagent) is due Sun Jun 7.
