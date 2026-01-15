import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import 'providers/app_lock_provider.dart';
import 'providers/classly_sync_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/app_lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()..load()),
        ChangeNotifierProvider(create: (_) => AppLockProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ClasslySyncProvider()..load()),
      ],
      child: const HabiterApp(),
    ),
  );
}

class HabiterApp extends StatelessWidget {
  const HabiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Habiter',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _RootShell(),
        );
      },
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;
  late final PageController _pageController;
  final _pages = const [HomeScreen(), AnalyticsScreen()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Listen to habit changes to update app lock status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupHabitListener();
    });
  }

  void _setupHabitListener() {
    final habitProvider = context.read<HabitProvider>();
    final appLockProvider = context.read<AppLockProvider>();

    // Initial check
    appLockProvider.updateHabitCompletion(
      habits: habitProvider.habits,
      entries: habitProvider.habitEntries,
    );

    // Listen for changes
    habitProvider.addListener(() {
      appLockProvider.updateHabitCompletion(
        habits: habitProvider.habits,
        entries: habitProvider.habitEntries,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavChange(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
  }

  void _openAppLock() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppLockScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.appShell),
      child: Stack(
        children: [
          const _ShellBackground(),
          Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: _pages,
            ),
            floatingActionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'settings',
                  onPressed: _openSettings,
                  backgroundColor: AppColors.surface,
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<AppLockProvider>(
                  builder: (context, appLock, _) {
                    if (!appLock.isSupported) return const SizedBox.shrink();
                    return FloatingActionButton.small(
                      heroTag: 'applock',
                      onPressed: _openAppLock,
                      backgroundColor: appLock.isEnabled
                          ? AppColors.primary
                          : AppColors.surface,
                      child: Icon(
                        appLock.isEnabled ? Icons.lock : Icons.lock_open,
                        color: appLock.isEnabled
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _GlassNavBar(
                index: _index,
                onChange: _onNavChange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onChange});

  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor =
        isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final l = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: AppShadows.soft,
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onChange,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.checklist_rtl),
                selectedIcon: const Icon(Icons.checklist_rtl),
                label: l.navHabits,
              ),
              NavigationDestination(
                icon: const Icon(Icons.query_stats),
                selectedIcon: const Icon(Icons.query_stats),
                label: l.navAnalytics,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBackground extends StatelessWidget {
  const _ShellBackground();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          _GlowOrb(
            size: 320,
            top: -120,
            left: -70,
            colors: [Color(0xFF1B52FF), Color(0x662563EB)],
          ),
          _GlowOrb(
            size: 260,
            bottom: -40,
            right: -20,
            colors: [Color(0xFF0FCFBB), Color(0x6600C9A7)],
          ),
          _GlowOrb(
            size: 180,
            top: 220,
            right: 120,
            colors: [Color(0xFFFF9C55), Color(0x55FFB86C)],
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.colors,
  });

  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}
