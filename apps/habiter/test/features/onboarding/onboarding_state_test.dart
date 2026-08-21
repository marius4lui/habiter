import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('v4 progress owns the complete ten-step product order', () {
    expect(OnboardingState.currentVersion, 4);
    expect(OnboardingProgress.total, 10);
    expect(OnboardingProgress.orderedSteps, <OnboardingStep>[
      OnboardingStep.welcome,
      OnboardingStep.intent,
      OnboardingStep.firstHabit,
      OnboardingStep.rhythm,
      OnboardingStep.rhythmExplainer,
      OnboardingStep.reminderModel,
      OnboardingStep.reminder,
      OnboardingStep.backgroundRuntime,
      OnboardingStep.widgetIntro,
      OnboardingStep.widgetPin,
    ]);
    expect(OnboardingProgress.indexOf(OnboardingStep.reminderModel), 6);
    expect(
      OnboardingProgress.previousOf(OnboardingStep.reminderModel),
      OnboardingStep.rhythmExplainer,
    );
  });

  test('every persisted step exposes deterministic history and progress', () {
    for (
      var index = 0;
      index < OnboardingProgress.orderedSteps.length;
      index++
    ) {
      final step = OnboardingProgress.orderedSteps[index];

      expect(OnboardingProgress.indexOf(step), index + 1, reason: step.name);
      expect(
        OnboardingProgress.through(step),
        OnboardingProgress.orderedSteps.take(index + 1),
        reason: step.name,
      );
      expect(
        OnboardingProgress.previousOf(step),
        index == 0 ? step : OnboardingProgress.orderedSteps[index - 1],
        reason: step.name,
      );
    }

    expect(
      OnboardingProgress.indexOf(OnboardingStep.habitReady),
      OnboardingProgress.indexOf(OnboardingStep.widgetIntro),
    );
    expect(
      OnboardingProgress.previousOf(OnboardingStep.completed),
      OnboardingStep.widgetPin,
    );
  });

  test('v2 incomplete steps migrate explicitly without losing the draft', () {
    const expected = <String, OnboardingStep>{
      'welcome': OnboardingStep.welcome,
      'intent': OnboardingStep.intent,
      'firstHabit': OnboardingStep.firstHabit,
      'rhythm': OnboardingStep.rhythm,
      'reminder': OnboardingStep.rhythmExplainer,
      'habitReady': OnboardingStep.widgetIntro,
      'widgetIntro': OnboardingStep.widgetIntro,
      'widgetPin': OnboardingStep.widgetPin,
      'completed': OnboardingStep.completed,
    };

    for (final entry in expected.entries) {
      final migrated = OnboardingState.fromMap(<String, Object?>{
        'onboardingVersion': 2,
        'currentStep': entry.key,
        'habitDraft': <String, Object?>{
          'name': 'Read',
          'category': 'Learning',
          'icon': '📚',
          'color': '#7B61A8',
          'frequency': 'weekly',
          'targetCount': 3,
          'customDays': <int>[],
        },
      });

      expect(migrated.onboardingVersion, 4, reason: entry.key);
      expect(migrated.currentStep, entry.value, reason: entry.key);
      expect(migrated.habitDraft?.name, 'Read', reason: entry.key);
      expect(migrated.habitDraft?.targetCount, 3, reason: entry.key);
    }
  });

  test('repository persists a loaded v2 state as v4', () async {
    final store = InMemoryKeyValueStore();
    await store.write(
      KeyValueOnboardingRepository.storageKey,
      jsonEncode(<String, Object?>{
        'onboardingVersion': 2,
        'currentStep': 'reminder',
      }),
    );
    final repository = KeyValueOnboardingRepository(store);

    final restored = await repository.load();
    final persisted =
        jsonDecode(
              await store.read(KeyValueOnboardingRepository.storageKey)
                  as String,
            )
            as Map<String, dynamic>;

    expect(restored?.currentStep, OnboardingStep.rhythmExplainer);
    expect(persisted['onboardingVersion'], 4);
    expect(persisted['currentStep'], 'rhythmExplainer');
  });

  test('versioned onboarding state roundtrips the resumable draft', () async {
    final repository = KeyValueOnboardingRepository(InMemoryKeyValueStore());
    final state = OnboardingState(
      currentStep: OnboardingStep.reminder,
      intent: OnboardingIntent.fitness,
      firstHabitId: 'first-habit',
      widgetPromotionState: WidgetPromotionState.presented,
      habitDraft: OnboardingHabitDraft(
        name: 'Training',
        category: 'Fitness',
        icon: '🏋️',
        color: '#C45B42',
        frequency: HabitFrequency.custom,
        targetCount: 1,
        customDays: const <int>[5, 1, 3],
        templateId: 'workout',
        reminderEnabled: true,
        reminderTime: '18:30',
      ),
    );

    await repository.save(state);
    final restored = await repository.load();

    expect(restored?.onboardingVersion, OnboardingState.currentVersion);
    expect(restored?.currentStep, OnboardingStep.reminder);
    expect(restored?.intent, OnboardingIntent.fitness);
    expect(restored?.firstHabitId, 'first-habit');
    expect(restored?.habitDraft?.customDays, <int>[1, 3, 5]);
    expect(restored?.habitDraft?.reminderTime, '18:30');
  });
}
