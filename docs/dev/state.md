# State Management

Habiter uses **Provider** for state management.

## HabitProvider

The main provider managing all habit-related state:

```dart
class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];
  List<HabitEntry> habitEntries = [];
  
  Future<void> addHabit({...}) async { ... }
  Future<void> toggleHabitCompletion(String habitId, String date) async { ... }
  Future<void> importFromClasslyEvents(List<ClasslyEvent> events) async { ... }
}
```

## Usage

```dart
final provider = context.read<HabitProvider>();
await provider.toggleHabitCompletion(habit.id, '2024-01-14');
```

## Listening to Changes

```dart
Consumer<HabitProvider>(
  builder: (context, provider, child) {
    return Text('${provider.habits.length} habits');
  },
)
```
