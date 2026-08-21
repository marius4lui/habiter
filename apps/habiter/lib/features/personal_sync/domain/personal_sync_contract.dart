import 'dart:collection';

enum PersonalSyncEntityType { habit, entry, setting }

enum PersonalSyncMergePolicy { fieldRevision }

enum PersonalSyncProjection { none, appearance, coaching, reminders }

enum PersonalSyncCompatibility {
  compatible,
  clientUpgradeRequired,
  serverUpgradeRequired,
}

final class PersonalSyncContractException implements Exception {
  const PersonalSyncContractException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PersonalSyncContractException($code): $message';
}

abstract final class PersonalSyncVersions {
  static const protocol = 1;
  static const minimumProtocol = 1;
  static const entitySchema = 1;
  static const settingSchema = 1;

  static PersonalSyncCompatibility negotiateProtocol(int remoteVersion) {
    if (remoteVersion < minimumProtocol) {
      return PersonalSyncCompatibility.serverUpgradeRequired;
    }
    if (remoteVersion > protocol) {
      return PersonalSyncCompatibility.clientUpgradeRequired;
    }
    return PersonalSyncCompatibility.compatible;
  }
}

final class PersonalSyncEntityId {
  PersonalSyncEntityId._(this.type, Iterable<String> components)
    : components = List<String>.unmodifiable(components) {
    if (this.components.any((component) => component.trim().isEmpty)) {
      throw const PersonalSyncContractException(
        'invalid_entity_id',
        'Entity identifier components must not be empty.',
      );
    }
  }

  factory PersonalSyncEntityId.habit(String habitId) =>
      PersonalSyncEntityId._(PersonalSyncEntityType.habit, <String>[habitId]);

  factory PersonalSyncEntityId.entry(String habitId, String localDate) {
    _requireLocalDate(localDate);
    return PersonalSyncEntityId._(PersonalSyncEntityType.entry, <String>[
      habitId,
      localDate,
    ]);
  }

  factory PersonalSyncEntityId.setting(String stableKey) =>
      PersonalSyncEntityId._(PersonalSyncEntityType.setting, <String>[
        stableKey,
      ]);

  factory PersonalSyncEntityId.parse(String value) {
    final raw = value.split('/');
    if (raw.isEmpty) {
      throw const PersonalSyncContractException(
        'invalid_entity_id',
        'Entity identifier is empty.',
      );
    }
    final type = PersonalSyncEntityType.values.where(
      (candidate) => candidate.name == raw.first,
    );
    if (type.length != 1) {
      throw const PersonalSyncContractException(
        'invalid_entity_id',
        'Entity identifier has an unknown type.',
      );
    }
    final expectedLength = type.single == PersonalSyncEntityType.entry ? 3 : 2;
    if (raw.length != expectedLength) {
      throw const PersonalSyncContractException(
        'invalid_entity_id',
        'Entity identifier has the wrong number of components.',
      );
    }
    late final List<String> components;
    try {
      components = raw.skip(1).map(Uri.decodeComponent).toList();
    } on ArgumentError {
      throw const PersonalSyncContractException(
        'invalid_entity_id',
        'Entity identifier contains invalid percent encoding.',
      );
    }
    return switch (type.single) {
      PersonalSyncEntityType.habit => PersonalSyncEntityId.habit(
        components.single,
      ),
      PersonalSyncEntityType.entry => PersonalSyncEntityId.entry(
        components.first,
        components.last,
      ),
      PersonalSyncEntityType.setting => PersonalSyncEntityId.setting(
        components.single,
      ),
    };
  }

  final PersonalSyncEntityType type;
  final List<String> components;

  String get value =>
      <String>[type.name, ...components.map(Uri.encodeComponent)].join('/');

