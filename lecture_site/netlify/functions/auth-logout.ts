import { clearSessionCookie } from "../../src/lib/session";

export default async function handleLogout(_req: Request): Promise<Response> {
  return new Response(null, { status: 204, headers: { "Set-Cookie": clearSessionCookie() } });
}
export const config = { path: "/api/auth/logout" };
