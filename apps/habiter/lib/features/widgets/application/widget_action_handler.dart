import 'dart:convert';
import 'dart:developer' as developer;

import '../../../core/ids/id_generator.dart';
import '../../../core/persistence/key_value_store.dart';
import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
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
       _undoStore = WidgetUndoStore(actionStore),
       _clock = clock,
       _completion = CompletionUseCase(
         repository: repository,
         ids: ids,
         clock: clock,
       ),
       _sync = sync;

  final HabitRepository _repository;
  final WidgetActionLedger _ledger;
  final WidgetUndoStore _undoStore;
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
    try {
      if (action.type == WidgetActionType.undoCompletion) {
        return _undo(action, locale: locale);
      }
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
      if (result.undoToken case final token?) {
        await _undoStore.save(action.actionId, token);
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
    } catch (error, stackTrace) {
      developer.log(
        'Widget action failed safely.',
        name: 'habiter.widget',
        error: error,
        stackTrace: stackTrace,
      );
      return const WidgetActionResult(WidgetActionStatus.failed);
    }
  }

  Future<WidgetActionResult> _undo(
    WidgetAction action, {
    required String locale,
  }) async {
    final sourceActionId = action.sourceActionId;
    if (sourceActionId == null) {
      return const WidgetActionResult(WidgetActionStatus.failed);
    }
    final token = await _undoStore.read(sourceActionId);
    if (token == null) {
      return const WidgetActionResult(WidgetActionStatus.failed);
    }
    final result = await _completion.undo(token);
    if (result.status != CompletionStatus.undone) {
      return const WidgetActionResult(WidgetActionStatus.failed);
    }
    await _ledger.record(action.actionId);
    await _undoStore.remove(sourceActionId);
    final snapshot = await _sync.synchronize(locale: locale);
    return WidgetActionResult(WidgetActionStatus.completed, snapshot: snapshot);
  }
}

final class WidgetUndoStore {
  const WidgetUndoStore(this._store);

  static const storageKey = 'habiter_widget_undo_tokens';
  final KeyValueStore _store;

  Future<void> save(String actionId, CompletionUndoToken token) async {
    final values = await _readAll();
    values[actionId] = <String, Object?>{
      'habitId': token.habitId,
      'date': token.date,
      'committedEntryId': token.committedEntryId,
      // Preserve the original zone representation because CompletionUseCase's
      // stale-undo guard intentionally compares the exact persisted DateTime.
      'committedAt': token.committedAt.toIso8601String(),
      'previousEntry': token.previousEntry?.toMap(),
    };
    await _store.write(storageKey, jsonEncode(values));
  }

  Future<CompletionUndoToken?> read(String actionId) async {
    final value = (await _readAll())[actionId];
    if (value is! Map) return null;
    final map = Map<String, Object?>.from(value);
    final previous = map['previousEntry'];
    return CompletionUndoToken(
      habitId: map['habitId']! as String,
      date: map['date']! as String,
      committedEntryId: map['committedEntryId']! as String,
      committedAt: DateTime.parse(map['committedAt']! as String),
      previousEntry: previous is Map
          ? HabitEntry.fromMap(Map<String, dynamic>.from(previous))
          : null,
    );
  }

  Future<void> remove(String actionId) async {
    final values = await _readAll()
      ..remove(actionId);
    await _store.write(storageKey, jsonEncode(values));
  }

  Future<Map<String, Object?>> _readAll() async {
    final value = await _store.read(storageKey);
    if (value == null) return <String, Object?>{};
    if (value is! String) throw const FormatException('Invalid undo store.');
    final decoded = jsonDecode(value);
    if (decoded is! Map) throw const FormatException('Invalid undo store.');
    return Map<String, Object?>.from(decoded);
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
