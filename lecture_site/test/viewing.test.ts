import { beforeEach, describe, expect, it } from "vitest";
import { handleViewing } from "../netlify/functions/viewing";
import type { SiteIndex } from "../src/lib/site-index";
import { signSession } from "../src/lib/session";

beforeEach(() => {
  process.env.SESSION_SECRET = "test-secret";
  process.env.ADMIN_HANDLES = "hunterino";
});

const INDEX: SiteIndex = {
  lectures: [
    { id: "w02-game-the-loop", week: 2, track: "game", title: "The Loop", subtitle: "s",
      slide_count: 10, word_count: 100, duration_ms: 1000, file: "a.json", has_audio: true, has_slides: true },
    { id: "w01-game-first-contact", week: 1, track: "game", title: "First Contact", subtitle: "s",
      slide_count: 3, word_count: 100, duration_ms: 1000, file: "b.json", has_audio: true, has_slides: true },
  ],
};
const loadIndex = async () => INDEX;

// pg returns aggregate columns as strings — the fake mimics that.
const ROWS = [
  { handle: "student1", deck: "w02-game-the-loop", slides_touched: "9", seconds_listened: "600.5", last_seen: "2026-09-02T10:00:00Z" },
  { handle: "student2", deck: "w02-game-the-loop", slides_touched: "8", seconds_listened: "300", last_seen: "2026-09-02T11:00:00Z" },
  { handle: "student1", deck: "w01-game-first-contact", slides_touched: "3", seconds_listened: "200", last_seen: "2026-09-01T09:00:00Z" },
];

function fakeSql(rows: unknown[] = ROWS) {
  const calls: string[] = [];
  const sql = async (strings: TemplateStringsArray) => { calls.push(strings.join("?")); return rows; };
  return { sql, calls };
}

const get = (cookie?: string) =>
  new Request("https://x/api/viewing", { headers: cookie ? { cookie } : {} });
const admin = () => `session=${signSession("hunterino", "test-secret")}`;
const student = () => `session=${signSession("student1", "test-secret")}`;

describe("/api/viewing", () => {
  it("401s anonymous and 403s non-admin without querying the DB", async () => {
    const { sql, calls } = fakeSql();
    expect((await handleViewing(get(), sql, loadIndex)).status).toBe(401);
    expect((await handleViewing(get(student()), sql, loadIndex)).status).toBe(403);
    expect(calls).toHaveLength(0);
  });

  it("marks completion at >= 90% of slides and orders decks by week", async () => {
    const { sql } = fakeSql();
    const res = await handleViewing(get(admin()), sql, loadIndex);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.completion_pct).toBe(0.9);
    expect(body.decks.map((d: { id: string }) => d.id))
      .toEqual(["w01-game-first-contact", "w02-game-the-loop"]);

    const loop = body.decks[1];
    expect(loop.slide_count).toBe(10);
    expect(loop.watching).toBe(2);
    expect(loop.completed).toBe(1); // 9/10 = 0.9 completes; 8/10 does not
    const s1 = loop.watchers.find((w: { handle: string }) => w.handle === "student1");
    expect(s1).toMatchObject({ slides_touched: 9, seconds_listened: 600.5, completed: true });
    expect(s1.pct).toBeCloseTo(0.9);
    expect(loop.watchers[0].completed).toBe(true); // completed sort first

    const first = body.decks[0];
    expect(first.watching).toBe(1);
    expect(first.completed).toBe(1); // 3/3
  });

  it("returns decks with zero watchers as empty lists", async () => {
    const { sql } = fakeSql([]);
    const body = await (await handleViewing(get(admin()), sql, loadIndex)).json();
    expect(body.decks[0].watchers).toEqual([]);
    expect(body.decks[0].watching).toBe(0);
    expect(body.decks[0].completed).toBe(0);
  });
});
