# Habiter

Habiter is a local-first habit tracker built with Flutter. It focuses on calm daily planning, schedule-aware progress, forgiving pauses, and explicit control over reminders and data.

## Current capabilities

- Daily, weekly, and custom schedules with history-preserving pause/archive/restore flows
- Schedule-aware analytics and deterministic on-device recovery coaching
- Opt-in reminders with timezone-aware occurrence scheduling and diagnostic tools
- Local JSON export/import with preview, collision handling, and rollback
- Optional Classly-compatible OAuth import; credentials live in secure device storage
- Experimental remote AI configuration, disabled by default and clearly separated from local coaching
- Android-only App Lock with explicit permissions and recovery controls
- Responsive Android, iOS, desktop, and web shells; platform-specific features degrade explicitly

Habit data is stored locally by default. No account is required. Optional integrations can transmit the data described in their setup screen only after the user enables them.

## Development

Prerequisites are Flutter 3.44.8, Java 17, and Node 24 with pnpm 11 for the landing page.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
```

The marketing site is a server-first Next.js application with one small interactive demo island:

```bash
cd landing_page
pnpm install --frozen-lockfile
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Documentation is built with VitePress:

```bash
cd docs
npm ci
npm run docs:build
```

## Architecture

Feature code lives under `lib/features`, shared persistence and design-system infrastructure under `lib/core`, and native platform adapters under their platform directories. See [architecture](docs/dev/architecture.md), [reminder QA](docs/reminder-qa.md), [App Lock](docs/app-lock.md), and [Classly-compatible sync](docs/guide/classly-sync.md).

## Releases and support

Build artifacts and availability are documented on the [GitHub Releases page](https://github.com/marius4lui/habiter/releases). A successful build does not imply store availability. App Lock is Android-only; reminder delivery still depends on OS and device-vendor policies.

Habiter is licensed under the [MIT License](LICENSE).
