import { createHash, randomUUID } from "node:crypto";
import { copyFile, mkdir, readFile, rename, rm, stat } from "node:fs/promises";
import path from "node:path";
import { DatabaseSync, backup } from "node:sqlite";
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
  type ReplicaState,
  type StorageCommitResult,
  type StoragePullPage,
  type StorageSnapshot,
  type SyncOperation,
  type SyncStorage
} from "@habiter/sync-core";
import {
  currentSqliteSchemaVersion,
  sqliteMigrations,
  type SqliteMigration
} from "./migrations";

export { currentSqliteSchemaVersion, sqliteMigrations, type SqliteMigration };

export class SqliteStorageError extends Error {
  constructor(readonly code: string, message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "SqliteStorageError";
  }
}

export interface SqliteSyncStorageOptions {
  migrations?: readonly SqliteMigration[];
  generation?: string;
  busyTimeoutMs?: number;
}

export interface SqliteBackupManifest {
  formatVersion: 1;
  databaseSchemaVersion: number;
  streamGeneration: string;
  headOffset: number;
  size: number;
  sha256: string;
}

export interface SqliteRestoreResult {
  restoredPath: string;
  rollbackPath: string | null;
  manifest: SqliteBackupManifest;
}

type SqlRow = Record<string, string | number | bigint | null>;

export class SqliteSyncStorage implements SyncStorage {
  readonly #db: DatabaseSync;
  readonly #filename: string;
  #closed = false;

  constructor(filename: string, options: SqliteSyncStorageOptions = {}) {
    if (!filename.trim()) throw new SqliteStorageError("invalid_database_path", "SQLite path must not be empty");
    this.#filename = filename;
    this.#db = new DatabaseSync(filename);
    this.#db.exec("PRAGMA foreign_keys = ON");
    this.#db.exec(`PRAGMA busy_timeout = ${positiveInteger(options.busyTimeoutMs ?? 5000, "busy_timeout")}`);
    if (filename !== ":memory:") {
      this.#db.exec("PRAGMA journal_mode = WAL");
      this.#db.exec("PRAGMA synchronous = FULL");
    }
    this.migrate(options.migrations ?? sqliteMigrations);
    this.#initializeMetadata(options.generation);
  }

  get schemaVersion(): number {
    this.#assertOpen();
    return this.#userVersion();
  }

  get filename(): string {
    return this.#filename;
  }

