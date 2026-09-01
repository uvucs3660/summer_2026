import { execFileSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const CONTENT = process.env.CONTENT_DIR
  ?? path.join(os.homedir(), "code/uvu/tools/course_builder/content/cs3540/2026/lectures/slides/_lectures");

function netlifyJSON(args: string[]): unknown {
  return JSON.parse(execFileSync("npx", ["netlify", ...args, "--json"], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 }));
}

function main(): void {
  const listed = netlifyJSON(["blobs:list", "takes"]) as { key: string }[] | { blobs: { key: string }[] };
  const keys = (Array.isArray(listed) ? listed : listed.blobs).map((b) => b.key);
  if (keys.length === 0) { console.log("no takes in the blob store yet"); return; }

  let pulled = 0, skipped = 0;
  for (const key of keys) {
    const m = key.match(/^takes\/([a-z0-9-]+)\/(.+)$/);
    if (!m) { console.error(`unexpected blob key skipped: ${key}`); continue; }
    const [, deck, file] = m;
    const destDir = path.join(CONTENT, "audio", deck, "recorded");
    const dest = path.join(destDir, file);
    const isImmutableArchive = /-take\d+\./.test(file);
    if (isImmutableArchive && fs.existsSync(dest)) { skipped++; continue; }
    fs.mkdirSync(destDir, { recursive: true });
    execFileSync("npx", ["netlify", "blobs:get", "takes", key, "--output", dest], { stdio: "inherit" });
    pulled++;
  }
  console.log(`mirrored ${pulled} blobs into ${CONTENT}/audio/*/recorded (${skipped} archives already present)`);
}

main();
