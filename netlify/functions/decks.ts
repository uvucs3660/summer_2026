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
