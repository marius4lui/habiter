import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/persistence/key_value_store.dart';
import 'package:habiter/core/persistence/storage_envelope.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/habits/application/habit_repository.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/personal_sync/application/personal_sync_engine.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_connection.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_contract.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_engine_state.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_operation.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_recovery_artifact.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_replica.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_api_client.dart';
import 'package:habiter/features/personal_sync/infrastructure/syncing_habit_repository.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test(
    'local queue is atomic, durable across restart, and debounce-triggered',
    () async {
      final fixture = await _fixture();
      var requests = 0;
      fixture.engine.configureConnection(
        _connection(),
        requestSync: () async {
          requests += 1;
          return true;
        },
      );

      await fixture.repository.transact(
        (draft) => draft.upsertHabit(_habit('Local')),
      );

      expect(fixture.remote.pushCalls, 0);
      expect(fixture.engine.pendingOperations, 1);
      expect(
        (await _state(fixture.store)).queue.single.kind,
        PersonalSyncOperationKind.create,
      );
      await Future<void>.delayed(const Duration(milliseconds: 850));
      expect(requests, 1);

      fixture.engine.dispose();
      final restarted = await _fixture(
        store: fixture.store,
        remote: fixture.remote,
      );
      restarted.engine.configureConnection(_connection());
      expect(restarted.engine.pendingOperations, 1);

      await restarted.engine.synchronize(_connection());

      expect(restarted.remote.pushCalls, 1);
      expect(restarted.engine.pendingOperations, 0);
      expect((await _state(restarted.store)).queue, isEmpty);
      restarted.engine.dispose();
    },
  );

  test(
    'captures create, field patch, entry, and tombstone mutation boundaries',
    () async {
      final fixture = await _fixture();
      fixture.engine.configureConnection(_connection());
      await fixture.repository.transact((draft) {
        draft.upsertHabit(_habit('First'));
        draft.upsertEntry(_entry());
      });
      await fixture.repository.transact((draft) {
        draft.upsertHabit(_habit('Renamed'));
      });
      await fixture.repository.transact(
        (draft) => draft.deleteHabit('habit-a'),
      );

      final operations = (await _state(fixture.store)).queue;
      expect(
        operations.map((operation) => operation.kind),
        <PersonalSyncOperationKind>[
          PersonalSyncOperationKind.create,
          PersonalSyncOperationKind.create,
          PersonalSyncOperationKind.patch,
          PersonalSyncOperationKind.delete,
          PersonalSyncOperationKind.delete,
        ],
      );
      expect(operations[2].changedFields, contains('name'));
      expect(operations.map((operation) => operation.revision.sequence), <int>[
        1,
        2,
        3,
        4,
        5,
      ]);
      fixture.engine.dispose();
    },
  );

  test(
    'remote apply is atomic, idempotent, echo-free, and reconciles projections',
    () async {
      var projections = 0;
      final remote = _Remote(
        pages: <PersonalSyncPullPage>[
          _page(<PersonalSyncOperation>[
            _remotePatch(sequence: 2, name: 'Remote newest'),
            _remoteCreate(sequence: 1, name: 'Remote original'),
          ], offset: 2),
        ],
      );
      final fixture = await _fixture(
        remote: remote,
        reconcile: () async => projections += 1,
      );
      fixture.engine.configureConnection(_connection());

      await fixture.engine.synchronize(_connection());

      final snapshot = await fixture.repository.load();
      expect(snapshot.habits.single.name, 'Remote newest');
      expect(fixture.engine.pendingOperations, 0);
      expect(projections, 1);
      expect((await _state(fixture.store)).replica.cursor?.offset, 2);

      remote.pageIndex = 0;
      await fixture.engine.synchronize(_connection());
      expect(
        (await fixture.repository.load()).habits.single.name,
        'Remote newest',
      );
      expect(fixture.engine.pendingOperations, 0);
      fixture.engine.dispose();
    },
  );

  test(
    'crash during remote apply leaves local data and cursor unchanged for replay',
    () async {
      final store = _FailingStore();
      final remote = _Remote(
        pages: <PersonalSyncPullPage>[
          _page(<PersonalSyncOperation>[
            _remoteCreate(sequence: 1, name: 'Recovered'),
          ], offset: 1),
        ],
      );
      final fixture = await _fixture(store: store, remote: remote);
      fixture.engine.configureConnection(_connection());
      store.failNextEnvelopeWrite = true;

      await expectLater(
        fixture.engine.synchronize(_connection()),
        throwsA(isA<HabitRepositoryException>()),
      );
      expect((await fixture.repository.load()).habits, isEmpty);
      expect((await _state(store)).replica.cursor, isNull);

      remote.pageIndex = 0;
      await fixture.engine.synchronize(_connection());
      expect((await fixture.repository.load()).habits.single.name, 'Recovered');
      expect((await _state(store)).replica.cursor?.offset, 1);
      fixture.engine.dispose();
    },
  );

  test(
    'retriable, offline, auth, and protocol failures have stable non-looping states',
    () async {
      final remote = _Remote();
      final fixture = await _fixture(remote: remote);
      fixture.engine.configureConnection(_connection());
      await fixture.repository.transact(
        (draft) => draft.upsertHabit(_habit('Queued')),
      );

      remote.pushError = const PersonalSyncRemoteException('network');
      await expectLater(
        fixture.engine.synchronize(_connection()),
        throwsA(isA<PersonalSyncRemoteException>()),
      );
      expect(fixture.engine.phase, PersonalSyncEnginePhase.retrying);
      expect(fixture.engine.retryAt, isNotNull);
      expect(fixture.engine.pendingOperations, 1);

      remote.pushError = const PersonalSyncRemoteException(
        'authentication_required',
      );
      await expectLater(
        fixture.engine.synchronize(_connection()),
        throwsA(isA<PersonalSyncRemoteException>()),
      );
      expect(
        fixture.engine.phase,
        PersonalSyncEnginePhase.authenticationRequired,
      );
      expect(fixture.engine.retryAt, isNull);

      fixture.engine.handleConnectivity(false);
      expect(fixture.engine.phase, PersonalSyncEnginePhase.offline);
      await expectLater(
        fixture.engine.synchronize(_connection()),
        throwsA(isA<PersonalSyncRemoteException>()),
      );
      fixture.engine.handleLifecycle(AppLifecycleState.paused);
      fixture.engine.handleConnectivity(true);
      fixture.engine.dispose();
    },
  );

  test('allow-listed setting mutations share the durable queue', () async {
    final fixture = await _fixture();
    fixture.engine.configureConnection(_connection());

    await fixture.engine.captureSettings(<String, Object?>{
      'appearance.theme': 'dark',
      'reminders.enabled': true,
    });

    final queue = (await _state(fixture.store)).queue;
    expect(queue, hasLength(2));
    expect(
      queue.map((operation) => operation.document.entityId.value),
      <String>['setting/appearance.theme', 'setting/reminders.enabled'],
    );
    fixture.engine.dispose();
  });

  test(
    'initial matrix uploads local-only and downloads remote-only data',
    () async {
      final localFixture = await _fixture();
      await localFixture.repository.transact(
        (draft) => draft.upsertHabit(_habit('Local before connection')),
      );
      localFixture.engine.configureConnection(_connection());
      await localFixture.engine.synchronize(_connection());
      expect(localFixture.remote.pushCalls, 1);
      expect(
        (await _recovery(localFixture.store)).reason,
        'initial_reconciliation',
      );
      localFixture.engine.dispose();

      final remoteOperation = _remoteCreate(sequence: 1, name: 'Remote only');
      final remoteState = PersonalSyncReplica.empty()
          .apply(remoteOperation)
          .replica;
      final remote = _Remote(
        snapshot: PersonalSyncSnapshot(
          cursor: PersonalSyncServerCursor(generation: 'epoch-a', offset: 1),
          entities: remoteState.entities.values.toList(),
        ),
      );
      final remoteFixture = await _fixture(remote: remote);
      remoteFixture.engine.configureConnection(_connection());
      await remoteFixture.engine.synchronize(_connection());
      expect(
        (await remoteFixture.repository.load()).habits.single.name,
        'Remote only',
      );
      expect(remoteFixture.remote.pushCalls, 0);
      remoteFixture.engine.dispose();
    },
  );

  test(
    'populated sides require confirmation and a verified recovery copy',
    () async {
      final remoteOperation = _remoteCreate(
        sequence: 1,
        name: 'Remote version',
      );
      final remoteState = PersonalSyncReplica.empty()
          .apply(remoteOperation)
          .replica;
      final remote = _Remote(
        snapshot: PersonalSyncSnapshot(
          cursor: PersonalSyncServerCursor(generation: 'epoch-a', offset: 1),
          entities: remoteState.entities.values.toList(),
        ),
      );
      final fixture = await _fixture(remote: remote);
      await fixture.repository.transact(
        (draft) => draft.upsertHabit(_habit('Local version')),
      );
      fixture.engine.configureConnection(
        _connection(),
        requestSync: () async {
          try {
            await fixture.engine.synchronize(_connection());
            return true;
          } on Object {
            return false;
          }
        },
      );

      await expectLater(
        fixture.engine.synchronize(_connection()),
        throwsA(
          isA<PersonalSyncRemoteException>().having(
            (error) => error.code,
            'code',
            'action_required',
          ),
        ),
      );
      expect(fixture.engine.phase, PersonalSyncEnginePhase.actionRequired);
      expect(fixture.engine.reconciliationPreview?.localEntities, 1);
      expect(fixture.engine.reconciliationPreview?.remoteEntities, 1);
      expect(fixture.remote.pushCalls, 0);

      await fixture.engine.confirmInitialReconciliation();

      expect(fixture.engine.reconciliationPreview, isNull);
      expect(fixture.remote.pushCalls, 1);
      expect((await _recovery(fixture.store)).sha256Digest, hasLength(64));
      fixture.engine.dispose();
    },
  );

  test(
    'expired cursor recovers from snapshot without losing queued work',
    () async {
      final remoteOperation = _remoteCreate(
        sequence: 3,
        name: 'Snapshot value',
      );
      final remoteState = PersonalSyncReplica.empty()
          .apply(remoteOperation)
          .replica;
      final remote = _Remote(
        pages: <PersonalSyncPullPage>[
          PersonalSyncPullPage(
            operations: const <PersonalSyncOperation>[],
            cursor: PersonalSyncServerCursor(generation: 'epoch-b', offset: 3),
            headOffset: 3,
            compactionFloor: 2,
            requiresSnapshot: true,
            recoveryReason: 'generation_changed',
          ),
        ],
        snapshot: PersonalSyncSnapshot(
          cursor: PersonalSyncServerCursor(generation: 'epoch-b', offset: 3),
          entities: remoteState.entities.values.toList(),
        ),
      );
      final fixture = await _fixture(remote: remote);
      fixture.engine.configureConnection(_connection());
      await fixture.engine.synchronize(_connection());
      remote.pageIndex = 0;
      await fixture.repository.transact(
        (draft) => draft.upsertHabit(_habit('Offline edit')),
      );

      await fixture.engine.synchronize(_connection());

      expect(
        (await _state(fixture.store)).replica.cursor?.generation,
        'epoch-b',
      );
      expect((await _recovery(fixture.store)).reason, 'generation_changed');
      expect(fixture.engine.phase, PersonalSyncEnginePhase.idle);
      fixture.engine.dispose();
    },
  );
}

