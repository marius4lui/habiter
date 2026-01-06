# Architecture

Habiter follows a clean, layered architecture to ensure separation of concerns.

## Directory Structure
The `lib/` folder is organized by technical function:

- `features/` or `screens/`: UI components and Pages.
- `providers/`: State management (Business Logic).
- `services/`: External data sources and system interaction.
- `models/`: Data classes.
- `theme/`: Styling definitions.

## Entry Point
`main.dart` is the entry point. It initializes:
1. `MultiProvider` for state injection.
2. `HabiterApp` root widget.
3. `_RootShell` which handles the persistent bottom navigation and the animated background.

## Key Components

### The Root Shell
The `_RootShell` widget in `main.dart` is crucial. It contains the `PageView` for top-level navigation (Home, Analytics) and the `_ShellBackground` which renders the animated Glow Orbs.

```dart
// main.dart
class _RootShell extends StatefulWidget { ... }
```
