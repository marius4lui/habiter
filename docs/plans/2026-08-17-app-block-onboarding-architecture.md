# App Block Onboarding Architecture and Implementation Plan

**Status:** implementation plan  
**Date:** 2026-08-17  
**Scope:** Android App Block onboarding, local distraction discovery, App↔Habit rules, schedule-aware gate evaluation, and activation UX

## 1. Goal

Add App Block as an optional, self-contained onboarding subflow that can be inserted into the wider onboarding without redefining the parent onboarding structure.

The flow must:

- ask whether the user wants App Block before requesting any privilege;
- allow a clear opt-out, with one deliberate second motivation screen before leaving the flow;
- explain Usage Access visually before opening Android settings;
- analyze app usage locally and combine it with a local distraction catalog to recommend likely distracting apps;
- let the user choose apps explicitly; recommendations must never auto-select apps;
- let each protected app be linked either to the user's general focus or to specific habits;
- explain the blocking behavior using the user's real habit schedule, including daily, flexible `N×/week`, and fixed-day schedules;
- request overlay access only after the user understands what the blocking overlay does;
- persist an App Block configuration and publish schedule-aware per-package blocking state to the Android runtime;
- reuse canonical habit/schedule semantics from the habit domain instead of creating independent schedule rules inside App Block or native Android code.

This plan is intentionally modular. The parent onboarding owns where the App Block subflow is entered and exited. App Block owns its internal navigation, permissions, draft state, education, configuration, and final result.

## 2. Architectural boundary

The parent onboarding should only depend on a small result contract:

```text
Parent Onboarding
      │
      │ Habit exists + platform supports App Block
      ▼
┌────────────────────────────┐
│ AppBlockOnboardingFlow     │
│                            │
│ own navigation             │
│ own persisted draft state  │
│ own permission handling    │
│ own configuration          │
└──────────────┬─────────────┘
               │
               ▼
     AppBlockOnboardingResult

       enabled
       skipped
       deferred
```

Do not hard-code this flow into a fixed global onboarding step order. This keeps it compatible with the onboarding navigation work in issue #7 and the habit/reminder mental-model work in issue #8.

App Block must also not duplicate the runtime reliability work from issue #10 or the foreground/widget state-convergence work from issue #11. It should expose clean inputs/outputs so those systems can reconcile App Block state.

## 3. Subflow overview

```text
ENTRY
  │
  ▼
[1] App Block offer
  │
  ├── YES ──────────────────────────┐
  │                                │
  └── NO                           │
       │                            │
       ▼                            │
[2] Second motivation               │
       │                            │
       ├── YES ─────────────────────┘
       │
       └── NO → SKIPPED → EXIT
                                    │
                                    ▼
[3] Explain Usage Access
                                    │
                                    ▼
                         Android Usage Access settings
                                    │
                                    ▼
[4] Local analysis microflow
                                    │
                                    ▼
[5] Select distracting apps
                                    │
                                    ▼
[6] Bind apps to general focus / habits
                                    │
                                    ▼
[7] Explain schedule-aware blocking
                                    │
                                    ▼
[8] Explain overlay access
                                    │
                                    ▼
                         Android overlay settings
                                    │
                                    ▼
[9] Review and activate
                                    │
                                    ▼
                                  ENABLED
```

All system-setting returns must be state-driven: on app resume, re-check the real permission state. Do not depend on an "I enabled it" confirmation button.

## 4. Screen 1 — App Block offer

### Purpose

Sell the outcome before discussing Android privileges or implementation details.

### Visual composition

```text
             ○ Social
              \
       ○ Video ────→   ◉ Fokus
              /          │
             ○ Feed      │
                         ▼
                 ┌───────────────┐
                 │ 📖 10 min lesen│
                 └───────────────┘


        Weniger Ablenkung.
        Mehr Raum für dein Habit.

 Habiter kann ausgewählte Apps pausieren,
 bis du das erledigt hast, was dir wichtig ist.


 [ Nicht jetzt ]       [ Fokus schützen ]
```

Do not show real installed-app icons at this point. Habiter has not yet been granted Usage Access and should not imply that the device was already analyzed.

### Animation

Three abstract app tiles slowly move toward the habit card. After roughly 800 ms, a thin Habiter protection line appears between the apps and the habit.

```text
Apps  → → →  │  Habit
             │
          Habiter
```

The tiles should decelerate and lose some opacity instead of bouncing or behaving like a game. The habit card can gain a small amount of emphasis.

