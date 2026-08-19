# Habiter v1.7 Habit Experience and Onboarding v3 Implementation Plan

> **For Claude/Codex:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task and keep this ledger current.

**Goal:** Deliver Habiter v1.7 with one canonical habit schedule/progress model, truthful flexible-weekly reminders, resumable nested onboarding navigation, interactive schedule/reminder education, and equivalent Smart Reminder choices during manual habit creation.

**Architecture:** `HabitSchedule` remains the domain source of truth. A small immutable progress evaluator supplies Monday-Sunday completion state to Today, Analytics, reminder planning, onboarding presentation mapping, and future App Block work. Onboarding keeps its persisted `OnboardingController`, while a declarative nested `Navigator` owns page history and system-back behavior; education widgets keep simulation state locally and never write completions, reminder signals, or analytics.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Provider, Navigator pages, SharedPreferences-backed repositories, `flutter_local_notifications`, ARB localization, `flutter_test`, golden tests, pnpm roadmap tooling, GitHub Actions.

---

## Scope and authority

- Source of truth: `roadmap.json`, GitHub issues #6, #7 and #8, and `docs/plans/2026-08-17-onboarding-mental-model-reminder-architecture.md`.
- Branch: `feat/v1-7-habit-onboarding`, based on `origin/main` at `f519cdbefad1087b600945441cdb8c28637cdb2b`.
- v1.6 installer work is independent and remains outside this branch. This PR can review against `main` without importing the unrelated v1.6 plan branch.
- This work opens a code-review PR only. It does not merge, tag, publish, release, or deploy v1.7.
- No accounts, backend, telemetry, forced permission prompts, persistence rewrite, or automatic mutation of existing users' reminder intensity.
- Existing habits, entries, onboarding drafts, widget flows, fixed/custom schedules, pause/archive behavior, DE/EN, theme, reduced motion, and App Lock behavior must remain compatible.

## Baseline evidence

Verified on 2026-08-19 before product edits:

| Gate | Result |
|---|---|
| `git status --short --branch` | Clean on `feat/v1-7-habit-onboarding` after removing only test-created artifacts. |
| `gh auth status` / repo | Authenticated as `marius4lui`; `marius4lui/habiter`; default branch `main`. Token value not retained. |
| Main CI | `Monorepo Quality` run `32241256887` passed for base SHA `f519cdb`. |
| `flutter analyze --fatal-infos` | Code analysis: `No issues found`. Flutter then attempted its own analytics upload and exited through a network `SocketException`; future local commands use `--suppress-analytics`. |
| `flutter --suppress-analytics test` | 281 tests passed; 15 pre-existing Windows golden comparisons failed with 0.68-1.89% raster differences. Main CI remains authoritative for Linux goldens. |
| `pnpm roadmap:check` | Pre-existing base drift: generated `ROADMAP.md` and `README.md` are stale relative to `roadmap.json`; do not mix unrelated regeneration into feature batches unless v1.7 metadata itself changes. |

Local full-suite evaluation must therefore separate functional failures from the recorded Windows golden baseline. Changed v1.7 goldens are reviewed deliberately and verified again in GitHub Actions.

## Product invariants

1. Flexible `N×/week` means `N` distinct local calendar dates within Monday-Sunday; consecutive dates are valid.
2. One `habitId + LocalDate` occurrence counts at most once.
3. Daily and explicit-weekday schedules keep their existing eligibility semantics.
4. Paused/inactive dates remain neutral. Completion and undo reconcile future reminder opportunities.
5. Schedule decides what counts; completion changes progress; reminders only help with timing.
6. Onboarding simulations never call completion, persistence, notification, or learning-signal APIs.
7. Permission is requested only after explicit Smart Reminder activation; denial still creates the habit with reminders disabled.
8. New-user Smart policies use `balanced` (maximum two attempts per occurrence); existing policies are not migrated.
9. Same-habit Smart attempt spacing is at least two hours, global spacing defaults to 90 minutes, global daily limit defaults to eight, and active hours default to 08:00-22:00.
10. Existing completed onboarding remains completed. Incomplete v2 state migrates explicitly into v3.

## Batch ledger

Exactly 20 batches are allowed. A batch is `VERIFIED` only after its listed focused tests, format/analyze checks for touched Dart, `git diff --check`, and an intentional commit where files changed.