Future<_Fixture> _fixture({
  KeyValueStore? store,
  _Remote? remote,
  Future<void> Function()? reconcile,
}) async {
  final resolvedStore = store ?? InMemoryKeyValueStore();
  if (!await resolvedStore.contains(StorageEnvelope.storageKey)) {
    await resolvedStore.write(
      StorageEnvelope.storageKey,
      StorageEnvelope(
        schemaVersion: StorageEnvelope.currentSchemaVersion,
        migratedAt: DateTime.utc(2026, 8, 22),
        data: const <String, Object?>{},
      ).toJson(),
    );
  }
  final resolvedRemote = remote ?? _Remote();
  final engine = PersonalSyncEngine(
    store: resolvedStore,
    remoteFactory: (_) => resolvedRemote,
    clock: _Clock(),
    reconcileProjections: reconcile,
    random: () => 0,
  );
  final repository = SyncingHabitRepository(
    delegate: KeyValueHabitRepository(
      resolvedStore,
      transactionalSidecarKeys: const <String>{
        PersonalSyncEngine.storageKey,
        PersonalSyncEngine.recoveryKey,
      },
    ),
    recorder: engine,
  );
  engine.attachRepository(repository);
  await engine.initialize();
  return _Fixture(engine, repository, resolvedRemote, resolvedStore);
}