With Reduced Motion enabled, show the final static composition immediately.

### Actions

- `Fokus schützen` → continue to Usage Access education.
- `Nicht jetzt` → second motivation screen.

## 5. Screen 2 — deliberate second opt-out

### Purpose

Give one additional, respectful explanation of why the feature can be useful. The user is not forced into App Block.

### Layout

```text
         Ein kleiner Moment kann
         den Autopiloten unterbrechen.


 OHNE APP BLOCK                  MIT APP BLOCK

 Impuls                           Impuls
   │                                │
   ▼                                ▼
 App öffnen                       App öffnen
   │                                │
   ▼                                ▼
 Feed / Scroll                    Habiter
   │                                │
   ▼                                ▼
 Zeit vergeht                    Habit erledigen
                                    │
                                    ▼
                               App ist frei


 [ App Block einrichten ]     [ Ohne App Block weiter ]
```

On screen 1, the negative action is on the left and the positive action on the right. On this second screen, reverse the visual sides:

```text
Screen 1:  [ Nein ]                         [ Ja ]
Screen 2:  [ Ja ]                           [ endgültig Nein ]
```

This is a deliberate second decision, not a moving target. Never move a button after the user tries to press it and never make the decline action evade interaction.

### Actions

- `App Block einrichten` → Usage Access education.
- `Ohne App Block weiter` → persist `AppBlockOnboardingResult.skipped` and exit immediately.

There is no third persuasion dialog in the same onboarding session.

## 6. Screen 3 — Usage Access education

### Purpose

Explain exactly why Habiter needs Usage Access before opening the Android settings screen.

### Layout

```text
              So findet Habiter
             deine Ablenkungen


 ┌──────────────┐
 │ Instagram    │──┐
 └──────────────┘  │
 ┌──────────────┐  │      nur Nutzungsdaten
 │ YouTube      │──┼───────────────┐
 └──────────────┘  │               │
 ┌──────────────┐  │               ▼
 │ Maps         │──┘        ┌─────────────┐
 └──────────────┘            │   HABITER   │
                             │    lokal    │
                             └──────┬──────┘
                                    │
                                    ▼
                           mögliche Ablenkungen


 Habiter verarbeitet z. B.
 ✓ wie lange eine App genutzt wurde
 ✓ wann sie zuletzt genutzt wurde

 Habiter liest nicht
 ✕ deine Nachrichten
 ✕ Inhalte in anderen Apps
 ✕ Passwörter


 Alles bleibt auf deinem Gerät.


        [ Apps analysieren ]
```

The copy must describe data Habiter actually consumes. Do not make broader claims about every field Android might expose through usage APIs.

### Permission flow

The CTA opens Android Usage Access settings through `Settings.ACTION_USAGE_ACCESS_SETTINGS`.

On resume:

```text
App resumed
    ↓
checkUsageAccess()
    ↓
granted → continue automatically
denied  → remain on education screen + keep explicit skip/back path
```

## 7. Screen 4 — local analysis microflow

### Purpose

Query local usage, rank candidates, and transition into the selection screen without a fake waiting period.

### Visual

```text
       Wir schauen nur auf dieses Gerät


 Instagram    █████████████
 YouTube      █████████
 WhatsApp     █████
 Maps         ██
 TikTok       ████████

                ↓

 Instagram    ───────────┐
 TikTok       ───────────┼──→ mögliche Ablenkungen
 YouTube      ───────────┘
```

### Motion

1. App rows appear.
2. Usage bars grow from zero to their local values.
3. High-scoring candidates move toward the top.
4. The composition morphs directly into the app-selection list.

Do not artificially hold the user on this screen. Continue as soon as the local query and ranking are ready.

## 8. Local recommendation model

Use two local signals:

```text
                tatsächliche Nutzung
                        +
             lokaler Distraction Catalog
                        │
                        ▼
                Recommendation Score
```

### A. Actual usage

Use recent local usage, initially a seven-day lookback window. `UsageStatsManager.queryAndAggregateUsageStats()` is appropriate for package-keyed aggregated usage over a time range.

Useful ranking inputs include foreground usage duration and recency/last use where available and reliable for the supported Android versions.

Example presentation data:

```text
Instagram    4 h 12 min
YouTube      3 h 41 min
TikTok       2 h 55 min
Maps         1 h 50 min
Banking         18 min
```

### B. Local distraction catalog

