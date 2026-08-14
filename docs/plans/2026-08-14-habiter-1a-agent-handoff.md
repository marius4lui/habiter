# Habiter 1A Modernization – Agent Handoff

**Cut date:** 2026-08-14

**Repository:** `marius4lui/habiter`

**Local path:** `C:\Users\Marius\Projekte\Dev\habiter`

**Branch:** `codex/habiter-1a-modernization`

**Base:** `main` at `18b9689c88029d4d2d6f125dd6fcd87207c0f767`

**Canonical execution ledger:** `docs/plans/2026-08-14-habiter-1a-modernization.md`
**State at this cut:** Batches 01–17 verified; Batch 18 intentionally `IN_PROGRESS`; no PR, merge, release, or deployment.

This file is the operational handoff for the next long-running implementation agent. The canonical plan remains authoritative for scope, batch acceptance criteria, exact commands, risks, and the final PR checklist. Do not replace or shorten that plan.

## 1. Non-negotiable objective and boundaries

Finish the complete 40-batch modernization described in the canonical plan. The final state must include at least 30 real, substantive, individually tested Conventional Commits; the plan targets one or more commits for each of 40 batches. Preserve existing local data through characterization tests and versioned migration. Modernize the Flutter app, Next.js landing, tests, CI, documentation, accessibility, security, and performance.

Mandatory constraints:

- Use only `git` and `gh` CLI for repository and GitHub operations. Do not use a GitHub connector or app.
- Work only on `codex/habiter-1a-modernization`; never force-push or rewrite history.
- Continue committing by coherent tested batch. Run `git diff --check` before every commit and stage only intended files.
- Push at least at each five-batch checkpoint and at the final handoff.
- Do not merge, release, publish, or deploy.
- Create a review-ready PR against `main` only after all required gates are genuinely green or explicitly identified as external/manual.
- Classly must end default-off and lazy. AI must end isolated, experimental, default-off, and must not leak credentials.
- Notifications must be correct on Android and iOS, including device timezone, DST, permissions, rescheduling, stable IDs, background/terminated actions, and honest hardware gates.
- App Lock must remain, but use typed platform contracts, fail-open recovery, lifecycle/battery safeguards, and honest OEM/policy limits.
- Never invent demo data, product capabilities, testimonials, metrics, or deployment claims.
- Do not treat a successful push as a deployment.

## 2. Verified commits already present

The following commits are ordered and must be preserved:

1. `8b8eedb` `docs(modernization): capture verified baseline`
2. `3630ce8` `test(domain): lock in existing habit behavior`
3. `7152983` `build(toolchain): align flutter node and java versions`
4. `24de94a` `ci: replace duplicated and misleading workflows`
5. `349d29e` `test(core): add deterministic platform and storage fakes`
6. `85b2737` `refactor(domain): define explicit habit schedules`
7. `6ef5c15` `refactor(data): introduce habit repositories`
8. `10fa73a` `feat(data): migrate legacy local records safely`
9. `b64b11e` `refactor(app): introduce explicit dependency graph`
10. `6d9b35f` `refactor(state): split monolithic app state`
11. `d25183a` `feat(navigation): add adaptive application shell`
12. `9997942` `feat(design): introduce accessible habiter tokens`
13. `919cbb8` `feat(motion): add reduced-motion aware feedback`
14. `1146aeb` `feat(onboarding): create consent-first first run`
15. `79c18df` `feat(today): redesign daily habit focus`
16. `c355031` `feat(habits): rebuild habit editor`
17. `0882a62` `feat(habits): make completion durable and reversible`

The commit containing this handoff is an explicit cut/checkpoint for the partial Batch 18 implementation. Determine its exact SHA with `git rev-parse HEAD`; do not amend it. Complete Batch 18 in a subsequent commit and record both facts honestly in the ledger.

## 3. What is implemented and verified

### Foundations and data safety

- Flutter/Node/Java/pnpm pins and release-compatible unsigned local Android behavior.
- Consolidated CI workflows with explicit permissions and concurrency.
- Deterministic clock, IDs, storage, notification, and platform fakes.
- Explicit schedule domain for daily, weekdays, and times-per-week semantics.
- Repository boundary with serialized atomic transactions and rollback.
- Versioned storage envelope with raw backup, record quarantine, idempotent migration, unknown-field preservation, and legacy-key fallback.
- Startup composition graph runs migration before repository verification and keeps optional services out of cold start.