| Batch | Status | Commit | Verification |
|---:|---|---|---|
| 01 | VERIFIED | self | Baseline and plan captured; no product file changed. |
| 02 | VERIFIED | `feat(habits): add canonical schedule progress` | 13/13 schedule and progress tests pass; distinct dates, Monday-Sunday, undo, pause, daily and fixed weekdays covered. |
| 03 | VERIFIED | `refactor(progress): share weekly semantics across app` | 17/17 Today and Analytics tests pass; target reached, undo, duplicate dates and Monday reset covered. |
| 04 | VERIFIED | `fix(reminders): honor flexible weekly progress` | 35/35 planner, domain and coordinator tests pass; arbitrary days, target suppression, undo, pause, custom days and Monday reset covered. |
| 05 | VERIFIED | `fix(reminders): align fixed weekly planning` | 25/25 fixed and dynamic planner tests pass; legacy API accepts completed occurrences and shares target, undo and reset semantics. |
| 06 | VERIFIED | `feat(onboarding): migrate persisted flow to v3` | 14 state, controller, flow and Smart tests pass serially; explicit v2 mapping, persisted rewrite, nine-step order and resume covered. |
| 07 | PENDING | - | Nested navigator, manual back, system back, resume tests. |
| 08 | PENDING | - | Presentation mapper unit tests for all schedules. |
| 09 | PENDING | - | Week demo interaction and semantics widget tests. |
| 10 | PENDING | - | Rhythm explainer routing and read-only behavior tests. |
| 11 | PENDING | - | Reminder timeline Done/Later/reset widget tests. |
| 12 | PENDING | - | Reminder model routing and no-side-effect tests. |
| 13 | PENDING | - | Permission timing, copy guardrails, balanced defaults. |
| 14 | PENDING | - | Combined screen, dynamic preview, pin flow regressions. |
| 15 | PENDING | - | Manual create fixed/Smart/none parity and persistence tests. |
| 16 | PENDING | - | Editor/settings reuse tests. |
| 17 | PENDING | - | ARB generation and DE/EN string completeness. |
| 18 | PENDING | - | 320-412 dp, 200% text, themes, reduced motion, semantics, goldens. |
| 19 | PENDING | - | Full functional suite, analyze, format, repo gates, diff/security review. |
| 20 | PENDING | - | Ledger, clean status, push, PR, GitHub checks snapshot. |

## Batch 01 - Plan, baseline, and risk register

**Files:** Create this plan only.

**Steps:** Inspect branch/remote/HEAD and open issues; review the architecture; run baseline analyze, tests, roadmap check, CI lookup, and diff checks; record platform-specific golden drift without regenerating unrelated images.

**Acceptance:** Dedicated purpose branch exists; exact 20-batch scope is durable; no product mutation; known baseline failures are distinguished from v1.7 regressions.

**Commit:** `docs(plan): define v1.7 habit onboarding delivery`

## Batch 02 - Canonical Monday-Sunday schedule progress

**Files:** Create `apps/habiter/lib/features/habits/domain/habit_schedule_progress.dart`; create `apps/habiter/test/features/habits/domain/habit_schedule_progress_test.dart`; minimally modify `habit_schedule.dart` only if shared schedule helpers belong there.

**TDD steps:** Write failing cases for Monday-Sunday buckets, distinct completion dates, consecutive dates, duplicate occurrences, target reached/reopened, custom weekdays, daily schedules, and paused dates. Implement an immutable evaluator derived from `HabitSchedule`; expose week start/end, target, counted completions, remaining count, completion-on-date, target reached, and occurrence eligibility without UI copy.

**Verify:** `flutter --suppress-analytics test test/features/habits/domain`; `flutter --suppress-analytics analyze --fatal-infos`; `git diff --check`.

**Commit:** `feat(habits): add canonical schedule progress`

## Batch 03 - Today and Analytics consume canonical progress

**Files:** Modify `features/today/application/today_query.dart`, `features/analytics/domain/habit_metrics.dart`, and their focused tests. Modify Today presentation only to expose accurate flexible-weekly progress language without a persistent tutorial banner.

**TDD steps:** Lock current daily/custom behavior; add `3×/week` cases for 0/3, completion today, target reached, Monday reset, and duplicate entries. Replace local week/count calculations with the domain evaluator while preserving pause/archive denominators.

**Verify:** focused Today and Analytics tests, then analyze and diff check.

**Commit:** `refactor(progress): share weekly semantics across app`

## Batch 04 - Dynamic reminder weekly correctness

**Files:** Modify `dynamic_reminder_planner.dart`; extend `dynamic_reminder_planner_test.dart`.

**TDD steps:** Prove a flexible weekly habit does not consume the first N iterated weekdays, arbitrary later dates stay eligible, distinct completions reach the target, remaining normal reminders disappear, undo reopens the target, Monday starts a new bucket, and custom/paused behavior remains unchanged. Remove `weeklyCounts`; query canonical progress from `completedOccurrences` for each week.

**Verify:** dynamic planner tests plus reminder-domain tests, analyze, diff check.

**Commit:** `fix(reminders): honor flexible weekly progress`

## Batch 05 - Legacy fixed planner alignment

**Files:** Modify `reminder_scheduler.dart` planner input/API and focused scheduler tests. Update only real callers if needed.

