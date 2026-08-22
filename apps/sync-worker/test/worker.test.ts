import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { copyFile, mkdir, mkdtemp, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { Miniflare } from "miniflare";
import { afterEach, describe, expect, it } from "vitest";
import { D1SyncStorage, type D1DatabaseLike } from "@habiter/sync-d1";

const workers: Miniflare[] = [];
const temporaryDirectories: string[] = [];
const baseBindings = {
  BASE_URL: "https://sync.example.test",
  REDIRECT_URIS: "https://app.example.test/auth/callback",
  CORS_ORIGINS: "",
  INSTANCE_NAME: "Test Worker Beta",
  AUDIENCE: "habiter-mobile",
  HABITER_SYNC_INSTANCE_KEY: Buffer.alloc(32, 7).toString("base64url"),
  HABITER_SYNC_SETUP_TOKEN: Buffer.alloc(32, 8).toString("base64url"),
};

async function worker(options: { database?: boolean; bindings?: Record<string, string> } = {}): Promise<Miniflare> {
  const miniflare = new Miniflare({
    modules: true,
    scriptPath: fileURLToPath(new URL("../.tmp/worker.mjs", import.meta.url)),
    compatibilityDate: "2026-08-15",
    bindings: { ...baseBindings, ...options.bindings },
    ...(options.database === false ? {} : { d1Databases: { DB: crypto.randomUUID() } }),
  });
  await miniflare.ready;
  workers.push(miniflare);
  return miniflare;
}

async function migrate(miniflare: Miniflare): Promise<void> {
  const database = await miniflare.getD1Database("DB") as unknown as D1DatabaseLike;
  const storage = await D1SyncStorage.open(database, { migrate: true, generation: "worker-distribution-test" });
  await storage.close();
}

afterEach(async () => {
  await Promise.all(workers.splice(0).map((item) => item.dispose()));
  await Promise.all(temporaryDirectories.splice(0).map((item) => rm(item, { recursive: true, force: true })));
});

describe("Personal Sync Worker distribution", () => {
  it("rejects passwords and instance keys passed as process arguments", () => {
    const setup = spawnSync(process.execPath, ["scripts/setup.mjs", "--password-stdin", "--url", "https://sync.example.test", "--username", "owner", "literal-password"], { input: "protected-password-material\n", encoding: "utf8" });
    expect(setup.status).toBe(2);
    expect(setup.stderr).not.toContain("literal-password");
    expect(setup.stderr).not.toContain("protected-password-material");
    const key = spawnSync(process.execPath, ["scripts/configure-instance-key.mjs", "literal-instance-key"], { encoding: "utf8" });
    expect(key.status).toBe(2);
    expect(key.stderr).not.toContain("literal-instance-key");
  });

  it("creates local secrets privately without printing or implicit rotation", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "habiter-worker-secrets-"));
    temporaryDirectories.push(directory);
    await mkdir(path.join(directory, "scripts"));
    const script = path.join(directory, "scripts", "prepare-local.mjs");
    await copyFile("scripts/prepare-local.mjs", script);
    const first = spawnSync(process.execPath, [script], { encoding: "utf8" });
    expect(first.status).toBe(0);
    expect(first.stdout).not.toMatch(/[A-Za-z0-9_-]{43}/);
    expect((await stat(path.join(directory, ".dev.vars"))).mode & 0o777).toBe(0o600);
    const second = spawnSync(process.execPath, [script], { encoding: "utf8" });
    expect(second.status).toBe(2);
  });

  it("fails closed for a missing D1 binding", async () => {
    const miniflare = await worker({ database: false });
    const response = await miniflare.dispatchFetch("https://sync.example.test/v1/health");
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: "service_unavailable", message: "Personal Sync is unavailable" });
  });

  it("fails closed for an uninitialized or newer schema and a missing instance key", async () => {
    const empty = await worker();
    expect((await empty.dispatchFetch("https://sync.example.test/v1/health")).status).toBe(503);
    const database = await empty.getD1Database("DB");
    await database.prepare("CREATE TABLE sync_schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL) STRICT").run();
    await database.prepare("INSERT INTO sync_schema_migrations VALUES (99, 'future', CURRENT_TIMESTAMP)").run();
    expect((await empty.dispatchFetch("https://sync.example.test/v1/health")).status).toBe(503);

    const missingKey = await worker({ bindings: { HABITER_SYNC_INSTANCE_KEY: "" } });
    await migrate(missingKey);
    expect((await missingKey.dispatchFetch("https://sync.example.test/v1/health")).status).toBe(503);
  });

  it("serves the shared API only after migrations", async () => {
    const miniflare = await worker();
    await migrate(miniflare);
    const response = await miniflare.dispatchFetch("https://sync.example.test/v1/health", { headers: { "x-request-id": "request-12345678" } });
    expect(response.status).toBe(200);
    expect(response.headers.get("x-request-id")).toBe("request-12345678");
    expect(await response.json()).toEqual({ status: "ok", version: 1 });
  });

  it("requires the one-time setup token and initializes exactly once", async () => {
    const miniflare = await worker();
    await migrate(miniflare);
    const setup = { username: "owner", passwordKey: Buffer.alloc(32, 11).toString("base64url"), salt: Buffer.alloc(16, 13).toString("base64url"), iterations: 600_000 };
    const denied = await miniflare.dispatchFetch("https://sync.example.test/_admin/setup", { method: "POST", headers: { authorization: "Bearer wrong", "content-type": "application/json" }, body: JSON.stringify(setup) });
    expect(denied.status).toBe(401);
    const headers = { authorization: `Bearer ${baseBindings.HABITER_SYNC_SETUP_TOKEN}`, "content-type": "application/json" };
    expect((await miniflare.dispatchFetch("https://sync.example.test/_admin/setup", { method: "POST", headers, body: JSON.stringify(setup) })).status).toBe(204);
    expect((await miniflare.dispatchFetch("https://sync.example.test/_admin/setup", { method: "POST", headers, body: JSON.stringify(setup) })).status).toBe(409);
    const info = await miniflare.dispatchFetch("https://sync.example.test/v1/instance-info");
    expect(await info.json()).toMatchObject({ initialized: true, name: "Test Worker Beta" });
  });

  it("does not expose setup on a different origin or without a configured token", async () => {
    const miniflare = await worker({ bindings: { HABITER_SYNC_SETUP_TOKEN: "" } });
    await migrate(miniflare);
    expect((await miniflare.dispatchFetch("https://other.example/_admin/setup", { method: "POST" })).status).toBe(404);
    expect((await miniflare.dispatchFetch("https://sync.example.test/_admin/setup", { method: "POST" })).status).toBe(401);
  });
});
