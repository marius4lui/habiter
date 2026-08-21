# Personal Sync convergence core

This page defines the runtime-neutral Personal Sync v1 operation and merge
algorithm. It builds on the [data contract](./personal-sync-data-contract.md)
and is shared by clients and storage adapters. Backend, HTTP, authentication,
and Flutter orchestration code must not replace these rules with adapter-local
conflict behavior.

## Logical identity and ordering

Every installation owns a stable, random, URL-safe device ID and a durable
monotonic operation sequence. Together they form a logical revision:

```text
(sequence, deviceId)
```

Sequence is compared first. The device ID is the deterministic tie-breaker for
concurrent operations with the same sequence. Wall-clock timestamps are never
authoritative because device clocks can be wrong or move backwards. Before a
local edit, a replica advances its sequence beyond both its durable local value
and every observed remote sequence. This is a Lamport clock: causally later
edits beat revisions they have seen, while the device ID resolves genuinely
concurrent ties.

The canonical operation and idempotency ID is derived from that revision:

```text
operation/<percent-encoded-device-id>/<sequence>
```

Reusing an ID for different content is an integrity error. An exact replay is a
no-op. Operation fingerprints use canonical JSON object-key ordering, so map
insertion order cannot change duplicate detection.

## Operations

An operation contains the protocol version, logical revision, kind, a validated
entity document, and explicit sets of changed payload and document-metadata
fields.

| Kind | Meaning | Payload rule | Lifecycle effect |
| --- | --- | --- | --- |
| `create` | First materialization | Complete live payload | Establishes a live entity but never revives a tombstone. |
| `patch` | Ordinary edit | One or more explicit changed fields | No lifecycle change. |
| `delete` | Durable deletion | Tombstone with no payload | Advances the lifecycle to deleted. |
| `restore` | Explicit recovery | Complete live payload | Revives only when its revision wins. |

Patch documents are complete and contract-valid, but only fields named in the
changed-field sets enter the merge. This validates each operation independently
without creating an unconditional whole-snapshot last-write-wins path.
Additive payload and document fields use the same field registers; sensitive
looking keys fail closed before state mutation.

## Deterministic merge

Each payload or document-metadata field is an independent register containing a
JSON value and logical revision. A candidate replaces the register only when
its revision compares greater. Independent edits therefore survive, while a
same-field conflict selects exactly one deterministic winner.

The entity lifecycle is a separate register. Delete and explicit restore use
the same total ordering. Ordinary patches can be retained while they arrive out
of order, but they cannot change a deleted lifecycle. A live materialization
includes only fields at or above its lifecycle revision:

- a patch arriving before creation becomes visible after the older create;
- fields older than a winning tombstone cannot resurrect an entity;
- patches after deletion still cannot resurrect it;
- restore is explicit, complete, and cuts off fields from the prior lifecycle;
- a late stale create never revives a tombstone.

Applying valid operations in any order produces the same canonical entity
state. Tests exercise complete permutations and 100 deterministic shuffled
mixed sequences across create, patch, delete, and restore.

## Cursors and recovery

Server cursors are opaque, canonical base64url tokens containing a version,
server generation, and non-negative stream offset. A server advertises the
retained cursor window as generation, floor, and head.

Incremental pull is safe only when the cursor uses the current generation and
falls inside the inclusive retained window. The client requests an
authoritative snapshot when:

- it has no cursor and the server has already compacted history;
- the server generation changed;
- its cursor is below the retained floor;
- its cursor is ahead of the server head.

Incremental cursors only move forward within one generation. Applying a
snapshot explicitly replaces the cursor and may change generation. Invalid or
non-canonical tokens fail closed; adapters must return the typed recovery path
rather than silently treating them as an empty history.

## Safe compaction

Processed-operation fingerprints may be pruned only behind a per-device server
acknowledgement watermark. A single global counter is invalid because device
sequences are independent. Compaction removes duplicate-detection ledger rows,
not entity registers or tombstones. Replayed acknowledged operations are still
state-idempotent because their revisions cannot beat retained field and
lifecycle registers.

Storage adapters may compact more aggressively only after proving an equivalent
snapshot and replay invariant. In particular, they must never discard a
tombstone merely because its operation ID left the duplicate ledger.

## Initial synchronization matrix

| Local state | Remote state | Plan |
| --- | --- | --- |
| Empty | Empty | No changes |
| Present | Empty | Upload local operations |
| Empty | Present | Download remote state |
| Present | Present | Reconcile bidirectionally through the same operation merge |

Neither side is declared the blanket winner. Adapters can page, persist, and
retry these plans, but all entity mutation still passes through the shared core.

## Adapter obligations

- Persist the device ID and next sequence before an operation can be retried.
- Never derive logical ordering from a timestamp.
- Preserve operation IDs, changed-field sets, unknown safe fields, and cursor
  tokens byte-for-byte across transport and storage boundaries.
- Apply a pull page durably before advancing its cursor.
- Surface snapshot recovery as a normal, resumable state.
- Keep server acknowledgement watermarks per device and retain tombstones.
- Reject protocol, schema, identity, idempotency, and sensitive-field errors
  before writing canonical state.
