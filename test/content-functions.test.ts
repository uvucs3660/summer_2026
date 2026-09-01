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
