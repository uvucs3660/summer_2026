# CS 3540 Lecture Site (Netlify) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the CS 3540 lecture player + recording studio as one Netlify site with GitHub OAuth sign-in, admin-gated recording into Netlify Blobs, and viewing-progress tracking in Netlify DB.

**Architecture:** Static `dist/` (pages + slide webps + deck script JSON + TTS mp3s under `/media/`) assembled by a build script from the course content dir; seven Netlify Functions that preserve the local `studio-server.ts` endpoint contracts (`/api/decks`, `/api/status`, `/api/record`) plus auth (`/api/auth/*`, `/api/me`), blob-streamed audio (`/api/audio/:deck/:file`), and progress beacons (`/api/progress`). Recorded takes live in the `takes` blob store (archive-before-overwrite); viewing events in Postgres via `@netlify/database`.

**Tech Stack:** TypeScript (strict, ESM), Netlify Functions v2 (`Request`/`Response`), `@netlify/blobs`, `@netlify/database`, vitest, `tsx` for scripts. No frontend framework — the pages are self-contained HTML ported from `~/code/fivex/mod_node/modules/lecture/web/`.

**Spec:** `docs/superpowers/specs/2026-09-01-lecture-site-netlify-design.md`

## Global Constraints

- **FERPA:** No student data in this repo, ever — no rosters, no export outputs, no DB dumps. `.gitignore` must cover `dist/`, `.netlify/`, `.env`, `*.local.*`.
- **Identity:** the handle used for progress rows comes ONLY from the verified session cookie — never from a request body or query param.
- **Never lose audio:** archive-copy the canonical take blob BEFORE writing a new canonical. Nothing ever deletes a take blob.
- **Endpoint contracts:** `/api/decks`, `/api/status?deck=`, `POST /api/record?deck=&slide=&ms=` keep the local server's request/response shapes (client fields used: `decks[].id/file/has_audio/recorded_slides`, `status.recorded_count/recorded_url_base/slides[].recorded/.file`).
- **Env vars** (already set on the site, production context): `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `SESSION_SECRET`, `ADMIN_HANDLES=hunterino`. Session max age: 120 days. Admin comparison case-insensitive.
- **Validation floors:** deck id `^[a-z0-9][a-z0-9-]{0,63}$`; audio take ≥ 2048 bytes; content types `audio/webm|audio/ogg|audio/mp4` (+ codec suffixes); progress beacon `seconds` in (0, 20], `slide` integer 1–300, `playback_rate` 0.25–4.
- **Content dir** (build input): `~/code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides/_lectures` — contains `lectures.json`, `<deck>.json`, `<deck>.mp3`, `slides/<deck>/slide-NN.webp`, `audio/` (NOT copied to dist).
- Site: `cs3540-lectures` (`https://cs3540-lectures.netlify.app`), already linked in this repo dir.
- The user-facing repo standard: production-ready code only — no stubs, no TODOs, no silent error swallowing (surface failures in UI/HTTP status).

---

### Task 1: Project scaffold

**Files:**
- Create: `package.json`, `tsconfig.json`, `vitest.config.ts`, `netlify.toml`, `.gitignore`

**Interfaces:**
- Produces: npm scripts `test`, `typecheck`, `build`, `deploy`; TS config all later tasks compile under; `dist/` as publish dir, `netlify/functions` as functions dir.

- [ ] **Step 1: Write config files**

`package.json`:
```json
{
  "name": "lecture-site",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "vitest run",
    "typecheck": "tsc --noEmit",
    "build": "tsx scripts/build.ts",
    "deploy": "bash scripts/deploy.sh"
  }
}
```

`tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true,
    "types": ["node"]
  },
  "include": ["src", "netlify/functions", "scripts", "test"]
}
```

`vitest.config.ts`:
```ts
import { defineConfig } from "vitest/config";
export default defineConfig({ test: { include: ["test/**/*.test.ts"] } });
```

`netlify.toml`:
```toml
[build]
  publish = "dist"

[functions]
  node_bundler = "esbuild"

[dev]
  framework = "#static"
  publish = "dist"
```

`.gitignore`:
```
node_modules/
dist/
.netlify/
.env
*.local.*
```

- [ ] **Step 2: Install dependencies (latest)**

Run: `npm install @netlify/blobs @netlify/database @netlify/functions && npm install -D typescript tsx vitest @types/node`

- [ ] **Step 3: Verify toolchain**

Run: `npx tsc --noEmit && npx vitest run`
Expected: tsc exits 0 (nothing to compile yet); vitest reports "No test files found" — passing exit is fine at this point (`vitest run --passWithNoTests` if it exits non-zero).

- [ ] **Step 4: Commit**

```bash
git add package.json package-lock.json tsconfig.json vitest.config.ts netlify.toml .gitignore
git commit -m "chore: scaffold TypeScript + Netlify project"
```

---

### Task 2: Session library (`src/lib/session.ts`)

**Files:**
- Create: `src/lib/session.ts`
- Test: `test/session.test.ts`

**Interfaces:**
- Produces:
  - `signSession(handle: string, secret: string, now?: number): string`
  - `verifySession(token: string | undefined, secret: string, maxAgeMs?: number, now?: number): { handle: string; iat: number } | null`
  - `isAdmin(handle: string, adminHandles?: string): boolean` (default `process.env.ADMIN_HANDLES ?? ""`)
  - `sessionFromRequest(req: Request, secret?: string): { handle: string; iat: number } | null` (default secret `process.env.SESSION_SECRET!`, reads `session=` cookie)
  - `sessionCookie(token: string): string` / `clearSessionCookie(): string` (HttpOnly, Secure, SameSite=Lax, Path=/, Max-Age 120d / 0)
  - `SESSION_MAX_AGE_MS = 120 * 24 * 3600 * 1000`

- [ ] **Step 1: Write the failing tests**

`test/session.test.ts`:
```ts
import { describe, expect, it } from "vitest";
import {
  clearSessionCookie, isAdmin, SESSION_MAX_AGE_MS, sessionCookie,
  sessionFromRequest, signSession, verifySession,
} from "../src/lib/session";

const SECRET = "test-secret";

describe("session sign/verify", () => {
  it("round-trips a handle", () => {
    const tok = signSession("hunterino", SECRET);
    expect(verifySession(tok, SECRET)?.handle).toBe("hunterino");
  });
  it("rejects a tampered payload", () => {
    const tok = signSession("hunterino", SECRET);
    const [payload, mac] = tok.split(".");
    const forged = Buffer.from(JSON.stringify({ h: "attacker", iat: Date.now() })).toString("base64url");
    expect(verifySession(`${forged}.${mac}`, SECRET)).toBeNull();
    expect(verifySession(`${payload}.AAAA`, SECRET)).toBeNull();
  });
  it("rejects the wrong secret", () => {
    expect(verifySession(signSession("h", SECRET), "other")).toBeNull();
  });
  it("rejects expired and future-dated tokens", () => {
    const old = signSession("h", SECRET, Date.now() - SESSION_MAX_AGE_MS - 1000);
    expect(verifySession(old, SECRET)).toBeNull();
    const future = signSession("h", SECRET, Date.now() + 3600_000);
    expect(verifySession(future, SECRET)).toBeNull();
  });
  it("rejects garbage", () => {
    expect(verifySession(undefined, SECRET)).toBeNull();
    expect(verifySession("", SECRET)).toBeNull();
    expect(verifySession("no-dot", SECRET)).toBeNull();
    expect(verifySession("a.b.c", SECRET)).toBeNull();
  });
  it("rejects a payload whose handle is not a GitHub login shape", () => {
    const tok = signSession("bad handle!", SECRET);
    expect(verifySession(tok, SECRET)).toBeNull();
  });
});

describe("isAdmin", () => {
  it("matches case-insensitively against a comma list", () => {
    expect(isAdmin("Hunterino", "hunterino")).toBe(true);
    expect(isAdmin("hunterino", " a , HUNTERINO ,b")).toBe(true);
    expect(isAdmin("student1", "hunterino")).toBe(false);
    expect(isAdmin("hunterino", "")).toBe(false);
  });
});

describe("cookies", () => {
  it("extracts the session cookie from a Request", () => {
    const tok = signSession("hunterino", SECRET);
    const req = new Request("https://x/", { headers: { cookie: `a=1; session=${tok}; b=2` } });
    expect(sessionFromRequest(req, SECRET)?.handle).toBe("hunterino");
    expect(sessionFromRequest(new Request("https://x/"), SECRET)).toBeNull();
  });
  it("serializes hardened cookie attributes", () => {
    expect(sessionCookie("tok")).toBe("session=tok; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=10368000");
    expect(clearSessionCookie()).toBe("session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0");
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `npx vitest run test/session.test.ts`
Expected: FAIL — cannot resolve `../src/lib/session`.

- [ ] **Step 3: Implement**

`src/lib/session.ts`:
```ts
import { createHmac, timingSafeEqual } from "node:crypto";

export const SESSION_MAX_AGE_MS = 120 * 24 * 3600 * 1000;
const HANDLE_RE = /^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$/;

export interface Session { handle: string; iat: number; }

function mac(payload: string, secret: string): Buffer {
  return createHmac("sha256", secret).update(payload).digest();
}

export function signSession(handle: string, secret: string, now = Date.now()): string {
  const payload = Buffer.from(JSON.stringify({ h: handle, iat: now })).toString("base64url");
  return `${payload}.${mac(payload, secret).toString("base64url")}`;
}

export function verifySession(
  token: string | undefined, secret: string,
  maxAgeMs = SESSION_MAX_AGE_MS, now = Date.now(),
): Session | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 2 || !parts[0] || !parts[1]) return null;
  const expect = mac(parts[0], secret);
  const got = Buffer.from(parts[1], "base64url");
  if (got.length !== expect.length || !timingSafeEqual(got, expect)) return null;
  let obj: unknown;
  try { obj = JSON.parse(Buffer.from(parts[0], "base64url").toString()); } catch { return null; }
  if (typeof obj !== "object" || obj === null) return null;
  const { h, iat } = obj as { h?: unknown; iat?: unknown };
  if (typeof h !== "string" || !HANDLE_RE.test(h) || typeof iat !== "number") return null;
  if (now - iat > maxAgeMs || iat > now + 60_000) return null;
  return { handle: h, iat };
}

export function isAdmin(handle: string, adminHandles = process.env.ADMIN_HANDLES ?? ""): boolean {
  return adminHandles.split(",").map((s) => s.trim().toLowerCase()).filter(Boolean)
    .includes(handle.toLowerCase());
}

export function sessionFromRequest(req: Request, secret = process.env.SESSION_SECRET ?? ""): Session | null {
  if (!secret) return null;
  const m = (req.headers.get("cookie") ?? "").match(/(?:^|;\s*)session=([^;]+)/);
  return verifySession(m?.[1], secret);
}

export function sessionCookie(token: string): string {
  return `session=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${SESSION_MAX_AGE_MS / 1000}`;
}

