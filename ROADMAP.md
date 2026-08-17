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
