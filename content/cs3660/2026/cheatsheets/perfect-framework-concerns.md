# Perfect Framework Concerns Deep-Dive Cheat Sheet (80/20)

The 20% of `cheatsheet-perfect-framework`'s seven concerns you'll need to *implement* in Sprint 3 capstones — not just name. This sheet drills into the four that capstones most often pick: **i18n**, **accessibility**, **RBAC + data permissions**, **audit trails**.

The other concerns (Scale, Database, Messaging, CI/CD) have their own dedicated sheets. This one fills the gap on the four "Application" sub-concerns the rubric most often awards capstone bonus points for.

## i18n — internationalization

Internationalization is the **engineering substrate** that lets translation happen. Translation is a separate (human) concern.

### The four concrete capabilities

1. **Strings out of code.** No hardcoded English (or any language) in source. Every user-visible string is in a translation table.

   ```typescript
   // Bad:
   <h1>Welcome to Job Pack</h1>

   // Good:
   <h1>{t('home.welcome')}</h1>
   // and: en.json: { "home.welcome": "Welcome to Job Pack" }
   //      es.json: { "home.welcome": "Bienvenido a Job Pack" }
   ```

2. **Locale-aware formatting.** Numbers, dates, currencies, units. Use `Intl` (browser-native):

   ```javascript
   new Intl.NumberFormat('de-DE').format(1234.56);  // "1.234,56"
   new Intl.DateTimeFormat('ja-JP', { dateStyle: 'long' }).format(new Date());
   // "2026年5月6日"
   ```

3. **Pluralization rules** — different per language. English: 1 / many. Russian: 1 / 2-4 / 5+ / many. Arabic: 1 / 2 / 3-10 / 11-99 / 100+.

   Use ICU MessageFormat (`{count, plural, one {# item} other {# items}}`); libraries (`messageformat`, `formatjs`) handle locale rules.

4. **Right-to-left (RTL) layout** — Arabic, Hebrew, Persian, Urdu. CSS logical properties (`margin-inline-start` instead of `margin-left`); `dir="rtl"` on html/body; flexbox/grid handle the rest cleanly.

### Testing your i18n

Don't test by switching English to "English With Different Words." Test with:
- A locale you don't read (Hebrew or Japanese) — does the layout break?
- A long-string locale (German, Finnish) — does the UI overflow?
- A pluralization-heavy locale (Arabic, Russian) — does the message library handle it?

If you only test in English, you've tested 0% of i18n.

### Tools

- **`i18next`** + `react-i18next` / `vue-i18n` — battle-tested.
- **`formatjs`** (Format.JS) — the standard ICU MessageFormat implementation.
- **Crowdin** / **Lokalise** — translation-management platforms.

## Accessibility (a11y)

WCAG 2.1 AA is the realistic target. The 80/20 of accessibility is four practices applied consistently:

### 1. Semantic HTML

Use the right element. `<button>` not `<div onclick>`. `<nav>` for navigation. `<main>` for the primary content. `<h1>`-`<h6>` for hierarchy.

The single biggest accessibility win is replacing div-soup with semantic tags. Screen readers, keyboard navigation, browser features all rely on this. Free a11y in exchange for typing 5 characters.

### 2. Keyboard navigation