export function clearSessionCookie(): string {
  return "session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0";
}
```

- [ ] **Step 4: Run tests, verify pass; typecheck**

Run: `npx vitest run test/session.test.ts && npx tsc --noEmit`
Expected: all tests PASS, tsc clean.

- [ ] **Step 5: Commit**

```bash
git add src/lib/session.ts test/session.test.ts
git commit -m "feat: HMAC session cookies with admin-handle check"
```

---

### Task 3: Takes library (`src/lib/takes.ts`) + in-memory blob store

**Files:**
- Create: `src/lib/takes.ts`, `test/helpers/memory-store.ts`
- Test: `test/takes.test.ts`

**Interfaces:**
- Produces:
  - `interface TakeStore { getJSON(key: string): Promise<unknown | null>; setJSON(key: string, v: unknown): Promise<void>; getBuffer(key: string): Promise<ArrayBuffer | null>; setBuffer(key: string, data: ArrayBuffer): Promise<void>; getStream(key: string): Promise<{ body: ReadableStream; etag?: string } | null>; }`
  - `wrapNetlifyStore(store: Store): TakeStore` (adapter over `@netlify/blobs`)
  - `interface TakeRecord { file: string; ms: number; kept_at: string }`
  - `interface TakesManifest { deck: string; slides: Record<string, TakeRecord[]> }` (newest first per slide; `slides` keys are 1-based slide numbers as strings)
  - `keepTake(store: TakeStore, deck: string, slide: number, ext: string, data: ArrayBuffer, ms: number, now?: Date): Promise<{ file: string; archived: string | null }>`
  - `readManifest(store: TakeStore, deck: string): Promise<TakesManifest>`
  - `manifestKey(deck: string): string` → `takes/<deck>/takes.json`; `blobKey(deck, file)` → `takes/<deck>/<file>`; `SUMMARY_KEY = "takes/summary.json"` (blob mapping deck → recorded slide count)
  - `pad2(n: number): string`; `DECK_ID_RE`; `AUDIO_FILE_RE = /^slide-\d{2}(-take\d+)?\.(webm|ogg|m4a)$/`; `extForMime(contentType: string): "webm" | "ogg" | "m4a" | null`
  - Test helper: `class MemoryStore implements TakeStore` with public `data: Map<string, ArrayBuffer | unknown>` for assertions.

- [ ] **Step 1: Write the memory store test helper**

`test/helpers/memory-store.ts`:
```ts
import type { TakeStore } from "../../src/lib/takes";

export class MemoryStore implements TakeStore {
  json = new Map<string, unknown>();
  bufs = new Map<string, ArrayBuffer>();
  async getJSON(key: string) { return this.json.has(key) ? this.json.get(key)! : null; }
  async setJSON(key: string, v: unknown) { this.json.set(key, JSON.parse(JSON.stringify(v))); }
  async getBuffer(key: string) { return this.bufs.get(key) ?? null; }
  async setBuffer(key: string, data: ArrayBuffer) { this.bufs.set(key, data.slice(0)); }
  async getStream(key: string) {
    const buf = this.bufs.get(key);
    if (!buf) return null;
    return { body: new Blob([buf]).stream(), etag: `"${key}-${buf.byteLength}"` };
  }
}

export const bytes = (n: number, fill = 7): ArrayBuffer => new Uint8Array(n).fill(fill).buffer;
```

- [ ] **Step 2: Write the failing tests**

`test/takes.test.ts`:
```ts
import { describe, expect, it } from "vitest";
import {
  AUDIO_FILE_RE, blobKey, DECK_ID_RE, extForMime, keepTake,
  manifestKey, readManifest, SUMMARY_KEY, type TakesManifest,
} from "../src/lib/takes";
import { bytes, MemoryStore } from "./helpers/memory-store";

const DECK = "w02-game-the-loop";

describe("validation helpers", () => {
  it("deck ids", () => {
    expect(DECK_ID_RE.test(DECK)).toBe(true);
    expect(DECK_ID_RE.test("../etc")).toBe(false);
    expect(DECK_ID_RE.test("UPPER")).toBe(false);
  });
  it("audio file names", () => {
    expect(AUDIO_FILE_RE.test("slide-03.webm")).toBe(true);
    expect(AUDIO_FILE_RE.test("slide-03-take2.m4a")).toBe(true);
    expect(AUDIO_FILE_RE.test("takes.json")).toBe(false);
    expect(AUDIO_FILE_RE.test("slide-3.webm")).toBe(false);
  });
  it("mime to ext", () => {
    expect(extForMime("audio/webm;codecs=opus")).toBe("webm");
    expect(extForMime("audio/ogg")).toBe("ogg");
    expect(extForMime("audio/mp4")).toBe("m4a");
    expect(extForMime("text/html")).toBeNull();
  });
});

describe("keepTake", () => {
  it("first take: writes canonical blob + manifest + summary, no archive", async () => {
    const store = new MemoryStore();
    const res = await keepTake(store, DECK, 3, "webm", bytes(5000), 12000);
    expect(res).toEqual({ file: "slide-03.webm", archived: null });
    expect(store.bufs.has(blobKey(DECK, "slide-03.webm"))).toBe(true);
    const man = (await store.getJSON(manifestKey(DECK))) as TakesManifest;
    expect(man.slides["3"][0].file).toBe("slide-03.webm");
    expect(man.slides["3"][0].ms).toBe(12000);
    expect(await store.getJSON(SUMMARY_KEY)).toEqual({ [DECK]: 1 });
  });

  it("re-record: archives the old canonical BEFORE overwriting, keeps both blobs", async () => {
    const store = new MemoryStore();
    await keepTake(store, DECK, 3, "webm", bytes(5000, 1), 12000);
    const res = await keepTake(store, DECK, 3, "webm", bytes(6000, 2), 15000);
    expect(res.archived).toBe("slide-03-take2.webm");
    const archived = await store.getBuffer(blobKey(DECK, "slide-03-take2.webm"));
    expect(new Uint8Array(archived!)[0]).toBe(1); // old audio preserved
    const canonical = await store.getBuffer(blobKey(DECK, "slide-03.webm"));
    expect(new Uint8Array(canonical!)[0]).toBe(2); // new audio canonical
    const man = (await store.getJSON(manifestKey(DECK))) as TakesManifest;
    expect(man.slides["3"].map((t) => t.file)).toEqual(["slide-03.webm", "slide-03-take2.webm"]);
  });

  it("third take archives as take3; summary counts distinct slides", async () => {
    const store = new MemoryStore();
    await keepTake(store, DECK, 3, "webm", bytes(5000), 1);
    await keepTake(store, DECK, 3, "webm", bytes(5000), 2);
    const res = await keepTake(store, DECK, 3, "m4a", bytes(5000), 3);
    expect(res.archived).toBe("slide-03-take3.webm");
    expect((await store.getJSON(manifestKey(DECK)) as TakesManifest).slides["3"][0].file).toBe("slide-03.m4a");
    await keepTake(store, DECK, 7, "webm", bytes(5000), 4);
    expect(await store.getJSON(SUMMARY_KEY)).toEqual({ [DECK]: 2 });
  });

  it("readManifest tolerates a corrupt manifest by starting fresh", async () => {
    const store = new MemoryStore();
    await store.setJSON(manifestKey(DECK), { nonsense: true });
    expect(await readManifest(store, DECK)).toEqual({ deck: DECK, slides: {} });
  });
});
```

- [ ] **Step 3: Run tests, verify they fail**

Run: `npx vitest run test/takes.test.ts`
Expected: FAIL — cannot resolve `../src/lib/takes`.

- [ ] **Step 4: Implement**

`src/lib/takes.ts`:
```ts
import type { Store } from "@netlify/blobs";

export const DECK_ID_RE = /^[a-z0-9][a-z0-9-]{0,63}$/;
export const AUDIO_FILE_RE = /^slide-\d{2}(-take\d+)?\.(webm|ogg|m4a)$/;
export const SUMMARY_KEY = "takes/summary.json";

export const pad2 = (n: number): string => String(n).padStart(2, "0");
export const manifestKey = (deck: string): string => `takes/${deck}/takes.json`;
export const blobKey = (deck: string, file: string): string => `takes/${deck}/${file}`;

export function extForMime(contentType: string): "webm" | "ogg" | "m4a" | null {
  const base = contentType.split(";")[0].trim().toLowerCase();
  if (base === "audio/webm") return "webm";
  if (base === "audio/ogg") return "ogg";
  if (base === "audio/mp4") return "m4a";
  return null;
}

export interface TakeRecord { file: string; ms: number; kept_at: string; }
export interface TakesManifest { deck: string; slides: Record<string, TakeRecord[]>; }

export interface TakeStore {
  getJSON(key: string): Promise<unknown | null>;
  setJSON(key: string, v: unknown): Promise<void>;
  getBuffer(key: string): Promise<ArrayBuffer | null>;
  setBuffer(key: string, data: ArrayBuffer): Promise<void>;
  getStream(key: string): Promise<{ body: ReadableStream; etag?: string } | null>;
}

export function wrapNetlifyStore(store: Store): TakeStore {
  return {
    getJSON: async (key) => (await store.get(key, { type: "json" })) ?? null,
    setJSON: (key, v) => store.setJSON(key, v),
    getBuffer: async (key) => (await store.get(key, { type: "arrayBuffer" })) ?? null,
    setBuffer: async (key, data) => { await store.set(key, data); },
    getStream: async (key) => {
      const res = await store.getWithMetadata(key, { type: "stream" });
      if (!res || !res.data) return null;
      return { body: res.data, etag: res.etag };
    },
  };
}

export async function readManifest(store: TakeStore, deck: string): Promise<TakesManifest> {
  const raw = await store.getJSON(manifestKey(deck));
  if (typeof raw === "object" && raw !== null && typeof (raw as TakesManifest).slides === "object"
      && (raw as TakesManifest).slides !== null) {
    return { deck, slides: (raw as TakesManifest).slides };
  }
  return { deck, slides: {} };
}

export async function keepTake(
  store: TakeStore, deck: string, slide: number, ext: string,
  data: ArrayBuffer, ms: number, now = new Date(),
): Promise<{ file: string; archived: string | null }> {
  const file = `slide-${pad2(slide)}.${ext}`;
  const manifest = await readManifest(store, deck);
  const arr = manifest.slides[String(slide)] ?? [];
  let archived: string | null = null;

  if (arr.length > 0) {
    const cur = arr[0];
    const buf = await store.getBuffer(blobKey(deck, cur.file));
    if (buf) {
      const curExt = cur.file.slice(cur.file.lastIndexOf(".") + 1);
      archived = `slide-${pad2(slide)}-take${arr.length + 1}.${curExt}`;
      await store.setBuffer(blobKey(deck, archived), buf); // archive BEFORE overwrite
      arr[0] = { ...cur, file: archived };
    }
  }

  await store.setBuffer(blobKey(deck, file), data);
  manifest.slides[String(slide)] = [{ file, ms, kept_at: now.toISOString() }, ...arr];
  await store.setJSON(manifestKey(deck), manifest);

  const summary = ((await store.getJSON(SUMMARY_KEY)) ?? {}) as Record<string, number>;
  summary[deck] = Object.keys(manifest.slides).length;
  await store.setJSON(SUMMARY_KEY, summary);

  return { file, archived };
}
```

- [ ] **Step 5: Run tests, verify pass; typecheck**

Run: `npx vitest run test/takes.test.ts && npx tsc --noEmit`
Expected: PASS, tsc clean.

- [ ] **Step 6: Commit**

```bash
git add src/lib/takes.ts test/takes.test.ts test/helpers/memory-store.ts
git commit -m "feat: blob-backed take storage with archive-before-overwrite"
```

---

### Task 4: GitHub OAuth exchange + auth functions

**Files:**
- Create: `src/lib/github.ts`, `netlify/functions/auth-login.ts`, `netlify/functions/auth-callback.ts`, `netlify/functions/auth-logout.ts`, `netlify/functions/me.ts`
- Test: `test/github.test.ts`, `test/auth-functions.test.ts`

**Interfaces:**
- Consumes: `signSession`, `sessionCookie`, `clearSessionCookie`, `sessionFromRequest`, `isAdmin` from Task 2.
- Produces:
  - `exchangeCodeForHandle(code: string, clientId: string, clientSecret: string, fetchFn?: typeof fetch): Promise<string>`
  - `signState(secret: string, now?: number): string` / `verifyState(state: string | undefined, cookieVal: string | undefined, secret: string, now?: number): boolean` (10-minute nonce; cookie `oauth_state`)
  - `handleCallback(req: Request, deps: { exchange: typeof exchangeCodeForHandle }): Promise<Response>` (exported for tests)
  - Routes: `GET /api/auth/login`, `GET /api/auth/callback`, `POST /api/auth/logout`, `GET /api/me` → `{ handle, admin }` or 401.

- [ ] **Step 1: Write failing tests for the exchange + state helpers**

`test/github.test.ts`:
```ts
import { describe, expect, it } from "vitest";
import { exchangeCodeForHandle, signState, verifyState } from "../src/lib/github";

