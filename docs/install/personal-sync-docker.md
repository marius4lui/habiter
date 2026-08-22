# Personal Sync Docker Compose Beta

Habiter Personal Sync is available as a **Beta** self-hosting stack for Docker Compose. One application container serves the versioned HTTP API and stores the single-account database in embedded SQLite. It requires no external database, cache, identity provider, analytics service, or other runtime dependency.

Beta means the data and authentication contracts are tested, but operators should expect manual updates and keep verified backups before every change. This child does not publish an image or deploy a service.

## Prerequisites and boundaries

Use a current Docker Engine with the Compose v2 plugin. Budget at least one CPU, 512 MiB memory, 100 process IDs, and enough persistent storage for the SQLite database plus retained backups. Small personal instances normally use far less; monitor actual usage before lowering limits.

The Compose file publishes port 8787 on `127.0.0.1` by default. Keep that loopback binding and put a maintained reverse proxy in front of it. Public exposure requires:

- an HTTPS-only public URL with a valid certificate;
- HSTS at the proxy and on the application response;
- request-body and connection limits at least as strict as the service limits;
- WebSocket upgrades disabled because the API does not use them;
- client IP forwarding headers overwritten, not appended from untrusted clients;
- the application port blocked from external networks;
- proxy logs that omit authorization headers, request bodies, query strings, and cookies.

The service does not trust `Host`, `Forwarded`, or `X-Forwarded-*` when constructing redirects. It uses the exact `HABITER_SYNC_BASE_URL` and exact redirect allowlist configured by the operator. This removes proxy-header ambiguity but makes correct configuration mandatory.

## Prepare the Beta stack

From a trusted checkout, create the local environment file:

```sh
cd deploy/personal-sync
cp .env.example .env
chmod 600 .env
```

Edit `.env` and set:

- `HABITER_SYNC_BASE_URL` to the final public HTTPS origin;
- `HABITER_SYNC_REDIRECT_URIS` to a comma-separated list of exact HTTPS callbacks;
- `HABITER_SYNC_CORS_ORIGINS` only when a trusted browser client needs cross-origin API access;
- the display name and host port if needed.

Do not put a password, derived password key, refresh token, or instance encryption key in `.env`. The service creates a random 256-bit instance key directly in the private data volume with mode `0600`.

Validate and build the pinned Node 24 image:

```sh
docker compose config --quiet
docker compose build --pull
```

The runtime image is labeled Beta, runs as `node:node`, drops every Linux capability, sets `no-new-privileges`, uses a read-only root filesystem and bounded temporary filesystem, and contains only Node plus the bundled service program. The Node base image is pinned by tag and multi-platform digest. Rebuilding is reproducible for a fixed checkout, lockfile, platform, and base digest.

## Fresh start

Start the uninitialized service:

```sh
docker compose up -d --wait
docker compose exec sync node /app/service.mjs health
curl --fail --silent http://127.0.0.1:8787/v1/instance-info
```

A fresh volume contains schema and instance metadata but no account and no default credential. `instance-info` reports `initialized: false`. The service does not listen until all contiguous SQLite migrations complete. A migration failure rolls back its exclusive transaction, exits non-zero, remains visible in `docker compose logs sync`, and leaves the prior database usable by the prior image.

## Create the one account

Interactive setup hides password input and asks for confirmation:

```sh
docker compose run --rm sync setup
```

For automation, pass the password only through an already protected standard-input channel:

```sh
secret_command_that_writes_one_password |
  docker compose run --rm -T sync setup --username owner --password-stdin
```

Never put the password in a command argument, environment variable, Compose file, shell history, process substitution, or log. The CLI explicitly rejects `--password`. Avoid `printf 'literal-password'` outside disposable tests because the literal becomes shell history or process metadata. The non-interactive producer should read from a secret manager or protected file descriptor and write exactly one line.

The CLI derives the password key inside the one-shot container, sends no plaintext over HTTP, and persists only the wrapped verifier defined by the authentication contract. A second setup attempt fails; there is no registration route.

## Health, readiness, and shutdown

Compose checks `GET /v1/health` inside the container. Readiness is equivalent to the service listening after the migration gate. For monitoring, alert on:

- unhealthy or restarting container state;
- non-200 health responses;
- repeated `startup_failed` or unexpected 5xx request events;
- data-volume exhaustion, backup age, and backup verification failures;
- CPU throttling or memory pressure near the configured limits.

