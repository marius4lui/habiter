import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/reminders/application/availability_profile_engine.dart';
import 'package:habiter/features/reminders/domain/availability_profile.dart';
import 'package:habiter/features/reminders/domain/local_time.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/features/reminders/domain/reminder_preferences.dart';
import 'package:habiter/features/reminders/domain/reminder_signal.dart';
import 'package:habiter/models/habit.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final habit = _habit(category: 'Fitness');
  const engine = AvailabilityProfileEngine();

  test('decay has an exact 42 day half-life', () {
    final recent = _signal('recent', now: now, minute: 600);
    final old = _signal(
      'old',
      now: now.subtract(const Duration(days: 42)),
      minute: 600,
    );

    expect(
      AvailabilityProfileEngine.decayWeight(recent, now),
      closeTo(1, 1e-9),
    );
    expect(AvailabilityProfileEngine.decayWeight(old, now), closeTo(0.5, 1e-9));
  });

  test('spatial smoothing uses 1.0, 0.5 and 0.2 for bucket neighbors', () {
    final signal = _signal('signal', now: now, minute: 615);
    double weight(int minute) =>
        AvailabilityProfileEngine.effectiveWeightForBucket(
          signal,
          ProfileBucketKey(
            dayType: ProfileDayType.weekday,
            minuteOfDay: minute,
          ),
          now,
        );

    expect(weight(600), 1);
    expect(weight(570), 0.5);
    expect(weight(540), 0.2);
    expect(weight(510), 0);
  });

  test(
    'hierarchical backoff starts from category and becomes habit specific',
    () {
      final empty = engine.computeForHabit(
        habit: habit,
        allSignals: const <ReminderSignal>[],
        now: now,
      );
      final categoryEvening = empty.categoryProfile.bucketFor(1, 18 * 60)!;
      final habitEvening = empty.habitProfile.bucketFor(1, 18 * 60)!;
      expect(
        habitEvening.explicitAvailability,
        closeTo(categoryEvening.explicitAvailability, 1e-12),
      );
      expect(empty.habitProfile.confidence, 0);

      final signals = <ReminderSignal>[
        for (var index = 0; index < 8; index++)
          _signal(
            'habit-$index',
            now: now.subtract(Duration(days: index)),
            minute: 8 * 60,
            rating: FeasibilityRating.good,
          ),
      ];
      final learned = engine.computeForHabit(
        habit: habit,
        allSignals: signals,
        now: now,
      );
      expect(
        learned.habitProfile.bucketFor(1, 8 * 60)!.explicitAvailability,
        greaterThan(
          empty.habitProfile.bucketFor(1, 8 * 60)!.explicitAvailability,
        ),
      );
      expect(learned.habitProfile.effectiveSamples, greaterThan(0));
    },
  );

  test('calibration makes explicit feasibility the dominant score', () {
    final signals = <ReminderSignal>[
      _signal('bad', now: now, minute: 600, rating: FeasibilityRating.bad),
      _signal(
        'done',
        now: now,
        minute: 600,
        source: SignalSource.notificationCompletion,
      ),
    ];
    final regular = engine.computeForHabit(
      habit: habit,
      allSignals: signals,
      now: now,
    );
    final calibration = engine.computeForHabit(
      habit: habit,
      allSignals: signals,
      now: now,
      calibrationActive: true,
    );

    expect(
      calibration.habitProfile.bucketFor(1, 600)!.combinedScore,
      lessThan(regular.habitProfile.bucketFor(1, 600)!.combinedScore),
    );
  });

  test(
    'conflicting explicit answers reduce confidence versus stable answers',
    () {
      List<ReminderSignal> answers(Iterable<FeasibilityRating> ratings) =>
          ratings.indexed
              .map(
                (item) => _signal(
                  'answer-${item.$1}',
                  now: now.subtract(Duration(days: item.$1)),
                  minute: 600,
                  rating: item.$2,
                ),
              )
              .toList();
      final stable = engine.computeForHabit(
        habit: habit,
        allSignals: answers(
          List<FeasibilityRating>.filled(12, FeasibilityRating.good),
        ),
        now: now,
      );
      final conflicting = engine.computeForHabit(
        habit: habit,
        allSignals: answers(<FeasibilityRating>[
          for (var index = 0; index < 12; index++)
            index.isEven ? FeasibilityRating.good : FeasibilityRating.bad,
        ]),
        now: now,
      );

      expect(
        stable.habitProfile.confidence,
        greaterThan(conflicting.habitProfile.confidence),
      );
    },
  );

  test('peak detection uses category fallback and hard user windows', () {
    final profiles = engine.computeForHabit(
      habit: habit,
      allSignals: const <ReminderSignal>[],
      now: now,
    );
    final preset = PeakWindowDetector.detect(
      profiles: profiles,
      dayType: ProfileDayType.weekday,
      config: SmartReminderConfig(),
      preferences: ReminderPreferences(),
    );
    expect(preset, isNotEmpty);
    expect(preset.first.origin, PeakWindowOrigin.categoryPreset);

    final custom = PeakWindowDetector.detect(
      profiles: profiles,
      dayType: ProfileDayType.weekday,
      config: SmartReminderConfig(
        windowSource: PeakWindowSource.userDefined,
        userPeakWindows: const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(15, 0), end: LocalTime(16, 0)),
        ],
      ),
      preferences: ReminderPreferences(),
    );
    expect(custom.single.origin, PeakWindowOrigin.userDefined);
    expect(custom.single.range.start, const LocalTime(15, 0));
  });

  test('fine tuning questions adapt exactly from six down to three', () {
    expect(FineTuningQuestionPolicy.questionsPerWeek(0.44), 6);
    expect(FineTuningQuestionPolicy.questionsPerWeek(0.45), 5);
    expect(FineTuningQuestionPolicy.questionsPerWeek(0.60), 4);
    expect(FineTuningQuestionPolicy.questionsPerWeek(0.75), 3);
  });
}

Habit _habit({required String category}) => Habit(
  id: 'habit',
  name: 'Training',
  color: '#000000',
  icon: 'T',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: category,
  createdAt: DateTime.utc(2026, 8, 1),
  isActive: true,
);

ReminderSignal _signal(
  String id, {
  required DateTime now,
  required int minute,
  FeasibilityRating rating = FeasibilityRating.good,
  SignalSource source = SignalSource.calibrationNotification,
}) => ReminderSignal(
  id: id,
  habitId: 'habit',
  source: source,
  occurredAtUtc: now,
  timeZoneId: 'UTC',
  localWeekday: DateTime.monday,
  localMinuteOfDay: minute,
  feasibility: source.isExplicit ? rating : null,
  createdAt: now,
);
