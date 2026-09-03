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
