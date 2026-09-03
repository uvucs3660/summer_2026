import { describe, expect, it } from "vitest";
import { buildExport, parseRoster } from "../scripts/export-viewing";

const rows = [
  { handle: "student1", deck: "w01-game-first-contact", slides_touched: 8, seconds_listened: 500, first_seen: "2026-09-02T10:00:00Z", last_seen: "2026-09-02T10:20:00Z" },
  { handle: "STUDENT1", deck: "w01-ai-eleven-pillars", slides_touched: 2, seconds_listened: 90, first_seen: "2026-09-03T10:00:00Z", last_seen: "2026-09-03T10:05:00Z" },
  { handle: "not-enrolled", deck: "w01-game-first-contact", slides_touched: 9, seconds_listened: 700, first_seen: "2026-09-02T10:00:00Z", last_seen: "2026-09-02T10:20:00Z" },
];
const counts = { "w01-game-first-contact": 9, "w01-ai-eleven-pillars": 7 };

describe("buildExport", () => {
  it("filters to roster handles case-insensitively and computes pct", () => {
    const doc = buildExport(rows, new Set(["student1"]), counts, new Date("2026-10-01T00:00:00Z"));
    expect(Object.keys(doc.students)).toEqual(["student1"]);
    const s1 = doc.students["student1"];
    expect(s1["w01-game-first-contact"].pct_slides).toBeCloseTo(8 / 9);
    expect(s1["w01-ai-eleven-pillars"].slides_touched).toBe(2); // case-folded onto the roster handle
    expect(doc.generated_at).toBe("2026-10-01T00:00:00.000Z");
  });
});

describe("parseRoster", () => {
  it("parses handles, skipping blanks and comments", () => {
    expect(parseRoster("# roster\nstudent1\n\n Student2 \n#x\n")).toEqual(new Set(["student1", "student2"]));
  });
});
