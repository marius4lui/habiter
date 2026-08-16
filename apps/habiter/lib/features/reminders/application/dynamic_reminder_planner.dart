import 'dart:convert';
import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule.dart';
import '../domain/availability_profile.dart';
import '../domain/calibration_session.dart';
import '../domain/local_time.dart';
import '../domain/reminder_plan.dart';
import '../domain/reminder_policy.dart';
import '../domain/reminder_preferences.dart';
import '../domain/reminder_signal.dart';
import '../infrastructure/device_time_zone_service.dart';
import 'availability_profile_engine.dart';
import 'reminder_scheduler.dart';

final class DynamicReminderPlanInput {
  const DynamicReminderPlanInput({
    required this.habits,
    required this.policies,
    required this.preferences,
    required this.signals,
    required this.start,
    required this.now,
    required this.location,
    this.calibration,
    this.completedOccurrences = const <String>{},
    this.pendingSnoozes = const <PendingReminderSnooze>[],
    this.horizonDays = 14,
    this.capacity = 64,
  });

  final Iterable<Habit> habits;
  final Map<String, HabitReminderPolicy> policies;
  final ReminderPreferences preferences;
  final Iterable<ReminderSignal> signals;
  final CalibrationSession? calibration;
  final Set<String> completedOccurrences;
  final Iterable<PendingReminderSnooze> pendingSnoozes;
  final LocalDate start;
  final DateTime now;
  final tz.Location location;
  final int horizonDays;
  final int capacity;
}

final class DynamicReminderPlanResult {
  const DynamicReminderPlanResult({
    required this.reminders,
    required this.profilesByHabit,
  });

  final List<PlannedReminder> reminders;
  final Map<String, HabitProfileComputation> profilesByHabit;
}

final class DynamicReminderPlanner {
  const DynamicReminderPlanner({
    AvailabilityProfileEngine profileEngine = const AvailabilityProfileEngine(),
  }) : _profileEngine = profileEngine;

  static const algorithmVersion = AvailabilityProfileEngine.algorithmVersion;
  final AvailabilityProfileEngine _profileEngine;

  DynamicReminderPlanResult plan(DynamicReminderPlanInput input) {
    if (!input.preferences.enabled || input.capacity <= 0) {
      return const DynamicReminderPlanResult(
        reminders: <PlannedReminder>[],
        profilesByHabit: <String, HabitProfileComputation>{},
      );
    }
    final signals = input.signals.toList(growable: false);
    final calibrationActive = _calibrationIsActive(input);
    final profiles = <String, HabitProfileComputation>{};
    final candidates = <_Candidate>[];
    for (final habit in input.habits) {
      final policy = input.policies[habit.id];
      if (policy == null || !policy.enabled || !habit.isActive) continue;
      final computation = _profileEngine.computeForHabit(
        habit: habit,
        allSignals: signals,
        now: input.now,
        preferences: input.preferences,
        calibrationActive: calibrationActive,
      );
      profiles[habit.id] = computation;
      final schedule = _scheduleFor(habit);
      if (schedule == null) continue;
      final weeklyCounts = <LocalDate, int>{};
      for (var offset = 0; offset < input.horizonDays; offset++) {
        final date = input.start.addDays(offset);
        if (!_isHabitDay(habit, schedule, date, weeklyCounts)) continue;
        if (input.completedOccurrences.contains(
          '${habit.id}@${date.toString()}',
        )) {
          continue;
        }
        candidates.addAll(
          _habitDayCandidates(
            habit: habit,
            policy: policy,
            date: date,
            profiles: computation,
            input: input,
            signals: signals,
            calibrationActive: calibrationActive,
          ),
        );
      }
    }
    candidates.addAll(_overviewCandidates(input));
    candidates.addAll(_snoozeCandidates(input));
    var selected = _applyGlobalGuardrails(candidates, input);
    selected = _decorateQuestions(
      selected,
      input: input,
      profiles: profiles,
      signals: signals,
      calibrationActive: calibrationActive,
    );
    selected.sort((left, right) {
      final time = left.scheduledFor.compareTo(right.scheduledFor);
      return time != 0 ? time : left.logicalKey.compareTo(right.logicalKey);
    });
    return DynamicReminderPlanResult(
      reminders: List<PlannedReminder>.unmodifiable(
        selected.take(input.capacity),
      ),
      profilesByHabit: Map<String, HabitProfileComputation>.unmodifiable(
        profiles,
      ),
    );
  }