**TDD steps:** Add optional completed-occurrence input, apply canonical progress to fixed reminders, cover target suppression/undo/new week/custom dates, and preserve call compatibility for legacy tests.

**Verify:** scheduler and coordinator focused tests, analyze, diff check.

**Commit:** `fix(reminders): align fixed weekly planning`

## Batch 06 - Onboarding v3 state and central order

**Files:** Modify `onboarding_state.dart`, `onboarding_controller.dart`, repository decoding if required, and state/controller tests.

**TDD steps:** Introduce `rhythmExplainer` and `reminderModel`; set version 3; add ordered `OnboardingProgress`; implement the documented v2 resume mapping; preserve drafts and completed users; route controller forward/back transitions without presentation mutation.

**Verify:** onboarding state/controller tests, analyze, diff check.

**Commit:** `feat(onboarding): migrate persisted flow to v3`

## Batch 07 - Nested onboarding navigation

**Files:** Modify `onboarding_flow.dart` and flow tests; add a small route/page helper only if it keeps page ownership clear.

**TDD steps:** Replace `AnimatedSwitcher` step swapping with a nested declarative `Navigator`; derive pages from central order; manual and system back both persist the previous step; forward CTAs push naturally; resume builds the correct stack; preserve reduced-motion transitions; leave the main Today/Analytics/Rhythm shell untouched.

**Verify:** navigation and flow tests including system pop, analyze, diff check.

**Commit:** `fix(onboarding): give steps real navigation history`

## Batch 08 - Schedule education presentation model

**Files:** Create `presentation/models/schedule_education_model.dart` and unit tests.

**TDD steps:** Map `OnboardingHabitDraft` through `HabitSchedule` into immutable daily/flexible-weekly/fixed-weekday rendering data. Include only title-independent facts: kind, target, eligible weekdays, Monday-first order, and progress seed. Reject malformed custom drafts through a typed safe fallback rather than inventing days.

**Verify:** mapper/domain tests, analyze, diff check.

**Commit:** `feat(onboarding): map canonical schedule education`

## Batch 09 - Reusable week target demo

**Files:** Create `components/week_target_demo.dart`, `components/onboarding_fact_chip.dart`, and widget tests.

**TDD steps:** Implement deterministic ephemeral day toggling, one-day-one-check behavior, flexible consecutive selection, disabled neutral custom days, numeric Semantics, keyboard focus, 48 dp targets, interaction callback, 320 dp wrapping, and reduced-motion state changes. Inject labels/copy; perform no domain writes.

**Verify:** focused component tests at EN/DE and text scale 2.0, analyze, diff check.

**Commit:** `feat(onboarding): add interactive schedule demo`

## Batch 10 - Rhythm explainer route

**Files:** Create `steps/rhythm_explainer_step.dart`; modify flow/controller wiring and flow tests.

**TDD steps:** Render the user's actual schedule, require one meaningful interaction without dead ends, demonstrate flexible consecutive days, expose Monday-Sunday facts, and move to the reminder model. Assert repositories/entries/reminder signals remain untouched.

**Verify:** rhythm explainer and onboarding flow tests, analyze, diff check.

**Commit:** `feat(onboarding): teach how habits count`

## Batch 11 - Reusable reminder timeline demo

**Files:** Create `components/reminder_timeline_demo.dart` and widget tests.

**TDD steps:** Parameterize habit identity and schedule progress; simulate Done (progress increases and occurrence reminders disappear), Later (time moves by 30 minutes while progress stays), and reset. Add precise Semantics, keyboard operation, reduced-motion mode, and no external callbacks except interaction completion.

**Verify:** component tests across themes/widths, analyze, diff check.

**Commit:** `feat(onboarding): add reminder timing simulation`

## Batch 12 - Reminder mental-model route

**Files:** Create `steps/reminder_model_step.dart`; wire flow/controller and tests.

**TDD steps:** Explain schedule/completion/reminder boundaries using the actual draft; unlock Continue after Done or Later once; allow replay; prove zero permission requests, notifications, persistence, completion writes, and learning signals.

**Verify:** reminder model and flow tests, analyze, diff check.

**Commit:** `feat(onboarding): teach reminder boundaries`

## Batch 13 - Smart Reminder choice and balanced defaults

**Files:** Refactor `reminder_step.dart`; modify `reminder_setup_service.dart`, policy/repository tests, and Smart onboarding tests.

**TDD steps:** Present None vs Smart; keep concise local-learning chips; put exact 2-hour/90-minute/eight-per-day/08:00-22:00 limits behind progressive disclosure; request permission only from activation CTA; keep denial fail-open; use balanced for new-user onboarding and later new habits while preserving serialized existing policies.

**Verify:** permission timing matrix, setup/repository tests, analyze, diff check.

