import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";

export async function exchangeCodeForHandle(
  code: string, clientId: string, clientSecret: string, fetchFn: typeof fetch = fetch,
): Promise<string> {
  const tokenRes = await fetchFn("https://github.com/login/oauth/access_token", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code }),
  });
  if (!tokenRes.ok) throw new Error(`token exchange failed: HTTP ${tokenRes.status}`);
  const tok = (await tokenRes.json()) as { access_token?: string; error?: string };
  if (!tok.access_token) throw new Error(`token exchange error: ${tok.error ?? "no access_token"}`);

  const userRes = await fetchFn("https://api.github.com/user", {
    headers: {
      Authorization: `Bearer ${tok.access_token}`,
      Accept: "application/vnd.github+json",
      "User-Agent": "cs3540-lectures",
    },
  });
  if (!userRes.ok) throw new Error(`user fetch failed: HTTP ${userRes.status}`);
  const user = (await userRes.json()) as { login?: string };
  if (!user.login) throw new Error("GitHub /user response had no login");
  return user.login;
}

export function signState(secret: string, now = Date.now()): string {
  const payload = `${randomBytes(12).toString("base64url")}.${now}`;
  const mac = createHmac("sha256", secret).update(payload).digest("base64url");
  return `${payload}.${mac}`;
}

export function verifyState(
  state: string | undefined, cookieVal: string | undefined, secret: string, now = Date.now(),
): boolean {
  if (!state || !cookieVal || state !== cookieVal) return false;
  const parts = state.split(".");
  if (parts.length !== 3) return false;
  const expect = createHmac("sha256", secret).update(`${parts[0]}.${parts[1]}`).digest();
  const got = Buffer.from(parts[2], "base64url");
  if (got.length !== expect.length || !timingSafeEqual(got, expect)) return false;
  const ts = Number(parts[1]);
  return Number.isFinite(ts) && now - ts <= 10 * 60_000;
}
