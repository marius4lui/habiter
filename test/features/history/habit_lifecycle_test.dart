import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/history/application/habit_lifecycle_use_case.dart';
import 'package:habiter/features/history/application/habit_timeline.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/utils/habit_utils.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  final pausedAt = DateTime.utc(2026, 8, 10, 12);
  final resumedAt = DateTime.utc(2026, 8, 12, 8);

  test('pause metadata roundtrips without changing legacy defaults', () {
    final habit = _habit().copyWith(
      isActive: false,
      pauses: <HabitPause>[HabitPause(startedAt: pausedAt)],
    );

    final decoded = Habit.fromMap(habit.toMap());

    expect(decoded.lifecycleStatus, HabitLifecycleStatus.paused);
    expect(decoded.pauses.single.startedAt, pausedAt);
    expect(decoded.pauses.single.endedAt, isNull);
    expect(
      Habit.fromMap(_habit().toMap()).lifecycleStatus,
      HabitLifecycleStatus.active,
    );
  });

  test(
    'pause, resume, archive and restore preserve a forgiving timeline',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      await repository.transact((draft) => draft.upsertHabit(_habit()));
      final lifecycle = HabitLifecycleUseCase(
        repository: repository,
        clock: _SequenceClock(<DateTime>[
          pausedAt,
          resumedAt,
          resumedAt.add(const Duration(days: 1)),
          resumedAt.add(const Duration(days: 2)),
        ]),
      );

      expect((await lifecycle.pause('habit-1')).changed, isTrue);
      expect(
        (await repository.load()).habits.single.lifecycleStatus,
        HabitLifecycleStatus.paused,
      );
      expect((await lifecycle.resume('habit-1')).changed, isTrue);
      var habit = (await repository.load()).habits.single;
      expect(habit.lifecycleStatus, HabitLifecycleStatus.active);
      expect(habit.pauses.single.endedAt, resumedAt);

      await lifecycle.archive('habit-1');
      habit = (await repository.load()).habits.single;
      expect(habit.lifecycleStatus, HabitLifecycleStatus.archived);
      await lifecycle.restore('habit-1');
      habit = (await repository.load()).habits.single;
      expect(habit.lifecycleStatus, HabitLifecycleStatus.active);

      final timeline = HabitTimeline.forHabit(habit);
      expect(timeline.map((event) => event.type), <HabitTimelineEventType>[
        HabitTimelineEventType.created,
        HabitTimelineEventType.paused,
        HabitTimelineEventType.resumed,
        HabitTimelineEventType.archived,
        HabitTimelineEventType.restored,
      ]);
    },
  );

  test(
    'pause ranges are excluded from stats and delete remains cascading',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      final habit = _habit().copyWith(
        pauses: <HabitPause>[
          HabitPause(startedAt: pausedAt, endedAt: resumedAt),
        ],
      );
      await repository.transact((draft) {
        draft.upsertHabit(habit);
        draft.upsertEntry(_entry('2026-08-09'));
        draft.upsertEntry(_entry('2026-08-11'));
      });

      expect(
        calculateHabitStats(
          habit,
          (await repository.load()).entries,
        ).totalCompletions,
        1,
      );
      final lifecycle = HabitLifecycleUseCase(
        repository: repository,
        clock: _SequenceClock(<DateTime>[resumedAt]),
      );
      await lifecycle.delete('habit-1');
      final snapshot = await repository.load();
      expect(snapshot.habits, isEmpty);
      expect(snapshot.entries, isEmpty);
    },
  );
}

Habit _habit() => Habit(
  id: 'habit-1',
  name: 'Walk',
  color: '#000000',
  icon: 'W',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  createdAt: DateTime.utc(2026, 8, 1),
  isActive: true,
);

HabitEntry _entry(String date) => HabitEntry(
  id: 'entry-$date',
  habitId: 'habit-1',
  date: date,
  completed: true,
  count: 1,
  timestamp: DateTime.parse('${date}T08:00:00Z'),
);

final class _SequenceClock implements Clock {
  _SequenceClock(this.values);
  final List<DateTime> values;
  @override
  DateTime now() => values.removeAt(0);
}
