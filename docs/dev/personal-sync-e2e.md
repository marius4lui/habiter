# Personal Sync integration and evidence matrix

This page is the durable verification contract for the Personal Sync v1
platform and backend matrix. It distinguishes repeatable automated evidence
from physical-device or hosted-service observations. A build proves
compilation only; a local Worker emulator is not evidence of a production
deployment.

## One-command evidence entry point

From the repository root, install the pinned dependencies and run:

```sh
pnpm sync:e2e:check
```

This fast gate validates that the matrix remains connected to the required CI
workflows and package gates. The full evidence run is the `quality`,
`platform-builds`, and `sync-docker` workflow set. Their individual commands
remain runnable through the root scripts and are listed below.

## Backend parity

| Behavior | SQLite/Docker evidence | D1/Worker evidence |
| --- | --- | --- |
| Shared operation, cursor, tombstone, auth-record, and compaction contract | `pnpm sync:sqlite:check` imports the shared storage conformance suite | `pnpm sync:d1:check` imports the same suite through Miniflare |
| Authenticated HTTP push, pull, snapshot, refresh, device, and revocation | `pnpm sync:http:check` runs against SQLite | The same HTTP suite runs against a D1 Worker harness |
| Two devices edit offline, reconnect out of order, retry, and converge | The HTTP parity scenario verifies independent and same-entity fields plus duplicate delivery | The identical scenario runs through the Worker/D1 adapter |
| Restart, migration, and recovery | File-backed close/reopen, migration rollback, verified backup/restore/rollback | Migration rollback, verified logical export/restore, generation and compaction recovery |
| Personal-use resource bounds | Docker enforces 1 CPU, 512 MB memory, 100 PIDs, bounded logs, and a 16 MB temporary filesystem; the lifecycle workflow builds and inspects the image | The D1 suite records statements and rows for a representative creation plus 100-edit day and enforces at most 11 statements per adapter call |

The convergence source of truth remains the
[Personal Sync convergence contract](/dev/personal-sync-convergence). Adapter
tests may add platform checks but may not replace the shared suite.

## App and platform matrix

| Client surface | Automated evidence | What remains outside that evidence |
| --- | --- | --- |
| Android direct/store | Flutter sync engine, handoff, lifecycle, process-interruption, initial-matrix and accessibility tests; both APK flavors and native unit tests build in CI | Browser/OEM behavior, background restrictions, and accessibility on a physical device |
| Linux desktop | Flutter sync and secure loopback handoff tests; release application build in CI | End-to-end interaction with a user browser and desktop keyring on representative distributions |
| Windows desktop | Shared Flutter tests plus a Windows release build in CI | Browser association, Windows Credential Manager, and installer behavior on a physical host |
| macOS desktop | Shared Flutter tests plus a macOS release build in CI | Browser association, Keychain prompts, signing, and notarized distribution |
| iOS | Shared Dart tests plus an unsigned iOS release build on a macOS CI runner | Universal-link routing, Keychain behavior, background transitions, signing, and physical-device accessibility |
| Docker/SQLite | Hardened Compose validation and a real container lifecycle, health, replacement, backup, restore, rollback, graceful-stop, and volume-retention drill | Operator proxy/TLS configuration and host-specific resource monitoring |
| Worker/D1 | Worker bundle, TypeScript, HTTP parity, local D1 migrations, query plans, concurrency, export/restore, and query accounting | Hosted preview/production latency, billing analytics, and remote D1 Time Travel |

## Scenario ownership

| Scenario | Reproducible gate |
| --- | --- |
| Cold and warm browser handoff, callback replay, expiry, and process restart | `pnpm mobile:handoff:check` and Flutter personal-sync handoff/controller tests |
| Same-field and independent-field concurrent edits | `pnpm sync:check`, both shared adapter suites, and the two-device HTTP parity scenario |
| Local queue restart, process interruption, invalid cursor, long-offline compaction, and snapshot recovery | Flutter personal-sync engine tests plus SQLite/D1 conformance |
| Token rotation, device/all-session revocation, and replay rejection | `pnpm sync:auth:check` and the two-backend HTTP parity scenario |
| Schema upgrade and incompatible future schema | SQLite/D1 migration suites and Flutter contract/API validation tests |
| Realistic data volume and free-plan query accounting | D1 usage test and the documented Docker resource envelope |

Run the Flutter layer from `apps/habiter` with `flutter analyze` and
`flutter test`. Platform builds and the full Docker lifecycle intentionally
remain CI gates because their runner and container requirements exceed the
portable unit-test boundary.

## Unverified and blocked ledger

These gates must be recorded as unverified until somebody runs the matching
manual procedure and captures device/host, operating-system version, build,
locale, appearance, steps, and observed result:

- physical Android cold/warm external-browser return on representative OEMs;
- physical iOS universal-link return, Keychain persistence, and lifecycle
  transitions;
- signed/notarized macOS and signed iOS distribution;
- Windows browser association and credential-store prompts on a real host;
- hosted Worker/D1 preview or production latency, analytics, billing, and Time
  Travel recovery;
- operator-managed Docker reverse proxy, TLS, backup retention, and host
  resource behavior.

Absence of access, credentials, a signing identity, a physical device, or
deployment authorization is a blocked/unverified result. It never converts an
automated build or local emulator result into a pass for that gate.
