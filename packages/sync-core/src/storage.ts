import type { EntityState, Json, SyncOperation } from "./index";

export type MaybePromise<T> = T | Promise<T>;

export interface StorageCommitResult {
  cursor: string;
  offset: number;
  duplicate: boolean;
  changed: boolean;
}

export interface StoragePullPage {
  operations: SyncOperation[];
  cursor: string;
  headOffset: number;
  compactionFloor: number;
  requiresSnapshot: boolean;
  recoveryReason:
    | "none"
    | "missing_compacted_history"
    | "generation_changed"
    | "cursor_ahead";
}

export interface StorageSnapshot {
  schemaVersion: 1;
  cursor: string;
  entities: EntityState[];
}

export interface AuthAccountRecord {
  username: string;
  verifier: Json;
  passwordVersion: number;
  createdAt: string;
  updatedAt: string;
}

export interface AuthOneTimeRecord {
  kind: "login_challenge" | "authorization_code";
  idHash: string;
  payload: Json;
  expiresAt: string;
  consumedAt: string | null;
}

export interface AuthSessionRecord {
  refreshHash: string;
  familyId: string;
  deviceId: string;
  payload: Json;
  expiresAt: string;
  rotatedToHash: string | null;
  revokedAt: string | null;
}

export interface AuthRateLimitRecord {
  scopeKey: string;
  failures: number;
  blockedUntil: string | null;
  updatedAt: string;
}

export interface SyncStorage {
  readonly schemaVersion: number;
  commit(operation: SyncOperation, committedAt?: string): MaybePromise<StorageCommitResult>;
  pull(cursor: string | null, limit: number): MaybePromise<StoragePullPage>;
  snapshot(): MaybePromise<StorageSnapshot>;
  compact(throughOffset: number): MaybePromise<{ removedOperations: number; floorOffset: number }>;
  getAccount(): MaybePromise<AuthAccountRecord | null>;
  createAccount(account: AuthAccountRecord): MaybePromise<void>;
  updateAccount(account: AuthAccountRecord, expectedPasswordVersion: number): MaybePromise<boolean>;
  putOneTime(record: AuthOneTimeRecord): MaybePromise<void>;
  consumeOneTime(
    kind: AuthOneTimeRecord["kind"],
    idHash: string,
    consumedAt: string,
  ): MaybePromise<AuthOneTimeRecord | null>;
  putSession(session: AuthSessionRecord): MaybePromise<void>;
  getSession(refreshHash: string): MaybePromise<AuthSessionRecord | null>;
  rotateSession(
    refreshHash: string,
    replacement: AuthSessionRecord,
    rotatedAt: string,
  ): MaybePromise<boolean>;
  revokeDevice(deviceId: string, revokedAt: string): MaybePromise<number>;
  revokeAllSessions(revokedAt: string): MaybePromise<number>;
  getRateLimit(scopeKey: string): MaybePromise<AuthRateLimitRecord | null>;
  putRateLimit(record: AuthRateLimitRecord): MaybePromise<void>;
  close(): MaybePromise<void>;
}
