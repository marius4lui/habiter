# Personal Sync data contract

Personal Sync Beta synchronizes an explicit, versioned subset of Habiter data. It never synchronizes a raw storage envelope, a SharedPreferences dump, secure storage, or native platform state. The executable source of truth is `personal_sync_contract.dart`; this page records the persistence inventory and the rationale behind the allow-list.

The contract starts at protocol, entity, and setting schema version `1`. A peer below the supported protocol window must upgrade its server; a peer above it must upgrade its client. Unsupported entity schemas are rejected before mutation.

## Classification rules

| Class | Meaning |
| --- | --- |
| Synchronized | Canonical user data represented by a `habit`, `entry`, or allow-listed `setting` entity. |
| Device-local | Durable state that belongs to one installation, platform, connection, or runtime. |
| Derived | A cache, projection, diagnostic, or learned value that can be rebuilt from canonical/local signals. |
| Sensitive | A credential, verifier, token, secret, or recovery material that must never enter sync. |
| Unsupported | Product state intentionally excluded until a later contract explicitly reviews it. |

Unknown storage keys are unsupported. A key is not eligible merely because SharedPreferences can enumerate it. Names resembling `token`, `secret`, `password`, `apiKey`, or `credential` fail closed at the entity and setting boundaries.

## Canonical habit state

The main repository persists a versioned `habiter_storage_envelope`. The envelope itself, its migration metadata, quarantine, and local revision never synchronize; clients project reviewed records from it.

| Persisted area | Contents | Class | Contract behavior |
| --- | --- | --- | --- |
| `habiter_habits` | Habit identity, title, description, color, icon, frequency, target, category, custom days, creation time, active/lifecycle state, pauses, archive/restore time, legacy reminder fields, and source metadata | Synchronized | One `habit/<encoded habit-id>` entity per habit. Additive fields are preserved unless sensitive-looking. |
| `habiter_habit_entries` | Entry ID, habit ID, local date, completion, count, and timestamp | Synchronized | One `entry/<encoded habit-id>/<local-date>` entity. Habit ID plus local date is the logical identity; the existing local entry ID remains payload metadata. |
| `habiter_habit_state_revision` | Monotonic repository revision | Device-local | Used to observe local commits; never treated as a cross-device revision. |
| Envelope `schemaVersion`, `migratedAt`, and `quarantine` | Persistence migration state and rejected legacy records | Device-local / Sensitive | Never synchronized. Quarantine may contain raw corrupt data. |
| `habiter_storage_backup_v0` | Pre-migration raw recovery payload | Sensitive | Remains local recovery material and never enters sync. |

Habit reminder configuration has two generations. Legacy `notificationEnabled` and `notificationTime` fields already live on each habit. Modern `HabitReminderPolicy` values inside `habiter_smart_reminders_v1`—mode, intensity, mode-specific configuration, snooze duration, and additive policy fields—are attached to the matching habit entity when the projection adapter is implemented. Runtime planning and learning fields from that same store remain local.

Deletion is a versioned entity document with `deleted: true` and no payload. Removing a record from a local list is not sufficient evidence of a remote deletion; later sync-engine work must create a durable tombstone operation.

## Approved setting registry

Each setting uses field-revision merge semantics and declares the local projection that must run after remote application. Version 1 contains only these stable keys:

