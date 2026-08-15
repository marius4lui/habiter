import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';

enum HabitLifecycleTransition {
  paused,
  resumed,
  archived,
  restored,
  deleted,
  ignored,
}

final class HabitLifecycleResult {
  const HabitLifecycleResult(this.transition);
  final HabitLifecycleTransition transition;
  bool get changed => transition != HabitLifecycleTransition.ignored;
}

final class HabitLifecycleUseCase {
  HabitLifecycleUseCase({
    required HabitRepository repository,
    required Clock clock,
  }) : _repository = repository,
       _clock = clock;

  final HabitRepository _repository;
  final Clock _clock;

  Future<HabitLifecycleResult> pause(String habitId) => _change(
    habitId,
    allowed: HabitLifecycleStatus.active,
    transition: HabitLifecycleTransition.paused,
    update: (habit, now) => habit.copyWith(
      isActive: false,
      pauses: <HabitPause>[
        ...habit.pauses,
        HabitPause(startedAt: now),
      ],
    ),
  );

  Future<HabitLifecycleResult> resume(String habitId) => _change(
    habitId,
    allowed: HabitLifecycleStatus.paused,
    transition: HabitLifecycleTransition.resumed,
    update: (habit, now) => habit.copyWith(
      isActive: true,
      pauses: <HabitPause>[
        ...habit.pauses.take(habit.pauses.length - 1),
        habit.pauses.last.end(now),
      ],
    ),
  );

  Future<HabitLifecycleResult> archive(String habitId) async {
    var result = const HabitLifecycleResult(HabitLifecycleTransition.ignored);
    await _repository.transact((draft) {
      final habit = draft.habits
          .where((value) => value.id == habitId)
          .firstOrNull;
      if (habit == null ||
          habit.lifecycleStatus == HabitLifecycleStatus.archived) {
        return;
      }
      final now = _clock.now();
      final pauses = habit.lifecycleStatus == HabitLifecycleStatus.paused
          ? <HabitPause>[
              ...habit.pauses.take(habit.pauses.length - 1),
              habit.pauses.last.end(now),
            ]
          : habit.pauses;
      draft.upsertHabit(
        habit.copyWith(isActive: false, pauses: pauses, archivedAt: now),
      );
      result = const HabitLifecycleResult(HabitLifecycleTransition.archived);
    });
    return result;
  }

  Future<HabitLifecycleResult> restore(String habitId) => _change(
    habitId,
    allowed: HabitLifecycleStatus.archived,
    transition: HabitLifecycleTransition.restored,
    update: (habit, now) => habit.copyWith(isActive: true, restoredAt: now),
  );

  Future<HabitLifecycleResult> delete(String habitId) async {
    var found = false;
    await _repository.transact((draft) {
      found = draft.habits.any((habit) => habit.id == habitId);
      if (found) draft.deleteHabit(habitId);
    });
    return HabitLifecycleResult(
      found
          ? HabitLifecycleTransition.deleted
          : HabitLifecycleTransition.ignored,
    );
  }

  Future<HabitLifecycleResult> _change(
    String habitId, {
    required HabitLifecycleStatus allowed,
    required HabitLifecycleTransition transition,
    required Habit Function(Habit habit, DateTime now) update,
  }) async {
    var result = const HabitLifecycleResult(HabitLifecycleTransition.ignored);
    await _repository.transact((draft) {
      final habit = draft.habits
          .where((value) => value.id == habitId)
          .firstOrNull;
      if (habit == null || habit.lifecycleStatus != allowed) return;
      draft.upsertHabit(update(habit, _clock.now()));
      result = HabitLifecycleResult(transition);
    });
    return result;
  }
}