  List<_Candidate> _habitDayCandidates({
    required Habit habit,
    required HabitReminderPolicy policy,
    required LocalDate date,
    required HabitProfileComputation profiles,
    required DynamicReminderPlanInput input,
    required List<ReminderSignal> signals,
    required bool calibrationActive,
  }) => switch (policy.mode) {
    ReminderMode.fixedTimes => _fixedCandidates(habit, policy, date, input),
    ReminderMode.randomWithinWindow => _randomCandidates(
      habit,
      policy,
      date,
      input,
    ),
    ReminderMode.smart => _smartCandidates(
      habit,
      policy,
      date,
      profiles,
      input,
      signals,
      calibrationActive,
    ),
  };

  List<_Candidate> _fixedCandidates(
    Habit habit,
    HabitReminderPolicy policy,
    LocalDate date,
    DynamicReminderPlanInput input,
  ) => <_Candidate>[
    for (var index = 0; index < policy.fixed!.times.length; index++)
      if (_allowed(policy.fixed!.times[index], input.preferences))
        _candidate(
          habit: habit,
          date: date,
          time: policy.fixed!.times[index],
          attemptIndex: index,
          utility: 2,
          reason: const ReminderReason(code: ReminderReasonCode.fixedTime),
          input: input,
        ),
  ];

  List<_Candidate> _randomCandidates(
    Habit habit,
    HabitReminderPolicy policy,
    LocalDate date,
    DynamicReminderPlanInput input,
  ) {
    final config = policy.random!;
    final slots =
        <int>[
          for (
            var minute = config.window.start.minuteOfDay;
            minute <= config.window.end.minuteOfDay;
            minute += 15
          )
            if (_allowed(LocalTime.fromMinuteOfDay(minute), input.preferences))
              minute,
        ]..sort(
          (left, right) =>
              _stableHash(
                '${habit.id}|$date|$algorithmVersion|$left',
              ).compareTo(
                _stableHash('${habit.id}|$date|$algorithmVersion|$right'),
              ),
        );
    final selected = _selectSpacedSlots(
      slots,
      count: config.timesPerHabitDay,
      minimumSpacingMinutes: config.minimumSpacing.inMinutes,
    );
    selected.sort();
    return <_Candidate>[
      for (var index = 0; index < selected.length; index++)
        _candidate(
          habit: habit,
          date: date,
          time: LocalTime.fromMinuteOfDay(selected[index]),
          attemptIndex: index,
          utility: 1.8,
          reason: ReminderReason(
            code: ReminderReasonCode.deterministicRandom,
            window: config.window,
          ),
          input: input,
        ),
    ];
  }

