import { getStore } from "@netlify/blobs";
import type { Context } from "@netlify/functions";
import { AUDIO_FILE_RE, blobKey, DECK_ID_RE, type TakeStore, wrapNetlifyStore } from "../../src/lib/takes";

const CONTENT_TYPES: Record<string, string> = { webm: "audio/webm", ogg: "audio/ogg", m4a: "audio/mp4" };

export async function handleAudio(
  req: Request, store: TakeStore, params: { deck: string; file: string },
): Promise<Response> {
  const { deck, file } = params;
  if (!DECK_ID_RE.test(deck) || !AUDIO_FILE_RE.test(file)) return new Response("bad path", { status: 400 });
  const found = await store.getStream(blobKey(deck, file));
  if (!found) return new Response("no such take", { status: 404 });
  const headers = new Headers({
    "Content-Type": CONTENT_TYPES[file.slice(file.lastIndexOf(".") + 1)],
    "Cache-Control": "public, max-age=0, must-revalidate",
  });
  if (found.etag) {
    headers.set("ETag", found.etag);
    if (req.headers.get("if-none-match") === found.etag) return new Response(null, { status: 304, headers });
  }
  return new Response(found.body, { status: 200, headers });
}

export default (req: Request, context: Context) =>
  handleAudio(req, wrapNetlifyStore(getStore({ name: "takes", consistency: "strong" })), {
    deck: context.params.deck ?? "", file: context.params.file ?? "",
  });
export const config = { path: "/api/audio/:deck/:file" };
