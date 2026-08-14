# Habiter 1A Modernization Implementation Plan

**Goal:** Habiter vollständig zu einer modernen, verlässlichen und psychologisch unterstützenden Habit-App samt hochwertiger Next.js-Landingpage umbauen.

**Repository:** https://github.com/marius4lui/habiter

**Base SHA:** `18b9689c88029d4d2d6f125dd6fcd87207c0f767`

**Working Branch:** `codex/habiter-1a-modernization`

**Architecture:** Ein expliziter App-Bootstrap verdrahtet injizierbare Zeit-, ID-, Persistenz-, Reminder- und Plattformadapter. Provider bleibt vorerst als schlanke Flutter-Bindung erhalten; Domain, Use Cases und Repository-Verträge sind frameworkfrei. Das bestehende SharedPreferences-Format wird über ein versioniertes Envelope, Backup und idempotente Migration abgesichert; ein späterer Datenbankwechsel ist erst nach nachgewiesenem Bedarf zulässig.

**Tech Stack:** Flutter 3.44.x / Dart 3.12.x, Provider hinter Feature-Controllern, SharedPreferences plus sichere Credential-Ablage, `flutter_local_notifications`, Kotlin/Android Platform Channels, Next.js 16 App Router, React 19, TypeScript, pnpm, Vitest und Playwright.

**Status:** IN_PROGRESS

**Resume Pointer:** Batch 12 – organisches Habiter Design System aus Farb-, Typo-, Spacing-, Shape- und State-Tokens aufbauen; zuerst Token-Vollständigkeit, Theme-Snapshots und Kontrastgrenzen testen.

---

## 1. Executive Summary

Habiter wird in 40 substanzielle, einzeln geprüfte Batches modernisiert. Kernverhalten und lokale Daten erhalten Vorrang vor visueller Neuheit. Die Flutter-App bleibt offline-first, accountfrei und trackingfrei. Reminder werden occurrence-basiert und DST-sicher, Android App Lock erhält einen typisierten Vertrag und einen sicheren Recovery-Weg, Classly und AI werden echte opt-in Integrationen. Die Landingpage wird server-first neu gebaut; Beta-, Test-, Feedback-, Admin- und Supabase-Funktionalität wird vollständig entfernt, während Legal-Routen und allgemeine Download-Zwecke erhalten bleiben.

## 2. Verifizierter Ausgangszustand

- Verifiziert am 2026-08-14 auf Windows 11 25H2.
- `main` und `origin/main` zeigten auf `18b9689c88029d4d2d6f125dd6fcd87207c0f767`.
- Neuer Branch `codex/habiter-1a-modernization` wurde direkt von `origin/main` erstellt.
- `gh auth status`: Account `marius4lui`, Git-Protokoll HTTPS, benötigte Repo-/Workflow-Rechte vorhanden; Token wurde nicht ausgegeben.
- Flutter-App liegt im Root; Landingpage in `landing_page/`; VitePress-Dokumentation in `docs/`.
- 4 Flutter/Build-Workflows überlappen sich; die letzten App-Läufe waren rot, Docs war grün.
- Große Verantwortungsmischungen: `settings_screen.dart` 866 Zeilen, `analytics_screen.dart` 562, `app_lock_screen.dart` 544, `add_habit_sheet.dart` 470, `main.dart` 473, `notification_service.dart` 403, `habit_provider.dart` 363.
- Landing-God-Components: `app/admin/page.tsx` 565 Zeilen, `lib/i18n.tsx` 383, Testdetail 333, Startseite 300.
- Keine fremden oder vorbestehenden Worktree-Änderungen beim Preflight.

## 3. Aktuelle Core-Funktionsmatrix

| Fähigkeit | Ausgangsimplementierung | Erhaltungsvertrag | Hauptrisiko |
|---|---|---|---|
| Habit CRUD | `HabitProvider` + statischer `StorageService` | Create/Edit/Archive/Delete bleiben erreichbar | Updates verlieren Schedule-/Reminder-Felder |
| Frequenzen | `daily`, `weekly`, `custom`, `targetCount`, `customDays` | Semantik wird explizit und getestet | weekly/X-mal-pro-Woche uneindeutig |
| Completion/Undo | Ein Entry pro Habit/Datum | One-tap, idempotent, sofortiges Undo | lokale Datumsstrings und Race Conditions |
| History/Streaks/Analytics | `habit_utils.dart` | schedule-aware, deterministisch | ungeplante Tage verfälschen Kennzahlen |
| Offline Storage | sechs SharedPreferences-Keys | kein Account/Cloudzwang; alte Payloads migrieren | kein Schema, keine atomaren Writes |
| DE/EN/Theme | ARB + SettingsProvider | beide Sprachen, System/Light/Dark | generierte Dateien und lange Texte |
| Notifications | Singleton, Hash-IDs, Berlin-Zeitzone | Device-TZ, DST, Actions, Diagnose | alte Payload-Daten, Doppel-Schedules |
| Android App Lock | MethodChannel + FGS + Overlay | erhalten, deaktivierbar, Recovery | 150-ms-Main-Looper-Polling, Policy |
| Classly | Root-Provider lädt beim Start | nur explizites opt-in, lazy, sicher | Default-URL, Token-/OAuth-Flows |
| AI | lokaler zufälliger Stub mit API-Key-Config | nur experimentell/default-off | Key in SharedPreferences, irreführend |
| Landing/Live/Legal | Next App Router | DE/EN, Demo, Imprint/Privacy/Terms | Client-lastig, Claims, fehlende Tests |
| Beta/Feedback/Admin | Supabase-Client und Routen | vollständig entfernen | tote Links/Übersetzungen/Deps |

## 4. Nicht veränderbare Verhaltensverträge

- Bestehende Habits und Entries müssen nach Update vollständig lesbar bleiben.
- Create, Edit, Archive, Delete, Completion und Undo dürfen nicht verschwinden.
- Daily, weekly und custom schedules bleiben abbildbar; Migration darf keine Frequenz erfinden.
- Kein ungefragter Seed-/Mock-Habit bei leerem Storage.
- DE/EN, Theme, lokale Notifications und Android App Lock bleiben vorhanden.
- Classly und AI bleiben optional, dürfen ohne Aktivierung weder initialisieren noch Netzwerk auslösen.
- Kein Accountzwang, keine Telemetrie, Werbung oder Datenübertragung als Default.
- Legal-Inhalte bleiben erhalten; juristische Aussagen werden nicht erfunden oder materiell umgeschrieben.

## 5. Datenformate und Migrationsrisiken

Bestehende Keys: `habiter_habits`, `habiter_habit_entries`, `habiter_ai_insights`, `habiter_user_preferences`, `habiter_ai_config`, `habiter_app_lock_config`; zusätzlich Classly-Keys `classly_base_url`, `classly_last_sync`, `classly_token`, `classly_auto_sync_interval`. Native App-Lock nutzt das separate Android-Preference-File `app_lock` mit `locked_packages`, `is_enabled`, `habits_complete` und `incomplete_habits`.

Legacy-Habitfelder: `id`, `name`, `description`, `color`, `icon`, `frequency`, `targetCount`, `category`, `customDays`, `createdAt`, `isActive`, `notificationEnabled`, `notificationTime`. `StorageService.updateHabit` persistiert derzeit `customDays`, `notificationEnabled` und `notificationTime` nicht. `fromMap` verwendet `DateTime.now()` als nichtdeterministischen Fallback. Unbekannte Felder gehen beim Roundtrip verloren.

Migration: zuerst realistische Fixtures und Characterization Tests, dann unverändertes Raw-Backup, versioniertes Envelope, quarantänisierte fehlerhafte Records, atomarer Temp/Commit-Schritt und idempotente Wiederholung. Rollback liest das Backup und schreibt nur nach expliziter Bestätigung zurück.

## 6. Baseline-Testresultate

| Command | Result |
|---|---|
| `flutter --version` | PASS: Flutter 3.44.8, Dart 3.12.2 |
| `flutter doctor -v` | PASS: Windows, Android 36.1, Chrome, Visual Studio; keine Issues |
| `flutter pub get` | PASS, aber erzeugt untracked `pubspec.lock` und aktualisiert Generatorausgaben |
| `dart format --output=none --set-exit-if-changed .` | FAIL: 20 von 36 Dart-Dateien nicht formatiert |
| `flutter analyze` | PASS: no issues, 62.2 s |
| `flutter test` | PASS: 4 Tests in 3 Dateien |
| `flutter build apk --debug` | PASS: `app-debug.apk`, Java-8-Deprecation-Warnungen |
| `flutter build apk --release` | FAIL: Release-SigningConfig verlangt fehlendes `storeFile` |
| `corepack enable` | FAIL: EPERM auf `C:\Program Files\nodejs\pnpx` |
| `pnpm install --frozen-lockfile` | FAIL nach Installation: `sharp` und `unrs-resolver` Buildskripte nicht freigegeben |
| lokales `eslint .` | FAIL: 6 Errors, 4 Warnings in Test/Admin/i18n |
| lokales `tsc --noEmit` | PASS |
| lokales `next build` | FAIL: `/de/feedback` prerender benötigt Supabase-URL |

## 7. CI-Ausgangszustand

