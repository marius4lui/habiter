# Architecture

Habiter follows a feature-centric architecture pattern to ensure scalability and maintainability.

## Project Structure

```text
lib/
├── features/       # Feature-specific code (UI, Logic, Models)
│   ├── home/
│   ├── habits/
│   ├── settings/
│   └── ...
├── core/           # Shared utilities, constants, and widgets
├── l10n/           # Localization files
└── main.dart       # Entry point
```

## State Management

The project uses `Provider` for state management. Key providers include:

-   `HabitProvider`: Manages the list of habits and their status.
-   `ThemeProvider`: Handles theme switching (Light/Dark mode).
-   `LocaleProvider`: Manages app localization.

## Data Persistence

Local data persistence is handled using `shared_preferences` for settings and potentially `hive` or `sqflite` for habit data (check implementation details).

## Testing

The project includes:

-   **Unit Tests**: For business logic.
-   **Widget Tests**: For UI components.
