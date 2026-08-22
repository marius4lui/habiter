# Personal Sync Beta

Personal Sync is an **optional, self-hosted Beta** for one account and one private data space. Habiter does not host your instance or offer a hosted fallback. Core habit tracking remains local-first, works without an account, and continues when the sync server is unavailable.

Sync is not a backup: deletion and lifecycle operations also converge between devices. Keep independent, tested backups of the server and local exports.

## Choose and operate a server

You operate one of two compatible targets:

- [Docker with SQLite](/install/personal-sync-docker) for a server or NAS you control. The guide covers requirements, installation, HTTPS reverse proxying, setup, upgrades, migrations, backup, restore, rollback, and uninstall.
- [Cloudflare Worker with D1](/install/personal-sync-worker) for an operator-managed Worker and database. The guide covers prerequisites, creation, migrations, secrets, deployment, updates, backup, restore, usage inspection, and free-plan limits.

Both targets implement the same [versioned HTTP protocol](/api/personal-sync-http). The operator owns availability, security, costs, backups, restores, upgrades, and the data stored by the selected provider.

## Data boundaries

| Category | Personal Sync | Device only / never synchronized |
| --- | --- | --- |
| Habits | identity, name, icon, color, schedule, ordering, pause/archive lifecycle | transient editor and navigation state |
| Entries | completion identity, date, value, lifecycle metadata | temporary animations and undo presentation |
| Preferences | explicitly allow-listed non-secret product preferences | device presentation and OS-specific settings |
| Reminders | stable product intent where allow-listed | notification IDs, delivery history, calibration, learned timing, permissions |
| Integrations | non-secret enablement only when explicitly allow-listed | passwords, access/refresh tokens, API keys, PKCE verifier, recovery artifacts |
| Platform features | no App Lock or widget runtime state | App Lock grants/state, widget snapshots, downloads, caches, diagnostics |

The detailed allowlist and compatibility rules live in the [data contract](/dev/personal-sync-data-contract). Credentials stay in platform-secure storage where available and are never written to the synchronization log.

## Connect a device

1. Deploy a supported server and confirm its HTTPS health and capability endpoints.
2. In Habiter, open **Settings → Data & privacy → Personal Sync**.
3. Enter the exact HTTPS server URL and choose **Connect**.
4. Habiter opens the system browser. Confirm the server origin, sign in, and return through the validated app link or loopback callback.
5. Confirm the device name and review the initial-sync choice if both sides already contain data.

Android and iOS use an allow-listed app link. Desktop uses a bounded loopback callback. Web requires an exact configured HTTPS redirect origin. The browser page is served by your instance; Habiter exchanges a one-time authorization code with PKCE and never receives the account password. The [handoff contract](/dev/mobile-sync-handoff) documents validation and failure recovery.

If the callback does not return, leave the browser open, switch back to Habiter, and retry. Codes expire quickly and cannot be replayed. Never paste a code, token, or password into a support request.

## Automatic synchronization

Habiter records allowed changes locally first, then uploads them in bounded batches. It pulls remote operations on connection, app start or resume, local edits, a short foreground polling interval, and network recovery. Debouncing, retry backoff, and durable cursors prevent tight loops and preserve work across crashes.

Automatic sync is not a real-time guarantee. Mobile operating systems can suspend background work; browser tabs can be throttled; offline devices cannot receive remote changes. Foreground or resume reconciliation is the dependable catch-up path. The status screen shows pending work, last success, current failure class, and a retry action.

## Initial merge and conflicts

The first connection follows a deterministic matrix:

- local data only: upload it;
- server data only: download it;
- neither side: start empty;
- both sides populated: require an explicit merge or replace choice.

Merge preserves identities and applies the same deterministic convergence rules used later. Concurrent edits resolve per field; deletion and lifecycle markers prevent stale devices from silently restoring removed state. Replacement first writes an atomic local recovery artifact, validates the authenticated server snapshot, then replaces local synchronized data. A compacted or invalid cursor also uses a validated snapshot while preserving unsent local operations.

