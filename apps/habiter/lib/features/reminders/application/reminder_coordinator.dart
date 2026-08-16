import 'package:timezone/timezone.dart' as tz;

import '../../../core/ids/id_generator.dart';
import '../../../core/persistence/key_value_store.dart';
import '../../../core/platform/notification_gateway.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../today/application/completion_use_case.dart';
import '../domain/availability_profile.dart';
import '../domain/calibration_session.dart';
import '../domain/local_time.dart';
import '../domain/reminder_plan.dart';
import '../domain/reminder_policy.dart';
import '../domain/reminder_preferences.dart';
import '../domain/reminder_signal.dart';
import 'dynamic_reminder_planner.dart';
import 'notification_id_registry.dart';
import 'reminder_action_inbox.dart';
import 'reminder_reconciler.dart';
import 'reminder_repository.dart';
import 'reminder_scheduler.dart';
import 'reminder_setup_service.dart';

typedef CompleteFromReminder =
    Future<CompletionResult> Function(String habitId, String date);

final class ReminderCoordinator {
  ReminderCoordinator({
    required KeyValueStore store,
    required NotificationGateway notifications,
    required Clock clock,
    required IdGenerator ids,
    required CompleteFromReminder complete,
    tz.Location Function()? location,
    DynamicReminderPlanner planner = const DynamicReminderPlanner(),
  }) : _repository = ReminderRepository(store),
       _notifications = notifications,
       _clock = clock,
       _ids = ids,
       _complete = complete,
       _location = location ?? _safeLocalLocation,
       _planner = planner,
       _scheduler = ReminderScheduler(
         registry: NotificationIdRegistry(store),
         gateway: notifications,
       ),
       _reconciler = ReminderReconciler(
         registry: NotificationIdRegistry(store),
         gateway: notifications,
       ),
       _inbox = ReminderActionInbox(store);

  final ReminderRepository _repository;
  final NotificationGateway _notifications;
  final Clock _clock;
  final IdGenerator _ids;
  final CompleteFromReminder _complete;
  final tz.Location Function() _location;
  final DynamicReminderPlanner _planner;
  final ReminderScheduler _scheduler;
  final ReminderReconciler _reconciler;
  final ReminderActionInbox _inbox;

  ReminderRepositorySnapshot _snapshot = ReminderRepositorySnapshot();
  List<Habit> _habits = const <Habit>[];
  List<HabitEntry> _entries = const <HabitEntry>[];

  ReminderRepositorySnapshot get snapshot => _snapshot;
  ReminderPreferences get preferences => _snapshot.preferences;
  Map<String, HabitReminderPolicy> get policies => _snapshot.policies;
  CalibrationSession? get calibration => _snapshot.calibration;
  List<PersistedPlannedReminder> get plannedReminders =>
      _snapshot.plannedReminders;
  Map<String, AvailabilityProfile> get profiles => _snapshot.profiles;

  Future<void> initialize({
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
    required LegacyReminderSettings legacySettings,
  }) async {
    await ReminderSetupService(_repository).migrateLegacy(
      habits: habits,
      settings: legacySettings,
      now: _clock.now(),
    );
    await _notifications.initialize();
    await synchronize(habits: habits, entries: entries, processActions: true);
  }

