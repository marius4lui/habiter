import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const primary = Color(0xFF90B280); // Muted Green
  static const primaryDark = Color(0xFF7A996B); // Darker Green for interactions
  static const primaryLight = Color(0xFFB4D1A6); // Lighter Green

  // Background
  static const background = Color(0xFFF6F5F3); // Light Background
  static const backgroundDark = Color(0xFF22262A); // Dark Background

  // Cards
  static const cardLight = Color(0xFFFCFAF7);
  static const cardDark = Color(0xFF2C3136);

  // Text
  static const textMain = Color(0xFF383F45);
  static const textDark = Colors.white; // Text color in dark mode
  static const textSecondary = Color(0xFF6B7280); // Gray 500 equivalent
  static const textTertiary = Color(0xFF9CA3AF); // Gray 400 equivalent

  // Accents & Functional
  static const matteBlue = Color(0xFFC9D8E6);
  static const warmBeige = Color(0xFFE8E1D5);
  static const secondary = Color(0xFF9CAF88); // Muted Sage (New Secondary)
  static const accent = Color(0xFFE76F51); // Keeping Terracotta as Accent
  static const warning = Color(0xFFF4A261); // Muted Orange
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF90B280);

  // Surface aliases
  static const surface = cardLight;
  static const surfaceDark = cardDark;
  static const surfaceMuted = Color(0xFFF6F5F3); // Use background color as muted surface alias

  // Backward compatibility
  static const text = textMain;
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
}

/// Dark theme colors - warm and cozy dark mode
class AppColorsDark {
  static const primary =
      Color(0xFFE5B896); // Lighter tan for visibility on dark
  static const primaryDark = Color(0xFFD4A373); // Same as light primary
  static const primaryLight = Color(0xFF3D3530); // Dark cream
  static const secondary = Color(0xFF9CAF88); // Lighter sage for dark
  static const accent = Color(0xFFFF8A6B); // Brighter terracotta
  static const background = Color(0xFF1A1918); // Warm charcoal
  static const backgroundDark = Color(0xFF141312); // Deeper charcoal
  static const surface = Color(0xFF2A2826); // Warm dark surface
  static const surfaceMuted = Color(0xFF232120); // Even darker muted surface
  static const text = Color(0xFFF5F0EB); // Warm white
  static const textSecondary = Color(0xFFB5AEA7); // Light brown
  static const textTertiary = Color(0xFF7A746D); // Muted brown
  static const textMuted = textTertiary;
  static const border = Color(0xFF3D3835); // Dark warm border
  static const borderLight = Color(0xFF2E2A27); // Subtle border
  static const success = Color(0xFF9BC77B); // Brighter green for dark
  static const warning = Color(0xFFFFB074); // Brighter orange for dark
  static const error = Color(0xFFFF8A6B); // Brighter red for dark
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppBorderRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const full = 999.0;
}

class AppShadows {
  static const neumorph = [
    BoxShadow(
      color: Color(0xFFD1D0CE),
      offset: Offset(8, 8),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Colors.white,
      offset: Offset(-8, -8),
      blurRadius: 16,
    ),
  ];

  static const neumorphDark = [
    BoxShadow(
      color: Color(0xFF1B1E22),
      offset: Offset(8, 8),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0xFF292E32),
      offset: Offset(-8, -8),
      blurRadius: 16,
    ),
  ];

  static const neumorphSm = [
    BoxShadow(
      color: Color(0xFFD1D0CE),
      offset: Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Colors.white,
      offset: Offset(-4, -4),
      blurRadius: 8,
    ),
  ];

  static const neumorphSmDark = [
    BoxShadow(
      color: Color(0xFF1B1E22),
      offset: Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0xFF292E32),
      offset: Offset(-4, -4),
      blurRadius: 8,
    ),
  ];

  static const neumorphInset = [
    BoxShadow(
      color: Color(0xFFD1D0CE),
      offset: Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Colors.white,
      offset: Offset(-4, -4),
      blurRadius: 8,
    ),
  ];

  // Helper to stick to standard Material shadows where inset isn't supported easily
  // or use a specific customized container for inset
  static const soft = [
    BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.05),
        blurRadius: 10,
        offset: Offset(0, 4))
  ];

  static const glow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [
      Color(0xFFD4A373),
      Color(0xFFE9C46A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const hero = LinearGradient(
    colors: [
      Color(0xFFD4A373),
      Color(0xFFE76F51),
    ],
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
  );

  static const halo = RadialGradient(
    colors: [
      Color(0x55E9C46A),
      Color(0x33E76F51),
      Colors.transparent,
    ],
    radius: 1.1,
    center: Alignment.topRight,
  );

  static const appShell = LinearGradient(
    colors: [
      Color(0xFFFAFAF5),
      Color(0xFFF2EFE9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardSheen = LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFFDFBF7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Dark theme gradients
class AppGradientsDark {
  static const primary = LinearGradient(
    colors: [
      Color(0xFFE5B896),
      Color(0xFFD4A373),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const hero = LinearGradient(
    colors: [
      Color(0xFF8B5A3C), // Muted tan
      Color(0xFF6B3D2E), // Muted terracotta
    ],
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
  );

  static const halo = RadialGradient(
    colors: [
      Color(0x33E9C46A),
      Color(0x22E76F51),
      Colors.transparent,
    ],
    radius: 1.1,
    center: Alignment.topRight,
  );

  static const appShell = LinearGradient(
    colors: [
      Color(0xFF1A1918),
      Color(0xFF141312),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardSheen = LinearGradient(
    colors: [
      Color(0xFF2A2826),
      Color(0xFF232120),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  // We strictly use Plus Jakarta Sans as per design
  static final _base = GoogleFonts.plusJakartaSans();

  static final h1 = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static final h2 = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static final h3 = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static final body = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static final bodySmall = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static final caption = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static final bodySecondary = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}

class AppStyles {
  static final glassLow = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
  );

  static final glassHigh = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
  );

  static final glassBorder = Border.all(
    color: Colors.white.withValues(alpha: 0.1),
    width: 1.0,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.cardLight,
      onSurface: AppColors.textMain,
      brightness: Brightness.light,

    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0, // Using manual shadows for neumorph
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      displayLarge: AppTextStyles.h1.copyWith(color: AppColors.textMain),
      displayMedium: AppTextStyles.h2.copyWith(color: AppColors.textMain),
      bodyLarge: AppTextStyles.body.copyWith(color: AppColors.textMain),
      bodyMedium: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textMain,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      iconSize: 28,
      elevation: 8,
    ),
  );
}

/// Build dark theme for the app
ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
  );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.cardDark,
      onSurface: Colors.white,
      brightness: Brightness.dark,

    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 8,
    ),
  );
}
