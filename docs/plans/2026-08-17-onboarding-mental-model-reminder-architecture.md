# Onboarding v3: Habit mental model and reminder architecture

**Status:** Proposed  
**Date:** 2026-08-17  
**Scope:** Flutter app onboarding, weekly habit semantics, Smart Reminder onboarding, reusable in-app education  
**Primary goal:** A new user should understand how Habiter counts habits and how reminders relate to that schedule before they reach the home screen.

---

## 1. Problem statement

The current onboarding successfully creates a first real habit, delays notification permission until the user explicitly opts in, and promotes the home-screen widget. The remaining problem is the mental model.

For a habit configured as `3x per week`, the current rhythm screen only communicates that the user chooses a weekly target. It does not explain:

- that one calendar day can count at most once for the habit;
- that Monday, Tuesday and Wednesday are a valid `3/3` week;
- that the user does not have to preselect weekdays for a flexible weekly target;
- that the weekly bucket is Monday through Sunday;
- that reminders do not change what counts as a completion.

The Smart Reminder step has the inverse problem: it exposes several technical facts before the user has understood the simpler relationship between schedule, completion and reminder.

There are also two implementation inconsistencies that must be resolved before the onboarding can truthfully explain the product:

1. `TimesPerWeekSchedule` is flexible in the habit domain, but `DynamicReminderPlanner._isHabitDay()` currently consumes the first `target` days encountered in each week through `weeklyCounts`. This effectively invents reminder days for a schedule that is otherwise intentionally day-agnostic.
2. Current onboarding copy collapses reminder spacing into one number. The domain actually enforces at least 2 hours between Smart Reminder attempts for the same habit occurrence, while the global notification guardrail defaults to 90 minutes.

Relevant current implementation:

- `apps/habiter/lib/features/onboarding/application/onboarding_state.dart`
- `apps/habiter/lib/features/onboarding/application/onboarding_controller.dart`
- `apps/habiter/lib/features/onboarding/presentation/onboarding_flow.dart`
- `apps/habiter/lib/features/onboarding/presentation/onboarding_scaffold.dart`
- `apps/habiter/lib/features/onboarding/presentation/steps/rhythm_step.dart`
- `apps/habiter/lib/features/onboarding/presentation/steps/reminder_step.dart`
- `apps/habiter/lib/features/onboarding/presentation/steps/habit_ready_step.dart`
- `apps/habiter/lib/features/onboarding/presentation/steps/widget_intro_step.dart`
- `apps/habiter/lib/features/widgets/presentation/widget_preview.dart`
- `apps/habiter/lib/features/habits/domain/habit_schedule.dart`
- `apps/habiter/lib/features/reminders/application/dynamic_reminder_planner.dart`
- `apps/habiter/lib/features/reminders/domain/reminder_policy.dart`
- `apps/habiter/lib/features/reminders/domain/reminder_preferences.dart`

---

## 2. Product contract

After onboarding, a user who created a flexible `3x per week` habit should be able to state the following without opening help:

1. **One day counts at most once.**
2. **Three consecutive days are valid.**
3. **The weekly target resets on Monday; the bucket is Monday-Sunday.**
4. **Flexible weekly targets do not require fixed weekdays.**
5. **A reminder is a timing aid, not a scheduling rule.**
6. **Completing the habit changes progress; snoozing or ignoring a reminder does not.**
7. **Smart Reminder is optional and can be changed later.**

The onboarding must teach these rules by interaction and state change, not by a long explanatory wall of text.

---

## 3. UX principles

### 3.1 Learn by doing

The two new education steps are small sandboxes. They must not mutate real habit entries, reminder signals or analytics. The user should tap a day and interact with a simulated reminder to see cause and effect.

### 3.2 Recognition over recall

The same explanatory components must be reusable later in the habit editor/settings. Onboarding is not the only place where the user can learn the model.

### 3.3 No tutorial quiz

Do not introduce multiple-choice knowledge checks. The interaction itself is the proof of understanding.

### 3.4 No artificial waiting

Do not use timers, delayed CTAs or animation gates. A single meaningful interaction is sufficient to enable continuation.

