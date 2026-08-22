import { randomBytes } from "node:crypto";
import { spawnSync } from "node:child_process";

const wrangler = process.platform === "win32" ? "wrangler.cmd" : "wrangler";
if (process.argv.slice(2).some((value) => value !== "--key-stdin")) {
  console.error("Only --key-stdin is supported; secret arguments are forbidden.");
  process.exit(2);
}
const secret = process.argv.includes("--key-stdin") ? await readSecret() : randomBytes(32).toString("base64url");
if (!/^[A-Za-z0-9_-]{43}$/.test(secret) || Buffer.from(secret, "base64url").toString("base64url") !== secret || Buffer.from(secret, "base64url").byteLength !== 32) {
  console.error("Instance key must be canonical base64url for exactly 32 bytes.");
  process.exit(2);
}
const result = spawnSync(wrangler, ["secret", "put", "HABITER_SYNC_INSTANCE_KEY"], { input: `${secret}\n`, encoding: "utf8", stdio: ["pipe", "inherit", "inherit"] });
if (result.status !== 0) {
  console.error("Failed to configure the Worker instance key.");
  process.exit(result.status ?? 1);
}
console.log("Configured a new Worker instance key without printing it.");

async function readSecret() {
  if (process.stdin.isTTY) {
    console.error("Pipe the protected instance key through standard input.");
    process.exit(2);
  }
  const chunks = [];
  let size = 0;
  for await (const chunk of process.stdin) {
    const bytes = Buffer.from(chunk);
    size += bytes.length;
    if (size > 256) {
      console.error("Instance-key input is too large.");
      process.exit(2);
    }
    chunks.push(bytes);
  }
  return Buffer.concat(chunks).toString("utf8").trim();
}
