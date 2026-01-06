# Data Models

Core data structures located in `lib/models/`.

## Habit
Represents a single habit to be tracked.
Properties:
- `id`: Unique identifier.
- `title`: Display name.
- `frequency`: Enum (Daily, Weekly).
- `reminderTime`: `TimeOfDay` for notifications.

## LockedApp
Represents an external application that is restricted.
Properties:
- `packageName`: Android package name (e.g., `com.instagram.android`).
- `appName`: Human readable name.
- `isLocked`: Boolean status.
