import 'dart:math' as math;

import '../../../models/habit.dart';
import '../domain/availability_profile.dart';
import '../domain/local_time.dart';
import '../domain/reminder_policy.dart';
import '../domain/reminder_preferences.dart';
import '../domain/reminder_signal.dart';

final class HabitProfileComputation {
  const HabitProfileComputation({
    required this.categoryProfile,
    required this.globalUserProfile,
    required this.habitProfile,
  });

  final AvailabilityProfile categoryProfile;
  final AvailabilityProfile globalUserProfile;
  final AvailabilityProfile habitProfile;
}

abstract final class CategoryAvailabilityPresets {
  static AvailabilityProfile profileFor({
    required String category,
    required DateTime computedAt,
    int algorithmVersion = AvailabilityProfileEngine.algorithmVersion,
  }) {
    final windows = _windowsFor(category);
    final buckets = <ProfileBucketKey, ProfileBucket>{};
    for (final dayType in ProfileDayType.values) {
      for (var minute = 0; minute < LocalTime.minutesPerDay; minute += 30) {
        final time = LocalTime.fromMinuteOfDay(minute);
        final inPeak = windows.any((window) => window.contains(time));
        buckets[ProfileBucketKey(
          dayType: dayType,
          minuteOfDay: minute,
        )] = ProfileBucket(
          explicitAvailability: inPeak ? 0.72 : 0.42,
          completionLikelihood: inPeak ? 0.58 : 0.38,
          combinedScore: inPeak ? 0.678 : 0.408,
          confidence: inPeak ? 0.72 : 0.6,
          effectiveWeight: 0,
        );
      }
    }
    return AvailabilityProfile(
      profileId: 'category:${_normalize(category)}',
      category: category,
      buckets: buckets,
      confidence: 0.65,
      effectiveSamples: 0,
      computedAt: computedAt,
      algorithmVersion: algorithmVersion,
    );
  }

  static List<LocalTimeRange> _windowsFor(String category) =>
      switch (_normalize(category)) {
        'fitness' => const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(7, 0), end: LocalTime(9, 0)),
          LocalTimeRange(start: LocalTime(17, 0), end: LocalTime(20, 0)),
        ],
        'mindfulness' => const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(7, 0), end: LocalTime(9, 0)),
          LocalTimeRange(start: LocalTime(20, 0), end: LocalTime(22, 0)),
        ],
        'learning' || 'productivity' || 'finance' => const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
          LocalTimeRange(start: LocalTime(14, 0), end: LocalTime(18, 0)),
        ],
        'health' => const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(8, 0), end: LocalTime(10, 0)),
          LocalTimeRange(start: LocalTime(18, 0), end: LocalTime(21, 0)),
        ],
        'home' => const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
          LocalTimeRange(start: LocalTime(17, 0), end: LocalTime(20, 0)),
        ],
        _ => const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(9, 0), end: LocalTime(11, 0)),
          LocalTimeRange(start: LocalTime(17, 0), end: LocalTime(20, 0)),
        ],
      };

  static String _normalize(String value) => value.trim().toLowerCase();
}

final class AvailabilityProfileEngine {
  const AvailabilityProfileEngine();

  static const algorithmVersion = 1;
  static const halfLife = Duration(days: 42);
  static const explicitPriorStrength = 3.0;
  static const habitPriorStrength = 4.0;

