import 'dart:collection';
import 'dart:convert';

import 'personal_sync_contract.dart';

enum PersonalSyncOperationKind { create, patch, delete, restore }

final class PersonalSyncRevision implements Comparable<PersonalSyncRevision> {
  PersonalSyncRevision({required this.deviceId, required this.sequence}) {
    if (!_deviceIdPattern.hasMatch(deviceId)) {
      throw const PersonalSyncContractException(
        'invalid_device_id',
        'Device identifiers must be 1-128 URL-safe characters.',
      );
    }
    if (sequence < 1) {
      throw const PersonalSyncContractException(
        'invalid_revision',
        'Device operation sequences start at one.',
      );
    }
  }

  factory PersonalSyncRevision.fromMap(Map<String, Object?> map) {
    final deviceId = map['deviceId'];
    final sequence = map['sequence'];
    if (deviceId is! String || sequence is! int) {
      throw const PersonalSyncContractException(
        'invalid_revision',
        'Revision fields have invalid types.',
      );
    }
    return PersonalSyncRevision(deviceId: deviceId, sequence: sequence);
  }

  factory PersonalSyncRevision.fromOperationId(String operationId) {
    final components = operationId.split('/');
    if (components.length != 3 || components.first != 'operation') {
      throw const PersonalSyncContractException(
        'invalid_operation_id',
        'Operation identifier has an invalid shape.',
      );
    }
    late final String deviceId;
    try {
      deviceId = Uri.decodeComponent(components[1]);
    } on ArgumentError {
      throw const PersonalSyncContractException(
        'invalid_operation_id',
        'Operation identifier contains invalid percent encoding.',
      );
    }
    final sequence = int.tryParse(components[2]);
    if (sequence == null) {
      throw const PersonalSyncContractException(
        'invalid_operation_id',
        'Operation identifier has an invalid sequence.',
      );
    }
    final revision = PersonalSyncRevision(
      deviceId: deviceId,
      sequence: sequence,
    );
    if (revision.operationId != operationId) {
      throw const PersonalSyncContractException(
        'invalid_operation_id',
        'Operation identifier is not canonically encoded.',
      );
    }
    return revision;
  }

  final String deviceId;
  final int sequence;

  factory PersonalSyncRevision.next({
    required String deviceId,
    required int localSequence,
    Iterable<PersonalSyncRevision> observed = const <PersonalSyncRevision>[],
  }) {
    if (localSequence < 0) {
      throw const PersonalSyncContractException(
        'invalid_revision',
        'Local operation sequence must not be negative.',
      );
    }
    var maximum = localSequence;
    for (final revision in observed) {
      if (revision.sequence > maximum) maximum = revision.sequence;
    }
    return PersonalSyncRevision(deviceId: deviceId, sequence: maximum + 1);
  }

  String get operationId =>
      'operation/${Uri.encodeComponent(deviceId)}/$sequence';

  Map<String, Object?> toMap() => <String, Object?>{
    'deviceId': deviceId,
    'sequence': sequence,
  };

  @override
  int compareTo(PersonalSyncRevision other) {
    final sequenceComparison = sequence.compareTo(other.sequence);
    return sequenceComparison != 0
        ? sequenceComparison
        : deviceId.compareTo(other.deviceId);
  }

  @override
  bool operator ==(Object other) =>
      other is PersonalSyncRevision &&
      other.deviceId == deviceId &&
      other.sequence == sequence;

  @override
  int get hashCode => Object.hash(deviceId, sequence);

  static final RegExp _deviceIdPattern = RegExp(r'^[A-Za-z0-9._~-]{1,128}$');
}

final class PersonalSyncOperation {
  PersonalSyncOperation({
    this.protocolVersion = PersonalSyncVersions.protocol,
    required this.kind,
    required this.revision,
    required this.document,
    required Iterable<String> changedFields,
    Iterable<String> changedMetadataFields = const <String>[],
    Map<String, Object?> additionalFields = const <String, Object?>{},
  }) : changedFields = _validatedChangedFields(
         kind,
         document,
         changedFields,
         metadata: false,
       ),
       changedMetadataFields = _validatedChangedFields(
         kind,
         document,
         changedMetadataFields,
         metadata: true,
       ),
       additionalFields = _immutableJsonMap(additionalFields) {
    if (protocolVersion != PersonalSyncVersions.protocol) {
      throw const PersonalSyncContractException(
        'unsupported_protocol',
        'Operation protocol version is not supported.',
      );
    }
    if (kind == PersonalSyncOperationKind.delete) {
      if (!document.deleted || this.changedFields.isNotEmpty) {
        throw const PersonalSyncContractException(
          'invalid_delete_operation',
          'Delete operations require a tombstone and no payload fields.',
        );
      }
    } else if (document.deleted) {
      throw const PersonalSyncContractException(
        'invalid_live_operation',
        'Create, patch, and restore operations require a live document.',
      );
    }
    if (kind == PersonalSyncOperationKind.patch &&
        this.changedFields.isEmpty &&
        this.changedMetadataFields.isEmpty) {
      throw const PersonalSyncContractException(
        'empty_patch',
        'Patch operations must change at least one field.',
      );
    }
  }

