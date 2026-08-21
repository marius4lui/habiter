import 'dart:collection';

import 'personal_sync_contract.dart';
import 'personal_sync_operation.dart';

enum PersonalSyncApplyOutcome { applied, superseded, duplicate }

enum PersonalSyncInitialSyncPlan {
  noChanges,
  uploadLocal,
  downloadRemote,
  reconcileBidirectional,
}

final class PersonalSyncFieldRegister {
  const PersonalSyncFieldRegister({
    required this.value,
    required this.revision,
  });

  final Object? value;
  final PersonalSyncRevision revision;
}

final class PersonalSyncEntityState {
  PersonalSyncEntityState._({
    required this.entityId,
    required Map<String, PersonalSyncFieldRegister> payloadFields,
    required Map<String, PersonalSyncFieldRegister> metadataFields,
    required this.lifecycleRevision,
    required this.deleted,
  }) : payloadFields = UnmodifiableMapView(payloadFields),
       metadataFields = UnmodifiableMapView(metadataFields);

  factory PersonalSyncEntityState.empty(PersonalSyncEntityId entityId) =>
      PersonalSyncEntityState._(
        entityId: entityId,
        payloadFields: <String, PersonalSyncFieldRegister>{},
        metadataFields: <String, PersonalSyncFieldRegister>{},
        lifecycleRevision: null,
        deleted: false,
      );

  factory PersonalSyncEntityState.fromMap(Map<String, Object?> map) {
    final entityIdValue = map['entityId'];
    final lifecycleValue = map['lifecycleRevision'];
    final deleted = map['deleted'];
    final payloadValue = map['payloadFields'];
    final metadataValue = map['metadataFields'];
    if (entityIdValue is! String ||
        (lifecycleValue != null && lifecycleValue is! Map) ||
        deleted is! bool ||
        payloadValue is! Map ||
        metadataValue is! Map) {
      throw const PersonalSyncContractException(
        'invalid_replica_state',
        'Persisted entity state fields have invalid types.',
      );
    }
    final lifecycle = lifecycleValue == null
        ? null
        : PersonalSyncRevision.fromMap(
            Map<String, Object?>.from(lifecycleValue as Map),
          );
    if (lifecycle == null && deleted) {
      throw const PersonalSyncContractException(
        'invalid_replica_state',
        'An unmaterialized entity cannot be deleted.',
      );
    }
    final state = PersonalSyncEntityState._(
      entityId: PersonalSyncEntityId.parse(entityIdValue),
      payloadFields: _registersFromMap(payloadValue),
      metadataFields: _registersFromMap(metadataValue),
      lifecycleRevision: lifecycle,
      deleted: deleted,
    );
    if (state.isMaterialized) state.document;
    return state;
  }

  final PersonalSyncEntityId entityId;
  final Map<String, PersonalSyncFieldRegister> payloadFields;
  final Map<String, PersonalSyncFieldRegister> metadataFields;
  final PersonalSyncRevision? lifecycleRevision;
  final bool deleted;

  bool get isMaterialized => lifecycleRevision != null;

  PersonalSyncEntityDocument? get document {
    final lifecycle = lifecycleRevision;
    if (lifecycle == null) return null;
    final metadata = _visibleValues(metadataFields, lifecycle);
    if (deleted) {
      return PersonalSyncEntityDocument(
        entityId: entityId,
        deleted: true,
        additionalFields: metadata,
      );
    }
    return PersonalSyncEntityDocument(
      entityId: entityId,
      deleted: false,
      payload: _visibleValues(payloadFields, lifecycle),
      additionalFields: metadata,
    );
  }

