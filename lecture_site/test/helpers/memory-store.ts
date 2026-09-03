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
