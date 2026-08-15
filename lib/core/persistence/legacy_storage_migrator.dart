import 'dart:convert';

import '../../models/habit.dart';
import '../../models/locked_app.dart';
import '../time/clock.dart';
import 'key_value_store.dart';
import 'storage_envelope.dart';

enum StorageMigrationStatus { migrated, alreadyCurrent }

final class StorageMigrationResult {
  const StorageMigrationResult({
    required this.status,
    required this.migratedHabits,
    required this.quarantinedRecords,
  });

  final StorageMigrationStatus status;
  final int migratedHabits;
  final int quarantinedRecords;
}

final class StorageMigrationException implements Exception {
  const StorageMigrationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageMigrationException: $message';
}

final class LegacyStorageMigrator {
  LegacyStorageMigrator({required KeyValueStore store, required Clock clock})
    : _store = store,
      _clock = clock;

  static const _habitsKey = 'habiter_habits';
  static const _entriesKey = 'habiter_habit_entries';
  static const _aiInsightsKey = 'habiter_ai_insights';
  static const _preferencesKey = 'habiter_user_preferences';
  static const _aiConfigKey = 'habiter_ai_config';
  static const _appLockKey = 'habiter_app_lock_config';
  static const _legacyKeys = <String>[
    _habitsKey,
    _entriesKey,
    _aiInsightsKey,
    _preferencesKey,
    _aiConfigKey,
    _appLockKey,
  ];

  final KeyValueStore _store;
  final Clock _clock;

  Future<StorageMigrationResult> migrate() async {
    try {
      final currentValue = await _store.read(StorageEnvelope.storageKey);
      if (currentValue != null) {
        if (currentValue is! String) {
          throw const FormatException('Envelope value is not JSON text.');
        }
        final current = StorageEnvelope.fromJson(currentValue);
        if (current.schemaVersion == StorageEnvelope.currentSchemaVersion) {
          return StorageMigrationResult(
            status: StorageMigrationStatus.alreadyCurrent,
            migratedHabits: _collectionLength(current.data[_habitsKey]),
            quarantinedRecords: current.quarantine.length,
          );
        }
        throw FormatException(
          'Unsupported storage schema ${current.schemaVersion}.',
        );
      }

      final raw = <String, Object?>{};
      for (final key in _legacyKeys) {
        final value = await _store.read(key);
        if (value != null) raw[key] = value;
      }
      final backup = jsonEncode(<String, Object?>{
        'schemaVersion': 0,
        'createdAt': _clock.now().toUtc().toIso8601String(),
        'raw': raw,
      });
      if (!await _store.contains(StorageEnvelope.backupKey)) {
        await _store.write(StorageEnvelope.backupKey, backup);
      }

      final quarantine = <Map<String, Object?>>[];
      final data = <String, Object?>{};
      for (final entry in raw.entries) {
        final decoded = _decodeLegacyValue(entry.key, entry.value, quarantine);
        if (decoded != null) data[entry.key] = decoded;
      }
      final envelope = StorageEnvelope(
        schemaVersion: StorageEnvelope.currentSchemaVersion,
        migratedAt: _clock.now(),
        data: data,
        quarantine: quarantine,
      );
      await _store.write(StorageEnvelope.storageKey, envelope.toJson());

      final verificationValue = await _store.read(StorageEnvelope.storageKey);
      final verified = StorageEnvelope.fromJson(verificationValue! as String);
      if (verified.schemaVersion != StorageEnvelope.currentSchemaVersion) {
        throw const FormatException('Envelope verification failed.');
      }
      return StorageMigrationResult(
        status: StorageMigrationStatus.migrated,
        migratedHabits: _collectionLength(verified.data[_habitsKey]),
        quarantinedRecords: verified.quarantine.length,
      );
    } catch (error) {
      if (error is StorageMigrationException) rethrow;
      throw StorageMigrationException(
        'Legacy storage could not be migrated safely.',
        cause: error,
      );
    }
  }

  Object? _decodeLegacyValue(
    String key,
    Object? value,
    List<Map<String, Object?>> quarantine,
  ) {
    if (value is! String) {
      quarantine.add(<String, Object?>{
        'collection': key,
        'errorCode': 'not_json_text',
        'raw': value,
      });
      return null;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(value);
    } catch (_) {
      quarantine.add(<String, Object?>{
        'collection': key,
        'errorCode': 'invalid_json',
        'raw': value,
      });
      return null;
    }
    if (key == _habitsKey) {
      return _validatedCollection(key, decoded, Habit.fromMap, quarantine);
    }
    if (key == _entriesKey) {
      return _validatedCollection(key, decoded, HabitEntry.fromMap, quarantine);
    }
    if (key == _aiInsightsKey) {
      return _validatedCollection(key, decoded, AIInsight.fromMap, quarantine);
    }
    try {
      final map = Map<String, dynamic>.from(decoded! as Map);
      if (key == _preferencesKey) UserPreferences.fromMap(map);
      if (key == _appLockKey) AppLockConfig.fromMap(map);
      if (key == _aiConfigKey) {
        map.map((name, item) => MapEntry(name, item.toString()));
      }
      return map;
    } catch (_) {
      quarantine.add(<String, Object?>{
        'collection': key,
        'errorCode': 'invalid_object',
        'raw': decoded,
      });
      return null;
    }
  }

  List<Object?> _validatedCollection<T>(
    String key,
    Object? decoded,
    T Function(Map<String, dynamic>) validate,
    List<Map<String, Object?>> quarantine,
  ) {
    if (decoded is! List) {
      quarantine.add(<String, Object?>{
        'collection': key,
        'errorCode': 'not_a_list',
        'raw': decoded,
      });
      return <Object?>[];
    }
    final valid = <Object?>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      try {
        final map = Map<String, dynamic>.from(item as Map);
        validate(map);
        valid.add(map);
      } catch (_) {
        quarantine.add(<String, Object?>{
          'collection': key,
          'index': index,
          'errorCode': 'invalid_record',
          'raw': item,
        });
      }
    }
    return valid;
  }

  int _collectionLength(Object? value) => value is List ? value.length : 0;
}
