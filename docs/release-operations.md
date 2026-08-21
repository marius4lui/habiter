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

The [Release API reference](/api/release-api) is the HTTP contract. The [manifest and signature reference](/api/release-manifest) defines schemas, publication invariants, client verification, and key rotation.

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

Keep the v1 upload key in an operator-managed encrypted directory outside every repository checkout, synced folder, and routine backup that is not explicitly approved for signing material. Do not document a contributor-specific path: each release operator must record the location in their private runbook.

The public fingerprint is safe to compare, but the keystore and password files are secrets. Maintain and periodically verify a second encrypted offline backup. Losing both copies prevents compatible Android upgrades; rotating the GitHub secret does not rotate the certificate.

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

## Desktop installer and uninstaller delivery and rollback

The only script source files are `scripts/install/install.sh`, `scripts/install/install.ps1`, `scripts/install/uninstall.sh`, and `scripts/install/uninstall.ps1`. The deployment workflow bundles their exact repository contents into the Worker, so the four exact endpoints `/install.sh`, `/install.ps1`, `/uninstall.sh`, and `/uninstall.ps1` have no runtime dependency on GitHub Raw and expose no generic path or upstream URL parameter. Successful responses use content-derived ETags, explicit text MIME types, `nosniff`, the repository-source marker, and `public, max-age=60, s-maxage=300`. Missing or malformed bundled content fails closed as non-executable plain text with `no-store`; changes to any canonical script trigger a Worker deployment.

Installers write `.habiter-install.json` only after payload activation and configured integration succeed. Schema version 1 contains:

| Field | Contract |
| --- | --- |
| `schemaVersion` | Exactly `1`; unknown versions fail closed. |
| `product` / `applicationId` | Exactly `habiter` and `dev.habiter.Habiter`. |
| `installId` / `version` / `scope` | Non-empty install correlation, SemVer, and `user` or `system`. |
| `canonicalInstallRoot` / `executable` | Canonical literal root and exact platform executable below that root. |
| `integrationPaths` | Only installer-created wrapper, desktop, command, or shortcut paths allowed for that platform. |
| `pathEntry` / `pathEntryAddedByInstaller` | Windows command directory and whether this install appended that exact user-PATH component; POSIX uses `null` and `false`. |

Linux and Windows keep the manifest at the installation root. macOS keeps it inside `Habiter.app`. The manifest is evidence, never a deletion instruction: uninstallers recanonicalize every value, reject broad roots and link/reparse escapes, verify executable/bundle identity and each integration target, and preserve mismatches. Pre-manifest installs require multiple matching legacy signals and an additional warning.

Installers never derive release file names. They call `/api/v1/install/<platform>/<architecture>` with stable/beta, optional version, and Linux distro. The resolver selects exactly one artifact marked `primary: true` with an explicit `format`, HTTPS URL, SHA-256, and size. Ambiguity or incomplete metadata is a 404, not array-order fallback. A macOS `universal` artifact may satisfy an `arm64` or `x64` request. Linux browser requests without an explicit distro go to the chooser because a browser cannot reliably identify Fedora, Arch, Ubuntu, Debian, or openSUSE.

The stable tag workflow blocks publication until installer/uninstaller script and API tests pass and at least three complete primary desktop artifacts exist. Linux publishes both the primary AppImage and the complete Flutter tar bundle. Windows and macOS archives retain the complete application bundle. `.github/workflows/installer.yml` separately checks ShellCheck/syntax, deterministic distro fixtures and containers, POSIX discovery/lifecycle on Linux and macOS, Windows PowerShell 5 and pwsh discovery/lifecycle, manifest/install compatibility, resolver/endpoint behavior, generated-bundle drift, release metadata, documentation links, and the VitePress build. All lifecycle tests use injected temporary roots and never inspect or mutate runner home, PATH, Start Menu, `/Applications`, `/opt`, `/usr/local`, or `Program Files`.

Smoke test a Worker preview or production endpoint without executing a script:

```bash
curl --fail --dump-header - https://get.habiter.dev/install.sh --output /tmp/habiter-install.sh
curl --fail --dump-header - https://get.habiter.dev/uninstall.sh --output /tmp/habiter-uninstall.sh
head -n 1 /tmp/habiter-install.sh
sh -n /tmp/habiter-install.sh
sh -n /tmp/habiter-uninstall.sh
curl --fail --dump-header - https://get.habiter.dev/uninstall.ps1 --output /tmp/habiter-uninstall.ps1
head -n 1 /tmp/habiter-uninstall.ps1
curl --fail 'https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=fedora' | jq .
curl --head 'https://get-the.habiter.dev/?platform=linux&distro=fedora'
```

