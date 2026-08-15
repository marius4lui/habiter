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
    final baseTextTheme = base.textTheme.apply(
      bodyColor: palette.onSurface,
      displayColor: palette.onSurface,
    );
    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 30,
        height: 1.16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HabiterRadius.card),
      side: BorderSide(color: palette.outline.withValues(alpha: 0.22)),
    );

    return base.copyWith(
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: palette.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        minWidth: 80,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
          borderSide: BorderSide(color: palette.primary, width: 2),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            HabiterState.minimumTarget,
            HabiterState.minimumTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiterRadius.control),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(HabiterState.minimumTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.control),
        ),
      ),
      focusColor: palette.primary.withValues(alpha: HabiterState.hoverOpacity),
    );
  }
}