const okJson = (obj: unknown) => new Response(JSON.stringify(obj), { status: 200, headers: { "Content-Type": "application/json" } });

describe("exchangeCodeForHandle", () => {
  it("exchanges code then fetches the login", async () => {
    const calls: string[] = [];
    const fetchFn = (async (url: RequestInfo | URL, init?: RequestInit) => {
      calls.push(String(url));
      if (String(url).includes("access_token")) {
        expect(JSON.parse(String(init!.body))).toMatchObject({ code: "c0de", client_id: "id", client_secret: "sec" });
        return okJson({ access_token: "tok123" });
      }
      expect((init!.headers as Record<string, string>).Authorization).toBe("Bearer tok123");
      return okJson({ login: "hunterino" });
    }) as typeof fetch;
    expect(await exchangeCodeForHandle("c0de", "id", "sec", fetchFn)).toBe("hunterino");
    expect(calls).toEqual(["https://github.com/login/oauth/access_token", "https://api.github.com/user"]);
  });
  it("throws on exchange error payloads", async () => {
    const fetchFn = (async () => okJson({ error: "bad_verification_code" })) as typeof fetch;
    await expect(exchangeCodeForHandle("x", "id", "sec", fetchFn)).rejects.toThrow(/bad_verification_code/);
  });
  it("throws on non-200 responses", async () => {
    const fetchFn = (async () => new Response("nope", { status: 502 })) as typeof fetch;
    await expect(exchangeCodeForHandle("x", "id", "sec", fetchFn)).rejects.toThrow(/502/);
  });
});

describe("state nonce", () => {
  it("round-trips and rejects mismatch/expiry", () => {
    const s = signState("sec");
    expect(verifyState(s, s, "sec")).toBe(true);
    expect(verifyState(s, signState("sec"), "sec")).toBe(false);
    expect(verifyState(s, s, "other")).toBe(false);
    const old = signState("sec", Date.now() - 11 * 60_000);
    expect(verifyState(old, old, "sec")).toBe(false);
  });
});
```

- [ ] **Step 2: Run, verify fail** — `npx vitest run test/github.test.ts` → cannot resolve module.

- [ ] **Step 3: Implement `src/lib/github.ts`**

```ts
import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";

export async function exchangeCodeForHandle(
  code: string, clientId: string, clientSecret: string, fetchFn: typeof fetch = fetch,
): Promise<string> {
  const tokenRes = await fetchFn("https://github.com/login/oauth/access_token", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code }),
  });
  if (!tokenRes.ok) throw new Error(`token exchange failed: HTTP ${tokenRes.status}`);
  const tok = (await tokenRes.json()) as { access_token?: string; error?: string };
  if (!tok.access_token) throw new Error(`token exchange error: ${tok.error ?? "no access_token"}`);

  const userRes = await fetchFn("https://api.github.com/user", {
    headers: {
      Authorization: `Bearer ${tok.access_token}`,
      Accept: "application/vnd.github+json",
      "User-Agent": "cs3540-lectures",
    },
  });
  if (!userRes.ok) throw new Error(`user fetch failed: HTTP ${userRes.status}`);
  const user = (await userRes.json()) as { login?: string };
  if (!user.login) throw new Error("GitHub /user response had no login");
  return user.login;
}

export function signState(secret: string, now = Date.now()): string {
  const payload = `${randomBytes(12).toString("base64url")}.${now}`;
  const mac = createHmac("sha256", secret).update(payload).digest("base64url");
  return `${payload}.${mac}`;
}

export function verifyState(
  state: string | undefined, cookieVal: string | undefined, secret: string, now = Date.now(),
): boolean {
  if (!state || !cookieVal || state !== cookieVal) return false;
  const parts = state.split(".");
  if (parts.length !== 3) return false;
  const expect = createHmac("sha256", secret).update(`${parts[0]}.${parts[1]}`).digest();
  const got = Buffer.from(parts[2], "base64url");
  if (got.length !== expect.length || !timingSafeEqual(got, expect)) return false;
  const ts = Number(parts[1]);
  return Number.isFinite(ts) && now - ts <= 10 * 60_000;
}
```

- [ ] **Step 4: Run, verify pass** — `npx vitest run test/github.test.ts`

- [ ] **Step 5: Write failing tests for the function handlers**

`test/auth-functions.test.ts`:
```ts
import { beforeEach, describe, expect, it } from "vitest";
import { handleCallback } from "../netlify/functions/auth-callback";
import handleMe from "../netlify/functions/me";
import handleLogin from "../netlify/functions/auth-login";
import handleLogout from "../netlify/functions/auth-logout";
import { signState } from "../src/lib/github";
import { signSession } from "../src/lib/session";

beforeEach(() => {
  process.env.SESSION_SECRET = "test-secret";
  process.env.ADMIN_HANDLES = "hunterino";
  process.env.GITHUB_CLIENT_ID = "id";
  process.env.GITHUB_CLIENT_SECRET = "sec";
});

describe("/api/auth/login", () => {
  it("redirects to GitHub with a state cookie", async () => {
    const res = await handleLogin(new Request("https://site.test/api/auth/login"));
    expect(res.status).toBe(302);
    const loc = new URL(res.headers.get("location")!);
    expect(loc.origin + loc.pathname).toBe("https://github.com/login/oauth/authorize");
    expect(loc.searchParams.get("client_id")).toBe("id");
    expect(loc.searchParams.get("redirect_uri")).toBe("https://site.test/api/auth/callback");
    expect(res.headers.get("set-cookie")).toContain("oauth_state=");
  });
});

describe("/api/auth/callback", () => {
  it("sets a session cookie for a valid code+state", async () => {
    const state = signState("test-secret");
    const req = new Request(
      `https://site.test/api/auth/callback?code=c0de&state=${encodeURIComponent(state)}`,
      { headers: { cookie: `oauth_state=${state}` } },
    );
    const res = await handleCallback(req, { exchange: async () => "hunterino" });
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("/");
    expect(res.headers.get("set-cookie")).toMatch(/^session=.+HttpOnly/s);
  });
  it("rejects state mismatch with 403 and no cookie", async () => {
    const req = new Request("https://site.test/api/auth/callback?code=c&state=evil",
      { headers: { cookie: `oauth_state=${signState("test-secret")}` } });
    const res = await handleCallback(req, { exchange: async () => "hunterino" });
    expect(res.status).toBe(403);
    expect(res.headers.get("set-cookie")).toBeNull();
  });
  it("surfaces exchange failure as 502", async () => {
    const state = signState("test-secret");
    const req = new Request(`https://site.test/api/auth/callback?code=c&state=${encodeURIComponent(state)}`,
      { headers: { cookie: `oauth_state=${state}` } });
    const res = await handleCallback(req, { exchange: async () => { throw new Error("boom"); } });
    expect(res.status).toBe(502);
  });
});

describe("/api/me", () => {
  it("returns handle+admin for a valid session", async () => {
    const tok = signSession("hunterino", "test-secret");
    const res = await handleMe(new Request("https://x/api/me", { headers: { cookie: `session=${tok}` } }));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ handle: "hunterino", admin: true });
  });
  it("401s without a session", async () => {
    expect((await handleMe(new Request("https://x/api/me"))).status).toBe(401);
  });
});

describe("/api/auth/logout", () => {
  it("clears the cookie", async () => {
    const res = await handleLogout(new Request("https://x/api/auth/logout", { method: "POST" }));
    expect(res.headers.get("set-cookie")).toContain("Max-Age=0");
  });
});
```

- [ ] **Step 6: Run, verify fail** — `npx vitest run test/auth-functions.test.ts`

- [ ] **Step 7: Implement the four functions**

`netlify/functions/auth-login.ts`:
```ts
import { signState } from "../../src/lib/github";

export default async function handleLogin(req: Request): Promise<Response> {
  const secret = process.env.SESSION_SECRET;
  const clientId = process.env.GITHUB_CLIENT_ID;
  if (!secret || !clientId) return new Response("auth not configured", { status: 500 });
  const state = signState(secret);
  const origin = new URL(req.url).origin;
  const to = new URL("https://github.com/login/oauth/authorize");
  to.searchParams.set("client_id", clientId);
  to.searchParams.set("redirect_uri", `${origin}/api/auth/callback`);
  to.searchParams.set("state", state);
  return new Response(null, {
    status: 302,
    headers: {
      Location: to.toString(),
      "Set-Cookie": `oauth_state=${state}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=600`,
    },
  });
}
export const config = { path: "/api/auth/login" };
```

`netlify/functions/auth-callback.ts`:
```ts
import { exchangeCodeForHandle, verifyState } from "../../src/lib/github";
import { sessionCookie, signSession } from "../../src/lib/session";

export async function handleCallback(
  req: Request, deps: { exchange: typeof exchangeCodeForHandle },
): Promise<Response> {
  const secret = process.env.SESSION_SECRET;
  const clientId = process.env.GITHUB_CLIENT_ID;
  const clientSecret = process.env.GITHUB_CLIENT_SECRET;
  if (!secret || !clientId || !clientSecret) return new Response("auth not configured", { status: 500 });

  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") ?? undefined;
  const cookieState = (req.headers.get("cookie") ?? "").match(/(?:^|;\s*)oauth_state=([^;]+)/)?.[1];
  if (!code || !verifyState(state, cookieState, secret)) {
    return new Response("state mismatch — restart sign-in at /api/auth/login", { status: 403 });
  }
  let handle: string;
  try {
    handle = await deps.exchange(code, clientId, clientSecret);
  } catch (err) {
    return new Response(`GitHub sign-in failed: ${String(err)}. Retry at /api/auth/login`, { status: 502 });
  }
  return new Response(null, {
    status: 302,
    headers: { Location: "/", "Set-Cookie": sessionCookie(signSession(handle, secret)) },
  });
}

