export interface D1Migration {
  version: number;
  name: string;
  statements: readonly string[];
}

export const d1Migrations: readonly D1Migration[] = [
  {
    version: 1,
    name: "initial_sync_storage",
    statements: [
      "CREATE TABLE sync_schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL) STRICT",
      "CREATE TABLE sync_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT",
      "CREATE TABLE sync_entities (entity_id TEXT PRIMARY KEY, state_json TEXT NOT NULL, deleted INTEGER NOT NULL CHECK (deleted IN (0, 1)), lifecycle_sequence INTEGER, lifecycle_device_id TEXT, updated_cursor INTEGER NOT NULL, state_version INTEGER NOT NULL CHECK (state_version > 0)) STRICT",
      "CREATE TABLE sync_operations (server_cursor INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT NOT NULL UNIQUE, fingerprint TEXT NOT NULL, device_id TEXT NOT NULL, device_sequence INTEGER NOT NULL CHECK (device_sequence > 0), entity_id TEXT NOT NULL, operation_json TEXT NOT NULL, committed_at TEXT NOT NULL) STRICT",
      "CREATE TABLE sync_operation_receipts (operation_id TEXT PRIMARY KEY, fingerprint TEXT NOT NULL, device_id TEXT NOT NULL, device_sequence INTEGER NOT NULL CHECK (device_sequence > 0), server_cursor INTEGER NOT NULL, committed_at TEXT NOT NULL) STRICT",
      "CREATE TABLE sync_device_watermarks (device_id TEXT PRIMARY KEY, sequence INTEGER NOT NULL CHECK (sequence >= 0)) STRICT",
      "CREATE TABLE auth_account (singleton INTEGER PRIMARY KEY CHECK (singleton = 1), username TEXT NOT NULL UNIQUE, verifier_json TEXT NOT NULL, password_version INTEGER NOT NULL CHECK (password_version > 0), created_at TEXT NOT NULL, updated_at TEXT NOT NULL) STRICT",
      "CREATE TABLE auth_one_time (kind TEXT NOT NULL CHECK (kind IN ('login_challenge', 'authorization_code')), id_hash TEXT NOT NULL, payload_json TEXT NOT NULL, expires_at TEXT NOT NULL, consumed_at TEXT, PRIMARY KEY (kind, id_hash)) STRICT",
      "CREATE TABLE auth_sessions (refresh_hash TEXT PRIMARY KEY, family_id TEXT NOT NULL, device_id TEXT NOT NULL, payload_json TEXT NOT NULL, expires_at TEXT NOT NULL, rotated_to_hash TEXT, rotated_at TEXT, revoked_at TEXT) STRICT",
      "CREATE TABLE auth_rate_limits (scope_key TEXT PRIMARY KEY, failures INTEGER NOT NULL CHECK (failures >= 0), blocked_until TEXT, updated_at TEXT NOT NULL) STRICT",
      "CREATE TRIGGER sync_entities_version_update BEFORE UPDATE ON sync_entities WHEN NEW.state_version != OLD.state_version + 1 BEGIN SELECT RAISE(ABORT, 'stale_entity_version'); END",
    ],
  },
  {
    version: 2,
    name: "bounded_query_indexes",
    statements: [
      "CREATE INDEX sync_operations_entity_cursor ON sync_operations(entity_id, server_cursor)",
      "CREATE INDEX sync_operations_device_sequence ON sync_operations(device_id, device_sequence)",
      "CREATE INDEX auth_one_time_expiry ON auth_one_time(kind, expires_at)",
      "CREATE INDEX auth_sessions_device ON auth_sessions(device_id, revoked_at)",
      "CREATE INDEX auth_sessions_family ON auth_sessions(family_id, revoked_at)",
    ],
  },
] as const;

export const currentD1SchemaVersion = d1Migrations.at(-1)!.version;
