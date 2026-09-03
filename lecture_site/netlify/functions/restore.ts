import { getStore } from "@netlify/blobs";
import { isAdmin, sessionFromRequest } from "../../src/lib/session";
import { AUDIO_FILE_RE, DECK_ID_RE, restoreTake, type TakeStore, wrapNetlifyStore } from "../../src/lib/takes";

export async function handleRestore(req: Request, store: TakeStore): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response("sign in first", { status: 401 });
  if (!isAdmin(session.handle)) return new Response("restore is instructor-only", { status: 403 });

  const url = new URL(req.url);
  const deck = url.searchParams.get("deck") ?? "";
  const slide = Number(url.searchParams.get("slide"));
  const file = url.searchParams.get("file") ?? "";
  if (!DECK_ID_RE.test(deck) || !Number.isInteger(slide) || slide < 1 || slide > 300 || !AUDIO_FILE_RE.test(file)) {
    return new Response("bad restore request", { status: 400 });
  }

  const res = await restoreTake(store, deck, slide, file);
  if (!res.ok) {
    if (res.reason === "already_canonical") return new Response("that take is already canonical", { status: 409 });
    return new Response("no such archived take", { status: 404 });
  }
  return new Response(JSON.stringify(res), { status: 200, headers: { "Content-Type": "application/json" } });
}

export default (req: Request) =>
  handleRestore(req, wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" })));
export const config = { path: "/api/restore" };
