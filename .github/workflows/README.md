# Habiter CI workflows

Habiter exposes four intentionally scoped custom workflows. Their job names are
stable so they can be selected as required checks after repository settings are
approved separately.

| Workflow | Stable check | Purpose |
|---|---|---|
| `flutter_quality.yml` | `Flutter Quality` | Format, analyze, tests with coverage, generated-file drift, secret scan |
| `landing_quality.yml` | `Landing Quality` | Frozen pnpm install, ESLint, TypeScript and production build |
| `docs.yml` | `Docs Quality` | Reproducible VitePress build on PRs; Pages deployment only after a push to `main` |
| `platform_builds.yml` | platform job names | Android, web, Linux, macOS, Windows and unsigned iOS build verification |

All workflows use concurrency cancellation, explicit permissions and the pinned
versions from `.fvmrc`, `.node-version` and `.java-version`. Pull requests never
create a release, upload to an existing release or deploy Pages.

## Recommended repository settings

Do not change these settings without separate approval. Recommended required
checks for `main` are `Flutter Quality`, `Landing Quality`, `Docs Quality` and
the applicable platform build jobs. Branch protection should require a pull
request and an up-to-date branch.

## Local equivalents

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage

Set-Location landing_page
corepack pnpm@11.21.0 install --frozen-lockfile
corepack pnpm@11.21.0 lint
corepack pnpm@11.21.0 exec tsc --noEmit
corepack pnpm@11.21.0 build

Set-Location ..\docs
npm ci
npm run docs:build
```

Release signing and store publication are deliberately outside pull-request CI.
Without the external keystore, Android produces an unsigned release artifact for
build verification only.
