import { rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";

const state = ".tmp/migration-state";
await rm(state, { recursive: true, force: true });
const executable = process.platform === "win32" ? "wrangler.cmd" : "wrangler";
run(["d1", "migrations", "apply", "DB", "--local", "--persist-to", state]);
const result = run(["d1", "execute", "DB", "--local", "--persist-to", state, "--command", "SELECT MAX(version) AS version FROM sync_schema_migrations", "--json"]);
const payload = JSON.parse(result.stdout);
const version = payload?.[0]?.results?.[0]?.version;
if (version !== 2) {
  console.error(`Local Worker migrations reached unexpected schema ${String(version)}.`);
  process.exit(1);
}
console.log("Local Worker migrations reached schema 2.");

function run(args) {
  const result = spawnSync(executable, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(result.status ?? 1);
  }
  return result;
}