### Flutter architecture and experience

- Feature controllers split from the legacy provider façade.
- Adaptive Navigator shell, route codec/restoration, keyboard navigation, and system back behavior.
- Accessible light/dark/high-contrast design tokens with offline-native typography.
- Reduced-motion-aware animation budget and injected platform-safe haptics.
- Consent-first onboarding with a genuinely empty first run and no automatic AI/notification initialization.
- Today query filters inactive and unscheduled habits; adaptive 320px/200%-text UI; no fabricated personalization.
- Validated create/edit draft preserves all prior persisted fields, supports custom days and opt-in reminders, and survives German small-screen/keyboard tests.
- Completion is transactionally idempotent, double-tap-safe, target-count-aware, commit-bound to Undo tokens, protected against stale Undo, and used by notification actions without accidental toggling.

### Verification through Batch 17

- Batch 16: 4 targeted tests and full Flutter 75/75 passed; analyze passed.
- Batch 17: 4 targeted completion tests and full Flutter 79/79 passed; analyze passed.
- Checkpoints 05, 10, and 15 included Flutter analyze/coverage plus Android debug, unsigned Android release, Flutter web release, and Windows release builds.
- The exact commands and outputs are recorded in section 20 of the canonical plan.

## 4. Batch 18 at this cut: partial but green

Do not mark Batch 18 verified yet. The cut currently includes:

- `HabitPause`, `HabitLifecycleStatus`, pause/archive/restore timestamps, default-preserving serialization, and null-clearing `Habit.copyWith` semantics in `lib/models/habit.dart`.
- Editor preservation of lifecycle metadata so ordinary editing cannot erase it.
- `HabitLifecycleUseCase` with pause, resume, archive, restore, and cascading delete.
- `HabitTimeline` derived from created/pause/resume/archive/restore metadata.
- Analytics filtering of entries that fall inside pause ranges.
- Controller/provider methods for pause/resume/restore; deactivation cancels habit reminders and reactivation reschedules eligible reminders.
- A localized Pause action and a scrollable small-screen-safe lifecycle layout in the habit detail dialog.
- Three lifecycle tests covering serialization/legacy defaults, transition timeline, pause-aware statistics, and cascading delete.

Verification run immediately before this handoff:

```text
flutter gen-l10n                                      PASS
dart format [all touched Batch 18 files]              PASS
flutter analyze --fatal-infos                         PASS (no issues)
flutter test test/features/history/habit_lifecycle_test.dart
  test/domain/habit_legacy_test.dart
  test/features/habits/editor/habit_editor_draft_test.dart
                                                       PASS 10/10
flutter test                                           PASS 82/82
git diff --check                                       PASS
```

Known Batch 18 work still required before changing its status to `VERIFIED`:

1. Add widget tests at 320px and 200% text scale for Pause action/dialog scrolling and callback order.
2. Provide a real discoverable archived/paused management surface with Resume and Restore actions; provider methods alone are insufficient UI evidence.
3. Make notification lifecycle side effects injectable/testable. Current provider calls the legacy singleton directly, so reminder cancel/reschedule behavior is implemented but not strongly proven.
4. Verify safe destructive confirmation from the real delete entry point. Deletion must remain explicit and cascading; archive must remain reversible.
5. Confirm pause range boundary semantics in the canonical analytics model: pause start date is excluded, resume date is available again.
6. Run Batch 18 targeted tests, `flutter analyze --fatal-infos`, full `flutter test`, and `git diff --check` again.
7. Update Batch 18 status/acceptance/log in the canonical plan and advance exactly one `IN_PROGRESS` marker to Batch 19.
8. Commit the completion as `feat(history): add forgiving habit lifecycle` or an equally precise Conventional Commit. Do not amend the cut commit.

## 5. Exact resume procedure

Start with these read-only checks:

