# Personal Sync Cloudflare Worker/D1 Beta

Habiter Personal Sync has a source-available **Beta** target for Cloudflare Workers and D1. It runs the same authentication, HTTP, convergence, and storage contracts as the Docker target while using one Worker, one D1 database, Worker secrets, and no paid or external storage service.

This is an operator-managed Beta: the repository supplies local development, migrations, setup, checks, export/import, Time Travel, and deployment dry runs. Repository validation performs no production deployment.

## Current Free-plan envelope

The checked-in configuration caps HTTP CPU at 10 ms. As of August 2026, Cloudflare documents these relevant Workers Free limits:

| Resource | Free allowance or limit |
| --- | ---: |
| Worker requests | 100,000/day |
| HTTP CPU | 10 ms/request |
| Worker memory | 128 MB |
| D1 queries per invocation | 50 |
| D1 rows read | 5,000,000/day |
| D1 rows written | 100,000/day |
| D1 database size | 500 MB/database |
| D1 databases | 10/account |
| D1 total storage | 5 GB/account |
| D1 Time Travel | 7 days |

Sources: [Workers limits](https://developers.cloudflare.com/workers/platform/limits/), [D1 limits](https://developers.cloudflare.com/d1/platform/limits/), and [D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/). Limits can change; check the linked primary documentation before provisioning or updating.

The representative adapter test creates one habit, performs 100 edits, and pulls 500 operations. It records 1,112 rows read and 910 rows written, respectively 0.023% and 0.91% of the current daily D1 allowances, with no call exceeding 11 D1 statements. This is deterministic local accounting from D1 result metadata, not a billing guarantee. Authentication, retries, multiple devices, exports, and other Workers in the account add usage.

The Worker writes one sanitized `d1_usage` event per request with statement, row-read, and row-write counts. Monitor those logs plus the D1 dashboard/analytics, Worker CPU, request counts, exceptions, and database size. Cloudflare stops D1 queries after Free daily row limits are exhausted; the service then fails closed rather than serving stale or unauthenticated data.

## Prerequisites and source preparation

Work from a trusted checkout:

```sh
pnpm install --frozen-lockfile
cd apps/sync-worker
```

The committed `wrangler.jsonc` contains safe placeholder URLs and a placeholder D1 ID only. It contains no password, account verifier, API token, instance key, setup token, or long-lived plaintext credential. Wrangler authentication remains in the operator's normal protected Cloudflare configuration.

Create a D1 database and copy its returned ID and name into `wrangler.jsonc`:

```sh
pnpm exec wrangler d1 create habiter-personal-sync-beta
```

Replace `BASE_URL` with the exact public HTTPS origin and `REDIRECT_URIS` with exact HTTPS callbacks. Configure `CORS_ORIGINS` only for trusted browser origins. Do not use wildcard redirects or CORS.

## Local development

Generate local-only instance/setup secrets without printing them, apply the versioned migrations, and start Wrangler:

```sh
pnpm dev:prepare
pnpm dev:migrate
pnpm dev
```

`.dev.vars`, `.wrangler/`, exports, and generated temporary bundles are ignored. `.dev.vars` is created with mode `0600` and is never overwritten implicitly. Remove it when the local instance is discarded.

In another terminal, pipe one password to the setup client. The client derives PBKDF2 locally and sends only the derived key through loopback:

```sh
protected_password_producer |
  pnpm setup -- --local --url http://127.0.0.1:8787 --username owner --password-stdin
```

The local setup token is read directly from `.dev.vars`, never printed or passed as an argument. The Worker accepts setup only with the one-time token, an exact configured origin, JSON content type, bounded body, and an uninitialized database.

## Checks and deployment dry run

Run the complete Worker gate:

```sh
pnpm check
```

It performs TypeScript checking, verifies Worker migrations byte-for-byte against the shared D1 adapter, applies them to an isolated local Wrangler database, runs Miniflare binding/schema/setup tests, checks generated Worker types, and bundles a deployment dry run. The upload is approximately 100 KiB uncompressed and remains well below the current Worker Free script limit.

Individual scriptable gates are also available:

```sh
pnpm check:migrations
pnpm types:check
pnpm deploy:dry
```

`deploy:dry` uploads nothing and changes no Cloudflare state.

## Configure the durable instance secret

The 256-bit instance key wraps the stored password verifier and signs access tokens. It must remain stable for the lifetime of the database. The recommended workflow creates it in an operator secret manager first, then streams its canonical 32-byte base64url value directly to Wrangler:

```sh
protected_instance_key_producer |
  pnpm secret:instance -- --key-stdin
```

Without `--key-stdin`, the command generates an ephemeral random key and sends it directly to `wrangler secret put` without printing it. That is convenient, but it leaves no operator recovery copy. D1 export and Time Travel do not include Worker secrets; losing the instance key makes the wrapped verifier unusable. Never commit the key or place it in Wrangler vars, shell history, command arguments, CI output, or an unencrypted file.

## Remote migration, deployment, and setup

Review migrations and take a bookmark/export before applying them. Then run:

```sh
pnpm migrate:remote
pnpm deploy:dry
```

Only an operator explicitly choosing a production change should run `pnpm exec wrangler deploy`; this implementation does not run it.

After the first real deployment, initialize exactly one account:

```sh
protected_password_producer |
  pnpm setup -- --url https://sync.example.com --username owner --password-stdin
```

For remote setup the client generates a random one-time token, streams it to `wrangler secret put`, derives the password key locally, calls the HTTPS setup route, and deletes the setup-token secret in a `finally` block. It never prints the password, derived key, or token. If deletion reports a failure, immediately run:

```sh
pnpm exec wrangler secret delete HABITER_SYNC_SETUP_TOKEN
```

A second setup fails. There is no registration endpoint.

## Fail-closed runtime

Every request opens the D1 adapter with implicit migrations disabled. A missing `DB` binding, absent/partial/newer schema, invalid base origin, missing/invalid instance key, or storage exception returns a bounded 503 response. The Worker does not fall back to in-memory state or unauthenticated operation.

For a security-critical custom route, configure Cloudflare's route behavior to **fail closed** when the Workers Free daily request limit is exhausted. Fail-open would bypass the authentication service and is inappropriate.

The setup route is separate from `/v1`, requires its temporary Worker secret, and returns no account details. Normal HTTP behavior and security headers are shared with the SQLite distribution.

## Export and verified fixture restore

Create local or remote SQL exports:

```sh
pnpm backup:local
pnpm backup:remote
```

The commands create `backups/local.sql` or `backups/remote.sql`, replacing an older same-name local file. The directory is ignored. Move remote exports immediately to encrypted operator storage, calculate a SHA-256 checksum, and retain the matching Git revision, migration list, database ID, and timestamp. Cloudflare documents the `wrangler d1 export` and `d1 execute --file` flow in its [import/export guide](https://developers.cloudflare.com/d1/best-practices/import-export-data/).

Import an export only into a newly created, empty D1 database. Put that new database ID in a review copy of `wrangler.jsonc`, then run:

```sh
pnpm restore:remote
pnpm deploy:dry
```

Do not import over the active database. Verify schema version, instance info, authentication, push, pull, and usage against the restored target before changing the deployed binding. Keep the old D1 database untouched as the rollback target. The shared D1 suite separately exercises a checksum-protected logical fixture restore into an empty local binding and compares the restored snapshot.

## Time Travel and rollback

Cloudflare Time Travel is automatically enabled on production-backend D1 databases and currently retains seven days on Workers Free. Before migration or a destructive operation, record the current bookmark:

```sh
pnpm bookmark:remote > protected-bookmark.json
```

Time Travel restore overwrites the active database and cancels in-flight queries. It is a destructive operator action, never an automatic update step. After confirming the exact database and bookmark:

```sh
pnpm rollback:remote -- --bookmark=EXACT_BOOKMARK
```

Record the undo bookmark returned by the restore. Cloudflare documents that restoring does not remove older bookmarks and the returned prior bookmark can undo the operation. See [Time Travel and backups](https://developers.cloudflare.com/d1/reference/time-travel/) and the [Wrangler command reference](https://developers.cloudflare.com/d1/wrangler-commands/).

For a code-only regression with a compatible schema, use Wrangler's version rollback or redeploy the recorded prior Git revision. Never run older code against a schema it does not support; the adapter rejects newer schema versions.

## Update checklist

1. Review current Cloudflare limits and release notes.
2. Run the full local Worker and shared D1 conformance gates.
3. Create an encrypted SQL export and record a Time Travel bookmark.
4. Record current Worker version, Git revision, D1 database ID, and schema.
5. Run migration and deployment dry runs.
6. Apply reviewed remote migrations.
7. Deploy only with explicit operator intent.
8. Smoke-test health, instance info, login, token rotation, push/pull, revocation, usage, and error logs.
9. Roll code back only when schema-compatible; otherwise use the recorded export/new binding or Time Travel bookmark.

No step publishes repository credentials or requires R2, KV, an external database, or a paid Cloudflare product.
