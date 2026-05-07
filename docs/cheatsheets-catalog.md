# Cheat Sheet Catalog

What we have, what we need for the 2026 lecture spine, and what we could add.

## Style baseline

- Title: `# {Topic} Cheat Sheet (80/20)`
- Lead: one-paragraph statement of "the 20% you'll touch 80% of the time"
- Structure: headings by sub-topic, code blocks with inline annotations, embedded SVG diagrams via relative `diagrams/<name>.svg` links
- Length: 180–450 lines (target ~250)
- Tone: terse, opinionated ("almost always what you want"), points at what to skip

Existing sheets all hit this bar.

---

## A. What we have

### Markdown cheat sheets (6 files in `cheatsheets/`)

| File | Lines | Topic | Diagrams used | Maps to lecture week |
|---|---|---|---|---|
| `html.md` | 188 | HTML structure, common tags, forms, semantic markup | 3 | W2 |
| `css.md` | 238 | Selectors, box model, flexbox, grid, position | 5 | W2 |
| `typescript.md` | 305 | Primitives, objects, unions, generics, narrowing | 3 | W2 (carries into W3+) |
| `client-server-db.md` | 444 | HTTP, DNS, sockets, Koa middleware, Postgres connection | 5 | W4 (Node/REST/auth) + parts of W5 |
| `sql.md` | 377 | SELECT/JOIN/INSERT/UPDATE/DELETE, indexes, query plans, Postgres flavor | 4 | W5 |
| `shadow-dom-pwa.md` | 430 | Shadow DOM, custom elements, service workers, PWA install | 5 | W9 |

**Total existing markdown:** 1,982 lines across 6 sheets, all 25 referenced diagrams present.

### SVG diagrams (25 files in `cheatsheets/diagrams/`)

| Group | Diagrams |
|---|---|
| HTML | `html-document-tree`, `html-block-inline`, `html-form-flow` |
| CSS | `css-box-model`, `css-flexbox`, `css-grid`, `css-position`, `css-selectors` |
| TypeScript | `ts-generics`, `ts-narrowing`, `ts-union-intersection` |
| SQL | `sql-table-anatomy`, `sql-joins`, `sql-query-order`, `sql-index-vs-scan` |
| Client / Server / DB | `dns-resolution`, `http-anatomy`, `request-flow`, `koa-middleware-onion`, `connection-pool`, `caching-strategies` |
| Shadow DOM / PWA | `shadow-dom-tree`, `shadow-dom-slots`, `service-worker-lifecycle`, `pwa-architecture` |

Every existing SVG is referenced by at least one of the markdown sheets. No orphans.

---

## B. What we need (gap analysis vs. the 13-week lecture spine)

The 2026 spec's §5 defines 13 weekly lecture topics. Each should have a corresponding cheat sheet that students reference during sprint work and reflections. Below, ✅ = covered by an existing sheet, ❌ = not covered yet.

