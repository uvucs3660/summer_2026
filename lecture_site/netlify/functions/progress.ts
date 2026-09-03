import { getDatabase } from "@netlify/database";
import { sessionFromRequest } from "../../src/lib/session";
import { DECK_ID_RE } from "../../src/lib/takes";

export type SqlTag = (strings: TemplateStringsArray, ...vals: unknown[]) => Promise<unknown>;

export async function handleProgress(req: Request, sql: SqlTag): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response(null, { status: 401 });

  let body: unknown;
  try { body = await req.json(); } catch { return new Response("invalid JSON", { status: 400 }); }
  const { deck, slide, seconds, playback_rate } = (body ?? {}) as Record<string, unknown>;

  const ok =
    typeof deck === "string" && DECK_ID_RE.test(deck) &&
    typeof slide === "number" && Number.isInteger(slide) && slide >= 1 && slide <= 300 &&
    typeof seconds === "number" && seconds > 0 && seconds <= 20 &&
    typeof playback_rate === "number" && playback_rate >= 0.25 && playback_rate <= 4;
  if (!ok) return new Response("invalid progress payload", { status: 400 });

  await sql`INSERT INTO view_events (handle, deck, slide, seconds, playback_rate)
            VALUES (${session.handle}, ${deck}, ${slide}, ${seconds}, ${playback_rate})`;
  return new Response(null, { status: 204 });
}

export default (req: Request) => handleProgress(req, getDatabase().sql as unknown as SqlTag);
export const config = { path: "/api/progress" };