  factory PersonalSyncOperation.fromMap(Map<String, Object?> map) {
    const knownFields = <String>{
      'protocolVersion',
      'operationId',
      'kind',
      'revision',
      'document',
      'changedFields',
      'changedMetadataFields',
    };
    final protocolVersion = map['protocolVersion'];
    final operationId = map['operationId'];
    final kindName = map['kind'];
    final revisionValue = map['revision'];
    final documentValue = map['document'];
    final changedFields = map['changedFields'];
    final changedMetadataFields = map['changedMetadataFields'];
    if (protocolVersion is! int ||
        operationId is! String ||
        kindName is! String ||
        revisionValue is! Map ||
        documentValue is! Map ||
        changedFields is! List ||
        changedMetadataFields is! List ||
        changedFields.any((field) => field is! String) ||
        changedMetadataFields.any((field) => field is! String)) {
      throw const PersonalSyncContractException(
        'invalid_operation',
        'Operation fields have invalid types.',
      );
    }
    final matchingKinds = PersonalSyncOperationKind.values.where(
      (candidate) => candidate.name == kindName,
    );
    if (matchingKinds.length != 1) {
      throw const PersonalSyncContractException(
        'invalid_operation',
        'Operation kind is unknown.',
      );
    }
    final revision = PersonalSyncRevision.fromMap(
      Map<String, Object?>.from(revisionValue),
    );
    if (revision.operationId != operationId ||
        PersonalSyncRevision.fromOperationId(operationId) != revision) {
      throw const PersonalSyncContractException(
        'operation_id_mismatch',
        'Operation identifier does not match its revision.',
      );
    }
    return PersonalSyncOperation(
      protocolVersion: protocolVersion,
      kind: matchingKinds.single,
      revision: revision,
      document: PersonalSyncEntityDocument.fromMap(
        Map<String, Object?>.from(documentValue),
      ),
      changedFields: changedFields.cast<String>(),
      changedMetadataFields: changedMetadataFields.cast<String>(),
      additionalFields: Map<String, Object?>.from(map)
        ..removeWhere((key, _) => knownFields.contains(key)),
    );
  }

  final int protocolVersion;
  final PersonalSyncOperationKind kind;
  final PersonalSyncRevision revision;
  final PersonalSyncEntityDocument document;
  final Set<String> changedFields;
  final Set<String> changedMetadataFields;
  final Map<String, Object?> additionalFields;

  String get operationId => revision.operationId;
  String get idempotencyKey => operationId;

  String get fingerprint => jsonEncode(_canonicalJson(toMap()));

  Map<String, Object?> toMap() => <String, Object?>{
    ...additionalFields,
    'protocolVersion': protocolVersion,
    'operationId': operationId,
    'kind': kind.name,
    'revision': revision.toMap(),
    'document': document.toMap(),
    'changedFields': changedFields.toList()..sort(),
    'changedMetadataFields': changedMetadataFields.toList()..sort(),
  };
}

final class PersonalSyncServerCursor {
  PersonalSyncServerCursor({required this.generation, required this.offset}) {
    if (!_generationPattern.hasMatch(generation) || offset < 0) {
      throw const PersonalSyncContractException(
        'invalid_cursor',
        'Cursor generation or offset is invalid.',
      );
    }
  }

  factory PersonalSyncServerCursor.parse(String token) {
    try {
      final padded = token.padRight((token.length + 3) ~/ 4 * 4, '=');
      final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
      if (decoded is! Map) throw const FormatException();
      final map = Map<String, Object?>.from(decoded);
      if (map.length != 3 ||
          map['version'] != 1 ||
          map['generation'] is! String ||
          map['offset'] is! int) {
        throw const FormatException();
      }
      final cursor = PersonalSyncServerCursor(
        generation: map['generation']! as String,
        offset: map['offset']! as int,
      );
      if (cursor.token != token) throw const FormatException();
      return cursor;
    } on Object {
      throw const PersonalSyncContractException(
        'invalid_cursor',
        'Server cursor is malformed or non-canonical.',
      );
    }
  }

  final String generation;
  final int offset;

  String get token => base64Url
      .encode(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'version': 1,
            'generation': generation,
            'offset': offset,
          }),
        ),
      )
      .replaceAll('=', '');

  @override
  bool operator ==(Object other) =>
      other is PersonalSyncServerCursor &&
      other.generation == generation &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(generation, offset);

  static final RegExp _generationPattern = RegExp(r'^[A-Za-z0-9._~-]{1,128}$');
}

