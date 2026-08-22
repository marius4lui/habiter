import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_contract.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_operation.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_replica.dart';

void main() {
  group('PersonalSyncOperation', () {
    test('roundtrips canonical operations and derives the idempotency key', () {
      final operation = _create(
        device: 'phone-a',
        sequence: 1,
        extraPayload: <String, Object?>{
          'futureProviderField': <String, Object?>{'revision': 3},
        },
        metadata: <String, Object?>{'futureDocumentField': true},
      );

      final decoded = PersonalSyncOperation.fromMap(operation.toMap());

      expect(decoded.operationId, 'operation/phone-a/1');
      expect(decoded.idempotencyKey, decoded.operationId);
      expect(decoded.toMap(), operation.toMap());
      expect(decoded.fingerprint, operation.fingerprint);
      expect(decoded.changedFields, contains('futureProviderField'));
      expect(decoded.changedMetadataFields, {'futureDocumentField'});
    });

    test('rejects partial creates, empty patches, and mismatched ids', () {
      expect(
        () => PersonalSyncOperation(
          kind: PersonalSyncOperationKind.create,
          revision: _revision('phone-a', 1),
          document: _habitDocument(),
          changedFields: const <String>{'name'},
        ),
        _contractError('incomplete_replacement'),
      );
      expect(
        () => PersonalSyncOperation(
          kind: PersonalSyncOperationKind.patch,
          revision: _revision('phone-a', 2),
          document: _habitDocument(),
          changedFields: const <String>{},
        ),
        _contractError('empty_patch'),
      );
      final encoded = _create(device: 'phone-a', sequence: 1).toMap()
        ..['operationId'] = 'operation/phone-b/1';
      expect(
        () => PersonalSyncOperation.fromMap(encoded),
        _contractError('operation_id_mismatch'),
      );
    });

    test('protects operation and document metadata from secrets', () {
      expect(
        () => _create(
          device: 'phone-a',
          sequence: 1,
          operationMetadata: <String, Object?>{'accessToken': 'nope'},
        ),
        _contractError('sensitive_operation'),
      );
      expect(
        () => _habitDocument(
          metadata: <String, Object?>{
            'nested': <String, Object?>{'apiKey': 'x'},
          },
        ),
        _contractError('sensitive_payload'),
      );
    });

    test('uses a logical revision and never accepts wall-clock ordering', () {
      expect(
        _revision('phone-z', 4).compareTo(_revision('phone-a', 4)),
        greaterThan(0),
      );
      expect(
        _revision('phone-a', 5).compareTo(_revision('phone-z', 4)),
        greaterThan(0),
      );
      expect(
        () => PersonalSyncRevision(deviceId: 'bad/device', sequence: 1),
        _contractError('invalid_device_id'),
      );
      expect(
        () => PersonalSyncRevision(deviceId: 'phone-a', sequence: 0),
        _contractError('invalid_revision'),
      );
      expect(
        PersonalSyncRevision.next(
          deviceId: 'phone-a',
          localSequence: 3,
          observed: <PersonalSyncRevision>[_revision('phone-b', 12)],
        ).sequence,
        13,
      );
      expect(
        () => PersonalSyncRevision.fromOperationId('operation/%ZZ/1'),
        _contractError('invalid_operation_id'),
      );
    });
  });

  group('PersonalSyncReplica convergence', () {
    test('merges independent concurrent fields in every arrival order', () {
      final operations = <PersonalSyncOperation>[
        _create(device: 'phone-a', sequence: 1),
        _patch(
          device: 'phone-a',
          sequence: 2,
          field: 'name',
          value: 'Morning walk',
        ),
        _patch(
          device: 'phone-b',
          sequence: 1,
          field: 'description',
          value: 'Outside before work',
        ),
      ];
      final expected = PersonalSyncReplica.empty()
          .applyAll(operations)
          .replica
          .canonicalEntityState();

      for (final order in _permutations(operations)) {
        final actual = PersonalSyncReplica.empty()
            .applyAll(order)
            .replica
            .canonicalEntityState();
        expect(
          actual,
          expected,
          reason: order.map((item) => item.operationId).join(', '),
        );
      }
      final document = PersonalSyncReplica.empty()
          .applyAll(operations.reversed)
          .replica
          .documents
          .single;
      expect(document.payload!['name'], 'Morning walk');
      expect(document.payload!['description'], 'Outside before work');
    });

    test(
      'same-field conflicts use sequence then device id deterministically',
      () {
        final operations = <PersonalSyncOperation>[
          _create(device: 'phone-a', sequence: 1),
          _patch(device: 'phone-a', sequence: 5, field: 'name', value: 'A'),
          _patch(device: 'phone-z', sequence: 5, field: 'name', value: 'Z'),
          _patch(
            device: 'phone-b',
            sequence: 6,
            field: 'name',
            value: 'Sequence wins',
          ),
        ];

        for (final order in _permutations(operations)) {
          final document = PersonalSyncReplica.empty()
              .applyAll(order)
              .replica
              .documents
              .single;
          expect(document.payload!['name'], 'Sequence wins');
        }
      },
    );

    test('duplicate operations are idempotent and collisions fail closed', () {
      final create = _create(device: 'phone-a', sequence: 1);
      final first = PersonalSyncReplica.empty().apply(create);
      final duplicate = first.replica.apply(create);

      expect(first.outcome, PersonalSyncApplyOutcome.applied);
      expect(duplicate.outcome, PersonalSyncApplyOutcome.duplicate);
      expect(identical(duplicate.replica, first.replica), isTrue);

      final collision = _create(
        device: 'phone-a',
        sequence: 1,
        name: 'Different content',
      );
      expect(
        () => first.replica.apply(collision),
        _contractError('idempotency_collision'),
      );
    });

    test('out-of-order patches wait for creation without losing changes', () {
      final patch = _patch(
        device: 'phone-a',
        sequence: 2,
        field: 'name',
        value: 'Arrived first',
      );
      final pending = PersonalSyncReplica.empty().apply(patch).replica;

      expect(pending.documents, isEmpty);

      final materialized = pending
          .apply(_create(device: 'phone-a', sequence: 1))
          .replica
          .documents
          .single;
      expect(materialized.payload!['name'], 'Arrived first');
    });

    test('tombstones block stale and newer ordinary patches until restore', () {
      final operations = <PersonalSyncOperation>[
        _create(device: 'phone-a', sequence: 1),
        _delete(device: 'phone-a', sequence: 4),
        _patch(device: 'phone-b', sequence: 3, field: 'name', value: 'Stale'),
        _patch(
          device: 'phone-b',
          sequence: 5,
          field: 'name',
          value: 'Still cannot resurrect',
        ),
      ];

      for (final order in _permutations(operations)) {
        final document = PersonalSyncReplica.empty()
            .applyAll(order)
            .replica
            .documents
            .single;
        expect(document.deleted, isTrue);
        expect(document.payload, isNull);
      }

      final restored = PersonalSyncReplica.empty()
          .applyAll(<PersonalSyncOperation>[
            ...operations,
            _restore(device: 'phone-a', sequence: 6, name: 'Recovered'),
          ])
          .replica
          .documents
          .single;
      expect(restored.deleted, isFalse);
      expect(restored.payload!['name'], 'Recovered');
    });

    test('future payload and document fields survive field-level merges', () {
      final create = _create(
        device: 'phone-a',
        sequence: 1,
        extraPayload: <String, Object?>{
          'future': <String, Object?>{'v': 1},
        },
        metadata: <String, Object?>{'documentFuture': 'kept'},
      );
      final patch = _patch(
        device: 'phone-b',
        sequence: 2,
        field: 'name',
        value: 'Renamed',
        extraPayload: <String, Object?>{
          'future': <String, Object?>{'v': 1},
        },
        metadata: <String, Object?>{'documentFuture': 'kept'},
      );

      final document = PersonalSyncReplica.empty()
          .applyAll(<PersonalSyncOperation>[patch, create])
          .replica
          .documents
          .single;
      expect(document.payload!['future'], <String, Object?>{'v': 1});
      expect(document.additionalFields['documentFuture'], 'kept');
    });

    test('metadata-only patches merge without replacing the payload', () {
      final create = _create(
        device: 'phone-a',
        sequence: 1,
        metadata: <String, Object?>{'futureMetadata': 'v1'},
      );
      final document = _habitDocument(
        metadata: <String, Object?>{'futureMetadata': 'v2'},
      );
      final metadataPatch = PersonalSyncOperation(
        kind: PersonalSyncOperationKind.patch,
        revision: _revision('phone-b', 2),
        document: document,
        changedFields: const <String>{},
        changedMetadataFields: const <String>{'futureMetadata'},
      );

      final merged = PersonalSyncReplica.empty()
          .applyAll(<PersonalSyncOperation>[metadataPatch, create])
          .replica
          .documents
          .single;
      expect(merged.payload!['name'], 'Walk');
      expect(merged.additionalFields['futureMetadata'], 'v2');
    });

    test('seeded operation shuffles converge to one canonical state', () {
      final operations = <PersonalSyncOperation>[
        _create(device: 'phone-a', sequence: 1),
        for (var index = 2; index <= 9; index++)
          _patch(
            device: index.isEven ? 'phone-a' : 'phone-b',
            sequence: index,
            field: index % 3 == 0 ? 'description' : 'name',
            value: 'value-$index',
          ),
        _delete(device: 'phone-c', sequence: 10),
        _restore(device: 'phone-a', sequence: 11, name: 'restored'),
        _patch(
          device: 'phone-z',
          sequence: 12,
          field: 'description',
          value: 'final',
        ),
      ];
      final expected = PersonalSyncReplica.empty()
          .applyAll(operations)
          .replica
          .canonicalEntityState();
      final random = Random(520058);

      for (var iteration = 0; iteration < 100; iteration++) {
        final shuffled = List<PersonalSyncOperation>.from(operations)
          ..shuffle(random);
        expect(
          PersonalSyncReplica.empty()
              .applyAll(shuffled)
              .replica
              .canonicalEntityState(),
          expected,
          reason: 'shuffle $iteration',
        );
      }
    });
  });

  group('cursor, compaction, and initial sync', () {
    test('replica state roundtrips for durable storage adapters', () {
      final original = PersonalSyncReplica.empty()
          .applyAll(<PersonalSyncOperation>[
            _create(device: 'phone-a', sequence: 1),
            _patch(
              device: 'phone-b',
              sequence: 2,
              field: 'name',
              value: 'Persisted',
            ),
          ])
          .replica
          .advanceCursor(
            PersonalSyncServerCursor(generation: 'epoch-1', offset: 8),
          );

      final restored = PersonalSyncReplica.fromMap(original.toMap());

      expect(restored.toMap(), original.toMap());
      expect(restored.documents.single.payload!['name'], 'Persisted');
      expect(restored.cursor, original.cursor);
    });

    test(
      'persisted state rejects unsupported versions and unsafe registers',
      () {
        final encoded = PersonalSyncReplica.empty()
            .apply(_create(device: 'phone-a', sequence: 1))
            .replica
            .toMap();
        expect(
          () => PersonalSyncReplica.fromMap(<String, Object?>{
            ...encoded,
            'schemaVersion': 2,
          }),
          _contractError('invalid_replica_state'),
        );
        final entity = Map<String, Object?>.from(
          (encoded['entities']! as List).single as Map,
        );
        final payloadFields = Map<String, Object?>.from(
          entity['payloadFields']! as Map,
        );
        payloadFields['apiToken'] = payloadFields['name'];
        entity['payloadFields'] = payloadFields;
        expect(
          () => PersonalSyncReplica.fromMap(<String, Object?>{
            ...encoded,
            'entities': <Object?>[entity],
          }),
          _contractError('invalid_replica_state'),
        );
      },
    );

    test('cursor tokens roundtrip and malformed tokens fail closed', () {
      final cursor = PersonalSyncServerCursor(
        generation: 'epoch-2',
        offset: 42,
      );

      expect(PersonalSyncServerCursor.parse(cursor.token), cursor);
      expect(
        () => PersonalSyncServerCursor.parse('${cursor.token}='),
        _contractError('invalid_cursor'),
      );
      expect(
        () => PersonalSyncServerCursor.parse('not-a-cursor'),
        _contractError('invalid_cursor'),
      );
    });

    test('cursor windows demand snapshots for every unsafe position', () {
      final window = PersonalSyncCursorWindow(
        generation: 'epoch-2',
        floorOffset: 10,
        headOffset: 20,
      );

      expect(window.evaluate(null).requiresSnapshot, isTrue);
      expect(
        window
            .evaluate(
              PersonalSyncServerCursor(generation: 'epoch-1', offset: 15),
            )
            .reason,
        PersonalSyncCursorRecoveryReason.generationChanged,
      );
      expect(
        window
            .evaluate(
              PersonalSyncServerCursor(generation: 'epoch-2', offset: 9),
            )
            .reason,
        PersonalSyncCursorRecoveryReason.missingCompactedHistory,
      );
      expect(
        window
            .evaluate(
              PersonalSyncServerCursor(generation: 'epoch-2', offset: 21),
            )
            .reason,
        PersonalSyncCursorRecoveryReason.cursorAhead,
      );
      expect(
        window
            .evaluate(
              PersonalSyncServerCursor(generation: 'epoch-2', offset: 10),
            )
            .requiresSnapshot,
        isFalse,
      );
    });

    test('cursor advancement is monotonic and snapshots change generation', () {
      final replica = PersonalSyncReplica.empty().advanceCursor(
        PersonalSyncServerCursor(generation: 'epoch-1', offset: 4),
      );
      expect(
        () => replica.advanceCursor(
          PersonalSyncServerCursor(generation: 'epoch-1', offset: 3),
        ),
        _contractError('cursor_regression'),
      );
      expect(
        () => replica.advanceCursor(
          PersonalSyncServerCursor(generation: 'epoch-2', offset: 5),
        ),
        _contractError('cursor_regression'),
      );
      expect(
        replica
            .replaceCursorAfterSnapshot(
              PersonalSyncServerCursor(generation: 'epoch-2', offset: 5),
            )
            .cursor!
            .generation,
        'epoch-2',
      );
    });

    test('acknowledged ledger compaction never removes entity tombstones', () {
      final replica =
          PersonalSyncReplica.empty().applyAll(<PersonalSyncOperation>[
            _create(device: 'phone-a', sequence: 1),
            _delete(device: 'phone-a', sequence: 2),
            _create(device: 'phone-b', sequence: 1, habitId: 'habit-b'),
          ]).replica;

      final compacted = replica.compactProcessedOperations(
        PersonalSyncCompactionWatermark(<String, int>{'phone-a': 2}),
      );

      expect(compacted.processedOperations.keys, {'operation/phone-b/1'});
      expect(
        compacted.documents
            .singleWhere(
              (document) => document.entityId.value == 'habit/habit-a',
            )
            .deleted,
        isTrue,
      );
    });

    test('initial sync matrix covers all local and remote combinations', () {
      expect(
        PersonalSyncReplica.planInitialSync(
          hasLocalEntities: false,
          hasRemoteEntities: false,
        ),
        PersonalSyncInitialSyncPlan.noChanges,
      );
      expect(
        PersonalSyncReplica.planInitialSync(
          hasLocalEntities: true,
          hasRemoteEntities: false,
        ),
        PersonalSyncInitialSyncPlan.uploadLocal,
      );
      expect(
        PersonalSyncReplica.planInitialSync(
          hasLocalEntities: false,
          hasRemoteEntities: true,
        ),
        PersonalSyncInitialSyncPlan.downloadRemote,
      );
      expect(
        PersonalSyncReplica.planInitialSync(
          hasLocalEntities: true,
          hasRemoteEntities: true,
        ),
        PersonalSyncInitialSyncPlan.reconcileBidirectional,
      );
    });
  });
}

