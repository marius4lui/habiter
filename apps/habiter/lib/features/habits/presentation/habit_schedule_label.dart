import '../../../l10n/app_localizations.dart';
import '../../../models/habit.dart';
import '../domain/habit_schedule.dart';

String localizedHabitSchedule(AppLocalizations l10n, Habit habit) {
  final HabitSchedule schedule;
  try {
    schedule = LegacyHabitScheduleMapper.fromHabit(habit);
  } on FormatException {
    return l10n.scheduleUnavailable;
  } on ArgumentError {
    return l10n.scheduleUnavailable;
  }

  return switch (schedule) {
    DailySchedule() => l10n.daily,
    TimesPerWeekSchedule(:final target) => l10n.perWeek(target),
    WeekdaySchedule(:final weekdays) => l10n.onDays(
      habit.targetCount,
      weekdays.length,
    ),
  };
}
