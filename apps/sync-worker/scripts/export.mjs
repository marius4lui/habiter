import { mkdir, rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";

const mode = process.argv[2];
if (mode !== "--local" && mode !== "--remote") {
  console.error("Export mode must be --local or --remote.");
  process.exit(2);
}
await mkdir(new URL("../backups/", import.meta.url), { recursive: true, mode: 0o700 });
const name = mode === "--local" ? "local.sql" : "remote.sql";
const output = `backups/${name}`;
await rm(new URL(`../${output}`, import.meta.url), { force: true });
const executable = process.platform === "win32" ? "wrangler.cmd" : "wrangler";
const result = spawnSync(executable, ["d1", "export", "DB", mode, "--output", output], { encoding: "utf8", stdio: "inherit" });
if (result.status !== 0) process.exit(result.status ?? 1);
console.log(`Created ${output}; copy it to encrypted operator storage.`);
