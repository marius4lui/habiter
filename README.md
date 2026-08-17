<div align="center">

<img src="apps/website/logo.png" width="128" alt="Habiter logo" />

# Habiter

**Build better habits. Keep your data yours.**

A polished, local-first habit tracker for mobile, desktop, and web — built with Flutter and shipped through a signed, reproducible release pipeline.

[![Quality](https://github.com/marius4lui/habiter/actions/workflows/quality.yml/badge.svg?branch=main)](https://github.com/marius4lui/habiter/actions/workflows/quality.yml)
[![Platform builds](https://github.com/marius4lui/habiter/actions/workflows/platform-builds.yml/badge.svg?branch=main)](https://github.com/marius4lui/habiter/actions/workflows/platform-builds.yml)
[![Release API](https://github.com/marius4lui/habiter/actions/workflows/worker-deploy.yml/badge.svg?branch=main)](https://github.com/marius4lui/habiter/actions/workflows/worker-deploy.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Version](https://img.shields.io/badge/version-1.4.0-6C63FF)](apps/habiter/pubspec.yaml)

[Website](https://habiter.dev) · [Download](https://get.habiter.dev/download) · [Documentation](docs/) · [Release API](https://get.habiter.dev/health)

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

The smart download endpoint detects Android, Windows, Linux, or macOS and redirects to the matching artifact. Platform and architecture can also be selected explicitly through query parameters.

<div align="center">

### [Download Habiter](https://get.habiter.dev/download)

`https://get.habiter.dev/download`

</div>

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
│   ├── release/          Deterministic release tooling
│   └── website/          Website contract validation
├── docs/                 Product and engineering documentation
└── .github/workflows/    Quality, builds, previews, deploys, and releases
```

The release manifest in `packages/release-core/data/releases.json` is the reviewed source of truth. The Worker exposes that data through versioned, cache-aware endpoints and provides deterministic update and download decisions.

<!-- roadmap:start -->
## Roadmap

This roadmap tracks the released baseline and planned product releases. Version dates are stable-release targets and may move depending on testing results.

## Released

### v1.4.0 — Dynamic notifications

Released.

- Seven-day calibration and local smart timing.
- Dynamic reminder planning with local-only data.
- Explainable Rhythm experience.

---

## Planned releases

### v1.4.1 — Completion UI stability

**Target:** 18 Aug 2026

**Issue:** #9

Scope:

- Fix completion success-state layout compression.
- Prevent clipped text and overlapping undo actions.
- Verify responsive behavior across Android sizes.

Reason for separate patch release:

- User-visible bug.
- No architecture changes.
- Can ship independently.

---

### v1.4.2 — Widget/App lifecycle reconciliation

**Target:** 19 Aug 2026

**Issue:** #11

Scope:

- Introduce reliable `rehydrate → reconcile → publish` lifecycle flow.
- Sync external widget/headless changes back into active app state.
- Ensure Reminder and App Lock use fresh state after resume.
- Preserve widget idempotency and avoid refresh loops.

Reason before larger features:

- Provides the state consistency foundation required by future background features.

---

### v1.5.0 — Automatic update client

**Target:** 20 Aug 2026

Scope:

- Add client-side update checking.
- Use existing Release API infrastructure.
- Verify release metadata and artifacts.
- Keep installation user-controlled.

Note:

The release API and release infrastructure already exist. This release focuses on the application experience.

---

### v1.6.0 — Habit Experience and Onboarding v3

**Target:** 21–22 Aug 2026

**Issues:** #6, #7, #8

Implementation order:

1. #8 — Canonical habit schedule semantics.
   - Daily, fixed-day and flexible weekly behavior.
   - Shared progress model for Today, Analytics, Reminders and future App Block.

2. #7 — Onboarding navigation foundation.
   - Replace step switching with a proper navigation flow.
   - Preserve resumable onboarding state.

3. #8 — Interactive onboarding education.
   - Explain habit schedules visually.
   - Explain reminder behavior.
   - Add reusable education components.

4. #6 — Manual habit creation parity.
   - Reuse the same reminder components outside onboarding.

Goal:

Avoid multiple independent implementations of schedule and reminder behavior.

---

### v1.7.0 — Persistent Habiter Runtime

**Target:** 22–24 Aug 2026

**Issue:** #10

Scope:

- Convert the existing Android foreground service into a shared Habiter runtime.
- Support adaptive reminder evaluation while the UI is closed.
- Keep reminder business logic in Dart/domain code.
- Replace App-Lock-specific watchdog behavior with targeted runtime recovery.
- Share background and battery prerequisites across runtime features.

Stable testing required:

- Android lifecycle behavior.
- Background execution.
- Reminder delivery.
- Recovery after process/service termination.

---

### v1.8.0 — App Block 2.0

**Target:** 24–31 Aug 2026

**Issue:** #12

Scope:

- Optional App Block onboarding flow.
- Local usage analysis.
- Distraction recommendations.
- Explicit app selection.
- App-to-habit bindings.
- Schedule-aware blocking rules.
- Overlay education and blocking experience.

Dependencies:

- #8 schedule semantics.
- #11 state reconciliation.
- #10 persistent runtime.

Goal:

Build App Block on stable foundations instead of duplicating runtime, schedule or lifecycle logic.

---

## Versioning rules

### Patch releases

Used for:

- Bugs.
- Reliability fixes.
- Small UX corrections.

Example: `1.4.1`, `1.4.2`.

### Minor releases

Used for:

- New user-facing features.
- Large UX improvements.
- New architectural capabilities.

Example: `1.5.0`, `1.6.0`, `1.7.0`, `1.8.0`.

### Major releases

Reserved for incompatible product/data/platform changes. Current planned work does not require a major release.
<!-- roadmap:end -->

The roadmap is maintained in [`ROADMAP.md`](ROADMAP.md). Run `pnpm roadmap:sync` after editing it; CI verifies that this generated section stays current.

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
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test

# Worker, release tooling, and website
cd ../..
pnpm install --frozen-lockfile
pnpm release:validate
pnpm release:test
pnpm website:check
pnpm --filter @habiter/release-api types
pnpm --filter @habiter/release-api check
pnpm --filter @habiter/release-api deploy:dry
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
| `GET /api/v1/update/:platform` | Version and build update decision |
| `GET /api/v1/download/:platform` | Latest platform download |
| `GET /download` | User-Agent-aware download redirect |

Concrete release responses are immutable; latest, update, and download decisions use short cache windows. Errors share a stable JSON contract with a request ID.

## Delivery model

- Every push and pull request runs formatting, analysis, tests, schema checks, Worker contracts, website validation, documentation builds, and secret scanning.
- Platform builds cover Android, Windows, Linux, macOS, web, and unsigned iOS.
- Pull requests that affect the Worker receive isolated preview deployments.
- Relevant pushes to `main` deploy the production Worker through GitHub Actions.
- Only a matching `v<semver>` tag can start an application release.
- Android APK and AAB artifacts must pass signature and certificate-fingerprint verification before publication.
- A GitHub Release remains a draft until every artifact, checksum, metadata file, and API deployment succeeds.

See the [release operating model](docs/release-operations.md) for versioning, signing, recovery, rollback, and secret rotation.
The [mobile UX system](docs/mobile-ux-system.md) documents the product hierarchy, design primitives, accessibility contract, and visual regression matrix.

## Contributing

Issues and focused pull requests are welcome. Before opening a change, run the relevant local checks above and keep application, Worker, release-core, website, and documentation changes logically separated.

Create branches using the purpose-based `<type>/<short-description>` convention described in the [branch workflow](docs/dev/branches.md). Tool or agent prefixes such as `codex/` and `claude/` are not allowed.

For larger changes, describe the user problem and migration impact first so behavior and data compatibility can be reviewed alongside the implementation. Documentation changes should follow the [documentation guide](docs/dev/documentation.md).

---

<div align="center">

**Made with care, Flutter, and a healthy respect for local data.**

If Habiter helps you stay consistent, consider giving the repository a ⭐.

</div>