### 3.5 Preserve Habiter's existing product principles

- no shame language;
- missed and paused days remain neutral;
- no account or network requirement;
- no telemetry added for this work;
- notification permission remains opt-in and contextual;
- motion explains state and respects reduced-motion settings;
- all controls keep a minimum 48 dp target;
- color is never the only status channel;
- DE/EN localization remains mandatory.

---

## 4. Target onboarding flow

The current eight-step flow becomes a nine-step flow without adding a long tail of passive screens.

| Step | Screen | Responsibility |
|---|---|---|
| 1 | Welcome | Explain the product value briefly |
| 2 | Intent | Choose what the user wants to strengthen |
| 3 | First habit | Select/create a real first habit |
| 4 | Rhythm | Configure daily / flexible weekly / specific days |
| 5 | **How your habit counts** | New interactive schedule mental model |
| 6 | **Reminders help with timing** | New interactive schedule-vs-reminder mental model |
| 7 | Smart Reminder choice | Simplified opt-in and permission education |
| 8 | Habit ready + widget preview | Merge the current habit-ready confirmation with widget intro |
| 9 | Widget pin | Request pinning or show manual fallback |

The current standalone `HabitReadyStep` should not remain as another passive Continue screen. Its content is merged into the widget-intro experience.

---

## 5. Screen 5: How your habit counts

### 5.1 Flexible weekly schedule

For a user-selected `3x per week` habit:

**Title**

> 3x per week means three different days.

**Supporting copy**

> You do not need fixed weekdays. Any three different days between Monday and Sunday count — even three days in a row.

**Interactive model**

```text
THIS WEEK                         0 / 3

 Mo    Tu    We    Th    Fr    Sa    Su
[ ]   [ ]   [ ]   [ ]   [ ]   [ ]   [ ]

Tap three days. They may be consecutive.
```

After selecting Monday:

```text
THIS WEEK                         1 / 3

[x]   [ ]   [ ]   [ ]   [ ]   [ ]   [ ]

Monday counts. Choose another day.
```

After Monday, Tuesday and Wednesday:

```text
THIS WEEK                         3 / 3

[x]   [x]   [x]   [ ]   [ ]   [ ]   [ ]

Weekly target reached.
Three days in a row? Completely fine.
```

Below the demo, show three compact facts:

```text
[1 day = 1 check]   [week = Mon-Sun]   [spacing does not matter]
```

A second tap on an already selected day should toggle the demo state back off and briefly explain:

> A calendar day can count only once for this habit. Tapping again undoes it.

### 5.2 Daily schedule

For a daily habit:

**Title**

> Every day is one new opportunity.

**Supporting copy**

> Today can count once. Tomorrow starts a new day for this habit.

Use the same seven-day component with each day eligible.

### 5.3 Specific weekdays

For a custom schedule:

**Title**

> Only your selected days are planned.

**Supporting copy**

> Habiter expects this habit only on the weekdays you chose. Other days stay neutral.

The week component shows selected schedule days as eligible and non-scheduled days as disabled/neutral.

### 5.4 Interaction gate

The primary CTA is enabled after one meaningful interaction with the demo. For flexible weekly schedules, the ideal path is selecting the target number of distinct days, but accessibility or large-text layout must never create a dead end.

The demo is presentation-only state. It must never call `CompletionUseCase`, write `HabitEntry`, or emit reminder learning signals.

---

## 6. Screen 6: Reminders help with timing

This screen establishes the boundary between schedule and reminder before the user chooses whether to enable notifications.

**Title**

> Reminders help with timing. They do not change your goal.

**Supporting copy**

> Your rhythm decides what counts. Smart Reminder only looks for a useful moment to nudge you.

Use the user's actual habit name/icon and schedule in the simulation.

Example for `Workout · 3x per week · 1/3`:

```text
Workout                              1 / 3
3x per week

08        12        16        20        22
|---------|---------|---------|---------|
                    ^
                  16:15

+---------------------------------------+
| Workout                               |
| Does now work for you?                |
|                                       |
| [ Done ]             [ Later ]        |
+---------------------------------------+
```

### 6.1 Simulated Done

