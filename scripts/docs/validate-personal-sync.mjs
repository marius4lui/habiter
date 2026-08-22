#!/usr/bin/env node
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const root = new URL("../../", import.meta.url);
const cache = new Map();

async function contents(path) {
  if (!cache.has(path)) cache.set(path, await readFile(new URL(path, root), "utf8"));
  return cache.get(path);
}

const deliverables = [
  ["Beta framing", "docs/guide/personal-sync.md", ["optional, self-hosted Beta", "not a backup"]],
  ["ownership and privacy", "docs/guide/personal-sync.md", ["operator owns availability", "one private data space"]],
  ["sync data boundaries", "docs/guide/personal-sync.md", ["Data boundaries", "never synchronized"]],
  ["Docker requirements and installation", "docs/install/personal-sync-docker.md", ["Prerequisites", "docker compose"]],
  ["Docker setup", "docs/install/personal-sync-docker.md", ["Create the one account", "--password-stdin"]],
  ["reverse proxy and HTTPS", "docs/install/personal-sync-docker.md", ["reverse proxy", "HTTPS"]],
  ["Docker lifecycle", "docs/install/personal-sync-docker.md", ["Upgrade", "Backup", "Restore", "Rollback", "Uninstall"]],
  ["Worker prerequisites", "docs/install/personal-sync-worker.md", ["Prerequisites", "wrangler"]],
  ["Worker lifecycle", "docs/install/personal-sync-worker.md", ["Update checklist", "Backup", "Restore"]],
  ["platform connection", "docs/guide/personal-sync.md", ["Connect a device", "Android", "iOS", "Desktop", "Web"]],
  ["browser handoff", "docs/dev/mobile-sync-handoff.md", ["stateless bridge", "PKCE"]],
  ["automatic timing", "docs/guide/personal-sync.md", ["Automatic synchronization", "not a real-time guarantee"]],
  ["initial merge", "docs/guide/personal-sync.md", ["Initial merge and conflicts", "both sides populated"]],
  ["device and account management", "docs/guide/personal-sync.md", ["Devices, sessions, and account actions", "Revoke all devices"]],
  ["troubleshooting", "docs/guide/personal-sync.md", ["Troubleshooting", "Snapshot recovery"]],
  ["security hardening", "docs/guide/personal-sync.md", ["Security hardening", "exact redirect/CORS allowlists"]],
  ["free limits and inspection", "docs/install/personal-sync-worker.md", ["Free-plan", "usage"]],
  ["protocol and compatibility", "docs/api/personal-sync-http.md", ["versioned HTTP contract", "/v1/snapshot"]],
  ["developer SQLite and D1 evidence", "docs/dev/personal-sync-e2e.md", ["SQLite/Docker", "D1/Worker"]],
  ["Beta migration and rollback", "docs/guide/personal-sync.md", ["Beta limits, compatibility, and rollback", "Future versions"]],
];

for (const [name, path, markers] of deliverables) {
  const document = await contents(path);
  for (const marker of markers) {
    assert.ok(document.toLowerCase().includes(marker.toLowerCase()), `${name} is missing ${marker} in ${path}`);
  }
}

const guide = await contents("docs/guide/personal-sync.md");
for (const statement of [
  "one account and one private data space",
  "does not host your instance or offer a hosted fallback",
  "remains local-first",
  "operator-managed Beta",
]) {
  assert.ok(guide.includes(statement), `Canonical Personal Sync framing is missing: ${statement}`);
}

const navigation = await contents("docs/.vitepress/config.mts");
assert.ok(navigation.includes("/guide/personal-sync"), "Personal Sync guide is missing from VitePress navigation");

for (const link of [
  "/install/personal-sync-docker",
  "/install/personal-sync-worker",
  "/api/personal-sync-http",
  "/dev/personal-sync-data-contract",
  "/dev/personal-sync-convergence",
  "/dev/personal-sync-auth",
  "/dev/personal-sync-sqlite",
  "/dev/personal-sync-d1",
  "/dev/mobile-sync-handoff",
  "/dev/personal-sync-e2e",
]) {
  assert.ok(guide.includes(link), `Personal Sync guide is missing internal reference ${link}`);
}

for (const path of [
  "docs/guide/personal-sync.md",
  "docs/guide/features.md",
  "docs/guide/data-and-privacy.md",
  "docs/install/index.md",
]) {
  const document = await contents(path);
  assert.doesNotMatch(document, /Habiter Cloud|cloud backup|managed sync service/i, `${path} implies a hosted service`);
}

console.log(`Personal Sync documentation covers ${deliverables.length} required deliverables.`);
