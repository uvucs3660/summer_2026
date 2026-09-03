import { beforeEach, describe, expect, it } from "vitest";
import { handleCallback } from "../netlify/functions/auth-callback";
import handleMe from "../netlify/functions/me";
import handleLogin from "../netlify/functions/auth-login";
import handleLogout from "../netlify/functions/auth-logout";
import { signState } from "../src/lib/github";
import { signSession } from "../src/lib/session";

beforeEach(() => {
  process.env.SESSION_SECRET = "test-secret";
  process.env.ADMIN_HANDLES = "hunterino";
  process.env.GITHUB_CLIENT_ID = "id";
  process.env.GITHUB_CLIENT_SECRET = "sec";
});

describe("/api/auth/login", () => {
  it("redirects to GitHub with a state cookie", async () => {
    const res = await handleLogin(new Request("https://site.test/api/auth/login"));
    expect(res.status).toBe(302);
    const loc = new URL(res.headers.get("location")!);
    expect(loc.origin + loc.pathname).toBe("https://github.com/login/oauth/authorize");
    expect(loc.searchParams.get("client_id")).toBe("id");
    expect(loc.searchParams.get("redirect_uri")).toBe("https://site.test/api/auth/callback");
    expect(res.headers.get("set-cookie")).toContain("oauth_state=");
  });
});

describe("/api/auth/callback", () => {
  it("sets a session cookie for a valid code+state", async () => {
    const state = signState("test-secret");
    const req = new Request(
      `https://site.test/api/auth/callback?code=c0de&state=${encodeURIComponent(state)}`,
      { headers: { cookie: `oauth_state=${state}` } },
    );
    const res = await handleCallback(req, { exchange: async () => "hunterino" });
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("/");
    expect(res.headers.get("set-cookie")).toMatch(/^session=.+HttpOnly/s);
    const cookies = res.headers.getSetCookie();
    expect(cookies.some((c) => c.startsWith("session="))).toBe(true);
    expect(cookies.some((c) => c.startsWith("oauth_state=") && c.includes("Max-Age=0"))).toBe(true);
  });
  it("rejects state mismatch with 403 and no cookie", async () => {
    const req = new Request("https://site.test/api/auth/callback?code=c&state=evil",
      { headers: { cookie: `oauth_state=${signState("test-secret")}` } });
    const res = await handleCallback(req, { exchange: async () => "hunterino" });
    expect(res.status).toBe(403);
    expect(res.headers.get("set-cookie")).toBeNull();
  });
  it("surfaces exchange failure as 502", async () => {
    const state = signState("test-secret");
    const req = new Request(`https://site.test/api/auth/callback?code=c&state=${encodeURIComponent(state)}`,
      { headers: { cookie: `oauth_state=${state}` } });
    const res = await handleCallback(req, { exchange: async () => { throw new Error("boom"); } });
    expect(res.status).toBe(502);
  });
});

describe("/api/me", () => {
  it("returns handle+admin for a valid session", async () => {
    const tok = signSession("hunterino", "test-secret");
    const res = await handleMe(new Request("https://x/api/me", { headers: { cookie: `session=${tok}` } }));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ handle: "hunterino", admin: true });
  });
  it("401s without a session", async () => {
    expect((await handleMe(new Request("https://x/api/me"))).status).toBe(401);
  });
});

describe("/api/auth/logout", () => {
  it("clears the cookie", async () => {
    const res = await handleLogout(new Request("https://x/api/auth/logout", { method: "POST" }));
    expect(res.headers.get("set-cookie")).toContain("Max-Age=0");
  });
});
