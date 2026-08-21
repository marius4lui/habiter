export type Json = null | boolean | number | string | Json[] | { [key: string]: Json };

export type EntityType = "habit" | "entry" | "setting";
export type OperationKind = "create" | "patch" | "delete" | "restore";

export interface Revision {
  deviceId: string;
  sequence: number;
}

export interface EntityDocument {
  schemaVersion: 1;
  entityId: string;
  deleted: boolean;
  payload?: Record<string, Json>;
}

export interface SyncOperation {
  protocolVersion: 1;
  operationId: string;
  kind: OperationKind;
  revision: Revision;
  document: EntityDocument;
  changedFields: string[];
  changedMetadataFields: string[];
}

export interface FieldRegister {
  value: Json;
  revision: Revision;
}

export interface EntityState {
  entityId: string;
  lifecycleRevision: Revision | null;
  deleted: boolean;
  payloadFields: Record<string, FieldRegister>;
  metadataFields: Record<string, FieldRegister>;
}

export interface ReplicaState {
  schemaVersion: 1;
  entities: Record<string, EntityState>;
  processedOperations: Record<string, string>;
  cursor?: string;
}

export class SyncCoreError extends Error {
  constructor(readonly code: string, message: string) {
    super(message);
    this.name = "SyncCoreError";
  }
}

const devicePattern = /^[A-Za-z0-9._~-]{1,128}$/;
const sensitivePattern = /(token|secret|password|api.?key|credential)/i;
const localDatePattern = /^\d{4}-\d{2}-\d{2}$/;
const operationKinds = new Set<OperationKind>(["create", "patch", "delete", "restore"]);
const knownDocumentFields = new Set(["schemaVersion", "entityId", "deleted", "payload"]);
const booleanValue = (value: unknown): boolean => typeof value === "boolean";
const timeValue = (value: unknown): boolean => typeof value === "string" && /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value);
const positiveMinutes = (value: unknown): boolean => Number.isSafeInteger(value) && (value as number) >= 1 && (value as number) <= 1440;
const settingValidators: Record<string, (value: unknown) => boolean> = {
  "appearance.theme": (value) => ["light", "dark", "system"].includes(value as string),
  "appearance.language": (value) => ["en", "de"].includes(value as string),
  "coaching.showRecoverySupport": booleanValue,
  "reminders.enabled": booleanValue,
  "reminders.activeDayStart": timeValue,
  "reminders.activeDayEnd": timeValue,
  "reminders.globalDailyLimit": (value) => Number.isSafeInteger(value) && (value as number) >= 1 && (value as number) <= 64,
  "reminders.globalMinimumSpacingMinutes": positiveMinutes,
  "reminders.quietHours": validateQuietHours,
  "reminders.calibrationEnabled": booleanValue,
  "reminders.ongoingLearningEnabled": booleanValue,
  "reminders.showLearningExplanations": booleanValue,
  "reminders.defaultSnoozeMinutes": positiveMinutes,
  "reminders.dailyOverview.enabled": booleanValue,
  "reminders.dailyOverview.time": timeValue
};

export function compareRevisions(left: Revision, right: Revision): number {
  assertRevision(left);
  assertRevision(right);
  return left.sequence === right.sequence
    ? left.deviceId === right.deviceId ? 0 : left.deviceId < right.deviceId ? -1 : 1
    : left.sequence - right.sequence;
}

export function nextRevision(deviceId: string, localSequence: number, observed: Revision[] = []): Revision {
  if (!Number.isSafeInteger(localSequence) || localSequence < 0) fail("invalid_revision", "Local sequence is invalid");
  return revision(deviceId, Math.max(localSequence, ...observed.map((item) => item.sequence), 0) + 1);
}

export function revision(deviceId: string, sequence: number): Revision {
  const value = { deviceId, sequence };
  assertRevision(value);
  return value;
}

export function operationId(value: Revision): string {
  assertRevision(value);
  return `operation/${encodeURIComponent(value.deviceId)}/${value.sequence}`;
}

