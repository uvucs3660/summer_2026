# cs3540-lectures

Netlify site for CS 3540 lecture playback and instructor narration recording.
Production URL: **https://cs3540-lectures.netlify.app**

Deck content (slides, TTS scripts) is generated elsewhere by
`tools/course_builder` into `content/cs3540/2026/lectures/slides/_lectures`;
this site serves it, records narration takes over the top, and tracks
per-student listening progress.

## Roles

- **Anonymous visitor** — can open the landing page and `/player`, browse
  decks, view slides, and listen to any deck's TTS or recorded audio. No
  sign-in required to consume content.
- **Signed-in student** — signs in with GitHub via `/api/auth/login`
  (`GET /api/me` returns `{ handle, admin: false }`). Signing in enables
  progress tracking: the player beacons `deck`/`slide`/`seconds`/
  `playback_rate` to `POST /api/progress` every 15s of playback, recorded
  against the student's GitHub handle.
- **Instructor (`hunterino`)** — the only handle listed in `ADMIN_HANDLES`.
  `GET /api/me` returns `admin: true` for this handle, which is what gates
  `/studio`: the studio page checks `/api/me` on load and refuses to arm the
  microphone or render recording controls for anyone else.

## Commands

- `npm test` — runs the Vitest suite (`vitest run --passWithNoTests`).
- `npx tsc --noEmit` — typechecks the whole project with no emit.
- `npm run build` — runs `scripts/build.ts`, which reads deck content from
  `CONTENT_DIR` (see below), copies `web/*.html`, per-deck slide images, TTS
  MP3s, and `lectures.json` into `dist/`, and writes `dist/media/site-index.json`
  (the manifest the client and `scripts/export-viewing.ts` both read).
- `npm run deploy` — runs `scripts/deploy.sh`: `npm run build` then
  `npx netlify deploy --prod --dir dist`. This publishes functions, static
  assets, and applies any pending database migration under
  `netlify/database/migrations/` before the deploy goes live.
- `CONTENT_DIR` — environment variable overriding where `npm run build` and
  `scripts/pull-takes.ts` read/write deck content. Defaults to
  `~/code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides/_lectures`.
  Set it to point at a different semester's content directory when needed.

## Recording flow

1. Sign in as `hunterino` and open `/studio`. The instructor gate
   (`/api/me` → `admin: true`) must pass before the page arms the microphone
   or shows recording controls at all.
2. Record a take for a slide and press "keep." The browser uploads the
   audio to `POST /api/record`, which lands it in the `takes` Netlify Blobs
   store under `takes/<deck>/slide-NN.<ext>` (webm/ogg/m4a depending on what
   the browser recorded), and updates that deck's `takes/<deck>/takes.json`
   manifest plus the `takes/summary.json` recorded-slide counts that
   `/api/decks` and `/api/status` read.
3. **Archive-before-overwrite**: keeping a second take for the same slide
   does not delete the first. The prior file is copied to
   `slide-NN-takeK.<ext>` (K = 2, 3, …) *before* the new take is written to
   `slide-NN.<ext>`, so `slide-NN.<ext>` always holds the current take and
   every earlier one survives under its `-takeK` name.
4. **Recording needs no redeploy.** Takes go straight into the blob store,
   which the live functions read on every request — there is no build step
   between recording and playback. A redeploy (`npm run deploy`) is only
   needed when the underlying **slides, scripts, or TTS audio change**
   (i.e. anything that flows through `npm run build` from `CONTENT_DIR`).

## Operations

- **Mirror recorded takes to local disk**, after recording sessions and
  before semester close-out:
  ```bash
  npx tsx scripts/pull-takes.ts
  ```
  Lists every blob in the `takes` store, skips the internal summary key, and
  writes each file to `$CONTENT_DIR/audio/<deck>/recorded/<file>`. Immutable
  archive files (`slide-NN-takeK.*`) already present locally are skipped;
  the current `slide-NN.*` is always re-pulled since it can change.

