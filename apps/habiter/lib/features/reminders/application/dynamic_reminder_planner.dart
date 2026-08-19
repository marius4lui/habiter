import 'dart:convert';
import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../habits/domain/habit_schedule.dart';
import '../../habits/domain/habit_schedule_progress.dart';
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
    this.baselineProfiles = const <String, AvailabilityProfile>{},
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
  final Map<String, AvailabilityProfile> baselineProfiles;
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
        baselineProfiles: input.baselineProfiles,
      );
      profiles[habit.id] = computation;
      final schedule = _scheduleFor(habit);
      if (schedule == null) continue;
      final completedDates = _completedDatesForHabit(input, habit.id);
      for (var offset = 0; offset < input.horizonDays; offset++) {
        final date = input.start.addDays(offset);
        if (!_isHabitDay(habit, schedule, date, completedDates)) continue;
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
          for (final minute in _quarterHourMinutes(config.window))
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
      for (final minute in _quarterHourMinutes(window.range)) {
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
    final result = <_Candidate>[];
    final scheduledInstants = <DateTime>{};
    for (var index = 0; index < scored.length; index++) {
      final item = scored[index];
      final relevantSignals = signals.where(
        (signal) =>
            signal.habitId == habit.id &&
            signal.feasibility != null &&
            _dayType(signal.localWeekday) == dayType &&
            item.window.range.contains(
              LocalTime.fromMinuteOfDay(signal.localMinuteOfDay),
            ),
      );
      final candidate = _smartCandidate(
        habit: habit,
        policy: policy,
        date: date,
        item: item,
        attemptIndex: index,
        input: input,
        profiles: profiles,
        positive: relevantSignals
            .where((signal) => signal.feasibility == FeasibilityRating.good)
            .length,
        negative: relevantSignals
            .where((signal) => signal.feasibility == FeasibilityRating.bad)
            .length,
      );
      if (scheduledInstants.add(candidate.reminder.scheduledFor)) {
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
    final jitteredMinute =
        (item.minute + jitter + LocalTime.minutesPerDay) %
        LocalTime.minutesPerDay;
    final jitteredTime = LocalTime.fromMinuteOfDay(jitteredMinute);
    final actualMinute =
        item.window.range.contains(jitteredTime) &&
            _allowed(jitteredTime, input.preferences)
        ? jitteredMinute
        : item.minute;
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
      final scheduledDate = LocalDate(local.year, local.month, local.day);
      if (!_allowed(time, input.preferences)) continue;
      result.add(
        _candidate(
          habit: habit,
          date: snooze.occurrence,
          scheduledDate: scheduledDate,
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
    LocalDate? scheduledDate,
  }) {
    final effectiveScheduledDate = scheduledDate ?? date;
    final scheduledFor = DeviceTimeZoneService.resolveWallClock(
      location: input.location,
      date: effectiveScheduledDate,
      hour: time.hour,
      minute: time.minute,
    );
    final logicalKey =
        '${habit.id}@${date.toString()}:${kind.name}:$attemptIndex:'
        '${effectiveScheduledDate.toString()}:${time.toString()}';
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
        snoozeDuration:
            input.policies[habit.id]?.snoozeDuration ??
            input.preferences.defaultSnooze,
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
      final local = tz.TZDateTime.from(
        candidate.reminder.scheduledFor,
        input.location,
      );
      final scheduledDate = LocalDate(local.year, local.month, local.day);
      byDate.putIfAbsent(scheduledDate, () => <_Candidate>[]).add(candidate);
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
        final policy = input.policies[reminder.habit.id];
        if (policy?.mode == ReminderMode.smart &&
            reminder.kind == PlannedReminderKind.normal) {
          final acceptedForHabit = accepted.where(
            (other) =>
                other.habit.id == reminder.habit.id &&
                other.occurrence == reminder.occurrence &&
                other.kind == PlannedReminderKind.normal,
          );
          if (acceptedForHabit.length >= policy!.intensity.maximumAttempts ||
              acceptedForHabit.any(
                (other) =>
                    other.scheduledFor.difference(reminder.scheduledFor).abs() <
                    policy.smart!.minimumAttemptSpacing,
              )) {
            continue;
          }
        }
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
      if (!reminder.scheduledFor.isBefore(session.plannedEndAt)) continue;
      if ((dailyCounts[reminder.occurrence] ?? 0) >= dailyPulseLimit) continue;
      final local = tz.TZDateTime.from(reminder.scheduledFor, input.location);
      final bucket = CalibrationBucketKey(
        localDate: reminder.occurrence,
        twoHourStartMinute: (local.hour * 60 + local.minute) ~/ 120 * 120,
        habitId: reminder.habit.id,
        timeZoneId: input.location.name,
      );
      if (session.coveredBuckets.any(
        (covered) =>
            covered.localDate == bucket.localDate &&
            covered.twoHourStartMinute == bucket.twoHourStartMinute &&
            covered.timeZoneId == bucket.timeZoneId,
      )) {
        continue;
      }
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
    final output = List<PlannedReminder>.from(reminders);
    final eligibleByWeek = <LocalDate, List<int>>{};
    for (var index = 0; index < output.length; index++) {
      final reminder = output[index];
      if (input.policies[reminder.habit.id]?.mode != ReminderMode.smart ||
          reminder.kind != PlannedReminderKind.normal ||
          !input.policies[reminder.habit.id]!.smart!.allowFineTuningQuestions) {
        continue;
      }
      final local = tz.TZDateTime.from(reminder.scheduledFor, input.location);
      final date = LocalDate(local.year, local.month, local.day);
      final week = date.addDays(1 - date.weekday);
      eligibleByWeek.putIfAbsent(week, () => <int>[]).add(index);
    }
    final quota = FineTuningQuestionPolicy.questionsPerWeek(confidence);
    for (final entry in eligibleByWeek.entries) {
      final weekStart = entry.key;
      final weekEnd = weekStart.addDays(7);
      final existing = signals.where((signal) {
        if (signal.source != SignalSource.fineTuningNotification) return false;
        final local = tz.TZDateTime.from(signal.occurredAtUtc, input.location);
        final date = LocalDate(local.year, local.month, local.day);
        return date.compareTo(weekStart) >= 0 && date.compareTo(weekEnd) < 0;
      }).length;
      var remaining = math.max(0, quota - existing);
      if (remaining == 0) continue;
      final eligible = entry.value
        ..sort((left, right) {
          final priority =
              _fineTuningPriority(
                output[right],
                profiles,
                signals,
                input,
              ).compareTo(
                _fineTuningPriority(output[left], profiles, signals, input),
              );
          return priority != 0
              ? priority
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
    }
    return output;
  }

  double _fineTuningPriority(
    PlannedReminder reminder,
    Map<String, HabitProfileComputation> profiles,
    List<ReminderSignal> signals,
    DynamicReminderPlanInput input,
  ) {
    final computation = profiles[reminder.habit.id];
    final uncertainty = 1 - _bucketConfidence(reminder, profiles);
    final local = tz.TZDateTime.from(reminder.scheduledFor, input.location);
    final dayType = _dayType(local.weekday);
    final window = (local.hour * 60 + local.minute) ~/ 120;
    final relevant = signals
        .where(
          (signal) =>
              signal.habitId == reminder.habit.id &&
              signal.feasibility != null &&
              _dayType(signal.localWeekday) == dayType &&
              signal.localMinuteOfDay ~/ 120 == window,
        )
        .map((signal) => signal.targetValue)
        .toList(growable: false);
    final contradiction = _variance(relevant);
    final samples = computation?.habitProfile.effectiveSamples ?? 0;
    final lowSampleOrNew = math.max(
      1 - math.min(1, samples / 12),
      input.now.difference(reminder.habit.createdAt).inDays < 14 ? 1 : 0,
    );
    return 0.50 * uncertainty + 0.30 * contradiction + 0.20 * lowSampleOrNew;
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
    Set<LocalDate> completedDates,
  ) {
    final progress = HabitScheduleProgress.evaluate(
      schedule: schedule,
      focusDate: date,
      completedDates: completedDates,
      isInactiveOn: (candidate) =>
          HabitScheduleProgress.isHabitInactiveOn(habit, candidate),
    );
    return progress.isContributionAvailableOn(date);
  }

  Set<LocalDate> _completedDatesForHabit(
    DynamicReminderPlanInput input,
    String habitId,
  ) {
    final prefix = '$habitId@';
    final dates = <LocalDate>{};
    for (final occurrence in input.completedOccurrences) {
      if (!occurrence.startsWith(prefix)) continue;
      try {
        dates.add(LocalDate.parse(occurrence.substring(prefix.length)));
      } on FormatException {
        continue;
      }
    }
    return dates;
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

  static Iterable<int> _quarterHourMinutes(LocalTimeRange range) sync* {
    var minute = range.start.minuteOfDay;
    while (true) {
      yield minute;
      if (minute == range.end.minuteOfDay) break;
      final next = (minute + 15) % LocalTime.minutesPerDay;
      if (!range.contains(LocalTime.fromMinuteOfDay(next))) break;
      minute = next;
    }
  }

  static ProfileDayType _dayType(int weekday) => weekday >= DateTime.saturday
      ? ProfileDayType.weekend
      : ProfileDayType.weekday;

  static double _variance(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((left, right) => left + right) / values.length;
    return values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((left, right) => left + right) /
        values.length;
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