Aktiv sind `Build All Platforms`, `Build APK`, `Comprehensive CI`, `Deploy Docs`, `Flutter` und der Pages-Systemworkflow. Die letzten Push-Läufe für `18b9689` waren: Docs erfolgreich; Build APK, Comprehensive CI und Flutter fehlgeschlagen. Flutter-Pins 3.24.5 und 3.27.0 widersprechen README, Dart Constraints und lokaler Toolchain. Release-Signing wird auch in normalen Builds unzulässig vorausgesetzt. Es gibt keine eigenständige belastbare Landing-CI.

## 8. Online Research Log

| Datum | Quelle | `gh`-Befehl | Erkenntnis | Auswirkung / Prinzip | Lizenz |
|---|---|---|---|---|---|
| 2026-08-14 | `flutter/flutter` | `gh repo view flutter/flutter` | Aktuelle Flutter-Architektur unterstützt UI, Plattformkanäle und alle Zielplattformen | Flutter beibehalten; Adaptergrenzen testen | BSD-3-Clause |
| 2026-08-14 | `flutter/samples` | `gh search code "Material 3" --repo flutter/samples` | Material-3-Demo zeigt Farbrollen, Typografie, Elevation, Light/Dark | Prinzipien übernehmen, keinen Code kopieren | BSD-3-Clause |
| 2026-08-14 | `MaikuB/flutter_local_notifications` | `gh release view` + README via `gh api` | 22.3.0 aktuell; Background-Entry-Point, Launch Details, Zoned Schedule, 64-iOS-Limit, Exact/Inexact dokumentiert | Upgrade erst nach ADR; occurrence-basierter Adapter | BSD-3-Clause |
| 2026-08-14 | `vercel/next.js` | `gh release view --repo vercel/next.js` | 16.3.1 aktuell | kompatibles Minor-Upgrade nach grüner Foundation | MIT |
| 2026-08-14 | `w3c/wcag` | `gh repo view w3c/wcag` | WCAG-Quellen sind autoritative A11y-Basis | AA-Kontrast, Keyboard, Semantics, Reflow | W3C |
| 2026-08-14 | `rrousselGit/riverpod` | `gh repo view` / Release-Abfrage | aktive Alternative, aber Migration erhöht Scope | Provider vorerst modularisieren | MIT |
| 2026-08-14 | `simolus3/drift` | `gh release view` | Drift 2.34.3, starke Cross-Platform-Persistenz | kein sofortiger Wechsel ohne Bedarf | MIT |
| 2026-08-14 | `flutter/packages` | `gh repo view flutter/packages` | SharedPreferences offiziell gepflegt | versionierte Repository-Schicht zunächst ausreichend | BSD-3-Clause |
| 2026-08-14 | `nodejs/node` | `gh api repos/nodejs/node/releases/latest` | 26.7.0 ist aktuell, lokale 24.13.1-Linie bleibt die konservative LTS-Wahl | Node exakt auf 24.13.1 pinnen, keinen Current-Major erzwingen | MIT |
| 2026-08-14 | `pnpm/pnpm` | `gh release view --repo pnpm/pnpm`; `gh search code "allowBuilds:"` | 11.21.0 aktuell; Buildskripte werden mit booleschem `allowBuilds` explizit erlaubt/verboten | `sharp` und `unrs-resolver` explizit `true`, frozen install verifiziert | MIT |
| 2026-08-14 | `iSoron/uhabits` | `gh repo view --json ...` | klare Habit-Semantik, lokal | nur Produktprinzipien; kein GPL-Code | GPL-3.0 |
| 2026-08-14 | `FriesI23/mhabit` | `gh repo view --json ...` | local-first, smart scoring, Multi-Platform | verzeihender Score als optionales Prinzip | Apache-2.0 |
| 2026-08-14 | `xpavle00/Habo` | `gh repo view --json ...` | privacy-first | ehrliche Privacy-Kommunikation | GPL-3.0 |
| 2026-08-14 | `HabitRPG/habitica` | `gh repo view --json ...` | starke Gamification | bewusst keine manipulative Übernahme | Other |

## 9. Architekturentscheidungen und Alternativen

- **ADR-001 – Provider vs Riverpod:** Provider bleibt zunächst, wird aber nicht mehr aus Domain/Application referenziert. Wechsel bietet aktuell weniger Nutzen als Migrationsrisiko.
- **ADR-002 – SharedPreferences vs Drift:** Versioniertes SharedPreferences-Envelope bleibt für die kleine lokale Datenmenge. Drift ist ein möglicher späterer Adapter, aber kein Zwang.
- **ADR-003 – Zeit:** `Clock`, `LocalDate` und Occurrence-Berechnung werden injiziert; kein fachliches `DateTime.now()` in Domain/Tests.
- **ADR-004 – IDs:** `IdGenerator` wird injiziert; Notification-IDs werden stabil persistiert, nicht aus Dart-`hashCode` abgeleitet.
- **ADR-005 – Fehler:** typisierte Domain-/Persistence-/Permission-Fehler, redigierte Logs, kein leerer Catch.
- **ADR-006 – Web:** Server Components und statische Daten als Default; Client Islands nur für Demo, Locale-Steuerung und Navigation.

## 10. UX- und Psychologieprinzipien

Autonomie, kleine Schritte, ruhige Belohnung, One-tap Completion, sofortiges Undo, freundliche Rückkehr, Progress statt Perfektion, pausable Habits und ehrliche Empty States. Kein Shame, keine toxischen Streak-Screens, keine künstliche Verknappung, Fake-Zahlen oder medizinische Versprechen. Ein optionaler Recovery Score ergänzt klassische Streaks, verändert aber keine historischen Entries.

## 11. Accessibility-Anforderungen

WCAG-2.2-AA-orientierte Kontraste; plattformgerechte Touch Targets; Semantics Labels; logische Fokusreihenfolge; Keyboard-Navigation; 200% Text Scaling; lange deutsche Texte; 320–390 px Breite; Tablet/Desktop; High Contrast; Reduced Motion; keine ausschließlich farbbasierte Information; Live-Regionen nur für sinnvolle Statusänderungen.

## 12. Security- und Privacy-Anforderungen

Keine Secrets im Client oder in Logs. AI-/Classly-Tokens ausschließlich Secure Storage, mit redigierten Fehlern und Löschfunktion. Classly OAuth verwendet State und PKCE, keine Client Secrets oder direkten Passwortfluss. Landing-CSP, Referrer-/Content-Type-/Frame-Headers und validierte öffentliche Env-Werte. Keine Telemetrie oder neue Netzwerkanfrage ohne Aktivierung.

## 13. Performance-Budgets

- Flutter: Cold bootstrap ohne optionale Netzwerk-/Integrationsarbeit; keine Main-Isolate-Schleife unter 500 ms; UI-Frames 60 fps Ziel; große Listen lazy; keine ungegrenzten Partikel.
- App Lock: adaptive/eventnahe Abfrage statt 150-ms-Main-Looper-Polling; Screen-off vollständig pausiert.
- Landing: Lighthouse Performance/A11y/Best Practices/SEO jeweils >=95 auf öffentlichen Kernseiten; minimale Client-Bundles; stabile Media-Dimensionen; keine Layout Shifts.

## 14. Notification-Korrektheitsmatrix

| Dimension | Erwartung | Automatischer Nachweis | Manuelles Gate |
|---|---|---|---|
| Timezone/DST | Device-TZ, Spring/Fall Transition korrekt | FakeClock + TZ-Fixtures | reales Android-Gerät |
| Frequenzen | daily, weekday, custom, X/week | Scheduler Unit Tests | Stichprobe Gerät |
| Mutationen | create/edit reschedule; archive/delete/disable cancel | Controller + Plugin Fake | Pending-Diagnose |
| IDs | stabil, persistiert, kollisionsfrei | Registry Tests | Upgrade-Stichprobe |
| Permissions | Android/iOS State Machine; keine Prompt-Schleife | Adapter Tests | OS-Dialoge Gerät |
| Actions | foreground/background/terminated, idempotent | Durable Inbox Tests | echte Prozesszustände |
| Payload | Habit-ID + aktuelle Occurrence, kein altes Datum | Decoder/Resolver Tests | Deep Link |
| Limits | iOS max. 64, keine Duplikate | Capacity Tests | iOS manuell/offen |
| Reboot/Change | Boot/update/timezone reschedule | Contract/Manifest Tests | Gerät/Reboot |
| Exactness | inexact als Default; exact nur bewusst | Policy Tests | Systemeinstellungen |

## 15. App-Lock-Plattformmatrix

| Plattform | Scope | Automatisch | Manuell / Limit |
|---|---|---|---|
| Android 13–16 | Usage Access, Overlay, FGS, Recovery | MethodChannel/Kotlin/Manifest Tests | OEM/Policy/Prozesskill |
| Android <13 | kompatibler Permission-Pfad | Unit/Gradle | Geräteverfügbarkeit |
| iOS/macOS | andere Apps nicht blockierbar | Unsupported-State Test | klare UI-Erklärung |
| Windows/Linux/Web | nicht unterstützt | Unsupported-State Test | keine Zuverlässigkeitsclaims |

Recovery: App Lock kann jederzeit in Habiter deaktiviert werden; fehlende Rechte stoppen Monitoring fail-open; Overlay bietet Rückweg zu Habiter/Systemsettings. Keine absolute OEM-Zuverlässigkeitsbehauptung.

