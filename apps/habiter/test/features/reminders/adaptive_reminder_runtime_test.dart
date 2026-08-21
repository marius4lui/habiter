import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/adaptive_reminder_runtime.dart';
import 'package:habiter/features/reminders/application/dynamic_reminder_planner.dart';
import 'package:habiter/features/reminders/application/reminder_scheduler.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/features/reminders/domain/reminder_preferences.dart';
import 'package:habiter/models/habit.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

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

  test('completion before the expected time invalidates adaptive delivery', () {
    final now = DateTime.utc(2026, 8, 21, 6);
    final policy = HabitReminderPolicy.smart(habitId: habit.id, now: now);
    DynamicReminderPlanInput input({Set<String> completed = const {}}) =>
        DynamicReminderPlanInput(
          habits: <Habit>[habit],
          policies: <String, HabitReminderPolicy>{habit.id: policy},
          preferences: ReminderPreferences(enabled: true),
          signals: const [],
          completedOccurrences: completed,
          start: LocalDate(2026, 8, 21),
          now: now,
          location: tz.UTC,
          horizonDays: 1,
        );
    const planner = DynamicReminderPlanner();
    final previouslyExpected = planner.plan(input()).reminders.first;
    final current = planner.plan(
      input(completed: <String>{'${habit.id}@2026-08-21'}),
    );
    final decision = AdaptiveReminderDecision.fromCandidates(
      candidates: current.reminders,
      now: previouslyExpected.scheduledFor.subtract(
        const Duration(seconds: 30),
      ),
    );

    expect(decision.notification, isNull);
    expect(decision.nextEvaluationAt, isNull);
  });
}