export function parseOperationId(value: string): Revision {
  const parts = value.split("/");
  if (parts.length !== 3 || parts[0] !== "operation") fail("invalid_operation_id", "Operation ID shape is invalid");
  let deviceId: string;
  try {
    deviceId = decodeURIComponent(parts[1]!);
  } catch {
    fail("invalid_operation_id", "Operation ID encoding is invalid");
  }
  const sequence = Number(parts[2]);
  const parsed = revision(deviceId!, sequence);
  if (operationId(parsed) !== value) fail("invalid_operation_id", "Operation ID is not canonical");
  return parsed;
}

export function validateDocument(value: unknown): EntityDocument {
  if (!isObject(value) || value.schemaVersion !== 1 || typeof value.entityId !== "string" || typeof value.deleted !== "boolean") {
    fail("invalid_document", "Entity document fields are invalid");
  }
  const id = parseEntityId(value.entityId);
  const payload = value.payload;
  if (value.deleted === (payload !== undefined)) fail("invalid_tombstone", "Live documents need payload and tombstones omit it");
  assertJson(value);
  rejectSensitive(value);
  if (payload !== undefined) {
    if (!isObject(payload)) fail("invalid_payload", "Entity payload must be an object");
    if (id.type === "habit") validateHabit(payload, id.components[0]!);
    if (id.type === "entry") validateEntry(payload, id.components[0]!, id.components[1]!);
    if (id.type === "setting") validateSetting(payload, id.components[0]!);
  }
  return structuredClone(value) as unknown as EntityDocument;
}

export function createOperation(value: Omit<SyncOperation, "protocolVersion" | "operationId"> & Partial<Pick<SyncOperation, "protocolVersion" | "operationId">>): SyncOperation {
  const protocolVersion = value.protocolVersion ?? 1;
  if (protocolVersion !== 1 || !operationKinds.has(value.kind)) fail("unsupported_protocol", "Operation protocol is unsupported");
  assertRevision(value.revision);
  const id = operationId(value.revision);
  if (value.operationId !== undefined && value.operationId !== id) fail("operation_id_mismatch", "Operation ID does not match revision");
  const document = validateDocument(value.document);
  const changedFields = validateFieldSet(value.changedFields, document.payload ?? {});
  const metadata = Object.fromEntries(Object.entries(document).filter(([key]) => !knownDocumentFields.has(key)));
  const changedMetadataFields = validateFieldSet(value.changedMetadataFields, metadata);
  if (value.kind === "delete" && (!document.deleted || changedFields.length > 0)) fail("invalid_delete_operation", "Delete requires a tombstone");
  if (value.kind !== "delete" && document.deleted) fail("invalid_live_operation", "Live operation contains a tombstone");
  if (value.kind === "patch" && changedFields.length + changedMetadataFields.length === 0) fail("empty_patch", "Patch changes no fields");
  if (["create", "restore"].includes(value.kind)) {
    requireComplete(changedFields, Object.keys(document.payload ?? {}));
    requireComplete(changedMetadataFields, Object.keys(metadata));
  }
  if (value.kind === "delete") requireComplete(changedMetadataFields, Object.keys(metadata));
  const additional = Object.fromEntries(Object.entries(value).filter(([key]) => !new Set(["protocolVersion", "operationId", "kind", "revision", "document", "changedFields", "changedMetadataFields"]).has(key)));
  assertJson(additional);
  rejectSensitive(additional);
  const safeAdditional = additional as Record<string, Json>;
  return structuredClone({ ...safeAdditional, protocolVersion: 1, operationId: id, kind: value.kind, revision: value.revision, document, changedFields: changedFields.sort(), changedMetadataFields: changedMetadataFields.sort() }) as SyncOperation;
}

export function operationFingerprint(value: SyncOperation): string {
  return JSON.stringify(canonical(createOperation(value)));
}

export function emptyReplica(): ReplicaState {
  return { schemaVersion: 1, entities: {}, processedOperations: {} };
}

