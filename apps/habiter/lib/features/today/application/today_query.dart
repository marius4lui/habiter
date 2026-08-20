import 'dart:collection';

import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule_progress.dart';

final class TodaySnapshot {
  TodaySnapshot({
    required Iterable<Habit> scheduled,
    required Iterable<Habit> pending,
    required Iterable<Habit> completed,
    required Map<String, HabitScheduleProgress> progressByHabit,
  }) : scheduled = UnmodifiableListView<Habit>(scheduled.toList()),
       pending = UnmodifiableListView<Habit>(pending.toList()),
       completed = UnmodifiableListView<Habit>(completed.toList()),
       _progressByHabit = UnmodifiableMapView<String, HabitScheduleProgress>(
         Map<String, HabitScheduleProgress>.of(progressByHabit),
       );

  final List<Habit> scheduled;
  final List<Habit> pending;
  final List<Habit> completed;
  final Map<String, HabitScheduleProgress> _progressByHabit;

  double get progress =>
      scheduled.isEmpty ? 0 : completed.length / scheduled.length;

  HabitScheduleProgress? progressFor(String habitId) =>
      _progressByHabit[habitId];
}

abstract final class TodayQuery {
  static TodaySnapshot forDate({
    required LocalDate date,
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
  }) {
    final completedByHabit = <String, Set<LocalDate>>{};
    for (final entry in entries) {
      if (!entry.completed) continue;
      try {
        completedByHabit
            .putIfAbsent(entry.habitId, () => <LocalDate>{})
            .add(LocalDate.parse(entry.date));
      } on FormatException {
        continue;
      }
    }
    final progressByHabit = <String, HabitScheduleProgress>{};
    final scheduled = <Habit>[];
    for (final habit in habits) {
      if (!habit.isActive) continue;
      try {
        final progress = HabitScheduleProgress.forHabit(
          habit: habit,
          focusDate: date,
          completedDates: completedByHabit[habit.id] ?? const <LocalDate>{},
        );
        progressByHabit[habit.id] = progress;
        if (progress.isContributionAvailableOn(date)) scheduled.add(habit);
      } on FormatException {
        continue;
      }
    }
    final completedIds = completedByHabit.entries
        .where((entry) => entry.value.contains(date))
        .map((entry) => entry.key)
        .toSet();
    return TodaySnapshot(
      scheduled: scheduled,
      pending: scheduled.where((habit) => !completedIds.contains(habit.id)),
      completed: scheduled.where((habit) => completedIds.contains(habit.id)),
      progressByHabit: progressByHabit,
    );
  }
}