When the user taps `Done`:

```text
1 / 3  ->  2 / 3

Workout counted for today.
Further reminders for this occurrence disappear.
```

The demo must explain the real runtime relationship without mutating real state: completion is what changes progress, and completed occurrences are excluded from future reminder planning after reconciliation.

### 6.2 Simulated Later

When the user taps `Later`:

```text
16:15 reminder
      |
      | Later
      v
16:45 reminder

Weekly progress stays 1 / 3.
```

The current default snooze duration is 30 minutes. This is a simulation only.

### 6.3 Interaction gate

The CTA becomes active after the user chooses either `Done` or `Later` once. The component should offer a small reset/replay control, not force a second interaction.

---

## 7. Screen 7: Simplified Smart Reminder choice

The existing reminder screen should become a clear product choice rather than a four-section technical explanation.

### 7.1 Primary choices

```text
How present should Habiter be?

( ) No reminders
    Habiter will not notify you outside the app.

(*) Smart Reminder
    Finds useful time windows and learns from your feedback.

    [7-day learning] [on-device] [08-22]

    v How often can Habiter remind me?
```

### 7.2 Progressive disclosure

The expanded detail should state the actual guardrails precisely:

- Smart attempts for the same habit occurrence are separated by at least **2 hours**;
- global notification spacing defaults to at least **90 minutes**;
- the app-wide daily notification limit defaults to **8**;
- the active day defaults to **08:00-22:00**;
- the seven-day calibration and ongoing learning are local to the device;
- the user can change or disable reminders later.

Do not collapse the 2-hour same-habit spacing and 90-minute global spacing into one claim.

### 7.3 Permission sequence

The system notification permission request remains after explicit user intent:

```text
education -> choose Smart Reminder -> tap activation CTA -> OS permission
```

Viewing the screen, opening details, or selecting the Smart Reminder card must not itself trigger the operating-system permission prompt.

### 7.4 New-user reminder intensity

Change newly created Smart Reminder policies from `ReminderIntensity.persistent` to `ReminderIntensity.balanced`.

Product contract:

- new onboarding-created policy: maximum 2 Smart attempts per habit occurrence;
- existing reminder policies are not migrated or silently changed;
- `persistent` remains a valid domain option for users who explicitly choose it later.

---

## 8. Step 8: Merge Habit Ready and Widget Intro

The current `HabitReadyStep` is primarily a passive confirmation followed immediately by the more visual widget-intro screen. Merge them.

The combined screen should:

- confirm that the first habit was created;
- show the actual habit name/icon/rhythm;
- render the existing animated widget preview;
- populate that preview from the onboarding draft instead of the hard-coded workout/read example;
- offer `Later` and `Add widget` actions.

Example:

```text
Your habit is ready.

You can check it off directly from your home screen.

+-------------------------------+
| TODAY                    0 / 1|
| ----------------------------- |
| Read                          |
|                         [check]|
+-------------------------------+

[ Later ]          [ Add widget ]
```

`WidgetPreview` should become parameterized and reusable rather than containing product-example data internally.

---

## 9. Architecture

### 9.1 Domain remains the source of truth

Do not encode schedule rules separately inside onboarding widgets.

The source-of-truth chain should be:

```text
Habit / HabitSchedule
        |
        +--> completion eligibility/counting
        |
        +--> reminder planning
        |
        +--> OnboardingScheduleModel (read-only presentation mapping)
```

The onboarding demos consume a read-only presentation model derived from the same schedule semantics. They do not own their own interpretation of weekly logic.

### 9.2 Proposed presentation models

Create small immutable UI models rather than passing raw enums through all visual components.

Example shape:

```dart
final class ScheduleEducationModel {
  const ScheduleEducationModel({
    required this.kind,
    required this.weeklyTarget,
    required this.eligibleWeekdays,
    required this.weekStartsOnMonday,
  });

  final ScheduleEducationKind kind;
  final int? weeklyTarget;
  final Set<int> eligibleWeekdays;
  final bool weekStartsOnMonday;
}
```

This model is derived from `HabitSchedule`/`OnboardingHabitDraft`. It contains only information required to render the education UI and must not become a second business-rules engine.