## 16. Classly-Opt-in-Konzept

Default `disabled`; kein Root-Provider, kein Start-Netzwerk, keine sichtbare Default-URL. Erst Settings → Advanced → Integrations → Classly-kompatibel öffnen und bewusst aktivieren. Endpoint validieren, Credentials sicher speichern, OAuth State/PKCE, Timeout/Cancel, Disable + Credentials löschen. Bestehende verbundene Nutzer werden als enabled migriert, importierte Habits bleiben erhalten. Source-Metadaten und externe Event-ID ersetzen Description-Magic-String und Namensdeduplizierung.

## 17. Landingpage-Konzept

Ruhige organische Markenwelt mit warmem Off-White, tiefem Waldgrün, Moos-/Aprikosenakzenten, großzügiger Typografie und kleinen progressiven Motiven statt Glassmorphism. Hero: lokale Gewohnheiten, die in den Alltag passen. Ein primärer Download-/Release-CTA, ehrliche Plattformmatrix und reale App-Screens. Statische DE/EN-Dictionaries auf dem Server. Live-Demo bleibt ehrlich und lokal. Legal bleibt. Beta, Test, Feedback, Admin und Supabase verschwinden vollständig.

## 18. Batch-Plan

### Batch 01: Forensische Baseline und Funktionsmatrix
**Status:** VERIFIED
**Goal:** Verifizierten lokalen/remote Ausgangszustand, Verträge, Risiken und 40-Batch-Plan dauerhaft festhalten.
**Files:** Create `docs/plans/2026-08-14-habiter-1a-modernization.md`.
**Behavior preserved:** Keine Produktänderung.
**Tests first:** Baseline-Gates unverändert ausführen und Fehler erfassen.
**Implementation steps:** 1. Git/GH preflight. 2. Tree, Historie, CI, Modelle, Plattformen und Landing prüfen. 3. Toolchains und Gates messen. 4. ADRs und Plan dokumentieren.
**Commands:** `git diff --check`; `git status --short`; Plan-Strukturprüfung per `rg`.
**Expected result:** Vollständige Source of Truth mit genau einem IN_PROGRESS-Batch.
**Acceptance criteria:** [x] 25 Pflichtsektionen [x] 40 Batches [x] Base/Branch/Baseline korrekt [x] keine Produktdatei im Commit.
**Migration/Rollback risk:** Keines; Dokumentcommit rücksetzbar.
**Commit:** `docs(modernization): capture verified baseline`

### Batch 02: Characterization Tests für Domain und Legacy-Payloads
**Status:** VERIFIED
**Goal:** Bestehende JSON-, Entry-, Streak- und Settings-Semantik vor Refactor einfrieren.
**Files:** Create `test/fixtures/legacy/*.json`, `test/domain/habit_legacy_test.dart`, `test/core/persistence/legacy_payload_test.dart`; Modify `lib/models/habit.dart` nur für testbare Parser-Grenzen.
**Behavior preserved:** Alle aktuellen Felder und Defaults werden explizit charakterisiert.
**Tests first:** Failing Fixtures für Reminder/Schedule-Roundtrip, unknown fields und leere Daten.
**Implementation steps:** Fixture laden; Altverhalten messen; verlustbehaftete Stellen als erwartete spätere Fixes markieren.
**Commands:** `flutter test test/domain test/core/persistence`; `flutter analyze`; `git diff --check`.
**Expected result:** Reale Legacy-Fixtures und deterministische Verträge.
**Acceptance criteria:** [ ] alte Payloads lesbar [ ] kein Mock-Habit als erwarteter Vertrag [ ] Risiken dokumentiert.
**Migration/Rollback risk:** Tests dürfen Fehler sichtbar machen, noch keine Daten ändern.
**Commit:** `test(domain): lock in existing habit behavior`

### Batch 03: Toolchain-ADR und reproduzierbare Versionen
**Status:** VERIFIED
**Goal:** Flutter/Java/Node/pnpm kompatibel pinnen und Lockfiles reproduzierbar machen.
**Files:** Create `.fvmrc` oder `.tool-versions`; Modify `pubspec.yaml`, `pubspec.lock`, `landing_page/package.json`, `landing_page/pnpm-workspace.yaml`, Workflows, README; generated registrants nur durch Tools.
**Behavior preserved:** Keine Produktänderung.
**Tests first:** Lockfile-/Version-Konsistenztest.
**Implementation steps:** Upstream-Kompatibilität dokumentieren; minimal sinnvolle Upgrades; pnpm allowBuilds explizit; Release-Signing lokal fail-safe.
**Commands:** `flutter pub get`; `pnpm install --frozen-lockfile`; Versionscript; Debug/Release-Build.
**Expected result:** Identische Toolchain lokal/CI, kein untracked Lockfile.
**Acceptance criteria:** [x] Pins konsistent [x] Signing ohne Secrets prüfbar [x] Generator-Diffs erklärt.
**Migration/Rollback risk:** Dependency-API-Brüche; einzeln upgraden.
**Commit:** `build(toolchain): align flutter node and java versions`

### Batch 04: CI-Konsolidierung
**Status:** VERIFIED
**Goal:** Doppelte/missverständliche Workflows durch klare Flutter-, Landing-, Docs- und Plattformjobs ersetzen.
**Files:** Modify/Delete `.github/workflows/*.yml`; Modify `.github/workflows/README.md`.
**Behavior preserved:** PRs bauen und testen, Releases entstehen nicht aus PRs.
**Tests first:** YAML-/Trigger-/Pin-Integritätstests.
**Implementation steps:** Concurrency, Cache, Least Privilege, echte Summary, Artifact-Namen, Signing-Gates.
**Commands:** lokale YAML-Prüfung; `gh workflow list`; `git diff --check`.
**Expected result:** Drei Qualitätsworkflows plus klar getrennte Plattformbuilds.
**Acceptance criteria:** [x] keine Placebo-Gates [x] keine Release-Aktion auf PR [x] konsistente Pins.
**Migration/Rollback risk:** Required Checks extern nicht ändern; im PR empfehlen.
**Commit:** `ci: replace duplicated and misleading workflows`

### Batch 05: Deterministische Fakes und Fixtures
**Status:** VERIFIED
**Goal:** Clock, UUID, Storage, Notifications und Platform Channel testbar injizieren.
**Files:** Create `lib/core/time/clock.dart`, `lib/core/ids/id_generator.dart`, `test/support/fakes/*.dart`; Modify Testsetup.
**Behavior preserved:** Produktionsadapter liefern weiter reale Zeit/UUID.
**Tests first:** Fakes müssen festgelegte Zeit/IDs/Calls reproduzieren.
**Implementation steps:** kleine Interfaces; Recording Fakes; keine Flutter-Abhängigkeit in Domain.
**Commands:** `flutter test test/support test/core`; `flutter analyze`.
**Expected result:** Deterministische Testbasis.
**Acceptance criteria:** [x] keine fachlichen `DateTime.now()` in neuen Tests [x] Plugin-Calls prüfbar.
**Migration/Rollback risk:** Keines.
**Commit:** `test(core): add deterministic platform and storage fakes`

### Batch 06: Explizites Domain- und Schedule-Modell
**Status:** VERIFIED
**Goal:** Daily, Weekdays und X-mal-pro-Woche als validierte Value Objects definieren.
**Files:** Create `lib/features/habits/domain/*.dart`; Modify legacy `lib/models/habit.dart`; Create Domain Tests.
**Behavior preserved:** Alte Frequenzwerte migrieren ohne Bedeutungsverlust.
**Tests first:** Occurrences, Weekday-Grenzen, invalid targets, pause/archive.
**Implementation steps:** Value Objects; adapters; typed source metadata; immutable copy semantics.
**Commands:** `flutter test test/features/habits/domain`; `flutter analyze`.
**Expected result:** Zentrale Schedule-Semantik.
**Acceptance criteria:** [x] alle Legacy-Varianten [x] unbekannte Source-Metadaten roundtrippable [x] keine UI-Typen.
**Migration/Rollback risk:** Semantikmapping; Fixtures decken zurück.
**Commit:** `refactor(domain): define explicit habit schedules`

### Batch 07: Repository-Abstraktion
**Status:** VERIFIED
**Goal:** Habit/Entry-Operationen über atomaren Repository-Vertrag führen.
**Files:** Create `lib/features/habits/application/habit_repository.dart`, `lib/core/persistence/*.dart`; Modify Provider schrittweise.
**Behavior preserved:** CRUD/Entries verhalten sich gleich.
**Tests first:** InMemoryRepository CRUD, concurrency und unknown-field preservation.
**Implementation steps:** Result-/Error-Typen; transactional mutate; SharedPreferences Adapter.
**Commands:** Repository-Tests; full Flutter tests.
**Expected result:** Widgets kennen StorageService nicht.
**Acceptance criteria:** [x] atomare API [x] typisierte Fehler [x] injizierbarer SharedPreferences-Adapter.
**Migration/Rollback risk:** Parallelwrites; serialisierte Mutationen.
**Commit:** `refactor(data): introduce habit repositories`