export default (req: Request) => handleCallback(req, { exchange: exchangeCodeForHandle });
export const config = { path: "/api/auth/callback" };
```

`netlify/functions/auth-logout.ts`:
```ts
import { clearSessionCookie } from "../../src/lib/session";

export default async function handleLogout(_req: Request): Promise<Response> {
  return new Response(null, { status: 204, headers: { "Set-Cookie": clearSessionCookie() } });
}
export const config = { path: "/api/auth/logout" };
```

`netlify/functions/me.ts`:
```ts
import { isAdmin, sessionFromRequest } from "../../src/lib/session";

export default async function handleMe(req: Request): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response(JSON.stringify({ error: "not signed in" }), { status: 401, headers: { "Content-Type": "application/json" } });
  return new Response(JSON.stringify({ handle: session.handle, admin: isAdmin(session.handle) }),
    { status: 200, headers: { "Content-Type": "application/json" } });
}
export const config = { path: "/api/me" };
```

- [ ] **Step 8: Run all tests + typecheck** — `npx vitest run && npx tsc --noEmit` → PASS/clean.

- [ ] **Step 9: Commit**

```bash
git add src/lib/github.ts netlify/functions/auth-login.ts netlify/functions/auth-callback.ts netlify/functions/auth-logout.ts netlify/functions/me.ts test/github.test.ts test/auth-functions.test.ts
git commit -m "feat: GitHub OAuth sign-in functions with signed state + session"
```

---

### Task 5: Database migration + progress function

**Files:**
- Create: `netlify/database/migrations/001_create-view-events/migration.sql`, `netlify/functions/progress.ts`
- Test: `test/progress.test.ts`

**Interfaces:**
- Consumes: `sessionFromRequest` (Task 2).
- Produces:
  - Table `view_events(id, handle, deck, slide, seconds, playback_rate, created_at)`; view `deck_progress(handle, deck, slides_touched, seconds_listened, first_seen, last_seen)`.
  - `handleProgress(req: Request, sql: SqlTag): Promise<Response>` where `type SqlTag = (strings: TemplateStringsArray, ...vals: unknown[]) => Promise<unknown>`; default export wires `getDatabase().sql`.
  - Route: `POST /api/progress` with JSON body `{ deck, slide, seconds, playback_rate }` → 204 on insert, 401 unauthenticated, 400 invalid.

- [ ] **Step 1: Write the migration**

`netlify/database/migrations/001_create-view-events/migration.sql`:
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
         COUNT(DISTINCT slide) AS slides_touched,
         SUM(seconds)          AS seconds_listened,
         MIN(created_at)       AS first_seen,
         MAX(created_at)       AS last_seen
  FROM view_events GROUP BY handle, deck;
```

- [ ] **Step 2: Write the failing tests**

`test/progress.test.ts`:
```ts
import { beforeEach, describe, expect, it } from "vitest";
import { handleProgress, type SqlTag } from "../netlify/functions/progress";
import { signSession } from "../src/lib/session";

beforeEach(() => { process.env.SESSION_SECRET = "test-secret"; });

function fakeSql() {
  const calls: { text: string; vals: unknown[] }[] = [];
  const sql: SqlTag = async (strings, ...vals) => { calls.push({ text: strings.join("?"), vals }); return []; };
  return { sql, calls };
}

const post = (body: unknown, cookie?: string) =>
  new Request("https://x/api/progress", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });

const asUser = (h: string) => `session=${signSession(h, "test-secret")}`;
const good = { deck: "w02-game-the-loop", slide: 4, seconds: 15, playback_rate: 1.5 };

describe("/api/progress", () => {
  it("inserts a row using the COOKIE handle, ignoring any handle in the body", async () => {
    const { sql, calls } = fakeSql();
    const res = await handleProgress(post({ ...good, handle: "someone-else" }, asUser("student1")), sql);
    expect(res.status).toBe(204);
    expect(calls).toHaveLength(1);
    expect(calls[0].vals).toEqual(["student1", "w02-game-the-loop", 4, 15, 1.5]);
  });
  it("401s without a session and never touches the DB", async () => {
    const { sql, calls } = fakeSql();
    expect((await handleProgress(post(good), sql)).status).toBe(401);
    expect(calls).toHaveLength(0);
  });
  it.each([
    [{ ...good, seconds: 0 }], [{ ...good, seconds: 21 }], [{ ...good, seconds: -3 }],
    [{ ...good, slide: 0 }], [{ ...good, slide: 301 }], [{ ...good, slide: 2.5 }],
    [{ ...good, playback_rate: 9 }], [{ ...good, deck: "../evil" }], [{ ...good, deck: "" }],
  ])("400s bad payload %j", async (body) => {
    const { sql, calls } = fakeSql();
    expect((await handleProgress(post(body, asUser("s")), sql)).status).toBe(400);
    expect(calls).toHaveLength(0);
  });
  it("400s non-JSON bodies", async () => {
    const { sql } = fakeSql();
    const req = new Request("https://x/api/progress", { method: "POST", headers: { cookie: asUser("s") }, body: "not json" });
    expect((await handleProgress(req, sql)).status).toBe(400);
  });
});
```

- [ ] **Step 3: Run, verify fail** — `npx vitest run test/progress.test.ts`

- [ ] **Step 4: Implement `netlify/functions/progress.ts`**

```ts
import { getDatabase } from "@netlify/database";
import { sessionFromRequest } from "../../src/lib/session";
import { DECK_ID_RE } from "../../src/lib/takes";

export type SqlTag = (strings: TemplateStringsArray, ...vals: unknown[]) => Promise<unknown>;

export async function handleProgress(req: Request, sql: SqlTag): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response(null, { status: 401 });

  let body: unknown;
  try { body = await req.json(); } catch { return new Response("invalid JSON", { status: 400 }); }
  const { deck, slide, seconds, playback_rate } = (body ?? {}) as Record<string, unknown>;

  const ok =
    typeof deck === "string" && DECK_ID_RE.test(deck) &&
    typeof slide === "number" && Number.isInteger(slide) && slide >= 1 && slide <= 300 &&
    typeof seconds === "number" && seconds > 0 && seconds <= 20 &&
    typeof playback_rate === "number" && playback_rate >= 0.25 && playback_rate <= 4;
  if (!ok) return new Response("invalid progress payload", { status: 400 });

  await sql`INSERT INTO view_events (handle, deck, slide, seconds, playback_rate)
            VALUES (${session.handle}, ${deck}, ${slide}, ${seconds}, ${playback_rate})`;
  return new Response(null, { status: 204 });
}

export default (req: Request) => handleProgress(req, getDatabase().sql as unknown as SqlTag);
export const config = { path: "/api/progress" };
```

- [ ] **Step 5: Run tests + typecheck** — `npx vitest run && npx tsc --noEmit` → PASS/clean.

- [ ] **Step 6: Commit**

```bash
git add netlify/database/migrations/001_create-view-events/migration.sql netlify/functions/progress.ts test/progress.test.ts
git commit -m "feat: view_events migration + cookie-authenticated progress beacons"
```

---

### Task 6: Content API functions — decks, status, audio, record

**Files:**
- Create: `netlify/functions/decks.ts`, `netlify/functions/status.ts`, `netlify/functions/audio.ts`, `netlify/functions/record.ts`, `src/lib/site-index.ts`
- Test: `test/content-functions.test.ts`

**Interfaces:**
- Consumes: Task 3's `TakeStore`, `keepTake`, `readManifest`, `manifestKey`, `blobKey`, `SUMMARY_KEY`, `DECK_ID_RE`, `AUDIO_FILE_RE`, `extForMime`, `pad2`, `wrapNetlifyStore`; Task 2's `sessionFromRequest`, `isAdmin`.
- Produces:
  - `src/lib/site-index.ts`: `interface SiteIndexEntry { id: string; week: number; track: string; title: string; subtitle: string; slide_count: number; word_count: number; duration_ms: number; file: string; has_audio: boolean; has_slides: boolean; }`, `interface SiteIndex { lectures: SiteIndexEntry[] }`, `loadSiteIndex(origin: string, fetchFn?: typeof fetch): Promise<SiteIndex>` (fetches `<origin>/media/site-index.json`, throws on non-200).
  - `handleDecks(req, store: TakeStore, loadIndex: (origin: string) => Promise<SiteIndex>)` → `{ decks: (SiteIndexEntry & { recorded_slides: number })[] }`
  - `handleStatus(req, store, loadIndex)` → `{ deck, recorded_count, recorded_url_base: "/api/audio/<deck>/", slides: { slide, recorded, file, duration_ms }[] }` (array length = `slide_count`, 1-based `slide`)
  - `handleAudio(req, store, params: { deck, file })` → 200 stream with `ETag` + `Cache-Control: public, max-age=0, must-revalidate`, 304 on `If-None-Match` match, 404 unknown
  - `handleRecord(req, store, loadIndex)` → POST `?deck=&slide=&ms=`, admin-only, 200 `{ ok: true, file, archived }`; 401 unauthenticated, 403 non-admin, 400 invalid, 413 body < 2048 bytes is 400 ("too small — mic problem?")
  - Blob wiring in each default export: `wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" }))`.

- [ ] **Step 1: Write the failing tests**

