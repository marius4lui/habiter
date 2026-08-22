<div align="center">

<img src="apps/website/logo.png" width="128" alt="Habiter logo" />

# Habiter

**Build better habits. Keep your data yours.**

A polished, local-first habit tracker for mobile, desktop, and web — built with Flutter and shipped through a signed, reproducible release pipeline.

[![Quality](https://github.com/marius4lui/habiter/actions/workflows/quality.yml/badge.svg?branch=main)](https://github.com/marius4lui/habiter/actions/workflows/quality.yml)
[![Platform builds](https://github.com/marius4lui/habiter/actions/workflows/platform-builds.yml/badge.svg?branch=main)](https://github.com/marius4lui/habiter/actions/workflows/platform-builds.yml)
[![Release API](https://github.com/marius4lui/habiter/actions/workflows/worker-deploy.yml/badge.svg?branch=main)](https://github.com/marius4lui/habiter/actions/workflows/worker-deploy.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Latest release](https://img.shields.io/github/v/release/marius4lui/habiter?sort=semver&label=release&color=6C63FF)](https://github.com/marius4lui/habiter/releases/latest)

[Website](https://habiter.dev) · [Download](https://get-the.habiter.dev/) · [Documentation](https://docs.habiter.dev) · [Release API](https://docs.habiter.dev/api/release-api)

</div>

---

## Why Habiter?

Habiter helps you turn intentions into routines without turning your personal history into somebody else's dataset. Habits, entries, preferences, and insights remain local to your device. No account is required for the core experience.

<table>
<tr>
<td width="50%" valign="top">

### Private by default

Your habit data stays on your device. Sensitive integration credentials use secure platform storage, and core tracking works without a remote account.

### Built for real routines

Create daily, weekday-based, or weekly-frequency habits. Pause, resume, archive, restore, and review them without losing their history.

### Thoughtful reminders

Local Smart timing, a transparent calibration week, explicit permission flows, stable notification IDs, and reconciliation keep reminders useful and predictable.

</td>
<td width="50%" valign="top">

### Progress you can understand

Streaks, completion rates, weekly charts, lifecycle-aware statistics, and local coaching turn history into useful feedback.

### Mobile and desktop native

One Flutter codebase powers focused mobile navigation and responsive desktop layouts across the supported platforms.

### Accessible and multilingual

Responsive screens are tested at narrow widths and large text sizes. The interface ships in English and German.

</td>
</tr>
</table>

## Platform support

| Platform | CI build | Distribution | Signing status |
| --- | :---: | --- | --- |
| Android | ✅ | Universal APK and Play Store AAB | Signed and fingerprint-verified |
| Windows | ✅ | x64 ZIP | Checksum verified; code signing planned |
| Linux | ✅ | x64 tarball | Checksum verified |
| macOS | ✅ | Universal ZIP | Checksum verified; code signing planned |
| iOS | ✅ | Unsigned CI build | Manual signing and distribution gate |
| Web | ✅ | Flutter web build | Build validation only |


## Download

The smart download endpoint sends Android to the signed direct artifact and desktop users to maintained platform instructions. Linux distribution routing is used only when an explicit distro hint exists; the local installer performs authoritative detection from `/etc/os-release`.

<div align="center">

### [Download Habiter](https://get-the.habiter.dev/)

`https://get-the.habiter.dev/`

</div>

Checksum-verifying user-scoped installers and manual instructions are available in the [installation guide](docs/install/README.md):

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

```powershell
irm https://get.habiter.dev/install.ps1 | iex
```

## Repository

```text
habiter/
├── apps/
│   ├── habiter/          Flutter application and platform projects
│   ├── website/          Standalone, dependency-free product website
│   └── release-api/      Cloudflare Worker for releases and downloads
├── packages/
│   └── release-core/     Release schema, manifest, validation, and metadata
├── scripts/
│   ├── android/          Merged-manifest checks for update flavors
│   ├── release/          Deterministic release tooling
│   └── website/          Website contract validation
├── docs/                 Product and engineering documentation
└── .github/workflows/    Quality, builds, previews, deploys, and releases
```

The release manifest in `packages/release-core/data/releases.json` is the reviewed source of truth. The Worker exposes that data through versioned, cache-aware endpoints and provides deterministic update and download decisions.

<!-- roadmap:start -->
## Roadmap

A concise view of the released baseline and upcoming product milestones.

### Released

**v1.4.0 — Dynamic notifications (Stable)**

- Seven-day calibration and local smart timing.
- Dynamic reminder planning with local-only data.
- Explainable Rhythm experience.

**v1.4.1 — Completion UI stability (Beta)**

- Fix completion-state layout issues.

**v1.4.2 — Widget/App lifecycle reconciliation (Beta)**

- Improve state synchronization between app, widgets and background actions.

**v1.4.3 — App Block overlay stability (Beta)**

- Keep App Block UI scoped to the currently blocked foreground app and align it with Habiter's product language.

**v1.4.4 — Linux startup stability (Stable)**

- Fix the Linux startup crash caused by unguarded Home Widget initialization.

**v1.5.0 — Premium automatic update system (Stable)**

- Deliver a signed, localized update experience with safe direct Android downloads and user-controlled installation.

**v1.5.1 — Android update-check reliability (Stable)**

- Use a constrained native Android transport for signed release-manifest checks.
- Preserve the existing desktop transport for Linux, Windows and macOS.
- Expose the underlying update-check failure instead of only a generic status.

**v1.6.0 — Distribution and installers (Beta)**

- Deliver repository-backed installers and a reliable, documented desktop installation experience.

**v1.7.0 — Habit Experience and Onboarding v3 (Stable)**

- Improve habit schedule understanding.
- Improve onboarding navigation.
- Align reminder creation flows.

**v1.7.1 — Editorial onboarding polish (Stable)**

- Give every onboarding step a distinct editorial layout and clearer visual hierarchy.

**v1.8.0 — Persistent Habiter Runtime (Beta)**

- Introduce a shared background runtime for adaptive reminders and future focus features.

**v1.9.0 — App Block 2.0 (Beta)**

- Add local distraction discovery and habit-based app blocking.

**v1.10.0 — Responsive app shell (Beta)**

- Optimize Habiter for desktop, tablets and compact touch displays through one responsive layout system.

### Upcoming

**v1.11.0 — Pro-Widget Settings (Stable)**

- Make every placed Habiter widget configurable with clear basic controls and advanced customization.

**v1.12.0 — Personal Sync (Beta)**

- Deliver optional, local-first Personal Sync for securely connecting Habiter across a user's devices.
- Offer self-hosted SQLite/Docker and Cloudflare D1 Beta backends without making sync mandatory.

See the detailed [`ROADMAP.md`](ROADMAP.md) for targets, issues, scope, dependencies, and versioning rules.
<!-- roadmap:end -->

The roadmap is maintained in [`roadmap.json`](roadmap.json). Run `pnpm roadmap:sync` after editing it; CI verifies both generated Markdown views.

## Getting started

### Requirements

- Flutter `3.44.8`
- Node.js `24.13.1`
- pnpm `11.21.0`
- Java `17` for Android builds

### Run the app

```bash
git clone https://github.com/marius4lui/habiter.git
cd habiter/apps/habiter
flutter pub get --enforce-lockfile
flutter run
```

### Run the complete quality suite

```bash
# Flutter
cd apps/habiter
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage

# Worker, release tooling, and website
cd ../..
pnpm install --frozen-lockfile
pnpm roadmap:check
pnpm release:validate
pnpm release:test
pnpm website:check
pnpm --filter @habiter/release-api types
pnpm --filter @habiter/release-api check
pnpm --filter @habiter/release-api deploy:dry

# Documentation
cd docs
npm ci
npm run docs:check
```

### Run the website

The marketing website is a Next.js App Router application written in TypeScript.

```bash
pnpm website:dev
```

Open `http://localhost:3000`. Use `pnpm website:check` for the complete website contract, type, and production-build checks.

## Release API

| Endpoint | Purpose |
| --- | --- |
| `GET /health` | Deployment health and environment |
| `GET /api/v1/releases` | Paginated published releases |
| `GET /api/v1/releases/latest` | Latest release for a channel |
| `GET /api/v1/releases/:version` | One concrete release |
| `GET /api/v1/releases/:version/downloads` | Artifacts for one concrete release |
| `GET /api/v1/manifest` | ETag-aware Ed25519-signed update manifest envelope |
| `GET /api/v1/update/:platform` | Version and build update decision |
| `GET /api/v1/download/:platform` | Latest platform download |
| `GET /api/v1/download/:platform/:architecture` | Latest matching platform download |
| `GET /api/v1/install/:platform/:architecture` | Complete primary installer artifact contract |
| `GET /install.sh` | Allow-listed repository POSIX installer |
| `GET /install.ps1` | Allow-listed repository PowerShell installer |
| `GET https://get-the.habiter.dev/` | Explicit platform/distro or broad User-Agent smart route |
| `GET /download` | Legacy redirect to the canonical smart-download origin |

Concrete release responses are immutable; latest, update, and download decisions use short cache windows. Errors share a stable JSON contract with a request ID.

See the [complete Release API reference](https://docs.habiter.dev/api/release-api) for parameters, schemas, status codes, caching, redirects, and verification guidance.

## Delivery model

- Every push and pull request runs formatting, analysis, tests, schema checks, Worker contracts, website validation, documentation builds, and secret scanning.
- Platform builds cover Android, Windows, Linux, macOS, web, and unsigned iOS.
- Pull requests that affect the Worker receive native aliased Cloudflare preview versions.
- Relevant pushes to `main` deploy the production Worker through GitHub Actions.
- Only a matching `v<semver>` tag can start an application release.
- Android APK and AAB artifacts must pass signature and certificate-fingerprint verification before publication.
- A GitHub Release remains a draft until every artifact, checksum, metadata file, and API deployment succeeds.

See the [release operating model](docs/release-operations.md) for versioning, signing, recovery, rollback, and secret rotation.
The [mobile UX system](docs/mobile-ux-system.md) documents the product hierarchy, design primitives, accessibility contract, and visual regression matrix.

## Contributing

Issues and focused pull requests are welcome. Before opening a change, run the relevant local checks above and keep application, Worker, release-core, website, and documentation changes logically separated.

Every contributor and AI agent follows the [agent workflows](docs/dev/agent-workflows/index.md): select a flow, plan reviewable batches, commit each completed batch locally, and report validation honestly. The compact mandatory entry point for agents is [AGENTS.md](AGENTS.md); detailed rules are maintained in the developer documentation.

Create branches using the purpose-based `<type>/<short-description>` convention described in the [branch workflow](docs/dev/branches.md). `main` can be updated only by a pull-request merge or by a task-specific direct-push confirmation from the owner. Pushes, pull requests, merges, releases, and deployments require explicit authorization.

For larger changes, describe the user problem and migration impact first so behavior and data compatibility can be reviewed alongside the implementation. Documentation changes should follow the [documentation guide](docs/dev/documentation.md).

---

<div align="center">

**Made with care, Flutter, and a healthy respect for local data.**

If Habiter helps you stay consistent, consider giving the repository a ⭐.

</div>