### 9.3 Reusable components

Add:

```text
apps/habiter/lib/features/onboarding/presentation/components/
  week_target_demo.dart
  reminder_timeline_demo.dart
  onboarding_fact_chip.dart
```

Add steps:

```text
apps/habiter/lib/features/onboarding/presentation/steps/
  rhythm_explainer_step.dart
  reminder_model_step.dart
```

The week/schedule explanation component should later be reusable from the habit editor. The reminder model component should later be reusable from reminder settings/help.

### 9.4 Onboarding progress must not be hard-coded

`OnboardingScaffold` currently calculates progress against a literal total of `8`. Replace this with a single source of truth owned by the onboarding flow/application layer.

Preferred direction:

```dart
final class OnboardingProgress {
  static int indexOf(OnboardingStep step) => ...;
  static const total = 9;
}
```

or an equivalent ordered step definition. Individual steps should not embed their own global totals.

---

## 10. Phase 0: Fix weekly reminder semantics before UI work

This is a blocker for truthful onboarding.

### 10.1 Current issue

`TimesPerWeekSchedule.isAvailableOn(date)` intentionally keeps flexible weekly habits available without inventing weekdays. `DynamicReminderPlanner._isHabitDay()` currently tracks `weeklyCounts` while walking the planning horizon and returns false after the first `target` dates encountered.

That couples reminder eligibility to iteration order instead of actual weekly progress.

### 10.2 New contract

For `TimesPerWeekSchedule(target)`:

- every non-paused day is a potential occurrence while the weekly target is not met;
- reminder planning must not preselect weekdays;
- actual distinct completed dates in the Monday-Sunday week determine weekly progress;
- once completed distinct dates reach the target, normal reminders for remaining dates in that week are removed on reconciliation;
- the next Monday starts a new weekly target;
- custom/fixed-day schedules keep their explicit weekday semantics.

Conceptually:

```text
Monday-Sunday
     |
     +--> every non-paused date is eligible for a flexible weekly habit
     |
     +--> completed distinct dates / weekly target
     |
     +--> target not met: reminder opportunities may be planned
     |
     +--> target met: no more normal reminders in that week
```

### 10.3 Implementation direction

Remove the iteration-order `weeklyCounts` behavior from `_isHabitDay()`.

For flexible weekly schedules, determine whether the target is already met by counting completed occurrences for the habit inside the relevant Monday-Sunday bucket. Keep the planner occurrence-aware and reconcile after completion/undo so future reminders reflect the new weekly state.

Do not change completion storage semantics: one `habitId + local date` occurrence remains the counted unit.

### 10.4 Required domain/planner tests

- `3x/week`: Monday + Tuesday + Wednesday reaches target;
- `3x/week`: Tuesday + Thursday + Sunday reaches target;
- one calendar date cannot satisfy the target multiple times;
- skipping Monday does not prevent a reminder opportunity later in the week;
- target met removes remaining normal reminders for that week;
- undoing a completion can make the weekly target open again;
- next Monday starts a new weekly bucket;
- paused dates remain neutral;
- custom schedules still only produce reminders on selected weekdays.

---

## 11. Phase 1: Onboarding state v3 and migration

Update `OnboardingStep` with:

```dart
rhythmExplainer,
reminderModel,
```

Increase `OnboardingState.currentVersion` from `2` to `3`.

Do not blindly deserialize older incomplete onboarding states into the new flow. Add an explicit migration for v2 state.

Recommended v2 resume mapping:

| v2 saved step | v3 resume step |
|---|---|
| welcome | welcome |
| intent | intent |
| firstHabit | firstHabit |
| rhythm | rhythm |
| reminder | rhythmExplainer |
| habitReady | widgetIntro |
| widgetIntro | widgetIntro |
| widgetPin | widgetPin |
| completed | completed |

This lets incomplete users who were already about to choose reminders see the newly required mental-model education, while completed users are never forced through onboarding again.

Keep persisted habit draft data intact.

---

## 12. Phase 2: Controller and flow routing

Change the application flow from:

```text
rhythm -> reminder -> habitReady -> widgetIntro
```