  _EntityApplyResult _apply(PersonalSyncOperation operation) {
    final payload = Map<String, PersonalSyncFieldRegister>.from(payloadFields);
    final metadata = Map<String, PersonalSyncFieldRegister>.from(
      metadataFields,
    );
    var changed = _mergeRegisters(
      payload,
      operation.changedFields,
      operation.document.payload ?? const <String, Object?>{},
      operation.revision,
    );
    changed =
        _mergeRegisters(
          metadata,
          operation.changedMetadataFields,
          operation.document.additionalFields,
          operation.revision,
        ) ||
        changed;

    var nextLifecycle = lifecycleRevision;
    var nextDeleted = deleted;
    switch (operation.kind) {
      case PersonalSyncOperationKind.create:
        if (nextLifecycle == null ||
            (!nextDeleted && operation.revision.compareTo(nextLifecycle) > 0)) {
          nextLifecycle = operation.revision;
          nextDeleted = false;
          changed = true;
        }
      case PersonalSyncOperationKind.patch:
        break;
      case PersonalSyncOperationKind.delete:
        if (nextLifecycle == null ||
            operation.revision.compareTo(nextLifecycle) > 0) {
          nextLifecycle = operation.revision;
          nextDeleted = true;
          changed = true;
        }
      case PersonalSyncOperationKind.restore:
        if (nextLifecycle == null ||
            operation.revision.compareTo(nextLifecycle) > 0) {
          nextLifecycle = operation.revision;
          nextDeleted = false;
          changed = true;
        }
    }

    final next = PersonalSyncEntityState._(
      entityId: entityId,
      payloadFields: payload,
      metadataFields: metadata,
      lifecycleRevision: nextLifecycle,
      deleted: nextDeleted,
    );
    if (next.isMaterialized) {
      next.document;
    }
    return _EntityApplyResult(state: next, changed: changed);
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'entityId': entityId.value,
    'lifecycleRevision': lifecycleRevision?.toMap(),
    'deleted': deleted,
    'payloadFields': _registersToMap(payloadFields),
    'metadataFields': _registersToMap(metadataFields),
  };
}

final class PersonalSyncReplica {
  PersonalSyncReplica._({
    required Map<String, PersonalSyncEntityState> entities,
    required Map<String, String> processedOperations,
    required this.cursor,
  }) : entities = UnmodifiableMapView(entities),
       processedOperations = UnmodifiableMapView(processedOperations);

  factory PersonalSyncReplica.empty({PersonalSyncServerCursor? cursor}) =>
      PersonalSyncReplica._(
        entities: <String, PersonalSyncEntityState>{},
        processedOperations: <String, String>{},
        cursor: cursor,
      );

  factory PersonalSyncReplica.fromMap(Map<String, Object?> map) {
    final schemaVersion = map['schemaVersion'];
    final entitiesValue = map['entities'];
    final operationsValue = map['processedOperations'];
    final cursorValue = map['cursor'];
    if (schemaVersion != stateSchemaVersion ||
        entitiesValue is! List ||
        entitiesValue.any((value) => value is! Map) ||
        operationsValue is! Map ||
        cursorValue is! String?) {
      throw const PersonalSyncContractException(
        'invalid_replica_state',
        'Persisted replica fields are invalid or unsupported.',
      );
    }
    final entities = <String, PersonalSyncEntityState>{};
    for (final value in entitiesValue) {
      final state = PersonalSyncEntityState.fromMap(
        Map<String, Object?>.from(value as Map),
      );
      if (entities.containsKey(state.entityId.value)) {
        throw const PersonalSyncContractException(
          'invalid_replica_state',
          'Persisted replica contains a duplicate entity.',
        );
      }
      entities[state.entityId.value] = state;
    }
    final operations = <String, String>{};
    for (final entry in operationsValue.entries) {
      if (entry.key is! String ||
          entry.value is! String ||
          (entry.value! as String).isEmpty) {
        throw const PersonalSyncContractException(
          'invalid_replica_state',
          'Persisted processed operations are invalid.',
        );
      }
      PersonalSyncRevision.fromOperationId(entry.key! as String);
      operations[entry.key! as String] = entry.value! as String;
    }
    return PersonalSyncReplica._(
      entities: entities,
      processedOperations: operations,
      cursor: cursorValue == null
          ? null
          : PersonalSyncServerCursor.parse(cursorValue),
    );
  }

  static const stateSchemaVersion = 1;

  final Map<String, PersonalSyncEntityState> entities;
  final Map<String, String> processedOperations;
  final PersonalSyncServerCursor? cursor;

  Iterable<PersonalSyncEntityDocument> get documents sync* {
    final keys = entities.keys.toList()..sort();
    for (final key in keys) {
      final document = entities[key]!.document;
      if (document != null) yield document;
    }
  }

