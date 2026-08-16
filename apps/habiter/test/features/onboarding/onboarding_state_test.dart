import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
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