  List<_Candidate> _smartCandidates(
    Habit habit,
    HabitReminderPolicy policy,
    LocalDate date,
    HabitProfileComputation profiles,
    DynamicReminderPlanInput input,
    List<ReminderSignal> signals,
    bool calibrationActive,
  ) {
    final dayType = date.weekday >= DateTime.saturday
        ? ProfileDayType.weekend
        : ProfileDayType.weekday;
    final windows = PeakWindowDetector.detect(
      profiles: profiles,
      dayType: dayType,
      config: policy.smart!,
      preferences: input.preferences,
    );
    final scored = <_SmartCandidate>[];
    for (final window in windows) {
      for (
        var minute = window.range.start.minuteOfDay;
        minute <= window.range.end.minuteOfDay;
        minute += 15
      ) {
        final time = LocalTime.fromMinuteOfDay(minute);
        if (!_allowed(time, input.preferences)) continue;
        final bucket = profiles.habitProfile.bucketFor(date.weekday, minute);
        if (bucket == null) continue;
        final exploration = 1 - bucket.confidence;
        final availabilityShare = calibrationActive ? 0.55 : 0.62;
        final explorationShare = calibrationActive ? 0.10 : 0.03;
        const spacingQuality = 1.0;
        final utility =
            availabilityShare * bucket.explicitAvailability +
            0.25 * bucket.completionLikelihood +
            0.10 * spacingQuality +
            explorationShare * exploration;
        scored.add(
          _SmartCandidate(
            minute: minute,
            window: window,
            utility: utility,
            factors: <String, double>{
              'availability': bucket.explicitAvailability,
              'completion': bucket.completionLikelihood,
              'spacing': spacingQuality,
              'exploration': exploration,
              'confidence': bucket.confidence,
            },
          ),
        );
      }
    }
    scored.sort((left, right) {
      final utility = right.utility.compareTo(left.utility);
      return utility != 0 ? utility : left.minute.compareTo(right.minute);
    });
    final selected = <_SmartCandidate>[];
    for (final item in scored) {
      if (selected.every(
        (other) =>
            (other.minute - item.minute).abs() >=
            policy.smart!.minimumAttemptSpacing.inMinutes,
      )) {
        selected.add(item);
      }
      if (selected.length == policy.intensity.maximumAttempts) break;
    }
    final positive = signals
        .where(
          (signal) =>
              signal.habitId == habit.id &&
              signal.source.isExplicit &&
              signal.targetValue >= 0.5,
        )
        .length;
    final negative = signals
        .where(
          (signal) =>
              signal.habitId == habit.id &&
              signal.source.isExplicit &&
              signal.targetValue == 0,
        )
        .length;
    final result = <_Candidate>[];
    for (var index = 0; index < selected.length; index++) {
      final candidate = _smartCandidate(
        habit: habit,
        policy: policy,
        date: date,
        item: selected[index],
        attemptIndex: index,
        input: input,
        profiles: profiles,
        positive: positive,
        negative: negative,
      );
      if (result.every(
        (other) =>
            other.reminder.scheduledFor
                .difference(candidate.reminder.scheduledFor)
                .abs() >=
            policy.smart!.minimumAttemptSpacing,
      )) {
        result.add(candidate);
      }
    }
    return result;
  }

  _Candidate _smartCandidate({
    required Habit habit,
    required HabitReminderPolicy policy,
    required LocalDate date,
    required _SmartCandidate item,
    required int attemptIndex,
    required DynamicReminderPlanInput input,
    required HabitProfileComputation profiles,
    required int positive,
    required int negative,
  }) {
    final jitter = deterministicJitterMinutes(habit.id, date);
    var actualMinute = (item.minute + jitter).clamp(
      item.window.range.start.minuteOfDay,
      item.window.range.end.minuteOfDay,
    );
    while (actualMinute != item.minute &&
        !_allowed(LocalTime.fromMinuteOfDay(actualMinute), input.preferences)) {
      actualMinute += actualMinute > item.minute ? -1 : 1;
    }
    final origin = item.window.origin;
    final code = switch (origin) {
      PeakWindowOrigin.habitLearned => ReminderReasonCode.habitLearnedPeak,
      PeakWindowOrigin.globalLearned => ReminderReasonCode.globalLearnedPeak,
      PeakWindowOrigin.categoryPreset => ReminderReasonCode.categoryPreset,
      PeakWindowOrigin.userDefined => ReminderReasonCode.userDefinedWindow,
      PeakWindowOrigin.generalDefault => ReminderReasonCode.generalDefault,
    };
    final sourceProfileId = switch (origin) {
      PeakWindowOrigin.habitLearned => profiles.habitProfile.profileId,
      PeakWindowOrigin.globalLearned => profiles.globalUserProfile.profileId,
      PeakWindowOrigin.categoryPreset => profiles.categoryProfile.profileId,
      _ => null,
    };
    return _candidate(
      habit: habit,
      date: date,
      time: LocalTime.fromMinuteOfDay(actualMinute),
      attemptIndex: attemptIndex,
      utility: item.utility,
      reason: ReminderReason(
        code: code,
        sourceProfileId: sourceProfileId,
        window: item.window.range,
        positiveExplicitSignals: positive,
        negativeExplicitSignals: negative,
        factors: item.factors,
      ),
      input: input,
    );
  }

