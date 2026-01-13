import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFD4A373); // Warm Beige/Tan
  static const primaryDark = Color(0xFFA97142); // Darker Tan
  static const primaryLight = Color(0xFFE9DCC9); // Light Cream
  static const secondary = Color(0xFFCCD5AE); // Sage Green (Soft)
  static const accent = Color(0xFFE76F51); // Terracotta
  static const background = Color(0xFFFAFAF5); // Very Light Cream/Off-white
  static const backgroundDark = Color(0xFFF0EBE0); // Slightly darker background
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F4EB); // Warm Muted Surface
  static const text = Color(0xFF4A4036); // Dark Brown/Charcoal
  static const textSecondary = Color(0xFF8C7E72); // Muted Brown
  static const textTertiary = Color(0xFFBDB3AA); // Light Brown/Gray
  static const textMuted = textTertiary; // Alias for consistency
  static const border = Color(0xFFE6E0D4); // Warm Border
  static const borderLight = Color(0xFFF2EFE9); // Light Warm Border
  static const success = Color(0xFF8CB369); // Muted Green
  static const warning = Color(0xFFF4A261); // Muted Orange
  static const error = Color(0xFFE76F51); // Soft Red/Terracotta
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
      color: Color(0x084A4036), // Very subtle
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x144A4036),
      blurRadius: 22,
      spreadRadius: -2,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x0A4A4036),
      blurRadius: 36,
      spreadRadius: -10,
      offset: Offset(0, 26),
    ),
  ];

  static const glow = [
    BoxShadow(
      color: Color(0x1AD4A373), // Reduced opacity from 0x22
      blurRadius: 40, // Increased blur
      spreadRadius: -12, // Reduced spread
      offset: Offset(0, 20),
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
  static final h1 = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: -0.8,
  );

  static final h2 = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.4,
  );

  static final h3 = GoogleFonts.spaceGrotesk(
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
    letterSpacing: 0.35,
  );
}

class AppStyles {
  static final glassLow = BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.0),
    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
  );

  static final glassHigh = BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
  );

  static final glassBorder = Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1.0,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      shadowColor: const Color(0x160B1220),
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
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.primary.withOpacity(0.16),
      height: 74,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.textSecondary,
          size: 22,
        ),
      ),
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
      hintStyle:
          AppTextStyles.bodySecondary.copyWith(color: AppColors.textTertiary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.primary.withOpacity(0.18),
      labelStyle:
          AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      secondaryLabelStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primaryDark,
      contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        elevation: 0,
        shadowColor: const Color(0x1F0EA5E9),
      ),
    ),
    dividerColor: AppColors.borderLight,
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      dense: true,
      contentPadding: EdgeInsets.zero,
    ),
  );
}

/// Build dark theme for the app
ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  // Dark text styles
  final h1Dark = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColorsDark.text,
    letterSpacing: -0.8,
  );
  final h2Dark = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.text,
    letterSpacing: -0.4,
  );
  final h3Dark = GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.text,
    letterSpacing: -0.2,
  );
  final bodyDark = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.text,
    height: 1.5,
  );
  final bodySecondaryDark = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textSecondary,
    height: 1.45,
  );
  final captionDark = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColorsDark.textTertiary,
    letterSpacing: 0.35,
  );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsDark.primary,
      surface: AppColorsDark.surface,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColorsDark.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColorsDark.text,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColorsDark.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        side: const BorderSide(color: AppColorsDark.borderLight),
      ),
      shadowColor: const Color(0x40000000),
    ),
    textTheme: textTheme.copyWith(
      displayLarge: h1Dark,
      displayMedium: h2Dark,
      displaySmall: h3Dark,
      bodyLarge: bodyDark,
      bodyMedium: bodySecondaryDark,
      bodySmall: captionDark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColorsDark.primary.withOpacity(0.20),
      height: 74,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColorsDark.primary
              : AppColorsDark.textSecondary,
          size: 22,
        ),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        captionDark.copyWith(
          color: AppColorsDark.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsDark.primary,
      foregroundColor: AppColorsDark.background,
      shape: StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.primary),
      ),
      labelStyle: bodySecondaryDark,
      hintStyle: bodySecondaryDark.copyWith(color: AppColorsDark.textTertiary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColorsDark.surfaceMuted,
      selectedColor: AppColorsDark.primary.withOpacity(0.25),
      labelStyle: captionDark.copyWith(color: AppColorsDark.textSecondary),
      secondaryLabelStyle:
          captionDark.copyWith(color: AppColorsDark.background),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      side: const BorderSide(color: AppColorsDark.borderLight),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsDark.primary,
      contentTextStyle: bodyDark.copyWith(color: AppColorsDark.background),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.background,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        elevation: 0,
        shadowColor: const Color(0x40000000),
      ),
    ),
    dividerColor: AppColorsDark.borderLight,
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      dense: true,
      contentPadding: EdgeInsets.zero,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: bodySecondaryDark,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColorsDark.surface),
      ),
    ),
  );
}
