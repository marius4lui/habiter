import 'package:flutter/material.dart';

import 'habiter_palette.dart';
import 'tokens.dart';

abstract final class HabiterTheme {
  static ThemeData light({bool highContrast = false}) => _build(
    brightness: Brightness.light,
    palette: highContrast
        ? HabiterPalette.lightHighContrast
        : HabiterPalette.light,
  );

  static ThemeData dark({bool highContrast = false}) => _build(
    brightness: Brightness.dark,
    palette: highContrast
        ? HabiterPalette.darkHighContrast
        : HabiterPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required HabiterPalette palette,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          secondary: palette.secondary,
          onSecondary: palette.onSecondary,
          surface: palette.surface,
          surfaceContainer: palette.surfaceContainer,
          onSurface: palette.onSurface,
          outline: palette.outline,
          error: palette.error,
          onError: palette.onError,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: palette.surface,
    );
    final textTheme = base.textTheme.apply(
      bodyColor: palette.onSurface,
      displayColor: palette.onSurface,
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HabiterRadius.card),
      side: BorderSide(color: palette.outline.withValues(alpha: 0.22)),
    );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: palette.surfaceContainer,
        elevation: 0,
        shape: cardShape,
        margin: const EdgeInsets.all(HabiterSpace.sm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: palette.surfaceContainer,
        indicatorColor: palette.primary.withValues(alpha: 0.18),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.surfaceContainer,
        indicatorColor: palette.primary.withValues(alpha: 0.18),
        minWidth: 80,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
          borderSide: BorderSide(color: palette.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            HabiterState.minimumTarget,
            HabiterState.minimumTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiterRadius.control),
          ),
          disabledBackgroundColor: palette.onSurface.withValues(
            alpha: HabiterState.disabledOpacity,
          ),
        ),
      ),
      focusColor: palette.primary.withValues(alpha: HabiterState.hoverOpacity),
    );
  }
}
