import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/persistence/storage_envelope.dart';
import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';
import '../domain/personal_sync_connection.dart';
import '../domain/personal_sync_contract.dart';
import '../domain/personal_sync_engine_state.dart';
import '../domain/personal_sync_operation.dart';
import '../domain/personal_sync_replica.dart';
import '../infrastructure/personal_sync_api_client.dart';
import '../infrastructure/syncing_habit_repository.dart';

enum PersonalSyncEnginePhase {
  idle,
  syncing,
  offline,
  retrying,
  authenticationRequired,
  protocolRequired,
  actionRequired,
}

typedef PersonalSyncProjectionReconciler = Future<void> Function();
typedef PersonalSyncRequest = Future<bool> Function();

final class PersonalSyncEngine extends ChangeNotifier
    implements PersonalSyncMutationRecorder {
  PersonalSyncEngine({
    required KeyValueStore store,
    required PersonalSyncRemoteFactory remoteFactory,
    required Clock clock,
    PersonalSyncProjectionReconciler? reconcileProjections,
    double Function()? random,
  }) : _store = store,
       _remoteFactory = remoteFactory,
       _clock = clock,
       _reconcileProjections = reconcileProjections,
       _random = random ?? Random.secure().nextDouble;

  static const storageKey = 'habiter_personal_sync_engine_v1';
  static const _pushBatchSize = 100;
  static const _pullBatchSize = 100;
  static const _maximumPullPages = 20;
  static const _debounce = Duration(milliseconds: 750);
  static const _pollInterval = Duration(minutes: 1);

  final KeyValueStore _store;
  final PersonalSyncRemoteFactory _remoteFactory;
  final Clock _clock;
  PersonalSyncProjectionReconciler? _reconcileProjections;
  final double Function() _random;

  PersonalSyncEngineState _state = PersonalSyncEngineState.empty();
  PersonalSyncEnginePhase _phase = PersonalSyncEnginePhase.idle;
  SyncingHabitRepository? _repository;
  PersonalSyncRequest? _requestSync;
  String? _deviceId;
  DateTime? _lastSuccessAt;
  DateTime? _retryAt;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Timer? _pollTimer;
  bool _online = true;
  bool _foreground = true;
  bool _syncing = false;
  int _failures = 0;

  PersonalSyncEnginePhase get phase => _phase;
  int get pendingOperations => _state.queue.length;
  DateTime? get lastSuccessAt => _lastSuccessAt;
  DateTime? get retryAt => _retryAt;

  void setProjectionReconciler(PersonalSyncProjectionReconciler reconciler) {
    _reconcileProjections = reconciler;
  }

  void attachRepository(SyncingHabitRepository repository) {
    if (_repository != null && !identical(_repository, repository)) {
      throw StateError('Personal Sync repository is already attached.');
    }
    _repository = repository;
  }

  Future<void> initialize() async {
    final envelopeValue = await _store.read(StorageEnvelope.storageKey);
    Object? stateValue;
    if (envelopeValue is String) {
      stateValue = StorageEnvelope.fromJson(envelopeValue).data[storageKey];
    } else {
      stateValue = await _store.read(storageKey);
    }
    _state = PersonalSyncEngineState.fromStorage(stateValue);
    notifyListeners();
  }

  void configureConnection(
    PersonalSyncConnection? connection, {
    PersonalSyncRequest? requestSync,
  }) {
    _deviceId = connection?.deviceId;
    _requestSync = connection == null ? null : requestSync;
    if (connection == null) {
      _cancelTimers();
      _phase = PersonalSyncEnginePhase.idle;
    } else {
      _restartPolling();
      if (_state.queue.isNotEmpty) _schedule(_debounce);
    }
    notifyListeners();
  }

  @override
  void capture(HabitRepositoryDraft before, HabitRepositoryDraft after) {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    var state = PersonalSyncEngineState.fromStorage(after.sidecar[storageKey]);
    final changes = _diff(before, after);
    for (final change in changes) {
      final revision = PersonalSyncRevision(
        deviceId: deviceId,
        sequence: state.sequence + 1,
      );
      final existing = state.replica.entities[change.entityId.value];
      final operation = change.operation(revision, existing);
      final applied = state.replica.apply(operation);
      state = state.copyWith(
        sequence: revision.sequence,
        queue: <PersonalSyncOperation>[...state.queue, operation],
        replica: applied.replica,
      );
    }
    after.sidecar[storageKey] = state.toStorage();
  }

  @override
  void didCommit(HabitRepositoryDraft committed) {
    _state = PersonalSyncEngineState.fromStorage(committed.sidecar[storageKey]);
    notifyListeners();
    if (_state.queue.isNotEmpty) _schedule(_debounce);
  }

  Future<void> captureSettings(Map<String, Object?> values) async {
    final deviceId = _deviceId;
    final repository = _repository;
    if (deviceId == null || repository == null || values.isEmpty) return;
    final validated = PersonalSyncSettingRegistry.validateValues(values);
    late PersonalSyncEngineState committed;
    await repository.transactWithoutCapture((draft) {
      var latest = PersonalSyncEngineState.fromStorage(
        draft.sidecar[storageKey],
      );
      for (final entry in validated.entries) {
        final entityId = PersonalSyncEntityId.setting(entry.key);
        final existing = latest.replica.entities[entityId.value];
        final currentValue = existing?.document?.payload?['value'];
        if (existing?.deleted == false &&
            _jsonEqual(currentValue, entry.value)) {
          continue;
        }
        final revision = PersonalSyncRevision(
          deviceId: deviceId,
          sequence: latest.sequence + 1,
        );
        final document = PersonalSyncEntityDocument(
          entityId: entityId,
          deleted: false,
          payload: <String, Object?>{'value': entry.value},
        );
        final operation = PersonalSyncOperation(
          kind: existing == null || !existing.isMaterialized
              ? PersonalSyncOperationKind.create
              : existing.deleted
              ? PersonalSyncOperationKind.restore
              : PersonalSyncOperationKind.patch,
          revision: revision,
          document: document,
          changedFields: const <String>{'value'},
        );
        latest = latest.copyWith(
          sequence: revision.sequence,
          queue: <PersonalSyncOperation>[...latest.queue, operation],
          replica: latest.replica.apply(operation).replica,
        );
      }
      draft.sidecar[storageKey] = latest.toStorage();
      committed = latest;
    });
    _state = committed;
    notifyListeners();
    if (_state.queue.isNotEmpty) _schedule(_debounce);
  }

  Future<void> synchronize(PersonalSyncConnection connection) async {
    if (_syncing) return;
    if (!_online) {
      _phase = PersonalSyncEnginePhase.offline;
      notifyListeners();
      throw const PersonalSyncRemoteException('network');
    }
    final repository = _repository;
    if (repository == null) {
      throw StateError('Personal Sync repository missing.');
    }
    _syncing = true;
    _phase = PersonalSyncEnginePhase.syncing;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _retryAt = null;
    notifyListeners();
    final remote = _remoteFactory(Uri.parse(connection.instanceOrigin));
    var projectionsChanged = false;
    try {
      while (_state.queue.isNotEmpty) {
        final batch = _state.queue.take(_pushBatchSize).toList(growable: false);
        await remote.push(batch, connection.accessToken);
        final acknowledged = batch
            .map((operation) => operation.operationId)
            .toSet();
        late PersonalSyncEngineState committed;
        await repository.transactWithoutCapture((draft) {
          final latest = PersonalSyncEngineState.fromStorage(
            draft.sidecar[storageKey],
          );
          final remaining = latest.queue
              .where(
                (operation) => !acknowledged.contains(operation.operationId),
              )
              .toList(growable: false);
          final updated = latest.copyWith(queue: remaining);
          draft.sidecar[storageKey] = updated.toStorage();
          committed = updated;
        });
        _state = committed;
      }

      for (var pageIndex = 0; pageIndex < _maximumPullPages; pageIndex += 1) {
        final page = await remote.pull(
          cursor: _state.replica.cursor,
          limit: _pullBatchSize,
          accessToken: connection.accessToken,
        );
        if (page.requiresSnapshot) {
          _phase = PersonalSyncEnginePhase.actionRequired;
          notifyListeners();
          throw const PersonalSyncRemoteException('action_required');
        }
        if (page.operations.isEmpty && _state.replica.cursor == page.cursor) {
          break;
        }
        late PersonalSyncEngineState committed;
        await repository.transactWithoutCapture((draft) {
          var latest = PersonalSyncEngineState.fromStorage(
            draft.sidecar[storageKey],
          );
          final applied = latest.replica.applyAll(page.operations);
          final replica = applied.replica.advanceCursor(page.cursor);
          var sequence = latest.sequence;
          for (final operation in page.operations) {
            sequence = max(sequence, operation.revision.sequence);
          }
          latest = latest.copyWith(sequence: sequence, replica: replica);
          _materialize(replica, draft);
          draft.sidecar[storageKey] = latest.toStorage();
          committed = latest;
          projectionsChanged |= applied.outcomes.values.any(
            (outcome) => outcome == PersonalSyncApplyOutcome.applied,
          );
        });
        _state = committed;
        if (page.cursor.offset >= page.headOffset) break;
        if (pageIndex == _maximumPullPages - 1) {
          _phase = PersonalSyncEnginePhase.actionRequired;
          notifyListeners();
          throw const PersonalSyncRemoteException('action_required');
        }
      }
      _failures = 0;
      _retryAt = null;
      _lastSuccessAt = _clock.now().toUtc();
      _phase = PersonalSyncEnginePhase.idle;
      notifyListeners();
      if (projectionsChanged) await _reconcileProjections?.call();
    } on PersonalSyncRemoteException catch (error) {
      if (error.code == 'authentication_required') {
        _phase = PersonalSyncEnginePhase.authenticationRequired;
        _retryTimer?.cancel();
      } else if (error.code == 'invalid_response' ||
          error.code == 'invalid_batch') {
        _phase = PersonalSyncEnginePhase.protocolRequired;
        _retryTimer?.cancel();
      } else if (error.code == 'action_required') {
        _phase = PersonalSyncEnginePhase.actionRequired;
        _retryTimer?.cancel();
      } else {
        _scheduleRetry();
      }
      notifyListeners();
      rethrow;
    } on PersonalSyncContractException {
      _phase = PersonalSyncEnginePhase.protocolRequired;
      _retryTimer?.cancel();
      notifyListeners();
      throw const PersonalSyncRemoteException('invalid_response');
    } on Object {
      _phase = PersonalSyncEnginePhase.actionRequired;
      _retryTimer?.cancel();
      notifyListeners();
      rethrow;
    } finally {
      remote.close();
      _syncing = false;
    }
  }

  void handleConnectivity(bool online) {
    if (_online == online) return;
    _online = online;
    if (!online) {
      _retryTimer?.cancel();
      _phase = PersonalSyncEnginePhase.offline;
    } else {
      _phase = PersonalSyncEnginePhase.idle;
      _schedule(Duration.zero);
    }
    notifyListeners();
  }

  void handleLifecycle(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _restartPolling();
      _schedule(Duration.zero);
    } else {
      _pollTimer?.cancel();
    }
  }

  void _schedule(Duration delay) {
    if (_requestSync == null || !_online || !_foreground || _syncing) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      final request = _requestSync;
      if (request != null) unawaited(request());
    });
  }

  void _scheduleRetry() {
    _failures += 1;
    final seconds = min(300, 1 << min(_failures, 8));
    final jitter = (seconds * .25 * _random()).round();
    final delay = Duration(seconds: seconds + jitter);
    _retryAt = _clock.now().toUtc().add(delay);
    _phase = PersonalSyncEnginePhase.retrying;
    _retryTimer?.cancel();
    if (_requestSync != null && _online && _foreground) {
      _retryTimer = Timer(delay, () {
        final request = _requestSync;
        if (request != null) unawaited(request());
      });
    }
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    if (_requestSync == null || !_foreground) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (_online && !_syncing) {
        final request = _requestSync;
        if (request != null) unawaited(request());
      }
    });
  }

  void _cancelTimers() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _pollTimer?.cancel();
    _retryAt = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

