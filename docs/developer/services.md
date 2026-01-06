# Services

Services handle data application logic and communication with the outside world.

## NotificationService
Managed in `lib/services/notification_service.dart`.
- Handles scheduling local notifications.
- Manages permission requests.
- Maps habit reminders to system alarms.

## AppLockService
Managed in `lib/services/app_lock_service.dart`.
- Uses platform channels (Android) to detect running apps.
- Intercepts restricted apps and shows the overlay if habits aren't met.

## AiManager
Managed in `lib/services/ai_manager.dart`.
- Provides intelligent suggestions for habits.
- Analyzes user patterns (future implementation).

## StorageService
Managed in `lib/services/storage_service.dart`.
- Wrapper around `shared_preferences` or local database.
- Persists user settings and habit logs.