```powershell
Set-Location C:\Users\Marius\Projekte\Dev\habiter
git status --short
git branch --show-current
git log -5 --oneline
git rev-parse HEAD
git rev-parse origin/codex/habiter-1a-modernization
Get-Content docs/plans/2026-08-14-habiter-1a-agent-handoff.md
Get-Content docs/plans/2026-08-14-habiter-1a-modernization.md
```

Then finish Batch 18 test-first using the remaining list above. Preserve unrelated work if the worktree is dirty. After Batch 18, follow the canonical plan in order:

- Batch 19: deterministic analytics calculators and honest denominators.
- Batch 20: recovery/health score and checkpoint 20.
- Batches 21–26: reminder registry, timezone/DST, permission state machine, scheduler/reconciliation, background actions/inbox, diagnostics QA.
- Batches 27–29: typed App Lock contract, native lifecycle/battery/policy behavior, recovery UX.
- Batches 30–32: Classly lazy/default-off and security, then AI isolation/default-off.
- Batches 33–34: settings information architecture and safe export/import portability.
- Batches 35–38: server-first Next.js landing, premium real product story, honest demo/SEO/performance, complete Beta/Feedback/Test/Admin removal.
- Batch 39: verified legacy cleanup and documentation.
- Batch 40: full release-candidate evidence, push, review-ready PR, and available GitHub checks.

At every five-batch checkpoint run the full matrix in section 20 of the canonical plan and push. Never skip a failing gate silently; either fix it in scope or record exact evidence and the designated later batch.

## 6. Known baseline and open risks

- The Flutter secure-storage web package emits a known Wasm compatibility warning involving `dart:html`/`dart:js`; earlier Flutter web release builds still passed.
- Landing frozen install and TypeScript passed through checkpoint 15.
- Landing lint baseline was 6 errors/4 warnings in later-to-be-removed Beta/Admin/i18n surfaces.
- Landing had no test script and production build failed at `/de/feedback` because the legacy Supabase client required `supabaseUrl`. Batches 35–38 must remove that legacy surface and make all gates genuinely green, not suppress them.
- Docs build passed. Production dependency audit was zero at checkpoint 15; the dev tree retained three VitePress/Vite/esbuild findings without a stable VitePress 1.x fix. Re-evaluate in Batch 39; do not blindly move to an alpha.
- Local Android release APK is intentionally unsigned without a supplied keystore. Signing is an explicit external release gate, not permission to create or expose credentials.
- iOS hardware and Android OEM App Lock matrices may remain manual/external, but adapter contracts and automated platform tests must still be strong and the PR must state the residual gates honestly.

## 7. Final completion proof required

Before opening the PR, prove rather than assume:

- At least 30 substantive batch commits; target all 40 plan batches.
- Every plan row has status, tests, exact SHA, risk, and next step; exactly one row may be `IN_PROGRESS` until the final batch, then none.
- Migration and rollback evidence is still green.
- Classly default-off/lazy, AI isolated/default-off, notifications and App Lock meet their stated contracts.
- Flutter format, analyze, tests, coverage, Android debug/release, web release, Windows release, Gradle/Kotlin tests.
- Landing frozen install, lint, TypeScript, tests, build, Playwright, accessibility, responsive screenshots, and performance evidence.
- Docs build, secret scan, dependency audit, license review, `git diff --check`, and clean `git status`.
- Push the final branch with `git push` and create the PR with `gh pr create --base main --head codex/habiter-1a-modernization`.
- Inspect and watch checks with `gh`; fix available failures. Do not change repository settings or branch protection without explicit authority.
- Final handoff must state base/head SHAs, PR URL, commit count, exact automated evidence, manual/external gates, and explicitly: not merged, not released, not deployed.

## 8. Safety reminders

- Do not echo, persist, or commit secrets. Search staged content before final push.
- Do not delete legacy code or assets until replacement and reference checks prove safety.
- Do not use `git reset --hard`, force push, history rewrite, or broad destructive filesystem commands.
- Do not claim mobile notification correctness from a desktop unit test alone; separate automated contracts from real-device evidence.
- Do not mark the overall goal complete merely because this handoff is pushed. The goal remains incomplete until the full plan and PR completion audit pass.
