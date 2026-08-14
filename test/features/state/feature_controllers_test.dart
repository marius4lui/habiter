import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/application/feature_status.dart';
import 'package:habiter/core/ids/id_generator.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/analytics/application/analytics_controller.dart';
import 'package:habiter/features/habits/application/habits_controller.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/history/application/history_controller.dart';
import 'package:habiter/features/today/application/today_controller.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  final now = DateTime.utc(2026, 8, 14, 9);

  test(
    'habits controller exposes immutable ready state and ordered adds',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      final controller = HabitsController(
        repository: repository,
        ids: _Ids(<String>['habit-1', 'habit-2']),
        clock: _Clock(now),
      );

      await controller.load();
      expect(controller.state.status, FeatureStatus.empty);
      await controller.add(
        name: 'First',
        category: 'Health',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        color: '#000000',
        icon: 'A',
      );
      await controller.add(
        name: 'Second',
        category: 'Health',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        color: '#000000',
        icon: 'B',
      );

      expect(controller.state.status, FeatureStatus.ready);
      expect(controller.state.habits.map((habit) => habit.name), [
        'Second',
        'First',
      ]);
      expect(
        () => controller.state.habits.add(controller.state.habits.first),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'today controller toggles deterministically and requests refresh',
    () async {
      final store = InMemoryKeyValueStore();
      final repository = KeyValueHabitRepository(store);
      final habits = HabitsController(
        repository: repository,
        ids: _Ids(<String>['habit-1']),
        clock: _Clock(now),
      );
      await habits.load();
      await habits.add(
        name: 'Walk',
        category: 'Health',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        color: '#000000',
        icon: 'W',
      );
      var refreshes = 0;
      final today = TodayController(
        repository: repository,
        ids: _Ids(<String>['entry-1']),
        clock: _Clock(now),
        onChanged: () async => refreshes++,
      );

      await today.toggle('habit-1', '2026-08-14');
      await today.toggle('habit-1', '2026-08-14');

      final snapshot = await repository.load();
      expect(snapshot.entries.single.completed, isFalse);
      expect(snapshot.entries.single.id, 'entry-1');
      expect(snapshot.entries.single.timestamp, now);
      expect(refreshes, 2);
    },
  );

  test('history and analytics derive read-only feature views', () async {
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    await repository.transact((draft) {
      draft.upsertHabit(_habit(now));
      draft.upsertEntry(_entry(now));
    });
    final history = HistoryController(repository);
    final analytics = AnalyticsController();

    await history.load();
    final stats = analytics.statsFor(_habit(now), history.state.entries);

    expect(history.state.status, FeatureStatus.ready);
    expect(history.state.entries, hasLength(1));
    expect(stats.totalCompletions, 1);
  });
}

Habit _habit(DateTime now) => Habit(
  id: 'habit-1',
  name: 'Walk',
  color: '#000000',
  icon: 'W',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  createdAt: now,
  isActive: true,
);

HabitEntry _entry(DateTime now) => HabitEntry(
  id: 'entry-1',
  habitId: 'habit-1',
  date: '2026-08-14',
  completed: true,
  count: 1,
  timestamp: now,
);

final class _Clock implements Clock {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

final class _Ids implements IdGenerator {
  _Ids(this.values);
  final List<String> values;
  @override
  String next() => values.removeAt(0);
}