### Batch 08: Versionierte Datenmigration
**Status:** VERIFIED
**Goal:** Schema-Version, Backup, Quarantäne und idempotente Migration einführen.
**Files:** Create `lib/core/persistence/migrations/*.dart`, `lib/core/persistence/storage_envelope.dart`; tests/fixtures; Modify adapter.
**Behavior preserved:** Alle gültigen alten Daten bleiben erhalten.
**Tests first:** v0→v1, Wiederholung, Korruption, unbekannte Felder, Rollback.
**Implementation steps:** Raw backup; validate; migrate temp; verify; commit; retain recovery metadata.
**Commands:** Migration tests; full Flutter tests.
**Expected result:** Verlustfreie, wiederholbare Migration.
**Acceptance criteria:** [x] Backup vor Write [x] corrupt isolation [x] idempotent [x] unbekannte Felder erhalten.
**Migration/Rollback risk:** Höchster Datenrisiko-Batch; kein Commit ohne Fixture-Gates.
**Commit:** `feat(data): migrate legacy local records safely`

### Batch 09: App-Bootstrap und Dependency Graph
**Status:** VERIFIED
**Goal:** Explizite Composition Root statt statischer Singletons.
**Files:** Create `lib/app/bootstrap.dart`, `lib/app/dependencies.dart`; Modify `lib/main.dart`; tests.
**Behavior preserved:** App startet auf allen Zielplattformen.
**Tests first:** Bootstrap ohne optionale Integrationen, Fehlerzustand und Restore.
**Implementation steps:** Adapter verdrahten; startup phases; redigierte diagnostics.
**Commands:** widget/bootstrap tests; analyze; web/debug build.
**Expected result:** Optionale Dienste nicht im Cold Start.
**Acceptance criteria:** [x] keine Classly-Initialisierung [x] injizierbare Startup-Tasks/Adapter [x] nachvollziehbare, redigierte und retrybare Startup-Fehler.
**Migration/Rollback risk:** Startregression; Shell-Test schützt.
**Commit:** `refactor(app): introduce explicit dependency graph`

### Batch 10: Featurebezogener State
**Status:** VERIFIED
**Goal:** Monolithischen HabitProvider in kleine Feature-Controller teilen.
**Files:** Create `lib/features/{today,habits,history,analytics}/application/*_controller.dart`; Modify Provider/UI.
**Behavior preserved:** alle Mutationen und Updates.
**Tests first:** Controller state transitions und Fehler.
**Implementation steps:** Use Cases extrahieren; immutable view states; Provider nur Adapter.
**Commands:** controller tests; full Flutter tests/analyze.
**Expected result:** keine God-State-Klasse.
**Acceptance criteria:** [x] maximal kohäsive Controller [x] keine leeren catches [x] Loading/Error/Empty typisiert.
**Migration/Rollback risk:** Listener-Reihenfolge; Widgettests.
**Commit:** `refactor(state): split monolithic app state`

### Batch 11: Adaptive Navigation und Shell
**Status:** VERIFIED
**Goal:** Mobile, Tablet, Desktop, Web mit konsistenter Navigation und Deep Links.
**Files:** Create `lib/app/navigation/*`, `lib/app/shell/*`; Modify `home_screen.dart`, `main.dart`; tests.
**Behavior preserved:** Today/Analytics/App Lock/Settings erreichbar.
**Tests first:** Breakpoints, keyboard, route restore, deep links.
**Implementation steps:** NavigationBar/Rail; focus order; route codec.
**Commands:** widget/semantics tests; web/windows build.
**Expected result:** adaptive Shell ohne Overflow.
**Acceptance criteria:** [x] 320px bis Desktop [x] Keyboard [x] richtige Back-Semantik und kanonische Route-Restoration.
**Migration/Rollback risk:** Navigation state.
**Commit:** `feat(navigation): add adaptive application shell`

### Batch 12: Habiter Design System
**Status:** NOT_STARTED
**Goal:** Farb-, Typo-, Spacing-, Shape- und State-Tokens in ruhiger organischer Sprache.
**Files:** Create `lib/core/design_system/*`; Modify `app_theme.dart`; token/golden tests.
**Behavior preserved:** Light/Dark/System.
**Tests first:** Contrast/token completeness/theme snapshots.
**Implementation steps:** ColorScheme; high contrast; component themes; remove scattered Hex schrittweise.
**Commands:** golden/semantics tests; analyze.
**Expected result:** ein kohärentes System.
**Acceptance criteria:** [ ] Light/Dark/High Contrast [ ] Text scaling [ ] platform targets.
**Migration/Rollback risk:** Golden drift.
**Commit:** `feat(design): introduce accessible habiter tokens`

### Batch 13: Motion und Haptics
**Status:** NOT_STARTED
**Goal:** Ruhige Feedback-Tokens mit Reduced Motion und injizierbaren Haptics.
**Files:** Create `lib/core/design_system/motion.dart`, `haptics.dart`; Modify completion widgets/particles; tests.
**Behavior preserved:** Abschlussfeedback bleibt.
**Tests first:** reduced-motion zero/short durations, no haptic unsupported.
**Implementation steps:** zentrale Kurven/Dauern; Partikelbudget; adapter.
**Commands:** widget tests; profile sanity.
**Expected result:** proportionale, performante Motion.
**Acceptance criteria:** [ ] Reduced Motion [ ] keine unbounded controller [ ] haptics optional.
**Migration/Rollback risk:** visuell; Goldens.
**Commit:** `feat(motion): add reduced-motion aware feedback`

### Batch 14: Consent-first Onboarding und Empty States
**Status:** NOT_STARTED
**Goal:** Freiwilliger erster Erfolg ohne Mock-Daten oder Permission-Prompt.
**Files:** Create `lib/features/onboarding/*`; Modify bootstrap/today; l10n/tests.
**Behavior preserved:** bestehende Nutzer überspringen Onboarding.
**Tests first:** empty storage, migrated storage, restart, DE/EN.
**Implementation steps:** value choice; micro-habit; explicit reminder later.
**Commands:** widget/semantics tests.
**Expected result:** ehrlicher Empty State und schneller Add-Flow.
**Acceptance criteria:** [ ] kein Seed [ ] keine Permissions beim Start [ ] skip/back möglich.
**Migration/Rollback risk:** first-run flag.
**Commit:** `feat(onboarding): create consent-first first run`

### Batch 15: Today Dashboard
**Status:** NOT_STARTED
**Goal:** Geplante heutige Habits fokussiert, zugänglich und responsive darstellen.
**Files:** Create/Modify `lib/features/today/presentation/*`; retire passende alte Widgets; tests.
**Behavior preserved:** Completion/Details/Navigation.
**Tests first:** scheduled filtering, empty/completed/recovery states, scaling.
**Implementation steps:** Today query; progress; one primary action; honest copy.
**Commands:** widget/golden/semantics tests.
**Expected result:** ruhiger daily focus.
**Acceptance criteria:** [ ] one-tap [ ] ungeplante Habits getrennt [ ] kein toxischer Zustand.
**Migration/Rollback risk:** Filtersemantik.
**Commit:** `feat(today): redesign daily habit focus`

### Batch 16: Habit Create/Edit Flow
**Status:** NOT_STARTED
**Goal:** Ein validierter, zugänglicher Editor für alle Schedules und Reminder.
**Files:** Create `lib/features/habits/presentation/editor/*`; replace `add_habit_sheet.dart`; l10n/tests.
**Behavior preserved:** alle bestehenden Felder editierbar.
**Tests first:** validation, custom days, reminder, long DE, keyboard.
**Implementation steps:** progressive fields; micro-habit defaults only after choice; save use case.
**Commands:** widget tests; analyze.
**Expected result:** keine Felder gehen beim Edit verloren.
**Acceptance criteria:** [ ] create/edit parity [ ] cancel safe [ ] schedule preview.
**Migration/Rollback risk:** form mapping.
**Commit:** `feat(habits): rebuild habit editor`

### Batch 17: Durable Completion und Undo
**Status:** NOT_STARTED
**Goal:** Idempotente atomare Completion mit sofortigem Undo.
**Files:** Create completion use cases; Modify Today/details; tests.
**Behavior preserved:** ein Entry pro Habit/Occurrence.
**Tests first:** double tap, undo, target counts, midnight, write failure.
**Implementation steps:** occurrence key; optimistic UI mit rollback; reminder/app-lock events.
**Commands:** use-case/widget tests.
**Expected result:** keine Doppelentries oder verlorenes Undo.
**Acceptance criteria:** [ ] idempotent [ ] failure recovery [ ] haptic once.
**Migration/Rollback risk:** Entry-Key-Mapping.
**Commit:** `feat(habits): make completion durable and reversible`

### Batch 18: History, Pause und Archive
**Status:** NOT_STARTED
**Goal:** Verzeihender Lifecycle mit Pause/Wiederaufnahme/Archiv und Historie.
**Files:** Create `lib/features/history/*`; extend domain/migration; tests.
**Behavior preserved:** Archive/Delete/History.
**Tests first:** pause ranges, archive restore, delete confirmation, reminder cancel.
**Implementation steps:** lifecycle metadata; timeline; safe destructive dialogs.
**Commands:** domain/widget tests.
**Expected result:** Rückkehr ohne Bestrafung.
**Acceptance criteria:** [ ] Pause beeinflusst Metrics [ ] Restore möglich [ ] Delete explizit.
**Migration/Rollback risk:** neue optionale Felder.
**Commit:** `feat(history): add forgiving habit lifecycle`