| W | Lecture topic | Coverage | Cheat sheet (existing or needed) |
|---|---|---|---|
| 1 | Course intro · Agile v2 · Perfect Framework · vernacular | ❌ | **NEEDS:** `agile-v2.md` · `perfect-framework.md` · `vernacular-index.md` |
| 2 | HTML/CSS/JS refresh · Job Pack kickoff · LLM endpoint primer | ✅ | `html.md` + `css.md` + `typescript.md` cover web-platform; **NEEDS:** `llm-endpoint-usage.md` (auth, streaming, rate limits, Strategy pattern for backends) |
| 3 | Frameworks survey · GoF Creational patterns | ❌ | **NEEDS:** `frameworks-survey.md` (React/Vue/Svelte/Flutter-web tradeoffs) · `gof-creational.md` |
| 4 | Node + REST + auth · GoF Structural patterns | ⚠️ partial | `client-server-db.md` covers Node/Koa/REST; **NEEDS:** dedicated `auth.md` (OAuth/JWT/sessions) · `gof-structural.md` |
| 5 | SQL + document stores + DB versioning · GoF Behavioral patterns | ⚠️ partial | `sql.md` covers Postgres SQL; **NEEDS:** `document-stores.md` (Mongo/JSONB) · `db-versioning.md` (Liquibase/migrations) · `gof-behavioral.md` |
| 6 | EIPs Part 1 — channels, message construction | ❌ | **NEEDS:** `eips-part1-channels-and-messages.md` |
| 7 | EIPs Part 2 — routing, transformation · state charts | ❌ | **NEEDS:** `eips-part2-routing-and-transforms.md` · `state-charts.md` (XState) |
| 8 | Realtime web — MQTT, WebSockets, GraphQL subscriptions | ❌ | **NEEDS:** `mqtt.md` · `websockets.md` · `graphql-subscriptions.md` (or one merged `realtime-web.md`) |
| 9 | PRPL · service workers · offline-first | ⚠️ partial | `shadow-dom-pwa.md` covers service workers + PWA install; **NEEDS:** `offline-first-sync.md` (IndexedDB + background sync, cache strategies in depth) |
| 10 | Perfect Framework deep-dive (scale, i18n, accessibility, RBAC) | ❌ | **NEEDS:** `i18n.md` · `accessibility-wcag.md` · `rbac.md` · `audit-trails.md` (or combined `perfect-framework-concerns.md`) |
| 11 | Advanced web platform (WebRTC, USB, Bluetooth, Camera) | ❌ | **NEEDS:** `webrtc.md` · `web-usb-bluetooth.md` · `camera-and-media.md` (or merged `advanced-web-platform.md`) |
| 12 | PKI · OWASP · security review | ❌ | **NEEDS:** `pki-and-mtls.md` · `owasp-top-10.md` · `web-security-checklist.md` |
| 13 | CI/CD · observability · production-readiness | ❌ | **NEEDS:** `cicd-github-actions.md` · `observability-logs-metrics-traces.md` · `production-readiness-checklist.md` |

### Cross-cutting (not week-specific)

| Topic | Status | Why it matters |
|---|---|---|
| `claude-code-capabilities.md` | ❌ | Referenced from W1 onwards; the 5 individual CC artifact assignments (Track 3) all assume this vocabulary. Currently only the `docs/reference/claude-code-capabilities.md` text exists — no cheat-sheet-style sheet with diagrams. **NEEDS** a real cheat sheet. |
| `git-workflow.md` | ❌ | Every team and individual submission goes through git. PR review, branching, tags (`sprint-{N}-final`), commit hygiene. **NEEDS:** a cheat sheet that the W1 LinkedIn-Learning-Git assignment can reference. |
| `regular-expressions.md` | ❌ | Referenced in 2025 export (`regular-expression-language-quick-reference.html`); useful for both Job Pack pipeline and grading. **COULD GENERATE.** |

### Summary of needs

| Tier | Count | Estimate |
|---|---|---|
| **Critical** (one per uncovered lecture week + CC capabilities + git) | ~14 sheets | Largest gap |
| **Important** (split topics out of partial-coverage sheets) | ~5 sheets | Medium gap |
| **Nice** (regex, framework-specific deep dives) | ~3 sheets | Low priority |

---

## C. What we could generate (beyond strict need)

Each of these would add real value but isn't required by the spec. Roughly ordered by ROI:

