# Handouts

Printable, pass-around-in-class sheets. **Blank by construction** — no roster data, no student
names, so these belong in the content repo. The moment a sheet has names written on it, it is
roster data and its contents live only under `cs3540-2026-fall/`, never here.

Edit the `.html`, then re-render:

```bash
./build.sh
```

Shared print styling is inlined into each file from `_handout.css`. After editing that stylesheet,
re-inline it into the HTML `<style>` blocks before rendering — the CSS is deliberately inlined so
each handout is a single self-contained file you can email or open anywhere.

| Sheet | Used |
|---|---|
| `signup-favorite-game` | Week 2 — claims a presentation date, weeks 2–8 (12 sessions, 2 slots each) |
| `signup-engine-spec-sections` | Week 2 — holds a spec section `S04`–`S18`; the real claim is the PR to `spec/OWNERS.md`, due Sun Sep 13 |