  @override
  bool operator ==(Object other) =>
      other is PersonalSyncEntityId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class PersonalSyncSettingDefinition {
  const PersonalSyncSettingDefinition({
    required this.key,
    required this.valueSchema,
    required this.defaultValue,
    required this.validate,
    required this.normalize,
    required this.mergePolicy,
    required this.projection,
    required this.schemaVersionIntroduced,
    this.syncEligible = true,
    this.sensitive = false,
  });

  final String key;
  final String valueSchema;
  final Object? defaultValue;
  final bool Function(Object? value) validate;
  final Object? Function(Object? value) normalize;
  final PersonalSyncMergePolicy mergePolicy;
  final PersonalSyncProjection projection;
  final int schemaVersionIntroduced;
  final bool syncEligible;
  final bool sensitive;
}

abstract final class PersonalSyncSettingRegistry {
  static final List<PersonalSyncSettingDefinition> definitions =
      List<PersonalSyncSettingDefinition>.unmodifiable(
        <PersonalSyncSettingDefinition>[
          _setting(
            'appearance.theme',
            'light | dark | system',
            'system',
            _theme,
            PersonalSyncProjection.appearance,
          ),
          _setting(
            'appearance.language',
            'en | de',
            'de',
            _language,
            PersonalSyncProjection.appearance,
          ),
          _setting(
            'coaching.showRecoverySupport',
            'boolean',
            true,
            _boolean,
            PersonalSyncProjection.coaching,
          ),
          _setting(
            'reminders.enabled',
            'boolean',
            false,
            _boolean,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.activeDayStart',
            'HH:mm',
            '08:00',
            _localTime,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.activeDayEnd',
            'HH:mm',
            '22:00',
            _localTime,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.globalDailyLimit',
            'integer 1..64',
            8,
            _dailyLimit,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.globalMinimumSpacingMinutes',
            'integer 1..1440',
            90,
            _positiveMinutes,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.quietHours',
            'non-overlapping time ranges',
            const <Object?>[],
            _quietHours,
            PersonalSyncProjection.reminders,
            normalize: _normalizeQuietHours,
          ),
          _setting(
            'reminders.calibrationEnabled',
            'boolean',
            true,
            _boolean,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.ongoingLearningEnabled',
            'boolean',
            true,
            _boolean,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.showLearningExplanations',
            'boolean',
            true,
            _boolean,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.defaultSnoozeMinutes',
            'integer 1..1440',
            30,
            _positiveMinutes,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.dailyOverview.enabled',
            'boolean',
            false,
            _boolean,
            PersonalSyncProjection.reminders,
          ),
          _setting(
            'reminders.dailyOverview.time',
            'HH:mm',
            '20:00',
            _localTime,
            PersonalSyncProjection.reminders,
          ),
        ],
      );

  static final Map<String, PersonalSyncSettingDefinition> byKey =
      UnmodifiableMapView<String, PersonalSyncSettingDefinition>(
        <String, PersonalSyncSettingDefinition>{
          for (final definition in definitions) definition.key: definition,
        },
      );

  static Map<String, Object?> validateValues(Map<String, Object?> values) {
    final validated = <String, Object?>{};
    for (final entry in values.entries) {
      if (_secretKey.hasMatch(entry.key)) {
        throw PersonalSyncContractException(
          'sensitive_setting',
          'Setting "${entry.key}" is sensitive and cannot be synchronized.',
        );
      }
      final definition = byKey[entry.key];
      if (definition == null ||
          !definition.syncEligible ||
          definition.sensitive) {
        throw PersonalSyncContractException(
          'unknown_setting',
          'Setting "${entry.key}" is not in the synchronized allow-list.',
        );
      }
      if (!definition.validate(entry.value)) {
        throw PersonalSyncContractException(
          'invalid_setting',
          'Setting "${entry.key}" does not match ${definition.valueSchema}.',
        );
      }
      validated[entry.key] = _copyJson(definition.normalize(entry.value));
    }
    return UnmodifiableMapView<String, Object?>(validated);
  }

  static PersonalSyncSettingDefinition _setting(
    String key,
    String schema,
    Object? defaultValue,
    bool Function(Object?) validate,
    PersonalSyncProjection projection, {
    Object? Function(Object?) normalize = _identity,
  }) => PersonalSyncSettingDefinition(
    key: key,
    valueSchema: schema,
    defaultValue: defaultValue,
    validate: validate,
    normalize: normalize,
    mergePolicy: PersonalSyncMergePolicy.fieldRevision,
    projection: projection,
    schemaVersionIntroduced: 1,
  );