final class _EntityChange {
  const _EntityChange({
    required this.entityId,
    required this.before,
    required this.after,
  });

  final PersonalSyncEntityId entityId;
  final Map<String, Object?>? before;
  final Map<String, Object?>? after;

  PersonalSyncOperation operation(
    PersonalSyncRevision revision,
    PersonalSyncEntityState? existing,
  ) {
    final next = after;
    if (next == null) {
      return PersonalSyncOperation(
        kind: PersonalSyncOperationKind.delete,
        revision: revision,
        document: PersonalSyncEntityDocument(entityId: entityId, deleted: true),
        changedFields: const <String>[],
      );
    }
    if (existing == null || !existing.isMaterialized) {
      return PersonalSyncOperation(
        kind: PersonalSyncOperationKind.create,
        revision: revision,
        document: PersonalSyncEntityDocument(
          entityId: entityId,
          deleted: false,
          payload: next,
        ),
        changedFields: next.keys,
      );
    }
    if (existing.deleted) {
      return PersonalSyncOperation(
        kind: PersonalSyncOperationKind.restore,
        revision: revision,
        document: PersonalSyncEntityDocument(
          entityId: entityId,
          deleted: false,
          payload: next,
        ),
        changedFields: next.keys,
      );
    }
    final prior =
        before ?? existing.document?.payload ?? const <String, Object?>{};
    final payload = <String, Object?>{
      ...next,
      for (final key in prior.keys)
        if (!next.containsKey(key)) key: null,
    };
    final changed = <String>{
      ...prior.keys,
      ...next.keys,
    }.where((key) => !_jsonEqual(prior[key], next[key])).toSet();
    return PersonalSyncOperation(
      kind: PersonalSyncOperationKind.patch,
      revision: revision,
      document: PersonalSyncEntityDocument(
        entityId: entityId,
        deleted: false,
        payload: payload,
      ),
      changedFields: changed,
    );
  }
}

