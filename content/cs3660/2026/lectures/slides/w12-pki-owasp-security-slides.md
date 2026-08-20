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

# Week 12 — PKI · OWASP · Security Review

---

# What you'll know after this

1. **Certificate chains** + how mTLS differs from server TLS
2. **OWASP Top 10** by name + which one your capstone is most exposed to
3. Three concrete mitigations beyond "use HTTPS"
4. Review someone else's code with **security questions** in mind

---

# PKI in 8 minutes

A **certificate** says:

> "this public key belongs to this name, signed by a CA we trust"

A **chain** says:

> "we trust the CA because that root authority vouches for it"

**Browser trust stores** = the root authorities.

What goes wrong: expired, hostname mismatch, weak signature, self-signed in prod.

---

# Mutual TLS (mTLS)

| | Server TLS | Mutual TLS |
|---|---|---|
| **Server proves identity** | yes | yes |
| **Client proves identity** | no | **yes** |

**Used for** service-to-service inside infrastructure (no shared API key).

**Why not for users?** Humans don't carry certs gracefully.

If your inter-service comms cross zone boundaries → **consider mTLS**.

---

# JWT in production — what they don't tell you

- **Signing key rotation** — you have to do this
- **Expiration vs. revocation** — different problems
- **Storing tokens** — NOT in localStorage if avoidable; **HttpOnly cookies**
- **The `kid` header** — multi-key support
- **Don't confuse JWT for sessions** — different problems

---

# OWASP Top 10 — 1/2

- **A01 Broken Access Control** ← most common
- **A02 Cryptographic Failures** ← don't roll your own
- **A03 Injection** ← SQL · command · XSS
- **A04 Insecure Design** ← hard to retrofit
- **A05 Security Misconfiguration**

---

# OWASP Top 10 — 2/2

- **A06 Vulnerable Components** ← `npm audit` is your friend
- **A07 Auth Failures**
- **A08 Software & Data Integrity Failures**
- **A09 Logging & Monitoring Failures** ← connects to W13
- **A10 SSRF**

---

# Three browser-side defenses

**CSP (Content Security Policy)**<br>
→ what scripts can run, from where<br>
→ mitigates XSS **structurally**

**SameSite cookies**<br>
→ cookies attached only to first-party requests<br>
→ mitigates CSRF

**CSRF tokens**<br>
→ for form submissions where SameSite isn't enough

---

# Code review with security eyes

Three questions for **any PR**:

1. **What input does this trust?**
2. **What does this output to where?**
3. **What permission does this run under, and could a less-privileged caller reach it?**

Use these on someone else's PR this week.

---

# Discuss in class

1. **Pick your most-exposed OWASP item** — which of A01-A10 is your biggest risk? Mitigation in code right now?
2. **Storage of secrets** — where does the class LLM API key live in your running app? Is that the same place it lives in source? *(It should NOT be.)*
3. **The CSP that breaks Stripe but not your app** — sketch a CSP header for your capstone.

---

# What's next

**Week 13** — CI/CD · observability · production-readiness

**W13 quiz** drops with that lecture

**CC #5 (Plugin)** due Sun Aug 2

**Final demos Wed Aug 5**
