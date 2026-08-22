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
  test(
    'controller preserves the complete ten-step lifecycle contract',
    () async {
      final repository = KeyValueOnboardingRepository(InMemoryKeyValueStore());
      final controller = OnboardingController(
        repository: repository,
        ids: FakeIdGenerator(const <String>['habit-1', 'unused']),
        clock: FakeClock(DateTime.utc(2026, 8, 20)),
      );
      addTearDown(controller.dispose);
      final visited = <OnboardingStep>[];

      await controller.initialize(hasExistingHabits: false);
      visited.add(controller.state.currentStep);
      await controller.start();
      visited.add(controller.state.currentStep);
      await controller.selectIntent(OnboardingIntent.health);
      visited.add(controller.state.currentStep);
      final draft = OnboardingHabitDraft(
        name: 'Walk',
        category: 'Health',
        icon: 'W',
        color: '#467B68',
        frequency: HabitFrequency.weekly,
        targetCount: 3,
      );
      await controller.selectHabit(draft);
      visited.add(controller.state.currentStep);
      await controller.configureRhythm(draft);
      visited.add(controller.state.currentStep);
      await controller.confirmRhythmUnderstanding();
      visited.add(controller.state.currentStep);
      await controller.confirmReminderModel();
      visited.add(controller.state.currentStep);
      await controller.configureReminder(
        draft.copyWith(reminderEnabled: true, reminderTime: '18:30'),
      );
      final firstId = await controller.reserveFirstHabitId();
      expect(await controller.reserveFirstHabitId(), firstId);
      await controller.markHabitReady(backgroundSetupRequired: true);
      visited.add(controller.state.currentStep);
      await controller.completeBackgroundSetup();
      visited.add(controller.state.currentStep);
      await controller.beginWidgetPin();
      visited.add(controller.state.currentStep);

      expect(visited, OnboardingProgress.orderedSteps);
      expect(
        controller.state.onboardingVersion,
        OnboardingState.currentVersion,
      );
      expect(controller.state.habitDraft?.frequency, HabitFrequency.weekly);
      expect(controller.state.habitDraft?.reminderEnabled, isTrue);
      expect(controller.state.habitDraft?.reminderTime, '18:30');
      expect(controller.state.firstHabitId, 'habit-1');

      await controller.recordWidgetPinAttempt();
      await controller.finishWithoutPin();
      final restarted = OnboardingController(
        repository: repository,
        ids: FakeIdGenerator(const <String>['unused']),
        clock: FakeClock(DateTime.utc(2026, 8, 21)),
      );
      addTearDown(restarted.dispose);
      await restarted.initialize(hasExistingHabits: false);

      expect(restarted.state.currentStep, OnboardingStep.completed);
      expect(restarted.state.widgetPinAttempted, isTrue);
      expect(restarted.state.widgetPinned, isFalse);
      expect(restarted.state.firstHabitId, firstId);
    },
  );

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

    expect(restarted.state.currentStep, OnboardingStep.rhythmExplainer);
    expect(restarted.state.intent, OnboardingIntent.learning);
    expect(restarted.state.habitDraft?.name, 'Read');
    expect(restarted.state.habitDraft?.customDays, <int>[1, 3, 5]);

    await restarted.confirmRhythmUnderstanding();
    expect(restarted.state.currentStep, OnboardingStep.reminderModel);
    await restarted.confirmReminderModel();
    expect(restarted.state.currentStep, OnboardingStep.reminder);
    await restarted.back();
    expect(restarted.state.currentStep, OnboardingStep.reminderModel);
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
    'optional reminder and widget deferral complete without side effects',
    () async {
      final repository = KeyValueOnboardingRepository(InMemoryKeyValueStore());
      final completionTime = DateTime.utc(2026, 8, 20, 18, 30);
      final controller = OnboardingController(
        repository: repository,
        ids: FakeIdGenerator(const <String>['habit-optional']),
        clock: FakeClock(completionTime),
      );
      addTearDown(controller.dispose);

      await controller.initialize(hasExistingHabits: false);
      await controller.start();
      await controller.selectIntent(OnboardingIntent.mindfulness);
      final draft = OnboardingHabitDraft(
        name: 'Pause',
        category: 'Mindfulness',
        icon: 'P',
        color: '#DFA79B',
        frequency: HabitFrequency.daily,
        targetCount: 1,
      );
      await controller.selectHabit(draft);
      await controller.configureRhythm(draft);
      await controller.confirmRhythmUnderstanding();
      await controller.confirmReminderModel();
      await controller.configureReminder(draft);
      await controller.reserveFirstHabitId();
      await controller.markHabitReady();

      expect(controller.state.habitDraft?.reminderEnabled, isFalse);
      expect(controller.state.habitDraft?.reminderTime, isNull);
      expect(controller.state.completedAt, isNull);

      await controller.deferWidget();
      final restarted = OnboardingController(
        repository: repository,
        ids: FakeIdGenerator(const <String>['unused']),
        clock: FakeClock(completionTime.add(const Duration(days: 1))),
      );
      addTearDown(restarted.dispose);
      await restarted.initialize(hasExistingHabits: false);

      expect(restarted.state.currentStep, OnboardingStep.completed);
      expect(restarted.state.firstHabitId, 'habit-optional');
      expect(
        restarted.state.widgetPromotionState,
        WidgetPromotionState.deferred,
      );
      expect(restarted.state.widgetPinAttempted, isFalse);
      expect(restarted.state.widgetPinned, isFalse);
      expect(restarted.state.completedAt, completionTime);
    },
  );

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

  test('existing user widget promotion dismissal survives restart', () async {
    final repository = KeyValueOnboardingRepository(InMemoryKeyValueStore());
    final first = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['unused']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    await first.initialize(hasExistingHabits: true);
    expect(first.state.currentStep, OnboardingStep.completed);
    expect(first.state.widgetPromotionState, WidgetPromotionState.pending);

    await first.dismissWidgetPromotion();
    final restarted = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['unused-2']),
      clock: FakeClock(DateTime.utc(2026, 8, 17)),
    );
    await restarted.initialize(hasExistingHabits: true);

    expect(
      restarted.state.widgetPromotionState,
      WidgetPromotionState.dismissed,
    );
    expect(restarted.shouldShowOnboarding, isFalse);
  });
}
