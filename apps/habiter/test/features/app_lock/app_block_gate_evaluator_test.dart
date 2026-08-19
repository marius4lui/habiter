import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/app_lock/application/app_block_gate_evaluator.dart';
import 'package:habiter/features/app_lock/domain/app_block_rule.dart';
import 'package:habiter/models/habit.dart';

void main() {
  const evaluator = AppBlockGateEvaluator();
  final wednesday = LocalDate(2026, 8, 19);

  test('daily habit gates until completed today', () {
    final habit = _habit(id: 'read', frequency: HabitFrequency.daily);
    expect(
      evaluator
          .evaluate(
            requirement: const GeneralRequirement(),
            date: wednesday,
            habits: <Habit>[habit],
            entries: const <HabitEntry>[],
          )
          .blocked,
      isTrue,
    );
    expect(
      evaluator
          .evaluate(
            requirement: const GeneralRequirement(),
            date: wednesday,
            habits: <Habit>[habit],
            entries: <HabitEntry>[_entry('read', wednesday)],
          )
          .blocked,
      isFalse,
    );
  });

  test('custom schedule only gates on a canonical scheduled weekday', () {
    final habit = _habit(
      id: 'run',
      frequency: HabitFrequency.custom,
      customDays: <int>[DateTime.monday, DateTime.wednesday],
    );
    expect(
      evaluator
          .evaluate(
            requirement: const GeneralRequirement(),
            date: wednesday,
            habits: <Habit>[habit],
            entries: const <HabitEntry>[],
          )
          .blocked,
      isTrue,
    );
    expect(
      evaluator
          .evaluate(
            requirement: const GeneralRequirement(),
            date: wednesday.addDays(1),
            habits: <Habit>[habit],
            entries: const <HabitEntry>[],
          )
          .blocked,
      isFalse,
    );
  });

  test('flexible weekly habit uses a daily contribution gate', () {
    final habit = _habit(
      id: 'learn',
      frequency: HabitFrequency.weekly,
      targetCount: 3,
    );
    final monday = wednesday.addDays(-2);
    final tuesday = wednesday.addDays(-1);
    final entries = <HabitEntry>[
      _entry('learn', monday),
      _entry('learn', tuesday),
    ];

    final openToday = evaluator.evaluate(
      requirement: const GeneralRequirement(),
      date: wednesday,
      habits: <Habit>[habit],
      entries: <HabitEntry>[...entries, _entry('learn', wednesday)],
    );
    final pendingToday = evaluator.evaluate(
      requirement: const GeneralRequirement(),
      date: wednesday,
      habits: <Habit>[habit],
      entries: entries,
    );

    expect(openToday.blocked, isFalse);
    expect(pendingToday.blockers.single.progressLabel, '2/3 this week');
  });

  test('weekly target reached removes gates for the rest of that week', () {
    final habit = _habit(
      id: 'learn',
      frequency: HabitFrequency.weekly,
      targetCount: 3,
    );
    final entries = <HabitEntry>[
      _entry('learn', wednesday.addDays(-2)),
      _entry('learn', wednesday.addDays(-1)),
      _entry('learn', wednesday),
    ];
    expect(
      evaluator
          .evaluate(
            requirement: const GeneralRequirement(),
            date: wednesday.addDays(1),
            habits: <Habit>[habit],
            entries: entries,
          )
          .blocked,
      isFalse,
    );
  });

  test('specific requirements use AND semantics across active blockers', () {
    final habits = <Habit>[
      _habit(id: 'read', name: 'Read'),
      _habit(id: 'move', name: 'Move'),
      _habit(id: 'ignore', name: 'Ignore'),
    ];
    final result = evaluator.evaluate(
      requirement: HabitRequirement(<String>['read', 'move']),
      date: wednesday,
      habits: habits,
      entries: <HabitEntry>[_entry('read', wednesday)],
    );
    expect(result.blockers.map((gate) => gate.habitId), <String>['move']);
  });

  test('paused, archived, deleted, and malformed habits fail open', () {
    final paused = _habit(id: 'paused', isActive: false);
    final archived = _habit(id: 'archived', isActive: false);
    final malformed = _habit(
      id: 'malformed',
      frequency: HabitFrequency.custom,
      customDays: const <int>[],
    );
    expect(
      evaluator
          .evaluate(
            requirement: HabitRequirement(<String>[
              'paused',
              'archived',
              'deleted',
              'malformed',
            ]),
            date: wednesday,
            habits: <Habit>[paused, archived, malformed],
            entries: const <HabitEntry>[],
          )
          .blocked,
      isFalse,
    );
  });

  test('week rollover counts only the canonical local Monday bucket', () {
    final habit = _habit(
      id: 'learn',
      frequency: HabitFrequency.weekly,
      targetCount: 1,
    );
    final nextMonday = LocalDate(2026, 8, 24);
    final result = evaluator.evaluate(
      requirement: const GeneralRequirement(),
      date: nextMonday,
      habits: <Habit>[habit],
      entries: <HabitEntry>[_entry('learn', LocalDate(2026, 8, 23))],
    );
    expect(result.blocked, isTrue);
  });
}

Habit _habit({
  required String id,
  String? name,
  HabitFrequency frequency = HabitFrequency.daily,
  int targetCount = 1,
  List<int>? customDays,
  bool isActive = true,
}) => Habit(
  id: id,
  name: name ?? id,
  color: '#000000',
  icon: 'x',
  frequency: frequency,
  targetCount: targetCount,
  category: 'Test',
  customDays: customDays,
  createdAt: DateTime(2026, 1, 1),
  isActive: isActive,
);

HabitEntry _entry(String habitId, LocalDate date) => HabitEntry(
  id: '$habitId-$date',
  habitId: habitId,
  date: date.toString(),
  completed: true,
  count: 1,
  timestamp: DateTime(date.year, date.month, date.day, 12),
);
