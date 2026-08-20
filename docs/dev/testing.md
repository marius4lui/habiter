# Testing and quality gates

Habiter uses layered automated checks plus explicit physical-device gates. A green narrow test proves only its own contract; release claims require the matching broader gate.

## Pinned toolchain

| Tool | Source of truth |
| --- | --- |
| Flutter | `.fvmrc` and CI workflow pins |
| Dart | Bundled with the pinned Flutter SDK |
| Java | `.java-version` |
| Node.js | `.node-version` |
| pnpm | Root `package.json#packageManager` |
| Documentation npm dependencies | `docs/package-lock.json` |

Use the pinned versions before diagnosing failures. Do not update a generated lockfile merely because a different local tool rewrote it.

## Flutter application

From `apps/habiter`:

```bash
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
```

Tests are grouped by boundary:

- `test/domain` covers legacy compatibility and domain invariants;
- `test/core` covers persistence, time, and design-system contracts;
- `test/features` covers controllers, repositories, platform adapters, policy, widgets, and UI flows;
- `test/screens` covers progressive settings and screen behavior;
- root-level tests protect toolchain, workflow, manifest, and configuration integrity.

Use the deterministic fakes in `test/support/fakes` instead of wall-clock time, random UUIDs, real preferences, or platform channels in unit tests. Goldens are committed behavior contracts; update them only after reviewing the rendered change.

## Android native contracts

After dependency resolution, run both application flavors:

```bash
./android/gradlew -p android \
  :app:testDirectDebugUnitTest \
  :app:testStoreDebugUnitTest
```

To prove direct/store manifest isolation, build both flavors and inspect the merged manifests:

```bash
flutter build apk --debug --flavor direct
flutter build apk --debug --flavor store
../../scripts/android/verify-update-flavors.sh \
  build/app/intermediates/merged_manifests directDebug storeDebug
```

The direct flavor must contain the installer permission and update `FileProvider`; the store flavor must contain neither. Source manifests alone are insufficient evidence because Gradle merging decides the shipped result.

## Workspace services and website

From the repository root:

```bash
pnpm install --frozen-lockfile
pnpm roadmap:check
pnpm release:validate
pnpm release:test
pnpm website:check
pnpm --filter @habiter/release-api types
pnpm --filter @habiter/release-api check
pnpm --filter @habiter/release-api deploy:dry
```

`website:check` validates the source contract, TypeScript, static production export, and a Cloudflare dry run. Worker `check` validates generated bindings, TypeScript, and route tests. Release validation checks schema, ordering, build/version agreement, channels, artifacts, media, and signing metadata.

## Documentation

From `docs`:

```bash
npm ci
npm run docs:check
```

The documentation check rejects machine-specific paths and incomplete API inventory, then performs a production VitePress build with internal-link validation. Preview the result with `npm run docs:preview` and inspect desktop/narrow layouts plus light/dark appearance when navigation or CSS changes.

## Platform builds

CI compiles:

- direct and store Android debug APKs;
- Flutter web release output;
- Linux, Windows, and macOS release applications;
- an unsigned iOS release application.

These builds prove compilation and packaging, not signing, store acceptance, background delivery, launcher behavior, or physical-device accessibility.

## Manual evidence

Keep manual checks aligned with the feature-specific matrices:

- [Release verification](/release-candidate)
- [Reminder QA](/reminder-qa)
- [App Lock QA](/app-lock)
- [Android widget QA](/dev/widget-qa)
- [Mobile UX system](/mobile-ux-system)

Record device model, operating-system version, build/flavor, locale, appearance, steps, and observed result. An unavailable gate remains unverified; it is not silently waived.

## Choosing the smallest valid gate

| Change | Minimum focused evidence | Required broader evidence before merge |
| --- | --- | --- |
| Domain rule | Direct unit test | Flutter analyze and full Flutter tests |
| Widget/layout | Widget test or golden | Flutter suite; native widget tests when Android projection changes |
| Platform channel | Dart adapter and native unit tests | Both Android flavors or affected Apple build |
| Release route | Worker route test | Worker check and deploy dry run |
| Manifest/tooling | Release-core test | Release validation and test suite |
| Website | Source/type check | Full `website:check` |
| Documentation | Relevant page review | `npm run docs:check` |

Run `git diff --check` before committing and review the final diff for generated output, local paths, credentials, and unrelated changes.