`test/content-functions.test.ts`:
```ts
import { beforeEach, describe, expect, it } from "vitest";
import { handleAudio } from "../netlify/functions/audio";
import { handleDecks } from "../netlify/functions/decks";
import { handleRecord } from "../netlify/functions/record";
import { handleStatus } from "../netlify/functions/status";
import { blobKey, keepTake } from "../src/lib/takes";
import type { SiteIndex } from "../src/lib/site-index";
import { signSession } from "../src/lib/session";
import { bytes, MemoryStore } from "./helpers/memory-store";

beforeEach(() => {
  process.env.SESSION_SECRET = "test-secret";
  process.env.ADMIN_HANDLES = "hunterino";
});

const INDEX: SiteIndex = {
  lectures: [{
    id: "w02-game-the-loop", week: 2, track: "game", title: "The Loop", subtitle: "s",
    slide_count: 3, word_count: 100, duration_ms: 1000, file: "w02-game-the-loop.json",
    has_audio: true, has_slides: true,
  }],
};
const loadIndex = async () => INDEX;
const admin = () => `session=${signSession("hunterino", "test-secret")}`;
const student = () => `session=${signSession("student1", "test-secret")}`;

describe("/api/decks", () => {
  it("merges the site index with recorded counts", async () => {
    const store = new MemoryStore();
    await keepTake(store, "w02-game-the-loop", 1, "webm", bytes(5000), 900);
    const res = await handleDecks(new Request("https://x/api/decks"), store, loadIndex);
    const body = await res.json();
    expect(body.decks[0].recorded_slides).toBe(1);
    expect(body.decks[0].has_audio).toBe(true);
  });
});

describe("/api/status", () => {
  it("returns per-slide status with recorded_url_base", async () => {
    const store = new MemoryStore();
    await keepTake(store, "w02-game-the-loop", 2, "webm", bytes(5000), 900);
    const res = await handleStatus(new Request("https://x/api/status?deck=w02-game-the-loop"), store, loadIndex);
    const body = await res.json();
    expect(body.recorded_url_base).toBe("/api/audio/w02-game-the-loop/");
    expect(body.recorded_count).toBe(1);
    expect(body.slides).toHaveLength(3);
    expect(body.slides[1]).toEqual({ slide: 2, recorded: true, file: "slide-02.webm", duration_ms: 900 });
    expect(body.slides[0].recorded).toBe(false);
  });
  it("400s a bad deck id, 404s an unknown deck", async () => {
    const store = new MemoryStore();
    expect((await handleStatus(new Request("https://x/api/status?deck=../x"), store, loadIndex)).status).toBe(400);
    expect((await handleStatus(new Request("https://x/api/status?deck=nope"), store, loadIndex)).status).toBe(404);
  });
});

describe("/api/audio", () => {
  it("streams a blob with ETag and honors If-None-Match", async () => {
    const store = new MemoryStore();
    await keepTake(store, "w02-game-the-loop", 2, "webm", bytes(5000), 900);
    const params = { deck: "w02-game-the-loop", file: "slide-02.webm" };
    const res = await handleAudio(new Request("https://x/"), store, params);
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("audio/webm");
    const etag = res.headers.get("etag")!;
    const res304 = await handleAudio(new Request("https://x/", { headers: { "if-none-match": etag } }), store, params);
    expect(res304.status).toBe(304);
  });
  it("404s missing files and 400s bad names", async () => {
    const store = new MemoryStore();
    expect((await handleAudio(new Request("https://x/"), store, { deck: "w02-game-the-loop", file: "slide-09.webm" })).status).toBe(404);
    expect((await handleAudio(new Request("https://x/"), store, { deck: "w02-game-the-loop", file: "takes.json" })).status).toBe(400);
  });
});

describe("/api/record", () => {
  const put = (cookie: string | null, body = bytes(5000), qs = "deck=w02-game-the-loop&slide=2&ms=900") =>
    new Request(`https://x/api/record?${qs}`, {
      method: "POST",
      headers: { "Content-Type": "audio/webm;codecs=opus", ...(cookie ? { cookie } : {}) },
      body,
    });
  it("keeps a take for the admin", async () => {
    const store = new MemoryStore();
    const res = await handleRecord(put(admin()), store, loadIndex);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ok: true, file: "slide-02.webm", archived: null });
    expect(store.bufs.has(blobKey("w02-game-the-loop", "slide-02.webm"))).toBe(true);
  });
  it("401s anonymous, 403s non-admin", async () => {
    const store = new MemoryStore();
    expect((await handleRecord(put(null), store, loadIndex)).status).toBe(401);
    expect((await handleRecord(put(student()), store, loadIndex)).status).toBe(403);
    expect(store.bufs.size).toBe(0);
  });
  it("400s: tiny body, bad mime, bad deck, out-of-range slide", async () => {
    const store = new MemoryStore();
    expect((await handleRecord(put(admin(), bytes(100)), store, loadIndex)).status).toBe(400);
    const badMime = new Request("https://x/api/record?deck=w02-game-the-loop&slide=2&ms=1",
      { method: "POST", headers: { "Content-Type": "text/html", cookie: admin() }, body: bytes(5000) });
    expect((await handleRecord(badMime, store, loadIndex)).status).toBe(400);
    expect((await handleRecord(put(admin(), bytes(5000), "deck=../x&slide=2&ms=1"), store, loadIndex)).status).toBe(400);
    expect((await handleRecord(put(admin(), bytes(5000), "deck=w02-game-the-loop&slide=9&ms=1"), store, loadIndex)).status).toBe(400);
  });
});
```

- [ ] **Step 2: Run, verify fail** — `npx vitest run test/content-functions.test.ts`

- [ ] **Step 3: Implement `src/lib/site-index.ts`**

```ts
export interface SiteIndexEntry {
  id: string; week: number; track: string; title: string; subtitle: string;
  slide_count: number; word_count: number; duration_ms: number; file: string;
  has_audio: boolean; has_slides: boolean;
}
export interface SiteIndex { lectures: SiteIndexEntry[]; }

export async function loadSiteIndex(origin: string, fetchFn: typeof fetch = fetch): Promise<SiteIndex> {
  const res = await fetchFn(`${origin}/media/site-index.json`);
  if (!res.ok) throw new Error(`site-index.json fetch failed: HTTP ${res.status}`);
  return (await res.json()) as SiteIndex;
}
```

- [ ] **Step 4: Implement the four functions**

`netlify/functions/decks.ts`:
```ts
import { getStore } from "@netlify/blobs";
import { loadSiteIndex, type SiteIndex } from "../../src/lib/site-index";
import { SUMMARY_KEY, type TakeStore, wrapNetlifyStore } from "../../src/lib/takes";

export async function handleDecks(
  req: Request, store: TakeStore, loadIndex: (origin: string) => Promise<SiteIndex>,
): Promise<Response> {
  let index: SiteIndex;
  try { index = await loadIndex(new URL(req.url).origin); }
  catch (err) { return new Response(`deck index unavailable: ${String(err)}`, { status: 502 }); }
  const summary = ((await store.getJSON(SUMMARY_KEY)) ?? {}) as Record<string, number>;
  const decks = index.lectures.map((l) => ({ ...l, recorded_slides: summary[l.id] ?? 0 }));
  return new Response(JSON.stringify({ decks }), { status: 200, headers: { "Content-Type": "application/json" } });
}