Application logs are one-line JSON with bounded request ID, method, path without query, status, and duration. Docker rotates them at 10 MiB with three files. The logger never receives headers, bodies, usernames, codes, or tokens. Restrict Docker-daemon and log-file access because infrastructure metadata can still be sensitive.

Docker sends `SIGTERM`; the service stops accepting new work, drains active requests, closes SQLite, and exits before the 30-second Compose grace period. Validate before maintenance:

```sh
docker compose stop --timeout 30 sync
docker compose ps -a
```

An exit code of zero is the expected graceful result.

## Backup and verify

Create an online SQLite backup while the service runs:

```sh
docker compose exec sync backup pre-update.sqlite
docker compose exec sync verify pre-update.sqlite
```

`backup` uses SQLite's online backup API, then runs `PRAGMA integrity_check` and records schema version, stream generation, head cursor, size, and SHA-256 in `pre-update.sqlite.json`. Ordinary copying of the live `sync.sqlite` file is unsafe while WAL mode is active.

The named backup volume survives container replacement and normal `docker compose down`, but it is not an off-host backup. Copy both files to encrypted operator storage and verify the recorded checksum there:

```sh
docker compose cp sync:/var/lib/habiter-sync-backups/pre-update.sqlite ./pre-update.sqlite
docker compose cp sync:/var/lib/habiter-sync-backups/pre-update.sqlite.json ./pre-update.sqlite.json
sha256sum ./pre-update.sqlite
```

Keep multiple generations under a retention policy and test restore regularly. Anyone with a database backup and the instance key from the data volume can impersonate the account; protect both like credentials and never place them in a public artifact.

## Restore and data rollback

Restore only while the main service is stopped:

```sh
docker compose stop --timeout 30 sync
docker compose run --rm -T sync restore pre-update.sqlite EXPECTED_SHA256
```

The restore command verifies the source and a temporary copy before atomically replacing the destination. It prints a rollback filename such as `sync.sqlite.rollback-1787390000000`. Keep that exact name until the restored service passes health, login, push, and pull smoke tests:

```sh
docker compose up -d --wait
docker compose exec sync node /app/service.mjs health
```

If verification fails, stop the service and switch back:

```sh
docker compose stop --timeout 30 sync
docker compose run --rm -T sync rollback sync.sqlite.rollback-1787390000000
docker compose up -d --wait
```

Rollback verifies the saved database before replacement and restores the current file if switching fails.

## Update and image rollback

Before every Beta update:

1. Create, verify, and copy out a backup.
2. Record the current Git revision and image ID.
3. Review migration and security notes.
4. Build the intended revision with `docker compose build --pull`.
5. Run `docker compose up -d --force-recreate --wait`.
6. Verify health, account initialization, login, push, pull, restart, and logs.

If the new image fails before migration, return to the recorded checkout/image and recreate the container. If it migrated successfully but the application smoke test fails, stop it, restore the verified pre-update backup, then recreate the prior image. Never run an older image against a database schema it reports as newer than supported.

## Restart and replacement safety

The `habiter-personal-sync-data` and `habiter-personal-sync-backups` named volumes are independent of the container. Confirm replacement durability:

```sh
docker compose restart sync
docker compose up -d --force-recreate --wait
curl --fail --silent http://127.0.0.1:8787/v1/instance-info
```

The initialized state must remain true. Do not bind-mount the database onto network filesystems that cannot provide normal SQLite locking and atomic rename semantics.

## Uninstall

The recoverable default removes containers and networks but preserves both named volumes:

```sh
docker compose down
docker volume inspect habiter-personal-sync-data
docker volume inspect habiter-personal-sync-backups
```

Only after an off-host backup is verified and permanent deletion is explicitly intended, remove the volumes:

```sh
docker compose down --volumes
```

Volume deletion removes the database, wrapped verifier, sessions, instance key, and in-volume backups and is not recoverable from Docker. Confirm the exact project and volume names before running it.

## Validation evidence

Run daemon-independent checks locally:

```sh
pnpm sync:sqlite:check
pnpm sync:service:check
pnpm sync:docker:check
```

The service suite executes migration, credential-safe setup, file permissions, health, graceful shutdown, backup verification, restore, rollback, and tamper rejection against temporary local paths. The Docker Beta workflow additionally builds and inspects the real image, starts the hardened Compose service, confirms no default account, performs setup, replaces the container, exercises both named volumes and the full backup lifecycle, confirms graceful exit, and verifies that ordinary uninstall preserves data.