  static final RegExp _secretKey = RegExp(
    r'(token|secret|password|api.?key|credential)',
    caseSensitive: false,
  );
}

final class PersonalSyncEntityDocument {
  PersonalSyncEntityDocument({
    this.schemaVersion = PersonalSyncVersions.entitySchema,
    required this.entityId,
    required this.deleted,
    Map<String, Object?>? payload,
    Map<String, Object?> additionalFields = const <String, Object?>{},
  }) : payload = _validatedPayloadForSchema(schemaVersion, entityId, payload),
       additionalFields = UnmodifiableMapView<String, Object?>(
         _validatedAdditionalFields(additionalFields),
       ) {
    if (deleted == (this.payload != null)) {
      throw const PersonalSyncContractException(
        'invalid_tombstone',
        'Deleted entities must omit payload; live entities must include it.',
      );
    }
  }

  factory PersonalSyncEntityDocument.fromMap(Map<String, Object?> map) {
    const known = <String>{'schemaVersion', 'entityId', 'deleted', 'payload'};
    final schemaVersion = map['schemaVersion'];
    final entityId = map['entityId'];
    final deleted = map['deleted'];
    final payload = map['payload'];
    if (schemaVersion is! int ||
        entityId is! String ||
        deleted is! bool ||
        (payload != null && payload is! Map)) {
      throw const PersonalSyncContractException(
        'invalid_document',
        'Entity document fields have invalid types.',
      );
    }
    return PersonalSyncEntityDocument(
      schemaVersion: schemaVersion,
      entityId: PersonalSyncEntityId.parse(entityId),
      deleted: deleted,
      payload: payload == null
          ? null
          : Map<String, Object?>.from(payload as Map),
      additionalFields: Map<String, Object?>.from(map)
        ..removeWhere((key, _) => known.contains(key)),
    );
  }

  final int schemaVersion;
  final PersonalSyncEntityId entityId;
  final bool deleted;
  final Map<String, Object?>? payload;
  final Map<String, Object?> additionalFields;

  Map<String, Object?> toMap() => <String, Object?>{
    ...additionalFields,
    'schemaVersion': schemaVersion,
    'entityId': entityId.value,
    'deleted': deleted,
    if (payload != null) 'payload': payload,
  };
}

Map<String, Object?> _validatedAdditionalFields(
  Map<String, Object?> additionalFields,
) {
  _rejectSensitiveKeys(additionalFields);
  return Map<String, Object?>.from(_copyJson(additionalFields)! as Map);
}

Map<String, Object?>? _validatedPayloadForSchema(
  int schemaVersion,
  PersonalSyncEntityId entityId,
  Map<String, Object?>? payload,
) {
  if (schemaVersion != PersonalSyncVersions.entitySchema) {
    throw const PersonalSyncContractException(
      'unsupported_entity_schema',
      'Entity schema version is not supported.',
    );
  }
  return payload == null
      ? null
      : UnmodifiableMapView<String, Object?>(
          _validatePayload(entityId, payload),
        );
}

Map<String, Object?> _validatePayload(
  PersonalSyncEntityId entityId,
  Map<String, Object?> payload,
) {
  _rejectSensitiveKeys(payload);
  switch (entityId.type) {
    case PersonalSyncEntityType.habit:
      _requireFields(payload, <String, bool Function(Object?)>{
        'id': _nonEmptyString,
        'name': _nonEmptyString,
        'description': (value) => value == null || value is String,
        'color': _nonEmptyString,
        'icon': _nonEmptyString,
        'frequency': (value) =>
            value is String &&
            const {'daily', 'weekly', 'custom'}.contains(value),
        'targetCount': (value) => value is int && value > 0,
        'category': _nonEmptyString,
        'customDays': _customDays,
        'createdAt': _dateTime,
        'isActive': _boolean,
        'notificationEnabled': _boolean,
        'notificationTime': (value) => value == null || _localTime(value),
      });
      if (payload['id'] != entityId.components.single) {
        throw const PersonalSyncContractException(
          'entity_id_mismatch',
          'Habit payload identity does not match its entity identifier.',
        );
      }
      break;
    case PersonalSyncEntityType.entry:
      _requireFields(payload, <String, bool Function(Object?)>{
        'id': _nonEmptyString,
        'habitId': _nonEmptyString,
        'date': (value) => value is String && _isLocalDate(value),
        'completed': _boolean,
        'count': (value) => value is int && value >= 0,
        'timestamp': _dateTime,
      });
      if (payload['habitId'] != entityId.components.first ||
          payload['date'] != entityId.components.last) {
        throw const PersonalSyncContractException(
          'entity_id_mismatch',
          'Entry logical identity does not match its entity identifier.',
        );
      }
      break;
    case PersonalSyncEntityType.setting:
      if (payload.keys.length != 1 || !payload.containsKey('value')) {
        throw const PersonalSyncContractException(
          'invalid_setting',
          'Setting payload must contain only its value.',
        );
      }
      PersonalSyncSettingRegistry.validateValues(<String, Object?>{
        entityId.components.single: payload['value'],
      });
      break;
  }
  return Map<String, Object?>.from(_copyJson(payload)! as Map);
}

void _requireFields(
  Map<String, Object?> payload,
  Map<String, bool Function(Object?)> fields,
) {
  for (final entry in fields.entries) {
    if (!payload.containsKey(entry.key) || !entry.value(payload[entry.key])) {
      throw PersonalSyncContractException(
        'invalid_payload',
        'Entity field "${entry.key}" is missing or invalid.',
      );
    }
  }
}

void _rejectSensitiveKeys(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (PersonalSyncSettingRegistry._secretKey.hasMatch(
        entry.key.toString(),
      )) {
        throw const PersonalSyncContractException(
          'sensitive_payload',
          'Entity payload contains a sensitive-looking field.',
        );
      }
      _rejectSensitiveKeys(entry.value);
    }
  } else if (value is List) {
    for (final item in value) {
      _rejectSensitiveKeys(item);
    }
  }
}

