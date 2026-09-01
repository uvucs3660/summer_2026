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