enum PersonalSyncCursorRecoveryReason {
  none,
  missingCompactedHistory,
  generationChanged,
  cursorAhead,
}

final class PersonalSyncCursorDecision {
  const PersonalSyncCursorDecision.incremental()
    : requiresSnapshot = false,
      reason = PersonalSyncCursorRecoveryReason.none;

  const PersonalSyncCursorDecision.snapshot(this.reason)
    : requiresSnapshot = true;

  final bool requiresSnapshot;
  final PersonalSyncCursorRecoveryReason reason;
}

final class PersonalSyncCursorWindow {
  PersonalSyncCursorWindow({
    required this.generation,
    required this.floorOffset,
    required this.headOffset,
  }) {
    if (floorOffset < 0 || headOffset < floorOffset) {
      throw const PersonalSyncContractException(
        'invalid_cursor_window',
        'Cursor window bounds are invalid.',
      );
    }
    PersonalSyncServerCursor(generation: generation, offset: headOffset);
  }

  final String generation;
  final int floorOffset;
  final int headOffset;

  PersonalSyncCursorDecision evaluate(PersonalSyncServerCursor? cursor) {
    if (cursor == null) {
      return floorOffset == 0
          ? const PersonalSyncCursorDecision.incremental()
          : const PersonalSyncCursorDecision.snapshot(
              PersonalSyncCursorRecoveryReason.missingCompactedHistory,
            );
    }
    if (cursor.generation != generation) {
      return const PersonalSyncCursorDecision.snapshot(
        PersonalSyncCursorRecoveryReason.generationChanged,
      );
    }
    if (cursor.offset < floorOffset) {
      return const PersonalSyncCursorDecision.snapshot(
        PersonalSyncCursorRecoveryReason.missingCompactedHistory,
      );
    }
    if (cursor.offset > headOffset) {
      return const PersonalSyncCursorDecision.snapshot(
        PersonalSyncCursorRecoveryReason.cursorAhead,
      );
    }
    return const PersonalSyncCursorDecision.incremental();
  }
}

Set<String> _validatedChangedFields(
  PersonalSyncOperationKind kind,
  PersonalSyncEntityDocument document,
  Iterable<String> values, {
  required bool metadata,
}) {
  final fields = Set<String>.from(values);
  if (fields.any((field) => field.trim().isEmpty)) {
    throw const PersonalSyncContractException(
      'invalid_changed_fields',
      'Changed field names must not be empty.',
    );
  }
  final available = metadata
      ? document.additionalFields.keys.toSet()
      : document.payload?.keys.toSet() ?? const <String>{};
  if (!available.containsAll(fields)) {
    throw const PersonalSyncContractException(
      'invalid_changed_fields',
      'Changed fields must exist in the validated document.',
    );
  }
  final replacesEntity =
      kind == PersonalSyncOperationKind.create ||
      kind == PersonalSyncOperationKind.restore;
  if ((replacesEntity ||
          (metadata && kind == PersonalSyncOperationKind.delete)) &&
      !_sameSet(fields, available)) {
    throw const PersonalSyncContractException(
      'incomplete_replacement',
      'Create, restore, and tombstone metadata must be complete.',
    );
  }
  return Set<String>.unmodifiable(fields);
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

Map<String, Object?> _immutableJsonMap(Map<String, Object?> value) =>
    UnmodifiableMapView<String, Object?>(
      Map<String, Object?>.from(_copyJson(value)! as Map),
    );

Object? _copyJson(Object? value) => switch (value) {
  null || bool() || String() => value,
  num number when number.isFinite => number,
  List<Object?> values => List<Object?>.unmodifiable(values.map(_copyJson)),
  Map<Object?, Object?> values => Map<String, Object?>.unmodifiable(
    values.map((key, value) {
      if (key is! String) {
        throw const PersonalSyncContractException(
          'non_json_value',
          'Synchronized object keys must be strings.',
        );
      }
      if (_sensitiveKey.hasMatch(key)) {
        throw const PersonalSyncContractException(
          'sensitive_operation',
          'Operation metadata contains a sensitive-looking field.',
        );
      }
      return MapEntry<String, Object?>(key, _copyJson(value));
    }),
  ),
  _ => throw const PersonalSyncContractException(
    'non_json_value',
    'Synchronized values must use JSON-compatible types.',
  ),
};

Object? _canonicalJson(Object? value) => switch (value) {
  Map<Object?, Object?> values => <String, Object?>{
    for (final key in values.keys.cast<String>().toList()..sort())
      key: _canonicalJson(values[key]),
  },
  List<Object?> values => values.map(_canonicalJson).toList(),
  _ => value,
};

final RegExp _sensitiveKey = RegExp(
  r'(token|secret|password|api.?key|credential)',
  caseSensitive: false,
);
