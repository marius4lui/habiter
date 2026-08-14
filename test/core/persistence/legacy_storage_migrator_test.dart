import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/persistence/legacy_storage_migrator.dart';
import 'package:habiter/core/persistence/key_value_store.dart';
import 'package:habiter/core/persistence/storage_envelope.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  Map<String, Object?> legacyHabit(String id) => <String, Object?>{
    'id': id,
    'name': 'Legacy $id',
    'color': '#123456',
    'icon': 'check',
    'frequency': 'daily',
    'targetCount': 1,
    'category': 'General',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'isActive': true,
    'futureHabitField': <String, Object?>{'revision': 7},
  };

  test(
    'backs up raw v0 values before writing a verified v1 envelope',
    () async {
      final rawHabits = jsonEncode(<Object?>[
        legacyHabit('valid'),
        <String, Object?>{'id': 42, 'name': 'corrupt'},
      ]);
      final store = InMemoryKeyValueStore(<String, Object?>{
        KeyValueHabitRepository.habitsKey: rawHabits,
        KeyValueHabitRepository.entriesKey: '[]',
        'habiter_user_preferences': jsonEncode(<String, Object?>{
          'theme': 'dark',
          'language': 'de',
        }),
      });
      final migrator = LegacyStorageMigrator(
        store: store,
        clock: FakeClock(DateTime.utc(2026, 8, 14, 12)),
      );

      final result = await migrator.migrate();

      expect(result.status, StorageMigrationStatus.migrated);
      expect(result.migratedHabits, 1);
      expect(result.quarantinedRecords, 1);
      final backup =
          jsonDecode(await store.read(StorageEnvelope.backupKey) as String)
              as Map<String, dynamic>;
      expect(backup['schemaVersion'], 0);
      expect(
        (backup['raw']
            as Map<String, dynamic>)[KeyValueHabitRepository.habitsKey],
        rawHabits,
      );

      final envelope = StorageEnvelope.fromJson(
        await store.read(StorageEnvelope.storageKey) as String,
      );
      expect(envelope.schemaVersion, StorageEnvelope.currentSchemaVersion);
      final habits =
          envelope.data[KeyValueHabitRepository.habitsKey] as List<Object?>;
      expect(habits, hasLength(1));
      expect(
        (habits.single as Map<String, Object?>)['futureHabitField'],
        <String, Object?>{'revision': 7},
      );
      expect(
        envelope.quarantine.single['collection'],
        KeyValueHabitRepository.habitsKey,
      );
    },
  );

  test(
    'is idempotent and does not rewrite an existing current envelope',
    () async {
      final store = InMemoryKeyValueStore(<String, Object?>{
        KeyValueHabitRepository.habitsKey: jsonEncode(<Object?>[
          legacyHabit('one'),
        ]),
        KeyValueHabitRepository.entriesKey: '[]',
      });
      final migrator = LegacyStorageMigrator(
        store: store,
        clock: FakeClock(DateTime.utc(2026, 8, 14)),
      );
      await migrator.migrate();
      final writesAfterFirstRun = store.writes.length;

      final second = await migrator.migrate();

      expect(second.status, StorageMigrationStatus.alreadyCurrent);
      expect(store.writes, hasLength(writesAfterFirstRun));
    },
  );

  test(
    'repository reads and updates the envelope without losing extras',
    () async {
      final store = InMemoryKeyValueStore(<String, Object?>{
        KeyValueHabitRepository.habitsKey: jsonEncode(<Object?>[
          legacyHabit('one'),
        ]),
        KeyValueHabitRepository.entriesKey: '[]',
      });
      await LegacyStorageMigrator(
        store: store,
        clock: FakeClock(DateTime.utc(2026, 8, 14)),
      ).migrate();
      final repository = KeyValueHabitRepository(store);

      await repository.transact((draft) {
        final current = draft.habits.single;
        draft.upsertHabit(current.copyWith(name: 'Updated'));
      });

      final loaded = await repository.load();
      expect(loaded.habits.single.name, 'Updated');
      final envelope = StorageEnvelope.fromJson(
        await store.read(StorageEnvelope.storageKey) as String,
      );
      final rawHabit =
          (envelope.data[KeyValueHabitRepository.habitsKey] as List<Object?>)
                  .single
              as Map<String, Object?>;
      expect(rawHabit['futureHabitField'], <String, Object?>{'revision': 7});
    },
  );

  test('keeps legacy data untouched when backup persistence fails', () async {
    final rawHabits = jsonEncode(<Object?>[legacyHabit('one')]);
    final store = _RejectBackupStore(<String, Object?>{
      KeyValueHabitRepository.habitsKey: rawHabits,
      KeyValueHabitRepository.entriesKey: '[]',
    });
    final migrator = LegacyStorageMigrator(
      store: store,
      clock: FakeClock(DateTime.utc(2026, 8, 14)),
    );

    await expectLater(
      migrator.migrate(),
      throwsA(isA<StorageMigrationException>()),
    );

    expect(await store.read(KeyValueHabitRepository.habitsKey), rawHabits);
    expect(await store.contains(StorageEnvelope.storageKey), isFalse);
  });
}

final class _RejectBackupStore implements KeyValueStore {
  _RejectBackupStore(Map<String, Object?> values)
    : _delegate = InMemoryKeyValueStore(values);

  final InMemoryKeyValueStore _delegate;

  @override
  Future<bool> contains(String key) => _delegate.contains(key);

  @override
  Future<Object?> read(String key) => _delegate.read(key);

  @override
  Future<bool> remove(String key) => _delegate.remove(key);

  @override
  Future<Map<String, Object?>> snapshot() => _delegate.snapshot();

  @override
  Future<void> write(String key, Object value) {
    if (key == StorageEnvelope.backupKey) {
      throw StateError('backup unavailable');
    }
    return _delegate.write(key, value);
  }
}
