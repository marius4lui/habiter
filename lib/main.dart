import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/habit_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => HabitProvider()..load(),
      child: const HabiterApp(),
    ),
  );
}

class HabiterApp extends StatelessWidget {
  const HabiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habiter',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _RootShell(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.soft,
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onChange,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.checklist_rtl),
                selectedIcon: Icon(Icons.checklist_rtl),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.query_stats),
                selectedIcon: Icon(Icons.query_stats),
                label: 'Analytics',
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
    return IgnorePointer(
      child: Stack(
        children: const [
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
