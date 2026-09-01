import { exchangeCodeForHandle, verifyState } from "../../src/lib/github";
import { sessionCookie, signSession } from "../../src/lib/session";

export async function handleCallback(
  req: Request, deps: { exchange: typeof exchangeCodeForHandle },
): Promise<Response> {
  const secret = process.env.SESSION_SECRET;
  const clientId = process.env.GITHUB_CLIENT_ID;
  const clientSecret = process.env.GITHUB_CLIENT_SECRET;
  if (!secret || !clientId || !clientSecret) return new Response("auth not configured", { status: 500 });

  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") ?? undefined;
  const cookieState = (req.headers.get("cookie") ?? "").match(/(?:^|;\s*)oauth_state=([^;]+)/)?.[1];
  if (!code || !verifyState(state, cookieState, secret)) {
    return new Response("state mismatch — restart sign-in at /api/auth/login", { status: 403 });
  }
  let handle: string;
  try {
    handle = await deps.exchange(code, clientId, clientSecret);
  } catch (err) {
    return new Response(`GitHub sign-in failed: ${String(err)}. Retry at /api/auth/login`, { status: 502 });
  }
  return new Response(null, {
    status: 302,
    headers: { Location: "/", "Set-Cookie": sessionCookie(signSession(handle, secret)) },
  });
}

export default (req: Request) => handleCallback(req, { exchange: exchangeCodeForHandle });
export const config = { path: "/api/auth/callback" };