to:

```text
rhythm
  -> rhythmExplainer
  -> reminderModel
  -> reminder
  -> widgetIntro
  -> widgetPin
```

Add explicit controller transitions such as:

```dart
confirmRhythmUnderstanding()
confirmReminderModel()
```

Update `back()` for every new step. Do not allow presentation widgets to mutate `currentStep` directly.

---

## 13. Phase 3: Interactive education components

Implement `WeekTargetDemo` and `ReminderTimelineDemo` as isolated widgets with internal ephemeral demo state.

Requirements:

- zero writes to repositories/provider state;
- no notification scheduling;
- no learning signals;
- deterministic state for widget/golden tests;
- Semantics describe selected days and progress numerically;
- keyboard/focus operation remains possible on desktop/web;
- 320 dp phone width and 200% text remain scrollable without overflow;
- reduced motion disables progress scaling/sliding while preserving state changes;
- haptics remain optional and use the existing gateway.

---

## 14. Phase 4: Reminder onboarding refactor

Refactor `ReminderStep` into a compact choice surface plus progressive disclosure.

Changes:

1. update DE/EN copy to distinguish same-habit 2-hour spacing from global 90-minute spacing;
2. keep privacy and calibration claims concise on the main card;
3. move detailed limits behind an expansion/details affordance;
4. preserve permission request only after explicit activation CTA;
5. create new-user Smart policies with `balanced` intensity;
6. preserve denial behavior: the habit is still created and reminders remain disabled.

Existing-user reminder policies must remain unchanged.

---

## 15. Phase 5: Combined habit-ready/widget screen

Remove the extra passive handoff between `HabitReadyStep` and `WidgetIntroStep`.

Implementation direction:

- keep compatibility for persisted `habitReady` states via migration;
- route new flows directly from successful habit creation/reminder setup to the combined widget-intro step;
- parameterize `WidgetPreview` with the new habit's name, icon and relevant progress data;
- keep the existing reduced-motion behavior;
- preserve `Later`, pin supported/unsupported, declined and manual fallback paths.

---

## 16. Phase 6: Reuse the mental model after onboarding

Onboarding should not become the only documentation for core semantics.

### Habit editor

Under the rhythm controls, add a small contextual action:

> How does Habiter count this?

Open a bottom sheet/dialog that reuses the schedule education component for the current draft.

### Reminder settings/editor

Add:

> How does Smart Reminder choose a time?

Reuse the reminder mental-model component and expose the actual configured guardrails.

### Today

For flexible weekly habits, prefer progress language that reinforces the model, e.g. `2 / 3 this week` and `One more day this week`, rather than implying a fixed weekday schedule.

Do not add new persistent tutorial banners to Today.

---

## 17. Localization and copy

All new user-facing strings belong in both ARB files and generated localizations.

Copy rules:

- say **different days**, not executions;
- say **Monday-Sunday** when explaining the weekly bucket;
- avoid implying that three weekly completions require spacing;
- avoid saying a reminder is a scheduled obligation;
- call calibration/learning local only if the current implementation continues to satisfy that privacy contract;
- do not describe global and per-habit notification limits as one limit.

German examples:

- `3x pro Woche heißt: drei verschiedene Tage.`
- `Drei Tage hintereinander? Völlig okay.`
- `Erinnerungen helfen beim Timing. Sie ändern dein Ziel nicht.`
- `Dein Rhythmus bestimmt, was zählt.`

English equivalents must preserve the same semantics rather than literal word order.

---

## 18. Test plan

### 18.1 Domain / reminder planner

- flexible weekly schedule is available on arbitrary non-paused dates;
- weekly target counts distinct completed dates;
- weekly target uses Monday-Sunday boundaries;
- reminder planner does not invent the first N weekdays;
- reaching target removes remaining weekly reminders after reconciliation;
- undo reopens the weekly target when appropriate;
- same-habit Smart spacing >= 2 h;
- global spacing >= configured 90 min default;
- global daily limit remains 8 by default.

### 18.2 Onboarding application

- new nine-step order;
- back navigation for every step;
- restart/resume at each new step;
- v2 -> v3 incomplete-state migration;
- completed v2 users remain completed;
- demo state never persists as habit completion/reminder data.

