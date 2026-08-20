import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/components/habit_illustration.dart';
import 'package:habiter/theme/app_theme.dart';

void main() {
  for (final kind in HabitIllustrationKind.values) {
    testWidgets('${kind.name} illustration exposes one image semantic', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: HabitIllustration(
              kind: kind,
              step: OnboardingStep.welcome,
              semanticLabel: '${kind.name} habit story',
            ),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey<String>('habit-illustration-${kind.name}')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('${kind.name} habit story'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  test('painter only repaints when its visual contract changes', () {
    const original = HabitIllustrationPainter(
      kind: HabitIllustrationKind.sprout,
      ink: Color(0xFF142A22),
      accent: Color(0xFF71966D),
    );
    const same = HabitIllustrationPainter(
      kind: HabitIllustrationKind.sprout,
      ink: Color(0xFF142A22),
      accent: Color(0xFF71966D),
    );
    const changed = HabitIllustrationPainter(
      kind: HabitIllustrationKind.growth,
      ink: Color(0xFF142A22),
      accent: Color(0xFF71966D),
    );

    expect(same.shouldRepaint(original), isFalse);
    expect(changed.shouldRepaint(original), isTrue);
  });

  testWidgets('illustration remains static when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: HabitIllustration(
            kind: HabitIllustrationKind.growth,
            step: OnboardingStep.widgetPin,
            semanticLabel: 'Growth without motion',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
