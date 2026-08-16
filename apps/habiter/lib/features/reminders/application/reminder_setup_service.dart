import '../../../models/habit.dart';
import 'reminder_repository.dart';
import '../domain/calibration_session.dart';
import '../domain/local_time.dart';
import '../domain/reminder_policy.dart';
import '../domain/reminder_preferences.dart';

final class LegacyReminderSettings {
  const LegacyReminderSettings({
    required this.notificationsEnabled,
    required this.reminderTime,
  });

  final bool notificationsEnabled;
  final String reminderTime;
}

final class ReminderSetupService {
  const ReminderSetupService(this._repository);

  final ReminderRepository _repository;

  Future<bool> migrateLegacy({
    required Iterable<Habit> habits,
    required LegacyReminderSettings settings,
    required DateTime now,
  }) async {
    var migrated = false;
    await _repository.transact((draft) {
      if (draft.legacyMigrationComplete) return;
      for (final habit in habits) {
        final time =
            _validTime(habit.notificationTime) ?? const LocalTime(20, 0);
        draft.policies[habit.id] = HabitReminderPolicy.fixedTimes(
          habitId: habit.id,
          times: <LocalTime>[time],
          now: now,
          enabled: habit.notificationEnabled && habit.notificationTime != null,
        );
      }
      draft.preferences = ReminderPreferences(
        enabled:
            settings.notificationsEnabled ||
            habits.any((habit) => habit.notificationEnabled),
        dailyOverview: DailyOverviewReminder(
          enabled: settings.notificationsEnabled,
          time: _validTime(settings.reminderTime) ?? const LocalTime(20, 0),
        ),
      );
      draft.legacyMigrationComplete = true;
      migrated = true;
    });
    return migrated;
  }

  Future<void> enableSmartForNewUser({
    required Iterable<Habit> habits,
    required String calibrationSessionId,
    required DateTime now,
  }) => _repository.transact((draft) {
    draft.preferences = ReminderPreferences(enabled: true);
    for (final habit in habits) {
      draft.policies[habit.id] = HabitReminderPolicy.smart(
        habitId: habit.id,
        now: now,
        intensity: ReminderIntensity.persistent,
      );
    }
    draft.calibration = CalibrationSession.start(
      id: calibrationSessionId,
      now: now,
    );
    draft.legacyMigrationComplete = true;
  });

  Future<void> addSmartPolicyForNewHabit({
    required Habit habit,
    required DateTime now,
  }) => _repository.transact((draft) {
    if (!draft.preferences.enabled) return;
    final hasSmartPolicy = draft.policies.values.any(
      (policy) => policy.mode == ReminderMode.smart,
    );
    if (!hasSmartPolicy) return;
    draft.policies[habit.id] = HabitReminderPolicy.smart(
      habitId: habit.id,
      now: now,
    );
  });

  static LocalTime? _validTime(String? value) {
    if (value == null) return null;
    try {
      return LocalTime.parse(value);
    } on FormatException {
      return null;
    }
  }
}
