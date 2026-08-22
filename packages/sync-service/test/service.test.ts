import { appendFile, mkdtemp, readFile, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { afterEach, describe, expect, it } from "vitest";
import { SqliteSyncStorage, currentSqliteSchemaVersion } from "@habiter/sync-sqlite";

const cli = path.resolve("dist/service.mjs");
const temporaryDirectories: string[] = [];

async function environment(extra: Record<string, string> = {}): Promise<{ env: NodeJS.ProcessEnv; data: string; backups: string }> {
  const root = await mkdtemp(path.join(tmpdir(), "habiter-sync-service-"));
  temporaryDirectories.push(root);
  const data = path.join(root, "data");
  const backups = path.join(root, "backups");
  return { data, backups, env: { ...process.env, HABITER_SYNC_DATA_DIR: data, HABITER_SYNC_BACKUP_DIR: backups, ...extra } };
}

function run(args: string[], env: NodeJS.ProcessEnv, input?: string) {
  return spawnSync(process.execPath, ["--experimental-sqlite", cli, ...args], { env, input, encoding: "utf8", timeout: 15_000 });
}

afterEach(async () => { await Promise.all(temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true }))); });

describe("personal sync service CLI", () => {
  it("migrates without creating an account", async () => {
    const fixture = await environment();
    const migrated = run(["migrate"], fixture.env);
    expect(migrated.status).toBe(0);
    expect(JSON.parse(migrated.stdout)).toMatchObject({ migrated: true, schemaVersion: currentSqliteSchemaVersion });
    const storage = new SqliteSyncStorage(path.join(fixture.data, "sync.sqlite"));
    expect(storage.getAccount()).toBeNull();
    storage.close();
  });

  it("supports one credential-safe setup and rejects password arguments", async () => {
    const fixture = await environment();
    const secret = "correct horse battery staple";
    const configured = run(["setup", "--username", "owner", "--password-stdin"], fixture.env, `${secret}\n`);
    expect(configured.status).toBe(0);
    expect(configured.stdout).not.toContain(secret);
    expect(configured.stderr).not.toContain(secret);
    const storage = new SqliteSyncStorage(path.join(fixture.data, "sync.sqlite"));
    expect(storage.getAccount()?.username).toBe("owner");
    storage.close();
    expect((await stat(path.join(fixture.data, "instance-key"))).mode & 0o777).toBe(0o600);
    expect((await stat(path.join(fixture.data, "sync.sqlite"))).mode & 0o777).toBe(0o600);
    const duplicate = run(["setup", "--username", "owner", "--password-stdin"], fixture.env, `${secret}\n`);
    expect(duplicate.status).toBe(1);
    const exposed = run(["setup", "--username", "owner", "--password", secret], fixture.env);
    expect(exposed.status).toBe(2);
    expect(exposed.stderr).not.toContain(secret);
    expect(exposed.stderr).toContain("secret_argument_forbidden");
  });

  it("performs checksum-verified backup, restore, and rollback drills", async () => {
    const fixture = await environment();
    expect(run(["setup", "--username", "owner", "--password-stdin"], fixture.env, "correct horse battery staple\n").status).toBe(0);
    const backedUp = run(["backup", "drill.sqlite"], fixture.env);
    expect(backedUp.status).toBe(0);
    const backup = JSON.parse(backedUp.stdout) as { manifest: { sha256: string } };
    expect((await stat(path.join(fixture.backups, "drill.sqlite"))).mode & 0o777).toBe(0o600);
    expect(run(["verify", "drill.sqlite", backup.manifest.sha256], fixture.env).status).toBe(0);
    const restored = run(["restore", "drill.sqlite", backup.manifest.sha256], fixture.env);
    expect(restored.status).toBe(0);
    const restoreResult = JSON.parse(restored.stdout) as { rollback: string };
    expect(restoreResult.rollback).toMatch(/^sync\.sqlite\.rollback-\d+$/);
    expect(run(["rollback", restoreResult.rollback], fixture.env).status).toBe(0);
    await appendFile(path.join(fixture.backups, "drill.sqlite"), "tampered");
    const tampered = run(["verify", "drill.sqlite", backup.manifest.sha256], fixture.env);
    expect(tampered.status).toBe(1);
    expect(tampered.stderr).not.toContain(fixture.data);
    expect(await readFile(path.join(fixture.backups, "drill.sqlite.json"), "utf8")).toContain(backup.manifest.sha256);
  });

  it("serves health and stops gracefully on SIGTERM", async () => {
    const port = 43_000 + Math.floor(Math.random() * 1_000);
    const fixture = await environment({ HABITER_SYNC_BASE_URL: `http://127.0.0.1:${port}`, HABITER_SYNC_REDIRECT_URIS: `http://127.0.0.1:${port}/callback`, HABITER_SYNC_PORT: String(port), HABITER_SYNC_HOST: "127.0.0.1" });
    const child = spawn(process.execPath, ["--experimental-sqlite", cli, "serve"], { env: fixture.env, stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk) => { output += chunk; });
    await waitUntil(() => output.includes('"event":"ready"'));
    const response = await fetch(`http://127.0.0.1:${port}/v1/health`);
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ status: "ok" });
    child.kill("SIGTERM");
    const exit = await new Promise<number | null>((resolve) => child.once("exit", resolve));
    expect(exit).toBe(0);
    expect(output).toContain('"event":"shutdown"');
  });

  it("fails closed for an unsafe or path-prefixed public URL", async () => {
    const fixture = await environment({ HABITER_SYNC_BASE_URL: "http://public.example/sync", HABITER_SYNC_REDIRECT_URIS: "https://app.example/callback" });
    const result = run(["serve"], fixture.env);
    expect(result.status).toBe(2);
    expect(result.stderr).toContain("invalid_configuration");
  });
});

async function waitUntil(condition: () => boolean): Promise<void> {
  const deadline = Date.now() + 10_000;
  while (!condition()) {
    if (Date.now() >= deadline) throw new Error("service did not become ready");
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
}