  List<_Candidate> _overviewCandidates(DynamicReminderPlanInput input) {
    final overview = input.preferences.dailyOverview;
    if (!overview.enabled || !_allowed(overview.time, input.preferences)) {
      return const <_Candidate>[];
    }
    final syntheticHabit = Habit(
      id: '_daily_overview',
      name: 'Habiter',
      color: '#000000',
      icon: 'H',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      category: 'Overview',
      createdAt: input.now,
      isActive: true,
    );
    return <_Candidate>[
      for (var offset = 0; offset < input.horizonDays; offset++)
        _candidate(
          habit: syntheticHabit,
          date: input.start.addDays(offset),
          time: overview.time,
          attemptIndex: 0,
          utility: 1.9,
          kind: PlannedReminderKind.dailyOverview,
          reason: const ReminderReason(code: ReminderReasonCode.dailyOverview),
          input: input,
        ),
    ];
  }

  List<_Candidate> _snoozeCandidates(DynamicReminderPlanInput input) {
    final habits = <String, Habit>{
      for (final habit in input.habits) habit.id: habit,
    };
    final result = <_Candidate>[];
    for (final snooze in input.pendingSnoozes) {
      final habit = habits[snooze.habitId];
      final policy = input.policies[snooze.habitId];
      if (habit == null ||
          policy == null ||
          !habit.isActive ||
          !policy.enabled ||
          habit.isPausedOn(snooze.occurrence.toString()) ||
          input.completedOccurrences.contains(
            '${habit.id}@${snooze.occurrence.toString()}',
          )) {
        continue;
      }
      final local = tz.TZDateTime.from(snooze.scheduledFor, input.location);
      final time = LocalTime(local.hour, local.minute);
      if (!_allowed(time, input.preferences)) continue;
      result.add(
        _candidate(
          habit: habit,
          date: snooze.occurrence,
          time: time,
          attemptIndex: 0,
          utility: 3,
          kind: PlannedReminderKind.snooze,
          reason: const ReminderReason(code: ReminderReasonCode.snoozedByUser),
          input: input,
        ),
      );
    }
    return result;
  }

  _Candidate _candidate({
    required Habit habit,
    required LocalDate date,
    required LocalTime time,
    required int attemptIndex,
    required double utility,
    required ReminderReason reason,
    required DynamicReminderPlanInput input,
    PlannedReminderKind kind = PlannedReminderKind.normal,
  }) {
    final scheduledFor = DeviceTimeZoneService.resolveWallClock(
      location: input.location,
      date: date,
      hour: time.hour,
      minute: time.minute,
    );
    final logicalKey =
        '${habit.id}@${date.toString()}:${kind.name}:$attemptIndex:${time.toString()}';
    return _Candidate(
      PlannedReminder(
        logicalKey: logicalKey,
        habit: habit,
        occurrence: date,
        scheduledFor: scheduledFor,
        kind: kind,
        attemptIndex: attemptIndex,
        utility: utility,
        reason: reason,
      ),
    );
  }

  List<PlannedReminder> _applyGlobalGuardrails(
    List<_Candidate> candidates,
    DynamicReminderPlanInput input,
  ) {
    final future = candidates
        .where(
          (candidate) => candidate.reminder.scheduledFor.isAfter(input.now),
        )
        .toList();
    final byDate = <LocalDate, List<_Candidate>>{};
    for (final candidate in future) {
      byDate
          .putIfAbsent(candidate.reminder.occurrence, () => <_Candidate>[])
          .add(candidate);
    }
    final selected = <PlannedReminder>[];
    for (final day in byDate.values) {
      day.sort((left, right) {
        final utility = right.reminder.utility.compareTo(left.reminder.utility);
        if (utility != 0) return utility;
        final time = left.reminder.scheduledFor.compareTo(
          right.reminder.scheduledFor,
        );
        return time != 0
            ? time
            : left.reminder.logicalKey.compareTo(right.reminder.logicalKey);
      });
      final accepted = <PlannedReminder>[];
      for (final candidate in day) {
        if (accepted.length >= input.preferences.globalDailyLimit) break;
        final reminder = candidate.reminder;
        if (accepted.any(
          (other) =>
              other.scheduledFor.difference(reminder.scheduledFor).abs() <
              input.preferences.globalMinimumSpacing,
        )) {
          continue;
        }
        accepted.add(reminder);
      }
      selected.addAll(accepted);
    }
    return selected;
  }

