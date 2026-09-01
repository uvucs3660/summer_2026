# CS 3540 Lecture Site on Netlify — design

**Date:** 2026-09-01
**Status:** approved approach (Approach C: full app on Netlify, admin = GitHub handle)
**Repo:** `~/code/uvu/tools/lecture-site/` (new; PII-free by construction, own git repo per workspace rules)
**Predecessor:** local `studio-server.ts` + `web/studio.html` + `web/player.html` in
`~/code/fivex/mod_node/modules/lecture/` (stays untouched and runnable; this project ports its UX to Netlify)

## Goal

Publish the CS 3540 lecture player and recording studio as one Netlify site:

- **Students** browse decks and listen to narrated slides without signing in. Signing in with
  GitHub makes their viewing count toward participation credit.
- **Admin** (`hunterino`) gets the studio: record a take in the browser, keep it, and it is live
  for students immediately — no redeploy.
- **Viewing history feeds grading**, so identity is proven by GitHub OAuth (never a typed-in or
  client-supplied handle) and the records follow the workspace's FERPA lifecycle.

## Decisions already made (with Michael)

1. **Approach C** — studio lives on Netlify too; editing is not a separate local-only workflow.
2. **Admin model** — same GitHub OAuth as students; `handle === hunterino` (via `ADMIN_HANDLES`
   env var) unlocks the studio API. No separate credentials.
3. **Content gate** — none. Slides/audio are publicly reachable; login is only required to *earn
   credit* (and to record).
4. **Audio source of truth** — **Netlify Blobs is canonical** for recorded takes. A `pull-takes`
   script mirrors Blobs → the local `_lectures/` tree for backup and close-out.
5. **Tracking store** — **Netlify DB** (`@netlify/database`, zero-config Postgres) with SQL
   migrations in-repo. Export to the semester grading dir at grading time; purge at close-out.

## Topology

One Netlify site, deployed by CLI (`netlify deploy --prod`) from a locally built `dist/` — not
git-linked, because slide/script content is assembled from `course_builder/content/`, which lives
outside this repo.

```
tools/lecture-site/
├── netlify.toml
├── package.json                     (TypeScript, esbuild via Netlify's default bundler)
├── netlify/
│   ├── functions/
│   │   ├── auth-login.ts            GET  /api/auth/login
│   │   ├── auth-callback.ts         GET  /api/auth/callback
│   │   ├── auth-logout.ts           POST /api/auth/logout
│   │   ├── me.ts                    GET  /api/me
│   │   ├── takes.ts                 GET  /api/takes/<deck> · PUT /api/takes/<deck>/<slide>
│   │   ├── audio.ts                 GET  /api/audio/<deck>/<slide>
│   │   └── progress.ts              POST /api/progress
│   └── database/migrations/
│       └── 001_create-view-events/migration.sql
├── src/lib/                         shared: session cookie, blob keys, take archiving
├── web/
│   ├── index.html                   deck list (links into player; "Sign in" affordance)
│   ├── player.html                  ported from mod_node player.html
│   └── studio.html                  ported from mod_node studio.html
├── scripts/
│   ├── setup.sh                     one-time: site create + GitHub App manifest flow + env vars
│   ├── build.ts                     assemble dist/ from content dir
│   ├── deploy.sh                    build + netlify deploy --prod
│   ├── pull-takes.ts                Blobs → local _lectures/ mirror
│   └── export-viewing.ts            DB → <semester>/grading/ rollup JSON (roster-filtered)
└── test/                            vitest: session, admin gate, take archiving, progress handler
```

### What is static vs. dynamic

| Piece | Where | Why |
|---|---|---|
| Deck index, per-slide script JSON, slide webps | static `dist/`, copied by `build.ts` from `content/cs3540/2026/lectures/` (`_lectures/lectures.json`, per-deck lecture JSON, `slides/`) | produced by the local pipeline (pptx→webp, script authoring); changes rarely; redeploy on change |
| TTS bootstrap audio (`stretched/slide-NN.mp3`) | static `dist/` | generated locally by the existing ElevenLabs pipeline |
| Recorded takes | **Netlify Blobs** | written from the browser studio; live immediately |
| Viewing events | **Netlify DB** | relational; grading queries |

**Audio resolution order in the player:** recorded take from Blobs if one exists for the slide,
else the static TTS mp3, else silent slide. The per-deck takes manifest (below) tells the player
which slides have recordings, so it never probes blob URLs blindly.

## Auth

Registered as a **GitHub App** via the scripted manifest flow (see Setup below); callback URL
`https://<site>.netlify.app/api/auth/callback`. The sign-in flow is byte-identical to a classic
OAuth App's web flow, so the functions don't care which kind backs the client id.

