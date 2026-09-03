import { beforeEach, describe, expect, it } from "vitest";
import { handleProgress, type SqlTag } from "../netlify/functions/progress";
import { signSession } from "../src/lib/session";

beforeEach(() => { process.env.SESSION_SECRET = "test-secret"; });

function fakeSql() {
  const calls: { text: string; vals: unknown[] }[] = [];
  const sql: SqlTag = async (strings, ...vals) => { calls.push({ text: strings.join("?"), vals }); return []; };
  return { sql, calls };
}

const post = (body: unknown, cookie?: string) =>
  new Request("https://x/api/progress", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });

const asUser = (h: string) => `session=${signSession(h, "test-secret")}`;
const good = { deck: "w02-game-the-loop", slide: 4, seconds: 15, playback_rate: 1.5 };

describe("/api/progress", () => {
  it("inserts a row using the COOKIE handle, ignoring any handle in the body", async () => {
    const { sql, calls } = fakeSql();
    const res = await handleProgress(post({ ...good, handle: "someone-else" }, asUser("student1")), sql);
    expect(res.status).toBe(204);
    expect(calls).toHaveLength(1);
    expect(calls[0].vals).toEqual(["student1", "w02-game-the-loop", 4, 15, 1.5]);
  });
  it("401s without a session and never touches the DB", async () => {
    const { sql, calls } = fakeSql();
    expect((await handleProgress(post(good), sql)).status).toBe(401);
    expect(calls).toHaveLength(0);
  });
  it.each([
    [{ ...good, seconds: 0 }], [{ ...good, seconds: 21 }], [{ ...good, seconds: -3 }],
    [{ ...good, slide: 0 }], [{ ...good, slide: 301 }], [{ ...good, slide: 2.5 }],
    [{ ...good, playback_rate: 9 }], [{ ...good, deck: "../evil" }], [{ ...good, deck: "" }],
  ])("400s bad payload %j", async (body) => {
    const { sql, calls } = fakeSql();
    expect((await handleProgress(post(body, asUser("s")), sql)).status).toBe(400);
    expect(calls).toHaveLength(0);
  });
  it("400s non-JSON bodies", async () => {
    const { sql } = fakeSql();
    const req = new Request("https://x/api/progress", { method: "POST", headers: { cookie: asUser("s") }, body: "not json" });
    expect((await handleProgress(req, sql)).status).toBe(400);
  });
});