  List<PlannedReminder> _decorateQuestions(
    List<PlannedReminder> reminders, {
    required DynamicReminderPlanInput input,
    required Map<String, HabitProfileComputation> profiles,
    required List<ReminderSignal> signals,
    required bool calibrationActive,
  }) {
    if (calibrationActive) {
      return _decorateCalibration(reminders, input: input, profiles: profiles);
    }
    if (!input.preferences.ongoingLearningEnabled ||
        input.calibration?.status != CalibrationStatus.completed) {
      return reminders;
    }
    return _decorateFineTuning(
      reminders,
      input: input,
      profiles: profiles,
      signals: signals,
    );
  }

  List<PlannedReminder> _decorateCalibration(
    List<PlannedReminder> reminders, {
    required DynamicReminderPlanInput input,
    required Map<String, HabitProfileComputation> profiles,
  }) {
    final session = input.calibration!;
    final output = List<PlannedReminder>.from(reminders);
    final byWindow = <String, List<int>>{};
    for (var index = 0; index < output.length; index++) {
      final reminder = output[index];
      final policy = input.policies[reminder.habit.id];
      if (policy?.mode != ReminderMode.smart ||
          reminder.kind != PlannedReminderKind.normal) {
        continue;
      }
      final local = tz.TZDateTime.from(reminder.scheduledFor, input.location);
      final window = (local.hour * 60 + local.minute) ~/ 120 * 120;
      final key = '${reminder.occurrence}:$window';
      byWindow.putIfAbsent(key, () => <int>[]).add(index);
    }
    final dailyCounts = <LocalDate, int>{};
    final distinctCoveredWindows = session.coveredBuckets
        .map(
          (bucket) =>
              '${bucket.localDate}:${bucket.twoHourStartMinute}:${bucket.timeZoneId}',
        )
        .toSet()
        .length;
    final dailyPulseLimit = switch (distinctCoveredWindows) {
      < 6 => 7,
      < 12 => 5,
      < 20 => 3,
      _ => 1,
    };
    for (final indices in byWindow.values) {
      indices.sort((left, right) {
        final a = output[left];
        final b = output[right];
        return _calibrationPriority(
          b,
          profiles,
        ).compareTo(_calibrationPriority(a, profiles));
      });
      final index = indices.first;
      final reminder = output[index];
      if ((dailyCounts[reminder.occurrence] ?? 0) >= dailyPulseLimit) continue;
      final local = tz.TZDateTime.from(reminder.scheduledFor, input.location);
      final bucket = CalibrationBucketKey(
        localDate: reminder.occurrence,
        twoHourStartMinute: (local.hour * 60 + local.minute) ~/ 120 * 120,
        habitId: reminder.habit.id,
        timeZoneId: input.location.name,
      );
      if (session.coveredBuckets.contains(bucket)) continue;
      output[index] = reminder.copyWith(
        logicalKey: '${reminder.logicalKey}:calibration',
        kind: PlannedReminderKind.calibrationPulse,
        utility: reminder.utility + 0.2,
        reason: reminder.reason.copyWith(
          code: ReminderReasonCode.calibrationUncertainty,
        ),
      );
      dailyCounts[reminder.occurrence] =
          (dailyCounts[reminder.occurrence] ?? 0) + 1;
    }
    return output;
  }

