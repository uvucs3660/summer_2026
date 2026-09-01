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
