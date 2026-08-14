import '../../../core/ids/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';
import 'completion_use_case.dart';

final class TodayController {
  TodayController({
    required HabitRepository repository,
    required IdGenerator ids,
    required Clock clock,
    required Future<void> Function() onChanged,
  }) : _repository = repository,
       _completion = CompletionUseCase(
         repository: repository,
         ids: ids,
         clock: clock,
       ),
       _onChanged = onChanged;

  final HabitRepository _repository;
  final CompletionUseCase _completion;
  final Future<void> Function() _onChanged;

  Future<void> toggle(String habitId, String date) async {
    final snapshot = await _repository.load();
    final existing = snapshot.entries
        .where((entry) => entry.habitId == habitId && entry.date == date)
        .firstOrNull;
    if (existing?.completed ?? false) {
      await _repository.transact((draft) {
        draft.upsertEntry(
          HabitEntry(
            id: existing!.id,
            habitId: habitId,
            date: date,
            completed: false,
            count: 0,
            timestamp: existing.timestamp,
          ),
        );
      });
      await _onChanged();
      return;
    }
    final result = await complete(habitId, date);
    if (!result.changed) return;
  }

  Future<CompletionResult> complete(String habitId, String date) async {
    final result = await _completion.complete(habitId, date);
    if (result.changed) await _onChanged();
    return result;
  }

  Future<CompletionResult> undo(CompletionUndoToken token) async {
    final result = await _completion.undo(token);
    if (result.changed) await _onChanged();
    return result;
  }
}
