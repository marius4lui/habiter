import 'dart:collection';

enum HabitSourceKind {
  local,
  classlyCompatible,
  imported,
  aiSuggested,
  unknown,
}

final class HabitSourceMetadata {
  HabitSourceMetadata({
    this.kind = HabitSourceKind.local,
    this.externalId,
    this.originalKind,
    Map<String, Object?> additionalFields = const <String, Object?>{},
  }) : additionalFields = UnmodifiableMapView<String, Object?>(
         _freezeMap(additionalFields),
       );

  factory HabitSourceMetadata.fromMap(Map<String, Object?> map) {
    final kindValue = map['kind'] as String? ?? HabitSourceKind.local.name;
    final parsedKind = HabitSourceKind.values.firstWhere(
      (candidate) =>
          candidate != HabitSourceKind.unknown && candidate.name == kindValue,
      orElse: () => HabitSourceKind.unknown,
    );
    final additionalFields = Map<String, Object?>.from(map)
      ..remove('kind')
      ..remove('externalId');
    return HabitSourceMetadata(
      kind: parsedKind,
      originalKind: parsedKind == HabitSourceKind.unknown ? kindValue : null,
      externalId: map['externalId'] as String?,
      additionalFields: additionalFields,
    );
  }

  final HabitSourceKind kind;
  final String? externalId;
  final String? originalKind;
  final Map<String, Object?> additionalFields;

  Map<String, Object?> toMap() => <String, Object?>{
    ..._freezeMap(additionalFields),
    'kind': originalKind ?? kind.name,
    if (externalId != null) 'externalId': externalId,
  };
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) {
  return source.map(
    (key, value) => MapEntry<String, Object?>(key, _freeze(value)),
  );
}

Object? _freeze(Object? value) {
  return switch (value) {
    List<Object?> values => List<Object?>.unmodifiable(values.map(_freeze)),
    Map<String, Object?> values => Map<String, Object?>.unmodifiable(
      _freezeMap(values),
    ),
    _ => value,
  };
}