### 18.3 Permission behavior

- `ReminderModelStep`: zero permission requests;
- opening Smart Reminder detail: zero permission requests;
- selecting Smart Reminder: zero permission requests;
- activation CTA: exactly one request;
- denial: habit still created, reminders disabled;
- no-reminder path: zero permission requests.

### 18.4 Widget / accessibility

Test at minimum:

- 320, 360, 390 and 412 dp phone widths;
- 200% text scaling;
- light and dark themes;
- DE and EN;
- reduced motion;
- Semantics for weekly day selection/progress;
- Semantics for simulated reminder actions;
- no overflow in expanded reminder details;
- widget preview with long user-created habit name;
- widget pin supported, unsupported, declined and failure states.

### 18.5 Golden coverage

Add/refresh goldens for:

- weekly rhythm explainer initial state;
- weekly target reached state;
- reminder model before interaction;
- reminder model after Done;
- simplified Smart Reminder selected state;
- combined habit-ready/widget preview.

---

## 19. Acceptance criteria

### Product understanding

- [ ] Flexible `Nx/week` is visibly taught as `N different calendar days`, not `N actions`.
- [ ] Consecutive days are explicitly demonstrated as valid.
- [ ] Monday-Sunday weekly boundaries are visible.
- [ ] Specific weekdays remain distinct from flexible weekly targets.
- [ ] Reminder vs completion vs schedule is demonstrated through interaction.

### Runtime correctness

- [ ] Reminder planner no longer selects the first `target` weekdays by iteration order for flexible weekly habits.
- [ ] Reaching a weekly target suppresses remaining normal reminders in that week after reconciliation.
- [ ] Same-habit and global reminder spacing are represented accurately.
- [ ] New-user Smart Reminder default is `balanced`; existing policies are unchanged.

### Onboarding architecture

- [ ] Onboarding v3 migration is explicit and tested.
- [ ] Progress total is no longer hard-coded across individual screens.
- [ ] Education components are read-only and reusable.
- [ ] `HabitReadyStep` no longer adds a passive extra Continue step for new flows.
- [ ] Widget preview uses the user's real first habit.

### Accessibility / quality

- [ ] 320 dp and 200% text pass without overflow.
- [ ] Reduced motion works.
- [ ] Status does not depend only on color.
- [ ] All interactive targets are at least 48 dp.
- [ ] DE/EN strings and semantics are complete.
- [ ] Full Flutter tests and analyze pass.

---

## 20. Suggested implementation order

1. **Planner characterization tests and weekly reminder semantic fix.**
2. **Reminder copy/guardrail tests.**
3. **Onboarding v3 state migration and central progress model.**
4. **`WeekTargetDemo` + `RhythmExplainerStep`.**
5. **`ReminderTimelineDemo` + `ReminderModelStep`.**
6. **Simplify `ReminderStep` and switch new-user intensity to balanced.**
7. **Merge habit-ready/widget-intro path and parameterize `WidgetPreview`.**
8. **Reuse explainers from editor/settings.**
9. **Goldens, 320 dp/200% text, semantics and full regression suite.**

The domain/planner fix is intentionally first. The UI must never teach a rule that reminder runtime behavior contradicts.

---

## 21. Non-goals

This work does **not** introduce:

- accounts or cloud sync;
- telemetry/product analytics;
- image assets or tutorial videos;
- gamified onboarding quizzes;
- forced notification permissions;
- new backend services;
- a rewrite of the habit persistence layer;
- automatic changes to existing users' reminder intensity;
- punitive streak semantics.

---

## 22. Definition of done

This work is complete when a fresh install can create a habit, experience the counting model, experience the reminder model, explicitly choose reminder behavior, optionally grant notification permission, and reach the home screen/widget path with the runtime semantics matching every claim made in onboarding.

A flexible weekly habit must have one consistent interpretation across:

```text
habit schedule
    = completion counting
    = Today progress
    = analytics weekly bucket
    = reminder eligibility
    = onboarding explanation
```

No layer may invent a different set of weekdays for the same schedule.