Review [convergence and recovery](/dev/personal-sync-convergence) before changing protocol or storage behavior.

## Devices, sessions, and account actions

Each connected device has a separately revocable refresh session. **Disconnect this device** removes its local credentials and revokes that session; already imported data remains local. For a lost device, use another authenticated device or the operator recovery path to revoke all sessions, then reconnect trusted devices.

Changing the account password invalidates durable refresh sessions. **Revoke all devices** does the same immediately. An access token already issued before revocation can remain valid for its short configured lifetime (five minutes by default), so secure the server and rotate exposed instance secrets when compromise is suspected.

## Troubleshooting

| Symptom | Check | Safe next action |
| --- | --- | --- |
| Server cannot be reached | HTTPS certificate, DNS, reverse proxy, `/v1/health` | Restore transport; local tracking remains available |
| Login returns to the wrong place | exact redirect allowlist and platform app-link/loopback setup | Cancel and begin a fresh browser login |
| Login expired or state mismatch | device clock, reused tab/code, callback URL | Close the flow and retry; do not reuse codes |
| Authorization repeatedly fails | configured account, password, server logs without secrets | Reset through the documented operator procedure |
| Changes remain pending | connection, server capacity, status failure class | Keep the app open briefly and use **Retry** |
| Snapshot recovery appears | invalid/compacted cursor or restored server | Let validation finish; retain the recovery artifact |
| Devices disagree | both devices reached the same origin and completed catch-up | Foreground both clients; inspect pending/error status |
| Worker limit or storage error | Cloudflare analytics, D1 size and request limits | Reduce load or move to an appropriate paid/alternate target |

Server-specific diagnostics and lifecycle commands are in the Docker and Worker guides. Logs must not contain passwords, authorization headers, token material, operation bodies, or habit content.

## Security hardening

- Serve only through HTTPS; keep the origin, proxy, Worker, database, and host patched.
- Use a long unique password, high-entropy instance encryption key, and exact redirect/CORS allowlists.
- Keep secrets outside source control and ordinary environment dumps; rotate them after exposure.
- Restrict administrative access and database/backups to the operator account.
- Monitor health, storage, request volume, authentication failures, and backup completion without logging private content.
- Schedule encrypted backups and regularly test restore and rollback on an isolated instance.
- Review provider retention, jurisdiction, availability, and pricing before storing personal data.

## Beta limits, compatibility, and rollback

Personal Sync is an operator-managed Beta. It supports a single private account/data space, not teams, sharing, public registration, managed recovery, or service-level guarantees. Availability and free-plan capacity depend on the deployment target. Background execution and conflict presentation remain platform-constrained.

Clients negotiate protocol capabilities and reject unsupported breaking versions. Additive fields are ignored only where the [protocol contract](/api/personal-sync-http) permits it. Back up before server or client upgrades and follow the target-specific migration steps. During a rollback, restore a compatible database backup and use clients that support that protocol version; do not downgrade schemas in place.

To disable sync, disconnect every device, verify/export local data, revoke sessions, take a final server backup, and then follow the target's uninstall procedure. Disabling sync does not delete local habits. Server deletion is an explicit operator action and cannot be recovered without a valid backup.

Future versions may change Beta storage or protocol details through documented migrations. There is no promise of a future Habiter-operated service, automatic provider migration, or unlimited free operation.

## Developer and protocol references

The implementation contract is split into focused, internally linked references:

- [HTTP routes, limits, errors, and compatibility](/api/personal-sync-http)
- [Synchronized data allowlist and migration rules](/dev/personal-sync-data-contract)
- [Deterministic convergence and recovery](/dev/personal-sync-convergence)
- [Authentication, PKCE, refresh, and revocation](/dev/personal-sync-auth)
- [SQLite schema, migrations, backups, and conformance](/dev/personal-sync-sqlite)
- [D1 schema, migrations, query accounting, and conformance](/dev/personal-sync-d1)
- [Mobile and desktop browser handoff](/dev/mobile-sync-handoff)
- [Cross-runtime end-to-end evidence and unverified gates](/dev/personal-sync-e2e)
