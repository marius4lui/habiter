import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/analytics/domain/habit_metrics.dart';
import 'package:habiter/models/habit.dart';

void main() {
  test('daily metrics use planned dates and neutral pause boundaries', () {
    final habit = _habit(
      createdAt: DateTime.utc(2026, 8, 9),
      pauses: <HabitPause>[
        HabitPause(
          startedAt: DateTime.utc(2026, 8, 10, 12),
          endedAt: DateTime.utc(2026, 8, 12, 8),
        ),
      ],
    );

    final metrics = HabitMetricCalculator.calculate(
      habit: habit,
      entries: <HabitEntry>[
        _entry('2026-08-09'),
        _entry('2026-08-11'),
        _entry('2026-08-12'),
      ],
      through: LocalDate(2026, 8, 13),
    );

    expect(metrics.scheduled, 3);
    expect(metrics.completed, 2);
    expect(metrics.completionRate, closeTo(2 / 3, 0.0001));
    expect(metrics.longestStreak, 2);
    expect(metrics.currentStreak, 0);
  });

  test('times-per-week clamps partial weeks without inventing weekdays', () {
    final habit = _habit(
      frequency: HabitFrequency.weekly,
      targetCount: 3,
      createdAt: DateTime.utc(2026, 8, 3),
      pauses: <HabitPause>[HabitPause(startedAt: DateTime.utc(2026, 8, 5))],
    );

    final metrics = HabitMetricCalculator.calculate(
      habit: habit,
      entries: <HabitEntry>[_entry('2026-08-03'), _entry('2026-08-04')],
      through: LocalDate(2026, 8, 9),
    );

    expect(metrics.scheduled, 2);
    expect(metrics.completed, 2);
    expect(metrics.completionRate, 1);
    expect(metrics.currentStreak, 1);
  });

  test('weekday metrics remain deterministic across leap day and timezone', () {
    final metrics = HabitMetricCalculator.calculate(
      habit: _habit(
        frequency: HabitFrequency.custom,
        customDays: <int>[DateTime.thursday],
        createdAt: DateTime.utc(2024, 2, 28, 23),
      ),
      entries: <HabitEntry>[_entry('2024-02-29')],
      through: LocalDate(2024, 3, 1),
    );

    expect(metrics.scheduled, 1);
    expect(metrics.completed, 1);
    expect(metrics.weeks.single.weekStart, LocalDate(2024, 2, 26));
  });

  test('archived interval is excluded and restored date is available', () {
    final metrics = HabitMetricCalculator.calculate(
      habit: _habit(
        createdAt: DateTime.utc(2026, 8, 1),
        archivedAt: DateTime.utc(2026, 8, 2, 12),
        restoredAt: DateTime.utc(2026, 8, 4, 9),
      ),
      entries: <HabitEntry>[
        _entry('2026-08-01'),
        _entry('2026-08-03'),
        _entry('2026-08-04'),
      ],
      through: LocalDate(2026, 8, 4),
    );

    expect(metrics.scheduled, 2);
    expect(metrics.completed, 2);
  });
}

Habit _habit({
  HabitFrequency frequency = HabitFrequency.daily,
  int targetCount = 1,
  List<int>? customDays,
  required DateTime createdAt,
  List<HabitPause> pauses = const <HabitPause>[],
  DateTime? archivedAt,
  DateTime? restoredAt,
}) => Habit(
  id: 'habit',
  name: 'Habit',
  color: '#000000',
  icon: 'H',
  frequency: frequency,
  targetCount: targetCount,
  category: 'Test',
  customDays: customDays,
  createdAt: createdAt,
  isActive: true,
  pauses: pauses,
  archivedAt: archivedAt,
  restoredAt: restoredAt,
);

HabitEntry _entry(String date) => HabitEntry(
  id: 'entry-$date',
  habitId: 'habit',
  date: date,
  completed: true,
  count: 1,
  timestamp: DateTime.parse('${date}T08:00:00Z'),
);
