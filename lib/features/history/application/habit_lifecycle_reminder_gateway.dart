import '../../../models/habit.dart';

/// Coordinates reminder side effects after a committed lifecycle transition.
///
/// Keeping this port separate from persistence makes pause/archive behavior
/// injectable and lets the UI prove that reminders are only changed after a
/// successful domain transition.
abstract interface class HabitLifecycleReminderGateway {
  Future<void> cancelForHabit(String habitId);

  Future<void> scheduleForHabit(Habit habit);
}
