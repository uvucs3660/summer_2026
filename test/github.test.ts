import { describe, expect, it } from "vitest";
import { exchangeCodeForHandle, signState, verifyState } from "../src/lib/github";

const okJson = (obj: unknown) => new Response(JSON.stringify(obj), { status: 200, headers: { "Content-Type": "application/json" } });

describe("exchangeCodeForHandle", () => {
  it("exchanges code then fetches the login", async () => {
    const calls: string[] = [];
    const fetchFn = (async (url: RequestInfo | URL, init?: RequestInit) => {
      calls.push(String(url));
      if (String(url).includes("access_token")) {
        expect(JSON.parse(String(init!.body))).toMatchObject({ code: "c0de", client_id: "id", client_secret: "sec" });
        return okJson({ access_token: "tok123" });
      }
      expect((init!.headers as Record<string, string>).Authorization).toBe("Bearer tok123");
      return okJson({ login: "hunterino" });
    }) as typeof fetch;
    expect(await exchangeCodeForHandle("c0de", "id", "sec", fetchFn)).toBe("hunterino");
    expect(calls).toEqual(["https://github.com/login/oauth/access_token", "https://api.github.com/user"]);
  });
  it("throws on exchange error payloads", async () => {
    const fetchFn = (async () => okJson({ error: "bad_verification_code" })) as typeof fetch;
    await expect(exchangeCodeForHandle("x", "id", "sec", fetchFn)).rejects.toThrow(/bad_verification_code/);
  });
  it("throws on non-200 responses", async () => {
    const fetchFn = (async () => new Response("nope", { status: 502 })) as typeof fetch;
    await expect(exchangeCodeForHandle("x", "id", "sec", fetchFn)).rejects.toThrow(/502/);
  });
});

describe("state nonce", () => {
  it("round-trips and rejects mismatch/expiry", () => {
    const s = signState("sec");
    expect(verifyState(s, s, "sec")).toBe(true);
    expect(verifyState(s, signState("sec"), "sec")).toBe(false);
    expect(verifyState(s, s, "other")).toBe(false);
    const old = signState("sec", Date.now() - 11 * 60_000);
    expect(verifyState(old, old, "sec")).toBe(false);
  });
});
