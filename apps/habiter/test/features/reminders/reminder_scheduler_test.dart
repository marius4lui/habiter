import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/platform/notification_gateway.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/notification_id_registry.dart';
import 'package:habiter/features/reminders/application/reminder_scheduler.dart';
import 'package:habiter/features/reminders/domain/reminder_plan.dart';
import 'package:habiter/features/reminders/domain/reminder_payload.dart';
import 'package:habiter/models/habit.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test(
    'planner covers daily, weekdays and times-per-week without duplicates',
    () {
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
      expect(plan.where((item) => item.habit.id == 'weekly'), hasLength(7));
      expect(
        plan.map((item) => item.logicalKey).toSet(),
        hasLength(plan.length),
      );
    },
  );

  test('legacy fixed planner reconciles flexible weekly progress', () {
    final habit = _habit('weekly', HabitFrequency.weekly, target: 3);
    final reached = ReminderPlanner.plan(
      habits: <Habit>[habit],
      start: LocalDate(2026, 8, 17),
      location: tz.UTC,
      completedOccurrences: <String>{
        'weekly@2026-08-17',
        'weekly@2026-08-18',
        'weekly@2026-08-19',
      },
      horizonDays: 8,
    );
    final reopened = ReminderPlanner.plan(
      habits: <Habit>[habit],
      start: LocalDate(2026, 8, 17),
      location: tz.UTC,
      completedOccurrences: <String>{'weekly@2026-08-17', 'weekly@2026-08-18'},
      horizonDays: 8,
    );

    expect(reached.map((item) => item.occurrence), <LocalDate>[
      LocalDate(2026, 8, 24),
    ]);
    expect(reopened.map((item) => item.occurrence), <LocalDate>[
      LocalDate(2026, 8, 19),
      LocalDate(2026, 8, 20),
      LocalDate(2026, 8, 21),
      LocalDate(2026, 8, 22),
      LocalDate(2026, 8, 23),
      LocalDate(2026, 8, 24),
    ]);
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
    expect(
      (await gateway.pending()).first.actions.map((action) => action.id),
      <String>['complete', 'snooze'],
    );
    await scheduler.replaceWith(first);
    expect(
      gateway.calls.where((call) => call.operation == 'schedule'),
      hasLength(2),
    );

    await scheduler.replaceWith(first.take(1));
    expect(await gateway.pending(), hasLength(1));
    await scheduler.replaceWith(const <PlannedReminder>[]);
    expect(await gateway.pending(), isEmpty);
    expect(await registry.snapshot(), isEmpty);
  });

  test(
    'question reminders carry feedback actions and a persisted reason',
    () async {
      final gateway = RecordingNotificationGateway();
      final scheduler = ReminderScheduler(
        registry: NotificationIdRegistry(InMemoryKeyValueStore()),
        gateway: gateway,
      );
      final planned = PlannedReminder(
        logicalKey: 'habit@2026-08-17:calibration',
        habit: _habit('habit', HabitFrequency.daily),
        occurrence: LocalDate(2026, 8, 17),
        scheduledFor: DateTime.utc(2026, 8, 17, 9),
        kind: PlannedReminderKind.calibrationPulse,
        reason: const ReminderReason(
          code: ReminderReasonCode.calibrationUncertainty,
        ),
      );

      await scheduler.replaceWith(<PlannedReminder>[planned]);
      final request = (await gateway.pending()).single;
      expect(request.category, NotificationCategory.calibration);
      expect(request.actions.map((action) => action.id), <String>[
        'feasibility_good',
        'feasibility_maybe',
        'feasibility_bad',
      ]);
      expect(request.payload['schema'], contains('calibrationUncertainty'));
    },
  );

  test('same logical key is rescheduled when its instant changes', () async {
    final gateway = RecordingNotificationGateway();
    final scheduler = ReminderScheduler(
      registry: NotificationIdRegistry(InMemoryKeyValueStore()),
      gateway: gateway,
    );
    final first = PlannedReminder(
      logicalKey: 'stable-key',
      habit: _habit('habit', HabitFrequency.daily),
      occurrence: LocalDate(2026, 8, 17),
      scheduledFor: DateTime.utc(2026, 8, 17, 9),
    );

    await scheduler.replaceWith(<PlannedReminder>[first]);
    await scheduler.replaceWith(<PlannedReminder>[
      first.copyWith(scheduledFor: DateTime.utc(2026, 8, 17, 10)),
    ]);

    expect((await gateway.pending()).single.scheduledFor.hour, 10);
    expect(
      gateway.calls.where((call) => call.operation == 'schedule'),
      hasLength(2),
    );
    expect(
      gateway.calls.where((call) => call.operation == 'cancel'),
      hasLength(1),
    );
  });

  test('static and adaptive runtime schedules preserve each other', () async {
    final store = InMemoryKeyValueStore();
    final gateway = RecordingNotificationGateway();
    final registry = NotificationIdRegistry(store);
    final scheduler = ReminderScheduler(registry: registry, gateway: gateway);
    final staticReminder = PlannedReminder(
      logicalKey: 'static-reminder',
      habit: _habit('habit', HabitFrequency.daily),
      occurrence: LocalDate(2026, 8, 17),
      scheduledFor: DateTime.utc(2026, 8, 17, 9),
    );
    final runtimeReminder = staticReminder.copyWith(
      logicalKey: '${adaptiveRuntimeNotificationKeyPrefix}smart-reminder',
      scheduledFor: DateTime.utc(2026, 8, 17, 10),
    );

    await scheduler.replaceWith(<PlannedReminder>[
      staticReminder,
      runtimeReminder,
    ]);
    await scheduler.replaceWith(
      <PlannedReminder>[staticReminder],
      preserveRegistered: (key) =>
          key.startsWith(adaptiveRuntimeNotificationKeyPrefix),
    );
    expect(await gateway.pending(), hasLength(2));

    await scheduler.replaceWith(
      <PlannedReminder>[runtimeReminder],
      preserveRegistered: (key) =>
          !key.startsWith(adaptiveRuntimeNotificationKeyPrefix),
    );
    expect(await gateway.pending(), hasLength(2));
    expect((await registry.snapshot()).keys, <String>{
      staticReminder.logicalKey,
      runtimeReminder.logicalKey,
    });
  });

  test('habit snooze duration is carried in the durable payload', () async {
    final gateway = RecordingNotificationGateway();
    final scheduler = ReminderScheduler(
      registry: NotificationIdRegistry(InMemoryKeyValueStore()),
      gateway: gateway,
    );
    final planned = PlannedReminder(
      logicalKey: 'habit@2026-08-17',
      habit: _habit('habit', HabitFrequency.daily),
      occurrence: LocalDate(2026, 8, 17),
      scheduledFor: DateTime.utc(2026, 8, 17, 9),
      snoozeDuration: const Duration(minutes: 60),
    );

    await scheduler.replaceWith(<PlannedReminder>[planned]);
    final raw = (await gateway.pending()).single.payload['schema']!;
    final payload = ReminderPayload.fromMap(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );

    expect(payload.snoozeDuration, const Duration(minutes: 60));
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
