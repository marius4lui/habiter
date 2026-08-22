import { appendFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";
import {
  createOperation,
  materializeEntity,
  type AuthAccountRecord,
  type EntityDocument,
  type SyncOperation,
} from "@habiter/sync-core";
import { registerStorageConformanceSuite } from "@habiter/sync-core/test-support";
import { describe, expect, it } from "vitest";
import {
  SqliteSyncStorage,
  currentSqliteSchemaVersion,
  sqliteMigrations,
  type SqliteMigration,
} from "../src/index";

registerStorageConformanceSuite({
  name: "SQLite",
  create: () => new SqliteSyncStorage(":memory:", { generation: "conformance-generation" }),
});

const habit = (name: string): EntityDocument => ({
  schemaVersion: 1,
  entityId: "habit/habit-a",
  deleted: false,
  payload: {
    id: "habit-a",
    name,
    description: "Daily",
    color: "#4CAF50",
    icon: "walk",
    frequency: "daily",
    targetCount: 1,
    category: "Health",
    customDays: null,
    createdAt: "2026-08-21T06:00:00.000Z",
    isActive: true,
    notificationEnabled: false,
    notificationTime: null,
  },
});

const createHabit = (name: string, deviceId = "server-a", sequence = 1): SyncOperation =>
  createOperation({
    kind: "create",
    revision: { deviceId, sequence },
    document: habit(name),
    changedFields: Object.keys(habit(name).payload!),
    changedMetadataFields: [],
  });

const patchHabit = (name: string, deviceId = "server-a", sequence = 2): SyncOperation =>
  createOperation({
    kind: "patch",
    revision: { deviceId, sequence },
    document: habit(name),
    changedFields: ["name"],
    changedMetadataFields: [],
  });

const account: AuthAccountRecord = {
  username: "owner",
  verifier: { algorithm: "test", value: "verifier" },
  passwordVersion: 1,
  createdAt: "2026-08-21T06:00:00.000Z",
  updatedAt: "2026-08-21T06:00:00.000Z",
};

async function withTempDirectory(run: (directory: string) => Promise<void>): Promise<void> {
  const directory = await mkdtemp(path.join(tmpdir(), "habiter-sync-sqlite-"));
  try {
    await run(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

function snapshotName(storage: SqliteSyncStorage): unknown {
  const entity = storage.snapshot().entities[0];
  return entity === undefined ? undefined : materializeEntity(entity)?.payload?.name;
}

describe("SQLite adapter durability", () => {
  it("applies contiguous migrations and creates the required indexes", () => {
    const storage = new SqliteSyncStorage(":memory:");
    try {
      expect(storage.schemaVersion).toBe(currentSqliteSchemaVersion);
      const raw = new DatabaseSync(":memory:");
      try {
        for (const migration of sqliteMigrations) raw.exec(migration.sql);
        const indexes = raw.prepare(`
          SELECT name FROM sqlite_master
          WHERE type = 'index' AND name NOT LIKE 'sqlite_%'
          ORDER BY name
        `).all().map((row) => row.name);
        expect(indexes).toEqual(expect.arrayContaining([
          "auth_one_time_expiry",
          "auth_sessions_device",
          "auth_sessions_family",
          "sync_operations_device_sequence",
          "sync_operations_entity_cursor",
        ]));
      } finally {
        raw.close();
      }
    } finally {
      storage.close();
    }
  });

  it("rolls back a failed migration atomically", async () => {
    await withTempDirectory(async (directory) => {
      const filename = path.join(directory, "migration.sqlite");
      const storage = new SqliteSyncStorage(filename, { migrations: [sqliteMigrations[0]!] });
      const failing: SqliteMigration = {
        version: 2,
        name: "failing_migration",
        sql: "CREATE TABLE should_rollback(value TEXT) STRICT; INVALID SQL;",
      };
      try {
        expect(() => storage.migrate([sqliteMigrations[0]!, failing])).toThrowError(
          expect.objectContaining({ code: "migration_failed" }),
        );
        expect(storage.schemaVersion).toBe(1);
      } finally {
        storage.close();
      }
      const raw = new DatabaseSync(filename, { readOnly: true });
      try {
        expect(raw.prepare("SELECT name FROM sqlite_master WHERE name = 'should_rollback'").get()).toBeUndefined();
      } finally {
        raw.close();
      }
    });
  });

  it("rolls back a commit when metadata persistence fails", async () => {
    await withTempDirectory(async (directory) => {
      const filename = path.join(directory, "transaction.sqlite");
      const storage = new SqliteSyncStorage(filename);
      const raw = new DatabaseSync(filename);
      try {
        raw.exec("DELETE FROM sync_metadata WHERE key = 'head_offset'");
        expect(() => storage.commit(createHabit("Rolled back"))).toThrowError(
          expect.objectContaining({ code: "database_metadata_missing" }),
        );
        expect((raw.prepare("SELECT COUNT(*) AS count FROM sync_operations").get() as { count: number }).count).toBe(0);
        expect((raw.prepare("SELECT COUNT(*) AS count FROM sync_entities").get() as { count: number }).count).toBe(0);
        expect((raw.prepare("SELECT COUNT(*) AS count FROM sync_operation_receipts").get() as { count: number }).count).toBe(0);
      } finally {
        raw.close();
        storage.close();
      }
    });
  });

  it("survives process-style close and reopen with stable cursors", async () => {
    await withTempDirectory(async (directory) => {
      const filename = path.join(directory, "restart.sqlite");
      const first = new SqliteSyncStorage(filename, { generation: "generation-a" });
      const cursor = first.commit(createHabit("Persistent")).cursor;
      first.createAccount(account);
      first.close();

      const second = new SqliteSyncStorage(filename, { generation: "ignored-new-generation" });
      try {
        expect(second.snapshot().cursor).toBe(cursor);
        expect(snapshotName(second)).toBe("Persistent");
        expect(second.getAccount()).toEqual(account);
        expect(second.pull(cursor, 10).operations).toEqual([]);
      } finally {
        second.close();
      }
    });
  });

  it("coordinates two writers against one WAL database", async () => {
    await withTempDirectory(async (directory) => {
      const filename = path.join(directory, "writers.sqlite");
      const first = new SqliteSyncStorage(filename, { generation: "shared-generation" });
      const second = new SqliteSyncStorage(filename);
      try {
        const create = createHabit("Initial");
        const committed = first.commit(create);
        expect(second.commit(create)).toMatchObject({
          cursor: committed.cursor,
          duplicate: true,
        });
        second.commit(patchHabit("Updated"));
        expect(first.pull(null, 10).operations.map((item) => item.operationId)).toEqual([
          "operation/server-a/1",
          "operation/server-a/2",
        ]);
        expect(snapshotName(first)).toBe("Updated");
      } finally {
        second.close();
        first.close();
      }
    });
  });

  it("creates verified backups and supports restore plus rollback", async () => {
    await withTempDirectory(async (directory) => {
      const sourcePath = path.join(directory, "source.sqlite");
      const destinationPath = path.join(directory, "destination.sqlite");
      const backupPath = path.join(directory, "backups", "source.sqlite");

      const source = new SqliteSyncStorage(sourcePath, { generation: "source-generation" });
      source.commit(createHabit("From backup"));
      source.createAccount(account);
      await expect(source.backup(sourcePath)).rejects.toMatchObject({ code: "invalid_backup_path" });
      const manifest = await source.backup(backupPath);
      source.close();
      expect(manifest).toMatchObject({
        formatVersion: 1,
        databaseSchemaVersion: currentSqliteSchemaVersion,
        streamGeneration: "source-generation",
        headOffset: 1,
      });
      expect(manifest.sha256).toMatch(/^[a-f0-9]{64}$/);
      await expect(SqliteSyncStorage.restoreBackup(backupPath, backupPath)).rejects.toMatchObject({
        code: "invalid_restore_path",
      });

      const destination = new SqliteSyncStorage(destinationPath, { generation: "destination-generation" });
      destination.commit(createHabit("Original destination", "destination", 1));
      destination.close();

      const restored = await SqliteSyncStorage.restoreBackup(backupPath, destinationPath, manifest.sha256);
      expect(restored.rollbackPath).not.toBeNull();
      const restoredStorage = new SqliteSyncStorage(destinationPath);
      expect(snapshotName(restoredStorage)).toBe("From backup");
      expect(restoredStorage.getAccount()).toEqual(account);
      restoredStorage.close();

      await SqliteSyncStorage.rollbackRestore(destinationPath, restored.rollbackPath!);
      const rolledBack = new SqliteSyncStorage(destinationPath);
      expect(snapshotName(rolledBack)).toBe("Original destination");
      rolledBack.close();

      await appendFile(backupPath, "tampered");
      await expect(SqliteSyncStorage.verifyBackup(backupPath, manifest.sha256)).rejects.toMatchObject({
        code: "backup_checksum_mismatch",
      });
    });
  });

  it("rejects non-finite auth JSON instead of silently coercing it", () => {
    const storage = new SqliteSyncStorage(":memory:");
    try {
      expect(() => storage.createAccount({
        ...account,
        verifier: { algorithm: "test", value: Number.NaN },
      })).toThrowError(expect.objectContaining({ code: "invalid_auth_record" }));
    } finally {
      storage.close();
    }
  });
});
