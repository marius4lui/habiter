import '../../../core/ids/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';
import '../../habits/domain/habit_source.dart';

enum CompletionStatus {
  completed,
  alreadyCompleted,
  habitNotFound,
  undone,
  staleUndo,
}

final class CompletionResult {
  const CompletionResult({required this.status, this.undoToken});

  final CompletionStatus status;
  final CompletionUndoToken? undoToken;

  bool get changed =>
      status == CompletionStatus.completed || status == CompletionStatus.undone;
}

final class CompletionUndoToken {
  const CompletionUndoToken({
    required this.habitId,
    required this.date,
    required this.committedEntryId,
    required this.committedAt,
    required this.previousEntry,
  });

  final String habitId;
  final String date;
  final String committedEntryId;
  final DateTime committedAt;
  final HabitEntry? previousEntry;
}

final class CompletionUseCase {
  CompletionUseCase({
    required HabitRepository repository,
    required IdGenerator ids,
    required Clock clock,
  }) : _repository = repository,
       _ids = ids,
       _clock = clock;

  final HabitRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<CompletionResult> complete(String habitId, String date) async {
    _validateDate(date);
    var result = const CompletionResult(status: CompletionStatus.habitNotFound);
    await _repository.transact((draft) {
      final habit = draft.habits
          .where((item) => item.id == habitId)
          .firstOrNull;
      if (habit == null) return;
      final previous = _occurrence(draft.entries, habitId, date);
      if (previous?.completed ?? false) {
        result = const CompletionResult(
          status: CompletionStatus.alreadyCompleted,
        );
        return;
      }

      final committedAt = _clock.now();
      final entry = HabitEntry(
        id: previous?.id ?? _ids.next(),
        habitId: habitId,
        date: date,
        completed: true,
        count: habit.targetCount,
        timestamp: committedAt,
      );
      draft.upsertEntry(entry);
      if (habit.source.kind == HabitSourceKind.classlyCompatible) {
        draft.upsertHabit(habit.copyWith(isActive: false));
      }
      result = CompletionResult(
        status: CompletionStatus.completed,
        undoToken: CompletionUndoToken(
          habitId: habitId,
          date: date,
          committedEntryId: entry.id,
          committedAt: committedAt,
          previousEntry: previous,
        ),
      );
    });
    return result;
  }

  Future<CompletionResult> undo(CompletionUndoToken token) async {
    var result = const CompletionResult(status: CompletionStatus.staleUndo);
    await _repository.transact((draft) {
      final current = _occurrence(draft.entries, token.habitId, token.date);
      if (current == null ||
          current.id != token.committedEntryId ||
          !current.completed ||
          current.timestamp != token.committedAt) {
        return;
      }
      final previous = token.previousEntry;
      if (previous == null) {
        draft.removeEntry(token.habitId, token.date);
      } else {
        draft.upsertEntry(previous);
      }
      result = const CompletionResult(status: CompletionStatus.undone);
    });
    return result;
  }

  HabitEntry? _occurrence(
    Iterable<HabitEntry> entries,
    String habitId,
    String date,
  ) => entries
      .where((entry) => entry.habitId == habitId && entry.date == date)
      .firstOrNull;

  void _validateDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Date must use yyyy-MM-dd.');
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException('Date is not a valid calendar day.');
    }
  }
}