List<_EntityChange> _diff(
  HabitRepositoryDraft before,
  HabitRepositoryDraft after,
) {
  final previous = _documents(before);
  final next = _documents(after);
  final keys = <String>{...previous.keys, ...next.keys}.toList()..sort();
  return <_EntityChange>[
    for (final key in keys)
      if (!_jsonEqual(previous[key], next[key]))
        _EntityChange(
          entityId: PersonalSyncEntityId.parse(key),
          before: previous[key],
          after: next[key],
        ),
  ];
}

Map<String, Map<String, Object?>> _documents(HabitRepositoryDraft draft) =>
    <String, Map<String, Object?>>{
      for (final habit in draft.habits)
        PersonalSyncEntityId.habit(habit.id).value: Map<String, Object?>.from(
          habit.toMap(),
        ),
      for (final entry in draft.entries)
        PersonalSyncEntityId.entry(entry.habitId, entry.date).value:
            Map<String, Object?>.from(entry.toMap()),
    };

bool _jsonEqual(Object? left, Object? right) =>
    jsonEncode(_canonical(left)) == jsonEncode(_canonical(right));

Object? _canonical(Object? value) => switch (value) {
  Map<Object?, Object?> map => <String, Object?>{
    for (final key in map.keys.cast<String>().toList()..sort())
      key: _canonical(map[key]),
  },
  List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};

void _materialize(PersonalSyncReplica replica, HabitRepositoryDraft draft) {
  final documents = replica.documents.toList(growable: false);
  for (final document in documents.where(
    (item) => item.entityId.type == PersonalSyncEntityType.habit,
  )) {
    if (document.deleted) {
      draft.deleteHabit(document.entityId.components.single);
    } else {
      draft.upsertHabit(
        Habit.fromMap(Map<String, dynamic>.from(document.payload!)),
      );
    }
  }
  for (final document in documents.where(
    (item) => item.entityId.type == PersonalSyncEntityType.entry,
  )) {
    final habitId = document.entityId.components.first;
    final date = document.entityId.components.last;
    if (document.deleted) {
      draft.removeEntry(habitId, date);
    } else {
      draft.upsertEntry(
        HabitEntry.fromMap(Map<String, dynamic>.from(document.payload!)),
      );
    }
  }
}