  Future<void> synchronize({
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
    bool processActions = false,
  }) async {
    _habits = List<Habit>.unmodifiable(habits);
    _entries = List<HabitEntry>.unmodifiable(entries);
    await _completeExpiredCalibration();
    if (processActions) await _drainActions();
    _snapshot = await _repository.load();
    final now = _clock.now();
    final location = _location();
    final localNow = tz.TZDateTime.from(now, location);
    final completed = <String>{
      for (final entry in _entries)
        if (entry.completed) '${entry.habitId}@${entry.date}',
    };
    final result = _planner.plan(
      DynamicReminderPlanInput(
        habits: _habits,
        policies: _snapshot.policies,
        preferences: _snapshot.preferences,
        signals: _snapshot.signals,
        calibration: _snapshot.calibration,
        completedOccurrences: completed,
        pendingSnoozes: _snapshot.pendingSnoozes,
        start: LocalDate(localNow.year, localNow.month, localNow.day),
        now: now,
        location: location,
        horizonDays: 90,
        capacity: 64,
      ),
    );
    await _scheduler.replaceWith(result.reminders);
    await _reconciler.reconcile();
    final profiles = <String, AvailabilityProfile>{};
    for (final computation in result.profilesByHabit.values) {
      profiles[computation.categoryProfile.profileId] =
          computation.categoryProfile;
      profiles[computation.globalUserProfile.profileId] =
          computation.globalUserProfile;
      profiles[computation.habitProfile.profileId] = computation.habitProfile;
    }
    final desiredKeys = result.reminders.map((item) => item.logicalKey).toSet();
    await _repository.transact((draft) {
      draft.profiles = profiles;
      draft.plannedReminders = result.reminders
          .map(
            (item) => PersistedPlannedReminder(
              logicalKey: item.logicalKey,
              habitId: item.habit.id,
              occurrence: item.occurrence,
              scheduledFor: item.scheduledFor,
              kind: item.kind,
              reason: item.reason,
            ),
          )
          .toList(growable: false);
      draft.pendingSnoozes.removeWhere(
        (snooze) =>
            snooze.scheduledFor.isBefore(now) ||
            !desiredKeys.any((key) => key.startsWith('${snooze.habitId}@')),
      );
      final cutoff = now.toUtc().subtract(
        ReminderRepository.rawSignalRetention,
      );
      draft.signals.removeWhere(
        (signal) => signal.occurredAtUtc.isBefore(cutoff),
      );
    });
    _snapshot = await _repository.load();
  }

