# Onboarding 5/5 — LLM API Smoke Test

**Due:** Sun May 10, 2026 23:59 MT
**Points:** 1 (pass/fail)
**Prerequisite:** Assignment 4 (GitHub username submitted, API key received).

## What to do

You've received your class LLM API key via Canvas DM. Save it as the env var `CS3660_LLM_KEY` in your shell:

```bash
export CS3660_LLM_KEY='<your-key-here>'
```

(Add this to your `.zshrc` or `.bashrc` for convenience. Do **not** commit the key.)

Then run the smoke test:

```bash
curl -s https://llm.uvucs.org/api/chat \
  -H "Authorization: Bearer $CS3660_LLM_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2:1b","messages":[{"role":"user","content":"Say hello in one word."}]}'
```

Expected: a JSON response with the assistant's one-word greeting.

## How to submit

Commit a markdown file at `week1/api-smoke-test.md` in your portfolio repo containing:

- The exact `curl` command you ran (with the API key redacted as `<REDACTED>`).
- The full JSON response.
- A 1-2 sentence note on what surprised you about the experience.

Submit the commit URL here.

## Acceptance criteria

- Curl command shown.
- Response JSON included and non-empty.
- API key is redacted in the committed file.
- Note is present.

## Troubleshooting

- 401 Unauthorized → key wrong or revoked. DM the instructor.
- Connection refused → service may be down. Check the status page (link in the LLM Endpoint Setup wiki page).
