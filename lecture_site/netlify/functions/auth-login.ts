import { signState } from "../../src/lib/github";

export default async function handleLogin(req: Request): Promise<Response> {
  const secret = process.env.SESSION_SECRET;
  const clientId = process.env.GITHUB_CLIENT_ID;
  if (!secret || !clientId) return new Response("auth not configured", { status: 500 });
  const state = signState(secret);
  const origin = new URL(req.url).origin;
  const to = new URL("https://github.com/login/oauth/authorize");
  to.searchParams.set("client_id", clientId);
  to.searchParams.set("redirect_uri", `${origin}/api/auth/callback`);
  to.searchParams.set("state", state);
  return new Response(null, {
    status: 302,
    headers: {
      Location: to.toString(),
      "Set-Cookie": `oauth_state=${state}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=600`,
    },
  });
}
export const config = { path: "/api/auth/login" };
