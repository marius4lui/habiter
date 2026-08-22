import 'dart:async';

import '../../habits/application/habit_repository.dart';

abstract interface class PersonalSyncMutationRecorder {
  void capture(HabitRepositoryDraft before, HabitRepositoryDraft after);
  void didCommit(HabitRepositoryDraft committed);
}

final class SyncingHabitRepository implements HabitRepository {
  SyncingHabitRepository({
    required HabitRepository delegate,
    required PersonalSyncMutationRecorder recorder,
  }) : _delegate = delegate,
       _recorder = recorder;

  final HabitRepository _delegate;
  final PersonalSyncMutationRecorder _recorder;

  @override
  Future<HabitRepositorySnapshot> load() => _delegate.load();

  @override
  Future<void> transact(
    FutureOr<void> Function(HabitRepositoryDraft draft) mutation,
  ) async {
    HabitRepositoryDraft? committed;
    await _delegate.transact((draft) async {
      final before = HabitRepositoryDraft(
        habits: draft.habits,
        entries: draft.entries,
        sidecar: draft.sidecar,
      );
      await mutation(draft);
      _recorder.capture(before, draft);
      committed = draft;
    });
    _recorder.didCommit(committed!);
  }

  Future<void> transactWithoutCapture(
    FutureOr<void> Function(HabitRepositoryDraft draft) mutation,
  ) => _delegate.transact(mutation);
}
