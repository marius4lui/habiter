import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/application/app_block_onboarding_state.dart';
import 'package:habiter/features/app_lock/domain/app_block_rule.dart';
import 'package:habiter/features/app_lock/infrastructure/app_block_onboarding_repository.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test(
    'resumable draft roundtrips settings progress and per-app rules',
    () async {
      final store = InMemoryKeyValueStore();
      final repository = KeyValueAppBlockOnboardingRepository(store);
      final state = AppBlockOnboardingState(
        stage: AppBlockOnboardingStage.overlayEducation,
        selectedPackages: const <String>{'social.example'},
        rules: <AppBlockRule>[
          AppBlockRule(
            packageName: 'social.example',
            appName: 'Social',
            requirement: HabitRequirement(<String>['read']),
          ),
        ],
        usagePermissionSeen: true,
        overlayPermissionSeen: true,
      );

      await repository.save(state);
      final restored = await repository.load();

      expect(restored?.stage, AppBlockOnboardingStage.overlayEducation);
      expect(restored?.selectedPackages, <String>{'social.example'});
      expect(
        (restored?.rules.single.requirement as HabitRequirement).habitIds,
        <String>{'read'},
      );
      expect(restored?.usagePermissionSeen, isTrue);
      expect(restored?.overlayPermissionSeen, isTrue);
    },
  );

  test('terminal stages expose the small parent-flow result contract', () {
    expect(
      const AppBlockOnboardingState(
        stage: AppBlockOnboardingStage.completed,
      ).result,
      AppBlockOnboardingResult.enabled,
    );
    expect(
      const AppBlockOnboardingState(
        stage: AppBlockOnboardingStage.skipped,
      ).result,
      AppBlockOnboardingResult.skipped,
    );
    expect(
      const AppBlockOnboardingState(
        stage: AppBlockOnboardingStage.deferred,
      ).result,
      AppBlockOnboardingResult.deferred,
    );
  });
}