### Batch 19: Schedule-aware Analytics
**Status:** NOT_STARTED
**Goal:** Streak, Rate und Wochenwerte nur gegen geplante Occurrences rechnen.
**Files:** Create analytics domain/application; replace `analytics_screen.dart`; tests.
**Behavior preserved:** klassische Streaks bleiben sichtbar.
**Tests first:** daily/weekly/custom/pause/timezone/leap-day.
**Implementation steps:** pure calculators; accessible charts; textual equivalents.
**Commands:** analytics tests; golden/semantics.
**Expected result:** mathematisch nachvollziehbare Kennzahlen.
**Acceptance criteria:** [ ] denominator korrekt [ ] no fake prediction [ ] chart labels.
**Migration/Rollback risk:** Werte ändern korrekt; im PR erklären.
**Commit:** `refactor(analytics): calculate schedule-aware metrics`

### Batch 20: Unterstützende Recovery States
**Status:** NOT_STARTED
**Goal:** Optionalen verzeihenden Habit Score und freundliche Rückkehrtexte ergänzen.
**Files:** Create coaching domain/presentation; l10n/tests.
**Behavior preserved:** Streakdaten unverändert.
**Tests first:** score is derived only; no shame copy; paused days neutral.
**Implementation steps:** transparent formula; opt-out; recovery messages.
**Commands:** domain/content tests.
**Expected result:** Progress ohne Manipulation.
**Acceptance criteria:** [ ] keine historischen Writes [ ] Formel erklärt [ ] DE/EN.
**Migration/Rollback risk:** Produktcopy.
**Commit:** `feat(coaching): add non-punitive recovery states`

### Batch 21: Notification-Adapter und ID-Registry
**Status:** NOT_STARTED
**Goal:** Plugin hinter Interface und stabile persistierte IDs bringen.
**Files:** Create `lib/features/reminders/{domain,application,infrastructure}/*`; migration/tests; phase out old service.
**Behavior preserved:** global/habit reminder migrierbar.
**Tests first:** stable IDs, collision, delete/recreate, pending reconciliation.
**Implementation steps:** registry repository; adapter; payload schema.
**Commands:** reminder tests; analyze.
**Expected result:** keine Dart-hashCode IDs.
**Acceptance criteria:** [ ] stable across restart [ ] no duplicates [ ] typed payload.
**Migration/Rollback risk:** alte pending notifications zunächst cancel/reconcile.
**Commit:** `refactor(reminders): add stable notification registry`

### Batch 22: Device-Timezone und DST
**Status:** NOT_STARTED
**Goal:** Gerätezeitzone erkennen und Occurrences DST-sicher berechnen.
**Files:** Add compatible timezone adapter dependency; Create timezone service/tests; Modify platform setup.
**Behavior preserved:** lokale Uhrzeit bleibt Nutzerintention.
**Tests first:** Berlin/NY/Kolkata, gaps/overlaps, timezone changes.
**Implementation steps:** initialize DB; resolve device TZ; fallback/error; reschedule trigger.
**Commands:** fake-clock/TZ tests.
**Expected result:** kein `Europe/Berlin` hardcode.
**Acceptance criteria:** [ ] DST matrices [ ] unknown TZ safe [ ] change event handled.
**Migration/Rollback risk:** Platform plugin support.
**Commit:** `fix(reminders): schedule in the device timezone`

### Batch 23: Respectful Permission State Machine
**Status:** NOT_STARTED
**Goal:** Android/iOS Permissionzustände ohne Prompt-Schleife abbilden.
**Files:** Create permission adapter/controller/UI; Modify Android/iOS config; tests.
**Behavior preserved:** Nutzer kann Reminder aktivieren/testen.
**Tests first:** unknown/denied/permanently denied/granted/exact unavailable.
**Implementation steps:** ask only after intent; settings deep link; inexact default.
**Commands:** adapter/widget/config tests.
**Expected result:** transparente Permission UX.
**Acceptance criteria:** [ ] Android 13 [ ] iOS [ ] no repeated prompts [ ] exact not required.
**Migration/Rollback risk:** OS differences.
**Commit:** `feat(reminders): add respectful permission flow`

### Batch 24: Daily/Weekly/Custom Scheduler
**Status:** NOT_STARTED
**Goal:** Alle Schedules occurrence-aware, kapazitätsbewusst und duplikatfrei planen.
**Files:** Create scheduler/planner; Modify mutation use cases; tests.
**Behavior preserved:** Reminderzeiten und Frequenzen.
**Tests first:** all frequency modes, boundaries, iOS 64 cap, edits/archive/delete.
**Implementation steps:** plan next occurrences; reconcile pending; reschedule hooks.
**Commands:** scheduler/property tests.
**Expected result:** korrekte Reminder-Matrix.
**Acceptance criteria:** [ ] create/edit/delete hooks [ ] no duplicates [ ] cap strategy.
**Migration/Rollback risk:** pending replacement.
**Commit:** `feat(reminders): implement occurrence-aware schedules`

### Batch 25: Durable Notification Actions
**Status:** NOT_STARTED
**Goal:** Foreground-, Background- und Terminated-Actions dauerhaft/idempotent verarbeiten.
**Files:** Create action inbox/processor; Modify `main.dart`, Android/iOS init; tests.
**Behavior preserved:** „Done“-Action schließt richtigen Habit ab.
**Tests first:** isolate write, launch details, duplicate action, stale occurrence.
**Implementation steps:** `@pragma`; serializable inbox; startup drain; deep link.
**Commands:** action lifecycle tests; release build.
**Expected result:** keine verlorenen Background Actions.
**Acceptance criteria:** [ ] all 3 states [ ] current occurrence resolution [ ] redacted logs.
**Migration/Rollback risk:** isolate plugin availability.
**Commit:** `fix(reminders): process notification actions durably`

### Batch 26: Notification-QA und Diagnose
**Status:** NOT_STARTED
**Goal:** Testnotification, Permissionstatus, Pending-Liste und ehrliche OEM-Hinweise.
**Files:** Create reminder diagnostics UI/tests/docs.
**Behavior preserved:** Settingszugriff.
**Tests first:** diagnostics model, redaction, empty/error states.
**Implementation steps:** pending snapshot; test action; reschedule control; manual matrix.
**Commands:** reminder suite; Android debug/release; config tests.
**Expected result:** überprüfbare Reminder statt Blindflug.
**Acceptance criteria:** [ ] IDs/times visible safely [ ] no secrets [ ] manual gates labeled.
**Migration/Rollback risk:** keine sensiblen Payloaddetails zeigen.
**Commit:** `test(reminders): cover scheduling and action lifecycle`

### Batch 27: Typisierter App-Lock-Plattformvertrag
**Status:** NOT_STARTED
**Goal:** MethodChannel-Aufrufe, Capability und Fehler als injizierbaren Adapter typisieren.
**Files:** Create `lib/features/app_lock/...`; Modify old service/provider; Kotlin contract tests.
**Behavior preserved:** installierte Apps, Permissions, start/stop, completion sync.
**Tests first:** method names/arguments/results/errors/unsupported.
**Implementation steps:** sealed results; recovery state; fake messenger.
**Commands:** Dart method-channel tests; native unit tests.
**Expected result:** kein statischer Platform-Zugriff aus UI.
**Acceptance criteria:** [ ] full contract [ ] fail-open [ ] typed errors.
**Migration/Rollback risk:** channel compatibility.
**Commit:** `refactor(app-lock): type the native channel contract`

### Batch 28: Native App-Lock-Zuverlässigkeit
**Status:** NOT_STARTED
**Goal:** Polling, Lifecycle, Boot, Watchdog, Permissions und Policy deutlich verbessern.
**Files:** Modify Kotlin service/activity/receivers/manifest/Gradle; native tests.
**Behavior preserved:** gesperrte Apps blockieren, wenn alle Voraussetzungen erfüllt sind.
**Tests first:** service idempotence, prefs, boot disabled/enabled, interval policy.
**Implementation steps:** background dispatcher; adaptive interval; no duplicate callbacks; scoped package queries where viable; safe battery settings link.
**Commands:** Gradle unit/lint; APK debug/release.
**Expected result:** weniger Last und klarer Lifecycle.
**Acceptance criteria:** [ ] no 150ms main-loop [ ] no empty catch [ ] Play policy documented.
**Migration/Rollback risk:** OEM behavior; manual matrix bleibt offen.
**Commit:** `fix(app-lock): improve service and battery behavior`

### Batch 29: App-Lock UX und Recovery
**Status:** NOT_STARTED
**Goal:** Permission-, Enable-, Status- und Disable-/Recovery-Flow neu bauen.
**Files:** Replace `app_lock_screen.dart`; l10n/tests/docs.
**Behavior preserved:** App-Auswahl und completion-based unlock.
**Tests first:** missing permissions, failed service, disable, no apps, midnight.
**Implementation steps:** progressive consent; status cards; recovery action; OEM honesty.
**Commands:** widget/semantics tests; Android device checklist.
**Expected result:** kein dauerhafter Lockout.
**Acceptance criteria:** [ ] one-tap disable [ ] fail-open [ ] all permission states.
**Migration/Rollback risk:** Nutzerkonfiguration.
**Commit:** `feat(app-lock): rebuild permission and recovery flow`

