import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule.dart';
import '../domain/app_block_gate.dart';
import '../domain/app_block_rule.dart';

final class AppBlockGateEvaluator {
  const AppBlockGateEvaluator();

  AppBlockGateEvaluation evaluate({
    required AppBlockRequirement requirement,
    required LocalDate date,
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
  }) {
    final requiredIds = switch (requirement) {
      HabitRequirement(:final habitIds) => habitIds,
      GeneralRequirement() => null,
    };
    final entryList = entries.toList(growable: false);
    final blockers = <AppBlockHabitGate>[];

    for (final habit in habits) {
      if (!habit.isActive || habit.isPausedOn(date.toString())) continue;
      if (requiredIds != null && !requiredIds.contains(habit.id)) continue;
      final gate = _gateFor(habit, date, entryList);
      if (gate != null) blockers.add(gate);
    }
    blockers.sort((a, b) => a.habitName.compareTo(b.habitName));
    return AppBlockGateEvaluation(blockers);
  }

  AppBlockHabitGate? _gateFor(
    Habit habit,
    LocalDate date,
    List<HabitEntry> entries,
  ) {
    final HabitSchedule schedule;
    try {
      schedule = LegacyHabitScheduleMapper.fromHabit(habit);
    } on FormatException {
      return null;
    }
    if (!schedule.isAvailableOn(date)) return null;

    final completedToday = entries.any(
      (entry) =>
          entry.habitId == habit.id &&
          entry.date == date.toString() &&
          entry.completed,
    );
    if (completedToday) return null;

    if (schedule is TimesPerWeekSchedule) {
      final weekStart = date.addDays(1 - date.weekday);
      final weekEnd = weekStart.addDays(7);
      final completedDates = entries
          .where((entry) {
            if (entry.habitId != habit.id || !entry.completed) return false;
            final entryDate = LocalDate.parse(entry.date);
            return entryDate.compareTo(weekStart) >= 0 &&
                entryDate.compareTo(weekEnd) < 0;
          })
          .map((entry) => entry.date)
          .toSet();
      if (completedDates.length >= schedule.target) return null;
      return AppBlockHabitGate(
        habitId: habit.id,
        habitName: habit.name,
        kind: AppBlockGateKind.weeklyContribution,
        weeklyProgress: completedDates.length,
        weeklyTarget: schedule.target,
      );
    }

    return AppBlockHabitGate(
      habitId: habit.id,
      habitName: habit.name,
      kind: schedule is DailySchedule
          ? AppBlockGateKind.daily
          : AppBlockGateKind.scheduledDay,
    );
  }
}
