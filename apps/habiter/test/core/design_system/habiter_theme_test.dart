import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_palette.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/core/design_system/tokens.dart';

void main() {
  test('token scales are complete, ordered, and immutable constants', () {
    expect(<double>[
      HabiterSpace.xs,
      HabiterSpace.sm,
      HabiterSpace.md,
      HabiterSpace.lg,
      HabiterSpace.xl,
    ], orderedEquals(<double>[4, 8, 16, 24, 32]));
    expect(HabiterRadius.card, greaterThan(HabiterRadius.control));
    expect(HabiterState.disabledOpacity, inInclusiveRange(0.3, 0.6));
  });

  test('light, dark, and high-contrast palettes meet text contrast', () {
    for (final palette in <HabiterPalette>[
      HabiterPalette.light,
      HabiterPalette.dark,
      HabiterPalette.lightHighContrast,
      HabiterPalette.darkHighContrast,
    ]) {
      expect(
        contrastRatio(palette.onSurface, palette.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(palette.onPrimary, palette.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('theme snapshots expose the same complete component contract', () {
    for (final theme in <ThemeData>[
      HabiterTheme.light(),
      HabiterTheme.dark(),
      HabiterTheme.light(highContrast: true),
      HabiterTheme.dark(highContrast: true),
    ]) {
      expect(theme.useMaterial3, isTrue);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.navigationBarTheme.height, greaterThanOrEqualTo(64));
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.visualDensity, VisualDensity.adaptivePlatformDensity);
      expect(theme.focusColor.a, greaterThan(0));
      expect(theme.hoverColor.a, greaterThan(0));
    }
  });

  testWidgets('controls survive 200 percent text scaling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: HabiterTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: FilledButton(
                onPressed: null,
                child: Text('Create a healthy habit'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Create a healthy habit'), findsOneWidget);
  });
}
