import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

final class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<bool> contains(String key) async {
    return (await _preferences()).containsKey(key);
  }

  @override
  Future<Object?> read(String key) async {
    return _clone((await _preferences()).get(key));
  }

  @override
  Future<bool> remove(String key) async {
    return (await _preferences()).remove(key);
  }

  @override
  Future<Map<String, Object?>> snapshot() async {
    final preferences = await _preferences();
    return <String, Object?>{
      for (final key in preferences.getKeys())
        key: _clone(preferences.get(key)),
    };
  }

  @override
  Future<void> write(String key, Object value) async {
    final preferences = await _preferences();
    final written = switch (value) {
      String value => preferences.setString(key, value),
      bool value => preferences.setBool(key, value),
      int value => preferences.setInt(key, value),
      double value => preferences.setDouble(key, value),
      List<String> value => preferences.setStringList(key, List.of(value)),
      _ => throw ArgumentError.value(
        value,
        'value',
        'SharedPreferences supports String, bool, int, double and List<String>.',
      ),
    };
    if (!await written) {
      throw StateError('SharedPreferences rejected the write for "$key".');
    }
  }
}

Object? _clone(Object? value) {
  return value is List<String> ? List<String>.of(value) : value;
}