PersonalSyncRevision _revision(String device, int sequence) =>
    PersonalSyncRevision(deviceId: device, sequence: sequence);

PersonalSyncOperation _create({
  required String device,
  required int sequence,
  String habitId = 'habit-a',
  String name = 'Walk',
  Map<String, Object?> extraPayload = const <String, Object?>{},
  Map<String, Object?> metadata = const <String, Object?>{},
  Map<String, Object?> operationMetadata = const <String, Object?>{},
}) {
  final document = _habitDocument(
    habitId: habitId,
    name: name,
    extraPayload: extraPayload,
    metadata: metadata,
  );
  return PersonalSyncOperation(
    kind: PersonalSyncOperationKind.create,
    revision: _revision(device, sequence),
    document: document,
    changedFields: document.payload!.keys,
    changedMetadataFields: document.additionalFields.keys,
    additionalFields: operationMetadata,
  );
}

PersonalSyncOperation _patch({
  required String device,
  required int sequence,
  required String field,
  required Object? value,
  Map<String, Object?> extraPayload = const <String, Object?>{},
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  final document = _habitDocument(
    name: field == 'name' ? value! as String : 'Walk',
    description: field == 'description' ? value as String? : 'Daily',
    extraPayload: extraPayload,
    metadata: metadata,
  );
  return PersonalSyncOperation(
    kind: PersonalSyncOperationKind.patch,
    revision: _revision(device, sequence),
    document: document,
    changedFields: <String>{field},
  );
}

PersonalSyncOperation _delete({required String device, required int sequence}) {
  return PersonalSyncOperation(
    kind: PersonalSyncOperationKind.delete,
    revision: _revision(device, sequence),
    document: PersonalSyncEntityDocument(
      entityId: PersonalSyncEntityId.habit('habit-a'),
      deleted: true,
    ),
    changedFields: const <String>{},
  );
}

PersonalSyncOperation _restore({
  required String device,
  required int sequence,
  required String name,
}) {
  final document = _habitDocument(name: name);
  return PersonalSyncOperation(
    kind: PersonalSyncOperationKind.restore,
    revision: _revision(device, sequence),
    document: document,
    changedFields: document.payload!.keys,
  );
}

PersonalSyncEntityDocument _habitDocument({
  String habitId = 'habit-a',
  String name = 'Walk',
  String? description = 'Daily',
  Map<String, Object?> extraPayload = const <String, Object?>{},
  Map<String, Object?> metadata = const <String, Object?>{},
}) => PersonalSyncEntityDocument(
  entityId: PersonalSyncEntityId.habit(habitId),
  deleted: false,
  payload: <String, Object?>{
    'id': habitId,
    'name': name,
    'description': description,
    'color': '#4CAF50',
    'icon': 'directions_walk',
    'frequency': 'daily',
    'targetCount': 1,
    'category': 'Health',
    'customDays': null,
    'createdAt': '2026-08-21T06:00:00.000Z',
    'isActive': true,
    'notificationEnabled': false,
    'notificationTime': null,
    ...extraPayload,
  },
  additionalFields: metadata,
);

Matcher _contractError(String code) => throwsA(
  isA<PersonalSyncContractException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

Iterable<List<T>> _permutations<T>(List<T> values) sync* {
  if (values.length <= 1) {
    yield List<T>.from(values);
    return;
  }
  for (var index = 0; index < values.length; index++) {
    final head = values[index];
    final tail = List<T>.from(values)..removeAt(index);
    for (final permutation in _permutations(tail)) {
      yield <T>[head, ...permutation];
    }
  }
}