### Batch 30: Classly Feature Flag und Lazy Loading
**Status:** NOT_STARTED
**Goal:** Integration wirklich default-off und außerhalb des Bootstraps machen.
**Files:** Modify `main.dart`, settings, provider; Create integration settings/repository/tests.
**Behavior preserved:** bestehende verbundene Nutzer werden explizit migriert.
**Tests first:** fresh install no provider/network/default URL; legacy connected migration.
**Implementation steps:** enabled flag; lazy composition; nested settings; disable/clear.
**Commands:** bootstrap/widget/network fake tests; `rg classly.site`.
**Expected result:** null Netzwerk ohne Opt-in.
**Acceptance criteria:** [ ] no root provider [ ] no default URL [ ] deep settings only.
**Migration/Rollback risk:** existing connections; token presence implies consent migration only with notice.
**Commit:** `refactor(classly): make integration explicit and lazy`

### Batch 31: Classly Security und Importmodell
**Status:** NOT_STARTED
**Goal:** Endpoint/Auth/Credentials und idempotente Eventimports härten.
**Files:** Modify Classly client/OAuth/provider/domain; secure storage/migration/tests.
**Behavior preserved:** bestehende importierte Habits bleiben.
**Tests first:** SSRF-like endpoints, timeout, redaction, PKCE/state, duplicate event ID, one-time events.
**Implementation steps:** HTTPS validation; Secure Storage; remove password flow; typed source metadata.
**Commands:** integration unit tests; secret-pattern scan.
**Expected result:** sichere optionale Kompatibilität.
**Acceptance criteria:** [ ] no password flow/client secret [ ] event ID idempotence [ ] disable clears credentials.
**Migration/Rollback risk:** OAuth server compatibility; ehrlich dokumentieren.
**Commit:** `fix(classly): harden auth and idempotent imports`

### Batch 32: AI-Integration isolieren
**Status:** NOT_STARTED
**Goal:** Zufalls-Stub als experimentelle lokale Coaching-Funktion ehrlich kapseln; Key-Migration sichern.
**Files:** Replace `ai_manager.dart`, setup UI; secure storage/migration/l10n/tests.
**Behavior preserved:** vorhandene Nutzer verlieren Config nicht still.
**Tests first:** default-off/no request, key not in SharedPreferences, deterministic coaching, clear.
**Implementation steps:** separate local coaching from remote AI; provider/cost copy; timeout/cancel contract.
**Commands:** tests; storage secret scan.
**Expected result:** keine irreführende „AI“-Behauptung.
**Acceptance criteria:** [ ] no random insights [ ] no plaintext key [ ] experimental label.
**Migration/Rollback risk:** alte Keymigration mit Löschung erst nach Secure-Write.
**Commit:** `refactor(ai): isolate experimental ai capabilities`

### Batch 33: Progressive Settings
**Status:** NOT_STARTED
**Goal:** Settings in Appearance, Reminders, Privacy/Data, App Lock und Advanced Integrations strukturieren.
**Files:** Replace `settings_screen.dart`; feature settings components; l10n/tests.
**Behavior preserved:** alle realen Einstellungen bleiben.
**Tests first:** navigation, persistence, long DE, keyboard, unsupported platform.
**Implementation steps:** route sections; status summaries; destructive actions separated.
**Commands:** widget/semantics/golden tests.
**Expected result:** keine 866-Zeilen-God-Screen.
**Acceptance criteria:** [ ] Classly/AI hidden advanced [ ] no overflow [ ] clear privacy.
**Migration/Rollback risk:** preference mapping.
**Commit:** `feat(settings): organize progressive preferences`

### Batch 34: Export, Import, Backup und Reset
**Status:** NOT_STARTED
**Goal:** Nutzerkontrollierte atomare Datenportabilität mit Preview und Restore.
**Files:** Create `lib/features/data_portability/*`; platform file adapter; tests/docs.
**Behavior preserved:** alle Domain-/Settingsdaten exportierbar; Secrets ausgeschlossen.
**Tests first:** roundtrip, corrupt, future schema, collision, cancel, atomicity.
**Implementation steps:** versioned export; preview; backup-before-import; explicit reset.
**Commands:** portability tests; platform capability tests.
**Expected result:** sichere Selbstkontrolle.
**Acceptance criteria:** [ ] no tokens [ ] rollback [ ] unknown fields [ ] explicit reset confirm.
**Migration/Rollback risk:** Dateizugriff je Plattform.
**Commit:** `feat(data): add safe user-controlled portability`

### Batch 35: Server-first Landing Foundation
**Status:** NOT_STARTED
**Goal:** Next 16.3.x kompatibel, server-first, typisierte i18n, Security Header und Testtooling.
**Files:** Modify package/lock/config/layout; Create dictionaries, env validation, Vitest/Playwright config, CI.
**Behavior preserved:** `/de`, `/en`, live, Legal.
**Tests first:** locale routing, metadata, headers, build without Supabase env.
**Implementation steps:** server layouts; central dictionaries; CSP; loading/error/not-found.
**Commands:** `pnpm lint`; `pnpm exec tsc --noEmit`; `pnpm test`; `pnpm build`.
**Expected result:** grüne server-first Foundation.
**Acceptance criteria:** [ ] no duplicate dictionaries [ ] no env crash [ ] minimal client JS.
**Migration/Rollback risk:** Next minor changes.
**Commit:** `refactor(web): build server-first landing foundation`

### Batch 36: Neue Landingpage Experience
**Status:** NOT_STARTED
**Goal:** Eigenständige, responsive, ehrliche Habiter-Markenwelt umsetzen.
**Files:** Replace locale page/global CSS/components; add optimized real assets/screenshots; tests.
**Behavior preserved:** Locale, primary CTA, feature/live/legal navigation.
**Tests first:** content contracts, responsive nav, keyboard, reduced motion.
**Implementation steps:** hero; product rhythm; feature matrix; platform availability; privacy story.
**Commands:** Vitest/Playwright; screenshots; Lighthouse preview.
**Expected result:** hochwertige organische Seite ohne Template-Look.
**Acceptance criteria:** [ ] one CTA [ ] honest claims [ ] real screens [ ] no fake proof.
**Migration/Rollback risk:** reale Screenshot-Erstellung benötigt Build/Device; transparent kennzeichnen.
**Commit:** `feat(web): launch the new habiter product story`

### Batch 37: Ehrliche Demo, SEO und Performance
**Status:** NOT_STARTED
**Goal:** Lokale Demo, Metadaten, JSON-LD, Sitemap/Robots/Canonicals und Budgets finalisieren.
**Files:** Refactor live route; metadata files; tests/perf config.
**Behavior preserved:** Live-Demo bleibt ohne Backend nutzbar.
**Tests first:** demo state, locale SEO, 404, image dimensions.
**Implementation steps:** client island minimieren; structured data; OG/Twitter; audit.
**Commands:** Playwright routes; Lighthouse; bundle inspect.
**Expected result:** >=95 Zielwerte oder belegte Restpunkte.
**Acceptance criteria:** [ ] no false claims [ ] all metadata [ ] performance logged.
**Migration/Rollback risk:** Lighthouse-Umgebung dokumentieren.
**Commit:** `feat(web): add honest demo and search metadata`

### Batch 38: Beta, Feedback, Test und Admin vollständig entfernen
**Status:** NOT_STARTED
**Goal:** Alle zugehörigen Routen, Komponenten, Styles, Übersetzungen, Modelle, Env-Variablen und Supabase-Dependency löschen.
**Files:** Delete `landing_page/app/admin`, `[locale]/feedback`, `[locale]/test`, `lib/supabase.ts`; Modify Header/Footer/i18n/package/lock/docs/tests.
**Behavior preserved:** Legal-Routen und allgemeine Download-CTAs.
**Tests first:** Referenzinventar; Routing erwartet 404; Legal/CTA bleiben.
**Implementation steps:** `rg` vor/nach; delete exact scope; remove dependency; lockfile regenerate; dead-code tests.
**Commands:** `rg -n "beta|feedback|admin|supabase" landing_page docs README.md`; full landing suite/build.
**Expected result:** keine Funktion oder Supabase-Laufzeitabhängigkeit übrig.
**Acceptance criteria:** [ ] routes 404 [ ] package removed [ ] no env refs [ ] legal passes.
**Migration/Rollback risk:** Externe alte Links werden 404; bewusst angefordert.
**Commit:** `chore(web): remove beta feedback and admin surfaces`

### Batch 39: Legacy- und Dokumentations-Cleanup
**Status:** NOT_STARTED
**Goal:** Nach Referenzprüfung tote Widgets, Assets, Services, Claims und veraltete Docs entfernen.
**Files:** Delete verified legacy/template assets; Modify README/VitePress/architecture/privacy/app-lock/reminders.
**Behavior preserved:** Core/Legal.
**Tests first:** asset/reference/config/dead-code scans.
**Implementation steps:** `rg` each target; remove; regenerate; document limits and setup.
**Commands:** full Flutter/Landing/Docs suites; secret/license scans.
**Expected result:** wartbares, ehrliches Repo.
**Acceptance criteria:** [ ] no Next/Vercel template SVG [ ] no old God classes referenced [ ] README current.
**Migration/Rollback risk:** nur nach Referenznachweis löschen.
**Commit:** `chore(repo): remove verified legacy and update docs`

