import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/dynamic_reminder_planner.dart';
import 'package:habiter/features/reminders/domain/calibration_session.dart';
import 'package:habiter/features/reminders/domain/local_time.dart';
import 'package:habiter/features/reminders/domain/reminder_plan.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/features/reminders/domain/reminder_preferences.dart';
import 'package:habiter/features/reminders/domain/reminder_signal.dart';
import 'package:habiter/models/habit.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);
  const planner = DynamicReminderPlanner();
  final now = DateTime.utc(2026, 8, 17, 6);
  final date = LocalDate(2026, 8, 17);

  test('fixed mode keeps every configured time on eligible habit days', () {
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: <Habit>[_habit('fixed')],
        policies: <HabitReminderPolicy>[
          HabitReminderPolicy.fixedTimes(
            habitId: 'fixed',
            times: const <LocalTime>[LocalTime(9, 0), LocalTime(18, 0)],
            now: now,
          ),
        ],
        preferences: ReminderPreferences(
          enabled: true,
          globalMinimumSpacing: const Duration(minutes: 30),
        ),
      ),
    );

    expect(result.reminders, hasLength(2));
    expect(result.reminders.map((item) => item.scheduledFor.hour), <int>[
      9,
      18,
    ]);
    expect(
      result.reminders.every(
        (item) => item.reason.code == ReminderReasonCode.fixedTime,
      ),
      isTrue,
    );
  });

  test(
    'random mode is deterministic and respects count, window and spacing',
    () {
      final policy = HabitReminderPolicy(
        habitId: 'random',
        enabled: true,
        mode: ReminderMode.randomWithinWindow,
        intensity: ReminderIntensity.persistent,
        random: RandomReminderConfig(
          window: const LocalTimeRange(
            start: LocalTime(9, 0),
            end: LocalTime(18, 0),
          ),
          timesPerHabitDay: 4,
          minimumSpacing: const Duration(hours: 2),
        ),
        createdAt: now,
        updatedAt: now,
      );
      final input = _input(
        now: now,
        date: date,
        habits: <Habit>[_habit('random')],
        policies: <HabitReminderPolicy>[policy],
        preferences: ReminderPreferences(
          enabled: true,
          globalDailyLimit: 8,
          globalMinimumSpacing: const Duration(minutes: 30),
        ),
      );
      final first = planner.plan(input).reminders;
      final second = planner.plan(input).reminders;

      expect(
        first.map((item) => item.scheduledFor),
        second.map((item) => item.scheduledFor),
      );
      expect(first, hasLength(4));
      expect(
        first.every(
          (item) => item.scheduledFor.hour >= 9 && item.scheduledFor.hour <= 18,
        ),
        isTrue,
      );
      for (var index = 1; index < first.length; index++) {
        expect(
          first[index].scheduledFor.difference(first[index - 1].scheduledFor),
          greaterThanOrEqualTo(const Duration(hours: 2)),
        );
      }
    },
  );

  test(
    'Smart uses category defaults immediately with deterministic bounded jitter',
    () {
      final policy = HabitReminderPolicy.smart(
        habitId: 'smart',
        now: now,
        intensity: ReminderIntensity.persistent,
      );
      final result = planner.plan(
        _input(
          now: now,
          date: date,
          habits: <Habit>[_habit('smart', category: 'Fitness')],
          policies: <HabitReminderPolicy>[policy],
        ),
      );

      expect(result.reminders, isNotEmpty);
      expect(result.reminders.length, lessThanOrEqualTo(3));
      expect(
        result.reminders.every(
          (item) => item.reason.code == ReminderReasonCode.categoryPreset,
        ),
        isTrue,
      );
      expect(
        DynamicReminderPlanner.deterministicJitterMinutes('smart', date),
        inInclusiveRange(-15, 15),
      );
      expect(
        DynamicReminderPlanner.deterministicJitterMinutes('smart', date),
        DynamicReminderPlanner.deterministicJitterMinutes('smart', date),
      );
    },
  );

  test('user-defined Smart windows are hard boundaries', () {
    final policy = HabitReminderPolicy.smart(
      habitId: 'smart',
      now: now,
      config: SmartReminderConfig(
        windowSource: PeakWindowSource.userDefined,
        userPeakWindows: const <LocalTimeRange>[
          LocalTimeRange(start: LocalTime(15, 0), end: LocalTime(16, 0)),
        ],
      ),
    );
    final reminders = planner
        .plan(
          _input(
            now: now,
            date: date,
            habits: <Habit>[_habit('smart')],
            policies: <HabitReminderPolicy>[policy],
          ),
        )
        .reminders;

    expect(reminders, isNotEmpty);
    expect(
      reminders.every(
        (item) =>
            item.scheduledFor.hour == 15 ||
            (item.scheduledFor.hour == 16 && item.scheduledFor.minute == 0),
      ),
      isTrue,
    );
    expect(reminders.first.reason.code, ReminderReasonCode.userDefinedWindow);
  });

  test(
    'global guardrails beat habit intensity and completion removes a day',
    () {
      final habits = <Habit>[_habit('one'), _habit('two')];
      final policies = <HabitReminderPolicy>[
        for (final habit in habits)
          HabitReminderPolicy.fixedTimes(
            habitId: habit.id,
            times: const <LocalTime>[
              LocalTime(9, 0),
              LocalTime(10, 0),
              LocalTime(11, 0),
            ],
            now: now,
          ),
      ];
      final result = planner.plan(
        _input(
          now: now,
          date: date,
          habits: habits,
          policies: policies,
          preferences: ReminderPreferences(
            enabled: true,
            globalDailyLimit: 2,
            globalMinimumSpacing: const Duration(minutes: 90),
            quietHours: const <LocalTimeRange>[
              LocalTimeRange(start: LocalTime(10, 30), end: LocalTime(12, 0)),
            ],
          ),
          completed: <String>{'one@2026-08-17'},
        ),
      );

      expect(result.reminders, hasLength(1));
      expect(result.reminders.single.habit.id, 'two');
      expect(result.reminders.single.scheduledFor.hour, 9);
    },
  );

  test('paused and archived habits never produce reminders', () {
    final paused = _habit('paused').copyWith(
      isActive: false,
      pauses: <HabitPause>[HabitPause(startedAt: DateTime.utc(2026, 8, 17))],
    );
    final archived = _habit('archived').copyWith(isActive: false);
    final policies = <HabitReminderPolicy>[
      for (final habit in <Habit>[paused, archived])
        HabitReminderPolicy.fixedTimes(
          habitId: habit.id,
          times: const <LocalTime>[LocalTime(9, 0)],
          now: now,
        ),
    ];

    expect(
      planner
          .plan(
            _input(
              now: now,
              date: date,
              habits: <Habit>[paused, archived],
              policies: policies,
            ),
          )
          .reminders,
      isEmpty,
    );
  });

  test('calibration converts at most one reminder per two-hour window', () {
    final habits = <Habit>[_habit('one'), _habit('two')];
    final session = CalibrationSession.start(id: 'calibration', now: now);
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: habits,
        policies: <HabitReminderPolicy>[
          for (final habit in habits)
            HabitReminderPolicy.smart(habitId: habit.id, now: now),
        ],
        calibration: session,
      ),
    );
    final pulses = result.reminders
        .where((item) => item.kind == PlannedReminderKind.calibrationPulse)
        .toList();
    final windows = pulses
        .map(
          (item) =>
              '${item.occurrence}:${(item.scheduledFor.hour * 60 + item.scheduledFor.minute) ~/ 120}',
        )
        .toSet();

    expect(pulses.length, windows.length);
    expect(pulses.length, lessThanOrEqualTo(7));
  });

  test('calibration pulse volume drops as distinct coverage grows', () {
    final habit = _habit('smart');
    final session = CalibrationSession(
      id: 'calibration',
      status: CalibrationStatus.active,
      startedAt: now,
      plannedEndAt: now.add(const Duration(days: 7)),
      coveredBuckets: <CalibrationBucketKey>[
        for (var index = 0; index < 20; index++)
          CalibrationBucketKey(
            localDate: date.addDays(-1 - index ~/ 7),
            twoHourStartMinute: (index % 7) * 120 + 480,
            habitId: 'previous-$index',
            timeZoneId: 'UTC',
          ),
      ],
    );
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: <Habit>[habit],
        policies: <HabitReminderPolicy>[
          HabitReminderPolicy.smart(habitId: habit.id, now: now),
        ],
        calibration: session,
      ),
    );

    expect(
      result.reminders.where(
        (item) => item.kind == PlannedReminderKind.calibrationPulse,
      ),
      hasLength(1),
    );
  });

  test(
    'completed calibration uses adaptive fine-tuning quota without extras',
    () {
      final habit = _habit('smart');
      final session = CalibrationSession(
        id: 'done',
        status: CalibrationStatus.completed,
        startedAt: now.subtract(const Duration(days: 8)),
        plannedEndAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1)),
      );
      final result = planner.plan(
        _input(
          now: now,
          date: date,
          habits: <Habit>[habit],
          policies: <HabitReminderPolicy>[
            HabitReminderPolicy.smart(habitId: habit.id, now: now),
          ],
          calibration: session,
          horizonDays: 7,
        ),
      );
      final questions = result.reminders
          .where((item) => item.kind == PlannedReminderKind.fineTuningQuestion)
          .length;

      expect(questions, lessThanOrEqualTo(6));
      expect(questions, lessThanOrEqualTo(result.reminders.length));
    },
  );

  test('calibration pulses stay inside the seven-day session', () {
    final habit = _habit('smart');
    final session = CalibrationSession(
      id: 'calibration',
      status: CalibrationStatus.active,
      startedAt: now,
      plannedEndAt: now.add(const Duration(days: 2)),
    );
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: <Habit>[habit],
        policies: <HabitReminderPolicy>[
          HabitReminderPolicy.smart(habitId: habit.id, now: now),
        ],
        calibration: session,
        horizonDays: 7,
      ),
    );

    expect(
      result.reminders
          .where((item) => item.kind == PlannedReminderKind.calibrationPulse)
          .every((item) => item.scheduledFor.isBefore(session.plannedEndAt)),
      isTrue,
    );
  });

  test('answered calibration window is covered across all habits', () {
    final habits = <Habit>[_habit('one'), _habit('two')];
    final base = planner.plan(
      _input(
        now: now,
        date: date,
        habits: habits,
        policies: <HabitReminderPolicy>[
          for (final habit in habits)
            HabitReminderPolicy.smart(habitId: habit.id, now: now),
        ],
        calibration: CalibrationSession.start(id: 'first', now: now),
      ),
    );
    final firstPulse = base.reminders.firstWhere(
      (item) => item.kind == PlannedReminderKind.calibrationPulse,
    );
    final coveredWindow =
        (firstPulse.scheduledFor.hour * 60 + firstPulse.scheduledFor.minute) ~/
        120 *
        120;
    final session = CalibrationSession(
      id: 'second',
      status: CalibrationStatus.active,
      startedAt: now,
      plannedEndAt: now.add(const Duration(days: 7)),
      coveredBuckets: <CalibrationBucketKey>[
        CalibrationBucketKey(
          localDate: date,
          twoHourStartMinute: coveredWindow,
          habitId: firstPulse.habit.id,
          timeZoneId: 'UTC',
        ),
      ],
    );
    final replanned = planner.plan(
      _input(
        now: now,
        date: date,
        habits: habits,
        policies: <HabitReminderPolicy>[
          for (final habit in habits)
            HabitReminderPolicy.smart(habitId: habit.id, now: now),
        ],
        calibration: session,
      ),
    );

    expect(
      replanned.reminders.where(
        (item) =>
            item.kind == PlannedReminderKind.calibrationPulse &&
            (item.scheduledFor.hour * 60 + item.scheduledFor.minute) ~/
                    120 *
                    120 ==
                coveredWindow,
      ),
      isEmpty,
    );
  });

  test('fine-tuning quota is applied independently to each week', () {
    final habit = _habit('smart');
    final session = CalibrationSession(
      id: 'done',
      status: CalibrationStatus.completed,
      startedAt: now.subtract(const Duration(days: 8)),
      plannedEndAt: now.subtract(const Duration(days: 1)),
      completedAt: now.subtract(const Duration(days: 1)),
    );
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: <Habit>[habit],
        policies: <HabitReminderPolicy>[
          HabitReminderPolicy.smart(habitId: habit.id, now: now),
        ],
        calibration: session,
        horizonDays: 14,
      ),
    );

    expect(
      result.reminders.where(
        (item) => item.kind == PlannedReminderKind.fineTuningQuestion,
      ),
      hasLength(12),
    );
  });

  test('global conflicts fall back to the next Smart candidate', () {
    final habits = <Habit>[_habit('one'), _habit('two')];
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: habits,
        policies: <HabitReminderPolicy>[
          for (final habit in habits)
            HabitReminderPolicy.smart(
              habitId: habit.id,
              now: now,
              intensity: ReminderIntensity.gentle,
              config: SmartReminderConfig(
                windowSource: PeakWindowSource.userDefined,
                userPeakWindows: const <LocalTimeRange>[
                  LocalTimeRange(start: LocalTime(9, 0), end: LocalTime(13, 0)),
                ],
              ),
            ),
        ],
        preferences: ReminderPreferences(
          enabled: true,
          globalMinimumSpacing: const Duration(minutes: 90),
        ),
      ),
    );

    expect(result.reminders.map((item) => item.habit.id).toSet(), {
      'one',
      'two',
    });
  });

  test('daily limits use the actual scheduled calendar day', () {
    final habits = <Habit>[_habit('snoozed'), _habit('fixed')];
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: habits,
        policies: <HabitReminderPolicy>[
          HabitReminderPolicy.fixedTimes(
            habitId: 'snoozed',
            times: const <LocalTime>[LocalTime(12, 0)],
            now: now,
          ),
          HabitReminderPolicy.fixedTimes(
            habitId: 'fixed',
            times: const <LocalTime>[LocalTime(0, 30)],
            now: now,
          ),
        ],
        preferences: ReminderPreferences(
          enabled: true,
          activeDayStart: const LocalTime(0, 0),
          activeDayEnd: const LocalTime(23, 59),
          globalDailyLimit: 1,
          globalMinimumSpacing: const Duration(minutes: 30),
        ),
        pendingSnoozes: <PendingReminderSnooze>[
          PendingReminderSnooze(
            id: 'snooze',
            habitId: 'snoozed',
            occurrence: date,
            scheduledFor: DateTime.utc(2026, 8, 18),
            createdAt: now,
          ),
        ],
        horizonDays: 2,
      ),
    );
    final onTuesday = result.reminders.where(
      (item) => LocalDate.fromDateTime(item.scheduledFor) == date.addDays(1),
    );

    expect(onTuesday, hasLength(1));
    expect(onTuesday.single.kind, PlannedReminderKind.snooze);
  });

  test('capacity is a chronological cross-platform limit of 64', () {
    final policy = HabitReminderPolicy.fixedTimes(
      habitId: 'fixed',
      times: const <LocalTime>[LocalTime(9, 0)],
      now: now,
    );
    final result = planner.plan(
      _input(
        now: now,
        date: date,
        habits: <Habit>[_habit('fixed')],
        policies: <HabitReminderPolicy>[policy],
        horizonDays: 90,
      ),
    );

    expect(result.reminders, hasLength(64));
    expect(result.reminders.first.occurrence, date);
    expect(result.reminders.last.occurrence, date.addDays(63));
  });
}

DynamicReminderPlanInput _input({
  required DateTime now,
  required LocalDate date,
  required List<Habit> habits,
  required List<HabitReminderPolicy> policies,
  ReminderPreferences? preferences,
  CalibrationSession? calibration,
  Set<String> completed = const <String>{},
  List<PendingReminderSnooze> pendingSnoozes = const <PendingReminderSnooze>[],
  int horizonDays = 1,
}) => DynamicReminderPlanInput(
  habits: habits,
  policies: <String, HabitReminderPolicy>{
    for (final policy in policies) policy.habitId: policy,
  },
  preferences: preferences ?? ReminderPreferences(enabled: true),
  signals: const <ReminderSignal>[],
  calibration: calibration,
  completedOccurrences: completed,
  pendingSnoozes: pendingSnoozes,
  start: date,
  now: now,
  location: tz.UTC,
  horizonDays: horizonDays,
);

Habit _habit(String id, {String category = 'Health'}) => Habit(
  id: id,
  name: id,
  color: '#000000',
  icon: 'H',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: category,
  createdAt: DateTime.utc(2026, 8, 1),
  isActive: true,
);
