import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/models/schedule_education_model.dart';
import 'package:habiter/models/habit.dart';

void main() {
  group('ScheduleEducationMapper', () {
    test('maps daily to an every-day Monday-first presentation', () {
      final model = _ready(_map(HabitFrequency.daily));

      expect(model.kind, ScheduleEducationKind.daily);
      expect(model.weeklyTarget, 7);
      expect(model.eligibleWeekdays, <int>{1, 2, 3, 4, 5, 6, 7});
      expect(model.weekdaysInDisplayOrder, <int>[1, 2, 3, 4, 5, 6, 7]);
      expect(model.weekStartsOnMonday, isTrue);
      expect(model.progressSeed, 0);
    });

    test('keeps flexible weekly days open instead of inventing weekdays', () {
      final model = _ready(_map(HabitFrequency.weekly, targetCount: 3));

      expect(model.kind, ScheduleEducationKind.flexibleWeekly);
      expect(model.weeklyTarget, 3);
      expect(model.eligibleWeekdays, <int>{1, 2, 3, 4, 5, 6, 7});
    });

    test('maps fixed weekdays without changing their eligibility', () {
      final model = _ready(
        _map(HabitFrequency.custom, customDays: <int>[7, 2, 4]),
      );

      expect(model.kind, ScheduleEducationKind.fixedWeekdays);
      expect(model.weeklyTarget, 3);
      expect(model.eligibleWeekdays, <int>{2, 4, 7});
      expect(model.weekdaysInDisplayOrder, <int>[1, 2, 3, 4, 5, 6, 7]);
    });

    test('returns typed failures for malformed drafts without fake days', () {
      expect(
        _map(HabitFrequency.weekly, targetCount: 0),
        isA<ScheduleEducationInvalid>().having(
          (value) => value.issue,
          'issue',
          ScheduleEducationIssue.invalidWeeklyTarget,
        ),
      );
      expect(
        _map(HabitFrequency.custom),
        isA<ScheduleEducationInvalid>().having(
          (value) => value.issue,
          'issue',
          ScheduleEducationIssue.missingFixedWeekdays,
        ),
      );
      expect(
        _map(HabitFrequency.custom, customDays: <int>[1, 8]),
        isA<ScheduleEducationInvalid>().having(
          (value) => value.issue,
          'issue',
          ScheduleEducationIssue.invalidFixedWeekday,
        ),
      );
    });

    test('exposes immutable weekday collections', () {
      final model = _ready(
        _map(HabitFrequency.custom, customDays: <int>[1, 3]),
      );

      expect(() => model.eligibleWeekdays.add(5), throwsUnsupportedError);
      expect(() => model.weekdaysInDisplayOrder.add(8), throwsUnsupportedError);
    });
  });
}

ScheduleEducationResult _map(
  HabitFrequency frequency, {
  int targetCount = 1,
  List<int> customDays = const <int>[],
}) => ScheduleEducationMapper.fromDraft(
  OnboardingHabitDraft(
    name: 'Read',
    category: 'Learning',
    icon: '📚',
    color: '#7B61A8',
    frequency: frequency,
    targetCount: targetCount,
    customDays: customDays,
  ),
);

ScheduleEducationModel _ready(ScheduleEducationResult result) =>
    (result as ScheduleEducationReady).model;
