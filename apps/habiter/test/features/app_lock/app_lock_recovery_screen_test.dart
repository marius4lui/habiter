import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/domain/app_lock_gateway.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/models/locked_app.dart';
import 'package:habiter/providers/app_lock_provider.dart';
import 'package:habiter/screens/app_lock_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/fake_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('unsupported platform explains scope without controls', (
    tester,
  ) async {
    final provider = AppLockProvider(
      gateway: _AppLockGateway(supported: false),
    );
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('Android Only'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('permission flow survives 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = AppLockProvider(gateway: _AppLockGateway());
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _app(provider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permissions required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabled App Lock always exposes one-tap disable', (
    tester,
  ) async {
    final gateway = _AppLockGateway(usage: true, overlay: true);
    final provider = AppLockProvider(gateway: gateway);
    await provider.load();
    await provider.loadInstalledApps();
    await provider.toggleAppLock('org.example.app');
    await provider.setEnabled(true);
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('disable-app-lock')));
    await tester.pumpAndSettle();
    expect(provider.isEnabled, isFalse);
    expect(gateway.stops, greaterThan(0));
  });

  testWidgets('app picker shows friendly names and keeps package IDs hidden', (
    tester,
  ) async {
    final provider = AppLockProvider(
      gateway: _AppLockGateway(usage: true, overlay: true),
    );
    await provider.load();
    await provider.loadInstalledApps();
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('Example'), findsOneWidget);
    expect(find.text('org.example.app'), findsNothing);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.text('No matching apps'), findsOneWidget);
  });

  test(
    'midnight recomputes completion and fails open for the new day',
    () async {
      final gateway = _AppLockGateway(usage: true, overlay: true);
      final clock = FakeClock(DateTime.utc(2026, 8, 14, 23, 59));
      final provider = AppLockProvider(gateway: gateway, clock: clock);
      await provider.load();
      await provider.loadInstalledApps();
      await provider.toggleAppLock('org.example.app');
      await provider.setEnabled(true);
      final habit = Habit(
        id: 'habit',
        name: 'Walk',
        color: '#000000',
        icon: 'H',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        category: 'Test',
        createdAt: DateTime.utc(2026, 8, 1),
        isActive: true,
      );
      final entry = HabitEntry(
        id: 'entry',
        habitId: 'habit',
        date: '2026-08-14',
        completed: true,
        count: 1,
        timestamp: clock.now(),
      );

      await provider.updateHabitCompletion(
        habits: <Habit>[habit],
        entries: <HabitEntry>[entry],
      );
      clock.advance(const Duration(minutes: 2));
      await provider.updateHabitCompletion(
        habits: <Habit>[habit],
        entries: <HabitEntry>[entry],
      );

      expect(gateway.completionStates, containsAllInOrder(<bool>[true, false]));
    },
  );
}

Widget _app(AppLockProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: const MaterialApp(
    locale: Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppLockScreen(),
  ),
);

final class _AppLockGateway implements AppLockGateway {
  _AppLockGateway({
    this.supported = true,
    this.usage = false,
    this.overlay = false,
  });

  final bool supported;
  bool usage;
  bool overlay;
  int stops = 0;
  final List<bool> completionStates = <bool>[];

  @override
  bool get isSupported => supported;

  @override
  Future<AppLockResult<List<LockedApp>>> installedApps() async =>
      const AppLockSuccess<List<LockedApp>>(<LockedApp>[
        LockedApp(packageName: 'org.example.app', appName: 'Example'),
      ]);

  @override
  Future<AppLockResult<bool>> isBatteryOptimized() async =>
      const AppLockSuccess<bool>(false);

  @override
  Future<AppLockResult<void>> openBatterySettings() async =>
      const AppLockSuccess<void>(null);

  @override
  Future<AppLockResult<AppLockPermissionSnapshot>> permissions() async =>
      AppLockSuccess<AppLockPermissionSnapshot>(
        AppLockPermissionSnapshot(usageAccess: usage, overlay: overlay),
      );

  @override
  Future<AppLockResult<void>> requestOverlay() async {
    overlay = true;
    return const AppLockSuccess<void>(null);
  }

  @override
  Future<AppLockResult<void>> requestUsageAccess() async {
    usage = true;
    return const AppLockSuccess<void>(null);
  }

  @override
  Future<AppLockResult<bool>> start(List<String> packageNames) async =>
      const AppLockSuccess<bool>(true);

  @override
  Future<AppLockResult<void>> stop() async {
    stops++;
    return const AppLockSuccess<void>(null);
  }

  @override
  Future<AppLockResult<void>> syncCompletion({
    required bool complete,
    required List<String> incompleteHabitNames,
  }) async {
    completionStates.add(complete);
    return const AppLockSuccess<void>(null);
  }

  @override
  Future<AppLockResult<void>> updatePackages(List<String> packageNames) async =>
      const AppLockSuccess<void>(null);
}
