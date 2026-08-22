import {
  SyncCoreError,
  applyOperation,
  createOperation,
  decodeCursor,
  decodeReplica,
  emptyReplica,
  encodeCursor,
  evaluateCursor,
  operationFingerprint,
  type AuthAccountRecord,
  type AuthOneTimeRecord,
  type AuthRateLimitRecord,
  type AuthSessionRecord,
  type EntityState,
  type Json,
  type StorageCommitResult,
  type StoragePullPage,
  type StorageSnapshot,
  type SyncOperation,
  type SyncStorage,
} from "@habiter/sync-core";
import { currentD1SchemaVersion, d1Migrations, type D1Migration } from "./migrations";

export { currentD1SchemaVersion, d1Migrations, type D1Migration };

export type D1Value = null | string | number | boolean | ArrayBuffer | Uint8Array;

export interface D1ResultMeta {
  rows_read?: number;
  rows_written?: number;
  last_row_id?: number;
  changes?: number;
  duration?: number;
  [key: string]: unknown;
}

export interface D1ResultLike<T = Record<string, unknown>> {
  success: boolean;
  results: T[];
  meta: D1ResultMeta;
  error?: string;
}

export interface D1PreparedStatementLike {
  bind(...values: D1Value[]): D1PreparedStatementLike;
  all<T = Record<string, unknown>>(): Promise<D1ResultLike<T>>;
  run<T = Record<string, unknown>>(): Promise<D1ResultLike<T>>;
}

export interface D1DatabaseLike {
  prepare(sql: string): D1PreparedStatementLike;
  batch<T = Record<string, unknown>>(statements: D1PreparedStatementLike[]): Promise<D1ResultLike<T>[]>;
}

export interface D1QueryUsage {
  statements: number;
  rowsRead: number;
  rowsWritten: number;
}

export interface D1SyncStorageOptions {
  migrate?: boolean;
  generation?: string;
  maxEntities?: number;
  onUsage?: (usage: D1QueryUsage) => void;
  migrations?: readonly D1Migration[];
}

export interface D1ExportFixture {
  formatVersion: 1;
  databaseSchemaVersion: number;
  sha256: string;
  payload: Record<string, Record<string, Json>[]>;
}

export class D1StorageError extends Error {
  constructor(readonly code: string, message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "D1StorageError";
  }
}

type Row = Record<string, string | number | null>;
const fixtureColumns: Record<string, string[]> = {
  sync_schema_migrations: ["version", "name", "applied_at"],
  sync_metadata: ["key", "value"],
  sync_entities: ["entity_id", "state_json", "deleted", "lifecycle_sequence", "lifecycle_device_id", "updated_cursor", "state_version"],
  sync_operations: ["server_cursor", "operation_id", "fingerprint", "device_id", "device_sequence", "entity_id", "operation_json", "committed_at"],
  sync_operation_receipts: ["operation_id", "fingerprint", "device_id", "device_sequence", "server_cursor", "committed_at"],
  sync_device_watermarks: ["device_id", "sequence"],
  auth_account: ["singleton", "username", "verifier_json", "password_version", "created_at", "updated_at"],
  auth_one_time: ["kind", "id_hash", "payload_json", "expires_at", "consumed_at"],
  auth_sessions: ["refresh_hash", "family_id", "device_id", "payload_json", "expires_at", "rotated_to_hash", "rotated_at", "revoked_at"],
  auth_rate_limits: ["scope_key", "failures", "blocked_until", "updated_at"],
};
const fixtureTables = Object.keys(fixtureColumns).sort();

export class D1SyncStorage implements SyncStorage {
  readonly #db: D1DatabaseLike;
  readonly #maxEntities: number;
  readonly #onUsage?: (usage: D1QueryUsage) => void;
  #schemaVersion = 0;
  #closed = false;

  private constructor(db: D1DatabaseLike, options: D1SyncStorageOptions) {
    this.#db = db;
    this.#maxEntities = positiveInteger(options.maxEntities ?? 10_000, "max_entities", 100_000);
    this.#onUsage = options.onUsage;
  }

