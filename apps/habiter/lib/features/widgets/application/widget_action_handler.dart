import 'dart:convert';

import '../../../core/ids/id_generator.dart';
import '../../../core/persistence/key_value_store.dart';
import '../../../core/time/clock.dart';
import '../../habits/application/habit_repository.dart';
import '../../today/application/completion_use_case.dart';
import '../domain/widget_action.dart';
import '../domain/widget_snapshot.dart';
import 'widget_sync_controller.dart';

enum WidgetActionStatus { completed, alreadyProcessed, unsupported, failed }

final class WidgetActionResult {
  const WidgetActionResult(this.status, {this.snapshot});

  final WidgetActionStatus status;
  final WidgetSnapshot? snapshot;
}

final class WidgetActionHandler {
  WidgetActionHandler({
    required HabitRepository repository,
    required KeyValueStore actionStore,
    required IdGenerator ids,
    required Clock clock,
    required WidgetSyncController sync,
  }) : _repository = repository,
       _ledger = WidgetActionLedger(actionStore),
       _clock = clock,
       _completion = CompletionUseCase(
         repository: repository,
         ids: ids,
         clock: clock,
       ),
       _sync = sync;

  final HabitRepository _repository;
  final WidgetActionLedger _ledger;
  final Clock _clock;
  final CompletionUseCase _completion;
  final WidgetSyncController _sync;

  Future<WidgetActionResult> handle(
    WidgetAction action, {
    required String locale,
  }) async {
    if (await _ledger.contains(action.actionId)) {
      return const WidgetActionResult(WidgetActionStatus.alreadyProcessed);
    }
    if (action.type != WidgetActionType.completeHabit) {
      return const WidgetActionResult(WidgetActionStatus.unsupported);
    }
    try {
      final result = await _completion.complete(
        action.habitId,
        action.localDate,
      );
      final repositorySnapshot = await _repository.load();
      final habit = repositorySnapshot.habits
          .where((item) => item.id == action.habitId)
          .firstOrNull;
      if (result.status == CompletionStatus.habitNotFound || habit == null) {
        return const WidgetActionResult(WidgetActionStatus.failed);
      }
      await _ledger.record(action.actionId);
      final snapshot = await _sync.synchronize(
        locale: locale,
        lastCompletion: WidgetLastCompletion(
          habitId: habit.id,
          habitName: habit.name,
          actionId: action.actionId,
          completedAt: _clock.now(),
        ),
      );
      return WidgetActionResult(
        WidgetActionStatus.completed,
        snapshot: snapshot,
      );
    } catch (_) {
      return const WidgetActionResult(WidgetActionStatus.failed);
    }
  }
}

final class WidgetActionLedger {
  const WidgetActionLedger(this._store);

  static const storageKey = 'habiter_widget_action_ids';
  static const maximumEntries = 64;

  final KeyValueStore _store;

  Future<bool> contains(String actionId) async =>
      (await _read()).contains(actionId);

  Future<void> record(String actionId) async {
    final values = await _read();
    values.remove(actionId);
    values.add(actionId);
    final bounded = values.length <= maximumEntries
        ? values
        : values.sublist(values.length - maximumEntries);
    await _store.write(storageKey, jsonEncode(bounded));
  }

  Future<List<String>> _read() async {
    final value = await _store.read(storageKey);
    if (value == null) return <String>[];
    if (value is! String) throw const FormatException('Invalid action ledger.');
    final decoded = jsonDecode(value);
    if (decoded is! List) throw const FormatException('Invalid action ledger.');
    return decoded.cast<String>().toList();
  }
}
