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
    primary: Color(0xFF285943),
    onPrimary: Colors.white,
    secondary: Color(0xFF925B3D),
    onSecondary: Colors.white,
    surface: Color(0xFFFFFDF7),
    surfaceContainer: Color(0xFFF2EEE4),
    onSurface: Color(0xFF1D2A24),
    outline: Color(0xFF68776F),
    error: Color(0xFF9B2C2C),
    onError: Colors.white,
  );

  static const dark = HabiterPalette(
    primary: Color(0xFFA9D6B8),
    onPrimary: Color(0xFF102018),
    secondary: Color(0xFFF0B89B),
    onSecondary: Color(0xFF2D160B),
    surface: Color(0xFF171C19),
    surfaceContainer: Color(0xFF222A25),
    onSurface: Color(0xFFF1F5F0),
    outline: Color(0xFF9BA9A0),
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