export function applyOperation(source: ReplicaState, input: SyncOperation): { state: ReplicaState; outcome: "applied" | "superseded" | "duplicate" } {
  const operation = createOperation(input);
  const fingerprint = operationFingerprint(operation);
  const prior = source.processedOperations[operation.operationId];
  if (prior !== undefined) {
    if (prior !== fingerprint) fail("idempotency_collision", "Operation ID was reused with different content");
    return { state: source, outcome: "duplicate" };
  }
  const state = decodeReplica(encodeReplica(source));
  const id = operation.document.entityId;
  const entity = state.entities[id] ?? { entityId: id, lifecycleRevision: null, deleted: false, payloadFields: {}, metadataFields: {} };
  let changed = mergeFields(entity.payloadFields, operation.changedFields, operation.document.payload ?? {}, operation.revision);
  const metadata = Object.fromEntries(Object.entries(operation.document).filter(([key]) => !knownDocumentFields.has(key))) as Record<string, Json>;
  changed = mergeFields(entity.metadataFields, operation.changedMetadataFields, metadata, operation.revision) || changed;
  const lifecycle = entity.lifecycleRevision;
  if (operation.kind === "create" && (lifecycle === null || (!entity.deleted && compareRevisions(operation.revision, lifecycle) > 0))) {
    entity.lifecycleRevision = operation.revision; entity.deleted = false; changed = true;
  } else if (operation.kind === "delete" && (lifecycle === null || compareRevisions(operation.revision, lifecycle) > 0)) {
    entity.lifecycleRevision = operation.revision; entity.deleted = true; changed = true;
  } else if (operation.kind === "restore" && (lifecycle === null || compareRevisions(operation.revision, lifecycle) > 0)) {
    entity.lifecycleRevision = operation.revision; entity.deleted = false; changed = true;
  }
  state.entities[id] = entity;
  state.processedOperations[operation.operationId] = fingerprint;
  materializeEntity(entity);
  return { state, outcome: changed ? "applied" : "superseded" };
}

export function applyOperations(source: ReplicaState, operations: SyncOperation[]): ReplicaState {
  return operations.reduce((state, operation) => applyOperation(state, operation).state, source);
}

export function materializeEntity(entity: EntityState): EntityDocument | null {
  if (entity.lifecycleRevision === null) return null;
  const metadata = visibleValues(entity.metadataFields, entity.lifecycleRevision);
  return validateDocument(entity.deleted
    ? { ...metadata, schemaVersion: 1, entityId: entity.entityId, deleted: true }
    : { ...metadata, schemaVersion: 1, entityId: entity.entityId, deleted: false, payload: visibleValues(entity.payloadFields, entity.lifecycleRevision) });
}

export function compactProcessedOperations(source: ReplicaState, watermark: Record<string, number>): ReplicaState {
  const state = decodeReplica(encodeReplica(source));
  for (const id of Object.keys(state.processedOperations)) {
    const value = parseOperationId(id);
    if (value.sequence <= (watermark[value.deviceId] ?? 0)) delete state.processedOperations[id];
  }
  return state;
}

export function encodeReplica(state: ReplicaState): Json {
  validateReplica(state);
  return structuredClone(canonical(state)) as Json;
}

export function decodeReplica(value: unknown): ReplicaState {
  if (!isObject(value)) fail("invalid_replica_state", "Replica is not an object");
  const state = structuredClone(value) as unknown as ReplicaState;
  validateReplica(state);
  return state;
}

export interface ServerCursor { generation: string; offset: number }
export type CursorRecovery = "none" | "missing_compacted_history" | "generation_changed" | "cursor_ahead";

