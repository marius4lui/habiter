# Architecture

Habiter is a local-first monorepo. The Flutter app is organized feature-first, with remaining compatibility screens and services isolated behind explicit domain and infrastructure boundaries.

## Repository map

```text
habiter/
├── apps/
│   ├── habiter/          Flutter application and native platform shells
│   ├── website/          Static Next.js product website
│   └── release-api/      Cloudflare Worker for releases and downloads
├── packages/
│   └── release-core/     Release schema, manifest, validation, and notes
├── scripts/              Release, website, and documentation tooling
├── docs/                 VitePress documentation
└── .github/workflows/    Quality, builds, deployments, and releases
```

## Flutter application layers

`apps/habiter/lib` contains four main areas:

- `app/` bootstraps dependencies, navigation, and the adaptive shell.
- `core/` provides clocks, IDs, persistence primitives, platform gateways, and the design system.
- `features/` groups analytics, App Lock, coaching, data portability, habits, history, integrations, onboarding, reminders, Today, and widgets.
- `models/`, `providers/`, `screens/`, and `services/` contain compatibility code being migrated incrementally.

Feature packages commonly separate:

```text
feature/
├── domain/          Immutable rules and value objects
├── application/     Controllers, use cases, queries, and ports
├── data/            Persistence implementations
├── infrastructure/  Platform and external adapters
└── presentation/    Widgets and screens
```

Dependencies point inward: presentation calls application code; application code works with domain concepts and interfaces; infrastructure implements those interfaces. Platform channels and packages should not leak into domain rules.

## Data flow

1. A presentation event calls a controller or use case.
2. The application layer validates the operation against domain rules.
3. A repository or gateway persists local state or invokes an explicit platform capability.
4. The controller publishes the updated view state.
5. Side effects such as reminders and widgets reconcile from committed state.

Persistence uses versioned envelopes and migration logic over key-value storage. Backup import is previewed before mutation and creates recovery material after success.

## External boundaries

- **Notifications:** `flutter_local_notifications` through reminder gateways and a durable action inbox; adaptive Android timing is evaluated by a persistent headless Flutter engine immediately before dispatch.
- **Android background runtime:** one neutral foreground service owns independent adaptive-reminder and App Block feature state, targeted recovery wakes, battery guidance, and persisted diagnostics.
- **Android App Lock:** a method-channel gateway supplies permission and blocking data to the shared background runtime; revoked access fails open.
- **Classly-compatible sync:** HTTPS OAuth with PKCE; disabled until configured.
- **Remote AI:** experimental and opt-in; local deterministic coaching is the default.
- **Release API:** a Cloudflare Worker backed by the reviewed release manifest.

The HTTP surface is specified in the [Release API reference](/api/release-api). Flutter/native message shapes are specified in [Platform-channel contracts](/dev/platform-contracts). These boundary documents must change in the same commit as an incompatible implementation change.

## Public and internal surfaces

Habiter is an application, not a published Dart or Kotlin SDK. Public HTTP routes are limited to the documented Release API. Repository packages are marked private, and release-core intentionally has no package export entry point.

Within the application, Dart declarations remain visible only where cross-file imports require them; file-local helpers use `_` names. Android implementation classes that are not framework components are `internal`. Activities, services, receivers, widgets, and callbacks referenced by Android or Glance must retain the visibility required for platform instantiation.

## Design system

The canonical presentation primitives live in `core/design_system/`: semantic colors, Material 3 themes, spacing, the [responsive layout contract](/dev/responsive-layout), shared components, motion, and haptics. User-facing text belongs in both ARB localization files.

## Quality gates

From `apps/habiter`:

```bash
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

From the repository root, install the pinned pnpm dependencies and run the release, Worker, website, and roadmap checks described in the [testing guide](/dev/testing). Documentation has its own [authoring and deployment guide](/dev/documentation).
