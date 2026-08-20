import 'package:flutter/material.dart';

import '../application/onboarding_state.dart';

@immutable
final class OnboardingEditorialColors {
  const OnboardingEditorialColors({
    required this.canvas,
    required this.ink,
    required this.softInk,
    required this.surface,
    required this.accent,
  });

  final Color canvas;
  final Color ink;
  final Color softInk;
  final Color surface;
  final Color accent;
}

abstract final class OnboardingEditorial {
  static const contentMaxWidth = 620.0;
  static const compactTitleSize = 44.0;
  static const regularTitleSize = 56.0;
  static const expandedTitleSize = 68.0;
  static const actionHeight = 56.0;

  static OnboardingEditorialColors colorsFor(
    BuildContext context,
    OnboardingStep step,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final tone = _toneIndex(step);

    if (highContrast) {
      final scheme = Theme.of(context).colorScheme;
      return OnboardingEditorialColors(
        canvas: scheme.surface,
        ink: scheme.onSurface,
        softInk: scheme.onSurface,
        surface: scheme.surfaceContainerHighest,
        accent: scheme.primary,
      );
    }

    final canvases = dark
        ? const <Color>[
            Color(0xFF1D2D26),
            Color(0xFF292F1D),
            Color(0xFF302522),
            Color(0xFF32281F),
            Color(0xFF242B2B),
          ]
        : const <Color>[
            Color(0xFFDCEBD0),
            Color(0xFFECF4CB),
            Color(0xFFF3D3CE),
            Color(0xFFF7DEC7),
            Color(0xFFDCE9E4),
          ];
    final accents = dark
        ? const <Color>[
            Color(0xFFA8C99B),
            Color(0xFFD0DE8E),
            Color(0xFFE1A59A),
            Color(0xFFE7B68E),
            Color(0xFF9BC8BA),
          ]
        : const <Color>[
            Color(0xFF71966D),
            Color(0xFF93A74B),
            Color(0xFFBE776B),
            Color(0xFFC88455),
            Color(0xFF5D8F82),
          ];
    final canvas = canvases[tone];
    final ink = dark ? const Color(0xFFF5F1E7) : const Color(0xFF142A22);
    return OnboardingEditorialColors(
      canvas: canvas,
      ink: ink,
      softInk: ink.withValues(alpha: 0.72),
      surface: Color.alphaBlend(ink.withValues(alpha: 0.075), canvas),
      accent: accents[tone],
    );
  }

  static int _toneIndex(OnboardingStep step) => switch (step) {
    OnboardingStep.welcome || OnboardingStep.notStarted => 0,
    OnboardingStep.intent || OnboardingStep.reminder => 2,
    OnboardingStep.firstHabit || OnboardingStep.rhythmExplainer => 1,
    OnboardingStep.rhythm || OnboardingStep.widgetPin => 3,
    OnboardingStep.reminderModel ||
    OnboardingStep.habitReady ||
    OnboardingStep.widgetIntro ||
    OnboardingStep.completed => 4,
  };
}