  migrate(migrations: readonly SqliteMigration[]): void {
    this.#assertOpen();
    validateMigrations(migrations);
    const current = this.#userVersion();
    const target = migrations.at(-1)?.version ?? 0;
    if (current > target) {
      throw new SqliteStorageError(
        "database_newer_than_service",
        `Database schema ${current} is newer than supported schema ${target}`
      );
    }
    if (current === target) return;
    this.#db.exec("BEGIN EXCLUSIVE");
    try {
      for (const migration of migrations) {
        if (migration.version <= current) continue;
        this.#db.exec(migration.sql);
        this.#db.exec(`PRAGMA user_version = ${migration.version}`);
      }
      this.#db.exec("COMMIT");
    } catch (error) {
      rollbackQuietly(this.#db);
      throw new SqliteStorageError(
        "migration_failed",
        `SQLite migration failed; schema remains at version ${current}`,
        { cause: error }
      );
    }
  }

  commit(input: SyncOperation, committedAt = new Date().toISOString()): StorageCommitResult {
    this.#assertOpen();
    assertIsoDate(committedAt, "committed_at");
    const operation = createOperation(input);
    const fingerprint = operationFingerprint(operation);
    this.#db.exec("BEGIN IMMEDIATE");
    try {
      const receipt = this.#db.prepare(
        "SELECT fingerprint, server_cursor FROM sync_operation_receipts WHERE operation_id = ?"
      ).get(operation.operationId) as SqlRow | undefined;
      if (receipt !== undefined) {
        if (receipt.fingerprint !== fingerprint) {
          throw new SyncCoreError(
            "idempotency_collision",
            "Operation identifier was reused with different content"
          );
        }
        this.#db.exec("COMMIT");
        const offset = Number(receipt.server_cursor);
        return {
          cursor: encodeCursor({ generation: this.#generation(), offset }),
          offset,
          duplicate: true,
          changed: false
        };
      }

      const entityRow = this.#db.prepare(
        "SELECT state_json FROM sync_entities WHERE entity_id = ?"
      ).get(operation.document.entityId) as SqlRow | undefined;
      const replica = emptyReplica();
      if (entityRow !== undefined) {
        const entity = parseJson<EntityState>(entityRow.state_json!, "entity_state");
        replica.entities[entity.entityId] = entity;
      }
      const applied = applyOperation(replica, operation);
      const entity = applied.state.entities[operation.document.entityId]!;
      const inserted = this.#db.prepare(`
        INSERT INTO sync_operations (
          operation_id, fingerprint, device_id, device_sequence,
          entity_id, operation_json, committed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(
        operation.operationId,
        fingerprint,
        operation.revision.deviceId,
        operation.revision.sequence,
        operation.document.entityId,
        JSON.stringify(operation),
        committedAt
      );
      const offset = Number(inserted.lastInsertRowid);
      this.#db.prepare(`
        INSERT INTO sync_operation_receipts (
          operation_id, fingerprint, device_id, device_sequence,
          server_cursor, committed_at
        ) VALUES (?, ?, ?, ?, ?, ?)
      `).run(
        operation.operationId,
        fingerprint,
        operation.revision.deviceId,
        operation.revision.sequence,
        offset,
        committedAt
      );
      this.#db.prepare(`
        INSERT INTO sync_entities (
          entity_id, state_json, deleted, lifecycle_sequence,
          lifecycle_device_id, updated_cursor
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(entity_id) DO UPDATE SET
          state_json = excluded.state_json,
          deleted = excluded.deleted,
          lifecycle_sequence = excluded.lifecycle_sequence,
          lifecycle_device_id = excluded.lifecycle_device_id,
          updated_cursor = excluded.updated_cursor
      `).run(
        entity.entityId,
        JSON.stringify(entity),
        entity.deleted ? 1 : 0,
        entity.lifecycleRevision?.sequence ?? null,
        entity.lifecycleRevision?.deviceId ?? null,
        offset
      );
      this.#setMetadata("head_offset", String(offset));
      this.#db.exec("COMMIT");
      return {
        cursor: encodeCursor({ generation: this.#generation(), offset }),
        offset,
        duplicate: false,
        changed: applied.outcome === "applied"
      };
    } catch (error) {
      rollbackQuietly(this.#db);
      throw error;
    }
  }

  pull(cursor: string | null, limit: number): StoragePullPage {
    this.#assertOpen();
    positiveInteger(limit, "pull_limit", 500);
    const generation = this.#generation();
    const headOffset = this.#metadataNumber("head_offset");
    const compactionFloor = this.#metadataNumber("compaction_floor");
    const decoded = cursor === null ? null : decodeCursor(cursor);
    const recoveryReason = evaluateCursor(decoded, {
      generation,
      floorOffset: compactionFloor,
      headOffset
    });
    if (recoveryReason !== "none") {
      return {
        operations: [],
        cursor: encodeCursor({ generation, offset: headOffset }),
        headOffset,
        compactionFloor,
        requiresSnapshot: true,
        recoveryReason
      };
    }
    const after = decoded?.offset ?? 0;
    const rows = this.#db.prepare(`
      SELECT server_cursor, operation_json
      FROM sync_operations
      WHERE server_cursor > ?
      ORDER BY server_cursor ASC
      LIMIT ?
    `).all(after, limit) as SqlRow[];
    const operations = rows.map((row) =>
      createOperation(parseJson<SyncOperation>(row.operation_json!, "operation"))
    );
    const nextOffset = rows.length === 0
      ? after
      : Number(rows.at(-1)!.server_cursor);
    return {
      operations,
      cursor: encodeCursor({ generation, offset: nextOffset }),
      headOffset,
      compactionFloor,
      requiresSnapshot: false,
      recoveryReason: "none"
    };
  }

  snapshot(): StorageSnapshot {
    this.#assertOpen();
    const generation = this.#generation();
    const headOffset = this.#metadataNumber("head_offset");
    const rows = this.#db.prepare(
      "SELECT state_json FROM sync_entities ORDER BY entity_id ASC"
    ).all() as SqlRow[];
    const entities = rows.map((row) =>
      parseJson<EntityState>(row.state_json!, "entity_state")
    );
    decodeReplica({
      schemaVersion: 1,
      entities: Object.fromEntries(entities.map((entity) => [entity.entityId, entity])),
      processedOperations: {}
    });
    return {
      schemaVersion: 1,
      cursor: encodeCursor({ generation, offset: headOffset }),
      entities
    };
  }

  compact(throughOffset: number): { removedOperations: number; floorOffset: number } {
    this.#assertOpen();
    if (!Number.isSafeInteger(throughOffset) || throughOffset < 0) {
      throw new SqliteStorageError("invalid_compaction_cursor", "Compaction cursor is invalid");
    }
    const head = this.#metadataNumber("head_offset");
    if (throughOffset > head) {
      throw new SqliteStorageError("invalid_compaction_cursor", "Compaction cannot pass stream head");
    }
    const currentFloor = this.#metadataNumber("compaction_floor");
    const nextFloor = Math.max(currentFloor, throughOffset);
    this.#db.exec("BEGIN IMMEDIATE");
    try {
      const watermarks = this.#db.prepare(`
        SELECT device_id, MAX(device_sequence) AS sequence
        FROM sync_operations
        WHERE server_cursor <= ?
        GROUP BY device_id
      `).all(nextFloor) as SqlRow[];
      const upsert = this.#db.prepare(`
        INSERT INTO sync_device_watermarks(device_id, sequence)
        VALUES (?, ?)
        ON CONFLICT(device_id) DO UPDATE SET
          sequence = MAX(sequence, excluded.sequence)
      `);
      for (const watermark of watermarks) {
        upsert.run(watermark.device_id!, watermark.sequence!);
      }
      const deleted = this.#db.prepare(
        "DELETE FROM sync_operations WHERE server_cursor <= ?"
      ).run(nextFloor);
      this.#setMetadata("compaction_floor", String(nextFloor));
      this.#db.exec("COMMIT");
      return { removedOperations: Number(deleted.changes), floorOffset: nextFloor };
    } catch (error) {
      rollbackQuietly(this.#db);
      throw error;
    }
  }

  getAccount(): AuthAccountRecord | null {
    this.#assertOpen();
    const row = this.#db.prepare(`
      SELECT username, verifier_json, password_version, created_at, updated_at
      FROM auth_account WHERE singleton = 1
    `).get() as SqlRow | undefined;
    return row === undefined ? null : {
      username: row.username as string,
      verifier: parseJson<Json>(row.verifier_json!, "account_verifier"),
      passwordVersion: Number(row.password_version),
      createdAt: row.created_at as string,
      updatedAt: row.updated_at as string
    };
  }

  createAccount(account: AuthAccountRecord): void {
    this.#assertOpen();
    validateAccount(account);
    try {
      this.#db.prepare(`
        INSERT INTO auth_account (
          singleton, username, verifier_json, password_version, created_at, updated_at
        ) VALUES (1, ?, ?, ?, ?, ?)
      `).run(
        account.username,
        JSON.stringify(account.verifier),
        account.passwordVersion,
        account.createdAt,
        account.updatedAt
      );
    } catch (error) {
      throw new SqliteStorageError(
        "account_already_initialized",
        "A SQLite sync instance can contain only one account",
        { cause: error }
      );
    }
  }

  updateAccount(account: AuthAccountRecord, expectedPasswordVersion: number): boolean {
    this.#assertOpen();
    validateAccount(account);
    const result = this.#db.prepare(`
      UPDATE auth_account
      SET username = ?, verifier_json = ?, password_version = ?, updated_at = ?
      WHERE singleton = 1 AND password_version = ?
    `).run(
      account.username,
      JSON.stringify(account.verifier),
      account.passwordVersion,
      account.updatedAt,
      expectedPasswordVersion
    );
    return Number(result.changes) === 1;
  }

  putOneTime(record: AuthOneTimeRecord): void {
    this.#assertOpen();
    validateOneTime(record);
    this.#db.prepare(`
      INSERT INTO auth_one_time(kind, id_hash, payload_json, expires_at, consumed_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      record.kind,
      record.idHash,
      JSON.stringify(record.payload),
      record.expiresAt,
      record.consumedAt
    );
  }

  consumeOneTime(
    kind: AuthOneTimeRecord["kind"],
    idHash: string,
    consumedAt: string
  ): AuthOneTimeRecord | null {
    this.#assertOpen();
    assertHash(idHash, "one_time_id");
    assertIsoDate(consumedAt, "consumed_at");
    this.#db.exec("BEGIN IMMEDIATE");
    try {
      const row = this.#db.prepare(`
        SELECT payload_json, expires_at
        FROM auth_one_time
        WHERE kind = ? AND id_hash = ? AND consumed_at IS NULL
      `).get(kind, idHash) as SqlRow | undefined;
      if (row === undefined) {
        this.#db.exec("COMMIT");
        return null;
      }
      const updated = this.#db.prepare(`
        UPDATE auth_one_time SET consumed_at = ?
        WHERE kind = ? AND id_hash = ? AND consumed_at IS NULL
      `).run(consumedAt, kind, idHash);
      if (Number(updated.changes) !== 1) {
        this.#db.exec("COMMIT");
        return null;
      }
      this.#db.exec("COMMIT");
      return {
        kind,
        idHash,
        payload: parseJson<Json>(row.payload_json!, "one_time_payload"),
        expiresAt: row.expires_at as string,
        consumedAt
      };
    } catch (error) {
      rollbackQuietly(this.#db);
      throw error;
    }
  }

  putSession(session: AuthSessionRecord): void {
    this.#assertOpen();
    validateSession(session);
    this.#db.prepare(`
      INSERT INTO auth_sessions (
        refresh_hash, family_id, device_id, payload_json, expires_at,
        rotated_to_hash, revoked_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      session.refreshHash,
      session.familyId,
      session.deviceId,
      JSON.stringify(session.payload),
      session.expiresAt,
      session.rotatedToHash,
      session.revokedAt
    );
  }

  getSession(refreshHash: string): AuthSessionRecord | null {
    this.#assertOpen();
    assertHash(refreshHash, "refresh_hash");
    const row = this.#db.prepare(`
      SELECT refresh_hash, family_id, device_id, payload_json, expires_at,
             rotated_to_hash, revoked_at
      FROM auth_sessions WHERE refresh_hash = ?
    `).get(refreshHash) as SqlRow | undefined;
    return row === undefined ? null : sessionFromRow(row);
  }

  rotateSession(
    refreshHash: string,
    replacement: AuthSessionRecord,
    rotatedAt: string
  ): boolean {
    this.#assertOpen();
    assertHash(refreshHash, "refresh_hash");
    validateSession(replacement);
    assertIsoDate(rotatedAt, "rotated_at");
    this.#db.exec("BEGIN IMMEDIATE");
    try {
      const current = this.getSession(refreshHash);
      if (current === null || current.rotatedToHash !== null || current.revokedAt !== null) {
        this.#db.exec("COMMIT");
        return false;
      }
      this.putSession(replacement);
      const updated = this.#db.prepare(`
        UPDATE auth_sessions
        SET rotated_to_hash = ?, rotated_at = ?
        WHERE refresh_hash = ? AND rotated_to_hash IS NULL AND revoked_at IS NULL
      `).run(replacement.refreshHash, rotatedAt, refreshHash);
      if (Number(updated.changes) !== 1) {
        throw new SqliteStorageError("session_rotation_race", "Refresh session changed during rotation");
      }
      this.#db.exec("COMMIT");
      return true;
    } catch (error) {
      rollbackQuietly(this.#db);
      throw error;
    }
  }

  revokeDevice(deviceId: string, revokedAt: string): number {
    this.#assertOpen();
    assertIdentifier(deviceId, "device_id");
    assertIsoDate(revokedAt, "revoked_at");
    return Number(this.#db.prepare(`
      UPDATE auth_sessions SET revoked_at = ?
      WHERE device_id = ? AND revoked_at IS NULL
    `).run(revokedAt, deviceId).changes);
  }

  revokeAllSessions(revokedAt: string): number {
    this.#assertOpen();
    assertIsoDate(revokedAt, "revoked_at");
    return Number(this.#db.prepare(`
      UPDATE auth_sessions SET revoked_at = ? WHERE revoked_at IS NULL
    `).run(revokedAt).changes);
  }

  getRateLimit(scopeKey: string): AuthRateLimitRecord | null {
    this.#assertOpen();
    assertIdentifier(scopeKey, "rate_limit_scope");
    const row = this.#db.prepare(`
      SELECT scope_key, failures, blocked_until, updated_at
      FROM auth_rate_limits WHERE scope_key = ?
    `).get(scopeKey) as SqlRow | undefined;
    return row === undefined ? null : {
      scopeKey: row.scope_key as string,
      failures: Number(row.failures),
      blockedUntil: row.blocked_until as string | null,
      updatedAt: row.updated_at as string
    };
  }

  putRateLimit(record: AuthRateLimitRecord): void {
    this.#assertOpen();
    assertIdentifier(record.scopeKey, "rate_limit_scope");
    if (!Number.isSafeInteger(record.failures) || record.failures < 0) {
      throw new SqliteStorageError("invalid_auth_record", "Rate-limit failures are invalid");
    }
    if (record.blockedUntil !== null) assertIsoDate(record.blockedUntil, "blocked_until");
    assertIsoDate(record.updatedAt, "updated_at");
    this.#db.prepare(`
      INSERT INTO auth_rate_limits(scope_key, failures, blocked_until, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(scope_key) DO UPDATE SET
        failures = excluded.failures,
        blocked_until = excluded.blocked_until,
        updated_at = excluded.updated_at
    `).run(record.scopeKey, record.failures, record.blockedUntil, record.updatedAt);
  }

  async backup(destination: string): Promise<SqliteBackupManifest> {
    this.#assertOpen();
    if (this.#filename === ":memory:") {
      throw new SqliteStorageError("backup_unsupported", "In-memory databases cannot be backed up as service state");
    }
    if (samePath(this.#filename, destination)) {
      throw new SqliteStorageError("invalid_backup_path", "Backup destination must differ from the live database");
    }
    await mkdir(path.dirname(destination), { recursive: true });
    await rm(destination, { force: true });
    await backup(this.#db, destination);
    return SqliteSyncStorage.verifyBackup(destination);
  }

  static async verifyBackup(
    filename: string,
    expectedSha256?: string
  ): Promise<SqliteBackupManifest> {
    const bytes = await readFile(filename);
    const sha256 = createHash("sha256").update(bytes).digest("hex");
    if (expectedSha256 !== undefined && expectedSha256 !== sha256) {
      throw new SqliteStorageError("backup_checksum_mismatch", "SQLite backup checksum does not match");
    }
    const db = new DatabaseSync(filename, { readOnly: true });
    try {
      const integrity = db.prepare("PRAGMA integrity_check").get() as SqlRow;
      if (Object.values(integrity)[0] !== "ok") {
        throw new SqliteStorageError("backup_integrity_failed", "SQLite integrity check failed");
      }
      const version = Number((db.prepare("PRAGMA user_version").get() as SqlRow).user_version);
      if (version !== currentSqliteSchemaVersion) {
        throw new SqliteStorageError(
          "backup_schema_mismatch",
          `Backup schema ${version} does not match ${currentSqliteSchemaVersion}`
        );
      }
      const metadataRows = db.prepare(
        "SELECT key, value FROM sync_metadata WHERE key IN ('stream_generation', 'head_offset')"
      ).all() as SqlRow[];
      const metadata = Object.fromEntries(
        metadataRows.map((row) => [row.key as string, row.value as string])
      );
      if (metadata.stream_generation === undefined || metadata.head_offset === undefined) {
        throw new SqliteStorageError("backup_metadata_missing", "Backup sync metadata is incomplete");
      }
      return {
        formatVersion: 1,
        databaseSchemaVersion: version,
        streamGeneration: metadata.stream_generation,
        headOffset: Number(metadata.head_offset),
        size: (await stat(filename)).size,
        sha256
      };
    } finally {
      db.close();
    }
  }

  static async restoreBackup(
    backupPath: string,
    destinationPath: string,
    expectedSha256?: string
  ): Promise<SqliteRestoreResult> {
    if (samePath(backupPath, destinationPath)) {
      throw new SqliteStorageError("invalid_restore_path", "Backup and restore destination must differ");
    }
    const manifest = await SqliteSyncStorage.verifyBackup(backupPath, expectedSha256);
    await mkdir(path.dirname(destinationPath), { recursive: true });
    const temporaryPath = `${destinationPath}.restore-${randomUUID()}`;
    const rollbackPath = `${destinationPath}.rollback-${Date.now()}`;
    await copyFile(backupPath, temporaryPath);
    await SqliteSyncStorage.verifyBackup(temporaryPath, manifest.sha256);
    let rollback: string | null = null;
    try {
      const destinationExists = await checkpointForReplacement(destinationPath);
      if (destinationExists) {
        await rename(destinationPath, rollbackPath);
        rollback = rollbackPath;
      }
    } catch (error) {
      await rm(temporaryPath, { force: true });
      throw error;
    }
    try {
      await rename(temporaryPath, destinationPath);
    } catch (error) {
      if (rollback !== null) await rename(rollback, destinationPath);
      await rm(temporaryPath, { force: true });
      throw error;
    }
    return { restoredPath: destinationPath, rollbackPath: rollback, manifest };
  }

  static async rollbackRestore(
    destinationPath: string,
    rollbackPath: string
  ): Promise<void> {
    if (samePath(destinationPath, rollbackPath)) {
      throw new SqliteStorageError("invalid_restore_path", "Destination and rollback paths must differ");
    }
    await SqliteSyncStorage.verifyBackup(rollbackPath);
    await checkpointForReplacement(destinationPath);
    await checkpointForReplacement(rollbackPath);
    const failedPath = `${destinationPath}.failed-${randomUUID()}`;
    await rename(destinationPath, failedPath);
    try {
      await rename(rollbackPath, destinationPath);
      await rm(failedPath, { force: true });
    } catch (error) {
      await rename(failedPath, destinationPath);
      throw error;
    }
  }

  close(): void {
    if (this.#closed) return;
    this.#db.close();
    this.#closed = true;
  }

  #initializeMetadata(requestedGeneration?: string): void {
    const generation = requestedGeneration ?? randomUUID();
    assertIdentifier(generation, "stream_generation");
    this.#db.prepare(
      "INSERT OR IGNORE INTO sync_metadata(key, value) VALUES ('stream_generation', ?)"
    ).run(generation);
    this.#db.exec(
      "INSERT OR IGNORE INTO sync_metadata(key, value) VALUES ('head_offset', '0')"
    );
    this.#db.exec(
      "INSERT OR IGNORE INTO sync_metadata(key, value) VALUES ('compaction_floor', '0')"
    );
  }

  #generation(): string {
    return this.#metadata("stream_generation");
  }

  #metadata(key: string): string {
    const row = this.#db.prepare(
      "SELECT value FROM sync_metadata WHERE key = ?"
    ).get(key) as SqlRow | undefined;
    if (row === undefined || typeof row.value !== "string") {
      throw new SqliteStorageError("database_metadata_missing", `SQLite metadata ${key} is missing`);
    }
    return row.value;
  }

  #metadataNumber(key: string): number {
    const value = Number(this.#metadata(key));
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new SqliteStorageError("database_metadata_invalid", `SQLite metadata ${key} is invalid`);
    }
    return value;
  }

  #setMetadata(key: string, value: string): void {
    const result = this.#db.prepare(
      "UPDATE sync_metadata SET value = ? WHERE key = ?"
    ).run(value, key);
    if (Number(result.changes) !== 1) {
      throw new SqliteStorageError("database_metadata_missing", `SQLite metadata ${key} is missing`);
    }
  }

  #userVersion(): number {
    return Number((this.#db.prepare("PRAGMA user_version").get() as SqlRow).user_version);
  }

  #assertOpen(): void {
    if (this.#closed) throw new SqliteStorageError("database_closed", "SQLite storage is closed");
  }
}

function validateMigrations(migrations: readonly SqliteMigration[]): void {
  let expected = 1;
  for (const migration of migrations) {
    if (migration.version !== expected || !migration.name.trim() || !migration.sql.trim()) {
      throw new SqliteStorageError(
        "invalid_migration_set",
        "SQLite migrations must be contiguous, named, and non-empty"
      );
    }
    expected += 1;
  }
}

function validateAccount(account: AuthAccountRecord): void {
  assertIdentifier(account.username, "username");
  assertJson(account.verifier, "account_verifier");
  if (!Number.isSafeInteger(account.passwordVersion) || account.passwordVersion < 1) {
    throw new SqliteStorageError("invalid_auth_record", "Password version is invalid");
  }
  assertIsoDate(account.createdAt, "created_at");
  assertIsoDate(account.updatedAt, "updated_at");
}

function validateOneTime(record: AuthOneTimeRecord): void {
  if (record.kind !== "login_challenge" && record.kind !== "authorization_code") {
    throw new SqliteStorageError("invalid_auth_record", "One-time record kind is invalid");
  }
  assertHash(record.idHash, "one_time_id");
  assertJson(record.payload, "one_time_payload");
  assertIsoDate(record.expiresAt, "expires_at");
  if (record.consumedAt !== null) assertIsoDate(record.consumedAt, "consumed_at");
}

function validateSession(session: AuthSessionRecord): void {
  assertHash(session.refreshHash, "refresh_hash");
  assertIdentifier(session.familyId, "family_id");
  assertIdentifier(session.deviceId, "device_id");
  assertJson(session.payload, "session_payload");
  assertIsoDate(session.expiresAt, "expires_at");
  if (session.rotatedToHash !== null) assertHash(session.rotatedToHash, "rotated_to_hash");
  if (session.revokedAt !== null) assertIsoDate(session.revokedAt, "revoked_at");
}

function sessionFromRow(row: SqlRow): AuthSessionRecord {
  return {
    refreshHash: row.refresh_hash as string,
    familyId: row.family_id as string,
    deviceId: row.device_id as string,
    payload: parseJson<Json>(row.payload_json!, "session_payload"),
    expiresAt: row.expires_at as string,
    rotatedToHash: row.rotated_to_hash as string | null,
    revokedAt: row.revoked_at as string | null
  };
}

function assertJson(value: Json, label: string): void {
  try {
    const encoded = JSON.stringify(value);
    if (encoded === undefined || JSON.parse(encoded) === undefined || !isStrictJson(value)) throw new Error();
  } catch (error) {
    throw new SqliteStorageError("invalid_auth_record", `${label} is not JSON-compatible`, {
      cause: error
    });
  }
}

function isStrictJson(value: unknown): value is Json {
  if (value === null || typeof value === "string" || typeof value === "boolean") return true;
  if (typeof value === "number") return Number.isFinite(value);
  if (Array.isArray(value)) return value.every(isStrictJson);
  if (typeof value !== "object") return false;
  const prototype = Object.getPrototypeOf(value);
  return (prototype === Object.prototype || prototype === null) &&
    Object.values(value as Record<string, unknown>).every(isStrictJson);
}

function parseJson<T>(value: SqlRow[string], label: string): T {
  if (typeof value !== "string") {
    throw new SqliteStorageError("database_record_invalid", `${label} is not text`);
  }
  try {
    return JSON.parse(value) as T;
  } catch (error) {
    throw new SqliteStorageError("database_record_invalid", `${label} is invalid JSON`, {
      cause: error
    });
  }
}

function positiveInteger(value: number, label: string, maximum = 60_000): number {
  if (!Number.isSafeInteger(value) || value < 1 || value > maximum) {
    throw new SqliteStorageError("invalid_numeric_option", `${label} is invalid`);
  }
  return value;
}

function assertIdentifier(value: string, label: string): void {
  if (!/^[A-Za-z0-9._~:@+-]{1,256}$/.test(value)) {
    throw new SqliteStorageError("invalid_auth_record", `${label} is invalid`);
  }
}

function assertHash(value: string, label: string): void {
  if (!/^[a-f0-9]{64}$/.test(value)) {
    throw new SqliteStorageError("invalid_auth_record", `${label} must be a SHA-256 hash`);
  }
}

function assertIsoDate(value: string, label: string): void {
  if (typeof value !== "string" || Number.isNaN(Date.parse(value))) {
    throw new SqliteStorageError("invalid_timestamp", `${label} is invalid`);
  }
}

function rollbackQuietly(db: DatabaseSync): void {
  try {
    db.exec("ROLLBACK");
  } catch {
    // The original error remains authoritative when SQLite already rolled back.
  }
}

function samePath(left: string, right: string): boolean {
  return path.resolve(left) === path.resolve(right);
}

async function checkpointForReplacement(filename: string): Promise<boolean> {
  try {
    await stat(filename);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw error;
  }
  const db = new DatabaseSync(filename);
  try {
    db.exec("PRAGMA busy_timeout = 1");
    const checkpoint = db.prepare("PRAGMA wal_checkpoint(TRUNCATE)").get() as SqlRow;
    if (Number(checkpoint.busy) !== 0) {
      throw new SqliteStorageError(
        "database_busy",
        "SQLite destination is busy; stop the service before restore",
      );
    }
    const integrity = db.prepare("PRAGMA integrity_check").get() as SqlRow;
    if (Object.values(integrity)[0] !== "ok") {
      throw new SqliteStorageError("restore_destination_invalid", "SQLite destination failed integrity check");
    }
  } finally {
    db.close();
  }
  await rm(`${filename}-wal`, { force: true });
  await rm(`${filename}-shm`, { force: true });
  return true;
}
