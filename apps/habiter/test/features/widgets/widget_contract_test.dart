import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/domain/widget_action.dart';
import 'package:habiter/features/widgets/domain/widget_habit_item.dart';
import 'package:habiter/features/widgets/domain/widget_snapshot.dart';

void main() {
  test('widget snapshot is a compact versioned roundtrip contract', () {
    const habit = WidgetHabitItem(
      id: 'habit-1',
      name: 'Training',
      icon: '🏋️',
      isCompleted: false,
      scheduleLabel: '3× per week',
    );
    final snapshot = WidgetSnapshot(
      generatedAt: DateTime.utc(2026, 8, 16, 12),
      localDate: '2026-08-16',
      locale: 'en',
      completedCount: 1,
      scheduledCount: 2,
      allComplete: false,
      hasAnyHabits: true,
      nextHabit: habit,
      habits: const <WidgetHabitItem>[habit],
      appLock: const WidgetAppLockState(
        complete: false,
        incompleteHabitNames: <String>['Training'],
      ),
    );

    final restored = WidgetSnapshot.fromJson(snapshot.toJson());

    expect(restored.schemaVersion, WidgetSnapshot.currentSchemaVersion);
    expect(restored.nextHabit?.id, 'habit-1');
    expect(restored.habits.single.scheduleLabel, '3× per week');
    expect(restored.appLock?.incompleteHabitNames, <String>['Training']);
  });

  test('completion action preserves its idempotency key', () {
    final action = WidgetAction.completeHabit(
      habitId: 'habit-1',
      localDate: '2026-08-16',
      actionId: 'action-123',
    );

    final restored = WidgetAction.fromUri(action.toUri());

    expect(restored.type, WidgetActionType.completeHabit);
    expect(restored.habitId, 'habit-1');
    expect(restored.localDate, '2026-08-16');
    expect(restored.actionId, 'action-123');
  });

  test('undo action preserves the originating completion action', () {
    final action = WidgetAction.undoCompletion(
      habitId: 'habit-1',
      localDate: '2026-08-16',
      actionId: 'undo-1',
      sourceActionId: 'action-123',
    );

    final restored = WidgetAction.fromUri(action.toUri());

    expect(restored.type, WidgetActionType.undoCompletion);
    expect(restored.sourceActionId, 'action-123');
  });
}
