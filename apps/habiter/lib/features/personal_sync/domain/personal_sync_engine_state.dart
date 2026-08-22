import 'dart:collection';
import 'dart:convert';

import 'personal_sync_operation.dart';
import 'personal_sync_replica.dart';

final class PersonalSyncEngineState {
  PersonalSyncEngineState({
    required this.sequence,
    required Iterable<PersonalSyncOperation> queue,
    required this.replica,
  }) : queue = UnmodifiableListView<PersonalSyncOperation>(queue.toList());

  factory PersonalSyncEngineState.empty() => PersonalSyncEngineState(
    sequence: 0,
    queue: const <PersonalSyncOperation>[],
    replica: PersonalSyncReplica.empty(),
  );

  factory PersonalSyncEngineState.fromStorage(Object? value) {
    if (value == null) return PersonalSyncEngineState.empty();
    if (value is! String) {
      throw const FormatException('invalid sync engine state');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('invalid sync engine state');
    }
    final map = Map<String, Object?>.from(decoded);
    final sequence = map['sequence'];
    final queue = map['queue'];
    final replica = map['replica'];
    if (map.length != 4 ||
        map['schemaVersion'] != 1 ||
        sequence is! int ||
        sequence < 0 ||
        queue is! List ||
        queue.any((item) => item is! Map) ||
        replica is! Map) {
      throw const FormatException('invalid sync engine state');
    }
    final operations = queue
        .map(
          (item) => PersonalSyncOperation.fromMap(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList(growable: false);
    if (operations.map((operation) => operation.operationId).toSet().length !=
        operations.length) {
      throw const FormatException('duplicate queued operation');
    }
    final state = PersonalSyncEngineState(
      sequence: sequence,
      queue: operations,
      replica: PersonalSyncReplica.fromMap(Map<String, Object?>.from(replica)),
    );
    final maximum = <int>[
      ...state.queue.map((operation) => operation.revision.sequence),
      ...state.replica.processedOperations.keys.map(
        (id) => PersonalSyncRevision.fromOperationId(id).sequence,
      ),
    ].fold<int>(0, (value, item) => item > value ? item : value);
    if (sequence < maximum) {
      throw const FormatException('sync sequence regressed');
    }
    return state;
  }

  final int sequence;
  final List<PersonalSyncOperation> queue;
  final PersonalSyncReplica replica;

  PersonalSyncEngineState copyWith({
    int? sequence,
    Iterable<PersonalSyncOperation>? queue,
    PersonalSyncReplica? replica,
  }) => PersonalSyncEngineState(
    sequence: sequence ?? this.sequence,
    queue: queue ?? this.queue,
    replica: replica ?? this.replica,
  );

  String toStorage() => jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'sequence': sequence,
    'queue': queue.map((operation) => operation.toMap()).toList(),
    'replica': replica.toMap(),
  });
}
