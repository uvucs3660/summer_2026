import { beforeEach, describe, expect, it } from "vitest";
import { handleAudio } from "../netlify/functions/audio";
import { handleDecks } from "../netlify/functions/decks";
import { handleRecord } from "../netlify/functions/record";
import { handleRestore } from "../netlify/functions/restore";
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
    expect(body.slides[1]).toEqual({
      slide: 2, recorded: true, file: "slide-02.webm", duration_ms: 900,
      status: "recorded", take_count: 1,
      takes: [{ file: "slide-02.webm", ms: 900, kept_at: body.slides[1].takes[0].kept_at }],
    });
    expect(body.slides[0].recorded).toBe(false);
    expect(body.slides[0]).toEqual({
      slide: 1, recorded: false, file: null, duration_ms: null,
      status: "none", take_count: 0, takes: [],
    });
    expect(body.slide_count).toBe(3);
    expect(body.total_recorded_ms).toBe(900);
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
  it("re-recording a slide returns archived as a single filename string, not an array", async () => {
    const store = new MemoryStore();
    const first = await handleRecord(put(admin()), store, loadIndex);
    expect(await first.json()).toEqual({ ok: true, file: "slide-02.webm", archived: null });
    const second = await handleRecord(put(admin()), store, loadIndex);
    expect(second.status).toBe(200);
    expect(await second.json()).toEqual({ ok: true, file: "slide-02.webm", archived: "slide-02-take2.webm" });
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

describe("/api/restore", () => {
  const DECK2 = "w02-game-the-loop";
  async function seedTwoTakes(store: MemoryStore) {
    await keepTake(store, DECK2, 2, "webm", bytes(5000, 1), 900);
    await keepTake(store, DECK2, 2, "webm", bytes(6000, 2), 950);
  }
  const post = (cookie: string | null, qs: string) =>
    new Request(`https://x/api/restore?${qs}`, { method: "POST", headers: cookie ? { cookie } : {} });
  const GOOD = "deck=w02-game-the-loop&slide=2&file=slide-02-take2.webm";

  it("promotes an archived take for the admin and returns the keep shape", async () => {
    const store = new MemoryStore();
    await seedTwoTakes(store);
    const res = await handleRestore(post(admin(), GOOD), store);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ok: true, file: "slide-02.webm", archived: "slide-02-take3.webm" });
    expect(new Uint8Array((await store.getBuffer(blobKey(DECK2, "slide-02.webm")))!)[0]).toBe(1);
  });
  it("401s anonymous and 403s non-admin without touching the store", async () => {
    const store = new MemoryStore();
    await seedTwoTakes(store);
    expect((await handleRestore(post(null, GOOD), store)).status).toBe(401);
    expect((await handleRestore(post(student(), GOOD), store)).status).toBe(403);
    expect(new Uint8Array((await store.getBuffer(blobKey(DECK2, "slide-02.webm")))!)[0]).toBe(2);
  });
  it("400s malformed deck/slide/file", async () => {
    const store = new MemoryStore();
    expect((await handleRestore(post(admin(), "deck=../x&slide=2&file=slide-02-take2.webm"), store)).status).toBe(400);
    expect((await handleRestore(post(admin(), "deck=w02-game-the-loop&slide=0&file=slide-02-take2.webm"), store)).status).toBe(400);
    expect((await handleRestore(post(admin(), "deck=w02-game-the-loop&slide=2&file=takes.json"), store)).status).toBe(400);
  });
  it("404s an unlisted take and 409s the canonical take", async () => {
    const store = new MemoryStore();
    await seedTwoTakes(store);
    expect((await handleRestore(post(admin(), "deck=w02-game-the-loop&slide=2&file=slide-02-take9.webm"), store)).status).toBe(404);
    expect((await handleRestore(post(admin(), "deck=w02-game-the-loop&slide=2&file=slide-02.webm"), store)).status).toBe(409);
  });
});

describe("/api/status take history", () => {
  it("lists every take per slide, newest first", async () => {
    const store = new MemoryStore();
    await keepTake(store, "w02-game-the-loop", 2, "webm", bytes(5000, 1), 900);
    await keepTake(store, "w02-game-the-loop", 2, "webm", bytes(6000, 2), 950);
    const res = await handleStatus(new Request("https://x/api/status?deck=w02-game-the-loop"), store, loadIndex);
    const body = await res.json();
    expect(body.slides[1].takes.map((t: { file: string }) => t.file))
      .toEqual(["slide-02.webm", "slide-02-take2.webm"]);
    expect(body.slides[1].takes[0].ms).toBe(950);
    expect(body.slides[0].takes).toEqual([]);
  });
});
