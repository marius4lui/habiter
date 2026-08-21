import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/adaptive_reminder_runtime.dart';
import 'package:habiter/features/reminders/application/reminder_scheduler.dart';
import 'package:habiter/models/habit.dart';

void main() {
  final habit = Habit(
    id: 'habit-1',
    name: 'Stretch',
    color: '#000000',
    icon: 'S',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    category: 'Health',
    createdAt: DateTime.utc(2026),
    isActive: true,
  );

  PlannedReminder reminder(DateTime scheduledFor) => PlannedReminder(
    logicalKey: 'habit-1@2026-08-21:normal:0',
    habit: habit,
    occurrence: LocalDate(2026, 8, 21),
    scheduledFor: scheduledFor,
  );

  test('waits until the final evaluation window without scheduling', () {
    final now = DateTime.utc(2026, 8, 21, 9);
    final decision = AdaptiveReminderDecision.fromCandidates(
      candidates: <PlannedReminder>[reminder(DateTime.utc(2026, 8, 21, 10))],
      now: now,
    );

    expect(decision.notification, isNull);
    expect(decision.nextEvaluationAt, DateTime.utc(2026, 8, 21, 9, 59));
  });

  test('materializes only the next reminder immediately before delivery', () {
    final scheduledFor = DateTime.utc(2026, 8, 21, 10);
    final decision = AdaptiveReminderDecision.fromCandidates(
      candidates: <PlannedReminder>[reminder(scheduledFor)],
      now: DateTime.utc(2026, 8, 21, 9, 59, 30),
    );

    expect(
      decision.notification!.logicalKey,
      startsWith(adaptiveRuntimeNotificationKeyPrefix),
    );
    expect(
      decision.nextEvaluationAt,
      scheduledFor.add(const Duration(seconds: 1)),
    );
  });

  test(
    'current state invalidation cancels delivery when no candidate remains',
    () {
      final decision = AdaptiveReminderDecision.fromCandidates(
        candidates: const <PlannedReminder>[],
        now: DateTime.utc(2026, 8, 21, 9, 59, 30),
      );

      expect(decision.notification, isNull);
      expect(decision.nextEvaluationAt, isNull);
    },
  );
}