### Batch 40: Release Candidate, Evidenz und PR
**Status:** NOT_STARTED
**Goal:** Alle Gates, Screenshots, Performance, Ledger, Push und reviewbereite PR abschließen.
**Files:** Modify Plan Final Handoff/PR evidence; Create screenshots/reports nur wenn repo-sinnvoll.
**Behavior preserved:** kein Merge, Release oder Deployment.
**Tests first:** full verification matrix und clean clone/lockfile sanity.
**Implementation steps:** all suites/builds; audits; device gates label; ledger commit; push; `gh pr create`; checks watch/fix.
**Commands:** vollständige Gates aus Abschnitt 20; `gh pr checks --watch`.
**Expected result:** reviewbereite PR mit >=30 echten Batch-Commits und grünen verfügbaren Checks.
**Acceptance criteria:** [ ] clean status [ ] Base/Head [ ] PR body 24 Abschnitte [ ] not merged/deployed.
**Migration/Rollback risk:** PR enthält Rollback/known risks; kein produktiver Eingriff.
**Commit:** `chore(release): finalize modernization candidate`

## 19. Fortschrittstabelle

| Batch | Scope | Status | Tests | Commit | Risiken | Nächster Schritt |
|---|---|---|---|---|---|---|
| 01 | Baseline/Plan | VERIFIED | `Batches=40`; `Sections=25`; `InProgressRows=1`; `git diff --check` PASS | `8b8eedb` | keine | abgeschlossen |
| 02 | Characterization | VERIFIED | Red: Reminder/Custom Days blieben alt; Green: 7 targeted + 11 full tests, analyze PASS | `3630ce8` | unknown fields folgen Migration | abgeschlossen |
| 03 | Toolchain | VERIFIED | Red: 3 Pin-Gates + Signing; Green: 6 targeted, 15 full, analyze/format/install/release PASS | `7152983` | APK bewusst unsigned ohne Keystore | abgeschlossen |
| 04 | CI | VERIFIED | Red: 4 Workflow-Verträge; Green: 5 targeted + 20 full, YAML/Docs build PASS | `24de94a` | Landing bleibt baseline-rot; Required Checks extern | abgeschlossen |
| 05 | Fakes | VERIFIED | Red: fehlende Ports/Fakes; Green: 5 targeted + 25 coverage, format/analyze/builds PASS | `349d29e` | Landing baseline-rot | abgeschlossen |
| 06 | Domain/Schedules | VERIFIED | Red: fehlende Domain; Green: 10 targeted + 35 full, format/analyze PASS | `85b2737` | Habit-Payload-Extras folgen Batch 08 | abgeschlossen |
| 07 | Repository | VERIFIED | Red: fehlende Repository/Adapter; Green: 7 targeted + 42 full, analyze PASS | `6ef5c15` | v0 Extras/Envelope folgen Batch 08 | abgeschlossen |
| 08 | Migration | VERIFIED | Red: fehlende Migration; Green: 9 targeted + 46 full, analyze PASS | `10fa73a` | Legacy-Keys bleiben als Rollback-Quelle | abgeschlossen |
| 09 | Bootstrap/DI | VERIFIED | Red: fehlende Bootstrap-Verträge; Green: 3 targeted + 49 full, analyze/web-debug PASS | `b64b11e` | Secure-Storage-Wasm-Warnung bleibt | abgeschlossen |
| 10 | Feature State | VERIFIED | Red: 4 Controller fehlten; Green: 3 targeted + 52 full, analyze PASS | `6d9b35f` | Provider bleibt temporäre UI-Fassade | abgeschlossen |
| 11 | Navigation | VERIFIED | Red: Codec/Shell fehlten; Green: 4 targeted + 56 full, analyze/web/windows PASS | pending | System-Routen bleiben Navigator-basiert | SHA im Batch-12-Preflight nachtragen |
| 12 | Design | NOT_STARTED | pending | pending | visual drift | tokens |
| 13 | Motion/Haptics | NOT_STARTED | pending | pending | performance | reduced motion |
| 14 | Onboarding | NOT_STARTED | pending | pending | first-run | empty state |
| 15 | Today | NOT_STARTED | pending | pending | filtering | dashboard |
| 16 | Editor | NOT_STARTED | pending | pending | field mapping | create/edit |
| 17 | Completion | NOT_STARTED | pending | pending | races | idempotency |
| 18 | History/Lifecycle | NOT_STARTED | pending | pending | pause semantics | lifecycle |
| 19 | Analytics | NOT_STARTED | pending | pending | metric changes | calculators |
| 20 | Recovery | NOT_STARTED | pending | pending | copy | score |
| 21 | Reminder Registry | NOT_STARTED | pending | pending | pending cleanup | IDs |
| 22 | TZ/DST | NOT_STARTED | pending | pending | platform TZ | adapter |
| 23 | Permissions | NOT_STARTED | pending | pending | OS variance | state machine |
| 24 | Scheduler | NOT_STARTED | pending | pending | iOS cap | planner |
| 25 | Actions | NOT_STARTED | pending | pending | isolates | inbox |
| 26 | Reminder QA | NOT_STARTED | pending | pending | sensitive data | diagnostics |
| 27 | App Lock Contract | NOT_STARTED | pending | pending | channel | typed adapter |
| 28 | Native App Lock | NOT_STARTED | pending | pending | OEM/policy | lifecycle |
| 29 | App Lock UX | NOT_STARTED | pending | pending | lockout | recovery |
| 30 | Classly Lazy | NOT_STARTED | pending | pending | existing users | feature flag |
| 31 | Classly Security | NOT_STARTED | pending | pending | OAuth compatibility | hardening |
| 32 | AI Isolation | NOT_STARTED | pending | pending | key migration | experimental |
| 33 | Settings | NOT_STARTED | pending | pending | mapping | sections |
| 34 | Portability | NOT_STARTED | pending | pending | import safety | export/import |
| 35 | Web Foundation | NOT_STARTED | pending | pending | Next migration | server-first |
| 36 | Web Experience | NOT_STARTED | pending | pending | real assets | rebuild |
| 37 | Demo/SEO/Perf | NOT_STARTED | pending | pending | lab variance | audit |
| 38 | Remove Beta/Admin | NOT_STARTED | pending | pending | old links 404 | remove all refs |
| 39 | Cleanup/Docs | NOT_STARTED | pending | pending | accidental delete | reference checks |
| 40 | RC/PR | NOT_STARTED | pending | pending | external gates | verify/push/PR |

## 20. Test- und Verifikationslog

Die unveränderte Baseline steht in Abschnitt 6. Nach jedem Batch werden hier Datum, exakter Befehl, Exit-Code und relevantes Ergebnis ergänzt. Alle fünf Batches: volle Flutter- und Landing-Suite, relevante Builds, Branch-Push und Risiko-Review.

