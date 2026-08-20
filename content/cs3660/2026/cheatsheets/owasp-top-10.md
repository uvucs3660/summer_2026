# OWASP Top 10 Cheat Sheet (80/20)

The 10 most-common web app security failure categories. The OWASP Top 10 is updated every few years; this cheat sheet aligns to the 2021/2024 list. If you only learn 10 security categories, learn these.

You don't memorize the list to pass the W12 quiz — you learn each enough to recognize it in your own code. The W12 quiz is a comprehension check.

## A01 — Broken Access Control

The most common; #1 since 2017.

**What it is**: A user can access data or perform operations they shouldn't. Most often: missing authorization checks, predictable record IDs.

**Examples**:
- `GET /api/users/42/profile` — does the server check that the requester IS user 42 (or has admin)?
- IDOR (Insecure Direct Object Reference): `GET /docs/12345` returns the doc without checking ownership.
- BOLA (Broken Object-Level Authorization): the same, terminology shift.
- Function-level missing checks: `POST /admin/delete-all` is exposed but only the UI hides it.

**Mitigations**:
- Default deny, allow-list.
- Authorization at the route AND at the data layer (see `cheatsheet-auth` data permissions).
- Postgres row-level security as defense-in-depth.
- UI hiding ≠ security. The API must refuse.

## A02 — Cryptographic Failures

(Was "Sensitive Data Exposure"; renamed in 2021.)

**What it is**: data exposed because crypto is missing, weak, or misconfigured. Includes plaintext passwords, weak hashing, expired certs, weak ciphers, secrets in source.

**Examples**:
- Storing passwords with MD5/SHA-256 (single-pass). Should be argon2 or bcrypt.
- Sending sensitive data over HTTP. Should be HTTPS everywhere; HSTS configured.
- Hardcoded secrets in source / config commits. Should be in env vars or a secrets manager.
- Weak TLS configurations (SSLv3, TLS 1.0, weak ciphers).

**Mitigations**:
- Use battle-tested libraries (`bcrypt`, `argon2`, `libsodium`). Don't roll your own.
- Enforce HTTPS via HSTS header.
- Scan repos for committed secrets (`gitleaks`, `truffleHog`); rotate any leaked.
- Store secrets in environment, secrets manager, or runtime-injected (Kubernetes secrets, AWS Secrets Manager).
- Modern TLS only (1.2+; ideally 1.3) — see `cheatsheet-pki-and-mtls`.

## A03 — Injection

SQL injection, command injection, XSS, LDAP injection — same family of bugs: user input is treated as code.

**Examples**:
- String-concatenating user input into a SQL query — SQL injection.
- Passing user input as a shell command argument without escaping — command injection.
- Inserting user-supplied content into the page DOM via the unsafe HTML setters — XSS.

**Mitigations**:
- **Parameterized queries / prepared statements** — never concatenate user input into SQL. The library binds parameters separately:
  ```javascript
  // Good (parameterized):
  db.query('SELECT * FROM users WHERE id = $1', [userId]);
  // Bad (concatenated):
  db.query(`SELECT * FROM users WHERE id = ${userId}`);
  ```
- **Use array-form child process APIs** instead of shell-string forms when invoking external programs. Pass arguments as an array; the OS treats them as data, not as part of a command line.
- **Output encoding** — escape user input when rendering. React/Vue/Svelte do this by default unless you opt out via the framework's explicit-unsafe-HTML escape hatches (named with words like *dangerously*, *raw*, or *html* — those are the red-flag APIs).
- **CSP (Content Security Policy)** — defense-in-depth against XSS by limiting which scripts can run.
- **Validation at input boundaries** — accept what you expect; reject what you don't.

## A04 — Insecure Design

**What it is**: the architecture itself enables vulnerabilities. No amount of careful coding will fix a fundamentally weak design.

**Examples**:
- Password reset that leaks whether an email exists ("we sent reset email" vs. "no such user").
- Rate-limiting only on the login endpoint, not on the password-reset endpoint.
- Trusting the client to send `userRole: "admin"` in API requests.

**Mitigations**:
- Threat modeling early in design.
- Default-deny security architecture (zero trust).
- Rate-limit and abuse-detect everything user-facing.
- Server-side authoritative state. Never trust client claims about identity, role, or permission.

## A05 — Security Misconfiguration

The category that includes everything else: default credentials, verbose error messages, unnecessary features enabled, missing security headers.

**Examples**:
- Default admin password unchanged.
- Stack traces returned to users in production.
- `X-Powered-By: Express` header advertising your framework version.
- CORS too permissive (`Access-Control-Allow-Origin: *` with credentials).
- Open S3 buckets / public cloud storage.

**Mitigations**:
- Hardening checklist for each layer (server, framework, DB, cloud).
- `helmet` (Node) or equivalent for security headers.
- Production builds vs. development builds — different config, different verbosity.
- Cloud security scanners (AWS Config, GCP SCC, Azure Defender).
- `Mozilla Observatory` for a one-shot HTTPS/headers grade.

## A06 — Vulnerable & Outdated Components

Dependencies have known CVEs. You inherit the vulnerabilities.

**Mitigations**:
- `npm audit` / `pip-audit` / `bundler-audit` / `cargo audit` — run on every build.
- Dependabot or Renovate to auto-PR dependency bumps.
- Pin versions in production lockfiles.
- Subscribe to security advisories for major dependencies.
- Avoid abandoned packages — check last update date and download trend.

## A07 — Identification & Authentication Failures

