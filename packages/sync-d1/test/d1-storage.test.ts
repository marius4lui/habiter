import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { Miniflare } from "miniflare";
import {
  createOperation,
  materializeEntity,
  type EntityDocument,
  type SyncOperation,
  type SyncStorage,
} from "@habiter/sync-core";
import { registerStorageConformanceSuite } from "@habiter/sync-core/test-support";
import { describe, expect, it } from "vitest";
import { D1StorageError, D1SyncStorage, type D1ExportFixture, type D1QueryUsage } from "../src/index";

const workerPath = fileURLToPath(new URL("../.tmp/worker.mjs", import.meta.url));
const owners = new WeakMap<object, Miniflare>();
const usageByStorage = new WeakMap<object, D1QueryUsage>();
const maxStatementsByStorage = new WeakMap<object, number>();

async function createMiniflare(): Promise<Miniflare> {
  await readFile(workerPath);
  const miniflare = new Miniflare({
    modules: true,
    scriptPath: workerPath,
    compatibilityDate: "2026-08-15",
    compatibilityFlags: ["nodejs_compat"],
    d1Databases: { DB: crypto.randomUUID() },
  });
  await miniflare.ready;
  return miniflare;
}

async function call<T>(miniflare: Miniflare, method: string, args: unknown[] = [], extra: object = {}): Promise<{ result: T; usage?: D1QueryUsage }> {
  const response = await miniflare.dispatchFetch("http://local.test/", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ method, args, ...extra }),
  });
  const body = await response.json() as { result: T; usage?: D1QueryUsage; error?: { code: string; message: string; cause?: string } };
  if (!response.ok) {
    const error = new Error(body.error?.message ?? "D1 worker request failed") as Error & { code: string };
    error.code = body.error?.code ?? "worker_error";
    if (body.error?.cause) error.message += `: ${body.error.cause}`;
    throw error;
  }
  return body;
}

async function createProxy(): Promise<SyncStorage> {
  const miniflare = await createMiniflare();
  await call(miniflare, "open", [], { migrate: true });
  const target = { schemaVersion: 2 };
  const proxy = new Proxy(target, {
    get(object, property) {
      if (property === "schemaVersion") return object.schemaVersion;
      if (property === "then") return undefined;
      if (property === "close") return async () => undefined;
      if (typeof property !== "string") return undefined;
      return async (...args: unknown[]) => {
        const response = await call<unknown>(miniflare, property, args);
        if (response.usage) {
          const current = usageByStorage.get(proxy) ?? { statements: 0, rowsRead: 0, rowsWritten: 0 };
          current.statements += response.usage.statements;
          current.rowsRead += response.usage.rowsRead;
          current.rowsWritten += response.usage.rowsWritten;
          usageByStorage.set(proxy, current);
          maxStatementsByStorage.set(proxy, Math.max(maxStatementsByStorage.get(proxy) ?? 0, response.usage.statements));
        }
        return response.result;
      };
    },
  }) as unknown as SyncStorage;
  owners.set(proxy, miniflare);
  return proxy;
}

async function disposeProxy(storage: SyncStorage): Promise<void> {
  await owners.get(storage)?.dispose();
}

registerStorageConformanceSuite({ name: "local D1", create: createProxy, cleanup: disposeProxy });

const habit = (name: string): EntityDocument => ({
  schemaVersion: 1,
  entityId: "habit/habit-a",
  deleted: false,
  payload: {
    id: "habit-a", name, description: "Daily", color: "#4CAF50", icon: "walk",
    frequency: "daily", targetCount: 1, category: "Health", customDays: null,
    createdAt: "2026-08-21T06:00:00.000Z", isActive: true,
    notificationEnabled: false, notificationTime: null,
  },
});

const operation = (name: string, deviceId: string, sequence: number, kind: "create" | "patch" = "patch"): SyncOperation => createOperation({
  kind,
  revision: { deviceId, sequence },
  document: habit(name),
  changedFields: kind === "create" ? Object.keys(habit(name).payload!) : ["name"],
  changedMetadataFields: [],
});