Expected headers include the correct `Content-Type`, `X-Content-Type-Options: nosniff`, `X-Habiter-Installer-Source: repository`, cache policy, and—when supplied upstream—an ETag. Resolver output must match the enriched GitHub Release URL, size, and SHA-256.

To roll back a script regression:

1. Revert or fix only the affected repository script and validate installer plus uninstaller lifecycle workflows.
2. Regenerate `apps/release-api/src/generated/installers.json` and require a clean second generation before review.
3. Merge the correction to `main`; the script change triggers a Worker deployment that refreshes the bundled copy.
4. Wait for revalidation (at most the documented shared-cache interval) or purge only the affected exact script URL; never purge or expose a broader repository path.
5. Fetch all four endpoints, validate markers/syntax, ETag, MIME, cache, `nosniff`, and repository-source headers without executing them.
6. Exercise installer and uninstaller dry-runs plus isolated user-scoped lifecycle fixtures before declaring recovery. Never test destructive recovery against an operator's real installation or data.

If the resolver/proxy contract itself regressed, revert the Worker change, let `worker-deploy.yml` publish the known-good version, and use Wrangler version rollback only when the normal revert cannot recover production quickly. Never work around a bad resolver by hard-coding a release URL or checksum into an installer.

## Automatic-update release assets

Android is built in two flavors with the same application ID. `direct` produces a signed universal APK with the installer permission and FileProvider; `store` produces an AAB without either direct-install capability. The build and release workflows inspect the merged manifests with `scripts/android/verify-update-flavors.sh`, and the release workflow verifies both artifacts against `ANDROID_CERT_SHA256`. The build flavor is authoritative, while the detected Android install source is an additional safeguard: a Store-installed build never receives a direct APK.

Optional story images belong in `packages/release-core/media/<version>/` and must be declared by file name, MIME type and ID in the matching draft. The publish job copies them beside the platform artifacts, calculates size and SHA-256, adds their immutable GitHub Release URLs to the runtime manifest and signs those exact manifest bytes. Missing or corrupt client-side media falls back to the declared icon without affecting the update itself.

Habiter 1.5.0 is the bootstrap release for this updater. Clients older than 1.5 must install a current version once through the download page, GitHub Releases, or a store flow. Automatic checks and direct downloads begin only after 1.5 or newer is running. Every later release still has to pass the physical-device matrix below before stable publication.

## Manual gates

The following manual checks remain part of the stable-release checklist:

- Create and verify an encrypted offline Android-keystore backup.
- Attach and verify both `get.habiter.dev` and `get-the.habiter.dev` as Worker Custom Domains in Cloudflare, then set `RELEASE_API_BASE_URL` to the API origin.
- Verify that `https://get-the.habiter.dev/` performs platform selection and that the legacy `https://get.habiter.dev/download` path redirects there with its query string intact.
- Exercise Android reminders, notification actions and App Lock on physical hardware.
- Confirm the unsigned status and user guidance for Windows and macOS downloads.
- Complete the OAuth and import/export scenarios from the release-candidate checklist.
- Install 1.5 manually over the latest pre-1.5 direct APK, then install a newer RC through the in-app flow and confirm signer continuity.
- Verify Direct and Store routing, Wi-Fi and metered downloads, denied unknown-app permission, interrupted download/process restart, offline expired mandatory deadline and the single ready notification on physical Android devices.

The current Flutter build reports a future Kotlin Gradle Plugin migration warning. It does not invalidate v1, but it must be resolved before upgrading to a Flutter release that removes KGP compatibility.

## Website deployment on Cloudflare Workers

The website is exported by Next.js as static files and deployed as Cloudflare Worker assets. No OpenNext server bundle is involved. The Cloudflare Workers Build for `habiter` uses:

```text
Root directory: apps/website
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

## Historical releases

Published tags and release entries are part of the update and download history. Do not delete or rewrite them as routine cleanup. If a release must be withdrawn for security or integrity reasons, preserve the manifest history, document the incident, verify client behavior, and use the GitHub and Worker rollback procedures deliberately.