export default (req: Request) =>
  handleDecks(req, wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" })), loadSiteIndex);
export const config = { path: "/api/decks" };
```

`netlify/functions/status.ts`:
```ts
import { getStore } from "@netlify/blobs";
import { loadSiteIndex, type SiteIndex } from "../../src/lib/site-index";
import { DECK_ID_RE, readManifest, type TakeStore, wrapNetlifyStore } from "../../src/lib/takes";

export async function handleStatus(
  req: Request, store: TakeStore, loadIndex: (origin: string) => Promise<SiteIndex>,
): Promise<Response> {
  const url = new URL(req.url);
  const deck = url.searchParams.get("deck") ?? "";
  if (!DECK_ID_RE.test(deck)) return new Response("bad deck id", { status: 400 });
  let index: SiteIndex;
  try { index = await loadIndex(url.origin); }
  catch (err) { return new Response(`deck index unavailable: ${String(err)}`, { status: 502 }); }
  const meta = index.lectures.find((l) => l.id === deck);
  if (!meta) return new Response("unknown deck", { status: 404 });

  const manifest = await readManifest(store, deck);
  const slides = Array.from({ length: meta.slide_count }, (_, i) => {
    const rec = manifest.slides[String(i + 1)]?.[0];
    return rec
      ? { slide: i + 1, recorded: true, file: rec.file, duration_ms: rec.ms }
      : { slide: i + 1, recorded: false, file: null, duration_ms: null };
  });
  const recorded_count = slides.filter((s) => s.recorded).length;
  return new Response(
    JSON.stringify({ deck, recorded_count, recorded_url_base: `/api/audio/${deck}/`, slides }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

export default (req: Request) =>
  handleStatus(req, wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" })), loadSiteIndex);
export const config = { path: "/api/status" };
```

`netlify/functions/audio.ts`:
```ts
import { getStore } from "@netlify/blobs";
import type { Context } from "@netlify/functions";
import { AUDIO_FILE_RE, blobKey, DECK_ID_RE, type TakeStore, wrapNetlifyStore } from "../../src/lib/takes";

const CONTENT_TYPES: Record<string, string> = { webm: "audio/webm", ogg: "audio/ogg", m4a: "audio/mp4" };

export async function handleAudio(
  req: Request, store: TakeStore, params: { deck: string; file: string },
): Promise<Response> {
  const { deck, file } = params;
  if (!DECK_ID_RE.test(deck) || !AUDIO_FILE_RE.test(file)) return new Response("bad path", { status: 400 });
  const found = await store.getStream(blobKey(deck, file));
  if (!found) return new Response("no such take", { status: 404 });
  const headers = new Headers({
    "Content-Type": CONTENT_TYPES[file.slice(file.lastIndexOf(".") + 1)],
    "Cache-Control": "public, max-age=0, must-revalidate",
  });
  if (found.etag) {
    headers.set("ETag", found.etag);
    if (req.headers.get("if-none-match") === found.etag) return new Response(null, { status: 304, headers });
  }
  return new Response(found.body, { status: 200, headers });
}

export default (req: Request, context: Context) =>
  handleAudio(req, wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" })), {
    deck: context.params.deck ?? "", file: context.params.file ?? "",
  });
export const config = { path: "/api/audio/:deck/:file" };
```

`netlify/functions/record.ts`:
```ts
import { getStore } from "@netlify/blobs";
import { loadSiteIndex, type SiteIndex } from "../../src/lib/site-index";
import { isAdmin, sessionFromRequest } from "../../src/lib/session";
import { DECK_ID_RE, extForMime, keepTake, type TakeStore, wrapNetlifyStore } from "../../src/lib/takes";

export async function handleRecord(
  req: Request, store: TakeStore, loadIndex: (origin: string) => Promise<SiteIndex>,
): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response("sign in first", { status: 401 });
  if (!isAdmin(session.handle)) return new Response("recording is instructor-only", { status: 403 });

  const url = new URL(req.url);
  const deck = url.searchParams.get("deck") ?? "";
  const slide = Number(url.searchParams.get("slide"));
  const ms = Number(url.searchParams.get("ms") ?? 0);
  const ext = extForMime(req.headers.get("content-type") ?? "");
  if (!DECK_ID_RE.test(deck) || !Number.isInteger(slide) || slide < 1 || !ext || !Number.isFinite(ms) || ms < 0) {
    return new Response("bad record request", { status: 400 });
  }
  let index: SiteIndex;
  try { index = await loadIndex(url.origin); }
  catch (err) { return new Response(`deck index unavailable: ${String(err)}`, { status: 502 }); }
  const meta = index.lectures.find((l) => l.id === deck);
  if (!meta || slide > meta.slide_count) return new Response("unknown deck/slide", { status: 400 });

  const data = await req.arrayBuffer();
  if (data.byteLength < 2048) return new Response("take too small — mic problem?", { status: 400 });

  const { file, archived } = await keepTake(store, deck, slide, ext, data, ms);
  return new Response(JSON.stringify({ ok: true, file, archived }),
    { status: 200, headers: { "Content-Type": "application/json" } });
}

export default (req: Request) =>
  handleRecord(req, wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" })), loadSiteIndex);
export const config = { path: "/api/record" };
```

- [ ] **Step 5: Run all tests + typecheck** — `npx vitest run && npx tsc --noEmit` → PASS/clean.

- [ ] **Step 6: Commit**

```bash
git add netlify/functions/decks.ts netlify/functions/status.ts netlify/functions/audio.ts netlify/functions/record.ts src/lib/site-index.ts test/content-functions.test.ts
git commit -m "feat: decks/status/audio/record functions preserving studio-server contracts"
```

---

### Task 7: Build + deploy scripts

**Files:**
- Create: `scripts/build.ts`, `scripts/deploy.sh`

**Interfaces:**
- Consumes: content dir layout (Global Constraints); `web/*.html` (Tasks 8–9 add them; build must not fail if `web/` files exist — this task creates placeholder-free build logic and Task 8 adds the pages, so build is run against `web/` containing whatever exists).
- Produces: `dist/` with `media/site-index.json` (the `SiteIndex` shape from Task 6), `media/lectures.json`, `media/<deck>.json`, `media/<deck>.mp3`, `media/slides/<deck>/*.webp`, every file from `web/`, and `_redirects` (`/player /player.html 200`, `/studio /studio.html 200`, `/ /index.html 200`).

- [ ] **Step 1: Implement `scripts/build.ts`**

```ts
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

const CONTENT = process.env.CONTENT_DIR
  ?? path.join(os.homedir(), "code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides/_lectures");
const OUT = path.join(process.cwd(), "dist");
const WEB = path.join(process.cwd(), "web");

interface Lecture {
  id: string; week: number; track: string; title: string; subtitle: string;
  slide_count: number; word_count: number; duration_ms: number; file: string;
}

function main(): void {
  const indexPath = path.join(CONTENT, "lectures.json");
  if (!fs.existsSync(indexPath)) {
    console.error(`lectures.json not found at ${indexPath} — set CONTENT_DIR`);
    process.exit(1);
  }
  const index = JSON.parse(fs.readFileSync(indexPath, "utf8")) as { lectures: Lecture[] };

  fs.rmSync(OUT, { recursive: true, force: true });
  fs.mkdirSync(path.join(OUT, "media", "slides"), { recursive: true });

  // pages
  for (const f of fs.readdirSync(WEB)) {
    fs.copyFileSync(path.join(WEB, f), path.join(OUT, f));
  }
  fs.writeFileSync(path.join(OUT, "_redirects"),
    "/player /player.html 200\n/studio /studio.html 200\n/ /index.html 200\n");

  // per-deck content + site index
  const lectures = index.lectures.map((l) => {
    const docSrc = path.join(CONTENT, l.file);
    if (!fs.existsSync(docSrc)) {
      console.error(`missing deck doc: ${docSrc}`);
      process.exit(1);
    }
    fs.copyFileSync(docSrc, path.join(OUT, "media", l.file));

    const mp3 = path.join(CONTENT, `${l.id}.mp3`);
    const has_audio = fs.existsSync(mp3);
    if (has_audio) fs.copyFileSync(mp3, path.join(OUT, "media", `${l.id}.mp3`));

    const slidesDir = path.join(CONTENT, "slides", l.id);
    const has_slides = fs.existsSync(slidesDir);
    if (has_slides) {
      fs.cpSync(slidesDir, path.join(OUT, "media", "slides", l.id), { recursive: true });
    }
    return { ...l, has_audio, has_slides };
  });

  fs.copyFileSync(indexPath, path.join(OUT, "media", "lectures.json"));
  fs.writeFileSync(path.join(OUT, "media", "site-index.json"),
    JSON.stringify({ lectures }, null, 2) + "\n");

  const totalMb = lectures.length; // count only; sizes reported below
  console.log(`built ${lectures.length} decks → dist/ (${lectures.filter((l) => l.has_audio).length} with TTS audio, ${lectures.filter((l) => l.has_slides).length} with slides)`);
  void totalMb;
}

main();
```

- [ ] **Step 2: Implement `scripts/deploy.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm run build
npx netlify deploy --prod --dir dist
```

Run: `chmod +x scripts/deploy.sh`

- [ ] **Step 3: Run the build against the real content dir**

Run: `npm run build && ls dist/media | head && python3 -c "import json;d=json.load(open('dist/media/site-index.json'));print(len(d['lectures']),'decks');print(d['lectures'][0])"`
Expected: deck count matches `lectures.json` (28ish); first entry shows `has_audio`/`has_slides` booleans. (`web/` may be empty at this point — if `fs.readdirSync(WEB)` throws because `web/` doesn't exist yet, create it: `mkdir -p web` and re-run; pages arrive in Task 8.)

- [ ] **Step 4: Remove the leftover `totalMb` lines** — delete the `const totalMb…` and `void totalMb;` lines (they're scaffolding noise), re-run `npm run build` to confirm, and typecheck: `npx tsc --noEmit`.

- [ ] **Step 5: Commit**

```bash
git add scripts/build.ts scripts/deploy.sh
git commit -m "feat: dist assembly from course content dir + CLI deploy"
```

---

### Task 8: Landing page + player port (auth bar, progress beacons)

**Files:**
- Create: `web/index.html`, `web/player.html` (ported from `~/code/fivex/mod_node/modules/lecture/web/player.html`)

**Interfaces:**
- Consumes: `/api/decks`, `/api/status`, `/api/me`, `/api/auth/login`, `/api/auth/logout`, `/api/progress` from Tasks 4–6; `/media/*` static paths from Task 7. Player globals that already exist in the source file: `P.deck` (deck id), `P.slide` (1-based), `audio` (the `<audio>` element), and the slide-change function that assigns `P.slide`.
- Produces: `web/index.html`, `web/player.html`.

- [ ] **Step 1: Copy the player**

Run: `mkdir -p web && cp ~/code/fivex/mod_node/modules/lecture/web/player.html web/player.html`

The player's data calls (`/api/decks`, `/api/status?deck=`, `/media/...`) already match the Netlify functions and static layout — do not change them. Recorded-take URLs come from `status.recorded_url_base`, which the status function returns as `/api/audio/<deck>/`, so recorded playback works unmodified.

- [ ] **Step 2: Add the auth bar + beacons to `web/player.html`**

(a) In the header/topbar markup (immediately inside the top control bar element), add:
```html
<span id="authbar" style="margin-left:auto; font-size:13px; opacity:.85"></span>
```

(b) At the end of the main `<script>` block, add:
```js
// ---- sign-in + viewing credit -------------------------------------------
const AUTH = { me: null };
async function initAuth(){
  try { const r = await fetch('/api/me'); AUTH.me = r.ok ? await r.json() : null; }
  catch { AUTH.me = null; }
  const el = document.getElementById('authbar');
  if (!el) return;
  if (AUTH.me) {
    el.innerHTML = 'Signed in as <b></b> — viewing counts &nbsp;<a href="#" id="signout">sign out</a>';
    el.querySelector('b').textContent = AUTH.me.handle;
    el.querySelector('#signout').onclick = async (e) => {
      e.preventDefault();
      await fetch('/api/auth/logout', { method: 'POST' });
      location.reload();
    };
  } else {
    el.innerHTML = '<a href="/api/auth/login">Sign in with GitHub</a> to get credit for viewing';
  }
}
initAuth();

let listenedSec = 0;
setInterval(() => {
  if (!AUTH.me || !P.deck || !audio.src || audio.paused) return;
  listenedSec += 1;
  if (listenedSec >= 15) flushProgress();
}, 1000);

function flushProgress(){
  if (!AUTH.me || !P.deck || listenedSec <= 0) return;
  const body = JSON.stringify({
    deck: P.deck, slide: P.slide, seconds: listenedSec,
    playback_rate: audio.playbackRate || 1,
  });
  listenedSec = 0;
  const sent = navigator.sendBeacon &&
    navigator.sendBeacon('/api/progress', new Blob([body], { type: 'application/json' }));
  if (!sent) fetch('/api/progress', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body }).catch(() => {});
}
addEventListener('pagehide', flushProgress);
```

(c) Find the single function where `P.slide` is assigned on navigation (search `P.slide =`) and insert `flushProgress();` as its first statement, so seconds accumulated on the old slide are attributed to the old slide.

- [ ] **Step 3: Write `web/index.html`**

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CS 3540 Lectures</title>
<style>
  :root { color-scheme: dark; }
  body { margin: 0; background: #14161a; color: #e8e6e3; font: 15px/1.5 system-ui, sans-serif; }
  main { max-width: 720px; margin: 0 auto; padding: 32px 20px 64px; }
  h1 { font-size: 22px; } h2 { font-size: 15px; opacity: .7; margin-top: 28px; }
  a { color: #7cb7ff; text-decoration: none; } a:hover { text-decoration: underline; }
  #auth { float: right; font-size: 13px; opacity: .85; }
  ul { list-style: none; padding: 0; } li { padding: 4px 0; }
  .meta { opacity: .6; font-size: 13px; margin-left: 6px; }
  #err { color: #ff9a9a; }
</style>
</head>
<body>
<main>
  <span id="auth"></span>
  <h1>CS 3540 — Lecture Player</h1>
  <p><a href="/player">Open the player</a><span id="studiolink"></span></p>
  <div id="err"></div>
  <div id="weeks"></div>
</main>
<script>
async function getJSON(url){
  const r = await fetch(url);
  if (!r.ok) throw new Error(url + ' -> HTTP ' + r.status);
  return r.json();
}
async function main(){
  let me = null;
  try { const r = await fetch('/api/me'); me = r.ok ? await r.json() : null; } catch {}
  const auth = document.getElementById('auth');
  if (me) {
    auth.innerHTML = 'Signed in as <b></b> · <a href="#" id="out">sign out</a>';
    auth.querySelector('b').textContent = me.handle;
    auth.querySelector('#out').onclick = async (e) => {
      e.preventDefault(); await fetch('/api/auth/logout', { method: 'POST' }); location.reload();
    };
    if (me.admin) document.getElementById('studiolink').innerHTML = ' · <a href="/studio">Recording studio</a>';
  } else {
    auth.innerHTML = '<a href="/api/auth/login">Sign in with GitHub</a> to get credit for viewing';
  }
  try {
    const { decks } = await getJSON('/api/decks');
    const byWeek = new Map();
    for (const d of decks) {
      if (!byWeek.has(d.week)) byWeek.set(d.week, []);
      byWeek.get(d.week).push(d);
    }
    const root = document.getElementById('weeks');
    for (const [week, ds] of [...byWeek.entries()].sort((a, b) => a[0] - b[0])) {
      const h = document.createElement('h2'); h.textContent = 'Week ' + week; root.appendChild(h);
      const ul = document.createElement('ul');
      for (const d of ds) {
        const li = document.createElement('li');
        const audio = d.has_audio ? '♪ narrated' : (d.recorded_slides ? '● ' + d.recorded_slides + ' recorded' : 'no audio yet');
        li.innerHTML = '<a href="/player"></a><span class="meta"></span>';
        li.querySelector('a').textContent = d.title + ' — ' + d.subtitle;
        li.querySelector('.meta').textContent = d.slide_count + ' slides · ' + audio;
        ul.appendChild(li);
      }
      root.appendChild(ul);
    }
  } catch (err) {
    document.getElementById('err').textContent = 'Could not load the deck list: ' + err.message;
  }
}
main();
</script>
</body>
</html>
```

- [ ] **Step 4: Local smoke with `netlify dev`**

Create `.env` (gitignored) for local secrets:
```bash
cat > .env <<EOF
SESSION_SECRET=dev-only-secret
ADMIN_HANDLES=hunterino
GITHUB_CLIENT_ID=Ov23lipMgk83lQ5QmSB8
EOF
```
(`GITHUB_CLIENT_SECRET` is not needed for this smoke — OAuth redirects won't round-trip on localhost because the app's callback URL is the production site. Identity is tested with a minted cookie instead.)

Run: `npm run build && npx netlify dev` then in a second shell:
```bash
TOK=$(npx tsx -e "import('./src/lib/session.ts').then(m => console.log(m.signSession('hunterino', 'dev-only-secret')))")
curl -s localhost:8888/api/decks | python3 -m json.tool | head -20
curl -s -b "session=$TOK" localhost:8888/api/me
curl -s -X POST -b "session=$TOK" -H 'Content-Type: application/json' \
  -d '{"deck":"w01-game-first-contact","slide":1,"seconds":10,"playback_rate":1}' \
  -o /dev/null -w '%{http_code}\n' localhost:8888/api/progress
```
Expected: decks JSON with `recorded_slides: 0`; `{"handle":"hunterino","admin":true}`; `204`. Open `http://localhost:8888/` and `http://localhost:8888/player` in a browser: deck list renders, slides page, TTS audio plays for a narrated deck.

- [ ] **Step 5: Commit**

```bash
git add web/index.html web/player.html
git commit -m "feat: landing page + player with sign-in bar and progress beacons"
```

---

### Task 9: Studio port

**Files:**
- Create: `web/studio.html` (ported from `~/code/fivex/mod_node/modules/lecture/web/studio.html`)

**Interfaces:**
- Consumes: `/api/me`, `/api/decks`, `/api/status?deck=`, `POST /api/record?deck=&slide=&ms=` (unchanged contract), `/media/*` static paths.
- Produces: `web/studio.html`.

- [ ] **Step 1: Copy the studio**

Run: `cp ~/code/fivex/mod_node/modules/lecture/web/studio.html web/studio.html`

Endpoints already match — `/api/decks`, `/api/status`, `/api/record`, `/media/...` all resolve on the Netlify site. Do not change the recording, teleprompter, pacer, or take-handling logic.

- [ ] **Step 2: Add the admin gate on load**

At the START of the studio's main `<script>` block (before any init/boot call), add — then wrap the existing boot call so it only runs when admitted:

```js
// ---- instructor gate ------------------------------------------------------
async function requireAdmin(){
  let me = null;
  try { const r = await fetch('/api/me'); me = r.ok ? await r.json() : null; } catch {}
  if (me && me.admin) return true;
  document.body.innerHTML =
    '<div style="max-width:520px;margin:15vh auto;font:15px/1.6 system-ui;color:#e8e6e3">' +
    '<h1 style="font-size:20px">Recording studio</h1>' +
    (me
      ? '<p>Signed in as <b>' + me.handle + '</b>, but the studio is instructor-only.</p><p><a style="color:#7cb7ff" href="/player">Go to the player</a></p>'
      : '<p>The studio needs an instructor sign-in.</p><p><a style="color:#7cb7ff" href="/api/auth/login">Sign in with GitHub</a></p>') +
    '</div>';
  return false;
}
```

Locate the studio's entry call (the statement that kicks off deck loading — search for the call to the function that does `getJSON('/api/decks')`, near the bottom of the script) and replace it with:
```js
requireAdmin().then((ok) => { if (ok) boot(); });
```
where `boot` is that existing entry function's name (use its actual name).

- [ ] **Step 3: Sharpen the upload-failure message for auth losses**

In the studio's keep/upload function (the one that does `fetch(url, { method:'POST', … })` to `/api/record`), the existing non-OK branch shows a red retry banner. Extend it: when `res.status === 401 || res.status === 403`, set the banner text to `'Session expired or not instructor — take is safe in this tab. Sign in again in another tab, then press Enter to retry.'` (keep the existing behavior — blob retained, Enter retries — untouched).

- [ ] **Step 4: Local smoke**

With `netlify dev` still running: rebuild + reload — `npm run build`, open `http://localhost:8888/studio` in a normal window (no cookie): gate page with sign-in link appears. Then in the browser devtools console set the admin cookie: `document.cookie = 'session=<TOK>; path=/'` (TOK from Task 8 Step 4) and reload: studio boots, deck strip loads. Record a short take on slide 1 of any deck (Chrome will prompt for mic on localhost), press Enter to keep: upload succeeds. Verify: `curl -s 'localhost:8888/api/status?deck=<that-deck>' | python3 -m json.tool` shows `recorded: true, file: slide-01.webm`; open `http://localhost:8888/player`, switch source to "Recorded takes", hear the take.

- [ ] **Step 5: Commit**

```bash
git add web/studio.html
git commit -m "feat: browser studio with instructor gate, uploading takes to blobs"
```

---

### Task 10: Operational scripts — pull-takes + export-viewing

**Files:**
- Create: `scripts/pull-takes.ts`, `scripts/export-viewing.ts`
- Test: `test/export-viewing.test.ts`

**Interfaces:**
- Consumes: blob key layout from Task 3 (`takes/<deck>/<file>`); `deck_progress` view from Task 5; `dist/media/site-index.json` from Task 7.
- Produces:
  - `pull-takes.ts` — mirrors the `takes` blob store into `<content-dir>/audio/<deck>/recorded/` via the Netlify CLI (`netlify blobs:list` / `netlify blobs:get`). Canonical files and `takes.json` are always re-downloaded; immutable `-takeK` archives are skipped when present.
  - `export-viewing.ts` — `buildExport(rows, rosterHandles, slideCounts): ExportDoc` (pure, tested) + CLI wrapper run under `netlify dev:exec` (which injects the DB connection). Flags: `--roster <file>` (one GitHub handle per line, `#` comments), `--index <site-index.json>`, `--out <file>`.
  - `interface ExportDoc { generated_at: string; students: Record<string, Record<string, { slides_touched: number; seconds_listened: number; slide_count: number; pct_slides: number; first_seen: string; last_seen: string }>> }`

- [ ] **Step 1: Write the failing test for the export shaping**

`test/export-viewing.test.ts`:
```ts
import { describe, expect, it } from "vitest";
import { buildExport, parseRoster } from "../scripts/export-viewing";

const rows = [
  { handle: "student1", deck: "w01-game-first-contact", slides_touched: 8, seconds_listened: 500, first_seen: "2026-09-02T10:00:00Z", last_seen: "2026-09-02T10:20:00Z" },
  { handle: "STUDENT1", deck: "w01-ai-eleven-pillars", slides_touched: 2, seconds_listened: 90, first_seen: "2026-09-03T10:00:00Z", last_seen: "2026-09-03T10:05:00Z" },
  { handle: "not-enrolled", deck: "w01-game-first-contact", slides_touched: 9, seconds_listened: 700, first_seen: "2026-09-02T10:00:00Z", last_seen: "2026-09-02T10:20:00Z" },
];
const counts = { "w01-game-first-contact": 9, "w01-ai-eleven-pillars": 7 };

describe("buildExport", () => {
  it("filters to roster handles case-insensitively and computes pct", () => {
    const doc = buildExport(rows, new Set(["student1"]), counts, new Date("2026-10-01T00:00:00Z"));
    expect(Object.keys(doc.students)).toEqual(["student1"]);
    const s1 = doc.students["student1"];
    expect(s1["w01-game-first-contact"].pct_slides).toBeCloseTo(8 / 9);
    expect(s1["w01-ai-eleven-pillars"].slides_touched).toBe(2); // case-folded onto the roster handle
    expect(doc.generated_at).toBe("2026-10-01T00:00:00.000Z");
  });
});

describe("parseRoster", () => {
  it("parses handles, skipping blanks and comments", () => {
    expect(parseRoster("# roster\nstudent1\n\n Student2 \n#x\n")).toEqual(new Set(["student1", "student2"]));
  });
});
```

- [ ] **Step 2: Run, verify fail** — `npx vitest run test/export-viewing.test.ts`

- [ ] **Step 3: Implement `scripts/export-viewing.ts`**

```ts
import * as fs from "node:fs";

export interface ProgressRow {
  handle: string; deck: string; slides_touched: number;
  seconds_listened: number; first_seen: string; last_seen: string;
}
export interface ExportDoc {
  generated_at: string;
  students: Record<string, Record<string, {
    slides_touched: number; seconds_listened: number; slide_count: number;
    pct_slides: number; first_seen: string; last_seen: string;
  }>>;
}

export function parseRoster(text: string): Set<string> {
  return new Set(
    text.split("\n").map((l) => l.trim().toLowerCase())
      .filter((l) => l && !l.startsWith("#")),
  );
}

export function buildExport(
  rows: ProgressRow[], roster: Set<string>,
  slideCounts: Record<string, number>, now = new Date(),
): ExportDoc {
  const students: ExportDoc["students"] = {};
  for (const r of rows) {
    const handle = r.handle.toLowerCase();
    if (!roster.has(handle)) continue;
    const slideCount = slideCounts[r.deck] ?? 0;
    (students[handle] ??= {})[r.deck] = {
      slides_touched: Number(r.slides_touched),
      seconds_listened: Number(r.seconds_listened),
      slide_count: slideCount,
      pct_slides: slideCount > 0 ? Number(r.slides_touched) / slideCount : 0,
      first_seen: r.first_seen,
      last_seen: r.last_seen,
    };
  }
  return { generated_at: now.toISOString(), students };
}

function arg(name: string): string {
  const i = process.argv.indexOf(name);
  if (i < 0 || !process.argv[i + 1]) {
    console.error(`usage: netlify dev:exec npx tsx scripts/export-viewing.ts --roster <file> --index dist/media/site-index.json --out <file>`);
    process.exit(1);
  }
  return process.argv[i + 1];
}

async function main(): Promise<void> {
  const { getDatabase } = await import("@netlify/database");
  const roster = parseRoster(fs.readFileSync(arg("--roster"), "utf8"));
  const index = JSON.parse(fs.readFileSync(arg("--index"), "utf8")) as
    { lectures: { id: string; slide_count: number }[] };
  const counts = Object.fromEntries(index.lectures.map((l) => [l.id, l.slide_count]));

  const sql = getDatabase().sql;
  const rows = (await sql`SELECT handle, deck, slides_touched, seconds_listened, first_seen, last_seen FROM deck_progress`) as unknown as ProgressRow[];
  const doc = buildExport(rows, roster, counts);
  fs.writeFileSync(arg("--out"), JSON.stringify(doc, null, 2) + "\n");
  console.log(`wrote ${arg("--out")}: ${Object.keys(doc.students).length} students (${rows.length} deck-progress rows scanned)`);
}

if (process.argv[1]?.endsWith("export-viewing.ts")) main();
```

- [ ] **Step 4: Run tests, verify pass** — `npx vitest run test/export-viewing.test.ts && npx tsc --noEmit`

- [ ] **Step 5: Implement `scripts/pull-takes.ts`**

```ts
import { execFileSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const CONTENT = process.env.CONTENT_DIR
  ?? path.join(os.homedir(), "code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides/_lectures");

function netlifyJSON(args: string[]): unknown {
  return JSON.parse(execFileSync("npx", ["netlify", ...args, "--json"], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 }));
}

function main(): void {
  const listed = netlifyJSON(["blobs:list", "takes"]) as { key: string }[] | { blobs: { key: string }[] };
  const keys = (Array.isArray(listed) ? listed : listed.blobs).map((b) => b.key);
  if (keys.length === 0) { console.log("no takes in the blob store yet"); return; }

  let pulled = 0, skipped = 0;
  for (const key of keys) {
    const m = key.match(/^takes\/([a-z0-9-]+)\/(.+)$/);
    if (!m) { console.error(`unexpected blob key skipped: ${key}`); continue; }
    const [, deck, file] = m;
    const destDir = path.join(CONTENT, "audio", deck, "recorded");
    const dest = path.join(destDir, file);
    const isImmutableArchive = /-take\d+\./.test(file);
    if (isImmutableArchive && fs.existsSync(dest)) { skipped++; continue; }
    fs.mkdirSync(destDir, { recursive: true });
    execFileSync("npx", ["netlify", "blobs:get", "takes", key, "--output", dest], { stdio: "inherit" });
    pulled++;
  }
  console.log(`mirrored ${pulled} blobs into ${CONTENT}/audio/*/recorded (${skipped} archives already present)`);
}

main();
```

- [ ] **Step 6: Sanity-run pull-takes against the real store**

Run: `npx netlify blobs:list takes --json` first to confirm the CLI verb and output shape on the installed netlify-cli version; adjust `netlifyJSON`'s result handling if the shape differs (the code accepts both a bare array and `{ blobs: [...] }`). Then: `npx tsx scripts/pull-takes.ts` — with an empty store it must print `no takes in the blob store yet` (or mirror whatever test takes exist from Task 9's smoke, if `netlify dev` shared the store — local dev blobs are sandboxed, so an empty production store is the expected result here).

- [ ] **Step 7: Commit**

```bash
git add scripts/pull-takes.ts scripts/export-viewing.ts test/export-viewing.test.ts
git commit -m "feat: blob mirror + roster-filtered viewing export scripts"
```

---

### Task 11: Setup script (rebuildable auth provisioning)

**Files:**
- Create: `scripts/setup.sh`, `scripts/setup-app.ts`

**Interfaces:**
- Consumes: nothing from other tasks (standalone provisioning).
- Produces: `scripts/setup.sh` with two lanes — `--client-id X --client-secret-stdin` (env-vars-only lane) and the default GitHub App manifest lane via `scripts/setup-app.ts` (localhost listener + `gh api /app-manifests/<code>/conversions`).

- [ ] **Step 1: Implement `scripts/setup-app.ts`** (manifest flow: prints creds as `CLIENT_ID=… CLIENT_SECRET=…` on stdout for setup.sh to consume)

```ts
import { execFileSync } from "node:child_process";
import * as http from "node:http";

const siteUrl = process.argv[2];
if (!siteUrl?.startsWith("https://")) {
  console.error("usage: tsx scripts/setup-app.ts https://<site>.netlify.app");
  process.exit(1);
}
const PORT = 8799;
const manifest = {
  name: "cs3540-lectures",
  url: siteUrl,
  redirect_url: `http://localhost:${PORT}/converted`,
  callback_urls: [`${siteUrl}/api/auth/callback`],
  public: true,
  hook_attributes: { active: false },
  default_permissions: {},
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url ?? "/", `http://localhost:${PORT}`);
  if (url.pathname === "/") {
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(`<!doctype html><body>
      <form id="f" action="https://github.com/settings/apps/new" method="post">
        <input type="hidden" name="manifest" value='${JSON.stringify(manifest).replace(/'/g, "&#39;")}'>
      </form>
      <p>Submitting the app manifest to GitHub…</p>
      <script>document.getElementById('f').submit()</script></body>`);
    return;
  }
  if (url.pathname === "/converted") {
    const code = url.searchParams.get("code");
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end("<body><p>App created — you can close this tab.</p></body>");
    server.close();
    if (!code) { console.error("GitHub redirected without a code"); process.exit(1); }
    const out = execFileSync("gh", ["api", "-X", "POST", `/app-manifests/${code}/conversions`], { encoding: "utf8" });
    const app = JSON.parse(out) as { client_id?: string; client_secret?: string };
    if (!app.client_id || !app.client_secret) { console.error("conversion response missing credentials"); process.exit(1); }
    console.log(`CLIENT_ID=${app.client_id}`);
    console.log(`CLIENT_SECRET=${app.client_secret}`);
    process.exit(0);
  }
  res.writeHead(404); res.end();
});