  HabitProfileComputation computeForHabit({
    required Habit habit,
    required Iterable<ReminderSignal> allSignals,
    required DateTime now,
    ReminderPreferences? preferences,
    bool calibrationActive = false,
    Map<String, AvailabilityProfile> baselineProfiles =
        const <String, AvailabilityProfile>{},
  }) {
    final effectivePreferences = preferences ?? ReminderPreferences();
    final signals = allSignals
        .where((signal) => !signal.occurredAtUtc.isAfter(now.toUtc()))
        .toList(growable: false);
    final category = CategoryAvailabilityPresets.profileFor(
      category: habit.category,
      computedAt: now,
    );
    final computedGlobal = _computeLayer(
      profileId: 'global:${habit.category.toLowerCase()}',
      category: habit.category,
      signals: signals,
      prior: category,
      priorStrength: explicitPriorStrength,
      now: now,
      preferences: effectivePreferences,
      calibrationActive: calibrationActive,
    );
    final globalBaseline = baselineProfiles[computedGlobal.profileId];
    final global = signals.isEmpty && _isCompatible(globalBaseline)
        ? globalBaseline!
        : computedGlobal;
    final habitSignals = signals
        .where((signal) => signal.habitId == habit.id)
        .toList(growable: false);
    final computedHabit = _computeLayer(
      profileId: 'habit:${habit.id}',
      habitId: habit.id,
      category: habit.category,
      signals: habitSignals,
      prior: global,
      priorStrength: habitPriorStrength,
      now: now,
      preferences: effectivePreferences,
      calibrationActive: calibrationActive,
    );
    final habitBaseline = baselineProfiles[computedHabit.profileId];
    final habitProfile = habitSignals.isEmpty && _isCompatible(habitBaseline)
        ? habitBaseline!
        : computedHabit;
    return HabitProfileComputation(
      categoryProfile: category,
      globalUserProfile: global,
      habitProfile: habitProfile,
    );
  }

  static bool _isCompatible(AvailabilityProfile? profile) =>
      profile != null && profile.algorithmVersion == algorithmVersion;

  AvailabilityProfile _computeLayer({
    required String profileId,
    String? habitId,
    String? category,
    required List<ReminderSignal> signals,
    required AvailabilityProfile prior,
    required double priorStrength,
    required DateTime now,
    required ReminderPreferences preferences,
    required bool calibrationActive,
  }) {
    final buckets = <ProfileBucketKey, ProfileBucket>{};
    for (final entry in prior.buckets.entries) {
      final explicit = _weightedValue(
        signals: signals.where((signal) => signal.source.isExplicit),
        key: entry.key,
        now: now,
        prior: entry.value.explicitAvailability,
        priorStrength: priorStrength,
      );
      final completion = _weightedValue(
        signals: signals.where((signal) => !signal.source.isExplicit),
        key: entry.key,
        now: now,
        prior: entry.value.completionLikelihood,
        priorStrength: priorStrength,
      );
      final actualWeight = explicit.actualWeight + completion.actualWeight;
      final localConsistency = _consistency(<_WeightedTarget>[
        ...explicit.targets,
        ...completion.targets,
      ]);
      final localConfidence = actualWeight == 0
          ? 0.0
          : (0.7 * math.min(1, actualWeight / 4) + 0.3 * localConsistency)
                .clamp(0.0, 1.0);
      final explicitShare = calibrationActive ? 0.85 : 0.70;
      buckets[entry.key] = ProfileBucket(
        explicitAvailability: explicit.value,
        completionLikelihood: completion.value,
        combinedScore:
            explicitShare * explicit.value +
            (1 - explicitShare) * completion.value,
        confidence: localConfidence,
        effectiveWeight: actualWeight,
      );
    }

    final baseWeights = signals
        .map((signal) => signal.sourceWeight * decayWeight(signal, now))
        .toList(growable: false);
    final effectiveWeight = baseWeights.fold<double>(
      0,
      (sum, item) => sum + item,
    );
    final effectiveSamples = effectiveWeight.round();
    final eligibleWindowsPerDay =
        ((preferences.activeDayEnd.minuteOfDay -
                    preferences.activeDayStart.minuteOfDay) /
                120)
            .ceil();
    final eligibleWindows = math.max(1, eligibleWindowsPerDay * 2);
    final covered = signals
        .map(
          (signal) =>
              '${_dayType(signal.localWeekday).name}:${signal.localMinuteOfDay ~/ 120}',
        )
        .toSet()
        .length;
    final sampleConfidence = math.min(1.0, effectiveSamples / 12);
    final coverageConfidence = math.min(1.0, covered / eligibleWindows);
    final responseConsistency = _consistency([
      for (var index = 0; index < signals.length; index++)
        _WeightedTarget(signals[index].targetValue, baseWeights[index]),
    ]);
    final confidence = signals.isEmpty
        ? 0.0
        : (0.50 * sampleConfidence +
                  0.30 * coverageConfidence +
                  0.20 * responseConsistency)
              .clamp(0.0, 1.0);
    return AvailabilityProfile(
      profileId: profileId,
      habitId: habitId,
      category: category,
      buckets: buckets,
      confidence: confidence,
      effectiveSamples: effectiveSamples,
      computedAt: now,
      algorithmVersion: algorithmVersion,
    );
  }

