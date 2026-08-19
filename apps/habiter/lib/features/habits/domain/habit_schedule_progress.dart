import 'dart:collection';

import '../../../core/time/local_date.dart';
import 'habit_schedule.dart';

typedef HabitDatePredicate = bool Function(LocalDate date);

/// Canonical, local-date-only progress for the Monday-Sunday week containing
/// [focusDate].
///
/// The evaluator deliberately accepts a [HabitSchedule] instead of a UI or
/// persistence model so Today, Analytics, Reminders, onboarding education and
/// future App Block gates can share the same counting semantics.
final class HabitScheduleProgress {
  HabitScheduleProgress._({
    required this.schedule,
    required this.weekStart,
    required this.weekEnd,
    required this.target,
    required Iterable<LocalDate> eligibleDates,
    required Iterable<LocalDate> completedDates,
    required HabitDatePredicate isInactiveOn,
  }) : eligibleDates = UnmodifiableSetView<LocalDate>(
         Set<LocalDate>.of(eligibleDates),
       ),
       completedDates = UnmodifiableSetView<LocalDate>(
         Set<LocalDate>.of(completedDates),
       ),
       _isInactiveOn = isInactiveOn;

  factory HabitScheduleProgress.evaluate({
    required HabitSchedule schedule,
    required LocalDate focusDate,
    Iterable<LocalDate> completedDates = const <LocalDate>[],
    HabitDatePredicate? isInactiveOn,
  }) {
    final inactive = isInactiveOn ?? (_) => false;
    final weekStart = focusDate.addDays(1 - focusDate.weekday);
    final weekEnd = weekStart.addDays(6);
    final eligible = <LocalDate>{
      for (var offset = 0; offset < 7; offset++)
        if (!inactive(weekStart.addDays(offset)) &&
            schedule.isAvailableOn(weekStart.addDays(offset)))
          weekStart.addDays(offset),
    };
    final completed = completedDates.where(eligible.contains).toSet();
    final target = schedule.weeklyTarget.clamp(0, eligible.length);
    return HabitScheduleProgress._(
      schedule: schedule,
      weekStart: weekStart,
      weekEnd: weekEnd,
      target: target,
      eligibleDates: eligible,
      completedDates: completed,
      isInactiveOn: inactive,
    );
  }

  final HabitSchedule schedule;
  final LocalDate weekStart;
  final LocalDate weekEnd;
  final int target;
  final Set<LocalDate> eligibleDates;
  final Set<LocalDate> completedDates;
  final HabitDatePredicate _isInactiveOn;

  int get completed => completedDates.length.clamp(0, target);

  int get remaining => (target - completed).clamp(0, target);

  bool get targetReached => target > 0 && completed >= target;

  bool isCompletedOn(LocalDate date) => completedDates.contains(date);

  bool isContributionAvailableOn(LocalDate date) {
    if (date.compareTo(weekStart) < 0 || date.compareTo(weekEnd) > 0) {
      return false;
    }
    if (_isInactiveOn(date) || !schedule.isAvailableOn(date)) return false;
    if (schedule is! TimesPerWeekSchedule) return true;
    return isCompletedOn(date) || !targetReached;
  }
}
