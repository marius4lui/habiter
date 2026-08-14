import '../../../core/ids/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';

final class TodayController {
  TodayController({
    required HabitRepository repository,
    required IdGenerator ids,
    required Clock clock,
    required Future<void> Function() onChanged,
  }) : _repository = repository,
       _ids = ids,
       _clock = clock,
       _onChanged = onChanged;

  final HabitRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;
  final Future<void> Function() _onChanged;

  Future<void> toggle(String habitId, String date) async {
    await _repository.transact((draft) {
      final habit = draft.habits
          .where((item) => item.id == habitId)
          .firstOrNull;
      if (habit == null) return;
      final existing = draft.entries
          .where((entry) => entry.habitId == habitId && entry.date == date)
          .firstOrNull;
      final completed = !(existing?.completed ?? false);
      draft.upsertEntry(
        HabitEntry(
          id: existing?.id ?? _ids.next(),
          habitId: habitId,
          date: date,
          completed: completed,
          count: completed ? 1 : 0,
          timestamp: _clock.now(),
        ),
      );
      if (completed && habit.description == 'Imported from Classly') {
        draft.upsertHabit(habit.copyWith(isActive: false));
      }
    });
    await _onChanged();
  }
}
