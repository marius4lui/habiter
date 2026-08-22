import { readFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const files = {
  evidence: await read("docs/dev/personal-sync-e2e.md"),
  quality: await read(".github/workflows/quality.yml"),
  platforms: await read(".github/workflows/platform-builds.yml"),
  docker: await read(".github/workflows/sync-docker.yml"),
  http: await read("packages/sync-http/test/http.test.ts"),
  sqlite: await read("packages/sync-sqlite/test/sqlite-storage.test.ts"),
  d1: await read("packages/sync-d1/test/d1-storage.test.ts"),
};

for (const command of [
  "sync:check",
  "sync:auth:check",
  "sync:http:check",
  "sync:service:check",
  "sync:worker:check",
  "mobile:handoff:check",
  "sync:d1:check",
  "sync:docker:check",
  "sync:sqlite:check",
]) {
  requireText(files.quality, `pnpm ${command}`, `quality gate ${command}`);
}
for (const target of ["android", "web", "linux", "macos", "windows", "ios"]) {
  requireText(files.platforms, target, `platform build ${target}`);
}
for (const step of ["docker compose build", "backup", "restore", "rollback", "docker compose down"]) {
  requireText(files.docker, step, `Docker lifecycle step ${step}`);
}
requireText(files.http, "converges two authenticated offline devices", "two-device HTTP parity scenario");
requireText(files.sqlite, "registerStorageConformanceSuite", "SQLite shared conformance registration");
requireText(files.d1, "registerStorageConformanceSuite", "D1 shared conformance registration");
requireText(files.d1, "representative personal-write day", "D1 query-accounting scenario");

for (const heading of [
  "Backend parity",
  "App and platform matrix",
  "Scenario ownership",
  "Unverified and blocked ledger",
]) {
  requireText(files.evidence, `## ${heading}`, `evidence section ${heading}`);
}
for (const boundary of [
  "physical Android",
  "physical iOS",
  "hosted Worker/D1",
  "operator-managed Docker",
]) {
  requireText(files.evidence, boundary, `explicit unverified boundary ${boundary}`);
}

console.log("Personal Sync E2E evidence matrix is connected to its reproducible gates.");

async function read(relative) {
  return readFile(new URL(relative, root), "utf8");
}

function requireText(value, expected, label) {
  if (!value.includes(expected)) {
    console.error(`Missing ${label}.`);
    process.exit(1);
  }
}