Add a versioned local asset, for example:

```text
assets/app_block/distraction_catalog.v1.json
```

Conceptually:

```json
{
  "com.instagram.android": {
    "category": "social",
    "prior": "high"
  },
  "com.zhiliaoapp.musically": {
    "category": "short_video",
    "prior": "high"
  },
  "com.google.android.youtube": {
    "category": "video",
    "prior": "medium"
  }
}
```

Identity is the Android package ID, not the visible application name.

The catalog may cover categories such as:

```text
Social
Short Video
Video
Streaming
Forums
Games
Shopping
News
Dating
...
```

Catalog membership means "potentially distracting", not "harmful".

### Initial ranking weights

Use a simple deterministic ranking rather than ML:

```text
70 % actual foreground usage
20 % local distraction prior
10 % recency
```

These are starting weights and should be easy to tune. Keep the algorithm local and testable.

Never auto-select recommendations.

### Package visibility

The current Android app discovery path uses installed application enumeration. Android package visibility filters PackageManager results for apps targeting Android 11+.

App Block should focus on launchable user apps and declare the required selective package visibility using a targeted `<queries>` intent contract where possible. Do not add `QUERY_ALL_PACKAGES` merely as a shortcut.

The resulting selection source should represent apps the user can meaningfully open and protect.

## 9. Screen 5 — distraction selection

### Layout

```text
       Was zieht dich am häufigsten weg?

 Wir haben anhand deiner Nutzung einige
 mögliche Ablenkungen gefunden.


 ┌────────────────────────────────────┐
 │ ○  Instagram                      │
 │    4 h 12 min · Social            │
 │    Häufig genutzt                 │
 ├────────────────────────────────────┤
 │ ○  TikTok                         │
 │    2 h 55 min · Short Video       │
 │    Wahrscheinlich ablenkend       │
 ├────────────────────────────────────┤
 │ ○  YouTube                        │
 │    3 h 41 min · Video             │
 │    Häufig genutzt                 │
 ├────────────────────────────────────┤
 │ ○  Reddit                         │
 │    1 h 32 min · Community         │
 └────────────────────────────────────┘


          + Andere App auswählen


          [ 3 Apps schützen ]
```

Show at most five primary recommendations before an explicit `Andere App auswählen` search/full-list path.

If there is insufficient usage data:

```text
Wir haben noch nicht genug Nutzung gefunden,
um sinnvolle Vorschläge zu machen.

[ Apps manuell auswählen ]
```

Do not invent usage-based recommendations when the source data is missing.

## 10. Required domain-model change: per-app rules

The existing configuration applies one global unlock rule to all selected locked apps. That cannot represent the required behavior:

```text
Instagram ──────────────→ Allgemein
TikTok ─────────────────→ Sport
YouTube ────────────────→ Lesen + Lernen
Reddit ─────────────────→ Lernen
```

Replace the global rule model with per-app rules.

Conceptually:

```dart
final class AppBlockConfig {
  final bool enabled;
  final List<AppBlockRule> rules;
}

final class AppBlockRule {
  final String packageName;
  final String appName;
  final AppBlockRequirement requirement;
  final bool enabled;
}

sealed class AppBlockRequirement {}

final class GeneralRequirement extends AppBlockRequirement {}

final class HabitRequirement extends AppBlockRequirement {
  final Set<String> habitIds;
}
```

### Semantics

`GeneralRequirement` means:

> This app is protected by all active habits that are relevant for the current day according to canonical habit schedule/progress semantics.

`HabitRequirement` means:

> Only the selected habits can gate this app.

When multiple habits are linked to one app, use **AND** semantics:

```text
YouTube → Lesen + Sport

Lesen ✓
Sport ○

→ YouTube remains blocked
```

Only when all currently relevant linked blockers are satisfied does the app open:

```text
Lesen ✓
Sport ✓

→ YouTube open
```

## 11. Screen 6 — App↔Habit binding

Avoid forcing the user through one full page for every selected app. Start with a bulk rule and then allow per-app overrides.

### Bulk rule

```text
        Was sollen diese Apps schützen?


 Instagram   TikTok   YouTube
    ●          ●        ●


 (●) Meinen Fokus allgemein

     Ausgewählte Apps bleiben gesperrt,
     solange für heute relevante Habits
     noch offen sind.


 ( ) Bestimmte Habits

     Wähle genau aus, womit diese Apps
     verbunden sein sollen.


               [ Weiter ]
```