describe("D1 adapter platform behavior", () => {
  it("fails closed for a missing binding", async () => {
    await expect(D1SyncStorage.open(undefined, { migrate: true })).rejects.toBeInstanceOf(D1StorageError);
    await expect(D1SyncStorage.open(undefined, { migrate: true })).rejects.toMatchObject({ code: "missing_binding" });
  });

  it("fails closed for an uninitialized or newer schema", async () => {
    const miniflare = await createMiniflare();
    try {
      await expect(call(miniflare, "open", [], { migrate: false })).rejects.toMatchObject({ code: "schema_uninitialized" });
      await call(miniflare, "rawVersion", [], { version: 99 });
      await expect(call(miniflare, "open", [], { migrate: true })).rejects.toMatchObject({ code: "database_newer_than_service" });
    } finally {
      await miniflare.dispose();
    }
  });

  it("rolls back each failed migration batch and exposes the failure", async () => {
    const miniflare = await createMiniflare();
    try {
      await expect(call(miniflare, "failingMigration")).rejects.toMatchObject({ code: "migration_failed" });
      const version = await call<{ results: Array<{ version: number }> }>(miniflare, "sql", ["SELECT MAX(version) AS version FROM sync_schema_migrations"]);
      expect(version.result.results[0]?.version).toBe(1);
      const table = await call<{ results: Array<{ name: string }> }>(miniflare, "sql", ["SELECT name FROM sqlite_master WHERE name = 'should_rollback'"]);
      expect(table.result.results).toEqual([]);
    } finally {
      await miniflare.dispose();
    }
  });

  it("uses indexes for cursor, receipt, and auth lookup plans", async () => {
    const miniflare = await createMiniflare();
    try {
      await call(miniflare, "open", [], { migrate: true });
      const queries = [
        ["SELECT operation_json FROM sync_operations WHERE server_cursor > ? ORDER BY server_cursor LIMIT ?", 0, 10],
        ["SELECT fingerprint FROM sync_operation_receipts WHERE operation_id = ? LIMIT 1", "operation/device/1"],
        ["SELECT refresh_hash FROM auth_sessions WHERE device_id = ? AND revoked_at IS NULL", "phone-a"],
      ];
      for (const [sql, ...values] of queries) {
        const plan = await call<{ results: Array<{ detail: string }> }>(miniflare, "sql", [`EXPLAIN QUERY PLAN ${sql}`, ...values]);
        expect(plan.result.results.map((row) => row.detail).join(" ")).toMatch(/SEARCH|INTEGER PRIMARY KEY/);
      }
    } finally {
      await miniflare.dispose();
    }
  });

  it("retries concurrent entity writers without losing either operation", async () => {
    const storage = await createProxy();
    try {
      await storage.commit(operation("Initial", "phone-a", 1, "create"));
      await Promise.all([
        storage.commit(operation("From A", "phone-a", 2)),
        storage.commit(operation("From B", "phone-b", 2)),
      ]);
      const pull = await storage.pull(null, 10);
      expect(pull.operations).toHaveLength(3);
      const document = materializeEntity((await storage.snapshot()).entities[0]!);
      expect(document?.payload?.name).toBe("From B");
    } finally {
      await disposeProxy(storage);
    }
  });

  it("exports and restores a checksum-verified logical fixture", async () => {
    const source = await createProxy();
    const destination = await createMiniflare();
    try {
      await source.commit(operation("Exported", "phone-a", 1, "create"));
      const fixture = await (source as unknown as { exportFixture(): Promise<D1ExportFixture> }).exportFixture();
      expect(fixture.sha256).toMatch(/^[a-f0-9]{64}$/);
      const restored = await call<{ entities: unknown[] }>(destination, "restore", [], { fixture });
      expect(restored.result.entities).toEqual((await source.snapshot()).entities);
      await expect(call(destination, "restore", [], { fixture: { ...fixture, sha256: "0".repeat(64) } })).rejects.toMatchObject({ code: "fixture_verification_failed" });
    } finally {
      await destination.dispose();
      await disposeProxy(source);
    }
  });

  it("keeps a representative personal-write day well below free-plan row limits", async () => {
    const storage = await createProxy();
    try {
      await storage.commit(operation("Initial", "phone-a", 1, "create"));
      for (let sequence = 2; sequence <= 101; sequence += 1) {
        await storage.commit(operation(`Edit ${sequence}`, "phone-a", sequence));
      }
      await storage.pull(null, 500);
      const usage = usageByStorage.get(storage)!;
      expect(usage).toEqual({ statements: 1_119, rowsRead: 1_112, rowsWritten: 910 });
      expect(maxStatementsByStorage.get(storage)).toBeLessThanOrEqual(11);
      expect(usage.rowsRead).toBeLessThan(50_000);
      expect(usage.rowsWritten).toBeLessThan(2_000);
      expect(usage.rowsRead / 5_000_000).toBeLessThan(0.01);
      expect(usage.rowsWritten / 100_000).toBeLessThan(0.02);
    } finally {
      await disposeProxy(storage);
    }
  });
});
