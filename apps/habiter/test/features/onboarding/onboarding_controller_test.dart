import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/habits/application/habits_controller.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('process restart resumes the exact persisted step and draft', () async {
    final repository = KeyValueOnboardingRepository(InMemoryKeyValueStore());
    final first = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    await first.initialize(hasExistingHabits: false);
    await first.start();
    await first.selectIntent(OnboardingIntent.learning);
    await first.selectHabit(
      OnboardingHabitDraft(
        name: 'Read',
        category: 'Learning',
        icon: '📚',
        color: '#7B61A8',
        frequency: HabitFrequency.daily,
        targetCount: 1,
      ),
    );
    await first.configureRhythm(
      first.state.habitDraft!.copyWith(
        frequency: HabitFrequency.custom,
        customDays: const <int>[1, 3, 5],
      ),
    );

    final restarted = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['unused']),
      clock: FakeClock(DateTime.utc(2026, 8, 17)),
    );
    await restarted.initialize(hasExistingHabits: false);

    expect(restarted.state.currentStep, OnboardingStep.reminder);
    expect(restarted.state.intent, OnboardingIntent.learning);
    expect(restarted.state.habitDraft?.name, 'Read');
    expect(restarted.state.habitDraft?.customDays, <int>[1, 3, 5]);
  });

  test('back navigation keeps the draft and reserved id is stable', () async {
    final repository = KeyValueOnboardingRepository(InMemoryKeyValueStore());
    final controller = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['habit-1', 'habit-2']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    await controller.initialize(hasExistingHabits: false);
    await controller.start();
    await controller.selectIntent(OnboardingIntent.health);
    await controller.selectHabit(
      OnboardingHabitDraft(
        name: 'Water',
        category: 'Health',
        icon: '💧',
        color: '#3E7CB1',
        frequency: HabitFrequency.daily,
        targetCount: 1,
      ),
    );
    final firstId = await controller.reserveFirstHabitId();
    await controller.back();
    final secondId = await controller.reserveFirstHabitId();

    expect(firstId, 'habit-1');
    expect(secondId, firstId);
    expect(controller.state.habitDraft?.name, 'Water');
    expect(controller.state.currentStep, OnboardingStep.firstHabit);
  });

  test(
    'replaying first-habit creation with its reserved id is idempotent',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      final habits = HabitsController(
        repository: repository,
        ids: FakeIdGenerator(const <String>['unused']),
        clock: FakeClock(DateTime.utc(2026, 8, 16)),
      );

      for (var attempt = 0; attempt < 2; attempt++) {
        await habits.add(
          id: 'reserved-first-habit',
          name: 'Read',
          category: 'Learning',
          frequency: HabitFrequency.daily,
          targetCount: 1,
          color: '#7B61A8',
          icon: '📚',
        );
      }

      final snapshot = await repository.load();
      expect(snapshot.habits, hasLength(1));
      expect(snapshot.habits.single.id, 'reserved-first-habit');
      habits.dispose();
    },
  );
}
