import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/notification_id_registry.dart';
import 'package:habiter/features/reminders/application/reminder_scheduler.dart';
import 'package:habiter/models/habit.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('planner covers daily, weekdays and times-per-week without duplicates', () {
    final plan = ReminderPlanner.plan(
      habits: <Habit>[
        _habit('daily', HabitFrequency.daily),
        _habit('custom', HabitFrequency.custom, customDays: <int>[1, 3]),
        _habit('weekly', HabitFrequency.weekly, target: 2),
      ],
      start: LocalDate(2026, 8, 3),
      location: tz.getLocation('Europe/Berlin'),
      horizonDays: 7,
    );

    expect(plan.where((item) => item.habit.id == 'daily'), hasLength(7));
    expect(plan.where((item) => item.habit.id == 'custom'), hasLength(2));
    expect(plan.where((item) => item.habit.id == 'weekly'), hasLength(2));
    expect(plan.map((item) => item.logicalKey).toSet(), hasLength(plan.length));
  });

  test('planner respects lifecycle and the iOS pending capacity', () {
    final plan = ReminderPlanner.plan(
      habits: <Habit>[
        _habit('active', HabitFrequency.daily),
        _habit('archived', HabitFrequency.daily, active: false),
      ],
      start: LocalDate(2026, 8, 3),
      location: tz.UTC,
      horizonDays: 90,
      capacity: 64,
    );

    expect(plan, hasLength(64));
    expect(plan.every((item) => item.habit.id == 'active'), isTrue);
  });

  test('scheduler reconciles edits, archive and delete idempotently', () async {
    final store = InMemoryKeyValueStore();
    final registry = NotificationIdRegistry(store);
    final gateway = RecordingNotificationGateway();
    final scheduler = ReminderScheduler(registry: registry, gateway: gateway);
    final first = ReminderPlanner.plan(
      habits: <Habit>[_habit('habit', HabitFrequency.daily)],
      start: LocalDate(2026, 8, 3),
      location: tz.UTC,
      horizonDays: 2,
    );

    await scheduler.replaceWith(first);
    expect(await gateway.pending(), hasLength(2));
    await scheduler.replaceWith(first);
    expect(gateway.calls.where((call) => call.operation == 'schedule'), hasLength(2));

    await scheduler.replaceWith(first.take(1));
    expect(await gateway.pending(), hasLength(1));
    await scheduler.replaceWith(const <PlannedReminder>[]);
    expect(await gateway.pending(), isEmpty);
    expect(await registry.snapshot(), isEmpty);
  });
}

Habit _habit(
  String id,
  HabitFrequency frequency, {
  List<int>? customDays,
  int target = 1,
  bool active = true,
}) => Habit(
  id: id,
  name: id,
  color: '#000000',
  icon: 'H',
  frequency: frequency,
  targetCount: target,
  category: 'Test',
  customDays: customDays,
  createdAt: DateTime.utc(2026, 8, 1),
  isActive: active,
  notificationEnabled: true,
  notificationTime: '09:00',
);
