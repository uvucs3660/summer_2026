---
slug: lecture-w12-pki-owasp-security
week: 12
youtube_id: null
companion_sheets:
  - cheatsheet-pki-and-mtls
  - cheatsheet-owasp-top-10
  - cheatsheet-auth
reflection_assignment: reflection-w12
vernacular_tags:
  - "PKI: certificate, CA, chain"
  - "PKI: mTLS"
  - "JWT: signing key rotation"
  - "OWASP: A01-A10"
  - "Security: CSP, SameSite, CSRF"
  - "Perfect Framework: Security"
---

# Week 12 — PKI · OWASP · Security Review

## What you'll know after this

You'll be able to (a) explain what a certificate chain is and how mutual TLS differs from server TLS; (b) list the OWASP Top 10 (2021/2024) by name and identify which one your capstone is most exposed to; (c) describe three concrete mitigations beyond "use HTTPS" (CSP headers, SameSite cookies, CSRF tokens, signed cookies); (d) review someone else's code with security questions in mind.

## Outline

1. **PKI in 8 minutes** *(8 min)*
   Public key + private key + signature. A certificate is "this public key belongs to this name, signed by a CA we trust." A chain is "we trust the CA because that root authority vouches for it." Browser trust stores. What goes wrong: expired certs, hostname mismatch, weak signature algorithms, self-signed certs in production.

2. **Mutual TLS (mTLS)** *(7 min)*
   Server proves identity (normal HTTPS). Client ALSO proves identity. Used for service-to-service inside infrastructure (no shared API key needed). Why it doesn't replace user authn (humans don't carry certs gracefully). Sprint 3 capstones may or may not use mTLS; if your inter-service communication crosses zone boundaries, consider it.

3. **JWT in production — what they don't tell you** *(8 min)*
   Signing key rotation (you have to do this). Token expiration vs. revocation (these are different problems). Storing tokens (not in localStorage if you can help it; HttpOnly cookies). The `kid` header. Don't confuse JWT for sessions; they solve different problems.

4. **OWASP Top 10 — the working list** *(15 min)*
   - **A01 Broken Access Control** (most common).
   - **A02 Cryptographic Failures** (don't roll your own).
   - **A03 Injection** (SQL, command, XSS).
   - **A04 Insecure Design** (the one that's hard to retrofit).
   - **A05 Security Misconfiguration**.
   - **A06 Vulnerable Components** (`npm audit` is your friend).
   - **A07 Auth Failures**.
   - **A08 Software & Data Integrity Failures**.
   - **A09 Logging & Monitoring Failures** — connects directly to W13.
   - **A10 SSRF**.

5. **The three browser-side defenses** *(7 min)*
   - **CSP (Content Security Policy)** — what scripts are allowed to run, from where. Mitigates XSS structurally.
   - **SameSite cookies** — cookies attached only to first-party requests. Mitigates CSRF.
   - **CSRF tokens** — for the form submissions where SameSite isn't enough.

6. **Code review with security eyes** *(5 min)*
   Three questions to ask of any PR: "What input does this trust?" "What does this output to where?" "What permission does this code execute under, and could a less-privileged caller reach it?" Use these on someone else's PR this week.

## Discuss in class

- **Pick your capstone's most-exposed OWASP item.** Each team — which of A01-A10 is your biggest risk? What's the mitigation in your code right now?
- **Storage of secrets.** Where does the class LLM API key live in your team's running app? Is that the same place it lives in source control? (It should NOT be.)
- **The CSP that breaks Stripe but not your app.** Sketch a CSP header for your capstone. What `script-src` directives must include?

## Further reading

- **`cheatsheet-pki-and-mtls`** — cert chains, validation, mTLS.
- **`cheatsheet-owasp-top-10`** — current top 10 with mitigations.
- **`cheatsheet-auth`** — sessions/JWT/OAuth from W4, but skim again with security eyes.
- **OWASP cheat sheet series** — owasp.org/www-project-cheat-sheets — actual gold standard references.
- **Mozilla Observatory** — `observatory.mozilla.org` — runs your deployed site through a security checklist.

## What's next

Week 13 closes the lecture spine with CI/CD, observability, and production-readiness — the W13 quiz drops with this lecture. CC #5 (Plugin) is due Sun Aug 2; final demos are Wed Aug 5.
