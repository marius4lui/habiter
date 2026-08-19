import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/habits/domain/habit_schedule.dart';
import 'package:habiter/features/habits/domain/habit_schedule_progress.dart';

void main() {
  group('HabitScheduleProgress', () {
    test('uses a canonical Monday-Sunday bucket', () {
      final progress = HabitScheduleProgress.evaluate(
        schedule: TimesPerWeekSchedule(3),
        focusDate: LocalDate(2026, 8, 19),
      );

      expect(progress.weekStart, LocalDate(2026, 8, 17));
      expect(progress.weekEnd, LocalDate(2026, 8, 23));
      expect(progress.target, 3);
      expect(progress.completed, 0);
      expect(progress.remaining, 3);
      expect(progress.targetReached, isFalse);
    });

    test('counts distinct dates and allows consecutive completions', () {
      final monday = LocalDate(2026, 8, 17);
      final tuesday = LocalDate(2026, 8, 18);
      final wednesday = LocalDate(2026, 8, 19);

      final progress = HabitScheduleProgress.evaluate(
        schedule: TimesPerWeekSchedule(3),
        focusDate: wednesday,
        completedDates: <LocalDate>[monday, monday, tuesday, wednesday],
      );

      expect(progress.completedDates, <LocalDate>{monday, tuesday, wednesday});
      expect(progress.completed, 3);
      expect(progress.remaining, 0);
      expect(progress.targetReached, isTrue);
      expect(progress.isCompletedOn(monday), isTrue);
      expect(progress.isContributionAvailableOn(wednesday), isTrue);
      expect(
        progress.isContributionAvailableOn(LocalDate(2026, 8, 20)),
        isFalse,
      );
    });

    test('ignores other weeks and reopens after undo', () {
      final focus = LocalDate(2026, 8, 23);
      final completions = <LocalDate>[
        LocalDate(2026, 8, 16),
        LocalDate(2026, 8, 17),
        LocalDate(2026, 8, 18),
        LocalDate(2026, 8, 19),
        LocalDate(2026, 8, 24),
      ];

      final reached = HabitScheduleProgress.evaluate(
        schedule: TimesPerWeekSchedule(3),
        focusDate: focus,
        completedDates: completions,
      );
      final reopened = HabitScheduleProgress.evaluate(
        schedule: TimesPerWeekSchedule(3),
        focusDate: focus,
        completedDates: completions.where(
          (date) => date != LocalDate(2026, 8, 19),
        ),
      );
      final nextWeek = HabitScheduleProgress.evaluate(
        schedule: TimesPerWeekSchedule(3),
        focusDate: LocalDate(2026, 8, 24),
        completedDates: completions,
      );

      expect(reached.targetReached, isTrue);
      expect(reopened.completed, 2);
      expect(reopened.remaining, 1);
      expect(reopened.targetReached, isFalse);
      expect(nextWeek.weekStart, LocalDate(2026, 8, 24));
      expect(nextWeek.completed, 1);
      expect(nextWeek.targetReached, isFalse);
    });

    test('keeps paused dates neutral for progress and availability', () {
      final paused = LocalDate(2026, 8, 18);
      final progress = HabitScheduleProgress.evaluate(
        schedule: TimesPerWeekSchedule(2),
        focusDate: paused,
        completedDates: <LocalDate>[LocalDate(2026, 8, 17), paused],
        isInactiveOn: (date) => date == paused,
      );

      expect(progress.completed, 1);
      expect(progress.completedDates, <LocalDate>{LocalDate(2026, 8, 17)});
      expect(progress.isContributionAvailableOn(paused), isFalse);
      expect(
        progress.isContributionAvailableOn(LocalDate(2026, 8, 19)),
        isTrue,
      );
    });

    test('preserves daily and fixed-weekday eligibility', () {
      final daily = HabitScheduleProgress.evaluate(
        schedule: const DailySchedule(),
        focusDate: LocalDate(2026, 8, 19),
        completedDates: <LocalDate>[LocalDate(2026, 8, 19)],
      );
      final fixed = HabitScheduleProgress.evaluate(
        schedule: WeekdaySchedule(<int>{1, 3, 5}),
        focusDate: LocalDate(2026, 8, 19),
        completedDates: <LocalDate>[
          LocalDate(2026, 8, 18),
          LocalDate(2026, 8, 19),
        ],
      );

      expect(daily.target, 7);
      expect(daily.completed, 1);
      expect(daily.isContributionAvailableOn(LocalDate(2026, 8, 20)), isTrue);
      expect(fixed.target, 3);
      expect(fixed.completedDates, <LocalDate>{LocalDate(2026, 8, 19)});
      expect(fixed.isContributionAvailableOn(LocalDate(2026, 8, 18)), isFalse);
      expect(fixed.isContributionAvailableOn(LocalDate(2026, 8, 21)), isTrue);
    });
  });
}
