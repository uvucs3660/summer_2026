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