### Specific habits

```text
           Welche Habits?


 ☑ 📖 Lesen
 ☐ 🏃 Laufen
 ☑ 🧘 Meditation


 [ Für alle ausgewählten Apps übernehmen ]
```

### Review/edit bindings

```text
 Deine Regeln

 Instagram
 → Allgemein                       [Ändern]

 TikTok
 → Lesen                           [Ändern]

 YouTube
 → Lesen + Meditation              [Ändern]
```

This gives fast bulk setup while preserving per-app specificity.

## 12. Schedule-aware gate evaluation

Do not use the current generic `TodayQuery.pending` result as the direct App Block gate. Flexible `N×/week` habits are available on every weekday, so treating today's pending state as a lock condition would effectively convert a flexible weekly habit into a daily obligation.

Introduce a dedicated domain/application service:

```text
AppBlockGateEvaluator
```

It must consume canonical habit schedule/progress semantics from the habit domain. It must not independently redefine weekly counting, custom-day schedules, date bucketing, or completion semantics.

## 13. Gate semantics for the three schedule types

### Daily

```text
Habit: Lesen · täglich

Heute
○ Lesen

Instagram → BLOCKED

      ↓ Lesen erledigt

✓ Lesen

Instagram → OPEN
```

The gate resets on the next local day.

### Fixed/custom weekdays

Example:

```text
Laufen
Mo · Mi · Fr
```

Wednesday:

```text
Mo ✓    Di –    Mi ○    Do –    Fr ○
                  ▲
                heute

Laufen offen
      ↓
Instagram BLOCKED
```

Thursday:

```text
Mo ✓    Di –    Mi ✓    Do –    Fr ○
                         ▲
                       heute

Heute nicht geplant
      ↓
Instagram OPEN
```

A habit must not gate an app on a date on which its canonical schedule says it is not relevant.

### Flexible `N×/week`

This uses a **daily contribution gate** while the weekly target is still open.

Example: `Lesen · 3× pro Woche`.

Monday, before completion:

```text
Mo     Di     Mi     Do     Fr     Sa     So
 ○      ·      ·      ·      ·      ·      ·

0 / 3

Instagram
🔒
```

After completing Monday:

```text
Mo     Di     Mi     Do     Fr     Sa     So
 ✓      ·      ·      ·      ·      ·      ·

1 / 3

Instagram
🔓 frei für heute
```

It does **not** require `3 / 3` before unlocking that day.

Tuesday begins a new daily contribution opportunity:

```text
Mo     Di     Mi     Do     Fr     Sa     So
 ✓      ○      ·      ·      ·      ·      ·

1 / 3

Instagram
🔒
```

After Tuesday completion:

```text
✓      ✓

2 / 3

Instagram
🔓
```

After the third completion:

```text
✓      ✓      ✓

3 / 3

WOCHENZIEL ERREICHT
```

For the rest of that canonical week, this habit no longer creates a gate:

```text
Do     Fr     Sa     So
 🔓     🔓     🔓     🔓
```

The exact rule is:

```text
weekly target already reached
        ↓
NO GATE

otherwise:

completed today
        ↓
NO GATE FOR TODAY

otherwise
        ↓
GATE ACTIVE
```

This keeps `N×/week` flexible while still allowing App Block to create a useful daily focus gate until the weekly target is met.

## 14. Screen 7 — visual blocking education

Use the user's real habit and schedule instead of generic tutorial data.

For a user with `Lesen · 3×/Woche`:

```text
           So funktioniert dein App Block


 📖 Lesen
 3× pro Woche


 Mo       Di       Mi       Do       Fr       Sa       So
 ✓        ●        ○        ○        ○        ○        ○
          ↑
        heute

 1 / 3 diese Woche


 ┌──────────────────┐
 │    Instagram     │
 │        🔒         │
 │   noch gesperrt  │
 └──────────────────┘


            ↓


         Lesen ✓


 Mo       Di       Mi
 ✓        ✓        ○

 2 / 3


 ┌──────────────────┐
 │    Instagram     │
 │        🔓         │
 │   frei für heute │
 └──────────────────┘
```

### Animation

A short one-time sequence:

```text
0.0s   protected app appears locked
0.8s   current habit circle gains emphasis
1.4s   circle ○ → ✓
1.8s   weekly progress 1/3 → 2/3
2.2s   lock 🔒 → 🔓
2.5s   "frei für heute"
```

