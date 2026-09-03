import * as fs from "node:fs";

export interface ProgressRow {
  handle: string; deck: string; slides_touched: number;
  seconds_listened: number; first_seen: string; last_seen: string;
}
export interface ExportDoc {
  generated_at: string;
  students: Record<string, Record<string, {
    slides_touched: number; seconds_listened: number; slide_count: number;
    pct_slides: number; first_seen: string; last_seen: string;
  }>>;
}

export function parseRoster(text: string): Set<string> {
  return new Set(
    text.split("\n").map((l) => l.trim().toLowerCase())
      .filter((l) => l && !l.startsWith("#")),
  );
}

export function buildExport(
  rows: ProgressRow[], roster: Set<string>,
  slideCounts: Record<string, number>, now = new Date(),
): ExportDoc {
  const students: ExportDoc["students"] = {};
  for (const r of rows) {
    const handle = r.handle.toLowerCase();
    if (!roster.has(handle)) continue;
    const slideCount = slideCounts[r.deck] ?? 0;
    (students[handle] ??= {})[r.deck] = {
      slides_touched: Number(r.slides_touched),
      seconds_listened: Number(r.seconds_listened),
      slide_count: slideCount,
      pct_slides: slideCount > 0 ? Number(r.slides_touched) / slideCount : 0,
      first_seen: r.first_seen,
      last_seen: r.last_seen,
    };
  }
  return { generated_at: now.toISOString(), students };
}

function arg(name: string): string {
  const i = process.argv.indexOf(name);
  if (i < 0 || !process.argv[i + 1]) {
    console.error(`usage: netlify dev:exec npx tsx scripts/export-viewing.ts --roster <file> --index dist/media/site-index.json --out <file>`);
    process.exit(1);
  }
  return process.argv[i + 1];
}

async function main(): Promise<void> {
  const { getDatabase } = await import("@netlify/database");
  const roster = parseRoster(fs.readFileSync(arg("--roster"), "utf8"));
  const index = JSON.parse(fs.readFileSync(arg("--index"), "utf8")) as
    { lectures: { id: string; slide_count: number }[] };
  const counts = Object.fromEntries(index.lectures.map((l) => [l.id, l.slide_count]));

  const sql = getDatabase().sql;
  const rows = (await sql`SELECT handle, deck, slides_touched, seconds_listened, first_seen, last_seen FROM deck_progress`) as unknown as ProgressRow[];
  const doc = buildExport(rows, roster, counts);
  fs.writeFileSync(arg("--out"), JSON.stringify(doc, null, 2) + "\n");
  console.log(`wrote ${arg("--out")}: ${Object.keys(doc.students).length} students (${rows.length} deck-progress rows scanned)`);
}

if (process.argv[1]?.endsWith("export-viewing.ts")) main();