final class _Fixture {
  const _Fixture(this.engine, this.repository, this.remote, this.store);
  final PersonalSyncEngine engine;
  final SyncingHabitRepository repository;
  final _Remote remote;
  final KeyValueStore store;
}

Future<PersonalSyncEngineState> _state(KeyValueStore store) async {
  final value = await store.read(StorageEnvelope.storageKey) as String;
  return PersonalSyncEngineState.fromStorage(
    StorageEnvelope.fromJson(value).data[PersonalSyncEngine.storageKey],
  );
}

Future<PersonalSyncRecoveryArtifact> _recovery(KeyValueStore store) async {
  final value = await store.read(StorageEnvelope.storageKey) as String;
  return PersonalSyncRecoveryArtifact.fromStorage(
    StorageEnvelope.fromJson(value).data[PersonalSyncEngine.recoveryKey],
  );
}

Habit _habit(String name) => Habit(
  id: 'habit-a',
  name: name,
  description: null,
  color: '#6750A4',
  icon: '🌱',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  customDays: null,
  createdAt: DateTime.utc(2026, 8, 22),
  isActive: true,
);

HabitEntry _entry() => HabitEntry(
  id: 'entry-a',
  habitId: 'habit-a',
  date: '2026-08-22',
  completed: true,
  count: 1,
  timestamp: DateTime.utc(2026, 8, 22, 12),
);