**Commit:** `feat(reminders): clarify smart onboarding defaults`

## Batch 14 - Combined ready/widget experience

**Files:** Modify `widget_intro_step.dart`, parameterize `widget_preview.dart`, retire new-flow use of `habit_ready_step.dart`, update widget/onboarding tests and deliberate goldens.

**TDD steps:** Route creation directly to combined widget intro; display the actual name/icon/schedule/progress; preserve Later/Add widget/pin unsupported/declined/failure paths; keep compatibility mapping from persisted v2 `habitReady`; handle long names and reduced motion.

**Verify:** widget onboarding suite and changed goldens, analyze, diff check.

**Commit:** `feat(onboarding): combine ready and widget handoff`

## Batch 15 - Manual habit creation reminder parity

**Files:** Modify `widgets/add_habit_sheet.dart`, `habit_editor_draft.dart` or a focused reminder draft model, provider/coordinator integration if needed, and creation-flow tests.

**TDD steps:** Add None, fixed-time, and Smart choices for creation outside onboarding; use the same Smart summary/details component; do not trigger permission on selection/details; request only on save/activation; persist a Smart policy instead of falsely encoding a fixed `notificationTime`; keep editing existing fixed/Smart policies lossless.

**Verify:** creation flow and reminder provider integration tests, analyze, diff check.

**Commit:** `feat(habits): add smart reminder creation parity`

## Batch 16 - Education reuse after onboarding

**Files:** Integrate schedule education in the habit editor and reminder education in `habit_reminder_plan_editor.dart`; add focused UI tests.

**TDD steps:** Add contextual “How does Habiter count this?” and “How does Smart Reminder choose a time?” affordances. Open bottom sheets/dialogs backed by the same models/components; show actual configured limits; never write tutorial state or display persistent banners.

**Verify:** habit editor/reminder editor widget tests, analyze, diff check.

**Commit:** `feat(education): reuse habit mental models`

## Batch 17 - German and English localization

**Files:** Modify `app_en.arb`, `app_de.arb`; regenerate localization Dart files; remove feature-local hard-coded user copy introduced or touched by v1.7.

**TDD steps:** Add all titles, states, facts, semantics, progress phrases, expanded guardrails, and editor affordances. Preserve semantic equivalence, genuine umlauts, and exact distinct-day/Monday-Sunday wording.

**Verify:** `flutter gen-l10n`; localization integrity tests; analyze; diff check.

**Commit:** `feat(l10n): localize onboarding v3 education`

## Batch 18 - Accessibility, responsive, motion, and visual QA

**Files:** Extend onboarding/component widget tests and add only v1.7-owned goldens.

**TDD steps:** Cover 320/360/390/412 dp, 200% text, light/dark, DE/EN, reduced motion, focus traversal, Semantics, 48 dp controls, expanded reminder details, long habit names, and every widget pin outcome. Compare golden changes intentionally; do not regenerate unrelated base images on Windows.

**Verify:** complete v1.7 UI tests; format; analyze; diff check.

**Commit:** `test(onboarding): cover v1.7 experience quality`

## Batch 19 - Full review and repository gates

**Files:** Only fixes and plan ledger updates justified by review evidence.

**Steps:** Run Dart format check, fatal analyze, all functional Flutter tests, focused goldens, full suite with the recorded Windows baseline, relevant Android unit/config tests if platform files changed, roadmap check, `git diff --check`, secret-pattern scan, dependency-diff review, and a complete diff review for state loss, permission timing, reminder correctness, localization, accessibility, and unrelated changes.

**Acceptance:** No new functional failure; all v1.7 tests pass; any unchanged platform golden drift is explicitly separated; clean selective history.

**Commit:** `chore(v1.7): finalize quality evidence` only if the ledger or fixes changed.

## Batch 20 - Push and pull request

**Files:** Update this ledger with final commit SHAs and evidence.

**Steps:** Re-fetch and verify base/branch divergence; confirm clean worktree and intentional commit list; push `feat/v1-7-habit-onboarding`; create a review-ready PR to `main` with issue links, batch summary, test evidence, baseline caveats, manual gates, and explicit no-release/no-deployment scope; inspect initial GitHub check state.

**Acceptance:** Remote branch exists, PR URL is returned, PR is not merged, released, tagged, or deployed.

**Commit:** `docs(plan): record v1.7 implementation evidence`

## Manual residual gates

- Physical Android notification permission, foreground/background/terminated delivery, Done/Later actions, and reconciliation.
- System-back gestures on current Android navigation modes.
- Screen reader and switch/keyboard traversal on representative hardware.
- Real home-screen widget pin support/decline/failure paths and long habit names.
- Product comprehension review in German and English.

These gates remain PR evidence, not silent waivers. They do not authorize a stable release.