- `GET /api/auth/login` — sets a signed `state` cookie, redirects to
  `github.com/login/oauth/authorize` (no scopes needed beyond default public profile).
- `GET /api/auth/callback` — verifies `state`, exchanges the code server-side, fetches
  `GET /user` for the login handle, sets the session cookie, redirects to `/`.
- **Session cookie:** `session=<base64url(handle|issued-at)>.<hmac-sha256>`, HttpOnly, Secure,
  SameSite=Lax, Max-Age 120 days (covers the semester). Verified by every function that needs
  identity. No session table.
- `GET /api/me` — `{ handle, admin }` or `401`; the UI uses it to show sign-in state and the
  studio link.
- `POST /api/auth/logout` — clears the cookie.
- **Admin check:** `ADMIN_HANDLES` env var (comma-separated, default `hunterino`), compared
  case-insensitively against the cookie's handle.

Env vars (Netlify UI / CLI, never in code): `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`,
`SESSION_SECRET`, `ADMIN_HANDLES`.

## Studio port

`studio.html` keeps its UX wholesale: teleprompter + pacer on one clock, keyboard map,
level meter, NO SIGNAL banner, discard/undo-in-memory, unkept-take navigation guard. Only the
persistence calls change:

**The functions keep the local server's endpoint names and shapes** — the pages are driven by
`/api/decks`, `/api/status?deck=` (whose `recorded_url_base` + per-slide `file` fields already
parameterize where audio comes from), and `POST /api/record?deck=&slide=&ms=`, so preserving
those contracts means the pages port with near-zero changes:

| Local server call | Netlify implementation |
|---|---|
| `GET /api/decks` | function: static `site-index.json` (built from `lectures.json` + which decks have TTS mp3s) merged with a takes summary blob |
| `GET /api/status?deck=` | function: reads the per-deck `takes.json` blob; returns `recorded_url_base: "/api/audio/<deck>/"` |
| `POST /api/record?deck=&slide=&ms=` | function (admin-only): archive-then-write into Blobs |
| `GET /media/...` (deck JSON, webp, deck TTS mp3) | static paths in `dist/media/` |
| recorded audio (via `recorded_url_base`) | `GET /api/audio/<deck>/<file>` function streaming the blob |

### Blob layout and the keep-never-overwrites invariant

Blob store `takes`:

```
takes/<deck>/slide-NN.webm          canonical (newest kept take)
takes/<deck>/slide-NN-takeK.webm    archived earlier takes, K = 1, 2, …
takes/<deck>/takes.json             per-deck manifest: { slide: [{key, ms, kept_at}, …] }
```

`PUT /api/takes/<deck>/<slide>`:

1. Reject unless the session cookie's handle is in `ADMIN_HANDLES` (`403`).
2. Validate deck id against `^[a-z0-9][a-z0-9-]*$` and slide index against the deck's slide
   count; validate body is non-empty audio (`webm`/`ogg`/`mp4` per content-type) and ≥ 2 KB.
3. If a canonical blob exists, **copy it to the next free `-takeK` key first**, then write the
   new take to the canonical key, then update `takes.json`. The archive copy precedes the
   overwrite so a crash mid-sequence can duplicate a take but never lose one.
4. Single-writer assumption (one admin, one browser at a time) — no locking. `takes.json` is
   regenerable from a blob listing if it ever corrupts.

The studio's existing failed-upload behavior carries over: blob kept in browser memory, red
banner, `Enter` retries.

`GET /api/audio/<deck>/<slide>` streams the canonical blob with `ETag` (blob etag) and
`Cache-Control: public, max-age=0, must-revalidate` so a re-recorded slide is picked up on the
next revalidation while unchanged audio stays cached.

## Player + progress tracking

`player.html` ported as-is (speed control, slide strip), plus:

- A sign-in banner: "Signed in as `<handle>` — viewing counts" vs. "Sign in with GitHub to get
  credit". Playback works either way.
- When signed in, the player POSTs beacons to `/api/progress` **on slide change and every 15
  seconds while audio plays** (and on `pagehide` via `navigator.sendBeacon`):
  `{ deck, slide, seconds, playback_rate }` (field names match the `view_events` columns).
- `progress.ts` takes the handle **only from the verified cookie** (a handle in the body is
  ignored), stamps server time, validates deck/slide/seconds bounds (`seconds` ≤ 20 per
  beacon; nonconforming beacons dropped with `400`), inserts a row. Unauthenticated → `401`,
  player silently stops beaconing.

## Database

Migration `001_create-view-events`:

