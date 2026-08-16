import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/reminders/application/reminder_repository.dart';
import 'package:habiter/features/reminders/application/reminder_setup_service.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/domain/local_time.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/features/reminders/domain/reminder_plan.dart';
import 'package:habiter/features/reminders/domain/reminder_signal.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  final now = DateTime.utc(2026, 8, 16, 12);

  test(
    'repository persists policies and idempotent signals across restarts',
    () async {
      final store = InMemoryKeyValueStore();
      final repository = ReminderRepository(store);
      final policy = HabitReminderPolicy.smart(habitId: 'habit', now: now);
      final signal = _signal('signal', now);
      await repository.transact((draft) {
        draft.policies[policy.habitId] = policy;
        draft.preferences = draft.preferences.copyWith(enabled: true);
      });
      await Future.wait(<Future<void>>[
        repository.appendSignal(signal),
        repository.appendSignal(signal),
      ]);

      final restored = await ReminderRepository(store).load();
      expect(restored.policies['habit']!.mode, ReminderMode.smart);
      expect(restored.signals, hasLength(1));
      expect(restored.preferences.enabled, isTrue);
    },
  );

  test('raw retention runs after profiles can be stored', () async {
    final repository = ReminderRepository(InMemoryKeyValueStore());
    await repository.appendSignal(
      _signal('old', now.subtract(const Duration(days: 181))),
    );
    await repository.appendSignal(_signal('recent', now));

    expect(await repository.pruneRawSignals(now), 1);
    expect((await repository.load()).signals.single.id, 'recent');
  });

  test(
    'profile reset removes learning data but retains policies and preferences',
    () async {
      final repository = ReminderRepository(InMemoryKeyValueStore());
      await repository.transact((draft) {
        draft.preferences = draft.preferences.copyWith(enabled: true);
        draft.policies['habit'] = HabitReminderPolicy.smart(
          habitId: 'habit',
          now: now,
        );
        draft.signals.add(_signal('signal', now));
        draft.processedActionIds.add('action');
        draft.policies['fixed'] = HabitReminderPolicy.fixedTimes(
          habitId: 'fixed',
          times: const <LocalTime>[LocalTime(9, 0)],
          now: now,
        );
        draft.plannedReminders.addAll(<PersistedPlannedReminder>[
          PersistedPlannedReminder(
            logicalKey: 'smart',
            habitId: 'habit',
            occurrence: LocalDate(2026, 8, 17),
            scheduledFor: now.add(const Duration(hours: 1)),
            kind: PlannedReminderKind.normal,
            reason: const ReminderReason(
              code: ReminderReasonCode.categoryPreset,
            ),
          ),
          PersistedPlannedReminder(
            logicalKey: 'fixed',
            habitId: 'fixed',
            occurrence: LocalDate(2026, 8, 17),
            scheduledFor: now.add(const Duration(hours: 2)),
            kind: PlannedReminderKind.normal,
            reason: const ReminderReason(code: ReminderReasonCode.fixedTime),
          ),
        ]);
      });

      await repository.resetLearning();
      final snapshot = await repository.load();
      expect(snapshot.policies, contains('habit'));
      expect(snapshot.preferences.enabled, isTrue);
      expect(snapshot.signals, isEmpty);
      expect(snapshot.profiles, isEmpty);
      expect(snapshot.processedActionIds, contains('action'));
      expect(snapshot.plannedReminders.single.habitId, 'fixed');
    },
  );

  test('legacy migration preserves fixed times and disabled state', () async {
    final repository = ReminderRepository(InMemoryKeyValueStore());
    final service = ReminderSetupService(repository);
    final habits = <Habit>[
      _habit('enabled', enabled: true, time: '07:15'),
      _habit('disabled', enabled: false, time: '19:45'),
      _habit('none', enabled: false),
    ];

    expect(
      await service.migrateLegacy(
        habits: habits,
        settings: const LegacyReminderSettings(
          notificationsEnabled: true,
          reminderTime: '21:10',
        ),
        now: now,
      ),
      isTrue,
    );
    expect(
      await service.migrateLegacy(
        habits: habits,
        settings: const LegacyReminderSettings(
          notificationsEnabled: false,
          reminderTime: '10:00',
        ),
        now: now,
      ),
      isFalse,
    );

    final snapshot = await repository.load();
    expect(snapshot.policies['enabled']!.mode, ReminderMode.fixedTimes);
    expect(snapshot.policies['enabled']!.fixed!.times, const <LocalTime>[
      LocalTime(7, 15),
    ]);
    expect(snapshot.policies['disabled']!.enabled, isFalse);
    expect(snapshot.policies['none']!.enabled, isFalse);
    expect(snapshot.preferences.dailyOverview.enabled, isTrue);
    expect(snapshot.preferences.dailyOverview.time, const LocalTime(21, 10));
    expect(snapshot.calibration, isNull);
  });

  test(
    'new-user opt-in starts persistent Smart defaults and calibration',
    () async {
      final repository = ReminderRepository(InMemoryKeyValueStore());
      await ReminderSetupService(repository).enableSmartForNewUser(
        habits: <Habit>[_habit('one'), _habit('two')],
        calibrationSessionId: 'calibration',
        now: now,
      );

      final snapshot = await repository.load();
      expect(snapshot.preferences.enabled, isTrue);
      expect(snapshot.preferences.globalDailyLimit, 8);
      expect(
        snapshot.preferences.globalMinimumSpacing,
        const Duration(minutes: 90),
      );
      expect(
        snapshot.policies.values.every(
          (policy) => policy.mode == ReminderMode.smart,
        ),
        isTrue,
      );
      expect(
        snapshot.policies.values.every(
          (policy) => policy.intensity == ReminderIntensity.persistent,
        ),
        isTrue,
      );
      expect(
        snapshot.calibration!.plannedEndAt,
        now.add(const Duration(days: 7)),
      );
    },
  );

  test('unknown root and policy fields survive repository roundtrip', () async {
    final store = InMemoryKeyValueStore(<String, Object?>{
      ReminderRepository.storageKey: jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'preferences': <String, Object?>{},
        'policies': <Object?>[
          <String, Object?>{
            ...HabitReminderPolicy.smart(habitId: 'habit', now: now).toMap(),
            'futurePolicy': 42,
          },
        ],
        'signals': <Object?>[],
        'profiles': <Object?>[],
        'legacyMigrationComplete': true,
        'processedActionIds': <Object?>[],
        'futureRoot': <String, Object?>{'value': true},
      }),
    });
    final repository = ReminderRepository(store);

    await repository.transact((draft) {
      draft.preferences = draft.preferences.copyWith(globalDailyLimit: 7);
    });
    final raw =
        jsonDecode(await store.read(ReminderRepository.storageKey) as String)
            as Map<String, dynamic>;
    expect(raw['futureRoot'], <String, Object?>{'value': true});
    expect((raw['policies'] as List).single['futurePolicy'], 42);
  });
}

ReminderSignal _signal(String id, DateTime occurredAt) => ReminderSignal(
  id: id,
  habitId: 'habit',
  source: SignalSource.inAppFeedback,
  occurredAtUtc: occurredAt,
  timeZoneId: 'UTC',
  localWeekday: DateTime.sunday,
  localMinuteOfDay: 720,
  feasibility: FeasibilityRating.good,
  createdAt: occurredAt,
);

Habit _habit(String id, {bool enabled = false, String? time}) => Habit(
  id: id,
  name: id,
  color: '#000000',
  icon: 'H',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  createdAt: DateTime.utc(2026, 8, 1),
  isActive: true,
  notificationEnabled: enabled,
  notificationTime: time,
);