- 2026-08-14, Batch 01: `Select-String '^### Batch \d{2}:'` → 40; `Select-String '^## \d+\.'` → 25; Fortschrittstabelle → genau ein `IN_PROGRESS`; `git diff --check` → Exit 0; Worktree nach Isolierung der durch Baseline-Tools erzeugten No-op-Änderungen enthält ausschließlich das neue Plan-Dokument.
- 2026-08-14, Batch 02 Red: `flutter test test/domain/habit_legacy_test.dart test/core/persistence/legacy_payload_test.dart` → Exit 1; erwarteter Fehler: `customDays` blieb `[1,3,5]` statt `[2,4,6]`. Ein zusätzlicher Testvergleich wurde von Objektidentität auf serialisierte Maps korrigiert.
- 2026-08-14, Batch 02 Green: derselbe Target-Befehl → 7/7 PASS; formatierte Touched-Files → 0 Änderungen; `flutter analyze` → no issues; `flutter test` → 11/11 PASS.
- 2026-08-14, Batch 03 Red: `flutter test test/toolchain_integrity_test.dart` → `.fvmrc` fehlte, Workflows nutzten 3.24.5/3.27.0, pnpm Policy fehlte; `flutter test test/config_integrity_test.dart` → Release-Signing war zwingend.
- 2026-08-14, Batch 03 Green: pnpm 11.21.0 frozen install inklusive erlaubter nativer Builds PASS; 6/6 Toolchain/Config Tests PASS; `flutter build apk --release` PASS (56.7 MB, ohne Keystore bewusst unsigned; `apksigner` meldet `DOES NOT VERIFY`); `dart format .` normalisierte 31 Dateien, danach Formatcheck 39/39 ohne Änderung; `flutter analyze` no issues; `flutter test` 15/15 PASS.
- 2026-08-14, Batch 04 Red: `flutter test test/ci_workflow_test.dart` → 4/4 FAIL für fünf Legacy-Workflows, fehlende Zielnamen, Permissions/Concurrency und Release-Aktionen.
- 2026-08-14, Batch 04 Green: 4 neue YAML-Workflows syntaktisch geprüft; Target 5/5 PASS; Format 40/40, Analyze no issues, Full Flutter 20/20 PASS; `npm ci` + `npm run docs:build` PASS mit VitePress 1.6.4. `npm audit` bleibt mit 3 transitiven Vite/esbuild Findings offen; Upstream latest stable 1.6.4 hat laut Audit keinen Fix, VitePress 2 ist am 2026-08-14 nur Alpha und wird nicht blind übernommen.
- 2026-08-14, Batch 05 Red: `flutter test test/support/deterministic_fakes_test.dart` → fehlende Clock/ID/Storage/Notification/Platform-Ports und Recording Fakes; nach Implementation ein typisierter Generic-Return-Compilefehler, anschließend minimal korrigiert.
- 2026-08-14, Batch 05 Green/Checkpoint: Target 5/5 PASS; Format 51/51; Analyze no issues; `flutter test --coverage` 25/25 PASS; APK Debug PASS; APK Release PASS (unsigned); Flutter Web PASS mit bekanntem Wasm-Hinweis aus `flutter_secure_storage_web`; Windows Release PASS. Landing: frozen install PASS, TypeScript PASS, Lint weiterhin 6 Errors/4 Warnings ausschließlich in später zu entfernenden Beta/Admin-Flächen plus alter i18n, Build weiterhin FAIL auf fehlender Supabase-URL in `/de/feedback`; kein `test`-Script vorhanden. Diese bekannten Landing-Gates werden in Batches 35–38 beseitigt.
- 2026-08-14, Batch 06 Red: Schedule-/LocalDate-Tests kompilierten wegen fehlender Domain nicht; ein initialer Hash-Implementierungsfehler wurde sichtbar und korrigiert.
- 2026-08-14, Batch 06 Green: 10/10 Domain Tests für Leap Dates, Validation, Daily, Weekdays, X-mal/Woche, Map-Roundtrip, alle Legacy-Varianten sowie unbekannte zukünftige Source-Kinds/-Felder; Analyze no issues, Full Flutter 35/35 PASS.
- 2026-08-14, Batch 07 Red: Repository-, Transaktions- und SharedPreferences-Adaptertests kompilierten wegen fehlender Grenzen nicht.
- 2026-08-14, Batch 07 Green: 7/7 Target Tests für Legacy-Key-Load, atomare Habit/Entry-Commits, Cascade Delete, Rollback nach zweitem Write-Fehler, serialisierte Concurrent Mutations und typsichere SharedPreferences-Werte; Analyze no issues, Full Flutter 42/42 PASS.
- 2026-08-14, Batch 08 Red: Migration-/Envelope-Tests kompilierten wegen fehlender Implementierung nicht; der absichtlich nicht vererbbare InMemory-Fake wurde korrekt über Composition adaptiert.
- 2026-08-14, Batch 08 Green: 9/9 Target Tests inklusive Raw-Backup, validiertem v1-Envelope, recordweiser Quarantäne, Backup-Failure-Fail-Closed, idempotenter Wiederholung, repositoryseitigem Envelope-Read/Single-Write und Unknown-Field-Merge; Full Flutter 46/46 PASS; Analyze no issues.
- 2026-08-14, Batch 09 Red: Bootstrap-Tests kompilierten ohne Composition Root, Dependency Graph, Startup-Phasen und Ergebnis-/Fehlertypen nicht.
- 2026-08-14, Batch 09 Green: 3/3 Target Tests beweisen Migration vor Repository-Verifikation, keinen optionalen Service im Cold Start sowie redigierten retrybaren Fehlerzustand; Classly-Autoload entfernt; Full Flutter 49/49 PASS; Analyze no issues; Web Debug PASS mit bekannter Secure-Storage-Wasm-Warnung.
- 2026-08-14, Batch 10 Red: Tests kompilierten ohne Today-, Habits-, History- und Analytics-Controller sowie typisierte Feature-States nicht.
- 2026-08-14, Batch 10 Green: 3/3 Target Tests für immutable/ordered Habit-State, deterministisches Toggle samt Refresh und read-only History/Analytics; HabitProvider delegiert als temporäre UI-Fassade an injizierte Controller; Full Flutter 52/52 PASS; Analyze no issues.
- 2026-08-14, Checkpoint 10: Format 73 Dateien, Analyze und Coverage 52/52 PASS; APK Debug, unsigned APK Release, Web Release und Windows Release PASS. Landing: Frozen Install/TypeScript PASS; bekannte Baseline Lint 6 Fehler/4 Warnungen, kein Test-Script, Build ohne Supabase-URL rot. Docs Build PASS; Produktions-Audit 0, VitePress-Dev-Transitiven 3 Findings. Branch bis `6d9b35f` gepusht.
- 2026-08-14, Batch 11 Red: Route-Codec-, Adaptive-Shell-, Keyboard- und Back-Tests kompilierten ohne Navigationsmodule nicht.
- 2026-08-14, Batch 11 Green: 4/4 Target Tests für Deep-Link-Codec/Restoration, 320px/1200px Layout, Ctrl+1/2 und sekundäre Route mit System-Back; alte doppelte Shell entfernt und Listener lifecycle-sicher; Full Flutter 56/56 PASS; Analyze, Web Release und Windows Release PASS mit bekannter Secure-Storage-Wasm-Warnung.

Finale Pflichtgates: `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter test --coverage`, `flutter build apk --debug`, `flutter build apk --release`, `flutter build web --release`, Windows Build, Gradle/Kotlin Tests, `pnpm install --frozen-lockfile`, `pnpm lint`, `pnpm exec tsc --noEmit`, `pnpm test`, `pnpm build`, Playwright, Docs Build, Secret Scan, Dependency Audit, License Review, `git diff --check`, clean `git status`.

## 21. Risiko- und Blockerregister

| Risiko | Status | Mitigation / Gate |
|---|---|---|
| Legacy-Datenverlust | OPEN | Characterization, Backup, idempotente Migration vor Domain switch |
| Release Signing lokal | OPEN | CI/local unsigned/release-compatible config; echte Signierung extern offen |
| iOS Hardware nicht verfügbar | OPEN | automatisierte Adaptertests + klarer manueller Rest-Gate |
| Android OEM App Lock | OPEN | reale Gerätematrix, fail-open, keine absoluten Claims |
| Exact Alarm Store Policy | OPEN | inexact default; exact nur bewusste begründete Option |
| Classly OAuth Servervarianten | OPEN | standardsicherer Flow, Compatibility dokumentieren |
| Legal-Wahrheitsgehalt | OPEN | Inhalte erhalten; keine unbelegten Änderungen |
| VitePress 1.6.4 Audit | OPEN | 3 transitive Vite/esbuild Findings ohne Stable-Fix; V2 Alpha nicht blind übernehmen, in Batch 39 erneut prüfen |
| Repo Settings/Branch Protection | EXTERNAL | nur PR-Empfehlung, keine Änderung ohne Freigabe |

## 22. Legacy-Removal-Liste

- Nach Ersatz: statischer `StorageService`, monolithischer `HabitProvider`, `NotificationService` Singleton, große Screens/Widgets.
- Nach Referenzprüfung: `temp_icons/`, doppelte/ungenutzte Launcher-Assets, Next/Vercel/Globe/Window/File SVGs.
- Vollständig: Landing Beta/Test/Feedback/Admin/Supabase samt Styles, Modelle, Env und Copy.
- Entfernen/umschreiben: Default `classly.site`, Description-Magic-String, direkter Passwortfluss, zufällige AI-Insights, ungefragtes Mock-Habit.
- Workflows: vier überlappende App-Workflows durch klare Jobs ersetzen.

## 23. PR- und Release-Readiness-Checkliste

- [ ] >=30 substanzielle Batch-Commits; Ziel 40
- [ ] Plan-Ledger enthält jeden SHA
- [ ] Core-Matrix vollständig getestet
- [ ] Migration + Rollback verifiziert
- [ ] Classly default-off/lazy; AI experimentell/default-off
- [ ] Reminder correctness matrix automatisch grün; Hardware-Restgates ehrlich
- [ ] App Lock fail-open und Recovery geprüft
- [ ] Landingpage DE/EN/Live/Legal; Beta/Admin entfernt
- [ ] A11y/Performancewerte dokumentiert
- [ ] Flutter/Landing/Docs/Repo Gates grün
- [ ] Screenshots aus realem Build
- [ ] `gh` PR gegen `main`, Checks grün
- [ ] Nicht gemergt, nicht released, nicht deployed

## 24. Rollback-Plan

Code-Rollback erfolgt batchweise über normale Revert-Commits, niemals History Rewrite oder Force Push. Datenmigration schreibt vor dem ersten Schema-Write ein unverändertes Legacy-Backup und behält Schema-/Migrationsmetadaten; Restore validiert Ziel und erfolgt atomar. Reminder-Migration reconciliert die eigene ID-Registry und kann alle Habiter-IDs canceln/aus Domain neu planen. Classly-/AI-Credential-Migration löscht Legacywerte erst nach erfolgreichem Secure-Storage-Write. App Lock bleibt jederzeit lokal deaktivierbar. Landing-Routen können per Revert wiederhergestellt werden, ohne produktive Daten anzufassen.

## 25. Final Handoff

Noch nicht fällig. Am Ende ausschließlich belegte Werte eintragen: Branch, PR-Link, Base-/Head-SHA, Batch-/Commitanzahl, Tests, Builds, CI, Screenshots, Performance, implementiert, teilweise verifiziert, extern/manuell offen und Restrisiken. Abschlussaussage muss ausdrücklich bestätigen: nicht gemergt, nicht released, nicht deployed.
