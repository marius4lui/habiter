import 'package:habiter/core/persistence/key_value_store.dart';

final class KeyValueWrite {
  const KeyValueWrite(this.key, this.value);

  final String key;
  final Object value;
}

final class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object?> values = const {}])
    : _values = _cloneMap(values);

  final Map<String, Object?> _values;
  final List<KeyValueWrite> writes = <KeyValueWrite>[];

  @override
  Future<bool> contains(String key) async => _values.containsKey(key);

  @override
  Future<Object?> read(String key) async => _clone(_values[key]);

  @override
  Future<bool> remove(String key) async => _values.remove(key) != null;

  @override
  Future<Map<String, Object?>> snapshot() async => _cloneMap(_values);

  @override
  Future<void> write(String key, Object value) async {
    final cloned = _clone(value)!;
    _values[key] = cloned;
    writes.add(KeyValueWrite(key, cloned));
  }
}

Map<String, Object?> _cloneMap(Map<String, Object?> source) {
  return source.map(
    (key, value) => MapEntry<String, Object?>(key, _clone(value)),
  );
}

Object? _clone(Object? value) {
  return switch (value) {
    List<Object?> values => values.map(_clone).toList(growable: true),
    Map<String, Object?> values => _cloneMap(values),
    _ => value,
  };
}
