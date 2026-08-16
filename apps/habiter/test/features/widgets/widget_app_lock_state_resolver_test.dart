import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/widgets/application/widget_app_lock_state_resolver.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/models/locked_app.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('last required widget completion unlocks app lock projection', () async {
    final store = InMemoryKeyValueStore(<String, Object?>{
      WidgetAppLockStateResolver.configKey: jsonEncode(
        const AppLockConfig(
          isEnabled: true,
          lockUntilAllHabitsComplete: false,
          requiredHabitIds: <String>['training'],
        ).toMap(),
      ),
    });
    final resolver = WidgetAppLockStateResolver(store);
    final habit = Habit(
      id: 'training',
      name: 'Training',
      color: '#C45B42',
      icon: '🏋️',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      category: 'Fitness',
      createdAt: DateTime(2026, 8, 1),
      isActive: true,
    );

    final pending = await resolver.resolve(
      date: LocalDate(2026, 8, 16),
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
    );
    final complete = await resolver.resolve(
      date: LocalDate(2026, 8, 16),
      habits: <Habit>[habit],
      entries: <HabitEntry>[
        HabitEntry(
          id: 'entry-1',
          habitId: 'training',
          date: '2026-08-16',
          completed: true,
          count: 1,
          timestamp: DateTime(2026, 8, 16, 12),
        ),
      ],
    );

    expect(pending?.complete, isFalse);
    expect(pending?.incompleteHabitNames, <String>['Training']);
    expect(complete?.complete, isTrue);
    expect(complete?.incompleteHabitNames, isEmpty);
  });
}
