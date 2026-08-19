import 'dart:convert';

import 'package:timezone/timezone.dart' as tz;

import '../../../core/platform/notification_gateway.dart';
import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule.dart';
import '../../habits/domain/habit_schedule_progress.dart';
import '../domain/reminder_plan.dart';
import '../domain/reminder_payload.dart';
import '../infrastructure/device_time_zone_service.dart';
import 'notification_id_registry.dart';

final class PlannedReminder {
  const PlannedReminder({
    required this.logicalKey,
    required this.habit,
    required this.occurrence,
    required this.scheduledFor,
    this.kind = PlannedReminderKind.normal,
    this.attemptIndex = 0,
    this.utility = 1,
    this.reason = const ReminderReason(code: ReminderReasonCode.fixedTime),
    this.snoozeDuration = const Duration(minutes: 30),
  });

  final String logicalKey;
  final Habit habit;
  final LocalDate occurrence;
  final DateTime scheduledFor;
  final PlannedReminderKind kind;
  final int attemptIndex;
  final double utility;
  final ReminderReason reason;
  final Duration snoozeDuration;

  PlannedReminder copyWith({
    String? logicalKey,
    DateTime? scheduledFor,
    PlannedReminderKind? kind,
    double? utility,
    ReminderReason? reason,
    Duration? snoozeDuration,
  }) => PlannedReminder(
    logicalKey: logicalKey ?? this.logicalKey,
    habit: habit,
    occurrence: occurrence,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    kind: kind ?? this.kind,
    attemptIndex: attemptIndex,
    utility: utility ?? this.utility,
    reason: reason ?? this.reason,
    snoozeDuration: snoozeDuration ?? this.snoozeDuration,
  );
}

abstract final class ReminderPlanner {
  static List<PlannedReminder> plan({
    required Iterable<Habit> habits,
    required LocalDate start,
    required tz.Location location,
    Set<String> completedOccurrences = const <String>{},
    int horizonDays = 90,
    int capacity = 64,
  }) {
    final planned = <PlannedReminder>[];
    for (final habit in habits) {
      if (!habit.isActive ||
          !habit.notificationEnabled ||
          habit.notificationTime == null) {
        continue;
      }
      final time = _parseTime(habit.notificationTime!);
      if (time == null) continue;
      HabitSchedule schedule;
      try {
        schedule = LegacyHabitScheduleMapper.fromHabit(habit);
      } on FormatException {
        continue;
      }
      final completedDates = _completedDatesForHabit(
        completedOccurrences,
        habit.id,
      );
      for (var offset = 0; offset < horizonDays; offset++) {
        final date = start.addDays(offset);
        final progress = HabitScheduleProgress.evaluate(
          schedule: schedule,
          focusDate: date,
          completedDates: completedDates,
          isInactiveOn: (candidate) =>
              HabitScheduleProgress.isHabitInactiveOn(habit, candidate),
        );
        if (!progress.isContributionAvailableOn(date) ||
            completedDates.contains(date)) {
          continue;
        }
        planned.add(
          PlannedReminder(
            logicalKey: '${habit.id}@${date.toString()}',
            habit: habit,
            occurrence: date,
            scheduledFor: DeviceTimeZoneService.resolveWallClock(
              location: location,
              date: date,
              hour: time.$1,
              minute: time.$2,
            ),
          ),
        );
      }
    }
    planned.sort((left, right) {
      final time = left.scheduledFor.compareTo(right.scheduledFor);
      return time != 0 ? time : left.logicalKey.compareTo(right.logicalKey);
    });
    return List<PlannedReminder>.unmodifiable(planned.take(capacity));
  }

  static Set<LocalDate> _completedDatesForHabit(
    Set<String> completedOccurrences,
    String habitId,
  ) {
    final prefix = '$habitId@';
    final dates = <LocalDate>{};
    for (final occurrence in completedOccurrences) {
      if (!occurrence.startsWith(prefix)) continue;
      try {
        dates.add(LocalDate.parse(occurrence.substring(prefix.length)));
      } on FormatException {
        continue;
      }
    }
    return dates;
  }

  static (int, int)? _parseTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }
}

final class ReminderScheduler {
  const ReminderScheduler({
    required NotificationIdRegistry registry,
    required NotificationGateway gateway,
  }) : _registry = registry,
       _gateway = gateway;

  final NotificationIdRegistry _registry;
  final NotificationGateway _gateway;

  Future<void> replaceWith(Iterable<PlannedReminder> plan) async {
    final desired = {
      for (final reminder in plan) reminder.logicalKey: reminder,
    };
    final registered = await _registry.snapshot();
    for (final stale in registered.keys.where(
      (key) => !desired.containsKey(key),
    )) {
      await _gateway.cancel(registered[stale]!);
      await _registry.release(stale);
    }
    final pendingById = <int, NotificationRequest>{
      for (final request in await _gateway.pending()) request.id: request,
    };
    for (final entry in desired.entries) {
      final id = await _registry.idFor(entry.key);
      final reminder = entry.value;
      final pending = pendingById[id];
      if (pending != null &&
          pending.scheduledFor.toUtc() == reminder.scheduledFor.toUtc()) {
        continue;
      }
      if (pending != null) await _gateway.cancel(id);
      final payload = ReminderPayload(
        habitId: reminder.habit.id,
        occurrence: reminder.occurrence,
        notificationKey: reminder.logicalKey,
        kind: reminder.kind,
        reason: reminder.reason,
        snoozeDuration: reminder.snoozeDuration,
      );
      final isQuestion =
          reminder.kind == PlannedReminderKind.calibrationPulse ||
          reminder.kind == PlannedReminderKind.fineTuningQuestion;
      await _gateway.schedule(
        NotificationRequest(
          id: id,
          scheduledFor: reminder.scheduledFor,
          title: reminder.habit.name,
          body: isQuestion
              ? 'Would this habit fit right now?'
              : 'A planned opportunity is ready when you are.',
          payload: <String, String>{'schema': jsonEncode(payload.toMap())},
          category: switch (reminder.kind) {
            PlannedReminderKind.calibrationPulse =>
              NotificationCategory.calibration,
            PlannedReminderKind.fineTuningQuestion =>
              NotificationCategory.fineTuning,
            PlannedReminderKind.dailyOverview => NotificationCategory.overview,
            _ => NotificationCategory.reminder,
          },
          actions: isQuestion
              ? const <NotificationActionSpec>[
                  NotificationActionSpec(
                    id: 'feasibility_good',
                    title: 'Jetzt gut',
                  ),
                  NotificationActionSpec(
                    id: 'feasibility_maybe',
                    title: 'Vielleicht',
                  ),
                  NotificationActionSpec(
                    id: 'feasibility_bad',
                    title: 'Gerade nicht',
                  ),
                ]
              : reminder.kind == PlannedReminderKind.dailyOverview
              ? const <NotificationActionSpec>[]
              : const <NotificationActionSpec>[
                  NotificationActionSpec(id: 'complete', title: 'Erledigt'),
                  NotificationActionSpec(id: 'snooze', title: 'Später'),
                ],
        ),
      );
    }
  }
}