After the sequence, keep the final state visible. Provide `Nochmal ansehen` to replay it.

For daily and fixed-day schedules, reuse the same education component with the appropriate canonical schedule state.

Reduced Motion must present the semantic before/after states without required animation.

## 15. Screen 8 — overlay permission education

Request overlay access only after the user has chosen apps, created bindings, and understood the gate behavior.

### Layout

```text
              Wenn du eine
           geschützte App öffnest


         ┌──────────────────┐
         │    Instagram     │
         │                  │
         │      Feed        │
         └──────────────────┘
                  │
                  ▼
        ┌───────────────────────┐
        │          🔒           │
        │   Instagram pausiert  │
        │                       │
        │   Erledige zuerst:    │
        │   ○ 10 min Lesen      │
        │                       │
        │ [ In Habiter öffnen ] │
        │                       │
        │   Zurück zum Home     │
        └───────────────────────┘
```

Copy:

> **Warum diese Berechtigung?**  
> Android muss Habiter erlauben, den Blockier-Screen über der ablenkenden App anzuzeigen.

CTA:

```text
[ App Block erlauben ]
```

Use Android overlay settings through `Settings.ACTION_MANAGE_OVERLAY_PERMISSION`; permission state is checked through `Settings.canDrawOverlays()`.

On resume:

```text
canDrawOverlays()
       ↓
 true → continue automatically
false → remain on explanation/recovery state
```

Do not request overlay access before the user has context for what the overlay is used for.

## 16. Native blocking overlay projection

The current native overlay receives a blocked-app name plus a global list of incomplete habits. Replace this with a per-package projection produced from Dart/domain state.

Conceptually:

```text
AppBlockGateProjection
```

Example:

```json
{
  "packageName": "com.google.android.youtube",
  "blocked": true,
  "blockers": [
    {
      "habitId": "...",
      "name": "10 min lesen",
      "progress": "2/3 diese Woche"
    }
  ]
}
```

The overlay for YouTube shows only the blockers that currently gate YouTube. Instagram may have a completely different projection at the same moment.

The normal overlay has no `Trotzdem öffnen` bypass. The user can open Habiter to complete the requirement or return to the launcher/home screen.

## 17. Schedule logic stays in Dart/domain code

Do not implement daily/weekly/custom schedule semantics inside `AppMonitorService.kt`, `BlockingOverlay.kt`, or other Android-native runtime code.

Required direction:

```text
Habit Repository
       │
       ▼
canonical schedule progress
       │
       ▼
AppBlockGateEvaluator     ← Dart
       │
       ▼
AppBlockGateProjection
       │
       ▼
shared Habiter runtime
       │
       ▼
foreground package?
       │
       ▼
projection says blocked?
       │
       ▼
BlockingOverlay
```

Native Android only needs to know whether the current package is blocked and which already-computed habit blockers should be displayed.

## 18. Feature structure

Target structure after the ongoing refactors:

```text
features/app_lock/
│
├── domain/
│   ├── app_block_config.dart
│   ├── app_block_rule.dart
│   ├── app_block_gate.dart
│   ├── app_block_candidate.dart
│   └── app_lock_gateway.dart
│
├── application/
│   ├── app_block_gate_evaluator.dart
│   ├── app_block_gate_projector.dart
│   ├── app_block_recommendation_service.dart
│   ├── app_block_onboarding_controller.dart
│   └── app_block_onboarding_state.dart
│
├── infrastructure/
│   ├── method_channel_app_lock_gateway.dart
│   ├── app_block_repository.dart
│   ├── android_usage_repository.dart
│   └── local_distraction_catalog.dart
│
└── presentation/
    └── onboarding/
        ├── app_block_onboarding_flow.dart
        ├── app_block_offer_page.dart
        ├── app_block_reconsider_page.dart
        ├── usage_access_education_page.dart
        ├── distraction_analysis_page.dart
        ├── distraction_selection_page.dart
        ├── app_habit_binding_page.dart
        ├── app_block_behavior_page.dart
        ├── overlay_education_page.dart
        └── app_block_review_page.dart

assets/
└── app_block/
    └── distraction_catalog.v1.json
```

Names can be adjusted to repository conventions during implementation; the ownership boundaries should remain.

## 19. Persisted onboarding state

Do not inflate the parent onboarding enum with every internal App Block screen. Keep App Block progress feature-local.

Conceptually:

