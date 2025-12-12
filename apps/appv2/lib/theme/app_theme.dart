import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0A6EE0);
  static const primaryLight = Color(0xFF7CD3F7);
  static const secondary = Color(0xFF06C69A);
  static const accent = Color(0xFFFF8450);
  static const background = Color(0xFFF5F7FB);
  static const backgroundDark = Color(0xFFE7EDF6);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textTertiary = Color(0xFF94A3B8);
  static const border = Color(0xFFD0D8E6);
  static const borderLight = Color(0xFFE6EDF7);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFFF4757);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppBorderRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const full = 999.0;
}

class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 14,
      offset: Offset(0, 8),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x1F0F172A),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 30,
      spreadRadius: -8,
      offset: Offset(0, 24),
    ),
  ];
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [
      Color(0xFF0EA5E9),
      Color(0xFF2563EB),
      Color(0xFF06C69A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const halo = RadialGradient(
    colors: [
      Color(0x5534D399),
      Color(0x330EA5E9),
      Colors.transparent,
    ],
    radius: 1.1,
    center: Alignment.topRight,
  );
}

class AppTextStyles {
  static final h1 = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: -1,
  );

  static final h2 = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.5,
  );

  static final h3 = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.2,
  );

  static final body = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    height: 1.5,
  );

  static final bodySecondary = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static final caption = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 0.4,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
  );
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      foregroundColor: AppColors.text,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      shadowColor: const Color(0x160F172A),
    ),
    textTheme: textTheme.copyWith(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h2,
      displaySmall: AppTextStyles.h3,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.bodySecondary,
      bodySmall: AppTextStyles.caption,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      height: 70,
      labelTextStyle: WidgetStatePropertyAll(
        AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      labelStyle: AppTextStyles.bodySecondary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundDark,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      secondaryLabelStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primaryDark,
      contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        elevation: 0,
        shadowColor: const Color(0x1F0EA5E9),
      ),
    ),
  );
}