- **Export viewing progress for grading**, filtered to a roster of GitHub
  handles. **Do not run this via `netlify dev:exec`** — verified 2026-09-01:
  `netlify dev:exec` (and `netlify database connect`) never resolve the
  production database. `@netlify/database` reads its connection string from
  the `NETLIFY_DB_URL` env var (or the sandboxed `Netlify.env` global that
  only exists inside a real deployed Function invocation); `dev:exec` spawns
  a plain subprocess that has neither, and `netlify database status` /
  `netlify database connect --json` both report `context: "dev"` against a
  fresh, empty, ephemeral local Postgres (a new `localhost:<port>` each
  session) — `netlify env:get NETLIFY_DB_URL` returns no value in *any*
  context because it is a runtime-injected credential, not a settable env
  var. The only way to reach the real database from a local shell is to
  copy its connection string once from the Netlify dashboard's Database
  panel (`netlify database status` prints the link, currently
  https://app.netlify.com/projects/cs3540-lectures/database) and pass it
  explicitly — never let it land in `.env`, shell history you'd share, or
  this repo:
  ```bash
  NETLIFY_DB_URL="<paste from the Database panel>" \
    npx tsx scripts/export-viewing.ts \
    --roster <semester>/roster/github-handles.txt \
    --index dist/media/site-index.json \
    --out <semester>/grading/viewing-$(date +%F).json
  ```
  Reads `deck_progress` (the view over `view_events`) and writes one JSON
  document keyed by handle → deck with slides touched, seconds listened,
  and percent of slides seen — only for handles present in the roster file.

- **Semester close-out**: run the export above one final time (same
  explicit `NETLIFY_DB_URL=` pattern — never via `dev:exec`), then purge
  the view-events table so the next semester starts clean:
  ```bash
  NETLIFY_DB_URL="<paste from the Database panel>" \
    npx tsx -e "import('@netlify/database').then(async m => { await m.getDatabase().sql\`TRUNCATE view_events\`; console.log('view_events truncated'); })"
  ```

- **FERPA rule**: rosters, exports, and any dump containing student handles
  or listening data must never enter this repo — not as a committed file,
  not staged, not in a branch. Exports go to the semester directory's
  `grading/` folder (a NEVER-COMMIT zone per the top-level workspace rules),
  never here.

## Provisioning

`scripts/setup.sh` performs one-time provisioning: links the Netlify site
and creates the GitHub OAuth App credentials + env vars the functions need.
Two lanes:

- **Default (GitHub App manifest flow)**: `./scripts/setup.sh` — opens a
  browser, you click through GitHub's app-manifest confirmation once, and
  the script captures the resulting client ID/secret automatically via
  `scripts/setup-app.ts`.
- **Fallback (manual credentials)**:
  `./scripts/setup.sh --client-id <id> --client-secret-stdin` — paste the
  client secret on stdin, then Ctrl-D, if you already created the GitHub App
  by hand or the manifest flow isn't available.

Either lane sets these Netlify env vars (production, deploy-preview, and
branch-deploy contexts):

| Var | Purpose |
|---|---|
| `GITHUB_CLIENT_ID` | GitHub OAuth App client ID (not secret). |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth App client secret (`--secret`, encrypted). |
| `SESSION_SECRET` | Random 32-byte hex key (`openssl rand -hex 32`) used to HMAC-sign session cookies (`--secret`, encrypted). |
| `ADMIN_HANDLES` | Comma-free single handle (currently `hunterino`) permitted to see `admin: true` from `/api/me` and use `/studio`. |

Run with `--force` to overwrite already-set env vars (the script otherwise
refuses if `GITHUB_CLIENT_ID` is already present, to avoid silently
rotating live credentials).

### Local development

`netlify dev` runs the full stack locally (static pages, functions, and an
emulated Postgres database for `@netlify/database`), but the local database
starts empty — before the DB-backed endpoints (`/api/progress` and anything
using `deck_progress`/`view_events`) will work locally, run the migration
once:

```bash
npx netlify database migrations apply
```

This is a one-time step per local checkout (or after `.netlify/` is wiped);
`netlify dev` does not auto-apply pending migrations.

Local dev secrets (`GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`,
`SESSION_SECRET`, `ADMIN_HANDLES`) live in a gitignored `.env` file at the
repo root — `netlify dev` loads it automatically. Never commit `.env`; it is
already listed in `.gitignore`.
