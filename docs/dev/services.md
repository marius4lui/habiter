# Services and gateways

Habiter separates domain behavior from storage, platform APIs, and external services. New code should depend on an application-facing interface and inject its implementation during bootstrap.

## Persistence

`KeyValueStore` is the low-level contract. `SharedPreferencesKeyValueStore` is the current device implementation, while `StorageEnvelope` and `LegacyStorageMigrator` provide versioning and migration. `KeyValueHabitRepository` exposes habit-oriented operations above that layer.

Never write a new durable field without defining its default, serialization form, migration behavior, corruption fallback, and test coverage.

## Reminders

The reminder subsystem contains:

- permission state and prompt coordination;
- versioned Smart, deterministic-random, and fixed habit policies;
- local availability profiles with decayed explicit feedback, completion support, hierarchical backoff, and explainable peak windows;
- calibration and adaptive fine-tuning questions that count as normal reminders;
- deterministic candidate ranking followed by global active-time, quiet-time, spacing, completion, lifecycle, and daily-limit guardrails;
- stable notification-ID allocation;
- schedule planning in the device time zone;
- reconciliation of desired and pending notifications;
- durable, idempotent action inbox processing;
- redacted diagnostics for support and QA.

Profile formation uses no network, location, contacts, calendar, or sensor data. Notification content must not expose credentials or diagnostic payloads. Delivery remains best-effort under OS power policy.

## App Lock

`AppLockGateway` defines the application boundary and `MethodChannelAppLockGateway` talks to Android native code. Missing permissions, failed boot recovery, or revoked access must disable monitoring and fail open.

## Data portability

`DataPortabilityService` produces versioned JSON, validates imports, previews conflicts, and coordinates recovery backup. `PlatformFileAdapter` owns file selection and saving. Import parsers must reject malformed or incompatible data before mutating storage.

## Classly-compatible integration

The integration validates a public HTTPS endpoint and uses OAuth with PKCE. Tokens belong in secure platform storage, never SharedPreferences, logs, diagnostics, or source control. Sync is an explicit optional boundary and must tolerate network failure without affecting core tracking.

## Widgets

Widget snapshots are deliberately smaller than the application model. The bridge publishes sanitized render state, and incoming actions are parsed and handled idempotently before refreshing the snapshot.

## Adding an integration

1. Define the narrow gateway interface in domain/application code.
2. Implement it in `data` or `infrastructure`.
3. Inject it from `app/dependencies.dart` or bootstrap.
4. Test success, unavailable platform, permission denial, timeout, malformed response, and retry.
5. Document privacy, platform, and manual QA implications.