  PersonalSyncApplyResult apply(PersonalSyncOperation operation) {
    final fingerprint = processedOperations[operation.operationId];
    if (fingerprint != null) {
      if (fingerprint != operation.fingerprint) {
        throw const PersonalSyncContractException(
          'idempotency_collision',
          'An operation identifier was reused with different content.',
        );
      }
      return PersonalSyncApplyResult(
        replica: this,
        outcome: PersonalSyncApplyOutcome.duplicate,
      );
    }

    final entitiesCopy = Map<String, PersonalSyncEntityState>.from(entities);
    final current =
        entitiesCopy[operation.document.entityId.value] ??
        PersonalSyncEntityState.empty(operation.document.entityId);
    final applied = current._apply(operation);
    entitiesCopy[operation.document.entityId.value] = applied.state;
    final operationsCopy = Map<String, String>.from(processedOperations)
      ..[operation.operationId] = operation.fingerprint;
    return PersonalSyncApplyResult(
      replica: PersonalSyncReplica._(
        entities: entitiesCopy,
        processedOperations: operationsCopy,
        cursor: cursor,
      ),
      outcome: applied.changed
          ? PersonalSyncApplyOutcome.applied
          : PersonalSyncApplyOutcome.superseded,
    );
  }

  PersonalSyncBatchApplyResult applyAll(
    Iterable<PersonalSyncOperation> operations,
  ) {
    var current = this;
    final outcomes = <String, PersonalSyncApplyOutcome>{};
    for (final operation in operations) {
      final result = current.apply(operation);
      current = result.replica;
      outcomes[operation.operationId] = result.outcome;
    }
    return PersonalSyncBatchApplyResult(replica: current, outcomes: outcomes);
  }

  PersonalSyncReplica advanceCursor(PersonalSyncServerCursor next) {
    final current = cursor;
    if (current != null &&
        (current.generation != next.generation ||
            next.offset < current.offset)) {
      throw const PersonalSyncContractException(
        'cursor_regression',
        'Incremental cursors must advance within one generation.',
      );
    }
    return PersonalSyncReplica._(
      entities: Map<String, PersonalSyncEntityState>.from(entities),
      processedOperations: Map<String, String>.from(processedOperations),
      cursor: next,
    );
  }

  PersonalSyncReplica replaceCursorAfterSnapshot(
    PersonalSyncServerCursor snapshotCursor,
  ) => PersonalSyncReplica._(
    entities: Map<String, PersonalSyncEntityState>.from(entities),
    processedOperations: Map<String, String>.from(processedOperations),
    cursor: snapshotCursor,
  );

  PersonalSyncReplica compactProcessedOperations(
    PersonalSyncCompactionWatermark watermark,
  ) {
    final compacted = Map<String, String>.from(processedOperations)
      ..removeWhere(
        (operationId, _) => watermark.acknowledges(
          PersonalSyncRevision.fromOperationId(operationId),
        ),
      );
    return PersonalSyncReplica._(
      entities: Map<String, PersonalSyncEntityState>.from(entities),
      processedOperations: compacted,
      cursor: cursor,
    );
  }

  Map<String, Object?> canonicalEntityState() => <String, Object?>{
    for (final key in entities.keys.toList()..sort())
      key: entities[key]!.toMap(),
  };

  Map<String, Object?> toMap() => <String, Object?>{
    'schemaVersion': stateSchemaVersion,
    'entities': <Map<String, Object?>>[
      for (final key in entities.keys.toList()..sort()) entities[key]!.toMap(),
    ],
    'processedOperations': <String, String>{
      for (final key in processedOperations.keys.toList()..sort())
        key: processedOperations[key]!,
    },
    if (cursor != null) 'cursor': cursor!.token,
  };

  static PersonalSyncInitialSyncPlan planInitialSync({
    required bool hasLocalEntities,
    required bool hasRemoteEntities,
  }) => switch ((hasLocalEntities, hasRemoteEntities)) {
    (false, false) => PersonalSyncInitialSyncPlan.noChanges,
    (true, false) => PersonalSyncInitialSyncPlan.uploadLocal,
    (false, true) => PersonalSyncInitialSyncPlan.downloadRemote,
    (true, true) => PersonalSyncInitialSyncPlan.reconcileBidirectional,
  };
}

final class PersonalSyncApplyResult {
  const PersonalSyncApplyResult({required this.replica, required this.outcome});

