# State management

Habiter uses `provider`/`ChangeNotifier` at the UI boundary and increasingly keeps behavior in focused controllers, queries, repositories, and use cases.

## Ownership

- `HabitProvider` remains the compatibility facade for habits, entries, imports, and several screen flows.
- Feature controllers such as `TodayController`, `AnalyticsController`, `HistoryController`, and `OnboardingController` own focused view state.
- `ReminderCoordinator` owns local reminder migration, profile recomputation, durable action processing, planning, and reconciliation behind `HabitProvider`.
- Use cases such as completion and lifecycle operations apply domain rules without depending on widgets.
- Repositories own persistence. Gateways isolate notifications, App Lock, files, time, IDs, and widgets.

Widgets should observe the smallest useful state and call an application operation rather than mutating model collections directly.

```dart
final habits = context.watch<HabitProvider>();
await context.read<HabitProvider>().toggleHabitCompletion(habit.id, date);
```

## State transition contract

For mutations:

1. Validate input and schedule rules.
2. Persist the new canonical state.
3. Reconcile dependent reminders, widgets, or lifecycle state.
4. Publish one coherent state update.
5. Surface recoverable failure without discarding the last valid state.

Do not use widget lifecycle methods as the sole owner of durable business state. Background notification and widget actions must remain idempotent because platforms may retry them.

## Time and schedules

Domain code uses `LocalDate` and injected clocks rather than ad-hoc `DateTime.now()` calls. Reminder scheduling resolves the device time zone and explicitly handles daylight-saving gaps and overlaps.

## Testing

- Domain tests cover schedule and lifecycle invariants.
- Controller/use-case tests use fake clocks, repositories, and gateways.
- Widget tests cover responsive layouts, semantics, completion/undo, and key navigation flows.
- Platform integrations retain manual physical-device gates where emulators cannot prove OS behavior.
