import { getDatabase } from "@netlify/database";
import { loadSiteIndex, type SiteIndex } from "../../src/lib/site-index";
import { isAdmin, sessionFromRequest } from "../../src/lib/session";

export type SqlTag = (strings: TemplateStringsArray, ...vals: unknown[]) => Promise<unknown>;

// A lecture counts as completed once a student has touched >= 90% of its slides.
export const COMPLETION_PCT = 0.9;

interface ProgressRow {
  handle: string; deck: string;
  slides_touched: number | string; seconds_listened: number | string; last_seen: string;
}

export async function handleViewing(
  req: Request, sql: SqlTag, loadIndex: (origin: string) => Promise<SiteIndex>,
): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response("sign in first", { status: 401 });
  if (!isAdmin(session.handle)) return new Response("viewing report is instructor-only", { status: 403 });

  let index: SiteIndex;
  try { index = await loadIndex(new URL(req.url).origin); }
  catch (err) { return new Response(`deck index unavailable: ${String(err)}`, { status: 502 }); }

  const rows = (await sql`SELECT handle, deck, slides_touched, seconds_listened, last_seen
                          FROM deck_progress`) as ProgressRow[];
  const byDeck = new Map<string, ProgressRow[]>();
  for (const r of rows) {
    const list = byDeck.get(r.deck);
    if (list) list.push(r); else byDeck.set(r.deck, [r]);
  }

  const decks = index.lectures
    .slice().sort((a, b) => a.week - b.week || a.id.localeCompare(b.id))
    .map((l) => {
      const watchers = (byDeck.get(l.id) ?? [])
        .map((r) => {
          const slides_touched = Number(r.slides_touched);
          const pct = l.slide_count > 0 ? slides_touched / l.slide_count : 0;
          return {
            handle: r.handle,
            slides_touched,
            seconds_listened: Number(r.seconds_listened),
            last_seen: r.last_seen,
            pct,
            completed: pct >= COMPLETION_PCT,
          };
        })
        .sort((a, b) => Number(b.completed) - Number(a.completed) || a.handle.localeCompare(b.handle));
      return {
        id: l.id, title: l.title, subtitle: l.subtitle, week: l.week, track: l.track,
        slide_count: l.slide_count,
        watching: watchers.length,
        completed: watchers.filter((w) => w.completed).length,
        watchers,
      };
    });

  return new Response(JSON.stringify({ completion_pct: COMPLETION_PCT, decks }),
    { status: 200, headers: { "Content-Type": "application/json" } });
}

export default (req: Request) =>
  handleViewing(req, getDatabase().sql as unknown as SqlTag, loadSiteIndex);
export const config = { path: "/api/viewing" };
