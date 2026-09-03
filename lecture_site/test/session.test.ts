import { describe, expect, it } from "vitest";
import {
  clearSessionCookie, isAdmin, SESSION_MAX_AGE_MS, sessionCookie,
  sessionFromRequest, signSession, verifySession,
} from "../src/lib/session";

const SECRET = "test-secret";

describe("session sign/verify", () => {
  it("round-trips a handle", () => {
    const tok = signSession("hunterino", SECRET);
    expect(verifySession(tok, SECRET)?.handle).toBe("hunterino");
  });
  it("rejects a tampered payload", () => {
    const tok = signSession("hunterino", SECRET);
    const [payload, mac] = tok.split(".");
    const forged = Buffer.from(JSON.stringify({ h: "attacker", iat: Date.now() })).toString("base64url");
    expect(verifySession(`${forged}.${mac}`, SECRET)).toBeNull();
    expect(verifySession(`${payload}.AAAA`, SECRET)).toBeNull();
  });
  it("rejects the wrong secret", () => {
    expect(verifySession(signSession("h", SECRET), "other")).toBeNull();
  });
  it("rejects expired and future-dated tokens", () => {
    const old = signSession("h", SECRET, Date.now() - SESSION_MAX_AGE_MS - 1000);
    expect(verifySession(old, SECRET)).toBeNull();
    const future = signSession("h", SECRET, Date.now() + 3600_000);
    expect(verifySession(future, SECRET)).toBeNull();
  });
  it("rejects garbage", () => {
    expect(verifySession(undefined, SECRET)).toBeNull();
    expect(verifySession("", SECRET)).toBeNull();
    expect(verifySession("no-dot", SECRET)).toBeNull();
    expect(verifySession("a.b.c", SECRET)).toBeNull();
  });
  it("rejects a payload whose handle is not a GitHub login shape", () => {
    const tok = signSession("bad handle!", SECRET);
    expect(verifySession(tok, SECRET)).toBeNull();
  });
});

describe("isAdmin", () => {
  it("matches case-insensitively against a comma list", () => {
    expect(isAdmin("Hunterino", "hunterino")).toBe(true);
    expect(isAdmin("hunterino", " a , HUNTERINO ,b")).toBe(true);
    expect(isAdmin("student1", "hunterino")).toBe(false);
    expect(isAdmin("hunterino", "")).toBe(false);
  });
});

describe("cookies", () => {
  it("extracts the session cookie from a Request", () => {
    const tok = signSession("hunterino", SECRET);
    const req = new Request("https://x/", { headers: { cookie: `a=1; session=${tok}; b=2` } });
    expect(sessionFromRequest(req, SECRET)?.handle).toBe("hunterino");
    expect(sessionFromRequest(new Request("https://x/"), SECRET)).toBeNull();
  });
  it("serializes hardened cookie attributes", () => {
    expect(sessionCookie("tok")).toBe("session=tok; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=10368000");
    expect(clearSessionCookie()).toBe("session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0");
  });
});
