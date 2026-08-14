import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule.dart';

final class WeeklyHabitMetric {
  const WeeklyHabitMetric({
    required this.weekStart,
    required this.scheduled,
    required this.completed,
  });

  final LocalDate weekStart;
  final int scheduled;
  final int completed;

  double get rate => scheduled == 0 ? 0 : completed / scheduled;
}

final class HabitMetrics {
  HabitMetrics({
    required this.scheduled,
    required this.completed,
    required this.currentStreak,
    required this.longestStreak,
    required Iterable<WeeklyHabitMetric> weeks,
  }) : weeks = List<WeeklyHabitMetric>.unmodifiable(weeks);

  final int scheduled;
  final int completed;
  final int currentStreak;
  final int longestStreak;
  final List<WeeklyHabitMetric> weeks;

  double get completionRate => scheduled == 0 ? 0 : completed / scheduled;
}

abstract final class HabitMetricCalculator {
  static HabitMetrics calculate({
    required Habit habit,
    required Iterable<HabitEntry> entries,
    required LocalDate through,
  }) {
    final created = LocalDate.fromDateTime(habit.createdAt);
    if (through.compareTo(created) < 0) {
      return HabitMetrics(
        scheduled: 0,
        completed: 0,
        currentStreak: 0,
        longestStreak: 0,
        weeks: const <WeeklyHabitMetric>[],
      );
    }
    final schedule = LegacyHabitScheduleMapper.fromHabit(habit);
    final completedDates = <LocalDate>{
      for (final entry in entries)
        if (entry.habitId == habit.id && entry.completed)
          LocalDate.parse(entry.date),
    };
    return schedule is TimesPerWeekSchedule
        ? _weeklyTargetMetrics(
            habit: habit,
            schedule: schedule,
            completedDates: completedDates,
            start: created,
            through: through,
          )
        : _scheduledDateMetrics(
            habit: habit,
            schedule: schedule,
            completedDates: completedDates,
            start: created,
            through: through,
          );
  }

  static HabitMetrics _scheduledDateMetrics({
    required Habit habit,
    required HabitSchedule schedule,
    required Set<LocalDate> completedDates,
    required LocalDate start,
    required LocalDate through,
  }) {
    final planned = schedule
        .datesBetween(start, through)
        .where((date) => !_inactiveOn(habit, date))
        .toList(growable: false);
    final completed = planned
        .where((date) => completedDates.contains(date))
        .toSet();
    final streaks = _occurrenceStreaks(planned, completed);
    return HabitMetrics(
      scheduled: planned.length,
      completed: completed.length,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      weeks: _weeksFromDates(planned, completed),
    );
  }

  static HabitMetrics _weeklyTargetMetrics({
    required Habit habit,
    required TimesPerWeekSchedule schedule,
    required Set<LocalDate> completedDates,
    required LocalDate start,
    required LocalDate through,
  }) {
    final weeks = <WeeklyHabitMetric>[];
    final firstWeek = _weekStart(start);
    for (
      var weekStart = firstWeek;
      weekStart.compareTo(through) <= 0;
      weekStart = weekStart.addDays(7)
    ) {
      final available = <LocalDate>[];
      for (var offset = 0; offset < 7; offset++) {
        final date = weekStart.addDays(offset);
        if (date.compareTo(start) >= 0 &&
            date.compareTo(through) <= 0 &&
            !_inactiveOn(habit, date)) {
          available.add(date);
        }
      }
      final scheduled = schedule.target.clamp(0, available.length) as int;
      final completed = available
          .where(completedDates.contains)
          .length
          .clamp(0, scheduled) as int;
      weeks.add(
        WeeklyHabitMetric(
          weekStart: weekStart,
          scheduled: scheduled,
          completed: completed,
        ),
      );
    }
    final streaks = _weeklyStreaks(weeks);
    return HabitMetrics(
      scheduled: weeks.fold(0, (sum, week) => sum + week.scheduled),
      completed: weeks.fold(0, (sum, week) => sum + week.completed),
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      weeks: weeks,
    );
  }

  static (int, int) _occurrenceStreaks(
    List<LocalDate> planned,
    Set<LocalDate> completed,
  ) {
    var running = 0;
    var longest = 0;
    for (final date in planned) {
      if (completed.contains(date)) {
        running++;
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
    }
    return (running, longest);
  }

  static (int, int) _weeklyStreaks(List<WeeklyHabitMetric> weeks) {
    var running = 0;
    var longest = 0;
    for (final week in weeks) {
      if (week.scheduled > 0 && week.completed >= week.scheduled) {
        running++;
        if (running > longest) longest = running;
      } else if (week.scheduled > 0) {
        running = 0;
      }
    }
    return (running, longest);
  }

  static List<WeeklyHabitMetric> _weeksFromDates(
    List<LocalDate> planned,
    Set<LocalDate> completed,
  ) {
    final buckets = <LocalDate, List<LocalDate>>{};
    for (final date in planned) {
      buckets.putIfAbsent(_weekStart(date), () => <LocalDate>[]).add(date);
    }
    return <WeeklyHabitMetric>[
      for (final entry in buckets.entries)
        WeeklyHabitMetric(
          weekStart: entry.key,
          scheduled: entry.value.length,
          completed: entry.value.where(completed.contains).length,
        ),
    ];
  }

  static LocalDate _weekStart(LocalDate date) =>
      date.addDays(1 - date.weekday);

  static bool _inactiveOn(Habit habit, LocalDate date) {
    final value = date.toString();
    if (habit.isPausedOn(value)) return true;
    final archivedAt = habit.archivedAt;
    if (archivedAt == null) return false;
    final archiveDate = LocalDate.fromDateTime(archivedAt);
    if (date.compareTo(archiveDate) < 0) return false;
    final restoredAt = habit.restoredAt;
    return restoredAt == null ||
        date.compareTo(LocalDate.fromDateTime(restoredAt)) < 0;
  }
}
