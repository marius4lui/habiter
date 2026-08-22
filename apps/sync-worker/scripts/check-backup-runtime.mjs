import { copyFile, cp, mkdir, rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const source = resolve(".tmp/export-source");
const target = resolve(".tmp/export-target");
const fixture = resolve(".tmp/export-fixture.sql");
await Promise.all([rm(source, { recursive: true, force: true }), rm(target, { recursive: true, force: true }), rm(fixture, { force: true })]);
await Promise.all([prepareProject(source, true), prepareProject(target, false)]);
run(["--cwd", source, "d1", "migrations", "apply", "DB", "--local"]);
run(["--cwd", source, "d1", "execute", "DB", "--local", "--command", "INSERT INTO auth_rate_limits(scope_key, failures, blocked_until, updated_at) VALUES ('fixture', 0, NULL, '2026-08-22T00:00:00.000Z')"]);
run(["--cwd", source, "d1", "export", "DB", "--local", "--output", fixture]);
run(["--cwd", target, "d1", "execute", "DB", "--local", "--file", fixture]);
const result = run(["--cwd", target, "d1", "execute", "DB", "--local", "--command", "SELECT (SELECT MAX(version) FROM sync_schema_migrations) AS version, (SELECT COUNT(*) FROM auth_rate_limits WHERE scope_key = 'fixture') AS fixtures", "--json"]);
const row = JSON.parse(result.stdout)?.[0]?.results?.[0];
if (row?.version !== 2 || row?.fixtures !== 1) {
  console.error("Local D1 export/restore fixture did not preserve schema and data.");
  process.exit(1);
}
console.log("Local D1 export/restore fixture preserved schema and data.");

async function prepareProject(directory, includeMigrations) {
  await mkdir(directory, { recursive: true });
  await copyFile("wrangler.jsonc", resolve(directory, "wrangler.jsonc"));
  if (includeMigrations) {
    await cp("migrations", resolve(directory, "migrations"), { recursive: true });
  }
}

function run(args) {
  const executable = process.platform === "win32" ? "wrangler.cmd" : "wrangler";
  const result = spawnSync(executable, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(result.status ?? 1);
  }
  return result;
}
