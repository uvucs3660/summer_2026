import { execFileSync } from "node:child_process";
import * as http from "node:http";

const siteUrl = process.argv[2];
if (!siteUrl?.startsWith("https://")) {
  console.error("usage: tsx scripts/setup-app.ts https://<site>.netlify.app");
  process.exit(1);
}
const PORT = 8799;
const manifest = {
  name: "cs3540-lectures",
  url: siteUrl,
  redirect_url: `http://localhost:${PORT}/converted`,
  callback_urls: [`${siteUrl}/api/auth/callback`],
  public: true,
  hook_attributes: { active: false },
  default_permissions: {},
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url ?? "/", `http://localhost:${PORT}`);
  if (url.pathname === "/") {
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(`<!doctype html><body>
      <form id="f" action="https://github.com/settings/apps/new" method="post">
        <input type="hidden" name="manifest" value='${JSON.stringify(manifest).replace(/'/g, "&#39;")}'>
      </form>
      <p>Submitting the app manifest to GitHub…</p>
      <script>document.getElementById('f').submit()</script></body>`);
    return;
  }
  if (url.pathname === "/converted") {
    const code = url.searchParams.get("code");
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end("<body><p>App created — you can close this tab.</p></body>");
    server.close();
    if (!code) { console.error("GitHub redirected without a code"); process.exit(1); }
    const out = execFileSync("gh", ["api", "-X", "POST", `/app-manifests/${code}/conversions`], { encoding: "utf8" });
    const app = JSON.parse(out) as { client_id?: string; client_secret?: string };
    if (!app.client_id || !app.client_secret) { console.error("conversion response missing credentials"); process.exit(1); }
    console.log(`CLIENT_ID=${app.client_id}`);
    console.log(`CLIENT_SECRET=${app.client_secret}`);
    process.exit(0);
  }
  res.writeHead(404); res.end();
});

server.listen(PORT, "127.0.0.1", () => {
  console.error(`Open http://localhost:${PORT}/ — one click on "Create GitHub App" finishes this.`);
  execFileSync("open", [`http://localhost:${PORT}/`]);
});