  static async open(binding: unknown, options: D1SyncStorageOptions = {}): Promise<D1SyncStorage> {
    const db = requireBinding(binding);
    const storage = new D1SyncStorage(db, options);
    const migrations = options.migrations ?? d1Migrations;
    validateMigrations(migrations);
    let version = await storage.#userVersion();
    const target = migrations.at(-1)?.version ?? 0;
    if (version === 0 && options.migrate !== true) {
      throw new D1StorageError("schema_uninitialized", "D1 schema is not initialized");
    }
    if (version > target) {
      throw new D1StorageError("database_newer_than_service", `D1 schema ${version} is newer than supported schema ${target}`);
    }
    if (options.migrate === true && version < target) {
      await storage.#migrate(migrations, version);
      version = await storage.#userVersion();
    }
    if (version !== target) {
      throw new D1StorageError("schema_incompatible", `D1 schema ${version} does not match required schema ${target}`);
    }
    storage.#schemaVersion = version;
    await storage.#initializeMetadata(options.generation);
    return storage;
  }

  get schemaVersion(): number {
    this.#assertOpen();
    return this.#schemaVersion;
  }

  async commit(input: SyncOperation, committedAt = new Date().toISOString()): Promise<StorageCommitResult> {
    this.#assertOpen();
    assertIsoDate(committedAt, "committed_at");
    const operation = createOperation(input);
    const fingerprint = operationFingerprint(operation);
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const receipt = await this.#one("SELECT fingerprint, server_cursor FROM sync_operation_receipts WHERE operation_id = ? LIMIT 1", operation.operationId);
      if (receipt !== null) return this.#duplicate(receipt, fingerprint);

      const entityRow = await this.#one("SELECT state_json, state_version FROM sync_entities WHERE entity_id = ? LIMIT 1", operation.document.entityId);
      const replica = emptyReplica();
      if (entityRow !== null) {
        const entity = parseJson<EntityState>(entityRow.state_json, "entity_state");
        replica.entities[entity.entityId] = entity;
      }
      const applied = applyOperation(replica, operation);
      const entity = applied.state.entities[operation.document.entityId]!;
      const nextVersion = entityRow === null ? 1 : Number(entityRow.state_version) + 1;
      const statements = [
        this.#statement("INSERT INTO sync_operations (operation_id, fingerprint, device_id, device_sequence, entity_id, operation_json, committed_at) VALUES (?, ?, ?, ?, ?, ?, ?)", operation.operationId, fingerprint, operation.revision.deviceId, operation.revision.sequence, operation.document.entityId, JSON.stringify(operation), committedAt),
        this.#statement("INSERT INTO sync_operation_receipts (operation_id, fingerprint, device_id, device_sequence, server_cursor, committed_at) SELECT operation_id, fingerprint, device_id, device_sequence, server_cursor, committed_at FROM sync_operations WHERE operation_id = ?", operation.operationId),
        this.#statement(`INSERT INTO sync_entities (entity_id, state_json, deleted, lifecycle_sequence, lifecycle_device_id, updated_cursor, state_version)
          SELECT ?, ?, ?, ?, ?, server_cursor, ? FROM sync_operations WHERE operation_id = ?
          ON CONFLICT(entity_id) DO UPDATE SET state_json = excluded.state_json, deleted = excluded.deleted,
          lifecycle_sequence = excluded.lifecycle_sequence, lifecycle_device_id = excluded.lifecycle_device_id,
          updated_cursor = excluded.updated_cursor, state_version = excluded.state_version`, entity.entityId, JSON.stringify(entity), entity.deleted ? 1 : 0, entity.lifecycleRevision?.sequence ?? null, entity.lifecycleRevision?.deviceId ?? null, nextVersion, operation.operationId),
        this.#statement("UPDATE sync_metadata SET value = (SELECT CAST(server_cursor AS TEXT) FROM sync_operations WHERE operation_id = ?) WHERE key = 'head_offset'", operation.operationId),
      ];
      try {
        const results = await this.#batch(statements);
        const offset = Number(results[0]?.meta.last_row_id ?? (await this.#requiredReceipt(operation.operationId)).server_cursor);
        return {
          cursor: encodeCursor({ generation: await this.#generation(), offset }),
          offset,
          duplicate: false,
          changed: applied.outcome === "applied",
        };
      } catch (error) {
        const racedReceipt = await this.#one("SELECT fingerprint, server_cursor FROM sync_operation_receipts WHERE operation_id = ? LIMIT 1", operation.operationId);
        if (racedReceipt !== null) return this.#duplicate(racedReceipt, fingerprint);
        if (String(error).includes("stale_entity_version")) continue;
        throw new D1StorageError("commit_failed", "D1 transactional commit failed", { cause: error });
      }
    }
    throw new D1StorageError("commit_contention", "D1 entity remained contended after bounded retries");
  }

  async pull(cursor: string | null, limit: number): Promise<StoragePullPage> {
    this.#assertOpen();
    positiveInteger(limit, "pull_limit", 500);
    const generation = await this.#generation();
    const headOffset = await this.#metadataNumber("head_offset");
    const compactionFloor = await this.#metadataNumber("compaction_floor");
    const decoded = cursor === null ? null : decodeCursor(cursor);
    const recoveryReason = evaluateCursor(decoded, { generation, floorOffset: compactionFloor, headOffset });
    if (recoveryReason !== "none") return {
      operations: [], cursor: encodeCursor({ generation, offset: headOffset }), headOffset,
      compactionFloor, requiresSnapshot: true, recoveryReason,
    };
    const after = decoded?.offset ?? 0;
    const rows = await this.#rows("SELECT server_cursor, operation_json FROM sync_operations WHERE server_cursor > ? ORDER BY server_cursor ASC LIMIT ?", after, limit);
    const operations = rows.map((row) => createOperation(parseJson<SyncOperation>(row.operation_json, "operation")));
    const nextOffset = rows.length === 0 ? after : Number(rows.at(-1)!.server_cursor);
    return { operations, cursor: encodeCursor({ generation, offset: nextOffset }), headOffset, compactionFloor, requiresSnapshot: false, recoveryReason: "none" };
  }

  async snapshot(): Promise<StorageSnapshot> {
    this.#assertOpen();
    const rows = await this.#rows("SELECT state_json FROM sync_entities ORDER BY entity_id ASC LIMIT ?", this.#maxEntities + 1);
    if (rows.length > this.#maxEntities) throw new D1StorageError("snapshot_too_large", "D1 snapshot exceeds configured entity bound");
    const entities = rows.map((row) => parseJson<EntityState>(row.state_json, "entity_state"));
    decodeReplica({ schemaVersion: 1, entities: Object.fromEntries(entities.map((entity) => [entity.entityId, entity])), processedOperations: {} });
    return { schemaVersion: 1, cursor: encodeCursor({ generation: await this.#generation(), offset: await this.#metadataNumber("head_offset") }), entities };
  }

  async compact(throughOffset: number): Promise<{ removedOperations: number; floorOffset: number }> {
    this.#assertOpen();
    if (!Number.isSafeInteger(throughOffset) || throughOffset < 0) throw new D1StorageError("invalid_compaction_cursor", "Compaction cursor is invalid");
    const head = await this.#metadataNumber("head_offset");
    if (throughOffset > head) throw new D1StorageError("invalid_compaction_cursor", "Compaction cannot pass stream head");
    const floor = Math.max(await this.#metadataNumber("compaction_floor"), throughOffset);
    const results = await this.#batch([
      this.#statement(`INSERT INTO sync_device_watermarks(device_id, sequence)
        SELECT device_id, MAX(device_sequence) FROM sync_operations WHERE server_cursor <= ? GROUP BY device_id
        ON CONFLICT(device_id) DO UPDATE SET sequence = MAX(sequence, excluded.sequence)`, floor),
      this.#statement("DELETE FROM sync_operations WHERE server_cursor <= ?", floor),
      this.#statement("UPDATE sync_metadata SET value = ? WHERE key = 'compaction_floor'", String(floor)),
    ]);
    return { removedOperations: Number(results[1]?.meta.changes ?? results[1]?.meta.rows_written ?? 0), floorOffset: floor };
  }

  async getAccount(): Promise<AuthAccountRecord | null> {
    const row = await this.#one("SELECT username, verifier_json, password_version, created_at, updated_at FROM auth_account WHERE singleton = 1 LIMIT 1");
    return row === null ? null : { username: String(row.username), verifier: parseJson<Json>(row.verifier_json, "account_verifier"), passwordVersion: Number(row.password_version), createdAt: String(row.created_at), updatedAt: String(row.updated_at) };
  }

  async createAccount(account: AuthAccountRecord): Promise<void> {
    validateAccount(account);
    try {
      await this.#run("INSERT INTO auth_account (singleton, username, verifier_json, password_version, created_at, updated_at) VALUES (1, ?, ?, ?, ?, ?)", account.username, JSON.stringify(account.verifier), account.passwordVersion, account.createdAt, account.updatedAt);
    } catch (error) {
      throw new D1StorageError("account_already_initialized", "A D1 sync instance can contain only one account", { cause: error });
    }
  }

  async updateAccount(account: AuthAccountRecord, expectedPasswordVersion: number): Promise<boolean> {
    validateAccount(account);
    const result = await this.#run("UPDATE auth_account SET username = ?, verifier_json = ?, password_version = ?, updated_at = ? WHERE singleton = 1 AND password_version = ?", account.username, JSON.stringify(account.verifier), account.passwordVersion, account.updatedAt, expectedPasswordVersion);
    return changes(result) === 1;
  }

  async putOneTime(record: AuthOneTimeRecord): Promise<void> {
    validateOneTime(record);
    await this.#run("INSERT INTO auth_one_time(kind, id_hash, payload_json, expires_at, consumed_at) VALUES (?, ?, ?, ?, ?)", record.kind, record.idHash, JSON.stringify(record.payload), record.expiresAt, record.consumedAt);
  }

  async consumeOneTime(kind: AuthOneTimeRecord["kind"], idHash: string, consumedAt: string): Promise<AuthOneTimeRecord | null> {
    assertHash(idHash, "one_time_id"); assertIsoDate(consumedAt, "consumed_at");
    const rows = await this.#rows("UPDATE auth_one_time SET consumed_at = ? WHERE kind = ? AND id_hash = ? AND consumed_at IS NULL RETURNING payload_json, expires_at", consumedAt, kind, idHash);
    const row = rows[0];
    return row === undefined ? null : { kind, idHash, payload: parseJson<Json>(row.payload_json, "one_time_payload"), expiresAt: String(row.expires_at), consumedAt };
  }

  async putSession(session: AuthSessionRecord): Promise<void> {
    validateSession(session);
    await this.#run("INSERT INTO auth_sessions (refresh_hash, family_id, device_id, payload_json, expires_at, rotated_to_hash, revoked_at) VALUES (?, ?, ?, ?, ?, ?, ?)", session.refreshHash, session.familyId, session.deviceId, JSON.stringify(session.payload), session.expiresAt, session.rotatedToHash, session.revokedAt);
  }

  async getSession(refreshHash: string): Promise<AuthSessionRecord | null> {
    assertHash(refreshHash, "refresh_hash");
    const row = await this.#one("SELECT refresh_hash, family_id, device_id, payload_json, expires_at, rotated_to_hash, revoked_at FROM auth_sessions WHERE refresh_hash = ? LIMIT 1", refreshHash);
    return row === null ? null : sessionFromRow(row);
  }

  async rotateSession(refreshHash: string, replacement: AuthSessionRecord, rotatedAt: string): Promise<boolean> {
    assertHash(refreshHash, "refresh_hash"); validateSession(replacement); assertIsoDate(rotatedAt, "rotated_at");
    const results = await this.#batch([
      this.#statement("UPDATE auth_sessions SET rotated_to_hash = ?, rotated_at = ? WHERE refresh_hash = ? AND rotated_to_hash IS NULL AND revoked_at IS NULL", replacement.refreshHash, rotatedAt, refreshHash),
      this.#statement(`INSERT INTO auth_sessions (refresh_hash, family_id, device_id, payload_json, expires_at, rotated_to_hash, revoked_at)
        SELECT ?, ?, ?, ?, ?, ?, ?
        WHERE EXISTS (SELECT 1 FROM auth_sessions WHERE refresh_hash = ? AND rotated_to_hash = ?)
          AND NOT EXISTS (SELECT 1 FROM auth_sessions WHERE refresh_hash = ?)`, replacement.refreshHash, replacement.familyId, replacement.deviceId, JSON.stringify(replacement.payload), replacement.expiresAt, replacement.rotatedToHash, replacement.revokedAt, refreshHash, replacement.refreshHash, replacement.refreshHash),
    ]);
    return changes(results[0]!) === 1;
  }

  async revokeDevice(deviceId: string, revokedAt: string): Promise<number> {
    assertIdentifier(deviceId, "device_id"); assertIsoDate(revokedAt, "revoked_at");
    return changes(await this.#run("UPDATE auth_sessions SET revoked_at = ? WHERE device_id = ? AND revoked_at IS NULL", revokedAt, deviceId));
  }

  async revokeAllSessions(revokedAt: string): Promise<number> {
    assertIsoDate(revokedAt, "revoked_at");
    return changes(await this.#run("UPDATE auth_sessions SET revoked_at = ? WHERE revoked_at IS NULL", revokedAt));
  }

  async getRateLimit(scopeKey: string): Promise<AuthRateLimitRecord | null> {
    assertIdentifier(scopeKey, "rate_limit_scope");
    const row = await this.#one("SELECT scope_key, failures, blocked_until, updated_at FROM auth_rate_limits WHERE scope_key = ? LIMIT 1", scopeKey);
    return row === null ? null : { scopeKey: String(row.scope_key), failures: Number(row.failures), blockedUntil: row.blocked_until === null ? null : String(row.blocked_until), updatedAt: String(row.updated_at) };
  }

  async putRateLimit(record: AuthRateLimitRecord): Promise<void> {
    assertIdentifier(record.scopeKey, "rate_limit_scope");
    if (!Number.isSafeInteger(record.failures) || record.failures < 0) throw new D1StorageError("invalid_auth_record", "Rate-limit failures are invalid");
    if (record.blockedUntil !== null) assertIsoDate(record.blockedUntil, "blocked_until"); assertIsoDate(record.updatedAt, "updated_at");
    await this.#run("INSERT INTO auth_rate_limits(scope_key, failures, blocked_until, updated_at) VALUES (?, ?, ?, ?) ON CONFLICT(scope_key) DO UPDATE SET failures = excluded.failures, blocked_until = excluded.blocked_until, updated_at = excluded.updated_at", record.scopeKey, record.failures, record.blockedUntil, record.updatedAt);
  }

  async exportFixture(maxRows = 10_000): Promise<D1ExportFixture> {
    this.#assertOpen(); positiveInteger(maxRows, "export_rows", 100_000);
    const payload: Record<string, Record<string, Json>[]> = {};
    for (const table of fixtureTables) {
      const rows = await this.#rows(`SELECT * FROM ${table} ORDER BY rowid ASC LIMIT ?`, maxRows + 1);
      if (rows.length > maxRows) throw new D1StorageError("export_too_large", `${table} exceeds the export bound`);
      payload[table] = rows as Record<string, Json>[];
    }
    return { formatVersion: 1, databaseSchemaVersion: currentD1SchemaVersion, sha256: await sha256(canonicalString(payload)), payload };
  }

  static async restoreFixture(binding: unknown, fixture: D1ExportFixture): Promise<D1SyncStorage> {
    if (fixture.formatVersion !== 1 || fixture.databaseSchemaVersion !== currentD1SchemaVersion || fixture.sha256 !== await sha256(canonicalString(fixture.payload))) {
      throw new D1StorageError("fixture_verification_failed", "D1 export fixture is incompatible or has been modified");
    }
    if (JSON.stringify(Object.keys(fixture.payload).sort()) !== JSON.stringify(fixtureTables)) {
      throw new D1StorageError("fixture_verification_failed", "D1 export fixture table set is incomplete");
    }
    const storage = await D1SyncStorage.open(binding, { migrate: true });
    const count = await storage.#one(`SELECT
      (SELECT COUNT(*) FROM sync_entities) +
      (SELECT COUNT(*) FROM sync_operations) +
      (SELECT COUNT(*) FROM sync_operation_receipts) +
      (SELECT COUNT(*) FROM sync_device_watermarks) +
      (SELECT COUNT(*) FROM auth_account) +
      (SELECT COUNT(*) FROM auth_one_time) +
      (SELECT COUNT(*) FROM auth_sessions) +
      (SELECT COUNT(*) FROM auth_rate_limits) AS count`);
    if (Number(count?.count ?? 0) !== 0) throw new D1StorageError("restore_target_not_empty", "D1 restore target must be empty");
    const statements: D1PreparedStatementLike[] = [];
    for (const [table, rows] of Object.entries(fixture.payload)) {
      const fields = fixtureColumns[table];
      if (fields === undefined) throw new D1StorageError("fixture_verification_failed", `Unexpected fixture table ${table}`);
      for (const row of rows) statements.push(storage.#statement(`INSERT OR REPLACE INTO ${table} (${fields.join(", ")}) VALUES (${fields.map(() => "?").join(", ")})`, ...fields.map((field) => asD1Value(row[field]))));
    }
    for (let offset = 0; offset < statements.length; offset += 40) await storage.#batch(statements.slice(offset, offset + 40));
    return storage;
  }

  close(): void { this.#closed = true; }

  async #migrate(migrations: readonly D1Migration[], current: number): Promise<void> {
    for (const migration of migrations) {
      if (migration.version <= current) continue;
      try {
        await this.#batch([
          ...migration.statements.map((sql) => this.#db.prepare(sql)),
          this.#statement(
            "INSERT INTO sync_schema_migrations(version, name, applied_at) VALUES (?, ?, ?)",
            migration.version,
            migration.name,
            new Date().toISOString(),
          ),
        ]);
      } catch (error) {
        throw new D1StorageError("migration_failed", `D1 migration ${migration.version} failed atomically`, { cause: error });
      }
    }
  }

  async #initializeMetadata(requested?: string): Promise<void> {
    const generation = requested ?? crypto.randomUUID(); assertIdentifier(generation, "stream_generation");
    await this.#batch([
      this.#statement("INSERT OR IGNORE INTO sync_metadata(key, value) VALUES ('stream_generation', ?)", generation),
      this.#db.prepare("INSERT OR IGNORE INTO sync_metadata(key, value) VALUES ('head_offset', '0')"),
      this.#db.prepare("INSERT OR IGNORE INTO sync_metadata(key, value) VALUES ('compaction_floor', '0')"),
    ]);
  }

  async #userVersion(): Promise<number> {
    try { return Number((await this.#one("SELECT MAX(version) AS version FROM sync_schema_migrations"))?.version ?? 0); }
    catch (error) {
      if (String(error).includes("no such table: sync_schema_migrations")) return 0;
      throw new D1StorageError("binding_unavailable", `D1 binding could not be queried: ${String(error)}`, { cause: error });
    }
  }
  async #generation(): Promise<string> { return String((await this.#requiredMetadata("stream_generation")).value); }
  async #metadataNumber(key: string): Promise<number> {
    const value = Number((await this.#requiredMetadata(key)).value);
    if (!Number.isSafeInteger(value) || value < 0) throw new D1StorageError("database_metadata_invalid", `D1 metadata ${key} is invalid`);
    return value;
  }
  async #requiredMetadata(key: string): Promise<Row> {
    const row = await this.#one("SELECT value FROM sync_metadata WHERE key = ? LIMIT 1", key);
    if (row === null) throw new D1StorageError("database_metadata_missing", `D1 metadata ${key} is missing`);
    return row;
  }
  async #requiredReceipt(id: string): Promise<Row> {
    const row = await this.#one("SELECT fingerprint, server_cursor FROM sync_operation_receipts WHERE operation_id = ? LIMIT 1", id);
    if (row === null) throw new D1StorageError("commit_failed", "D1 commit receipt is missing"); return row;
  }
  async #duplicate(row: Row, fingerprint: string): Promise<StorageCommitResult> {
    if (row.fingerprint !== fingerprint) throw new SyncCoreError("idempotency_collision", "Operation identifier was reused with different content");
    const offset = Number(row.server_cursor);
    return { cursor: encodeCursor({ generation: await this.#generation(), offset }), offset, duplicate: true, changed: false };
  }
  #statement(sql: string, ...values: D1Value[]): D1PreparedStatementLike { this.#assertOpen(); return values.length === 0 ? this.#db.prepare(sql) : this.#db.prepare(sql).bind(...values); }
  async #one(sql: string, ...values: D1Value[]): Promise<Row | null> { return (await this.#rows(sql, ...values))[0] ?? null; }
  async #rows(sql: string, ...values: D1Value[]): Promise<Row[]> { return (await this.#all(this.#statement(sql, ...values))).results as Row[]; }
  async #run(sql: string, ...values: D1Value[]): Promise<D1ResultLike> { const result = await this.#statement(sql, ...values).run(); this.#observe([result]); assertSuccess(result); return result; }
  async #all(statement: D1PreparedStatementLike): Promise<D1ResultLike> { const result = await statement.all(); this.#observe([result]); assertSuccess(result); return result; }
  async #batch(statements: D1PreparedStatementLike[]): Promise<D1ResultLike[]> { const results = await this.#db.batch(statements); this.#observe(results); for (const result of results) assertSuccess(result); return results; }
  #observe(results: D1ResultLike[]): void { this.#onUsage?.({ statements: results.length, rowsRead: results.reduce((sum, result) => sum + Number(result.meta.rows_read ?? 0), 0), rowsWritten: results.reduce((sum, result) => sum + Number(result.meta.rows_written ?? 0), 0) }); }
  #assertOpen(): void { if (this.#closed) throw new D1StorageError("database_closed", "D1 storage is closed"); }
}

function requireBinding(value: unknown): D1DatabaseLike { if (value === null || typeof value !== "object" || typeof (value as D1DatabaseLike).prepare !== "function" || typeof (value as D1DatabaseLike).batch !== "function") throw new D1StorageError("missing_binding", "A D1 database binding is required"); return value as D1DatabaseLike; }
function validateMigrations(items: readonly D1Migration[]): void { let expected = 1; for (const item of items) { if (item.version !== expected || !item.name.trim() || item.statements.length === 0 || item.statements.some((sql) => !sql.trim())) throw new D1StorageError("invalid_migration_set", "D1 migrations must be contiguous, named, and non-empty"); expected += 1; } }
function changes(result: D1ResultLike): number { return Number(result.meta.changes ?? result.meta.rows_written ?? 0); }
function assertSuccess(result: D1ResultLike): void { if (!result.success) throw new D1StorageError("query_failed", result.error ?? "D1 query failed"); }
function positiveInteger(value: number, label: string, maximum: number): number { if (!Number.isSafeInteger(value) || value < 1 || value > maximum) throw new D1StorageError("invalid_numeric_option", `${label} is invalid`); return value; }
function parseJson<T>(value: unknown, label: string): T { if (typeof value !== "string") throw new D1StorageError("database_record_invalid", `${label} is not text`); try { return JSON.parse(value) as T; } catch (error) { throw new D1StorageError("database_record_invalid", `${label} is invalid JSON`, { cause: error }); } }
function assertIdentifier(value: string, label: string): void { if (!/^[A-Za-z0-9._~:@+-]{1,256}$/.test(value)) throw new D1StorageError("invalid_auth_record", `${label} is invalid`); }
function assertHash(value: string, label: string): void { if (!/^[a-f0-9]{64}$/.test(value)) throw new D1StorageError("invalid_auth_record", `${label} must be a SHA-256 hash`); }
function assertIsoDate(value: string, label: string): void { if (typeof value !== "string" || Number.isNaN(Date.parse(value))) throw new D1StorageError("invalid_timestamp", `${label} is invalid`); }
function validateAccount(value: AuthAccountRecord): void { assertIdentifier(value.username, "username"); assertJson(value.verifier); if (!Number.isSafeInteger(value.passwordVersion) || value.passwordVersion < 1) throw new D1StorageError("invalid_auth_record", "Password version is invalid"); assertIsoDate(value.createdAt, "created_at"); assertIsoDate(value.updatedAt, "updated_at"); }
function validateOneTime(value: AuthOneTimeRecord): void { if (value.kind !== "login_challenge" && value.kind !== "authorization_code") throw new D1StorageError("invalid_auth_record", "One-time record kind is invalid"); assertHash(value.idHash, "one_time_id"); assertJson(value.payload); assertIsoDate(value.expiresAt, "expires_at"); if (value.consumedAt !== null) assertIsoDate(value.consumedAt, "consumed_at"); }
function validateSession(value: AuthSessionRecord): void { assertHash(value.refreshHash, "refresh_hash"); assertIdentifier(value.familyId, "family_id"); assertIdentifier(value.deviceId, "device_id"); assertJson(value.payload); assertIsoDate(value.expiresAt, "expires_at"); if (value.rotatedToHash !== null) assertHash(value.rotatedToHash, "rotated_to_hash"); if (value.revokedAt !== null) assertIsoDate(value.revokedAt, "revoked_at"); }
function assertJson(value: Json): void {
  const visit = (item: unknown): boolean => {
    if (item === null || typeof item === "string" || typeof item === "boolean") return true;
    if (typeof item === "number") return Number.isFinite(item);
    if (Array.isArray(item)) return item.every(visit);
    if (typeof item !== "object") return false;
    const prototype = Object.getPrototypeOf(item);
    return (prototype === Object.prototype || prototype === null) && Object.values(item).every(visit);
  };
  if (!visit(value)) throw new D1StorageError("invalid_auth_record", "Auth payload is not strict JSON");
}
function sessionFromRow(row: Row): AuthSessionRecord { return { refreshHash: String(row.refresh_hash), familyId: String(row.family_id), deviceId: String(row.device_id), payload: parseJson<Json>(row.payload_json, "session_payload"), expiresAt: String(row.expires_at), rotatedToHash: row.rotated_to_hash === null ? null : String(row.rotated_to_hash), revokedAt: row.revoked_at === null ? null : String(row.revoked_at) }; }
function canonicalString(value: unknown): string { const canonical = (item: unknown): unknown => Array.isArray(item) ? item.map(canonical) : item !== null && typeof item === "object" ? Object.fromEntries(Object.entries(item as Record<string, unknown>).sort(([a], [b]) => a.localeCompare(b)).map(([key, child]) => [key, canonical(child)])) : item; return JSON.stringify(canonical(value)); }
async function sha256(value: string): Promise<string> { const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)); return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join(""); }
function asD1Value(value: Json | undefined): D1Value { if (value === undefined || Array.isArray(value) || (value !== null && typeof value === "object")) throw new D1StorageError("fixture_verification_failed", "Fixture contains a non-scalar SQL value"); return value; }
