import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/services/ai_manager.dart';

void main() {
  test('local coaching is deterministic without remote configuration', () {
    final habit = Habit(
      id: 'read',
      name: 'Read',
      color: '#000000',
      icon: 'book',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      category: 'Growth',
      createdAt: DateTime.utc(2026, 8, 1),\n      isActive: true,
    );
    final now = DateTime.utc(2026, 8, 14, 12);
    const engine = LocalCoachingEngine();

    final first = engine.generate(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      now: now,
    );
    final second = engine.generate(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      now: now,
    );

    expect(first.single.toMap(), second.single.toMap());
    expect(first.single.id, 'local:read:2026-08-14');
  });
}
