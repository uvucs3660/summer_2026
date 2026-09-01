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
    setJSON: async (key, v) => { await store.setJSON(key, v); },
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
