# Architecture

Habiter follows a **feature-first, clean architecture** approach.

## Project Structure

```
lib/
├── main.dart           # App entry point
├── models/             # Data models (Habit, HabitEntry, etc.)
├── providers/          # State management (ChangeNotifier)
├── screens/            # UI screens
├── services/           # Business logic & APIs
├── theme/              # App theme & styling
├── utils/              # Helper functions
└── widgets/            # Reusable UI components
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State | Provider |
| Storage | SharedPreferences / Hive |
| Notifications | flutter_local_notifications |

## Key Providers

- `HabitProvider` - Manages habits and entries
- `ClasslySyncProvider` - Handles Classly integration
- `AppLockProvider` - Controls App Lock feature
