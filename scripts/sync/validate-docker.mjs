import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";

const root = new URL("../../", import.meta.url);
const files = {
  dockerfile: await read("deploy/personal-sync/Dockerfile"),
  compose: await read("deploy/personal-sync/compose.yaml"),
  environment: await read("deploy/personal-sync/.env.example"),
  docs: await read("docs/install/personal-sync-docker.md"),
  service: await read("packages/sync-service/src/cli.ts"),
};

requireText(files.dockerfile, "node:24.13.1-bookworm-slim@sha256:", "pinned Node base image");
requireText(files.dockerfile, "USER node:node", "non-root runtime user");
requireText(files.dockerfile, "dev.habiter.distribution=\"beta\"", "Beta image label");
requireText(files.compose, "read_only: true", "read-only root filesystem");
requireText(files.compose, "no-new-privileges:true", "no-new-privileges");
requireText(files.compose, "cap_drop:\n      - ALL", "dropped Linux capabilities");
requireText(files.compose, "127.0.0.1", "loopback default binding");
requireText(files.compose, "sync-data:/var/lib/habiter-sync", "persistent data volume");
requireText(files.compose, "sync-backups:/var/lib/habiter-sync-backups", "persistent backup volume");
requireText(files.compose, "healthcheck:", "container health check");
requireText(files.service, "secret_argument_forbidden", "password argument rejection");
if (/HABITER_SYNC_(?:PASSWORD|INSTANCE_KEY)\s*:/.test(files.compose)) fail("Compose must not accept password or instance-key environment variables");
for (const section of [files.environment, files.docs, files.compose]) requireText(section, "Beta", "consistent Beta labeling");
for (const command of ["setup", "backup", "verify", "restore", "rollback", "down --volumes"]) requireText(files.docs, command, `documented ${command} lifecycle`);

const compose = spawnSync("docker", ["compose", "--env-file", "deploy/personal-sync/.env.example", "-f", "deploy/personal-sync/compose.yaml", "config"], { cwd: root, encoding: "utf8" });
if (compose.status !== 0) fail(`Docker Compose contract is invalid: ${compose.stderr.trim()}`);
for (const value of ["read_only: true", "no-new-privileges:true", "habiter-personal-sync-data", "habiter-personal-sync-backups"]) requireText(compose.stdout, value, `rendered Compose ${value}`);

console.log("Personal Sync Docker Beta contract is valid.");

async function read(relative) { return readFile(new URL(relative, root), "utf8"); }
function requireText(value, expected, label) { if (!value.includes(expected)) fail(`Missing ${label}`); }
function fail(message) { console.error(message); process.exit(1); }