(Was "Broken Authentication".)

**Examples**:
- No rate limiting on login → credential stuffing works.
- Weak password requirements → brute force works.
- Session IDs predictable / reused / not invalidated on logout.
- Account-recovery flows that bypass the password.

**Mitigations**:
- Rate-limit login and recovery endpoints (see `cheatsheet-auth`).
- Session invalidation on logout (delete session row; if JWT, blocklist or short expiration).
- Multi-factor authentication for sensitive operations.
- Don't roll your own — use `Auth0` / `Clerk` / `Supabase Auth` / battle-tested libraries.

## A08 — Software & Data Integrity Failures

(Newer category; 2021.)

**What it is**: trusting code or data that's been tampered with. Includes insecure deserialization, missing signature verification on updates, dependency confusion attacks.

**Examples**:
- Auto-updating from an unsigned URL.
- Deserializing untrusted JSON directly into native code paths.
- CI/CD pipeline that doesn't verify package signatures.
- `npm install` from a typo-squatted package name.

**Mitigations**:
- Subresource Integrity (SRI) for CDN-loaded scripts.
- Signed packages (Sigstore, npm publish provenance).
- CI signing: builds produce signed artifacts; deploy verifies.
- Lockfile commits (`package-lock.json`, `yarn.lock`, `Pipfile.lock`).
- Reject deserialization of untrusted data into native types.

## A09 — Security Logging & Monitoring Failures

You can't respond to what you don't see.

**Examples**:
- Login failures not logged → can't detect brute force.
- Privilege escalation not flagged → attackers move freely.
- Logs without timestamps, identities, or correlation IDs → useless during investigation.
- Logs deleted by attackers because they're not centralized.

**Mitigations**:
- Structured logging (see `cheatsheet-observability-logs-metrics-traces`).
- Centralized log aggregation (Loki, Splunk, Datadog) — not just on disk.
- Alert on anomalies (login spike from new IPs, failed-auth burst, role escalation).
- Audit trail for security-relevant operations (see `cheatsheet-perfect-framework-concerns`).

## A10 — Server-Side Request Forgery (SSRF)

The server makes a request to a URL it shouldn't.

**Example**: image-upload-by-URL feature lets attacker make the server fetch `http://169.254.169.254/latest/meta-data/iam/security-credentials/` (AWS internal metadata) and exfiltrate cloud credentials.

**Mitigations**:
- Allow-list of permitted destinations.
- Block private IP ranges (10.x, 172.16-31.x, 192.168.x, 169.254.169.254).
- Validate the resolved IP, not just the hostname (DNS rebinding).
- Use a forward proxy for outbound traffic that enforces these rules.

## The two browser-side defenses you'll set up

Beyond the per-vulnerability mitigations, two header-level defenses worth knowing:

### Content Security Policy (CSP)

Browser refuses to execute scripts not on your allow-list. Mitigates XSS *structurally* — even if attacker injects a `<script>`, it doesn't run unless the source is allowed.

```
Content-Security-Policy: default-src 'self';
  script-src 'self' https://cdn.example.com;
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' wss://api.example.com;
  frame-ancestors 'none';
```

Start in Report-Only mode (`Content-Security-Policy-Report-Only`) to find what you'd break before enforcing.

### SameSite cookies

Mitigates CSRF without you having to think about CSRF tokens for most cases.

```
Set-Cookie: session=abc; HttpOnly; Secure; SameSite=Lax
```

Lax = cookies sent on top-level navigation (clicking a link), not on cross-site form submissions. Strict = cookies only sent on same-origin requests at all. Default in modern browsers (since 2020-ish) is Lax even if you don't specify, but always set it explicitly.

## Pick your capstone's most-exposed item

Each Sprint 3 team should pick the item their capstone is most likely to fail at and demonstrate mitigation:

| If your capstone is... | Likely highest-exposure |
|---|---|
| Multi-tenant SaaS | A01 (Access Control) |
| Storing credentials / tokens | A02 (Cryptographic Failures) |
| User-supplied content (markdown, HTML) | A03 (Injection / XSS) |
| Plays with crypto | A02 + A04 (Insecure Design) |
| Connects to many third-party APIs | A05 + A10 (SSRF) |
| Has user accounts | A07 (Auth Failures) |
| Builds via CI/CD that auto-deploys | A08 (Integrity Failures) |
| Has logs but no alerting | A09 (Logging/Monitoring) |

## What this is in vernacular

- A01 maps to Perfect Framework's *Security > Authorization* + *Data permissions* + *Menu/form/field-level control*.
- A02 maps to Perfect Framework's *Security > Cryptographic protection at rest and in transit*.
- A09 maps to Perfect Framework's *Database > Audit trails* + *CI/CD/Documentation/Feedback > Observability*.
- A06 maps to Perfect Framework's *CI/CD > Versioned build artifacts* + dependency management.
- The whole list is what Perfect Framework's *Security* concern operationalizes when "the framework should handle this" goes from theory to practice.

## Further reading

- **owasp.org/www-project-top-ten/** — current top 10, with each category linked to detailed guidance.
- **OWASP Cheat Sheet Series** — practical "how to mitigate X" sheets for many of these.
- **PortSwigger Web Security Academy** — free hands-on training.
- **`cheatsheet-auth`** — covers A01, A02, A07 in implementation depth.
- **`cheatsheet-pki-and-mtls`** — covers A02 in transport-security depth.
- **`cheatsheet-observability-logs-metrics-traces`** — covers A09 in implementation depth.