```dart
enum AppBlockOnboardingStage {
  offer,
  reconsider,
  usageEducation,
  discovery,
  selection,
  binding,
  behaviorEducation,
  overlayEducation,
  review,
  completed,
  skipped,
}
```

Persist enough draft state to survive the system-settings round trips and possible process recreation:

```text
selectedPackages
ruleDrafts
usagePermissionSeen
overlayPermissionSeen
current App Block onboarding stage
```

A user who leaves Habiter for Android settings and returns after process recreation must resume at the correct App Block step rather than restarting from the first offer screen.

## 20. Screen 9 — review and activation

Keep the final screen concise.

```text
              Dein App Block


 Instagram
 Allgemeiner Fokus
 ────────────────────────

 TikTok
 📖 Lesen
 ────────────────────────

 YouTube
 📖 Lesen
 🧘 Meditation
 ────────────────────────


 ✓ Nutzungszugriff
 ✓ Blockier-Screen erlaubt
 ✓ Hintergrundbetrieb bereit


 Wenn ein verbundenes Habit offen ist,
 hält Habiter die App für dich zurück.


          [ App Block aktivieren ]
```

`Hintergrundbetrieb bereit` must come from the shared runtime prerequisite/reliability contract owned by issue #10; this flow must not duplicate the battery/runtime setup screens.

Activation sequence:

```text
persist AppBlockConfig
     ↓
evaluate current gates
     ↓
publish native projection
     ↓
require shared runtime
     ↓
success
```

Then return:

```text
AppBlockOnboardingResult.enabled
```

The parent onboarding resumes ownership from there.

## 21. Migration of existing App Lock configuration

Existing App Lock JSON must migrate deterministically without losing user choices.

For a former global `all habits` configuration:

```text
OLD:
lockUntilAllHabitsComplete = true
Instagram ✓
TikTok ✓

→

NEW:
Instagram → General
TikTok    → General
```

For a former global list of required habit IDs:

```text
OLD:
requiredHabitIds = [reading, sport]
Instagram ✓
TikTok ✓

→

NEW:
Instagram → [reading, sport]
TikTok    → [reading, sport]
```

Existing users must not be forced through the new onboarding after migration.

## 22. Integration boundaries with existing issues

### Issue #7 — onboarding navigation

App Block should be a self-contained nested/subflow destination. It must not reintroduce a manually switched global step stack or depend on a hard-coded absolute step index.

### Issue #8 — canonical habit schedule and reminder mental model

App Block consumes the canonical schedule/progress representation established there. It must not create a second implementation of `daily`, flexible `N×/week`, custom weekdays, weekly bucket boundaries, or completion counting.

The visual schedule education in App Block should reuse the same mental-model components where practical.

### Issue #10 — shared background runtime

Issue #10 owns foreground-service/background reliability and battery/runtime prerequisites. App Block should only declare that the feature requires the shared runtime when enabled.

Do not create a second App-Block-specific battery optimization onboarding sequence.

### Issue #11 — external state convergence

A completion performed through the home-screen widget or another external/headless path can change an App Block gate.

App Block should expose a reusable projection refresh path, conceptually:

```dart
AppBlockGateProjector.refresh(snapshot)
```

Issue #11 remains responsible for lifecycle/state convergence and for invoking dependent-state reconciliation with fresh repository state.

## 23. Fail-open and recovery rules

Blocking must fail open rather than trapping the user in an invalid runtime state.

At minimum:

- Usage Access revoked → do not rely on stale monitoring state; expose a recovery state in Habiter.
- Overlay access revoked → no invisible/half-working blocking state; expose recovery in Habiter.
- linked habit deleted/archived/paused → re-evaluate/clean the binding and never crash.
- protected app uninstalled → configuration may be retained for migration/history or cleaned according to repository policy, but must not crash the runtime.
- malformed/missing projection → native runtime should not block by default.

## 24. Tests

### Domain gate matrix

| Case | Expected |
|---|---|
| Daily, today open | blocked |
| Daily, today completed | open |
| Custom, today not scheduled | open |
| Custom, today scheduled + open | blocked |
| Custom, today completed | open |
| `3×/week`, 0/3 + today open | blocked |
| `3×/week`, 1/3 + today completed | open |
| `3×/week`, 2/3 + today open | blocked |
| `3×/week`, 3/3 target reached | open |
| Two linked habits, one open | blocked |
| All relevant linked habits complete | open |
| Habit paused | no gate |
| Habit archived | no gate |
| Habit deleted | binding cleanup/fail-open |
| App uninstalled | no crash |
| Usage Access revoked | fail-open + recovery state |
| Overlay access revoked | fail-open + recovery state |
| Widget completion | projection refreshes |
| Local date rollover | gates re-evaluate |
| Monday/week rollover | weekly progress resets canonically |
| Time-zone change | canonical current `LocalDate` wins |

