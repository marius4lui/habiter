# Habiter v1 release operations

## Version contract

The public version is SemVer and the internal Flutter build number is monotonic. `apps/habiter/pubspec.yaml`, the `vX.Y.Z` tag and the matching entry in `packages/release-core/data/releases.json` must agree.

Prepare a release by adding a newest-first manifest entry with `status: draft`, updating the Flutter version, reviewing structured notes and running:

```bash
pnpm release:validate
pnpm release:test
pnpm --filter @habiter/release-api check
```

Use the manual `Publish Habiter Release` workflow with `dry_run=true` before creating the tag. The production tag workflow builds all artifacts, verifies Android signing, calculates checksums, creates a draft GitHub Release, deploys enriched metadata and only then publishes the draft.

## GitHub configuration

Repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
```

Repository variables:

```text
ANDROID_CERT_SHA256
RELEASE_API_BASE_URL=https://get.habiter.dev
```

The Cloudflare token should be restricted to Workers Scripts edit access for the intended account. Secret values are passed through stdin to `gh secret set`; never place them in command arguments, workflow variables or the repository.

## Android signing and recovery

The v1 upload key is stored locally outside the repository under:

```text
/home/marius/.local/share/habiter/signing
```

Files are user-readable only. The public fingerprint is safe to compare, but the keystore and password files are secrets. Before publishing `v1.0.0`, create and verify a second encrypted offline backup. Losing both copies prevents compatible Android upgrades; rotating the GitHub secret does not rotate the certificate.

To rotate GitHub's stored copy without changing the certificate, re-upload the same local keystore and credentials, then run the dry-run workflow. A new certificate is a separate migration and must not be substituted silently.

## Worker deployment and rollback

Production Worker code deploys only from relevant changes on `main`. Pull requests from the same repository receive isolated workers named `habiter-release-api-pr-<number>` and a reusable preview comment. Closing the pull request deletes that preview worker.

The checked-in release manifest remains authoritative. Production data includes only `published` entries; previews may expose draft entries with preview-only runtime metadata.

Inspect and roll back deployments from `apps/release-api`:

```bash
pnpm exec wrangler versions list --env production
pnpm exec wrangler rollback --env production
```

After configuring the custom domain, set `RELEASE_API_BASE_URL` so deployment and release workflows smoke-test `/health` and the release routes on `get.habiter.dev`.

## Manual gates

The following remain blockers for a public `v1.0.0` release:

- Create and verify an encrypted offline Android-keystore backup.
- Attach and verify `get.habiter.dev` in Cloudflare and set `RELEASE_API_BASE_URL`.
- Exercise Android reminders, notification actions and App Lock on physical hardware.
- Confirm the unsigned status and user guidance for Windows and macOS downloads.
- Complete the OAuth and import/export scenarios from the release-candidate checklist.

The current Flutter build reports a future Kotlin Gradle Plugin migration warning. It does not invalidate v1, but it must be resolved before upgrading to a Flutter release that removes KGP compatibility.

## Legacy cleanup

The old `v1.3` and `v1.3.3` tags and the `v1.3.3` GitHub Release belong to the superseded product line. Remove them only after all local checks, the manual dry run and signing verification pass. Commit history is retained even when the public tags and release are deleted.