  static double decayWeight(ReminderSignal signal, DateTime now) {
    final ageDays = math.max(
      0,
      now.toUtc().difference(signal.occurredAtUtc.toUtc()).inSeconds /
          Duration.secondsPerDay,
    );
    return math.pow(0.5, ageDays / halfLife.inDays).toDouble();
  }

  static double spatialFactor(ReminderSignal signal, ProfileBucketKey key) {
    if (_dayType(signal.localWeekday) != key.dayType) return 0;
    final signalBucket = (signal.localMinuteOfDay ~/ 30) * 30;
    return switch ((signalBucket - key.minuteOfDay).abs() ~/ 30) {
      0 => 1,
      1 => 0.5,
      2 => 0.2,
      _ => 0,
    };
  }

  static double effectiveWeightForBucket(
    ReminderSignal signal,
    ProfileBucketKey key,
    DateTime now,
  ) =>
      signal.sourceWeight *
      decayWeight(signal, now) *
      spatialFactor(signal, key);

  static _WeightedValue _weightedValue({
    required Iterable<ReminderSignal> signals,
    required ProfileBucketKey key,
    required DateTime now,
    required double prior,
    required double priorStrength,
  }) {
    var weightedSum = prior * priorStrength;
    var totalWeight = priorStrength;
    var actualWeight = 0.0;
    final targets = <_WeightedTarget>[];
    for (final signal in signals) {
      final weight = effectiveWeightForBucket(signal, key, now);
      if (weight == 0) continue;
      weightedSum += signal.targetValue * weight;
      totalWeight += weight;
      actualWeight += weight;
      targets.add(_WeightedTarget(signal.targetValue, weight));
    }
    return _WeightedValue(
      value: weightedSum / totalWeight,
      actualWeight: actualWeight,
      targets: targets,
    );
  }

  static double _consistency(List<_WeightedTarget> values) {
    final totalWeight = values.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    if (totalWeight == 0) return 0;
    final mean =
        values.fold<double>(0, (sum, item) => sum + item.value * item.weight) /
        totalWeight;
    final variance =
        values.fold<double>(
          0,
          (sum, item) => sum + math.pow(item.value - mean, 2) * item.weight,
        ) /
        totalWeight;
    return (1 - variance).clamp(0.0, 1.0);
  }

  static ProfileDayType _dayType(int weekday) => weekday >= DateTime.saturday
      ? ProfileDayType.weekend
      : ProfileDayType.weekday;
}

final class _WeightedValue {
  const _WeightedValue({
    required this.value,
    required this.actualWeight,
    required this.targets,
  });

  final double value;
  final double actualWeight;
  final List<_WeightedTarget> targets;
}

final class _WeightedTarget {
  const _WeightedTarget(this.value, this.weight);

  final double value;
  final double weight;
}

enum PeakWindowOrigin {
  habitLearned,
  globalLearned,
  categoryPreset,
  userDefined,
  generalDefault,
}

