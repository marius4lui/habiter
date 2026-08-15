import 'dart:collection';
import 'dart:convert';

final class StorageEnvelope {
  StorageEnvelope({
    required this.schemaVersion,
    required this.migratedAt,
    required Map<String, Object?> data,
    List<Map<String, Object?>> quarantine = const <Map<String, Object?>>[],
  }) : data = UnmodifiableMapView<String, Object?>(_cloneMap(data)),
       quarantine = List<Map<String, Object?>>.unmodifiable(
         quarantine.map(_cloneMap),
       );

  static const currentSchemaVersion = 1;
  static const storageKey = 'habiter_storage_envelope';
  static const backupKey = 'habiter_storage_backup_v0';

  factory StorageEnvelope.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Storage envelope must be a JSON object.');
    }
    final map = Map<String, Object?>.from(decoded);
    final schemaVersion = (map['schemaVersion'] as num?)?.toInt();
    final migratedAt = map['migratedAt'] as String?;
    final data = map['data'];
    final quarantine = map['quarantine'];
    if (schemaVersion == null ||
        migratedAt == null ||
        data is! Map ||
        quarantine is! List) {
      throw const FormatException('Storage envelope fields are invalid.');
    }
    return StorageEnvelope(
      schemaVersion: schemaVersion,
      migratedAt: DateTime.parse(migratedAt),
      data: Map<String, Object?>.from(data),
      quarantine: quarantine
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList(growable: false),
    );
  }

  final int schemaVersion;
  final DateTime migratedAt;
  final Map<String, Object?> data;
  final List<Map<String, Object?>> quarantine;

  StorageEnvelope withData(Map<String, Object?> value) => StorageEnvelope(
    schemaVersion: schemaVersion,
    migratedAt: migratedAt,
    data: value,
    quarantine: quarantine,
  );

  String toJson() => jsonEncode(<String, Object?>{
    'schemaVersion': schemaVersion,
    'migratedAt': migratedAt.toUtc().toIso8601String(),
    'data': data,
    'quarantine': quarantine,
  });
}

Map<String, Object?> _cloneMap(Map<String, Object?> source) {
  return source.map(
    (key, value) => MapEntry<String, Object?>(key, _clone(value)),
  );
}

Object? _clone(Object? value) {
  return switch (value) {
    List<Object?> values => List<Object?>.unmodifiable(values.map(_clone)),
    Map<Object?, Object?> values => Map<String, Object?>.unmodifiable(
      values.map(
        (key, value) => MapEntry<String, Object?>(key as String, _clone(value)),
      ),
    ),
    _ => value,
  };
}