Flexible weekly behavior needs dedicated tests because App Block's daily contribution gate must never change the underlying flexible weekly completion semantics.

### Onboarding/UI tests

Cover at least:

- first `No` opens the reconsider screen;
- second `No` exits cleanly and persists `skipped`;
- accepting from either opt-in screen enters the same permission flow;
- Usage Access is not requested before its education page;
- resume after Usage Access grant advances automatically;
- insufficient usage data offers manual selection rather than fake recommendations;
- recommendations are never auto-selected;
- bulk binding and per-app overrides produce the expected rules;
- schedule education uses the user's real schedule and supports daily/custom/flexible weekly;
- overlay permission is not requested before overlay education;
- resume after overlay grant advances automatically;
- process recreation during Android-settings round trips restores App Block onboarding state;
- Reduced Motion keeps all semantics understandable without motion;
- existing users are not forced through the new flow after migration.

### Native/integration tests

Cover at least:

- package discovery respects supported package visibility behavior;
- per-package projection selects only that package's blockers;
- malformed/missing projection fails open;
- overlay never exposes a normal `Trotzdem öffnen` bypass;
- changing a habit completion updates the projection without duplicating schedule logic in Kotlin;
- shared runtime lifecycle integration does not create a second App Block-specific service lifecycle.

## 25. Definition of done

The feature is complete when:

- App Block is an optional, resumable onboarding subflow with `enabled`, `skipped`, and `deferred` outcomes;
- a first decline leads to one second motivation screen and a second decline exits without further pressure;
- Usage Access and overlay access are each explained contextually before their Android settings screens;
- distraction recommendations are computed locally from actual usage plus a versioned local package catalog;
- users explicitly select apps; no app is protected solely because the recommender suggested it;
- selected apps support per-app `General` or specific-habit requirements;
- multiple linked habits use AND semantics for currently relevant blockers;
- daily, custom-day, and flexible `N×/week` gates behave exactly as defined in this plan;
- flexible weekly habits unlock immediately for the current day after a completion and stop gating for the rest of the week once the weekly target is reached;
- the blocking education screen visually demonstrates the user's real schedule and gate behavior;
- schedule logic remains in the canonical Dart/domain layer and native Android receives only projected blocking state;
- old global App Lock configuration migrates without silently losing selected apps or habit requirements;
- App Block consumes the shared runtime from #10 and state convergence from #11 instead of duplicating those responsibilities;
- the existing onboarding/navigation and habit schedule work from #7/#8 can change independently without requiring hard-coded App Block step indices;
- automated tests cover the gate matrix, permission/resume flow, migration, reduced motion, recommendation fallbacks, projection behavior, and external completion reconciliation.

## 26. Product decisions fixed by this plan

These choices are intentional and should not be reinterpreted during implementation without a separate product decision:

1. **General means all currently relevant active habits.** New active habits can therefore become part of a general-focus rule according to the canonical schedule semantics.
2. **Multiple linked habits use AND semantics.** Every currently relevant linked blocker must be satisfied before that app is opened.
3. **Flexible weekly habits use the daily contribution gate.** Until the weekly target is reached, completing the habit unlocks the app for the current day immediately; after `N/N`, that habit no longer gates the rest of the week.
4. **There is no normal overlay bypass.** The user can open Habiter or return home, but the protected app does not expose a regular `Trotzdem öffnen` action.
5. **Recommendations never equal selection.** Usage/catalog scoring only suggests candidates; the user always makes the actual blocking choice.

## 27. Primary Android references

Implementation should be checked against current Android platform behavior while coding:

- UsageStatsManager: https://developer.android.com/reference/android/app/usage/UsageStatsManager
- Usage Access settings / overlay settings: https://developer.android.com/reference/android/provider/Settings
- Package visibility overview: https://developer.android.com/training/package-visibility
- Declaring package visibility needs: https://developer.android.com/training/package-visibility/declaring
- `<queries>` manifest element: https://developer.android.com/guide/topics/manifest/queries-element