final class PeakWindow {
  const PeakWindow({
    required this.range,
    required this.origin,
    required this.score,
    required this.confidence,
  });

  final LocalTimeRange range;
  final PeakWindowOrigin origin;
  final double score;
  final double confidence;
}

abstract final class PeakWindowDetector {
  static const minimumScore = 0.65;
  static const minimumConfidence = 0.45;

  static List<PeakWindow> detect({
    required HabitProfileComputation profiles,
    required ProfileDayType dayType,
    required SmartReminderConfig config,
    required ReminderPreferences preferences,
  }) {
    if (config.windowSource == PeakWindowSource.userDefined) {
      return List<PeakWindow>.unmodifiable(
        config.userPeakWindows.map(
          (range) => PeakWindow(
            range: range,
            origin: PeakWindowOrigin.userDefined,
            score: 1,
            confidence: 1,
          ),
        ),
      );
    }
    for (final candidate in <(AvailabilityProfile, PeakWindowOrigin)>[
      (profiles.habitProfile, PeakWindowOrigin.habitLearned),
      (profiles.globalUserProfile, PeakWindowOrigin.globalLearned),
      (profiles.categoryProfile, PeakWindowOrigin.categoryPreset),
    ]) {
      final windows = _qualifying(
        profile: candidate.$1,
        dayType: dayType,
        origin: candidate.$2,
        preferences: preferences,
      );
      if (windows.isNotEmpty) return windows;
    }
    return <PeakWindow>[
      PeakWindow(
        range: LocalTimeRange(
          start: preferences.activeDayStart,
          end: preferences.activeDayEnd,
        ),
        origin: PeakWindowOrigin.generalDefault,
        score: 0.5,
        confidence: 0,
      ),
    ];
  }

  static List<PeakWindow> _qualifying({
    required AvailabilityProfile profile,
    required ProfileDayType dayType,
    required PeakWindowOrigin origin,
    required ReminderPreferences preferences,
  }) {
    final entries =
        profile.buckets.entries
            .where(
              (entry) =>
                  entry.key.dayType == dayType &&
                  entry.value.combinedScore >= minimumScore &&
                  entry.value.confidence >= minimumConfidence &&
                  preferences.allows(
                    LocalTime.fromMinuteOfDay(entry.key.minuteOfDay),
                  ),
            )
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key));
    final groups = <List<MapEntry<ProfileBucketKey, ProfileBucket>>>[];
    for (final entry in entries) {
      if (groups.isEmpty ||
          entry.key.minuteOfDay - groups.last.last.key.minuteOfDay != 30) {
        groups.add(<MapEntry<ProfileBucketKey, ProfileBucket>>[entry]);
      } else {
        groups.last.add(entry);
      }
    }
    final windows =
        groups.where((group) => group.length >= 2).map((group) {
          final score =
              group.fold<double>(
                0,
                (sum, item) => sum + item.value.combinedScore,
              ) /
              group.length;
          final confidence =
              group.fold<double>(
                0,
                (sum, item) => sum + item.value.confidence,
              ) /
              group.length;
          return PeakWindow(
            range: LocalTimeRange(
              start: LocalTime.fromMinuteOfDay(group.first.key.minuteOfDay),
              end: LocalTime.fromMinuteOfDay(
                math.min(1439, group.last.key.minuteOfDay + 30),
              ),
            ),
            origin: origin,
            score: score,
            confidence: confidence,
          );
        }).toList()..sort((left, right) {
          final score = right.score.compareTo(left.score);
          return score != 0
              ? score
              : left.range.start.compareTo(right.range.start);
        });
    return List<PeakWindow>.unmodifiable(windows.take(2));
  }
}

abstract final class FineTuningQuestionPolicy {
  static int questionsPerWeek(double confidence) => switch (confidence) {
    < 0.45 => 6,
    < 0.60 => 5,
    < 0.75 => 4,
    _ => 3,
  };
}