server.listen(PORT, "127.0.0.1", () => {
  console.error(`Open http://localhost:${PORT}/ — one click on "Create GitHub App" finishes this.`);
  execFileSync("open", [`http://localhost:${PORT}/`]);
});
```

- [ ] **Step 2: Implement `scripts/setup.sh`**

```bash
#!/usr/bin/env bash
# One-time provisioning: Netlify site link + GitHub app credentials + env vars.
# Default lane: GitHub App manifest flow (one browser click).
# Fallback lane: ./setup.sh --client-id <id> --client-secret-stdin  (paste secret, ^D)
set -euo pipefail
cd "$(dirname "$0")/.."

FORCE=0; CLIENT_ID=""; SECRET_STDIN=0
while [ $# -gt 0 ]; do case "$1" in
  --force) FORCE=1 ;;
  --client-id) CLIENT_ID="$2"; shift ;;
  --client-secret-stdin) SECRET_STDIN=1 ;;
  *) echo "unknown flag: $1" >&2; exit 1 ;;
esac; shift; done

if ! npx netlify status >/dev/null 2>&1; then
  echo "Netlify CLI not logged in — run: npx netlify login" >&2; exit 1
fi
if ! npx netlify status | grep -q "Project URL"; then
  npx netlify sites:create --name cs3540-lectures
  npx netlify link --name cs3540-lectures