| Stable key | Schema / default | Projection | Current local source |
| --- | --- | --- | --- |
| `appearance.theme` | `light \| dark \| system`; `system` | Appearance | `habiter_user_preferences.theme` and `settings_theme_mode` |
| `appearance.language` | `en \| de`; `de` | Appearance | `habiter_user_preferences.language` and `settings_locale` |
| `coaching.showRecoverySupport` | Boolean; `true` | Coaching | `habiter_user_preferences.showRecoverySupport` |
| `reminders.enabled` | Boolean; `false` | Reminders | `habiter_smart_reminders_v1.preferences.enabled`; legacy `notifications` is migrated here |
| `reminders.activeDayStart` | `HH:mm`; `08:00` | Reminders | Smart-reminder preferences |
| `reminders.activeDayEnd` | `HH:mm`; `22:00` | Reminders | Smart-reminder preferences |
| `reminders.globalDailyLimit` | Integer `1..64`; `8` | Reminders | Smart-reminder preferences |
| `reminders.globalMinimumSpacingMinutes` | Integer `1..1440`; `90` | Reminders | Smart-reminder preferences |
| `reminders.quietHours` | Non-overlapping, non-empty local-time ranges; `[]` | Reminders | Smart-reminder preferences |
| `reminders.calibrationEnabled` | Boolean; `true` | Reminders | Smart-reminder preferences |
| `reminders.ongoingLearningEnabled` | Boolean; `true` | Reminders | Smart-reminder preferences |
| `reminders.showLearningExplanations` | Boolean; `true` | Reminders | Smart-reminder preferences |
| `reminders.defaultSnoozeMinutes` | Integer `1..1440`; `30` | Reminders | Smart-reminder preferences |
| `reminders.dailyOverview.enabled` | Boolean; `false` | Reminders | Smart-reminder preferences; legacy `notifications` is migrated here where applicable |
| `reminders.dailyOverview.time` | `HH:mm`; `20:00` | Reminders | Smart-reminder preferences; legacy `reminderTime` is migrated here |

The registry does not permit unknown keys. A newer protocol must first define the key, schema, default, merge policy, projection, introduction version, and sensitivity review. The application adapter—not the wire decoder—owns mapping duplicate legacy sources into one stable setting and reconciling reminders after application.

`habiter_user_preferences.aiInsights` is unsupported in version 1 because the legacy flag does not distinguish local coaching from an experimental remote provider. It must not be inferred from or applied to remote AI configuration.

## Reminder and notification persistence

| Store / field | Class | Reason |
| --- | --- | --- |
| `habiter_smart_reminders_v1.preferences` | Synchronized only through the allow-list | User-authored cross-device behavior; local introduction state is excluded. |
| `habiter_smart_reminders_v1.policies` | Synchronized as reviewed habit-attached fields | The policy describes habit behavior, while platform scheduling remains local. |
| `signals`, `profiles`, and `calibration` | Device-local / Derived | Learned from one device's delivery and response history. |
| `plannedReminders` and `pendingSnoozes` | Device-local / Derived | Exact platform schedule and transient delivery state. |
| `legacyMigrationComplete` and `processedActionIds` | Device-local | Installation migration/idempotency bookkeeping. |
| `habiter_notification_requests_v1` | Device-local / Derived | Exact scheduled notification-request ledger. |
| `habiter_notification_registry_v1` | Device-local / Derived | Stable platform notification IDs. |
| `habiter_reminder_action_inbox_v1` | Device-local | Durable platform action inbox. |

Notification permission state, OS channels, time-zone resolution, platform notification IDs, delivery success, and permission-prompt history are always device-local. Remote application recalculates projections using the receiving device's time zone and permissions.

## Other Flutter persistence

| Store / value | Class | Reason |
| --- | --- | --- |
| `habiter_ai_insights` | Derived / Unsupported | Local coaching output can be rebuilt; remote-provider output is not approved sync data. |
| `habiter_ai_config` (`enabled`, `provider`, `model`) | Device-local / Sensitive-adjacent | Controls an optional third-party boundary and may derive credential use. |
| `habiter_app_lock_config` | Device-local | Contains installed package identifiers, app labels, enablement, and device-specific rules/projections. |
| `habiter_app_block_onboarding_v1` | Device-local | Permission education, installed-app selection, and onboarding progress belong to one device. |
| `habiter_onboarding_v2` | Device-local | Temporary/product-education progress; not user domain data. |
| `settings_theme_mode`, `settings_locale` | Synchronized only through registry mapping | Compatibility stores for the approved appearance keys, never raw keys. |
| `updates_state_v1` | Device-local / Derived | Update track/profile, manifest cache, ETag, check time, presented builds, and download references depend on the installation. |
| `classly_base_url`, `classly_last_sync`, `classly_auto_sync_interval`, `classly_enabled` | Device-local | Optional integration endpoint and runtime state are not the Habiter Sync protocol. Imported habits remain normal habit entities with reviewed source metadata. |
| `habiter_widget_undo_tokens`, `habiter_widget_action_ids` | Device-local | Short-lived widget action idempotency and undo state. |
| `habiter_widget_snapshot` | Derived | Sanitized native render projection rebuilt from canonical habits. |
| `habiter_widget_pin/result` | Device-local | Launcher request state. |

