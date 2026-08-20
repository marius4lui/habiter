# Habiter mobile UX system

This document is the implementation contract for Habiter's v1 mobile
experience. It complements the domain and release documentation; it does not
replace the persistence, reminder, or App Lock contracts.

## Product principles

- The first screen answers “what is next?” before it shows statistics.
- A habit can be completed with one deliberate tap and immediately undone.
- Missed and paused days are neutral. Recovery language never shames or
  invents urgency.
- Habit data remains local unless the user explicitly exports it or connects
  an optional integration.
- App Lock fails open when Android access is missing and always exposes a
  one-tap off switch while active.
- Motion explains state changes. It is removed when the operating system asks
  for reduced motion.

## Design primitives

The canonical tokens live in `apps/habiter/lib/core/design_system/`:

- `tokens.dart` defines the spacing, radius, target-size, content-width, and
  breakpoint scales.
- `habiter_palette.dart` defines light, dark, and high-contrast semantic color
  roles.
- `habiter_theme.dart` maps those roles to Material 3 components. It uses the
  platform font stack and never downloads fonts at runtime.
- `components.dart` owns shared constrained content, surfaces, section
  headings, page introductions, and empty states.
- `motion.dart` and `haptics.dart` keep transitions and feedback bounded and
  accessibility-aware.

All interactive controls must retain at least a 48 dp target. Color is never
the only status signal. User-facing copy belongs in both ARB files and generated
localizations are refreshed with `flutter gen-l10n`.

## Screen hierarchy

### Today

Today uses this order: greeting and date, compact progress, next-habit hero,
remaining habit rows, collapsed completed habits, and collapsed inactive habit
management. At 840 dp and above, active work and lifecycle/history controls use
two columns; phone layouts remain a single reading column.

### Habit editor

Create and edit share one three-step flow: identity, rhythm, and optional
reminder. Step-specific validation prevents invalid schedules while preserving
all lifecycle, source, reminder, and creation metadata on edit. Deletion remains
confirmed and is kept out of the primary action path.

### Analytics

Analytics starts with three compact summaries, then one selected habit's weekly
pattern and gentle recovery context. The chart has an equivalent semantic text
description. Per-habit metrics wrap rather than compress on narrow or
large-text layouts.

### App Lock

The overview shows enabled state, selected-app count, permission readiness, and
recovery. Installed apps use launcher icon and friendly name; package IDs are
not shown. Search filters the lazily rendered list. The unlock rule can require
all habits scheduled today or a selected subset. Android remains the only
supported platform.

### Settings

Settings is grouped into appearance, reminders, focus/App Lock, data/privacy,
and advanced integrations. Backup export copies local JSON for user-controlled
storage. Import is previewed before mutation, keeps existing collisions by
default, and copies a pre-import recovery backup after success.

## Verification

Before integration, run:

```sh
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build web --release
```

The mobile UI suite covers 320, 360, 390, and 412 dp phone widths, 200% text,
light and dark themes, one-tap completion/undo, App Lock's friendly picker, and
golden contracts for Settings and the guided editor. Native App Lock permission,
overlay, OEM battery, and launcher-icon behavior still require the real-device
matrix documented in the [App Lock engineering notes](/app-lock).