fi
SITE_URL=$(npx netlify status | sed -n 's/.*Project URL:[^h]*\(https[^ ]*\).*/\1/p' | head -1)
echo "site: $SITE_URL"

if [ "$FORCE" = 0 ] && npx netlify env:list --plain --context production 2>/dev/null | grep -q '^GITHUB_CLIENT_ID='; then
  echo "env vars already present — re-run with --force to overwrite" >&2; exit 1
fi

if [ -n "$CLIENT_ID" ]; then
  [ "$SECRET_STDIN" = 1 ] || { echo "--client-id requires --client-secret-stdin" >&2; exit 1; }
  echo "paste the client secret, then Ctrl-D:"
  CLIENT_SECRET=$(cat)
else
  CREDS=$(npx tsx scripts/setup-app.ts "$SITE_URL")
  CLIENT_ID=$(echo "$CREDS" | sed -n 's/^CLIENT_ID=//p')
  CLIENT_SECRET=$(echo "$CREDS" | sed -n 's/^CLIENT_SECRET=//p')
fi
[ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ] || { echo "no credentials obtained" >&2; exit 1; }

CTX=(--context production --context deploy-preview --context branch-deploy)
npx netlify env:set GITHUB_CLIENT_ID "$CLIENT_ID"
npx netlify env:set GITHUB_CLIENT_SECRET "$CLIENT_SECRET" --secret "${CTX[@]}"
npx netlify env:set SESSION_SECRET "$(openssl rand -hex 32)" --secret "${CTX[@]}"
npx netlify env:set ADMIN_HANDLES "hunterino"
echo "done: GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, SESSION_SECRET, ADMIN_HANDLES set for $SITE_URL"
```

Run: `chmod +x scripts/setup.sh`

- [ ] **Step 3: Verify the guard lane against the live (already-configured) site**

Run: `bash scripts/setup.sh`
Expected: exits 1 with "env vars already present — re-run with --force to overwrite" — this proves the idempotency guard works against the real site without touching anything. Do NOT run with `--force` (the site is already provisioned; a forced run would rotate `SESSION_SECRET` and sign everyone out). Typecheck: `npx tsc --noEmit`.

- [ ] **Step 4: Commit**

```bash
git add scripts/setup.sh scripts/setup-app.ts
git commit -m "feat: one-click provisioning script (GitHub App manifest flow + env vars)"
```

---

### Task 12: README, first production deploy, end-to-end verification

**Files:**
- Create: `README.md`
- Modify: none

**Interfaces:**
- Consumes: everything.

- [ ] **Step 1: Write `README.md`**

Cover, concretely (full sentences, no placeholders):
- What the site is, URL, and the three roles (anonymous / signed-in student / instructor `hunterino`).
- Commands: `npm test`, `npm run build`, `npm run deploy`; `CONTENT_DIR` override.
- Recording flow: studio at `/studio`, takes land in the `takes` blob store, archive naming (`slide-NN-takeK`), and that recording needs NO redeploy; slides/scripts/TTS changes DO need `npm run deploy`.
- Operations: `npx tsx scripts/pull-takes.ts` (mirror blobs to local `_lectures/`; run after recording sessions and before close-out); `netlify dev:exec npx tsx scripts/export-viewing.ts --roster <semester>/roster/github-handles.txt --index dist/media/site-index.json --out <semester>/grading/viewing-$(date +%F).json`.
- **Semester close-out:** final export, then purge:
  `netlify dev:exec npx tsx -e "import('@netlify/database').then(async m => { await m.getDatabase().sql\`TRUNCATE view_events\`; console.log('view_events truncated'); })"`.
- FERPA rule: no rosters/exports/dumps ever enter this repo.
- Provisioning: `scripts/setup.sh` (both lanes), env var names.

- [ ] **Step 2: Full test suite + build**

Run: `npx vitest run && npx tsc --noEmit && npm run build`
Expected: everything green; dist assembled.

- [ ] **Step 3: First production deploy**

Run: `npm run deploy`
Expected: deploy succeeds; migration `001_create-view-events` is applied before publish (visible in deploy logs). If the DB was never provisioned, the first deploy provisions it.

- [ ] **Step 4: End-to-end verification on the live site** (report each result; stop and fix on any failure)

1. `curl -s https://cs3540-lectures.netlify.app/api/decks | python3 -m json.tool | head` → deck list, `recorded_slides: 0`.
2. Browser: open the site → landing page lists decks; open `/player` → slides render, TTS audio plays on a narrated deck.
3. Sign in with GitHub (real OAuth round-trip) → authbar shows the handle; `/api/me` returns `admin: true` for `hunterino`.
4. Open `/studio` (Chrome) → gate admits; record + keep a take on slide 1 of a deck → upload succeeds.
5. In a private window (not signed in): `/player`, source "Recorded takes" → hear the take just recorded.
6. Play ~30s of audio while signed in, then:
   `netlify dev:exec npx tsx -e "import('@netlify/database').then(async m => console.log(await m.getDatabase().sql\`SELECT * FROM deck_progress\`))"`
   → a row for `hunterino` with plausible `seconds_listened`.
   (Note: `dev:exec` talks to the dev branch DB; if the row isn't visible there, verify against production by running the same query with `NETLIFY_DATABASE_URL` taken from `netlify env:get NETLIFY_DATABASE_URL --context production --plain`.)
7. Re-record the same slide, keep → `/api/status?deck=…` now shows the new take; `netlify blobs:list takes --json` shows both `slide-01.webm` and `slide-01-take2.webm`.
8. Run `npx tsx scripts/pull-takes.ts` → both blobs land under `_lectures/audio/<deck>/recorded/`.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: operations README; first production deploy verified end-to-end"
```

---

## Plan Self-Review (performed at write time)

- **Spec coverage:** topology (T1, T7), auth + roles (T2, T4), studio port + archive invariant (T3, T6, T9), player + beacons (T8), DB + export + FERPA lifecycle (T5, T10, T12 README), setup script (T11), tests incl. netlify-dev smoke (T8–T9) and live E2E (T12). Deviation from spec noted and committed: endpoint names keep the local server's contracts.
- **Known judgment points for the executor:** exact insertion anchors in the ported HTML (the pages are 375/919 lines; anchors are given as searchable expressions, not line numbers); netlify-cli `blobs:*` output shape (T10 Step 6 verifies before relying on it).
- **Type consistency:** `TakeStore`/`keepTake`/`SiteIndex`/`SqlTag` signatures are identical across Tasks 3–6 and 10.