Object? _copyJson(Object? value) => switch (value) {
  null || bool() || String() => value,
  num number when number.isFinite => number,
  List<Object?> values => List<Object?>.unmodifiable(values.map(_copyJson)),
  Map<Object?, Object?> values => _copyJsonMap(values),
  _ => throw const PersonalSyncContractException(
    'non_json_value',
    'Synchronized values must use JSON-compatible types.',
  ),
};

Map<String, Object?> _copyJsonMap(Map<Object?, Object?> values) {
  final result = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.key is! String) {
      throw const PersonalSyncContractException(
        'non_json_value',
        'Synchronized object keys must be strings.',
      );
    }
    final key = entry.key;
    result[key as String] = _copyJson(entry.value);
  }
  return UnmodifiableMapView<String, Object?>(result);
}

Object? _identity(Object? value) => value;

Object? _normalizeQuietHours(Object? value) {
  final ranges = (value! as List)
      .map((item) => Map<String, Object?>.from(item! as Map))
      .toList();
  ranges.sort(
    (left, right) =>
        (left['start']! as String).compareTo(right['start']! as String),
  );
  return ranges;
}

bool _boolean(Object? value) => value is bool;
bool _nonEmptyString(Object? value) =>
    value is String && value.trim().isNotEmpty;
bool _theme(Object? value) =>
    value is String && const {'light', 'dark', 'system'}.contains(value);
bool _language(Object? value) =>
    value is String && const {'en', 'de'}.contains(value);
bool _dailyLimit(Object? value) => value is int && value >= 1 && value <= 64;
bool _positiveMinutes(Object? value) =>
    value is int && value >= 1 && value <= 1440;
bool _dateTime(Object? value) =>
    value is String && DateTime.tryParse(value) != null;
bool _localTime(Object? value) =>
    value is String &&
    RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);
bool _customDays(Object? value) =>
    value == null ||
    value is List && value.every((day) => day is int && day >= 1 && day <= 7);

bool _quietHours(Object? value) {
  if (value is! List) return false;
  final occupied = <int>{};
  for (final item in value) {
    if (item is! Map || item.keys.length != 2) return false;
    final start = item['start'];
    final end = item['end'];
    if (!_localTime(start) || !_localTime(end) || start == end) return false;
    final startMinute = _minuteOfDay(start! as String);
    final endMinute = _minuteOfDay(end! as String);
    var minute = startMinute;
    while (minute != endMinute) {
      if (!occupied.add(minute)) return false;
      minute = (minute + 1) % 1440;
    }
    if (!occupied.add(endMinute)) return false;
  }
  return true;
}

int _minuteOfDay(String value) {
  final parts = value.split(':');
  return int.parse(parts.first) * 60 + int.parse(parts.last);
}

bool _isLocalDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse('${value}T00:00:00Z');
  return parsed != null && parsed.toIso8601String().startsWith(value);
}

void _requireLocalDate(String value) {
  if (!_isLocalDate(value)) {
    throw const PersonalSyncContractException(
      'invalid_entity_id',
      'Entry entity identifier must contain a valid local date.',
    );
  }
}
