import 'dart:math' as math;

import 'package:flutter/material.dart';

final class HabiterPalette {
  const HabiterPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.surfaceContainer,
    required this.onSurface,
    required this.outline,
    required this.error,
    required this.onError,
  });

  static const light = HabiterPalette(
    primary: Color(0xFF356859),
    onPrimary: Colors.white,
    secondary: Color(0xFF8B5D48),
    onSecondary: Colors.white,
    surface: Color(0xFFFAF9F5),
    surfaceContainer: Color(0xFFF0F1EC),
    onSurface: Color(0xFF1E2925),
    outline: Color(0xFF727C76),
    error: Color(0xFF9A3B36),
    onError: Colors.white,
  );

  static const dark = HabiterPalette(
    primary: Color(0xFFA8D8C3),
    onPrimary: Color(0xFF0B2118),
    secondary: Color(0xFFF0B9A0),
    onSecondary: Color(0xFF30170D),
    surface: Color(0xFF151A18),
    surfaceContainer: Color(0xFF202724),
    onSurface: Color(0xFFEAF1ED),
    outline: Color(0xFF919C96),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF4A1010),
  );

  static const lightHighContrast = HabiterPalette(
    primary: Color(0xFF123D2C),
    onPrimary: Colors.white,
    secondary: Color(0xFF633019),
    onSecondary: Colors.white,
    surface: Colors.white,
    surfaceContainer: Color(0xFFF0F0EA),
    onSurface: Colors.black,
    outline: Colors.black,
    error: Color(0xFF750000),
    onError: Colors.white,
  );

  static const darkHighContrast = HabiterPalette(
    primary: Color(0xFFC9F8D8),
    onPrimary: Colors.black,
    secondary: Color(0xFFFFD3BC),
    onSecondary: Colors.black,
    surface: Colors.black,
    surfaceContainer: Color(0xFF171A18),
    onSurface: Colors.white,
    outline: Colors.white,
    error: Color(0xFFFFDAD6),
    onError: Colors.black,
  );

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color surfaceContainer;
  final Color onSurface;
  final Color outline;
  final Color error;
  final Color onError;
}

double contrastRatio(Color foreground, Color background) {
  final lighter = math.max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final darker = math.min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  return (lighter + 0.05) / (darker + 0.05);
}
