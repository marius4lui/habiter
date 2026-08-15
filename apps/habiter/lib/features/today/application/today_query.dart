import 'dart:collection';

import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule.dart';

final class TodaySnapshot {
  TodaySnapshot({
    required Iterable<Habit> scheduled,
    required Iterable<Habit> pending,
    required Iterable<Habit> completed,
  }) : scheduled = UnmodifiableListView<Habit>(scheduled.toList()),
       pending = UnmodifiableListView<Habit>(pending.toList()),
       completed = UnmodifiableListView<Habit>(completed.toList());

  final List<Habit> scheduled;
  final List<Habit> pending;
  final List<Habit> completed;

  double get progress =>
      scheduled.isEmpty ? 0 : completed.length / scheduled.length;
}

abstract final class TodayQuery {
  static TodaySnapshot forDate({
    required LocalDate date,
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
  }) {
    final completedIds = entries
        .where((entry) => entry.date == date.toString() && entry.completed)
        .map((entry) => entry.habitId)
        .toSet();
    final scheduled = habits
        .where((habit) {
          if (!habit.isActive) return false;
          try {
            return LegacyHabitScheduleMapper.fromHabit(
              habit,
            ).isAvailableOn(date);
          } on FormatException {
            return false;
          }
        })
        .toList(growable: false);
    return TodaySnapshot(
      scheduled: scheduled,
      pending: scheduled.where((habit) => !completedIds.contains(habit.id)),
      completed: scheduled.where((habit) => completedIds.contains(habit.id)),
    );
  }
}