1. **Per-framework deep dives** — `react.md`, `vue.md`, `svelte.md`, `flutter-web.md`. The W3 `frameworks-survey.md` should compare; some teams will want depth in one. Diagrams: component-tree, hooks lifecycle, reactivity model.
2. **`docker-compose-basics.md`** — most capstone projects benefit from local-stack composition; a mini-cheat sheet with one annotated `docker-compose.yml` would save hours.
3. **`testing.md`** — unit/integration/e2e for web (Vitest, Playwright). Sprint 2 already requires "1 unit test per team member" — students need the vocabulary.
4. **`api-design.md`** — REST resource modeling, GraphQL schema design, OpenAPI. Companion to the EIPs sheets; every sprint produces APIs.
5. **`accessibility-deep-dive.md`** — keyboard nav, ARIA roles, screen reader behavior. The Perfect Framework deep-dive sheet should at least *introduce* this; a deeper sheet helps capstone teams who pick accessibility as their concern.
6. **`design-systems-and-tokens.md`** — design tokens, Tailwind, component libraries. Sprint 3 capstone teams who go UI-heavy benefit.
7. **`prompt-engineering-for-llm-pipelines.md`** — system vs. user vs. tool messages, structured output, function calling. Adjacent to `llm-endpoint-usage.md`; useful for Sprint 1 Job Pack and the CC artifact track.
8. **`vector-search-and-rag.md`** — embeddings, similarity search, RAG architectures. Likely capstone material for some teams.
9. **`error-budgets-and-slos.md`** — SRE concepts. Companion to W13 production-readiness.
10. **`progressive-web-app-install.md`** — manifest, install prompts, app stores. Could merge into shadow-dom-pwa or stand alone.

Most of these would also need 1-3 diagrams each. Diagrams are the higher-effort part of cheat-sheet production.

---

## D. Canvas integration plan

Currently the course has 8 wiki pages (syllabus, instructor info, schedule, claude-pro-setup, llm-endpoint-setup, privacy, submission-mechanics, vernacular-references). Cheat sheets should join these as additional wiki pages, organized into a single "Cheat Sheets" module so students can browse them as a coherent reference library.

### Proposed structure

```
content/2026/
  pages/
    cheatsheets/
      html.md
      css.md
      typescript.md
      client-server-db.md
      sql.md
      shadow-dom-pwa.md
      ... (each cheat sheet)
    diagrams/                      ← copied from cheatsheets/diagrams/
      *.svg
  course.yaml
    pages:
      - slug: cheatsheet-html
        title: "Cheat Sheet — HTML"
        body: pages/cheatsheets/html.md
      - ...
    modules:
      - slug: cheat-sheets
        title: Cheat Sheet Library
        items:
          - kind: wiki_page
            ref: cheatsheet-html
          - ... (one per sheet)
```

### Generator changes required

