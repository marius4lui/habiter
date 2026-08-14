import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/habits/domain/habit_schedule.dart';
import 'package:habiter/models/habit.dart';

void main() {
  group('LocalDate', () {
    test('advances over leap days without a timezone dependency', () {
      final date = LocalDate(2024, 2, 28);

      expect(date.addDays(1), LocalDate(2024, 2, 29));
      expect(date.addDays(2), LocalDate(2024, 3, 1));
      expect(LocalDate.parse('2026-08-14').toString(), '2026-08-14');
    });

    test('rejects impossible calendar dates', () {
      expect(() => LocalDate(2026, 2, 30), throwsArgumentError);
      expect(() => LocalDate.parse('14.08.2026'), throwsFormatException);
    });
  });

  group('HabitSchedule', () {
    test('daily schedules every date in an inclusive range', () {
      const schedule = DailySchedule();

      expect(
        schedule.datesBetween(LocalDate(2026, 8, 14), LocalDate(2026, 8, 16)),
        <LocalDate>[
          LocalDate(2026, 8, 14),
          LocalDate(2026, 8, 15),
          LocalDate(2026, 8, 16),
        ],
      );
      expect(schedule.weeklyTarget, 7);
    });

    test('weekday schedule is immutable, ordered and validated', () {
      final input = <int>{5, 1, 3};
      final schedule = WeekdaySchedule(input);
      input.add(7);

      expect(schedule.weekdays, <int>[1, 3, 5]);
      expect(schedule.isAvailableOn(LocalDate(2026, 8, 14)), isTrue);
      expect(schedule.isAvailableOn(LocalDate(2026, 8, 15)), isFalse);
      expect(schedule.weeklyTarget, 3);
      expect(() => WeekdaySchedule(<int>{0, 8}), throwsArgumentError);
      expect(() => WeekdaySchedule(<int>{}), throwsArgumentError);
    });

    test('times-per-week stays available without inventing weekdays', () {
      final schedule = TimesPerWeekSchedule(3);

      expect(schedule.weeklyTarget, 3);
      expect(schedule.isAvailableOn(LocalDate(2026, 8, 16)), isTrue);
      expect(schedule.toMap(), <String, Object?>{
        'type': 'timesPerWeek',
        'target': 3,
      });
      expect(() => TimesPerWeekSchedule(0), throwsArgumentError);
      expect(() => TimesPerWeekSchedule(8), throwsArgumentError);
    });

    test('explicit schedules roundtrip through versionable maps', () {
      final schedules = <HabitSchedule>[
        const DailySchedule(),
        WeekdaySchedule(<int>{2, 4, 6}),
        TimesPerWeekSchedule(2),
      ];

      for (final schedule in schedules) {
        expect(HabitSchedule.fromMap(schedule.toMap()), schedule);
      }
      expect(
        () => HabitSchedule.fromMap(<String, Object?>{'type': 'future'}),
        throwsFormatException,
      );
    });
  });

  group('legacy schedule mapping', () {
    Habit habit({
      required HabitFrequency frequency,
      int targetCount = 1,
      List<int>? customDays,
    }) {
      return Habit(
        id: 'legacy',
        name: 'Legacy',
        color: '#000000',
        icon: 'check',
        frequency: frequency,
        targetCount: targetCount,
        category: 'General',
        customDays: customDays,
        createdAt: DateTime.utc(2026),
        isActive: true,
      );
    }

    test('maps all three legacy frequency variants explicitly', () {
      expect(
        LegacyHabitScheduleMapper.fromHabit(
          habit(frequency: HabitFrequency.daily),
        ),
        const DailySchedule(),
      );
      expect(
        LegacyHabitScheduleMapper.fromHabit(
          habit(frequency: HabitFrequency.weekly, targetCount: 4),
        ),
        TimesPerWeekSchedule(4),
      );
      expect(
        LegacyHabitScheduleMapper.fromHabit(
          habit(frequency: HabitFrequency.custom, customDays: <int>[1, 3, 5]),
        ),
        WeekdaySchedule(<int>{1, 3, 5}),
      );
    });

    test('rejects malformed custom schedules instead of guessing', () {
      expect(
        () => LegacyHabitScheduleMapper.fromHabit(
          habit(frequency: HabitFrequency.custom),
        ),
        throwsFormatException,
      );
    });
  });
}