  List<PlannedReminder> _decorateFineTuning(
    List<PlannedReminder> reminders, {
    required DynamicReminderPlanInput input,
    required Map<String, HabitProfileComputation> profiles,
    required List<ReminderSignal> signals,
  }) {
    if (profiles.isEmpty) return reminders;
    final confidence =
        profiles.values.fold<double>(
          0,
          (sum, item) => sum + item.habitProfile.confidence,
        ) /
        profiles.length;
    final quota = FineTuningQuestionPolicy.questionsPerWeek(confidence);
    final weekStart = input.start.addDays(1 - input.start.weekday);
    final existing = signals
        .where(
          (signal) =>
              signal.source == SignalSource.fineTuningNotification &&
              !signal.occurredAtUtc.isBefore(
                DateTime.utc(weekStart.year, weekStart.month, weekStart.day),
              ),
        )
        .length;
    var remaining = math.max(0, quota - existing);
    if (remaining == 0) return reminders;
    final output = List<PlannedReminder>.from(reminders);
    final eligible =
        <int>[
          for (var index = 0; index < output.length; index++)
            if (input.policies[output[index].habit.id]?.mode ==
                    ReminderMode.smart &&
                output[index].kind == PlannedReminderKind.normal &&
                input
                    .policies[output[index].habit.id]!
                    .smart!
                    .allowFineTuningQuestions)
              index,
        ]..sort((left, right) {
          final leftConfidence = _bucketConfidence(output[left], profiles);
          final rightConfidence = _bucketConfidence(output[right], profiles);
          final confidenceOrder = leftConfidence.compareTo(rightConfidence);
          return confidenceOrder != 0
              ? confidenceOrder
              : output[left].scheduledFor.compareTo(output[right].scheduledFor);
        });
    final usedWindows = <String>{};
    for (final index in eligible) {
      if (remaining == 0) break;
      final reminder = output[index];
      final local = tz.TZDateTime.from(reminder.scheduledFor, input.location);
      final key =
          '${reminder.habit.id}:${reminder.occurrence}:${(local.hour * 60 + local.minute) ~/ 120}';
      if (!usedWindows.add(key)) continue;
      output[index] = reminder.copyWith(
        logicalKey: '${reminder.logicalKey}:fine-tuning',
        kind: PlannedReminderKind.fineTuningQuestion,
        reason: reminder.reason.copyWith(
          code: ReminderReasonCode.fineTuningUncertainty,
        ),
      );
      remaining--;
    }
    return output;
  }

  double _calibrationPriority(
    PlannedReminder reminder,
    Map<String, HabitProfileComputation> profiles,
  ) {
    final confidence = _bucketConfidence(reminder, profiles);
    final availability = reminder.reason.factors['availability'] ?? 0.5;
    return 0.50 * (1 - confidence) + 0.30 + 0.20 * availability;
  }

  double _bucketConfidence(
    PlannedReminder reminder,
    Map<String, HabitProfileComputation> profiles,
  ) =>
      profiles[reminder.habit.id]?.habitProfile
          .bucketFor(
            reminder.occurrence.weekday,
            reminder.scheduledFor.hour * 60 + reminder.scheduledFor.minute,
          )
          ?.confidence ??
      0;

  bool _calibrationIsActive(DynamicReminderPlanInput input) {
    final calibration = input.calibration;
    return input.preferences.calibrationEnabled &&
        calibration?.status == CalibrationStatus.active &&
        input.now.isBefore(calibration!.plannedEndAt);
  }

  bool _isHabitDay(
    Habit habit,
    HabitSchedule schedule,
    LocalDate date,
    Map<LocalDate, int> weeklyCounts,
  ) {
    if (habit.isPausedOn(date.toString())) return false;
    if (schedule is TimesPerWeekSchedule) {
      final week = date.addDays(1 - date.weekday);
      final count = weeklyCounts[week] ?? 0;
      if (count >= schedule.target) return false;
      weeklyCounts[week] = count + 1;
      return true;
    }
    return schedule.isAvailableOn(date);
  }

  HabitSchedule? _scheduleFor(Habit habit) {
    try {
      return LegacyHabitScheduleMapper.fromHabit(habit);
    } on FormatException {
      return null;
    }
  }

  bool _allowed(LocalTime time, ReminderPreferences preferences) =>
      preferences.allows(time);

  List<int> _selectSpacedSlots(
    List<int> rankedSlots, {
    required int count,
    required int minimumSpacingMinutes,
  }) {
    final selected = <int>[];

    bool search(int startIndex) {
      if (selected.length == count) return true;
      for (var index = startIndex; index < rankedSlots.length; index++) {
        final minute = rankedSlots[index];
        if (!selected.every(
          (other) => (other - minute).abs() >= minimumSpacingMinutes,
        )) {
          continue;
        }
        selected.add(minute);
        if (search(index + 1)) return true;
        selected.removeLast();
      }
      return false;
    }

    search(0);
    return selected;
  }

  static int deterministicJitterMinutes(String habitId, LocalDate date) =>
      _stableHash('$habitId|$date|$algorithmVersion|jitter') % 31 - 15;

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

final class _Candidate {
  const _Candidate(this.reminder);
  final PlannedReminder reminder;
}

final class _SmartCandidate {
  const _SmartCandidate({
    required this.minute,
    required this.window,
    required this.utility,
    required this.factors,
  });

  final int minute;
  final PeakWindow window;
  final double utility;
  final Map<String, double> factors;
}
