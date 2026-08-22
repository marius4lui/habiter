import { describe, expect, it } from "vitest";
import {
  createOperation,
  materializeEntity,
  type AuthAccountRecord,
  type AuthOneTimeRecord,
  type AuthRateLimitRecord,
  type AuthSessionRecord,
  type EntityDocument,
  type OperationKind,
  type SyncOperation,
  type SyncStorage,
} from "../src/index";

export interface StorageConformanceHarness {
  name: string;
  create(): SyncStorage | Promise<SyncStorage>;
  cleanup?(storage: SyncStorage): void | Promise<void>;
}

const habit = (name = "Walk"): EntityDocument => ({
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

const operation = (
  kind: OperationKind,
  deviceId: string,
  sequence: number,
  document: EntityDocument = habit(),
  changedFields?: string[],
): SyncOperation => createOperation({
  kind,
  revision: { deviceId, sequence },
  document,
  changedFields: changedFields ?? (kind === "delete" ? [] : Object.keys(document.payload ?? {})),
  changedMetadataFields: [],
});

const patch = (deviceId: string, sequence: number, name: string): SyncOperation =>
  operation("patch", deviceId, sequence, habit(name), ["name"]);

const tombstone = (): EntityDocument => ({
  schemaVersion: 1,
  entityId: "habit/habit-a",
  deleted: true,
});

async function dispose(harness: StorageConformanceHarness, storage: SyncStorage): Promise<void> {
  if (harness.cleanup) await harness.cleanup(storage);
  else await storage.close();
}

export function registerStorageConformanceSuite(harness: StorageConformanceHarness): void {
  describe(`${harness.name} storage conformance`, () => {
    it("deduplicates exact commits and rejects operation-ID collisions", async () => {
      const storage = await harness.create();
      try {
        const create = operation("create", "phone-a", 1);
        const first = await storage.commit(create);
        const duplicate = await storage.commit(create);
        expect(duplicate).toMatchObject({ cursor: first.cursor, offset: first.offset, duplicate: true });
        const collision = operation("create", "phone-a", 1, habit("Different"));
        await expect(Promise.resolve().then(() => storage.commit(collision))).rejects.toMatchObject({
          code: "idempotency_collision",
        });
      } finally {
        await dispose(harness, storage);
      }
    });

    it("paginates a stable ordered operation stream", async () => {
      const storage = await harness.create();
      try {
        await storage.commit(operation("create", "phone-a", 1));
        await storage.commit(patch("phone-a", 2, "Morning walk"));
        await storage.commit(patch("phone-b", 1, "Outside walk"));
        const first = await storage.pull(null, 2);
        const second = await storage.pull(first.cursor, 2);
        expect(first.operations.map((item) => item.operationId)).toEqual([
          "operation/phone-a/1",
          "operation/phone-a/2",
        ]);
        expect(second.operations.map((item) => item.operationId)).toEqual(["operation/phone-b/1"]);
        expect(second.cursor).not.toBe(first.cursor);
        expect(second.headOffset).toBe(3);
      } finally {
        await dispose(harness, storage);
      }
    });

    it("converges out-of-order writes and retains tombstones", async () => {
      const storage = await harness.create();
      try {
        await storage.commit(patch("phone-b", 3, "Newest"));
        await storage.commit(operation("create", "phone-a", 1));
        await storage.commit(operation("delete", "phone-a", 4, tombstone()));
        await storage.commit(patch("phone-b", 5, "Cannot revive"));
        const snapshot = await storage.snapshot();
        expect(snapshot.entities).toHaveLength(1);
        expect(materializeEntity(snapshot.entities[0]!)?.deleted).toBe(true);
      } finally {
        await dispose(harness, storage);
      }
    });

    it("compacts stream history without losing receipts or tombstones", async () => {
      const storage = await harness.create();
      try {
        const create = operation("create", "phone-a", 1);
        await storage.commit(create);
        await storage.commit(operation("delete", "phone-a", 2, tombstone()));
        const compacted = await storage.compact(2);
        expect(compacted).toEqual({ removedOperations: 2, floorOffset: 2 });
        expect((await storage.pull(null, 10)).requiresSnapshot).toBe(true);
        expect((await storage.commit(create)).duplicate).toBe(true);
        const snapshot = await storage.snapshot();
        expect(materializeEntity(snapshot.entities[0]!)?.deleted).toBe(true);
      } finally {
        await dispose(harness, storage);
      }
    });

    it("enforces a single account and compare-and-swap password updates", async () => {
      const storage = await harness.create();
      const account: AuthAccountRecord = {
        username: "owner",
        verifier: { algorithm: "test", value: "verifier-a" },
        passwordVersion: 1,
        createdAt: "2026-08-21T06:00:00.000Z",
        updatedAt: "2026-08-21T06:00:00.000Z",
      };
      try {
        await storage.createAccount(account);
        await expect(Promise.resolve().then(() => storage.createAccount(account))).rejects.toMatchObject({
          code: "account_already_initialized",
        });
        const updated = { ...account, verifier: { algorithm: "test", value: "verifier-b" }, passwordVersion: 2 };
        expect(await storage.updateAccount(updated, 9)).toBe(false);
        expect(await storage.updateAccount(updated, 1)).toBe(true);
        expect((await storage.getAccount())?.passwordVersion).toBe(2);
      } finally {
        await dispose(harness, storage);
      }
    });

    it("consumes one-time records and rotates sessions exactly once", async () => {
      const storage = await harness.create();
      const oneTime: AuthOneTimeRecord = {
        kind: "login_challenge",
        idHash: "a".repeat(64),
        payload: { audience: "owner" },
        expiresAt: "2026-08-21T06:10:00.000Z",
        consumedAt: null,
      };
      const session: AuthSessionRecord = {
        refreshHash: "b".repeat(64),
        familyId: "family-a",
        deviceId: "phone-a",
        payload: { audience: "owner" },
        expiresAt: "2026-09-21T06:00:00.000Z",
        rotatedToHash: null,
        revokedAt: null,
      };
      const replacement = { ...session, refreshHash: "c".repeat(64) };
      try {
        await storage.putOneTime(oneTime);
        expect(await storage.consumeOneTime(oneTime.kind, oneTime.idHash, "2026-08-21T06:01:00.000Z")).not.toBeNull();
        expect(await storage.consumeOneTime(oneTime.kind, oneTime.idHash, "2026-08-21T06:02:00.000Z")).toBeNull();
        await storage.putSession(session);
        expect(await storage.rotateSession(session.refreshHash, replacement, "2026-08-21T06:03:00.000Z")).toBe(true);
        expect(await storage.rotateSession(session.refreshHash, replacement, "2026-08-21T06:04:00.000Z")).toBe(false);
        expect(await storage.revokeDevice("phone-a", "2026-08-21T06:05:00.000Z")).toBe(2);
        expect((await storage.getSession(session.refreshHash))?.revokedAt).not.toBeNull();
        expect((await storage.getSession(replacement.refreshHash))?.revokedAt).not.toBeNull();
      } finally {
        await dispose(harness, storage);
      }
    });

    it("roundtrips rate-limit state", async () => {
      const storage = await harness.create();
      const rate: AuthRateLimitRecord = {
        scopeKey: "login:owner",
        failures: 4,
        blockedUntil: "2026-08-21T06:10:00.000Z",
        updatedAt: "2026-08-21T06:00:00.000Z",
      };
      try {
        expect(await storage.getRateLimit(rate.scopeKey)).toBeNull();
        await storage.putRateLimit(rate);
        expect(await storage.getRateLimit(rate.scopeKey)).toEqual(rate);
      } finally {
        await dispose(harness, storage);
      }
    });
  });
}