1. **Web resources support** — the packager currently emits HTML wiki pages and assignments but no binary attachments. To include SVG diagrams in the Canvas zip, we need a `web_resources/` directory in the cartridge (matching the 2025 export's pattern) plus manifest entries. Estimated: 1 new emitter, 1 new packager step, ~50 lines.
2. **Image-link rewriting** — the markdown sheets reference `diagrams/foo.svg` (relative). Canvas needs `$IMS-CC-FILEBASE$/diagrams/foo.svg` paths in the rendered HTML. Either rewrite during markdown rendering, or copy SVGs to a path that matches the relative reference. Estimated: 10–20 lines in the markdown loader.
3. **Module item bulk-insert** — `course.yaml` will grow significantly with 20+ new pages. Consider a glob-style `pages_dir: pages/cheatsheets/` shorthand to avoid hand-listing every file. Estimated: 30 lines in the loader. Optional but worth doing once the count climbs.

### Sequencing

A reasonable order to ship:

1. Add web-resources / image-link plumbing to the generator (one task).
2. Write the W1 critical sheets (Agile v2, Perfect Framework concerns, Vernacular index, Claude Code capabilities, Git). These unblock the first few weeks.
3. Write per-week sheets in lecture order (W2 → W13). Realistic pace: 2-3 sheets / week alongside lectures.
4. Backfill the "could generate" list as time allows.

The course can ship Week 1 with only the existing 6 sheets + the 5 critical W1 sheets; weeks 2-13 sheets can land just-in-time.

---

## E. Lecture content track (outlines + notes + videos)

The cheat sheets are **reference material** — pull when needed, deep, structured by topic. The lecture content track is **narrative material** — push during instruction, structured by week. They serve different reading modes and should not duplicate.

### What we have (lecture content)

Almost nothing on the 2026 side:

- The 2025 course delivered lectures as YouTube videos with no per-lecture wiki pages — only a single schedule page. The 2026 spec (§13) asked for "13 weekly lecture pages with embedded YouTube + reflection assignment," but the shipped course.yaml distributes reflections across sprint modules with no standalone lecture pages. **This is a gap from the spec.**
- The 2025 export's `web_resources/Slides/` contains Ken Jenson's old slide decks (LAMP/Vue era) — *not* Hunter's content. Ignored per the as-built notes in the workspace CLAUDE.md.
- No YouTube videos recorded yet for any 2026 lecture.

### Recommended model: thin lecture pages + cheat sheets + videos

For each of the 13 lecture weeks, one Canvas wiki page with this structure:

```markdown
# Week N — {Topic title}

**Companion cheat sheets:** [cheat-sheet-A](#) · [cheat-sheet-B](#)
**Reflection due:** Sun {date} · [Submit reflection](#)
**Vernacular introduced:** {GoF pattern} · {EIP} · {Perfect Framework concern} · {CC capability}

## What you'll know after this

One paragraph (≤80 words) stating the three or four concrete things a student should be able to *do* or *recognize* after watching.

## Outline

1. **{Section title}** ({minutes})
   {1-2 sentence takeaway — the "what stuck."}
2. **{Section title}** ({minutes})
   {Takeaway.}
... 5–8 sections total

## Watch

{YouTube embed — block of HTML, or placeholder like `<!-- YOUTUBE: TBD -->` until recorded}

## Discuss in class

Two or three discussion prompts that the live Mon/Wed session uses to apply the lecture to current sprint work.

## Further reading

Links to companion cheat sheets, external references (refactoring.guru, EIP catalog, Perfect Framework doc), Anthropic docs for CC capabilities.
```

**Why this shape:**
- The **outline is the recording script.** Instructor writes it, records from it, students read it as a navigable index of the video. One artifact, three uses.
- The **takeaways under each outline item are the "lecture notes" layer.** 1-2 sentences per section, no more. Reference detail goes into the cheat sheet, not here.
- **Vernacular tags up top** make the LLM grader's job on reflections trivial — every reflection is supposed to apply ≥1 term from the lecture, and this list is the explicit menu.
- **Companion cheat sheet links** mean students never have to wonder where the deep reference lives.
- **No full transcripts.** YouTube auto-captions are sufficient for accessibility. Authoring transcripts is high cost / low marginal value.

### What we need (lecture spine)

13 lecture pages, one per week. Authoring effort per page: ~80–150 lines of structured markdown.

| W | Topic | Status | Authoring blocker |
|---|---|---|---|
| 1 | Course intro · Agile v2 · Perfect Framework · vernacular tour | ❌ | Pairs with 3 W1-critical cheat sheets — write together |
| 2 | HTML/CSS/JS refresh · Job Pack kickoff · class LLM endpoint primer | ❌ | Cheat sheets exist (`html.md`/`css.md`/`typescript.md`); needs `llm-endpoint-usage.md` |
| 3 | Frameworks survey · GoF Creational | ❌ | Pairs with 2 new cheat sheets |
| 4 | Node + REST + auth · GoF Structural | ❌ | Partial cheat-sheet coverage; needs `auth.md`, `gof-structural.md` |
| 5 | SQL + document stores + DB versioning · GoF Behavioral | ❌ | `sql.md` exists; needs 3 more cheat sheets |
| 6 | EIPs Part 1 — channels, message construction | ❌ | Pairs with `eips-part1...md` |
| 7 | EIPs Part 2 — routing, transformation · state charts | ❌ | Pairs with 2 new cheat sheets |
| 8 | Realtime web — MQTT, WebSockets, GraphQL subscriptions | ❌ | Pairs with realtime cheat sheet(s) |
| 9 | PRPL · service workers · offline-first | ⚠️ partial | `shadow-dom-pwa.md` covers PWA; needs `offline-first-sync.md` |
| 10 | Perfect Framework deep-dive | ❌ | Pairs with 4 concern cheat sheets |
| 11 | Advanced web platform | ❌ | Pairs with 1-3 new cheat sheets |
| 12 | PKI · OWASP · security review | ❌ | Pairs with 3 new cheat sheets |
| 13 | CI/CD · observability · production-readiness | ❌ | Pairs with 2-3 new cheat sheets |

**Coupling:** Authoring a lecture outline forces clarity about what the cheat sheet must contain (and vice versa). Best to write each lecture page + companion cheat sheet(s) as one unit of work, not two separate sweeps.

### What we could generate (lecture-side bonuses)

1. **Auto-extracted YouTube chapter markers from outlines.** If the outline has section start times, generating YouTube chapter timestamps is mechanical. Better viewer experience.
2. **Per-lecture quiz questions for self-check.** 3-5 questions per lecture, auto-graded, optional ungraded check. Could be a Canvas quiz instead of a wiki page.
3. **Slide deck templates.** Some instructors prefer slides-while-recording. A template that mirrors the outline structure would reduce setup time.
4. **Q&A archive per lecture.** As students ask in the live discussion, append the questions and answers to the lecture page. Compounds value over years.

### Generator implications (course_builder)

A 14th content type (`lectures/`) under `content/2026/`, treated like pages with extra metadata:

```yaml
lectures:
  - slug: w01-intro
    week: 1
    title: "Course Intro · Agile v2 · Perfect Framework · Vernacular"
    body: lectures/w01-intro.md
    youtube_id: TBD                  # filled in after recording
    companion_sheets: [agile-v2, perfect-framework, vernacular-index]
    reflection_assignment: reflection-w01
    vernacular_tags:                 # surfaces in the LLM grader's prompts
      - "Agile Manifesto v2"
      - "Perfect Framework: Scale"
      ...
```

Generator changes:
- New `Lecture` model (similar to `WikiPage` but with the metadata above).
- Loader extends `course_loader.dart` to read `lectures:` array.
- Emitter renders to a Canvas wiki page with the YouTube embed slot, sheet links, and reflection link auto-populated.
- A new "Lecture Spine" module is created that lists all 13 lecture pages.
- ~150–200 lines of generator code total. One self-contained task.

### Recommended sequencing

1. Land the 3 generator changes from §D plus the lecture-page support above (one combined task).
2. Author **W1 lecture page + W1's 3 cheat sheets** as the first end-to-end demo (lecture page, companion sheets, reflection rubric all working together). This is the proof-of-concept for the model.
3. From there, move week-by-week (W2 + cheat sheets, W3 + cheat sheets, etc.). One week per ~half-day of authoring is realistic.
4. Records videos on the same cadence — outline written Sun, video recorded Mon for the Wed class.

The course can ship Week 1 with only the W1 lecture page + 3 W1 cheat sheets + the existing 6 cheat sheets. Everything else can land just-in-time.

---

## F. Open questions

- **Single sheet vs. multiple per week?** W11 lists WebRTC, USB, Bluetooth, Camera — that's a lot of distinct APIs. One merged sheet (~600 lines) or four small ones? Same question for W8 realtime and W12 security.
- **Do CC artifact briefs need their own cheat sheets?** The brief itself documents what to build; a CC-capability sheet might overlap. Probably one shared `claude-code-capabilities.md` sheet covers it.
- **Spec coverage for vernacular reinforcement** — every cheat sheet should explicitly tag the GoF / EIP / Perfect Framework / CC vocabulary it touches, so students see the labels in the wild. Worth adopting as a style rule for new sheets.
- **Maintenance** — cheat sheets rot. Each year's content/2026/ → content/2027/ cycle should re-review them, especially anything tied to specific tool versions (Node, Postgres, framework majors).
