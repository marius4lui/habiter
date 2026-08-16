import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/reminder_action_inbox.dart';
import 'package:habiter/features/reminders/application/reminder_coordinator.dart';
import 'package:habiter/features/reminders/application/reminder_repository.dart';
import 'package:habiter/features/reminders/application/reminder_setup_service.dart';
import 'package:habiter/features/reminders/domain/reminder_action.dart';
import 'package:habiter/features/reminders/domain/reminder_plan.dart';
import 'package:habiter/features/reminders/domain/reminder_signal.dart';
import 'package:habiter/features/today/application/completion_use_case.dart';
import 'package:habiter/models/habit.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);
  final now = DateTime.utc(2026, 8, 17, 8);

  test(
    'initialization migrates legacy fixed plans and persists reasons',
    () async {
      final store = InMemoryKeyValueStore();
      final gateway = RecordingNotificationGateway();
      final coordinator = _coordinator(store, gateway, FakeClock(now));
      final habit = _habit(
        notificationEnabled: true,
        notificationTime: '09:00',
      );

      await coordinator.initialize(
        habits: <Habit>[habit],
        entries: const <HabitEntry>[],
        legacySettings: const LegacyReminderSettings(
          notificationsEnabled: false,
          reminderTime: '20:00',
        ),
      );

      expect(
        coordinator.policies[habit.id]!.fixed!.times.single.toString(),
        '09:00',
      );
      expect(coordinator.plannedReminders, hasLength(64));
      expect(
        coordinator.plannedReminders.first.reason.code,
        ReminderReasonCode.fixedTime,
      );
      expect(await gateway.pending(), hasLength(64));

      final restarted = ReminderRepository(store);
      expect(
        (await restarted.load()).plannedReminders.first.logicalKey,
        coordinator.plannedReminders.first.logicalKey,
      );
    },
  );

  test('manual completion near a plan is a 0.65 attributed signal', () async {
    final store = InMemoryKeyValueStore();
    final clock = FakeClock(now);
    final coordinator = _coordinator(
      store,
      RecordingNotificationGateway(),
      clock,
    );
    final habit = _habit(notificationEnabled: true, notificationTime: '09:00');
    await coordinator.initialize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      legacySettings: const LegacyReminderSettings(
        notificationsEnabled: false,
        reminderTime: '20:00',
      ),
    );
    final completionTime = DateTime.utc(2026, 8, 17, 9, 45);

    await coordinator.recordCompletion(
      habitId: habit.id,
      occurredAt: completionTime,
      signalId: 'completion',
    );

    final signal = (await ReminderRepository(store).load()).signals.single;
    expect(signal.source, SignalSource.habitCompletion);
    expect(signal.originatingNotificationKey, isNotNull);
    expect(signal.sourceWeight, 0.65);
  });

  test(
    'recent delivered plan survives resume for 90-minute attribution',
    () async {
      final store = InMemoryKeyValueStore();
      final clock = FakeClock(now);
      final coordinator = _coordinator(
        store,
        RecordingNotificationGateway(),
        clock,
      );
      final habit = _habit(
        notificationEnabled: true,
        notificationTime: '09:00',
      );
      await coordinator.initialize(
        habits: <Habit>[habit],
        entries: const <HabitEntry>[],
        legacySettings: const LegacyReminderSettings(
          notificationsEnabled: false,
          reminderTime: '20:00',
        ),
      );
      clock.set(DateTime.utc(2026, 8, 17, 9, 30));

      await coordinator.synchronize(
        habits: <Habit>[habit],
        entries: const <HabitEntry>[],
      );
      await coordinator.recordCompletion(
        habitId: habit.id,
        occurredAt: clock.now(),
        signalId: 'after-resume',
      );

      final signal = (await ReminderRepository(store).load()).signals.single;
      expect(signal.originatingNotificationKey, isNotNull);
      expect(signal.sourceWeight, 0.65);
    },
  );

  test('calibration feedback is durable, covered and idempotent', () async {
    final store = InMemoryKeyValueStore();
    final clock = FakeClock(now);
    final habit = _habit();
    final coordinator = _coordinator(
      store,
      RecordingNotificationGateway(),
      clock,
    );
    await coordinator.initialize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      legacySettings: const LegacyReminderSettings(
        notificationsEnabled: false,
        reminderTime: '20:00',
      ),
    );
    await coordinator.enableSmartForNewUser(sessionId: 'calibration');
    final inbox = ReminderActionInbox(store);
    final action = ReminderActionRecord(
      id: 'feedback-action',
      habitId: habit.id,
      occurrence: LocalDate(2026, 8, 17),
      receivedAt: now,
      notificationKey: 'smart-reminder',
      kind: ReminderActionKind.feasibilityBad,
      notificationKind: PlannedReminderKind.calibrationPulse,
    );
    await inbox.enqueue(action);

    await coordinator.synchronize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      processActions: true,
    );
    await inbox.enqueue(action);
    await coordinator.synchronize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      processActions: true,
    );

    final snapshot = await ReminderRepository(store).load();
    expect(snapshot.signals, hasLength(1));
    expect(snapshot.signals.single.feasibility, FeasibilityRating.bad);
    expect(snapshot.calibration!.answeredPulseCount, 1);
    expect(snapshot.calibration!.coveredBuckets, hasLength(1));
    expect(snapshot.processedActionIds, contains(action.id));
  });

  test(
    'snooze is a weak signal and remains subject to planner guardrails',
    () async {
      final store = InMemoryKeyValueStore();
      final habit = _habit();
      final coordinator = _coordinator(
        store,
        RecordingNotificationGateway(),
        FakeClock(now),
      );
      await coordinator.initialize(
        habits: <Habit>[habit],
        entries: const <HabitEntry>[],
        legacySettings: const LegacyReminderSettings(
          notificationsEnabled: false,
          reminderTime: '20:00',
        ),
      );
      await coordinator.enableSmartForNewUser(sessionId: 'calibration');
      await ReminderActionInbox(store).enqueue(
        ReminderActionRecord(
          id: 'snooze-action',
          habitId: habit.id,
          occurrence: LocalDate(2026, 8, 17),
          receivedAt: now,
          notificationKey: 'smart-reminder',
          kind: ReminderActionKind.snooze,
          snoozeDuration: const Duration(minutes: 30),
        ),
      );

      await coordinator.synchronize(
        habits: <Habit>[habit],
        entries: const <HabitEntry>[],
        processActions: true,
      );

      final snapshot = await ReminderRepository(store).load();
      expect(snapshot.signals.single.source, SignalSource.snooze);
      expect(snapshot.signals.single.targetValue, 0.25);
      expect(snapshot.signals.single.sourceWeight, 0.5);
      expect(
        snapshot.plannedReminders.any(
          (item) => item.kind == PlannedReminderKind.snooze,
        ),
        isTrue,
      );
    },
  );

  test('snooze action uses its policy-derived duration', () async {
    final store = InMemoryKeyValueStore();
    final habit = _habit();
    final coordinator = _coordinator(
      store,
      RecordingNotificationGateway(),
      FakeClock(now),
    );
    await coordinator.initialize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      legacySettings: const LegacyReminderSettings(
        notificationsEnabled: false,
        reminderTime: '20:00',
      ),
    );
    await coordinator.enableSmartForNewUser(sessionId: 'calibration');
    await ReminderActionInbox(store).enqueue(
      ReminderActionRecord(
        id: 'custom-snooze',
        habitId: habit.id,
        occurrence: LocalDate(2026, 8, 17),
        receivedAt: now,
        notificationKey: 'smart-reminder',
        kind: ReminderActionKind.snooze,
        snoozeDuration: const Duration(minutes: 60),
      ),
    );

    await coordinator.synchronize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      processActions: true,
    );

    final pending = (await ReminderRepository(
      store,
    ).load()).pendingSnoozes.single;
    expect(pending.scheduledFor, now.add(const Duration(minutes: 60)));
  });

  test('expired active calibration completes during reconciliation', () async {
    final store = InMemoryKeyValueStore();
    final clock = FakeClock(now);
    final habit = _habit();
    final coordinator = _coordinator(
      store,
      RecordingNotificationGateway(),
      clock,
    );
    await coordinator.initialize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      legacySettings: const LegacyReminderSettings(
        notificationsEnabled: false,
        reminderTime: '20:00',
      ),
    );
    await coordinator.enableSmartForNewUser(sessionId: 'calibration');
    clock.advance(const Duration(days: 7, minutes: 1));

    await coordinator.synchronize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
    );

    expect(coordinator.calibration!.status.name, 'completed');
    expect(coordinator.calibration!.completedAt, clock.now());
  });

  test('pruned raw feedback does not erase its persisted aggregate', () async {
    final store = InMemoryKeyValueStore();
    final clock = FakeClock(now);
    final habit = _habit();
    final coordinator = _coordinator(
      store,
      RecordingNotificationGateway(),
      clock,
    );
    await coordinator.initialize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
      legacySettings: const LegacyReminderSettings(
        notificationsEnabled: false,
        reminderTime: '20:00',
      ),
    );
    await coordinator.enableSmartForNewUser(sessionId: 'calibration');
    await ReminderRepository(store).appendSignal(
      ReminderSignal(
        id: 'old-feedback',
        habitId: habit.id,
        source: SignalSource.inAppFeedback,
        occurredAtUtc: now.subtract(const Duration(days: 181)),
        timeZoneId: 'UTC',
        localWeekday: DateTime.monday,
        localMinuteOfDay: 600,
        feasibility: FeasibilityRating.good,
        createdAt: now.subtract(const Duration(days: 181)),
      ),
    );

    await coordinator.synchronize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
    );
    final learned = coordinator.profiles['habit:${habit.id}']!;
    expect((await ReminderRepository(store).load()).signals, isEmpty);
    await coordinator.synchronize(
      habits: <Habit>[habit],
      entries: const <HabitEntry>[],
    );
    final retained = coordinator.profiles['habit:${habit.id}']!;

    expect(
      retained.bucketFor(DateTime.monday, 600)!.combinedScore,
      learned.bucketFor(DateTime.monday, 600)!.combinedScore,
    );
    expect(retained.computedAt, learned.computedAt);
  });
}

ReminderCoordinator _coordinator(
  InMemoryKeyValueStore store,
  RecordingNotificationGateway gateway,
  FakeClock clock,
) => ReminderCoordinator(
  store: store,
  notifications: gateway,
  clock: clock,
  ids: FakeIdGenerator(<String>['generated-signal']),
  complete: (_, _) async =>
      const CompletionResult(status: CompletionStatus.completed),
  location: () => tz.UTC,
);

Habit _habit({bool notificationEnabled = false, String? notificationTime}) =>
    Habit(
      id: 'habit',
      name: 'Habit',
      color: '#000000',
      icon: 'H',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      category: 'Health',
      createdAt: DateTime.utc(2026, 8, 1),
      isActive: true,
      notificationEnabled: notificationEnabled,
      notificationTime: notificationTime,
    );
