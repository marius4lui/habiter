import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/domain/availability_profile.dart';
import 'package:habiter/features/reminders/domain/calibration_session.dart';
import 'package:habiter/features/reminders/domain/local_time.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/features/reminders/domain/reminder_preferences.dart';
import 'package:habiter/features/reminders/domain/reminder_signal.dart';

void main() {
  test('local times and overnight ranges are deterministic', () {
    expect(LocalTime.parse('08:05').minuteOfDay, 485);
    expect(
      const LocalTimeRange(
        start: LocalTime(22, 0),
        end: LocalTime(6, 0),
      ).contains(const LocalTime(1, 30)),
      isTrue,
    );
    expect(() => LocalTime.parse('25:00'), throwsFormatException);
  });

  test('all reminder policy modes roundtrip with strict mode configs', () {
    final now = DateTime.utc(2026, 8, 16);
    final policies = <HabitReminderPolicy>[
      HabitReminderPolicy.smart(habitId: 'smart', now: now),
      HabitReminderPolicy(
        habitId: 'random',
        enabled: true,
        mode: ReminderMode.randomWithinWindow,
        intensity: ReminderIntensity.balanced,
        random: RandomReminderConfig(
          window: const LocalTimeRange(
            start: LocalTime(9, 0),
            end: LocalTime(17, 0),
          ),
          timesPerHabitDay: 2,
        ),
        createdAt: now,
        updatedAt: now,
      ),
      HabitReminderPolicy.fixedTimes(
        habitId: 'fixed',
        times: const <LocalTime>[LocalTime(18, 0), LocalTime(8, 0)],
        now: now,
      ),
    ];

    for (final policy in policies) {
      final restored = HabitReminderPolicy.fromMap(policy.toMap());
      expect(restored.mode, policy.mode);
      expect(restored.habitId, policy.habitId);
      expect(restored.toMap(), policy.toMap());
    }
    expect(policies.last.fixed!.times.first, const LocalTime(8, 0));
  });

  test('unknown policy fields survive a known-schema roundtrip', () {
    final policy = HabitReminderPolicy.fromMap(<String, Object?>{
      ...HabitReminderPolicy.smart(
        habitId: 'habit',
        now: DateTime.utc(2026),
      ).toMap(),
      'futureSetting': <String, Object?>{'enabled': true},
    });

    expect(policy.toMap()['futureSetting'], <String, Object?>{'enabled': true});
  });

  test('preferences enforce active hours and explicit quiet hours', () {
    final preferences = ReminderPreferences(
      enabled: true,
      quietHours: const <LocalTimeRange>[
        LocalTimeRange(start: LocalTime(12, 0), end: LocalTime(13, 0)),
      ],
    );

    expect(preferences.allows(const LocalTime(7, 59)), isFalse);
    expect(preferences.allows(const LocalTime(12, 30)), isFalse);
    expect(preferences.allows(const LocalTime(18, 0)), isTrue);
    expect(
      ReminderPreferences.fromMap(preferences.toMap()).toMap(),
      preferences.toMap(),
    );
  });

  test(
    'calibration coverage identity includes date, window, habit and zone',
    () {
      final first = CalibrationBucketKey(
        localDate: LocalDate(2026, 8, 16),
        twoHourStartMinute: 480,
        habitId: 'habit',
        timeZoneId: 'Europe/Berlin',
      );
      final otherHabit = CalibrationBucketKey(
        localDate: LocalDate(2026, 8, 16),
        twoHourStartMinute: 480,
        habitId: 'other',
        timeZoneId: 'Europe/Berlin',
      );
      final session = CalibrationSession.start(
        id: 'session',
        now: DateTime.utc(2026, 8, 16),
      ).copyWith(coveredBuckets: <CalibrationBucketKey>{first, otherHabit});

      expect(session.coveredBuckets, hasLength(2));
      expect(CalibrationSession.fromMap(session.toMap()).coveredBuckets, {
        first,
        otherHabit,
      });
    },
  );

  test('signal targets keep explicit and indirect data separate', () {
    final explicit = ReminderSignal(
      id: 'bad',
      habitId: 'habit',
      source: SignalSource.calibrationNotification,
      occurredAtUtc: DateTime.utc(2026, 8, 16, 8),
      timeZoneId: 'UTC',
      localWeekday: DateTime.sunday,
      localMinuteOfDay: 480,
      feasibility: FeasibilityRating.bad,
      createdAt: DateTime.utc(2026, 8, 16, 8),
    );
    final completion = ReminderSignal(
      id: 'done',
      habitId: 'habit',
      source: SignalSource.habitCompletion,
      occurredAtUtc: DateTime.utc(2026, 8, 16, 9),
      timeZoneId: 'UTC',
      localWeekday: DateTime.sunday,
      localMinuteOfDay: 540,
      createdAt: DateTime.utc(2026, 8, 16, 9),
    );

    expect(explicit.targetValue, 0);
    expect(explicit.source.baseWeight, 1);
    expect(completion.targetValue, 1);
    expect(completion.source.baseWeight, 0.35);
    expect(completion.withReminderAttribution('reminder').sourceWeight, 0.65);
  });

  test('availability profiles roundtrip and expose confidence labels', () {
    const key = ProfileBucketKey(
      dayType: ProfileDayType.weekday,
      minuteOfDay: 480,
    );
    final profile = AvailabilityProfile(
      profileId: 'habit:one',
      habitId: 'one',
      buckets: <ProfileBucketKey, ProfileBucket>{
        key: const ProfileBucket(
          explicitAvailability: 0.8,
          completionLikelihood: 0.5,
          combinedScore: 0.71,
          confidence: 0.7,
          effectiveWeight: 4,
        ),
      },
      confidence: 0.7,
      effectiveSamples: 8,
      computedAt: DateTime.utc(2026, 8, 16),
      algorithmVersion: 1,
    );

    final restored = AvailabilityProfile.fromMap(profile.toMap());
    expect(restored.buckets[key]!.combinedScore, 0.71);
    expect(
      ProfileConfidenceLabel.fromScore(0.44),
      ProfileConfidenceLabel.learning,
    );
    expect(
      ProfileConfidenceLabel.fromScore(0.8),
      ProfileConfidenceLabel.stable,
    );
  });
}
