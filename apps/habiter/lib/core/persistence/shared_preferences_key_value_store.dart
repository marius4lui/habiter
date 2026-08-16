import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

final class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({
    SharedPreferencesAsync? preferences,
    Future<SharedPreferences> Function()? legacyPreferences,
  }) : _preferences = legacyPreferences == null
           ? (preferences ?? SharedPreferencesAsync())
           : null,
       _legacyPreferences = legacyPreferences;

  // Widget actions execute in a headless Flutter isolate. The legacy API has
  // an isolate-local cache; production therefore uses the cache-free API.
  // The legacy injection exists only for the plugin's in-memory test backend.
  final SharedPreferencesAsync? _preferences;
  final Future<SharedPreferences> Function()? _legacyPreferences;

  @override
  Future<bool> contains(String key) async {
    final legacy = _legacyPreferences;
    return legacy == null
        ? _preferences!.containsKey(key)
        : (await legacy()).containsKey(key);
  }

  @override
  Future<Object?> read(String key) async {
    final legacy = _legacyPreferences;
    final value = legacy == null
        ? (await _preferences!.getAll(allowList: <String>{key}))[key]
        : (await legacy()).get(key);
    return _clone(value);
  }

  @override
  Future<bool> remove(String key) async {
    final legacy = _legacyPreferences;
    if (legacy != null) return (await legacy()).remove(key);
    final existed = await _preferences!.containsKey(key);
    await _preferences.remove(key);
    return existed;
  }

  @override
  Future<Map<String, Object?>> snapshot() async {
    final legacy = _legacyPreferences;
    final values = legacy == null
        ? await _preferences!.getAll()
        : await _legacySnapshot(await legacy());
    return <String, Object?>{
      for (final entry in values.entries) entry.key: _clone(entry.value),
    };
  }

  @override
  Future<void> write(String key, Object value) async {
    final legacy = _legacyPreferences;
    if (legacy != null) {
      final preferences = await legacy();
      final written = switch (value) {
        String value => preferences.setString(key, value),
        bool value => preferences.setBool(key, value),
        int value => preferences.setInt(key, value),
        double value => preferences.setDouble(key, value),
        List<String> value => preferences.setStringList(key, List.of(value)),
        _ => throw _unsupported(value),
      };
      if (!await written) {
        throw StateError('SharedPreferences rejected the write for "$key".');
      }
      return;
    }
    final write = switch (value) {
      String value => _preferences!.setString(key, value),
      bool value => _preferences!.setBool(key, value),
      int value => _preferences!.setInt(key, value),
      double value => _preferences!.setDouble(key, value),
      List<String> value => _preferences!.setStringList(key, List.of(value)),
      _ => throw _unsupported(value),
    };
    await write;
  }
}

Future<Map<String, Object?>> _legacySnapshot(
  SharedPreferences preferences,
) async => <String, Object?>{
  for (final key in preferences.getKeys()) key: preferences.get(key),
};

ArgumentError _unsupported(Object value) => ArgumentError.value(
  value,
  'value',
  'SharedPreferences supports String, bool, int, double and List<String>.',
);

Object? _clone(Object? value) =>
    value is List<String> ? List<String>.of(value) : value;
