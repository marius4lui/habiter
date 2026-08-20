import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import 'app/bootstrap.dart';
import 'app/dependencies.dart';
import 'app/navigation/app_route.dart';
import 'app/navigation/app_router.dart';
import 'app/shell/adaptive_app_shell.dart';
import 'core/design_system/haptics.dart';
import 'core/design_system/motion.dart';
import 'features/home/application/habit_hub_model.dart';
import 'features/onboarding/application/onboarding_controller.dart';
import 'features/onboarding/application/onboarding_repository.dart';
import 'features/onboarding/presentation/onboarding_flow.dart';
import 'features/updates/application/update_controller.dart';
import 'features/updates/presentation/update_center_screen.dart';
import 'features/updates/presentation/update_experience_gate.dart';
import 'features/widgets/application/widget_background_entry_point.dart';
import 'features/widgets/application/widget_app_lock_state_resolver.dart';
import 'features/widgets/application/widget_sync_controller.dart';
import 'features/widgets/application/widget_lifecycle_coordinator.dart';
import 'features/widgets/data/android_widget_bridge.dart';
import 'features/widgets/domain/home_widget_platform.dart';
import 'features/widgets/domain/widget_bridge.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import 'providers/app_lock_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/app_lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rhythm_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supportsHomeWidget) {
    await HomeWidget.registerInteractivityCallback(
      habiterWidgetBackgroundCallback,
    );
  }
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
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_problem_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n.bootstrapErrorTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.bootstrapErrorBody,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
    final widgetSync = WidgetSyncController(
      repository: dependencies.habitRepository,
      bridge: const AndroidWidgetBridge(),
      clock: dependencies.clock,
      appLockResolver: WidgetAppLockStateResolver(dependencies.store),
    );
    return MultiProvider(
      providers: [
        Provider<HapticGateway>.value(value: dependencies.haptics),
        Provider<WidgetBridge>.value(value: const AndroidWidgetBridge()),
        Provider<WidgetSyncController>.value(value: widgetSync),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(
            repository: dependencies.habitRepository,
            clock: dependencies.clock,
            ids: dependencies.ids,
            actionStore: dependencies.store,
            synchronizeWidget: () => widgetSync.synchronize(
              locale: WidgetsBinding
                  .instance
                  .platformDispatcher
                  .locale
                  .languageCode,
            ),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingController(
            repository: KeyValueOnboardingRepository(dependencies.store),
            ids: dependencies.ids,
            clock: dependencies.clock,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AppLockProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => dependencies.updateController),
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

class HabiterApp extends StatefulWidget {
  const HabiterApp({super.key});

  @override
  State<HabiterApp> createState() => _HabiterAppState();
}

class _HabiterAppState extends State<HabiterApp> {
  static const _updateChannel = MethodChannel('com.habiter.app/updates');
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _widgetLaunchSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _updateChannel.setMethodCallHandler((call) async {
        if (call.method == 'openUpdateCenter') _openUpdates();
      });
      unawaited(_consumePendingUpdateNavigation());
    }
    if (!supportsHomeWidget) return;
    _widgetLaunchSubscription = HomeWidget.widgetClicked.listen(
      (_) => _openTodayFromWidget(),
    );
    unawaited(_handleInitialWidgetLaunch());
  }

  Future<void> _handleInitialWidgetLaunch() async {
    final launch = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launch != null) _openTodayFromWidget();
  }

  void _openTodayFromWidget() {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openTodayFromWidget(),
      );
      return;
    }
    navigator.pushNamedAndRemoveUntil<void>(
      AppRouteCodec.encode(AppRoute.today),
      (_) => false,
    );
  }

  Future<void> _consumePendingUpdateNavigation() async {
    try {
      if (await _updateChannel.invokeMethod<bool>('consumePendingOpen') ==
          true) {
        _openUpdates();
      }
    } on MissingPluginException {
      // Non-Android platforms have no native update intent.
    }
  }

  void _openUpdates() {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openUpdates());
      return;
    }
    navigator.pushNamed<void>(AppRouteCodec.encode(AppRoute.updates));
  }

  @override
  void dispose() {
    _widgetLaunchSubscription?.cancel();
    if (!kIsWeb) _updateChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final router = AppRouter(
          primaryBuilder: (_, route) =>
              _OnboardingGate(child: _RootShell(initialRoute: route)),
          settingsBuilder: (_) => const SettingsScreen(),
          appLockBuilder: (_) => const AppLockScreen(),
          updatesBuilder: (_) => const UpdateCenterScreen(),
        );
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
          builder: (context, child) =>
              UpdateExperienceGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({required this.child});

  final Widget child;

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  HabitProvider? _habits;
  bool _updatesStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habits = context.read<HabitProvider>();
    if (identical(habits, _habits)) return;
    _habits?.removeListener(_initializeWhenReady);
    _habits = habits..addListener(_initializeWhenReady);
    _initializeWhenReady();
  }

  void _initializeWhenReady() {
    final habits = _habits;
    if (habits == null || habits.loading) return;
    final onboarding = context.read<OnboardingController>();
    if (!onboarding.initialized && !onboarding.loading) {
      onboarding.initialize(hasExistingHabits: habits.habits.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _habits?.removeListener(_initializeWhenReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final onboarding = context.watch<OnboardingController>();
    if (habits.loading || !onboarding.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (onboarding.shouldShowOnboarding) return const OnboardingFlow();
    if (!_updatesStarted) {
      _updatesStarted = true;
      unawaited(context.read<UpdateController>().initialize());
    }
    return widget.child;
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell({required this.initialRoute});

  final AppRoute initialRoute;

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> with WidgetsBindingObserver {
  late int _index;
  late final PageController _pageController;
  HabitProvider? _habitProvider;
  WidgetLifecycleCoordinator? _widgetLifecycle;
  Timer? _updateTimer;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _index = switch (widget.initialRoute) {
      AppRoute.analytics => 1,
      AppRoute.rhythm => 2,
      _ => 0,
    };
    _pages = <Widget>[
      HomeScreen(onOpenDestination: _openHubDestination),
      const AnalyticsScreen(),
      const RhythmScreen(),
    ];
    _pageController = PageController(initialPage: _index);
    WidgetsBinding.instance.addObserver(this);
    _updateTimer = Timer.periodic(const Duration(hours: 1), (_) {
      final updates = context.read<UpdateController>();
      if (updates.initialized) unawaited(updates.handleForegroundTick());
    });

    // Listen to habit changes to update app lock status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupHabitListener();
    });
  }

  void _setupHabitListener() {
    final habitProvider = context.read<HabitProvider>();
    _habitProvider = habitProvider;
    _widgetLifecycle = WidgetLifecycleCoordinator(
      reconcileForeground: () => habitProvider.reconcileExternalHabitState(),
      publishBackground: habitProvider.syncWidget,
      onError: (error, stackTrace) {
        debugPrint('Widget lifecycle reconciliation failed safely: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
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
    WidgetsBinding.instance.removeObserver(this);
    _habitProvider?.removeListener(_updateAppLock);
    _pageController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lifecycle = _widgetLifecycle;
    if (lifecycle != null) unawaited(lifecycle.handle(state));
    if (state == AppLifecycleState.resumed) {
      final updates = context.read<UpdateController>();
      if (updates.initialized) unawaited(updates.handleResume());
    }
  }

  void _onNavChange(int index) {
    if (index == _index) return;

    void changePage() {
      if (!mounted || !_pageController.hasClients) return;
      if (context.reduceMotion) {
        _pageController.jumpToPage(index);
        return;
      }
      _pageController.animateToPage(
        index,
        duration: HabiterMotion.standard.duration(reduced: false),
        curve: HabiterMotion.standard.curve,
      );
    }

    if (_pageController.hasClients) {
      changePage();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => changePage());
    }
  }

  void _onRouteSelected(AppRoute route) {
    _onNavChange(switch (route) {
      AppRoute.analytics => 1,
      AppRoute.rhythm => 2,
      _ => 0,
    });
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _restoreRoute(index);
  }

  void _restoreRoute(int index) {
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(
        AppRouteCodec.encode(switch (index) {
          1 => AppRoute.analytics,
          2 => AppRoute.rhythm,
          _ => AppRoute.today,
        }),
      ),
    );
  }

  void _openAppLock() {
    Navigator.of(context).pushNamed(AppRouteCodec.encode(AppRoute.appLock));
  }

  void _openSettings() {
    Navigator.of(context).pushNamed(AppRouteCodec.encode(AppRoute.settings));
  }

  void _openHubDestination(HabitHubDestination destination) {
    switch (destination) {
      case HabitHubDestination.today:
        _onRouteSelected(AppRoute.today);
        break;
      case HabitHubDestination.analytics:
        _onRouteSelected(AppRoute.analytics);
        break;
      case HabitHubDestination.rhythm:
        _onRouteSelected(AppRoute.rhythm);
        break;
      case HabitHubDestination.appLock:
        _openAppLock();
        break;
      case HabitHubDestination.updates:
        Navigator.of(context).pushNamed(AppRouteCodec.encode(AppRoute.updates));
        break;
      case HabitHubDestination.settings:
        _openSettings();
        break;
      case HabitHubDestination.createHabit:
        // The HomeScreen owns the existing habit editor sheet.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveAppShell(
      selected: switch (_index) {
        1 => AppRoute.analytics,
        2 => AppRoute.rhythm,
        _ => AppRoute.today,
      },
      onSelected: _onRouteSelected,
      onOpenSettings: _openSettings,
      onOpenAppLock: _openAppLock,
      child: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
    );
  }
}
