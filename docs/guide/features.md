# Features and platform support

## Habit tracking

- Daily, selected-weekday, and times-per-week schedules
- One-tap completion and immediate undo
- Pause, resume, archive, restore, and lifecycle-aware history
- Emoji icons, colors, templates, light/dark appearance, and responsive layouts

## Analytics

- Weekly progress charts, streaks, and completion rates
- Per-habit metrics and accessible chart descriptions
- Deterministic, on-device recovery suggestions
- Optional experimental remote AI, disabled until explicitly configured and governed by the selected provider's privacy and pricing terms

## Reminders

- Smart timing starts from useful category presets and learns personal and habit-specific availability locally.
- An optional seven-day calibration asks at most once per two-hour window; ignored or dismissed notifications remain neutral.
- Smart, deterministic-random, and fixed plans can be edited per habit in the Rhythm tab.
- Active hours, quiet periods, daily limits, global spacing, completion, pause state, and habit rhythm always override candidate times.
- Device-time-zone scheduling handles daylight-saving changes and reconciles stable notification identifiers after edits, resumes, and time-zone changes.
- Completion, snooze, and feasibility actions remain durable and idempotent from foreground, background, or terminated states.
- Raw learning signals expire after 180 days; aggregates remain local until the user resets or deletes them.

Delivery is controlled by the operating system. Battery policy and manufacturer customizations can delay reminders; Habiter does not promise exact delivery.

See [Reminders](/guide/reminders) for modes, calibration, permissions, local learning, actions, and troubleshooting.

## Data control

- No account is required for core tracking.
- Versioned JSON export/import includes preview, collision handling, and recovery backup.
- Optional Personal Sync connects devices to a Docker/SQLite or Worker/D1 instance that you operate; Habiter provides no hosted fallback.
- Classly-compatible OAuth and remote AI remain disabled until configured.
- Sensitive integration credentials use platform-secure storage where available.

See [Data and privacy](/guide/data-and-privacy) for storage categories, export/import behavior, optional network boundaries, credentials, and deletion scope.

See [Personal Sync Beta](/guide/personal-sync) for ownership, synchronized fields, connection, reconciliation, device sessions, limitations, and operator responsibilities.

## Platform-specific features

- **App Lock:** Android only; requires Usage Access, overlay access, and a foreground service. It fails open if access is missing.
- **Trusted updates:** Direct Android builds verify signed release metadata and the complete APK before opening Android's installer. Stable/Beta tracks, three download profiles, release stories, history and storage controls live in the Update Center. Desktop opens verified release links in the browser; iOS and web do not self-update in v1.5.
- **Home-screen widgets:** the interactive native widget and pinning flow are currently Android-only.
- **Reminders:** supported through platform notification APIs, subject to OS delivery policy.
- **Desktop/web:** core tracking works; mobile-only integrations may be unavailable.

See [Updates](/guide/updates) for tracks, download profiles, signed metadata, platform behavior, and offline safety.

## Accessibility and localization

- English and German interface text
- At least 48 dp interaction targets in the mobile design system
- Responsive layouts and large-text coverage
- Semantic chart descriptions and reduced-motion-aware transitions