```sql
CREATE TABLE view_events (
  id            BIGSERIAL PRIMARY KEY,
  handle        TEXT NOT NULL,
  deck          TEXT NOT NULL,
  slide         INT  NOT NULL,
  seconds       REAL NOT NULL,
  playback_rate REAL NOT NULL DEFAULT 1.0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX view_events_handle_deck_idx ON view_events (handle, deck);

CREATE VIEW deck_progress AS
  SELECT handle, deck,
         COUNT(DISTINCT slide)          AS slides_touched,
         SUM(seconds)                   AS seconds_listened,
         MIN(created_at)                AS first_seen,
         MAX(created_at)                AS last_seen
  FROM view_events GROUP BY handle, deck;
```

Raw events are the provenance record; rollups are derived (the view), never stored state.

## Grading export + FERPA lifecycle

- `scripts/export-viewing.ts --roster <semester>/roster/<file> --out <semester>/grading/viewing-<date>.json`
  connects with `getConnectionString()` locally, reads `deck_progress` joined against per-deck
  slide counts (completion %), **filters to roster handles**, writes JSON into the semester
  grading dir. Non-roster handles never leave the DB.
- The repo never contains student data: no roster copies, no export outputs, no DB dumps.
  `.gitignore` covers `dist/`, `.netlify/`, `.env`, and `*.local.*`.
- At semester close-out: final export into `<semester>/grading/`, then
  `TRUNCATE view_events` (documented in the README as a close-out step; `close_semester.sh`
  is not modified by this project).

## Build + deploy flow

```
scripts/build.ts:
  content dir (default ~/code/uvu/tools/course_builder/content/cs3540/2026/lectures)
    → dist/manifest.json        (from _lectures/lectures.json: decks, titles, slide counts, has-TTS)
    → dist/decks/<deck>/…       (lecture JSON script, slide webps, stretched mp3s)
    → dist/index.html, player.html, studio.html
scripts/deploy.sh: npm run build && netlify deploy --prod
```

Republish is needed only for **slides/scripts/TTS changes**; recorded audio bypasses deploys
entirely (Blobs).

## Setup (one-time, scripted — one browser click)

GitHub OAuth Apps cannot be created via API or `gh`; GitHub's only programmatic registration
path is the **GitHub App manifest flow**, and a GitHub App serves "Sign in with GitHub" using
the identical `/login/oauth/authorize` + `/login/oauth/access_token` + `GET /user` flow (users
authorize without installing). So the site registers a **GitHub App**, created by script.

`scripts/setup.sh` (idempotent; refuses to overwrite existing env vars without `--force`):

1. `netlify sites:create` (or `netlify link` if the site exists) → capture the site URL.
2. Start a localhost listener; open a page that auto-submits the app manifest
   (`name: cs3540-lectures`, `redirect_url: localhost listener`,
   `callback_urls: [<site>/api/auth/callback]`, `public: true`, webhook inactive, no
   permissions) to `https://github.com/settings/apps/new`.
3. Michael clicks the single **Create GitHub App** button; GitHub redirects back to the
   listener with a temporary code.
4. `gh api -X POST /app-manifests/<code>/conversions` → `client_id`, `client_secret`
   (pem/webhook_secret are discarded — unused).
5. Generate `SESSION_SECRET` via `openssl rand -hex 32`; set `ADMIN_HANDLES=hunterino`.
6. Push all four env vars with `netlify env:set`; print nothing secret to the terminal beyond
   confirmation.

Fallback lane (if the manifest flow ever misbehaves): create a classic OAuth App by hand and
run `scripts/setup.sh --client-id X --client-secret-stdin` to do steps 5–6 only.

Then `npm install` (includes `@netlify/database`, `@netlify/blobs`, `@netlify/functions`);
first deploy provisions the database and applies the migration.

## Testing

- **Unit (vitest):** session cookie sign/verify/expiry/tamper; admin gate (allowed, denied,
  case-insensitivity); take archiving sequence against a mocked blob store (first take, second
  take archives first, crash-window duplication is safe, `takes.json` update); progress handler
  (cookie-derived handle, body-handle ignored, bounds validation, 401 path).
- **Integration:** `netlify dev` emulates Functions + Blobs + DB locally; a scripted smoke:
  OAuth mocked via a test-only signed cookie, PUT a take, GET audio, POST progress, query the
  row.
- **Manual before first class use:** real OAuth round-trip on the deployed site, record one
  take in Chrome, hear it in the player from another browser, see the row in `deck_progress`.

## Non-goals

- No content gating (public slides/audio) — revisit only if Michael asks.
- No editing of slide images or script text in the browser — those stay in the local pipeline.
- No multi-admin concurrency handling.
- No changes to `mod_node/modules/lecture/` — the local studio remains as-is.