export function encodeCursor(cursor: ServerCursor): string {
  validateCursor(cursor);
  const bytes = new TextEncoder().encode(JSON.stringify({ version: 1, generation: cursor.generation, offset: cursor.offset }));
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

export function decodeCursor(token: string): ServerCursor {
  try {
    const base64 = token.replaceAll("-", "+").replaceAll("_", "/").padEnd(Math.ceil(token.length / 4) * 4, "=");
    const raw = Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
    const value = JSON.parse(new TextDecoder().decode(raw)) as unknown;
    if (!isObject(value) || value.version !== 1 || typeof value.generation !== "string" || typeof value.offset !== "number" || Object.keys(value).length !== 3) throw new Error();
    const cursor = { generation: value.generation, offset: value.offset };
    validateCursor(cursor);
    if (encodeCursor(cursor) !== token) throw new Error();
    return cursor;
  } catch {
    fail("invalid_cursor", "Cursor is malformed or non-canonical");
  }
}

export function evaluateCursor(cursor: ServerCursor | null, window: { generation: string; floorOffset: number; headOffset: number }): CursorRecovery {
  validateCursor({ generation: window.generation, offset: window.headOffset });
  if (!Number.isSafeInteger(window.floorOffset) || window.floorOffset < 0 || window.floorOffset > window.headOffset) fail("invalid_cursor_window", "Cursor window is invalid");
  if (cursor === null) return window.floorOffset === 0 ? "none" : "missing_compacted_history";
  validateCursor(cursor);
  if (cursor.generation !== window.generation) return "generation_changed";
  if (cursor.offset < window.floorOffset) return "missing_compacted_history";
  if (cursor.offset > window.headOffset) return "cursor_ahead";
  return "none";
}

function validateReplica(state: ReplicaState): void {
  if (state.schemaVersion !== 1 || !isObject(state.entities) || !isObject(state.processedOperations)) fail("invalid_replica_state", "Replica schema is invalid");
  assertJson(state);
  rejectSensitive(state.entities);
  for (const [id, entity] of Object.entries(state.entities)) {
    if (id !== entity.entityId || !isObject(entity.payloadFields) || !isObject(entity.metadataFields) || typeof entity.deleted !== "boolean") fail("invalid_replica_state", "Entity state is invalid");
    if (entity.lifecycleRevision !== null) assertRevision(entity.lifecycleRevision);
    if (entity.lifecycleRevision === null && entity.deleted) fail("invalid_replica_state", "Pending entity cannot be deleted");
    for (const registers of [entity.payloadFields, entity.metadataFields]) for (const [field, register] of Object.entries(registers)) {
      if (!field || sensitivePattern.test(field) || !isObject(register) || !("value" in register)) fail("invalid_replica_state", "Field register is unsafe");
      assertRevision(register.revision);
    }
    materializeEntity(entity);
  }
  for (const [id, fingerprint] of Object.entries(state.processedOperations)) {
    parseOperationId(id);
    if (typeof fingerprint !== "string" || !fingerprint) fail("invalid_replica_state", "Processed operation is invalid");
  }
  if (state.cursor !== undefined) decodeCursor(state.cursor);
}

function mergeFields(target: Record<string, FieldRegister>, fields: string[], values: Record<string, Json>, revisionValue: Revision): boolean {
  let changed = false;
  for (const field of fields) {
    const current = target[field];
    if (current === undefined || compareRevisions(revisionValue, current.revision) > 0) {
      target[field] = { value: structuredClone(values[field]!), revision: structuredClone(revisionValue) };
      changed = true;
    }
  }
  return changed;
}

function visibleValues(fields: Record<string, FieldRegister>, lifecycle: Revision): Record<string, Json> {
  return Object.fromEntries(Object.entries(fields).filter(([, register]) => compareRevisions(register.revision, lifecycle) >= 0).sort(([a], [b]) => a.localeCompare(b)).map(([key, register]) => [key, structuredClone(register.value)]));
}

function validateFieldSet(fields: unknown, values: object): string[] {
  if (!Array.isArray(fields) || fields.some((field) => typeof field !== "string" || !field.trim())) fail("invalid_changed_fields", "Changed fields are invalid");
  const unique = [...new Set(fields as string[])];
  if (unique.some((field) => !Object.hasOwn(values, field))) fail("invalid_changed_fields", "Changed field is absent from document");
  return unique;
}

function requireComplete(actual: string[], expected: string[]): void {
  if (actual.length !== expected.length || expected.some((field) => !actual.includes(field))) fail("incomplete_replacement", "Replacement fields are incomplete");
}

function parseEntityId(value: string): { type: EntityType; components: string[] } {
  const parts = value.split("/");
  const type = parts[0] as EntityType;
  if (!(["habit", "entry", "setting"] as string[]).includes(type) || parts.length !== (type === "entry" ? 3 : 2)) fail("invalid_entity_id", "Entity ID shape is invalid");
  let components: string[];
  try { components = parts.slice(1).map(decodeURIComponent); } catch { fail("invalid_entity_id", "Entity ID encoding is invalid"); }
  if (components!.some((part) => !part.trim()) || components!.map(encodeURIComponent).join("/") !== parts.slice(1).join("/")) fail("invalid_entity_id", "Entity ID is not canonical");
  if (type === "entry" && !validLocalDate(components![1]!)) fail("invalid_entity_id", "Entry date is invalid");
  return { type, components: components! };
}

function validateHabit(value: Record<string, unknown>, id: string): void {
  const strings = ["id", "name", "color", "icon", "frequency", "category"];
  const customDays = value.customDays;
  if (strings.some((key) => typeof value[key] !== "string" || !(value[key] as string).trim()) || value.id !== id || !["daily", "weekly", "custom"].includes(value.frequency as string) || (value.description !== null && typeof value.description !== "string") || typeof value.targetCount !== "number" || !Number.isSafeInteger(value.targetCount) || value.targetCount <= 0 || (customDays !== null && (!Array.isArray(customDays) || customDays.some((day) => !Number.isSafeInteger(day) || day < 1 || day > 7))) || typeof value.isActive !== "boolean" || typeof value.notificationEnabled !== "boolean" || (value.notificationTime !== null && !timeValue(value.notificationTime)) || typeof value.createdAt !== "string" || Number.isNaN(Date.parse(value.createdAt))) fail("invalid_payload", "Habit payload is invalid");
}

function validateEntry(value: Record<string, unknown>, habitId: string, date: string): void {
  if (typeof value.id !== "string" || !value.id || value.habitId !== habitId || value.date !== date || typeof value.completed !== "boolean" || !Number.isSafeInteger(value.count) || (value.count as number) < 0 || typeof value.timestamp !== "string" || Number.isNaN(Date.parse(value.timestamp))) fail("invalid_payload", "Entry payload is invalid");
}

function validateSetting(value: Record<string, unknown>, key: string): void {
  const validator = settingValidators[key];
  if (validator === undefined || Object.keys(value).length !== 1 || !("value" in value) || !validator(value.value)) fail("invalid_setting", "Setting payload is invalid");
}

function validateQuietHours(value: unknown): boolean {
  if (!Array.isArray(value)) return false;
  const occupied = new Set<number>();
  for (const item of value) {
    if (!isObject(item) || Object.keys(item).sort().join(",") !== "end,start" || !timeValue(item.start) || !timeValue(item.end) || item.start === item.end) return false;
    const minutes = (text: string): number => Number(text.slice(0, 2)) * 60 + Number(text.slice(3));
    const end = minutes(item.end as string);
    let current = minutes(item.start as string);
    while (current !== end) {
      if (occupied.has(current)) return false;
      occupied.add(current);
      current = (current + 1) % 1440;
    }
    if (occupied.has(end)) return false;
    occupied.add(end);
  }
  return true;
}

function assertRevision(value: Revision): void {
  if (!isObject(value) || typeof value.deviceId !== "string" || !devicePattern.test(value.deviceId) || !Number.isSafeInteger(value.sequence) || value.sequence < 1) fail("invalid_revision", "Revision is invalid");
}

function validateCursor(value: ServerCursor): void {
  if (!devicePattern.test(value.generation) || !Number.isSafeInteger(value.offset) || value.offset < 0) fail("invalid_cursor", "Cursor fields are invalid");
}

function validLocalDate(value: string): boolean {
  if (!localDatePattern.test(value)) return false;
  return new Date(`${value}T00:00:00Z`).toISOString().startsWith(value);
}

function assertJson(value: unknown): asserts value is Json {
  if (value === null || typeof value === "string" || typeof value === "boolean") return;
  if (typeof value === "number") { if (Number.isFinite(value)) return; fail("non_json_value", "Number is not finite"); }
  if (Array.isArray(value)) { value.forEach(assertJson); return; }
  if (isObject(value)) { Object.values(value).forEach(assertJson); return; }
  fail("non_json_value", "Value is not JSON-compatible");
}

function rejectSensitive(value: unknown): void {
  if (Array.isArray(value)) value.forEach(rejectSensitive);
  else if (isObject(value)) for (const [key, child] of Object.entries(value)) {
    if (sensitivePattern.test(key)) fail("sensitive_payload", "Sensitive-looking key is forbidden");
    rejectSensitive(child);
  }
}

function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical);
  if (isObject(value)) return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonical(value[key])]));
  return value;
}

function isObject(value: unknown): value is Record<string, any> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function fail(code: string, message: string): never {
  throw new SyncCoreError(code, message);
}
