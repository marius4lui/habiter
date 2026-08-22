import { readFile } from "node:fs/promises";
import { randomBytes, webcrypto } from "node:crypto";
import { spawnSync } from "node:child_process";
import process from "node:process";

class SetupFailure extends Error { constructor(message, code) { super(message); this.code = code; } }

const args = parseArgs(process.argv.slice(2));
let password = await readPassword();
if (password.length < 12 || password.length > 1024) fail("Password must contain between 12 and 1024 characters.", 2);
let setupToken;
let remoteSecretInstalled = false;
let setupFailure;
try {
  if (args.local) setupToken = await localSetupToken();
  else {
    setupToken = randomBytes(32).toString("base64url");
    runWrangler(["secret", "put", "HABITER_SYNC_SETUP_TOKEN"], `${setupToken}\n`);
    remoteSecretInstalled = true;
  }
  const salt = randomBytes(16).toString("base64url");
  const passwordKey = await derive(password, salt);
  password = "";
  const response = await fetch(new URL("/_admin/setup", args.url), {
    method: "POST",
    headers: { authorization: `Bearer ${setupToken}`, "content-type": "application/json" },
    body: JSON.stringify({ username: args.username, passwordKey, salt, iterations: 600_000 }),
  });
  if (!response.ok) throw new SetupFailure(`Worker setup failed with HTTP ${response.status}.`, 1);
  console.log("Worker account initialized.");
} catch (error) {
  setupFailure = error;
} finally {
  password = "";
  setupToken = "";
  if (remoteSecretInstalled) {
    const removed = runWrangler(["secret", "delete", "HABITER_SYNC_SETUP_TOKEN"], "y\n", false);
    if (!removed) console.error("Setup finished, but deleting HABITER_SYNC_SETUP_TOKEN failed; delete it manually now.");
  }
}
if (setupFailure !== undefined) {
  console.error(setupFailure instanceof SetupFailure ? setupFailure.message : "Worker setup failed.");
  process.exit(setupFailure instanceof SetupFailure ? setupFailure.code : 1);
}

function parseArgs(values) {
  for (let index = 0; index < values.length; index += 1) {
    const value = values[index];
    if (value === "--local" || value === "--password-stdin") continue;
    if (value === "--url" || value === "--username") {
      const next = values[index + 1];
      if (!next || next.startsWith("--")) fail("Setup arguments are invalid.", 2);
      index += 1;
      continue;
    }
    fail("Setup arguments are invalid; password arguments are forbidden.", 2);
  }
  if (!values.includes("--password-stdin")) fail("Use --password-stdin; password arguments and environment variables are forbidden.", 2);
  const url = option(values, "--url");
  const username = option(values, "--username");
  if (!url || !username || !/^[A-Za-z0-9._@+-]{1,128}$/.test(username)) fail("--url and a valid --username are required.", 2);
  let parsed;
  try { parsed = new URL(url); } catch { fail("Setup URL is invalid.", 2); }
  if (parsed.protocol !== "https:" && !(parsed.protocol === "http:" && ["localhost", "127.0.0.1", "::1"].includes(parsed.hostname))) fail("Setup URL must use HTTPS.", 2);
  if (parsed.username || parsed.password || parsed.hash || parsed.search || parsed.pathname !== "/") fail("Setup URL must be an origin.", 2);
  return { local: values.includes("--local"), url: parsed.origin, username };
}
function option(values, name) { const index = values.indexOf(name); return index < 0 ? undefined : values[index + 1]; }
async function readPassword() { if (process.stdin.isTTY) fail("Pipe the password through protected standard input.", 2); const chunks = []; let size = 0; for await (const chunk of process.stdin) { const bytes = Buffer.from(chunk); size += bytes.length; if (size > 4096) fail("Password input is too large.", 2); chunks.push(bytes); } return Buffer.concat(chunks).toString("utf8").replace(/[\r\n]+$/, ""); }
async function localSetupToken() { const contents = await readFile(new URL("../.dev.vars", import.meta.url), "utf8"); const match = /^HABITER_SYNC_SETUP_TOKEN=([A-Za-z0-9_-]{43})$/m.exec(contents); if (!match) fail("Local .dev.vars has no valid setup token.", 2); return match[1]; }
async function derive(value, salt) { const bytes = new TextEncoder(); const material = await webcrypto.subtle.importKey("raw", bytes.encode(value), "PBKDF2", false, ["deriveBits"]); const saltBytes = Buffer.from(salt, "base64url"); const bits = await webcrypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: saltBytes, iterations: 600_000 }, material, 256); return Buffer.from(bits).toString("base64url"); }
function runWrangler(command, input, fatal = true) { const executable = process.platform === "win32" ? "wrangler.cmd" : "wrangler"; const result = spawnSync(executable, command, { input, encoding: "utf8", stdio: ["pipe", "inherit", "inherit"] }); if (result.status !== 0 && fatal) fail("Wrangler secret operation failed.", result.status ?? 1); return result.status === 0; }
function fail(message, code) { console.error(message); process.exit(code); }
