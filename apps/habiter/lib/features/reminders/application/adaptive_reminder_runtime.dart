import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/persistence/shared_preferences_key_value_store.dart';
import '../../../core/time/local_date.dart';
import '../../habits/data/key_value_habit_repository.dart';
import '../domain/reminder_plan.dart';
import '../domain/reminder_policy.dart';
import '../../../services/notification_service.dart';
import 'dynamic_reminder_planner.dart';
import 'notification_id_registry.dart';
import 'reminder_repository.dart';
import 'reminder_scheduler.dart';

final class AdaptiveReminderDecision {
  const AdaptiveReminderDecision({
    required this.notification,
    required this.nextEvaluationAt,
  });

  final PlannedReminder? notification;
  final DateTime? nextEvaluationAt;

  static AdaptiveReminderDecision fromCandidates({
    required Iterable<PlannedReminder> candidates,
    required DateTime now,
    Duration evaluationLead = const Duration(minutes: 1),
  }) {
    final ordered = candidates.toList()
      ..sort((left, right) {
        final time = left.scheduledFor.compareTo(right.scheduledFor);
        return time != 0 ? time : left.logicalKey.compareTo(right.logicalKey);
      });
    if (ordered.isEmpty) {
      return const AdaptiveReminderDecision(
        notification: null,
        nextEvaluationAt: null,
      );
    }
    final next = ordered.first;
    final finalEvaluationAt = next.scheduledFor.subtract(evaluationLead);
    if (finalEvaluationAt.isAfter(now)) {
      return AdaptiveReminderDecision(
        notification: null,
        nextEvaluationAt: finalEvaluationAt,
      );
    }
    return AdaptiveReminderDecision(
      notification: next.copyWith(
        logicalKey: '$adaptiveRuntimeNotificationKeyPrefix${next.logicalKey}',
      ),
      nextEvaluationAt: next.scheduledFor.add(const Duration(seconds: 1)),
    );
  }
}

final class HeadlessAdaptiveReminderRuntime {
  HeadlessAdaptiveReminderRuntime({
    SharedPreferencesKeyValueStore? store,
    DynamicReminderPlanner planner = const DynamicReminderPlanner(),
    NotificationService? notifications,
  }) : _store = store ?? SharedPreferencesKeyValueStore(),
       _planner = planner,
       _notifications = notifications ?? NotificationService.instance;

  final SharedPreferencesKeyValueStore _store;
  final DynamicReminderPlanner _planner;
  final NotificationService _notifications;

  Future<Map<String, Object?>> evaluate() async {
    await _notifications.initialize();
    final habitSnapshot = await KeyValueHabitRepository(_store).load();
    final repository = ReminderRepository(_store);
    final reminderSnapshot = await repository.load();
    final now = DateTime.now();
    final location = _safeLocalLocation();
    final localNow = tz.TZDateTime.from(now, location);
    final result = _planner.plan(
      DynamicReminderPlanInput(
        habits: habitSnapshot.habits,
        policies: reminderSnapshot.policies,
        preferences: reminderSnapshot.preferences,
        signals: reminderSnapshot.signals,
        calibration: reminderSnapshot.calibration,
        completedOccurrences: <String>{
          for (final entry in habitSnapshot.entries)
            if (entry.completed) '${entry.habitId}@${entry.date}',
        },
        pendingSnoozes: reminderSnapshot.pendingSnoozes,
        baselineProfiles: reminderSnapshot.profiles,
        start: LocalDate(localNow.year, localNow.month, localNow.day),
        now: now,
        location: location,
        horizonDays: 14,
        capacity: 64,
      ),
    );
    final adaptive = result.reminders.where(
      (reminder) =>
          reminderSnapshot.policies[reminder.habit.id]?.mode ==
          ReminderMode.smart,
    );
    final decision = AdaptiveReminderDecision.fromCandidates(
      candidates: adaptive,
      now: now,
    );
    final scheduler = ReminderScheduler(
      registry: NotificationIdRegistry(_store),
      gateway: _notifications,
    );
    await scheduler.replaceWith(
      <PlannedReminder>[
        if (decision.notification != null) decision.notification!,
      ],
      preserveRegistered: (key) =>
          !key.startsWith(adaptiveRuntimeNotificationKeyPrefix),
    );
    await repository.transact((draft) {
      for (final computation in result.profilesByHabit.values) {
        draft.profiles[computation.categoryProfile.profileId] =
            computation.categoryProfile;
        draft.profiles[computation.globalUserProfile.profileId] =
            computation.globalUserProfile;
        draft.profiles[computation.habitProfile.profileId] =
            computation.habitProfile;
      }
      draft.plannedReminders = result.reminders
          .map(
            (reminder) => PersistedPlannedReminder(
              logicalKey: reminder.logicalKey,
              habitId: reminder.habit.id,
              occurrence: reminder.occurrence,
              scheduledFor: reminder.scheduledFor,
              kind: reminder.kind,
              reason: reminder.reason,
            ),
          )
          .toList(growable: false);
    });
    return <String, Object?>{
      'nextEvaluationAt': decision.nextEvaluationAt?.millisecondsSinceEpoch,
      'dispatched': decision.notification != null,
    };
  }
}

const _engineChannel = MethodChannel('com.habiter.app/runtime_engine');

Future<void> startHabiterReminderRuntime() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  final runtime = HeadlessAdaptiveReminderRuntime();
  _engineChannel.setMethodCallHandler((call) async {
    if (call.method == 'evaluate') return runtime.evaluate();
    throw MissingPluginException(
      'Unknown runtime engine method ${call.method}',
    );
  });
  await _engineChannel.invokeMethod<void>('ready');
}

tz.Location _safeLocalLocation() {
  try {
    return tz.local;
  } catch (_) {
    return tz.UTC;
  }
}