PersonalSyncOperation _remoteCreate({
  required int sequence,
  required String name,
}) => PersonalSyncOperation(
  kind: PersonalSyncOperationKind.create,
  revision: PersonalSyncRevision(deviceId: 'remote-phone', sequence: sequence),
  document: PersonalSyncEntityDocument(
    entityId: PersonalSyncEntityId.habit('habit-a'),
    deleted: false,
    payload: Map<String, Object?>.from(_habit(name).toMap()),
  ),
  changedFields: _habit(name).toMap().keys,
);

PersonalSyncOperation _remotePatch({
  required int sequence,
  required String name,
}) => PersonalSyncOperation(
  kind: PersonalSyncOperationKind.patch,
  revision: PersonalSyncRevision(deviceId: 'remote-phone', sequence: sequence),
  document: PersonalSyncEntityDocument(
    entityId: PersonalSyncEntityId.habit('habit-a'),
    deleted: false,
    payload: Map<String, Object?>.from(_habit(name).toMap()),
  ),
  changedFields: const <String>{'name'},
);

PersonalSyncPullPage _page(
  List<PersonalSyncOperation> operations, {
  required int offset,
}) => PersonalSyncPullPage(
  operations: operations,
  cursor: PersonalSyncServerCursor(generation: 'epoch-a', offset: offset),
  headOffset: offset,
  compactionFloor: 0,
  requiresSnapshot: false,
  recoveryReason: 'none',
);

PersonalSyncConnection _connection() => PersonalSyncConnection(
  instanceOrigin: 'https://sync.example.com',
  instanceName: 'Private Sync',
  deviceId: 'local-phone',
  accessToken: 'access-secret',
  accessExpiresAt: DateTime.utc(2026, 8, 22, 13),
  refreshToken: 'refresh-secret',
  refreshExpiresAt: DateTime.utc(2026, 9, 22),
  connectedAt: DateTime.utc(2026, 8, 22, 12),
  lastSuccessAt: DateTime.utc(2026, 8, 22, 12),
);

final class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 8, 22, 12);
}

final class _Remote implements PersonalSyncRemote {
  _Remote({
    this.pages = const <PersonalSyncPullPage>[],
    PersonalSyncSnapshot? snapshot,
  }) : snapshotValue =
           snapshot ??
           PersonalSyncSnapshot(
             cursor: PersonalSyncServerCursor(generation: 'epoch-a', offset: 0),
             entities: const <PersonalSyncEntityState>[],
           );
  final List<PersonalSyncPullPage> pages;
  PersonalSyncSnapshot snapshotValue;
  int pageIndex = 0;
  int pushCalls = 0;
  Object? pushError;

  @override
  Future<void> push(
    List<PersonalSyncOperation> operations,
    String accessToken,
  ) async {
    pushCalls += 1;
    if (pushError case final error?) throw error;
  }

  @override
  Future<PersonalSyncPullPage> pull({
    required PersonalSyncServerCursor? cursor,
    required int limit,
    required String accessToken,
  }) async {
    if (pageIndex < pages.length) return pages[pageIndex++];
    final current =
        cursor ?? PersonalSyncServerCursor(generation: 'epoch-a', offset: 0);
    return PersonalSyncPullPage(
      operations: const <PersonalSyncOperation>[],
      cursor: current,
      headOffset: current.offset,
      compactionFloor: 0,
      requiresSnapshot: false,
      recoveryReason: 'none',
    );
  }

  @override
  Future<PersonalSyncSnapshot> snapshot(String accessToken) async =>
      snapshotValue;

  @override
  void close() {}
  @override
  Future<PersonalSyncInstanceInfo> instanceInfo() => throw UnimplementedError();
  @override
  Future<PersonalSyncTokenPair> redeem({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String attemptId,
  }) => throw UnimplementedError();
  @override
  Future<PersonalSyncTokenPair> refresh(String refreshToken) =>
      throw UnimplementedError();
  @override
  Future<void> revokeAll(String accessToken) => throw UnimplementedError();
  @override
  Future<String> verifyDevice(String accessToken) => throw UnimplementedError();
}

final class _FailingStore implements KeyValueStore {
  final InMemoryKeyValueStore delegate = InMemoryKeyValueStore();
  bool failNextEnvelopeWrite = false;
  @override
  Future<bool> contains(String key) => delegate.contains(key);
  @override
  Future<Object?> read(String key) => delegate.read(key);
  @override
  Future<bool> remove(String key) => delegate.remove(key);
  @override
  Future<Map<String, Object?>> snapshot() => delegate.snapshot();
  @override
  Future<void> write(String key, Object value) async {
    if (key == StorageEnvelope.storageKey && failNextEnvelopeWrite) {
      failNextEnvelopeWrite = false;
      throw StateError('simulated process interruption');
    }
    await delegate.write(key, value);
  }
}
