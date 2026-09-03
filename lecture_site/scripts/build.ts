import * as fs from "node:fs";
import * as path from "node:path";

const CONTENT = process.env.CONTENT_DIR
  ?? path.resolve(import.meta.dirname, "../../content/cs3540/2026/lectures/slides/_lectures");
const OUT = path.join(process.cwd(), "dist");
const WEB = path.join(process.cwd(), "web");

interface Lecture {
  id: string; week: number; track: string; title: string; subtitle: string;
  slide_count: number; word_count: number; duration_ms: number; file: string;
}

function main(): void {
  const indexPath = path.join(CONTENT, "lectures.json");
  if (!fs.existsSync(indexPath)) {
    console.error(`lectures.json not found at ${indexPath} — set CONTENT_DIR`);
    process.exit(1);
  }
  const index = JSON.parse(fs.readFileSync(indexPath, "utf8")) as { lectures: Lecture[] };

  fs.rmSync(OUT, { recursive: true, force: true });
  fs.mkdirSync(path.join(OUT, "media", "slides"), { recursive: true });

  // pages
  for (const f of fs.readdirSync(WEB)) {
    fs.copyFileSync(path.join(WEB, f), path.join(OUT, f));
  }
  fs.writeFileSync(path.join(OUT, "_redirects"),
    "/player /player.html 200\n/studio /studio.html 200\n/admin /admin.html 200\n/ /index.html 200\n");

  // per-deck content + site index
  const lectures = index.lectures.map((l) => {
    const docSrc = path.join(CONTENT, l.file);
    if (!fs.existsSync(docSrc)) {
      console.error(`missing deck doc: ${docSrc}`);
      process.exit(1);
    }
    fs.copyFileSync(docSrc, path.join(OUT, "media", l.file));

    const mp3 = path.join(CONTENT, `${l.id}.mp3`);
    const has_audio = fs.existsSync(mp3);
    if (has_audio) fs.copyFileSync(mp3, path.join(OUT, "media", `${l.id}.mp3`));

    const slidesDir = path.join(CONTENT, "slides", l.id);
    const has_slides = fs.existsSync(slidesDir);
    if (has_slides) {
      fs.cpSync(slidesDir, path.join(OUT, "media", "slides", l.id), { recursive: true });
    }
    return { ...l, has_audio, has_slides };
  });

  fs.copyFileSync(indexPath, path.join(OUT, "media", "lectures.json"));
  fs.writeFileSync(path.join(OUT, "media", "site-index.json"),
    JSON.stringify({ lectures }, null, 2) + "\n");

  console.log(`built ${lectures.length} decks → dist/ (${lectures.filter((l) => l.has_audio).length} with TTS audio, ${lectures.filter((l) => l.has_slides).length} with slides)`);
}

main();
