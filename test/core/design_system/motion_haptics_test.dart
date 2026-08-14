import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/core/design_system/motion.dart';
import 'package:habiter/widgets/visuals/particle_burst.dart';

void main() {
  test(
    'reduced motion resolves every decorative duration and budget to zero',
    () {
      expect(HabiterMotion.standard.duration(reduced: true), Duration.zero);
      expect(HabiterMotion.emphasized.duration(reduced: true), Duration.zero);
      expect(HabiterMotion.particleBudget(reduced: true), 0);
      expect(
        HabiterMotion.particleBudget(reduced: false),
        lessThanOrEqualTo(12),
      );
    },
  );

  test('haptic platform support is explicit and web-safe', () {
    expect(supportsHaptics(TargetPlatform.android, isWeb: false), isTrue);
    expect(supportsHaptics(TargetPlatform.iOS, isWeb: false), isTrue);
    expect(supportsHaptics(TargetPlatform.windows, isWeb: false), isFalse);
    expect(supportsHaptics(TargetPlatform.android, isWeb: true), isFalse);
  });

  testWidgets('particle burst honors reduced motion and its hard budget', (
    tester,
  ) async {
    Future<int> particles({required bool disabled}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disabled),
            child: const ParticleBurst(color: Colors.green, particleCount: 99),
          ),
        ),
      );
      final count = tester
          .widgetList(find.byKey(const ValueKey('particle')))
          .length;
      await tester.pumpAndSettle();
      return count;
    }

    expect(await particles(disabled: false), 12);
    expect(await particles(disabled: true), 0);
  });
}
