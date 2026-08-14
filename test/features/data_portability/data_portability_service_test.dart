import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/persistence/key_value_store.dart';
import 'package:habiter/features/data_portability/data_portability_service.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/models/habit.dart';

void main() {
  test('round-trips data, tolerates unknown fields, and excludes secrets', () async {
    final source = KeyValueHabitRepository(InMemoryKeyValueStore());
    await source.transact((draft) => draft.upsertHabit(_habit('one')));
    final service = DataPortabilityService(source);
    final exported = await service.exportJson(
      settings: const {'theme': 'dark', 'apiKey': 'never-export'},
    );
    final map = jsonDecode(exported) as Map<String, dynamic>..['future'] = true;
    final target = KeyValueHabitRepository(InMemoryKeyValueStore());
    await DataPortabilityService(target).importJson(jsonEncode(map));

    expect((await target.load()).habits.single.id, 'one');
    expect(exported, isNot(contains('never-export')));
  });

  test('rejects corrupt and future exports before changing data', () async {
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    await repository.transact((draft) => draft.upsertHabit(_habit('safe')));
    final service = DataPortabilityService(repository);

    await expectLater(service.importJson('{bad'), throwsFormatException);
    await expectLater(
      service.importJson('{"schemaVersion":99,"habits":[],"entries":[]}'),
      throwsFormatException,
    );
    expect((await repository.load()).habits.single.id, 'safe');
  });

  test('previews collisions and keeps existing by default', () async {
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    await repository.transact((draft) => draft.upsertHabit(_habit('same')));
    final service = DataPortabilityService(repository);
    final input = jsonEncode({
      'schemaVersion': 1,
      'habits': [_habit('same').copyWith(name: 'Imported').toMap()],
      'entries': <Object?>[],
    });

    expect((await service.preview(input)).collisions, 1);
    final backup = await service.importJson(input);
    expect((await repository.load()).habits.single.name, 'Habit same');
    expect(jsonDecode(backup), isA<Map<String, dynamic>>());
  });
}

Habit _habit(String id) => Habit(
  id: id,
  name: 'Habit $id',
  color: '#000000',
  icon: 'check',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'General',
  createdAt: DateTime.utc(2026, 8, 14),
  isActive: true,
);

final class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object?> values = <String, Object?>{};
  @override
  Future<Object?> read(String key) async => values[key];
  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
  @override
  Future<void> write(String key, Object value) async => values[key] = value;
  @override
  Future<bool> contains(String key) async => values.containsKey(key);
  @override
  Future<Map<String, Object?>> snapshot() async => Map<String, Object?>.from(values);
}