Backup export settings remain an inspection snapshot and are not applied on import. Personal Sync maps only registry keys; it does not change backup schema version 1 or the existing reject-before-mutate import transaction.

## Native Android persistence and files

| Native area | Values | Class |
| --- | --- | --- |
| `app_lock` preferences | `locked_packages`, `is_enabled`, `habits_complete`, `incomplete_habits`, projected package sets, and per-package blocker names | Device-local / Derived |
| `HomeWidgetPreferences` | Widget snapshot consumed by Glance | Derived |
| `habiter_widget_pin` | Pin request/result state | Device-local |
| `habiter_updates` preferences | Download metadata (`download_*`) and notification markers (`notified_*`) | Device-local / Derived |
| App external update directory and Download Manager rows | Downloaded/verified APKs and transfer state | Device-local / Derived |

Installed application inventory, usage-access and overlay permissions, foreground-service state, update installer permission, package installer source, widget IDs, OS backups, and notification channels are device-local even when the operating system persists them outside Habiter's stores.

## Secure storage and never-synchronized data

| Secure key / category | Class |
| --- | --- |
| `classly_token` | Sensitive |
| `experimental_ai_api_key` | Sensitive |
| Future Personal Sync access tokens, refresh tokens, authorization verifiers, and pending PKCE verifier material | Sensitive |
| Passwords, password verifiers, API/OAuth credentials, signing/update keys, server secrets, and arbitrary secure-storage contents | Sensitive |

Endpoint origins and sanitized connection timestamps may later use ordinary preferences but remain device-scoped connection metadata. They are not user setting entities.

## Entity compatibility

Version-1 live documents contain `schemaVersion`, `entityId`, `deleted: false`, and a JSON payload. Tombstones contain the same version and ID with `deleted: true` and no payload.

- Habit payloads require the current portable habit fields. Their stable entity ID must match payload `id`.
- Entry payloads require the current portable entry fields. Their entity ID must match payload `habitId` and `date`.
- Setting payloads contain only `value`; the entity ID supplies the stable allow-listed key.
- Additive habit/entry fields and additive document metadata are preserved round-trip so an older compatible client cannot silently erase newer fields.
- Any nested sensitive-looking field fails closed rather than being uploaded.
- Unknown setting keys, malformed values, identity mismatches, malformed tombstones, non-JSON values, and unsupported entity schemas are rejected before mutation.

The operation stream, server revisions, idempotency keys, cursor pagination, and deterministic conflict algorithm build on this document contract in the runtime-neutral sync-core child issue. They must not reinterpret device wall-clock timestamps as authoritative ordering.

## Change procedure

Changing the synchronized allow-list, an entity identity, a required field, unknown-field behavior, or a version number requires:

1. a protocol compatibility decision and migration/rejection tests;
2. matching app and server contract changes;
3. storage-adapter conformance fixtures;
4. a privacy and secret-leak review;
5. updates to this page and later the public Personal Sync API reference;
6. explicit re-planning under the parent epic before implementation.

See [Services and gateways](/dev/services), [State management](/dev/state), [Backup JSON format](/api/backup-format), and [Data and privacy](/guide/data-and-privacy) for the existing local boundaries this contract preserves.
