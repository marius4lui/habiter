import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/runtime/domain/runtime_feature_state.dart';

void main() {
  test(
    'runtime feature-state matrix only stops when both features are off',
    () {
      const cases = <(bool, bool, bool)>[
        (false, false, false),
        (true, false, true),
        (false, true, true),
        (true, true, true),
      ];

      for (final (reminders, appBlock, shouldRun) in cases) {
        final state = RuntimeFeatureState(
          remindersEnabled: reminders,
          appBlockEnabled: appBlock,
        );
        expect(
          state.shouldRun,
          shouldRun,
          reason: 'reminders=$reminders appBlock=$appBlock',
        );
      }
    },
  );

  test('active features and serialized shape remain explicit', () {
    const state = RuntimeFeatureState(
      remindersEnabled: true,
      appBlockEnabled: false,
    );

    expect(state.activeFeatures, <RuntimeFeature>{RuntimeFeature.reminders});
    expect(RuntimeFeatureState.fromMap(state.toMap()).toMap(), state.toMap());
  });
}
