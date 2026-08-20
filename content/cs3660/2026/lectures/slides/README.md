# Lecture Slide Decks

One Marp markdown deck per lecture (W1–W13). These are **instructor presentation materials**, not Canvas content — they are intentionally placed in a subdirectory so the course-builder's lecture loader (which globs `content/cs3660/2026/lectures/*.md` non-recursively) ignores them.

## Render

```bash
# install marp once
npm i -g @marp-team/marp-cli

# render one deck to PDF
marp content/cs3660/2026/lectures/slides/w01-intro-slides.md --pdf

# or to HTML (browser-presentable)
marp content/cs3660/2026/lectures/slides/w01-intro-slides.md --html

# render all 13 in one shot
for f in content/cs3660/2026/lectures/slides/w*-slides.md; do
  marp "$f" --pdf
done
```

## Theme

All decks use the bundled `default` theme with `class: invert` (dark) and inline `<style>` overrides for color accents that match the cheat-sheet diagrams (yellow `#fcd34d` for headings, blue `#60a5fa` for subheadings).

## Editing

Edit the deck and re-render. Marp re-reads on each invocation; there's no build cache. For live preview during edits, install the **Marp for VS Code** extension — it renders inline as you type.

## Structure

Each deck:

1. Title slide (course · week · topic)
2. "What you'll know after this" — 3-4 outcomes
3. ~8-10 content slides — one idea per slide, large fonts, minimal text
4. "Discuss in class" — 3 prompts
5. "What's next" — link to next week + due dates

Slides match the corresponding `wNN-<slug>.md` lecture page in the parent directory but are presentation-shaped, not reading-shaped.
