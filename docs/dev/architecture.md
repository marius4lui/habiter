# Architecture

Habiter is a local-first monorepo. The Flutter app is organized feature-first while legacy screens and services are migrated behind explicit domain and infrastructure boundaries.

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

- **Notifications:** `flutter_local_notifications` through reminder gateways and a durable action inbox.
- **Android App Lock:** a method-channel gateway backed by an Android foreground service.
- **Classly-compatible sync:** HTTPS OAuth with PKCE; disabled until configured.
- **Remote AI:** experimental and opt-in; local deterministic coaching is the default.
- **Release API:** a Cloudflare Worker backed by the reviewed release manifest.

## Design system

The canonical mobile primitives live in `core/design_system/`: semantic colors, Material 3 themes, spacing and breakpoints, shared components, motion, and haptics. User-facing text belongs in both ARB localization files.

## Quality gates

From `apps/habiter`:

```bash
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

From the repository root, install the pinned pnpm dependencies and run the release, Worker, website, and roadmap checks described in the root README. Documentation has its own [build and deployment guide](/dev/documentation).
