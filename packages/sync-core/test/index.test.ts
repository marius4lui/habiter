import { describe, expect, it } from "vitest";
import {
  SyncCoreError,
  applyOperation,
  applyOperations,
  compactProcessedOperations,
  createOperation,
  decodeCursor,
  decodeReplica,
  emptyReplica,
  encodeCursor,
  encodeReplica,
  evaluateCursor,
  materializeEntity,
  nextRevision,
  operationFingerprint,
  type EntityDocument,
  type OperationKind,
  type SyncOperation
} from "../src/index";

const habit = (name = "Walk", metadata: Record<string, unknown> = {}): EntityDocument => ({
  ...metadata,
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
    future: { compatible: true }
  }
} as EntityDocument);

const operation = (kind: OperationKind, deviceId: string, sequence: number, document = habit(), changedFields?: string[]): SyncOperation => createOperation({
  kind,
  revision: { deviceId, sequence },
  document,
  changedFields: changedFields ?? (kind === "delete" ? [] : Object.keys(document.payload ?? {})),
  changedMetadataFields: Object.keys(document).filter((key) => !["schemaVersion", "entityId", "deleted", "payload"].includes(key))
});

const patch = (deviceId: string, sequence: number, field: "name" | "description", value: string): SyncOperation => {
  const document = habit(field === "name" ? value : "Walk");
  if (field === "description") document.payload!.description = value;
  return operation("patch", deviceId, sequence, document, [field]);
};

const tombstone = (): EntityDocument => ({ schemaVersion: 1, entityId: "habit/habit-a", deleted: true });

const permutations = <T>(items: T[]): T[][] => items.length < 2
  ? [items]
  : items.flatMap((item, index) => permutations(items.filter((_, candidate) => candidate !== index)).map((tail) => [item, ...tail]));

describe("authoritative TypeScript sync core", () => {
  it("creates canonical operations and stable fingerprints", () => {
    const first = operation("create", "phone-a", 1);
    const reordered = { ...first, document: { payload: first.document.payload, deleted: false, entityId: "habit/habit-a", schemaVersion: 1 } } as SyncOperation;
    expect(first.operationId).toBe("operation/phone-a/1");
    expect(operationFingerprint(reordered)).toBe(operationFingerprint(first));
    expect(nextRevision("phone-a", 3, [{ deviceId: "phone-b", sequence: 12 }]).sequence).toBe(13);
  });

  it("merges independent fields in every arrival order", () => {
    const operations = [
      operation("create", "phone-a", 1),
      patch("phone-a", 2, "name", "Morning walk"),
      patch("phone-b", 1, "description", "Outside")
    ];
    const expected = encodeReplica(applyOperations(emptyReplica(), operations));
    for (const order of permutations(operations)) {
      expect(encodeReplica(applyOperations(emptyReplica(), order))).toEqual(expected);
    }
    const document = materializeEntity(applyOperations(emptyReplica(), operations).entities["habit/habit-a"]!);
    expect(document?.payload).toMatchObject({ name: "Morning walk", description: "Outside", future: { compatible: true } });
  });

  it("resolves same-field conflicts without wall clocks", () => {
    const state = applyOperations(emptyReplica(), [
      patch("phone-z", 5, "name", "Z"),
      patch("phone-a", 6, "name", "Sequence"),
      operation("create", "phone-a", 1)
    ]);
    expect(materializeEntity(state.entities["habit/habit-a"]!)?.payload?.name).toBe("Sequence");
  });

  it("deduplicates exact retries and rejects id collisions", () => {
    const create = operation("create", "phone-a", 1);
    const first = applyOperation(emptyReplica(), create);
    expect(applyOperation(first.state, create).outcome).toBe("duplicate");
    const collision = operation("create", "phone-a", 1, habit("Different"));
    expect(() => applyOperation(first.state, collision)).toThrowError(expect.objectContaining({ code: "idempotency_collision" }));
  });

  it("keeps tombstones until an explicit newer restore", () => {
    const deleted = applyOperations(emptyReplica(), [
      operation("delete", "phone-a", 4, tombstone()),
      patch("phone-b", 5, "name", "Cannot revive"),
      operation("create", "phone-a", 1)
    ]);
    expect(materializeEntity(deleted.entities["habit/habit-a"]!)?.deleted).toBe(true);
    const restored = applyOperation(deleted, operation("restore", "phone-a", 6, habit("Recovered"))).state;
    expect(materializeEntity(restored.entities["habit/habit-a"]!)?.payload?.name).toBe("Recovered");
  });

  it("roundtrips durable state and compacts only acknowledged IDs", () => {
    const state = applyOperations(emptyReplica(), [
      operation("create", "phone-a", 1),
      operation("delete", "phone-a", 2, tombstone()),
      patch("phone-b", 3, "name", "pending")
    ]);
    const restored = decodeReplica(encodeReplica(state));
    expect(restored).toEqual(state);
    const compacted = compactProcessedOperations(restored, { "phone-a": 2 });
    expect(Object.keys(compacted.processedOperations)).toEqual(["operation/phone-b/3"]);
    expect(materializeEntity(compacted.entities["habit/habit-a"]!)?.deleted).toBe(true);
  });

  it("uses canonical opaque cursors and typed snapshot recovery", () => {
    const cursor = { generation: "epoch-2", offset: 12 };
    expect(decodeCursor(encodeCursor(cursor))).toEqual(cursor);
    expect(evaluateCursor(null, { generation: "epoch-2", floorOffset: 10, headOffset: 20 })).toBe("missing_compacted_history");
    expect(evaluateCursor({ generation: "epoch-1", offset: 12 }, { generation: "epoch-2", floorOffset: 10, headOffset: 20 })).toBe("generation_changed");
    expect(evaluateCursor({ generation: "epoch-2", offset: 21 }, { generation: "epoch-2", floorOffset: 10, headOffset: 20 })).toBe("cursor_ahead");
  });

  it("fails closed for secrets, malformed JSON, and unsafe protocols", () => {
    expect(() => habit("Walk", { accessToken: "nope" }) && operation("create", "phone-a", 1, habit("Walk", { accessToken: "nope" }))).toThrowError(expect.objectContaining({ code: "sensitive_payload" }));
    const invalid = habit();
    invalid.payload!.futureScore = Number.NaN;
    expect(() => operation("create", "phone-a", 1, invalid)).toThrowError(expect.objectContaining({ code: "non_json_value" }));
    expect(() => createOperation({ ...operation("create", "phone-a", 1), protocolVersion: 2 as 1 })).toThrowError(SyncCoreError);
  });
});
