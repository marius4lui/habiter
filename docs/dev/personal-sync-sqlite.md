# Personal Sync SQLite storage

`@habiter/sync-sqlite` is the transactional storage adapter for the
self-hosted Personal Sync service. It implements the shared
`@habiter/sync-core` storage contract with Node's built-in SQLite API and is
intended to be mounted on persistent local storage by the Docker service.

The adapter owns persistence only. HTTP behavior, login policy, password
hashing, token creation, and container assembly belong to later service layers.

## Runtime and database

Use Node.js 24 or newer. The adapter currently relies on `node:sqlite`, which
Node still reports as experimental at startup. A file-backed database enables
WAL journal mode, full synchronous durability, foreign keys, and a bounded busy
timeout. In-memory databases are supported for conformance tests but cannot be
used with the service backup primitive.

The schema is migrated by contiguous, numbered migrations in one exclusive
transaction. A failed statement rolls back every statement and the
`user_version` change from that migration run. A database newer than the
adapter fails closed rather than being opened with an older schema.

## Durable invariants

- Commits, receipts, entity state, and stream-head advancement share one
  immediate transaction.
- Exact operation retries return their original cursor. Reusing an operation
  ID with different content is an integrity error.
- Stream cursors are monotonically allocated by SQLite and remain stable after
  restart.
- Compaction removes retained stream rows through a cursor but preserves
  operation receipts, entity registers, and tombstones.
- One-time auth records and refresh-token rotation use transactions so only one
  consumer can win.
- Account password updates use a password-version compare-and-swap.

The reusable storage conformance suite is exported from
`@habiter/sync-core/test-support`. Every server storage adapter must run it;
adapter-local tests cannot substitute a different contract.

## Backup

Call `storage.backup(destination)` on the running adapter. SQLite's online
backup API creates a consistent database copy, after which the adapter runs an
integrity check and returns a manifest containing:

- manifest format and database schema versions;
- stream generation and head offset;
- byte size and SHA-256 checksum.

Persist the database and its manifest outside the replaceable container. Do
not copy only a live `*.sqlite` file with ordinary filesystem tools while WAL
mode is active.

## Restore and rollback

Stop the service and close every database connection before restore. Then:

1. Verify the backup and, when available, its recorded SHA-256 checksum.
2. Call `SqliteSyncStorage.restoreBackup(backup, destination, checksum)`.
3. Start the service and run its health and sync smoke checks.
4. Keep the returned rollback path until verification succeeds.
5. If verification fails, stop the service again and call
   `rollbackRestore(destination, rollbackPath)`.

Restore first verifies the source, copies and verifies a temporary candidate,
then atomically replaces the destination. If replacement fails, the original
database is put back. Rollback itself also verifies the saved database before
switching files.

The caller owns retention and eventual deletion of successful rollback files.
Neither restore nor rollback may run while a service process still holds the
destination or its WAL sidecars open.

## Validation

Run the adapter gate directly:

```sh
pnpm sync:sqlite:check
```

The suite covers shared semantics, migration rollback, transaction rollback,
two-connection WAL writes, close-and-reopen persistence, checksum verification,
restore, and restore rollback. The root quality workflow runs the same gate.
