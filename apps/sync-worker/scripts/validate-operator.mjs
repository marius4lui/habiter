import { readFile } from "node:fs/promises";

const config = await readFile(new URL("../wrangler.jsonc", import.meta.url), "utf8");
const setup = await readFile(new URL("./setup.mjs", import.meta.url), "utf8");
const docs = await readFile(new URL("../../../docs/install/personal-sync-worker.md", import.meta.url), "utf8");
const ignored = await readFile(new URL("../.gitignore", import.meta.url), "utf8");
for (const secret of ["HABITER_SYNC_INSTANCE_KEY", "HABITER_SYNC_SETUP_TOKEN"]) {
  if (config.includes(secret)) fail(`${secret} must not be committed in Wrangler vars.`);
}
for (const item of [".dev.vars", ".wrangler/", "backups/"]) if (!ignored.includes(item)) fail(`${item} must remain ignored.`);
for (const label of ["Beta", "setup", "migrate:remote", "deploy:dry", "backup:remote", "restore:remote", "bookmark:remote", "rollback:remote", "fail closed", "5,000,000", "100,000", "500 MB", "7 days"]) if (!docs.includes(label)) fail(`Operator documentation is missing ${label}.`);
if (!config.includes('"cpu_ms": 10')) fail("Worker Free CPU limit must be explicit.");
if (!setup.includes('finally {') || !setup.includes('"secret", "delete", "HABITER_SYNC_SETUP_TOKEN"')) fail("Remote setup must always delete its one-time secret.");
console.log("Personal Sync Worker Beta operator contract is valid.");

function fail(message) { console.error(message); process.exit(1); }
