# Habiter v1 release operations

## Version contract

The public version is SemVer and the internal Flutter build number is monotonic. `apps/habiter/pubspec.yaml`, the `vX.Y.Z` tag and the matching entry in `packages/release-core/data/releases.json` must agree. Every manifest entry explicitly selects either the `stable` or `beta` channel.

Prepare a release by adding a newest-first manifest entry with `status: draft`, updating the Flutter version, reviewing structured notes and running:

```bash
pnpm release:validate
pnpm release:test
pnpm --filter @habiter/release-api check
```

Use the manual `Publish Habiter Release` workflow with `dry_run=true` before creating the tag. The production tag workflow builds all artifacts, verifies Android signing, calculates checksums, creates a draft GitHub Release, deploys enriched metadata and only then publishes the draft. Stable releases become normal GitHub Releases and may become `latest`; beta releases become GitHub prereleases and never replace the latest stable release.

After the API smoke tests pass, the workflow finalizes the matching manifest entry with the verified publication timestamp, download URLs, sizes and SHA-256 hashes on `main`. This persistence step must succeed before the draft is made public, so later Worker deployments cannot silently drop an already published release.

The Release API defaults to `stable`. Beta clients opt in explicitly with `?channel=beta` on list, latest, update and download routes. Unknown channel values are rejected instead of being treated as an empty channel.

## GitHub configuration

Repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
RELEASE_MANIFEST_PRIVATE_KEY_BASE64
```

Repository variables:

```text
ANDROID_CERT_SHA256
HABITER_UPDATE_PUBLIC_KEYS
RELEASE_API_BASE_URL=https://get.habiter.dev
RELEASE_MANIFEST_KEY_ID
```

The Cloudflare token should be restricted to Workers Scripts edit access for the intended account. Secret values are passed through stdin to `gh secret set`; never place them in command arguments, workflow variables or the repository.

`RELEASE_MANIFEST_PRIVATE_KEY_BASE64` is the Base64-encoded PKCS#8 PEM for an Ed25519 private key. It exists only as a GitHub environment secret and must never be committed, printed by CI, embedded in an application build or copied into Cloudflare runtime configuration. `RELEASE_MANIFEST_KEY_ID` is a stable identifier such as `release-2026-01`. `HABITER_UPDATE_PUBLIC_KEYS` is a JSON object from key ID to the unpadded Base64URL encoding of the 32-byte raw Ed25519 public key, for example `{"release-2026-01":"<public-key>"}`. Release builds fail if the active signing key is absent from that ring.

Generate signing material on a trusted offline workstation, back up the private key encrypted, and inject only the encoded private PEM into the GitHub production environment. Keep the current and next public key in the client for an overlap release before rotating the server key. Remove an old public key only after every supported client trusts the replacement. Preview deployments deliberately use a throwaway key and cannot be trusted by production clients.

## Android signing and recovery

The v1 upload key is stored locally outside the repository under:

```text
/home/marius/.local/share/habiter/signing
```

Files are user-readable only. The public fingerprint is safe to compare, but the keystore and password files are secrets. Before publishing `v1.0.0`, create and verify a second encrypted offline backup. Losing both copies prevents compatible Android upgrades; rotating the GitHub secret does not rotate the certificate.

To rotate GitHub's stored copy without changing the certificate, re-upload the same local keystore and credentials, then run the dry-run workflow. A new certificate is a separate migration and must not be substituted silently.

## Worker deployment and rollback

Production Worker code deploys only from relevant changes on `main`. Pull requests from the same repository upload native Cloudflare preview versions to the shared `habiter-release-api-preview` Worker. Each pull request receives a stable `pr-<number>` preview alias and a reusable preview comment; preview uploads never promote a version to an active deployment.

The checked-in release manifest remains authoritative. Production data includes only `published` entries; previews may expose draft entries with preview-only runtime metadata. Do not manually mark a candidate as published before its tag workflow succeeds; the workflow owns that transition.

Inspect and roll back deployments from `apps/release-api`:

```bash
pnpm exec wrangler versions list --env production
pnpm exec wrangler rollback --env production
```

After configuring the custom domain, set `RELEASE_API_BASE_URL` so deployment and release workflows smoke-test `/health` and the release routes on `get.habiter.dev`.

## Automatic-update release assets

Android is built in two flavors with the same application ID. `direct` produces a signed universal APK with the installer permission and FileProvider; `store` produces an AAB without either direct-install capability. The release workflow verifies both artifacts against `ANDROID_CERT_SHA256`. The build flavor is authoritative, while the detected Android install source is an additional safeguard: a Store-installed build never receives a direct APK.

Optional story images belong in `packages/release-core/media/<version>/` and must be declared by file name, MIME type and ID in the matching draft. The publish job copies them beside the platform artifacts, calculates size and SHA-256, adds their immutable GitHub Release URLs to the runtime manifest and signs those exact manifest bytes. Missing or corrupt client-side media falls back to the declared icon without affecting the update itself.

Habiter 1.5.0 is the bootstrap release for this updater. Clients older than 1.5 must install it once through the existing download page, GitHub Release or store flow. Automatic checks and direct downloads begin only after 1.5 is running. Publish 1.5 first as Preview/RC; promote it to Stable only after the physical-device matrix below succeeds.

## Manual gates

The following manual checks remain part of the stable-release checklist:

- Create and verify an encrypted offline Android-keystore backup.
- Attach and verify `get.habiter.dev` in Cloudflare and set `RELEASE_API_BASE_URL`.
- Exercise Android reminders, notification actions and App Lock on physical hardware.
- Confirm the unsigned status and user guidance for Windows and macOS downloads.
- Complete the OAuth and import/export scenarios from the release-candidate checklist.
- Install 1.5 manually over the latest pre-1.5 direct APK, then install a newer RC through the in-app flow and confirm signer continuity.
- Verify Direct and Store routing, Wi-Fi and metered downloads, denied unknown-app permission, interrupted download/process restart, offline expired mandatory deadline and the single ready notification on physical Android devices.

The current Flutter build reports a future Kotlin Gradle Plugin migration warning. It does not invalidate v1, but it must be resolved before upgrading to a Flutter release that removes KGP compatibility.

## Website deployment on Cloudflare Workers

The website is exported by Next.js as static files and deployed as Cloudflare Worker assets. No OpenNext server bundle is involved. The Cloudflare Workers Build for `habiter` uses:

```text
Root directory: /apps/website
Build command: pnpm build
Deploy command: pnpm exec wrangler deploy
Production branch: main
```

`apps/website/wrangler.jsonc` owns the Worker name and points at the generated `out` directory. `pnpm website:check` validates the website contract, creates the static export and performs a Wrangler dry run locally and in CI.

For a manual deployment from the repository root, run:

```bash
pnpm --filter @habiter/website build
pnpm --dir apps/website exec wrangler deploy
```

## Documentation deployment on GitHub Pages

VitePress is deployed independently from the product website to `docs.habiter.dev`. The `Deploy Documentation` workflow builds `docs/.vitepress/dist` and publishes it with GitHub Pages. The site uses the custom-domain root (`base: '/'`); changing it to a repository subpath breaks CSS, JavaScript, images, and navigation.

Deployments run for documentation changes merged to `main` and can be started manually with:

```bash
gh workflow run docs-deploy.yml --ref main
gh run watch --exit-status
```

The committed `docs/public/CNAME` preserves the custom domain in every artifact. Keep Pages in GitHub Actions mode and enforce HTTPS after DNS and certificate validation succeed.

## Legacy cleanup

The old `v1.3` and `v1.3.3` tags and the `v1.3.3` GitHub Release belong to the superseded product line. Remove them only after all local checks, the manual dry run and signing verification pass. Commit history is retained even when the public tags and release are deleted.
