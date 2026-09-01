import { isAdmin, sessionFromRequest } from "../../src/lib/session";

export default async function handleMe(req: Request): Promise<Response> {
  const session = sessionFromRequest(req);
  if (!session) return new Response(JSON.stringify({ error: "not signed in" }), { status: 401, headers: { "Content-Type": "application/json" } });
  return new Response(JSON.stringify({ handle: session.handle, admin: isAdmin(session.handle) }),
    { status: 200, headers: { "Content-Type": "application/json" } });
}
export const config = { path: "/api/me" };