  final PersonalSyncReplica replica;
  final PersonalSyncApplyOutcome outcome;
}

final class PersonalSyncBatchApplyResult {
  PersonalSyncBatchApplyResult({
    required this.replica,
    required Map<String, PersonalSyncApplyOutcome> outcomes,
  }) : outcomes = UnmodifiableMapView(outcomes);

  final PersonalSyncReplica replica;
  final Map<String, PersonalSyncApplyOutcome> outcomes;
}

final class PersonalSyncCompactionWatermark {
  PersonalSyncCompactionWatermark(Map<String, int> sequences)
    : sequences = UnmodifiableMapView(Map<String, int>.from(sequences)) {
    for (final entry in this.sequences.entries) {
      PersonalSyncRevision(deviceId: entry.key, sequence: 1);
      if (entry.value < 0) {
        throw const PersonalSyncContractException(
          'invalid_compaction_watermark',
          'Compaction watermark sequences must not be negative.',
        );
      }
    }
  }

  final Map<String, int> sequences;

  bool acknowledges(PersonalSyncRevision revision) =>
      revision.sequence <= (sequences[revision.deviceId] ?? 0);
}

final class _EntityApplyResult {
  const _EntityApplyResult({required this.state, required this.changed});

  final PersonalSyncEntityState state;
  final bool changed;
}

bool _mergeRegisters(
  Map<String, PersonalSyncFieldRegister> target,
  Iterable<String> changedFields,
  Map<String, Object?> values,
  PersonalSyncRevision revision,
) {
  var changed = false;
  for (final field in changedFields) {
    final current = target[field];
    if (current == null || revision.compareTo(current.revision) > 0) {
      target[field] = PersonalSyncFieldRegister(
        value: values[field],
        revision: revision,
      );
      changed = true;
    }
  }
  return changed;
}

Map<String, Object?> _visibleValues(
  Map<String, PersonalSyncFieldRegister> fields,
  PersonalSyncRevision lifecycle,
) => <String, Object?>{
  for (final key in fields.keys.toList()..sort())
    if (fields[key]!.revision.compareTo(lifecycle) >= 0)
      key: fields[key]!.value,
};

Map<String, Object?> _registersToMap(
  Map<String, PersonalSyncFieldRegister> registers,
) => <String, Object?>{
  for (final key in registers.keys.toList()..sort())
    key: <String, Object?>{
      'value': registers[key]!.value,
      'revision': registers[key]!.revision.toMap(),
    },
};

Map<String, PersonalSyncFieldRegister> _registersFromMap(Map value) {
  final registers = <String, PersonalSyncFieldRegister>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! Map) {
      throw const PersonalSyncContractException(
        'invalid_replica_state',
        'Persisted field registers are invalid.',
      );
    }
    final field = entry.key! as String;
    final register = Map<String, Object?>.from(entry.value! as Map);
    final revision = register['revision'];
    if (field.trim().isEmpty ||
        _sensitiveKey.hasMatch(field) ||
        register.length != 2 ||
        !register.containsKey('value') ||
        revision is! Map) {
      throw const PersonalSyncContractException(
        'invalid_replica_state',
        'Persisted field registers are invalid.',
      );
    }
    registers[field] = PersonalSyncFieldRegister(
      value: _copyJson(register['value']),
      revision: PersonalSyncRevision.fromMap(
        Map<String, Object?>.from(revision),
      ),
    );
  }
  return registers;
}

Object? _copyJson(Object? value) => switch (value) {
  null || bool() || String() => value,
  num number when number.isFinite => number,
  List<Object?> values => List<Object?>.unmodifiable(values.map(_copyJson)),
  Map<Object?, Object?> values => Map<String, Object?>.unmodifiable(
    values.map((key, value) {
      if (key is! String || _sensitiveKey.hasMatch(key)) {
        throw const PersonalSyncContractException(
          'invalid_replica_state',
          'Persisted register values contain an unsafe object key.',
        );
      }
      return MapEntry<String, Object?>(key, _copyJson(value));
    }),
  ),
  _ => throw const PersonalSyncContractException(
    'invalid_replica_state',
    'Persisted register values must be JSON-compatible.',
  ),
};

final RegExp _sensitiveKey = RegExp(
  r'(token|secret|password|api.?key|credential)',
  caseSensitive: false,
);