- Every interactive element reachable via Tab.
- Focus indicators visible (don't `outline: none` without replacing it).
- No keyboard traps (Esc closes modals; focus returns to trigger).
- Skip-link to main content for screen-reader users.

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<!-- ...nav... -->
<main id="main-content" tabindex="-1">...</main>
```

Test: unplug your mouse and try to use the app. If you can't, neither can a keyboard-only or screen-reader user.

### 3. ARIA when semantic HTML isn't enough

ARIA labels/roles fill gaps that semantic HTML can't. Don't use ARIA when semantic HTML works (`<button>` doesn't need `role="button"`). Use it for:

- Custom widgets that don't have a native HTML equivalent (combobox, tree, tab panel).
- Live regions: `aria-live="polite"` for status updates.
- Labels for icon-only buttons: `<button aria-label="Close">×</button>`.

### 4. Color and contrast

- Text contrast ≥ 4.5:1 for normal text (3:1 for large text).
- Never information conveyed by color alone (red errors AND a ⚠ icon AND text).
- Disabled states must still meet contrast minimums (or use other affordances).

### Testing accessibility

- **axe DevTools** — browser extension; runs automated checks. Catches ~30% of issues.
- **NVDA** (Windows free) or **VoiceOver** (macOS built-in) — actually use a screen reader on your app.
- **Keyboard-only walkthrough** — unplug mouse.
- **High-contrast mode** — Windows/macOS settings; reveals contrast issues.

The tools find the easy 30%. The remaining 70% requires actually using the app the way disabled users do.

## RBAC + data permissions

Authorization in two layers. RBAC controls operations; data permissions control which records.

### RBAC schema (relational)

```sql
users (id, email, name)
roles (id, name)                          -- 'admin', 'instructor', 'student'
permissions (id, name)                    -- 'create_assignment', 'view_grade'
user_roles (user_id, role_id)
role_permissions (role_id, permission_id)
```

Check at the route level via middleware:

```typescript
app.post('/assignments',
  authenticate,
  requirePermission('create_assignment'),
  async (ctx) => { ... }
);
```

### Data permissions

The hard part. RBAC says "this user can call `view_grade`." Data permissions say "this user can view *which* grades."

Three layers, defense-in-depth:

**Layer 1: Postgres row-level security**
```sql
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;

CREATE POLICY student_sees_own_grades ON grades
  FOR SELECT TO authenticated_user
  USING (user_id = current_setting('app.user_id')::int);

CREATE POLICY instructor_sees_class_grades ON grades
  FOR SELECT TO authenticated_user
  USING (course_id IN (
    SELECT course_id FROM instructor_assignments
    WHERE user_id = current_setting('app.user_id')::int
  ));
```

The DB enforces; the app sets `SET LOCAL app.user_id = N` per request.

**Layer 2: ORM-level filters**
Every query that returns user-scoped data goes through a filter that adds `WHERE user_id = :current_user`.

**Layer 3: Per-record check before serializing**
```typescript
if (!await canRead(currentUser, grade)) throw new ForbiddenError();
```

**The right answer is usually all three.** Layer 1 catches "I forgot the WHERE clause." Layer 2 makes the common case ergonomic. Layer 3 catches edge cases the layers above missed.

### Menu/form/field-level visibility

UI computes visible elements from RBAC at render time:

```typescript
{can('admin_panel') && <NavLink to="/admin">Admin</NavLink>}
{can('edit_grade') && <input ... />}
```

Important: UI hiding ≠ security. The API must still refuse the call. UI hiding is for UX (don't show buttons users can't click); security is at the route + record layers.

## Audit trails

Recording every change with who/what/when/why. The Perfect Framework treats this as non-negotiable.

### Two implementation patterns

**Pattern 1: Append-only event log (event sourcing)**

Every change is an event. Current state is the fold of all events.

```sql
CREATE TABLE invoice_events (
  id          BIGSERIAL PRIMARY KEY,
  invoice_id  INTEGER NOT NULL,
  event_type  TEXT NOT NULL,         -- 'created', 'updated', 'paid', 'voided'
  actor_id    INTEGER NOT NULL,
  payload     JSONB NOT NULL,
  occurred_at TIMESTAMPTZ DEFAULT now()
);

-- Reconstruct an invoice's current state:
SELECT * FROM invoice_events WHERE invoice_id = 42 ORDER BY id;
-- Apply each event in order to get the current state.
```

Pros: complete history; can replay; enables time-travel queries.
Cons: every read requires the fold; usually paired with a "projection" table for the current state (read model).

**Pattern 2: Point-in-time tables**

Every row carries `valid_from` / `valid_to` timestamps. Updates "expire" the old row and insert a new one.

```sql
CREATE TABLE invoices (
  id          INTEGER NOT NULL,
  status      TEXT NOT NULL,
  amount      DECIMAL,
  valid_from  TIMESTAMPTZ NOT NULL,
  valid_to    TIMESTAMPTZ,            -- NULL = current row
  modified_by INTEGER NOT NULL,
  PRIMARY KEY (id, valid_from)
);

-- Current state:
SELECT * FROM invoices WHERE valid_to IS NULL;

-- State as of yesterday:
SELECT * FROM invoices
  WHERE valid_from <= NOW() - INTERVAL '1 day'
    AND (valid_to IS NULL OR valid_to > NOW() - INTERVAL '1 day');
```

Pros: easy queries for "current state"; relational tooling works.
Cons: every update is two operations (close old, insert new); transactions important.

### Picking between them

Event sourcing for: append-heavy, replay-needed, business-process-shaped systems (orders, payments, workflows).

Point-in-time for: relational-style data with audit needs grafted on (HR records, configuration, anything where the "object" is naturally a row that evolves).

### What every audit trail captures

- **Who** — the user_id of the actor.
- **What** — the entity affected, the field changed, the new value (and ideally the old).
- **When** — timestamp with timezone.
- **Why** — the business reason (often: the action name, like 'approved' or 'voided').

Optional but valuable: source IP, request ID, application version. Saves debugging time later.

## What this is in vernacular

- i18n + accessibility = Perfect Framework's *Application > Localization, Internationalization, Accessibility* concerns.
- RBAC + data permissions = *Security > Role-Based Access Control* + *Data permissions* concerns.
- Audit trails = *Database > Audit trails* concern, often implemented with EIP **Event Message** patterns.
- Event sourcing combines **Command** (GoF) at the storage level with **Event Message** (EIP) at the data shape level.

## Sprint 3 capstone — pick wisely

The rubric awards each concern equally. Pick the one your project structurally needs:

| If your capstone is... | Pick this concern |
|---|---|
| Multilingual user base, content app | i18n |
| Public-facing tool, accessibility is rubric-bonus | accessibility (WCAG AA) |
| Multi-tenant SaaS, multiple user roles | RBAC + data permissions |
| Financial / regulatory / "who did what" matters | audit trails |
| IoT / sensor data with replay | audit trails (event-sourced) |
| Workflow-heavy with state transitions | audit trails (event-sourced) + state charts |

## Further reading

- **`cheatsheet-perfect-framework`** — the seven concerns at-a-glance overview.
- **WCAG 2.1 quick reference** — accessibility checklist.
- **MDN: Internationalization** — `Intl` APIs and ICU MessageFormat.
- **Postgres Row Security** docs — policy syntax.
- **Martin Fowler, "Event Sourcing"** — the foundational article.
- **`cheatsheet-auth`** — sessions/JWT/OAuth that authenticate before authorization runs.
