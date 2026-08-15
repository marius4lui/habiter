import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/models/habit.dart';

List<Map<String, dynamic>> _fixtureList(String name) {
  final raw = File('test/fixtures/legacy/$name').readAsStringSync();
  return (jsonDecode(raw) as List<dynamic>)
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList(growable: false);
}

void main() {
  group('legacy Habit payloads', () {
    test('retain every persisted v0 habit field through a roundtrip', () {
      final fixture = _fixtureList('habits_v0.json');

      final habits = fixture.map(Habit.fromMap).toList(growable: false);

      expect(habits, hasLength(2));
      expect(habits.first.id, 'legacy-daily-water');
      expect(habits.first.frequency, HabitFrequency.daily);
      expect(habits.first.notificationEnabled, isTrue);
      expect(habits.first.notificationTime, '08:15');
      expect(habits.last.frequency, HabitFrequency.custom);
      expect(habits.last.customDays, <int>[1, 3, 5]);
      expect(habits.last.isActive, isFalse);

      for (var index = 0; index < habits.length; index++) {
        expect(habits[index].toMap(), fixture[index]);
      }
    });

    test('keeps documented defaults for sparse legacy records', () {
      final habit = Habit.fromMap(<String, dynamic>{
        'id': 'sparse',
        'name': 'Sparse habit',
        'color': '#123456',
        'icon': 'check',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(habit.frequency, HabitFrequency.daily);
      expect(habit.targetCount, 1);
      expect(habit.category, 'General');
      expect(habit.isActive, isTrue);
      expect(habit.notificationEnabled, isFalse);
      expect(habit.notificationTime, isNull);
    });
  });

  group('legacy HabitEntry payloads', () {
    test('retain completion count and timestamp', () {
      final fixture = _fixtureList('habit_entries_v0.json');

      final entries = fixture.map(HabitEntry.fromMap).toList(growable: false);

      expect(entries.first.completed, isTrue);
      expect(entries.first.count, 8);
      expect(entries.last.completed, isFalse);
      expect(entries.map((entry) => entry.toMap()), fixture);
    });
  });
}
