import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createServer } from "node:net";

const port = await availablePort();
const origin = `http://127.0.0.1:${port}`;
const executable = process.platform === "win32" ? "wrangler.cmd" : "wrangler";
const child = spawn(executable, ["dev", "--local", "--ip", "127.0.0.1", "--port", String(port)], {
  cwd: new URL("../", import.meta.url),
  env: { ...process.env, WRANGLER_SEND_METRICS: "false" },
  stdio: ["ignore", "pipe", "pipe"],
});
let output = "";
child.stdout.on("data", (chunk) => { output += chunk; });
child.stderr.on("data", (chunk) => { output += chunk; });

try {
  await waitUntilReady(origin);
  const callback = await fetch(`${origin}/auth/callback#code=${"c".repeat(43)}&state=${"s".repeat(32)}`, { redirect: "manual" });
  assert.equal(callback.status, 200);
  assert.equal(callback.headers.get("content-type"), "text/html; charset=utf-8");
  assert.equal(callback.headers.get("cache-control"), "no-store");
  assert.equal(callback.headers.get("referrer-policy"), "no-referrer");
  assert.equal(callback.headers.get("x-content-type-options"), "nosniff");
  assert.equal(callback.headers.get("x-frame-options"), "DENY");
  assert.match(callback.headers.get("content-security-policy") ?? "", /connect-src 'none'/);
  assert.doesNotMatch(await callback.text(), /code=c{10}|state=s{10}/);

  const assetLinks = await fetch(`${origin}/.well-known/assetlinks.json`, { redirect: "manual" });
  assert.equal(assetLinks.status, 200);
  assert.equal(assetLinks.headers.get("content-type"), "application/json; charset=utf-8");
  assert.match(assetLinks.headers.get("cache-control") ?? "", /max-age=3600/);
  JSON.parse(await assetLinks.text());
  const appleAssociation = await fetch(`${origin}/.well-known/apple-app-site-association`, { redirect: "manual" });
  assert.equal(appleAssociation.status, 404);
  const missing = await fetch(`${origin}/not-a-route`, { redirect: "manual" });
  assert.equal(missing.status, 404);
  console.log("Local handoff assets and security headers are valid.");
} finally {
  child.kill("SIGTERM");
  await Promise.race([new Promise((resolve) => child.once("exit", resolve)), new Promise((resolve) => setTimeout(resolve, 5_000))]);
}

function availablePort() {
  return new Promise((resolve, reject) => {
    const server = createServer();
    server.unref();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      server.close(() => resolve(address.port));
    });
  });
}

async function waitUntilReady(origin) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (child.exitCode !== null) throw new Error(`Wrangler stopped before serving assets.\n${output}`);
    try {
      const response = await fetch(origin);
      if (response.ok) return;
    } catch { /* Wrangler is still starting. */ }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`Wrangler did not become ready.\n${output}`);
}
