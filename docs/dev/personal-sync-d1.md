# Personal Sync D1 storage

`@habiter/sync-d1` implements the same Personal Sync storage contract as the
SQLite adapter on Cloudflare D1. It is storage infrastructure only: Worker
routing, authentication policy, and production deployment belong to separate
children of the sync epic.

## Binding and schema safety

Open the adapter with the configured D1 binding. A missing binding,
uninitialized schema, partially migrated schema, or schema newer than the
adapter fails closed. Production request paths do not implicitly migrate;
deployment tooling must run the reviewed, contiguous migrations first.

D1 does not authorize application code to use `PRAGMA user_version`, so the
adapter records applied versions in `sync_schema_migrations`. Each migration is
one D1 batch. Cloudflare documents batches as transactions: statements run in
order and one failing statement rolls back the sequence.

## Transaction and concurrency model

Each operation commit uses a transactional D1 batch for the change row,
idempotency receipt, materialized entity, and stream head. Entity rows carry a
storage version guarded by a database trigger. If two requests read the same
version, the stale batch aborts and the adapter rereads and retries a bounded
number of times. Exact operation retries keep their first cursor, while an ID
collision with different content fails as an integrity error.

One-time auth consumption uses `UPDATE ... RETURNING`. Refresh rotation updates
the prior session and conditionally inserts its replacement in one batch.
Compaction retains receipts and entity tombstones.

## Bounded and indexed queries

- Pull pages accept at most 500 operations and use the stream cursor primary
  key.
- Snapshot and export sizes have explicit configurable row bounds.
- Receipt, entity, session-device, session-family, one-time-expiry, and
  device-sequence lookups have dedicated primary keys or indexes.
- The local D1 suite runs `EXPLAIN QUERY PLAN` for representative cursor,
  receipt, and session queries and rejects scan plans.
- One adapter call uses at most 11 D1 statements in the measured workflow,
  below the Workers Free limit of 50 D1 queries per invocation.

## Free-plan usage evidence

Cloudflare's April 2026 documentation lists daily Workers Free allowances of
[5 million rows read and 100,000 rows written](https://developers.cloudflare.com/d1/platform/pricing/),
plus a [500 MB per-database limit and 50 D1 queries per Worker invocation](https://developers.cloudflare.com/d1/platform/limits/).
Indexes add row writes but avoid broad row scans, so the suite accounts from
the `meta.rows_read` and `meta.rows_written` values returned by local D1.

The representative test performs one habit creation, 100 same-entity edits,
and one 500-row pull. With Miniflare/D1 runtime `3.20250718.3`, it records:

| Metric | Observed | Daily free allowance | Share |
| --- | ---: | ---: | ---: |
| Rows read | 1,112 | 5,000,000 | 0.023% |
| Rows written | 910 | 100,000 | 0.910% |

This is test evidence, not a billing guarantee. Operators must monitor D1's
dashboard or analytics because authentication traffic, retries, exports, and
multiple instances add usage. Re-run the accounting test and review current
Cloudflare limits when migrations, indexes, or query shapes change.

## Verified export and restore

`exportFixture()` produces a bounded logical export of every sync and auth
table. The fixture includes its format version, database schema version, and a
SHA-256 digest over canonical JSON. Restore verifies all three before writing,
requires an otherwise empty initialized database, and writes bounded batches.

Restore is intended for a newly created D1 database. If any restore batch
fails, discard that target and retry with a new empty database; do not route a
Worker to a partially restored target. Verify the restored snapshot before
changing the Worker binding. D1 Time Travel remains the platform-level rollback
mechanism for an already active production database.

## Validation

```sh
pnpm sync:d1:check
```

The gate bundles a route-independent Worker fixture and runs the shared storage
conformance suite against local D1, plus binding/version failures, atomic
migration failure, concurrent writers, query plans, usage accounting, and
checksum-verified export/restore.
