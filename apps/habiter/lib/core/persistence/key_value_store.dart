abstract interface class KeyValueStore {
  Future<Object?> read(String key);

  Future<void> write(String key, Object value);

  Future<bool> remove(String key);

  Future<bool> contains(String key);

  Future<Map<String, Object?>> snapshot();
}
