import { execFileSync } from "node:child_process";
import { rmSync } from "node:fs";
import path from "node:path";

const persistence = path.resolve(".tmp/wrangler");
const wrangler = path.resolve("node_modules/.bin", process.platform === "win32" ? "wrangler.cmd" : "wrangler");
rmSync(persistence, { recursive: true, force: true });

const common = ["--local", "--persist-to", persistence, "--config", "wrangler.jsonc"];
execFileSync(wrangler, ["d1", "migrations", "apply", "DB", ...common], { stdio: "pipe" });
const output = execFileSync(
  wrangler,
  ["d1", "execute", "DB", ...common, "--command", "SELECT MAX(version) AS version FROM sync_schema_migrations", "--json"],
  { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
);
const result = JSON.parse(output);
const version = result[0]?.results?.[0]?.version;
if (version !== 2) throw new Error(`Expected local D1 schema 2, received ${String(version)}`);
process.stdout.write(`Local D1 migrations reached schema ${version}.\n`);