  Future<void> updatePolicy(HabitReminderPolicy policy) async {
    await _repository.transact((draft) {
      draft.policies[policy.habitId] = policy;
    });
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> ensurePolicyForNewHabit(Habit habit) async {
    await ReminderSetupService(
      _repository,
    ).addSmartPolicyForNewHabit(habit: habit, now: _clock.now());
    _snapshot = await _repository.load();
  }

  Future<void> applyLegacyHabitPolicy(Habit habit) async {
    await _repository.transact((draft) {
      final existing = draft.policies[habit.id];
      if (existing != null && existing.mode != ReminderMode.fixedTimes) return;
      LocalTime time;
      try {
        time = LocalTime.parse(
          habit.notificationTime ??
              existing?.fixed?.times.firstOrNull?.toString() ??
              '20:00',
        );
      } on FormatException {
        time = const LocalTime(20, 0);
      }
      draft.policies[habit.id] = HabitReminderPolicy.fixedTimes(
        habitId: habit.id,
        times: <LocalTime>[time],
        now: existing?.createdAt ?? _clock.now(),
        enabled: habit.notificationEnabled && habit.notificationTime != null,
      ).copyWith(updatedAt: _clock.now());
      draft.preferences = draft.preferences.copyWith(
        enabled:
            draft.preferences.dailyOverview.enabled ||
            draft.policies.values.any((policy) => policy.enabled),
      );
    });
    _snapshot = await _repository.load();
  }

  Future<void> applyLegacyOverviewSettings({
    required bool enabled,
    required String time,
  }) async {
    LocalTime parsed;
    try {
      parsed = LocalTime.parse(time);
    } on FormatException {
      parsed = const LocalTime(20, 0);
    }
    await _repository.transact((draft) {
      draft.preferences = draft.preferences.copyWith(
        enabled:
            enabled || draft.policies.values.any((policy) => policy.enabled),
        dailyOverview: DailyOverviewReminder(enabled: enabled, time: parsed),
      );
    });
    _snapshot = await _repository.load();
  }

  Future<void> deleteHabitData(String habitId) async {
    await _repository.transact((draft) {
      draft.policies.remove(habitId);
      draft.signals.removeWhere((signal) => signal.habitId == habitId);
      draft.profiles.removeWhere((_, profile) => profile.habitId == habitId);
      draft.plannedReminders.removeWhere(
        (reminder) => reminder.habitId == habitId,
      );
      draft.pendingSnoozes.removeWhere((snooze) => snooze.habitId == habitId);
    });
    _snapshot = await _repository.load();
  }

  Future<void> updatePreferences(ReminderPreferences preferences) async {
    await _repository.transact((draft) => draft.preferences = preferences);
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> enableSmartForNewUser({required String sessionId}) async {
    await ReminderSetupService(_repository).enableSmartForNewUser(
      habits: _habits,
      calibrationSessionId: sessionId,
      now: _clock.now(),
    );
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> pauseCalibration() async {
    final now = _clock.now();
    await _repository.transact((draft) {
      final session = draft.calibration;
      if (session?.status != CalibrationStatus.active) return;
      draft.calibration = session!.copyWith(
        status: CalibrationStatus.paused,
        pausedAt: now,
      );
    });
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> resumeCalibration() async {
    final now = _clock.now();
    await _repository.transact((draft) {
      final session = draft.calibration;
      if (session?.status != CalibrationStatus.paused ||
          session!.pausedAt == null) {
        return;
      }
      draft.calibration = session.copyWith(
        status: CalibrationStatus.active,
        plannedEndAt: session.plannedEndAt.add(
          now.difference(session.pausedAt!),
        ),
        clearPausedAt: true,
      );
    });
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> restartCalibration({required String sessionId}) async {
    await _repository.transact((draft) {
      draft.calibration = CalibrationSession.start(
        id: sessionId,
        now: _clock.now(),
      );
      draft.preferences = draft.preferences.copyWith(calibrationEnabled: true);
    });
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> resetLearning() async {
    await _repository.resetLearning();
    await synchronize(habits: _habits, entries: _entries);
  }

  Future<void> recordCompletion({
    required String habitId,
    required DateTime occurredAt,
    String? signalId,
  }) async {
    final location = _location();
    final local = tz.TZDateTime.from(occurredAt, location);
    final matching =
        _snapshot.plannedReminders
            .where(
              (item) =>
                  item.habitId == habitId &&
                  !occurredAt.isBefore(item.scheduledFor) &&
                  occurredAt.difference(item.scheduledFor) <=
                      const Duration(minutes: 90),
            )
            .toList()
          ..sort(
            (left, right) => right.scheduledFor.compareTo(left.scheduledFor),
          );
    await _repository.appendSignal(
      ReminderSignal(
        id: signalId ?? _ids.next(),
        habitId: habitId,
        source: SignalSource.habitCompletion,
        occurredAtUtc: occurredAt.toUtc(),
        timeZoneId: location.name,
        localWeekday: local.weekday,
        localMinuteOfDay: local.hour * 60 + local.minute,
        originatingNotificationKey: matching.isEmpty
            ? null
            : matching.first.logicalKey,
        createdAt: _clock.now(),
      ),
    );
  }

  Future<void> removeCompletionSignal(
    CompletionUndoToken token,
  ) => _repository.transact((draft) {
    draft.signals.removeWhere(
      (signal) =>
          signal.id ==
          'completion:${token.habitId}:${token.date}:${token.committedAt.toUtc().toIso8601String()}',
    );
  });

  Future<void> removeToggleCompletionSignal(String habitId, String date) =>
      _repository.transact((draft) {
        draft.signals.removeWhere(
          (signal) => signal.id.startsWith('toggle:$habitId:$date:'),
        );
      });

  Future<void> _drainActions() async {
    final processor = ReminderActionProcessor(
      inbox: _inbox,
      clock: _clock,
      complete: (_, _) async {},
      completeAction: _completeAction,
      recordFeasibility: _recordFeasibility,
      snooze: _recordSnooze,
      isProcessed: (id) async =>
          (await _repository.load()).processedActionIds.contains(id),
      markProcessed: (id) => _repository.transact((draft) {
        draft.processedActionIds.add(id);
      }),
    );
    await processor.drain();
    _snapshot = await _repository.load();
  }

  Future<void> _completeAction(ReminderActionRecord action) async {
    final result = await _complete(
      action.habitId,
      action.occurrence.toString(),
    );
    if (!result.changed) return;
    final location = _location();
    final local = tz.TZDateTime.from(action.receivedAt, location);
    await _repository.appendSignal(
      ReminderSignal(
        id: 'signal:${action.id}',
        habitId: action.habitId,
        source: SignalSource.notificationCompletion,
        occurredAtUtc: action.receivedAt.toUtc(),
        timeZoneId: location.name,
        localWeekday: local.weekday,
        localMinuteOfDay: local.hour * 60 + local.minute,
        originatingNotificationKey: action.notificationKey,
        createdAt: _clock.now(),
      ),
    );
  }

  Future<void> _recordFeasibility(
    ReminderActionRecord action,
    FeasibilityRating rating,
  ) async {
    final location = _location();
    final local = tz.TZDateTime.from(action.receivedAt, location);
    await _repository.transact((draft) {
      if (!draft.signals.any((signal) => signal.id == 'signal:${action.id}')) {
        draft.signals.add(
          ReminderSignal(
            id: 'signal:${action.id}',
            habitId: action.habitId,
            source:
                action.notificationKind == PlannedReminderKind.calibrationPulse
                ? SignalSource.calibrationNotification
                : SignalSource.fineTuningNotification,
            occurredAtUtc: action.receivedAt.toUtc(),
            timeZoneId: location.name,
            localWeekday: local.weekday,
            localMinuteOfDay: local.hour * 60 + local.minute,
            feasibility: rating,
            originatingNotificationKey: action.notificationKey,
            calibrationSessionId: draft.calibration?.id,
            createdAt: _clock.now(),
          ),
        );
      }
      final session = draft.calibration;
      if (action.notificationKind == PlannedReminderKind.calibrationPulse &&
          session != null) {
        final bucket = CalibrationBucketKey(
          localDate: action.occurrence,
          twoHourStartMinute: (local.hour * 60 + local.minute) ~/ 120 * 120,
          habitId: action.habitId,
          timeZoneId: location.name,
        );
        draft.calibration = session.copyWith(
          answeredPulseCount: session.answeredPulseCount + 1,
          coveredBuckets: <CalibrationBucketKey>{
            ...session.coveredBuckets,
            bucket,
          },
        );
      }
    });
  }

  Future<void> _recordSnooze(ReminderActionRecord action) async {
    final location = _location();
    final local = tz.TZDateTime.from(action.receivedAt, location);
    await _repository.transact((draft) {
      if (!draft.signals.any((signal) => signal.id == 'signal:${action.id}')) {
        draft.signals.add(
          ReminderSignal(
            id: 'signal:${action.id}',
            habitId: action.habitId,
            source: SignalSource.snooze,
            occurredAtUtc: action.receivedAt.toUtc(),
            timeZoneId: location.name,
            localWeekday: local.weekday,
            localMinuteOfDay: local.hour * 60 + local.minute,
            originatingNotificationKey: action.notificationKey,
            createdAt: _clock.now(),
          ),
        );
      }
      final snooze = PendingReminderSnooze(
        id: '${action.id}:snooze',
        habitId: action.habitId,
        occurrence: action.occurrence,
        scheduledFor: action.receivedAt.add(action.snoozeDuration),
        createdAt: _clock.now(),
      );
      draft.pendingSnoozes.removeWhere((item) => item.id == snooze.id);
      draft.pendingSnoozes.add(snooze);
    });
  }

  Future<void> _completeExpiredCalibration() => _repository.transact((draft) {
    final session = draft.calibration;
    final now = _clock.now();
    if (session?.status == CalibrationStatus.active &&
        !now.isBefore(session!.plannedEndAt)) {
      draft.calibration = session.copyWith(
        status: CalibrationStatus.completed,
        completedAt: now,
      );
    }
  });
}

tz.Location _safeLocalLocation() {
  try {
    return tz.local;
  } catch (_) {
    return tz.UTC;
  }
}
