import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';

final class NotificationIdRegistry {
  NotificationIdRegistry(this._store);

  static const storageKey = 'habiter_notification_registry_v1';
  final KeyValueStore _store;

  Future<int> idFor(String logicalKey) async {
    final values = await _load();
    final existing = values[logicalKey];
    if (existing != null) return existing;
    final occupied = values.values.toSet();
    var candidate = _stableHash(logicalKey);
    while (occupied.contains(candidate)) {
      candidate = candidate == 0x7fffffff ? 1 : candidate + 1;
    }
    values[logicalKey] = candidate;
    await _store.write(storageKey, jsonEncode(values));
    return candidate;
  }

  Future<int?> existingId(String logicalKey) async =>
      (await _load())[logicalKey];

  Future<void> release(String logicalKey) async {
    final values = await _load();
    if (values.remove(logicalKey) != null) {
      await _store.write(storageKey, jsonEncode(values));
    }
  }

  Future<Map<String, int>> snapshot() async =>
      Map<String, int>.unmodifiable(await _load());

  Future<Map<String, int>> _load() async {
    final raw = await _store.read(storageKey);
    if (raw == null) return <String, int>{};
    if (raw is! String)
      throw const FormatException('Invalid reminder registry.');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid reminder registry.');
    }
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return (hash & 0x7fffffff).clamp(1, 0x7fffffff) as int;
  }
}
