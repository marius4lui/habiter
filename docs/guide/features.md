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

- Device-time-zone scheduling with daylight-saving handling
- Stable notification identifiers and duplicate reconciliation
- Permission-aware behavior without repeated prompts
- Durable completion actions from foreground, background, or terminated states

Delivery is controlled by the operating system. Battery policy and manufacturer customizations can delay reminders; Habiter does not promise exact delivery.

## Data control

- No account is required for core tracking.
- Versioned JSON export/import includes preview, collision handling, and recovery backup.
- Classly-compatible OAuth and remote AI remain disabled until configured.
- Sensitive integration credentials use platform-secure storage where available.

## Platform-specific features

- **App Lock:** Android only; requires Usage Access, overlay access, and a foreground service. It fails open if access is missing.
- **Home-screen widgets:** native availability and interaction behavior depend on the platform.
- **Reminders:** supported through platform notification APIs, subject to OS delivery policy.
- **Desktop/web:** core tracking works; mobile-only integrations may be unavailable.

## Accessibility and localization

- English and German interface text
- At least 48 dp interaction targets in the mobile design system
- Responsive layouts and large-text coverage
- Semantic chart descriptions and reduced-motion-aware transitions
