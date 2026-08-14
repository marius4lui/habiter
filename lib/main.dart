import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/bootstrap.dart';
import 'app/dependencies.dart';
import 'app/navigation/app_route.dart';
import 'app/navigation/app_router.dart';
import 'app/shell/adaptive_app_shell.dart';
import 'core/design_system/haptics.dart';
import 'core/design_system/motion.dart';
import 'l10n/app_localizations.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_HabiterLauncher(AppBootstrap(AppDependencies.production())));
}

class _HabiterLauncher extends StatefulWidget {
  const _HabiterLauncher(this.bootstrap);

  final AppBootstrap bootstrap;

  @override
  State<_HabiterLauncher> createState() => _HabiterLauncherState();
}

class _HabiterLauncherState extends State<_HabiterLauncher> {
  late Future<BootstrapResult> _result;

  @override
  void initState() {
    super.initState();
    _result = widget.bootstrap.run();
  }

  void _retry() {
    setState(() => _result = widget.bootstrap.run());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapResult>(
      future: _result,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final result = snapshot.requireData;
        if (!result.isReady) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_problem_outlined, size: 40),
                    const SizedBox(height: 16),
                    Text(result.failure!.diagnostic),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          );
        }
        return _buildApplication();
      },
    );
  }

  Widget _buildApplication() {
    final dependencies = _resultDependencies;
    return MultiProvider(
      providers: [
        Provider<HapticGateway>.value(value: dependencies.haptics),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(
            repository: dependencies.habitRepository,
            clock: dependencies.clock,
            ids: dependencies.ids,
          )..load(),
        ),
        ChangeNotifierProvider(create: (_) => AppLockProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ClasslySyncProvider()),
      ],
      child: const HabiterApp(),
    );
  }

  AppDependencies get _resultDependencies {
    // This getter is only reached after the same future produced a ready result.
    // AppDependencies are stable for the lifetime of the launcher.
    return (widget.bootstrap.dependencies);
  }
}

class HabiterApp extends StatelessWidget {
  const HabiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final router = AppRouter(
          primaryBuilder: (_, route) => _RootShell(initialRoute: route),
          settingsBuilder: (_) => const SettingsScreen(),
          appLockBuilder: (_) => const AppLockScreen(),
        );
        return MaterialApp(
          title: 'Habiter',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkTheme(),
          highContrastTheme: buildHighContrastAppTheme(),
          highContrastDarkTheme: buildHighContrastDarkTheme(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute:
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
          onGenerateInitialRoutes: router.initialRoutes,
          onGenerateRoute: router.routeFor,
        );
      },
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell({required this.initialRoute});

  final AppRoute initialRoute;

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  late int _index;
  late final PageController _pageController;
  HabitProvider? _habitProvider;
  final _pages = const [HomeScreen(), AnalyticsScreen()];

  @override
  void initState() {
    super.initState();
    _index = widget.initialRoute == AppRoute.analytics ? 1 : 0;
    _pageController = PageController(initialPage: _index);

    // Listen to habit changes to update app lock status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupHabitListener();
    });
  }

  void _setupHabitListener() {
    final habitProvider = context.read<HabitProvider>();
    _habitProvider = habitProvider;
    _updateAppLock();
    habitProvider.addListener(_updateAppLock);
  }

  void _updateAppLock() {
    final habitProvider = _habitProvider;
    if (habitProvider == null || !mounted) return;
    context.read<AppLockProvider>().updateHabitCompletion(
      habits: habitProvider.habits,
      entries: habitProvider.habitEntries,
    );
  }

  @override
  void dispose() {
    _habitProvider?.removeListener(_updateAppLock);
    _pageController.dispose();
    super.dispose();
  }

  void _onNavChange(int index) {
    setState(() => _index = index);
    _restoreRoute(index);
    _pageController.animateToPage(
      index,
      duration: HabiterMotion.standard.duration(reduced: context.reduceMotion),
      curve: HabiterMotion.standard.curve,
    );
  }

  void _onRouteSelected(AppRoute route) {
    _onNavChange(route == AppRoute.analytics ? 1 : 0);
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _restoreRoute(index);
  }

  void _restoreRoute(int index) {
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(
        AppRouteCodec.encode(index == 0 ? AppRoute.today : AppRoute.analytics),
      ),
    );
  }

  void _openAppLock() {
    Navigator.of(context).pushNamed(AppRouteCodec.encode(AppRoute.appLock));
  }

  void _openSettings() {
    Navigator.of(context).pushNamed(AppRouteCodec.encode(AppRoute.settings));
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveAppShell(
      selected: _index == 0 ? AppRoute.today : AppRoute.analytics,
      onSelected: _onRouteSelected,
      onOpenSettings: _openSettings,
      onOpenAppLock: _openAppLock,
      child: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
    );
  }
}
