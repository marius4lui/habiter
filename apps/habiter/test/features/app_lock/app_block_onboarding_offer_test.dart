import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/application/app_block_onboarding_controller.dart';
import 'package:habiter/features/app_lock/application/app_block_onboarding_state.dart';
import 'package:habiter/features/app_lock/domain/app_block_candidate.dart';
import 'package:habiter/features/app_lock/domain/app_block_projection.dart';
import 'package:habiter/features/app_lock/domain/app_block_rule.dart';
import 'package:habiter/features/app_lock/domain/app_lock_gateway.dart';
import 'package:habiter/features/app_lock/infrastructure/app_block_onboarding_repository.dart';
import 'package:habiter/features/app_lock/infrastructure/local_distraction_catalog.dart';
import 'package:habiter/features/app_lock/presentation/onboarding/app_block_onboarding_flow.dart';
import 'package:habiter/models/locked_app.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('first decline reconsiders and second decline exits once', (
    tester,
  ) async {
    final finished = <AppBlockOnboardingResult>[];
    final controller = _controller(_Gateway());
    await tester.pumpWidget(_app(controller, finished.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('app-block-decline-offer')));
    await tester.pumpAndSettle();
    expect(find.text('A small pause can interrupt autopilot.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-block-final-decline')));
    await tester.pumpAndSettle();
    expect(finished, <AppBlockOnboardingResult>[
      AppBlockOnboardingResult.skipped,
    ]);
  });

  testWidgets('both accept actions enter education before requesting access', (
    tester,
  ) async {
    final gateway = _Gateway();
    final controller = _controller(gateway);
    await tester.pumpWidget(_app(controller, (_) {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('app-block-accept-offer')));
    await tester.pumpAndSettle();
    expect(
      find.text('How Habiter finds possible distractions'),
      findsOneWidget,
    );
    expect(gateway.usageRequests, 0);

    await tester.tap(find.byKey(const Key('app-block-request-usage')));
    await tester.pump();
    expect(gateway.usageRequests, 1);
  });

  testWidgets('resume checks permission and advances without confirmation', (
    tester,
  ) async {
    final gateway = _Gateway();
    final controller = _controller(gateway);
    await tester.pumpWidget(_app(controller, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-block-accept-offer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-block-request-usage')));
    gateway.usageAccess = true;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(controller.state.stage, AppBlockOnboardingStage.selection);
  });

  testWidgets('reduced motion exposes the final protection illustration', (
    tester,
  ) async {
    final controller = _controller(_Gateway());
    await tester.pumpWidget(_app(controller, (_) {}, reducedMotion: true));
    await tester.pumpAndSettle();
    final opacity = tester.widget<Opacity>(
      find.byKey(const Key('app-block-protection-line')),
    );
    expect(opacity.opacity, 1);
  });

  testWidgets(
    'recommendations start unselected and bulk habit binding persists',
    (tester) async {
      final now = DateTime(2026, 8, 19);
      final gateway = _Gateway(
        usageAccess: true,
        apps: const <LockedApp>[
          LockedApp(packageName: 'social.example', appName: 'Social'),
        ],
        usage: <AppUsageRecord>[
          AppUsageRecord(
            packageName: 'social.example',
            appName: 'Social',
            foregroundDuration: const Duration(hours: 2),
            lastUsed: now,
          ),
        ],
      );
      final controller = _controller(gateway);
      final finished = <AppBlockOnboardingResult>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AppBlockOnboardingFlow(
            controller: controller,
            habits: <Habit>[_habit('read', 'Read')],
            onFinished: finished.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-block-accept-offer')));
      await controller.reconcilePermissions();
      await tester.pumpAndSettle();

      final tile = tester.widget<CheckboxListTile>(
        find.byKey(const Key('app-block-app-social.example')),
      );
      expect(tile.value, isFalse);
      await tester.tap(find.byKey(const Key('app-block-app-social.example')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('app-block-confirm-selection')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('app-block-binding-specific')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('app-block-habit-read')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('app-block-confirm-bindings')));
      await tester.pumpAndSettle();

      expect(controller.state.stage, AppBlockOnboardingStage.behaviorEducation);
      expect(
        (controller.state.rules.single.requirement as HabitRequirement)
            .habitIds,
        <String>{'read'},
      );
      expect(
        find.text('Daily · unlocks after today’s completion'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('app-block-behavior-continue')));
      await tester.pumpAndSettle();
      expect(gateway.overlayRequests, 0);
      await tester.tap(find.byKey(const Key('app-block-request-overlay')));
      await tester.pump();
      expect(gateway.overlayRequests, 1);

      gateway.overlay = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Ready to protect your focus'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app-block-activate')));
      await tester.pumpAndSettle();
      expect(finished, <AppBlockOnboardingResult>[
        AppBlockOnboardingResult.enabled,
      ]);
    },
  );
}

Widget _app(
  AppBlockOnboardingController controller,
  ValueChanged<AppBlockOnboardingResult> onFinished, {
  bool reducedMotion = false,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: AppBlockOnboardingFlow(
        controller: controller,
        onFinished: onFinished,
      ),
    ),
  ),
);

AppBlockOnboardingController _controller(AppLockGateway gateway) =>
    AppBlockOnboardingController(
      repository: KeyValueAppBlockOnboardingRepository(InMemoryKeyValueStore()),
      gateway: gateway,
      loadCatalog: () async =>
          const LocalDistractionCatalog(<String, DistractionCatalogEntry>{}),
    );

final class _Gateway implements AppLockGateway {
  _Gateway({
    this.usageAccess = false,
    this.apps = const <LockedApp>[],
    this.usage = const <AppUsageRecord>[],
  });

  bool usageAccess;
  bool overlay = false;
  final List<LockedApp> apps;
  final List<AppUsageRecord> usage;
  int usageRequests = 0;
  int overlayRequests = 0;

  @override
  bool get isSupported => true;
  @override
  Future<AppLockResult<List<LockedApp>>> installedApps() async =>
      AppLockSuccess<List<LockedApp>>(apps);
  @override
  Future<AppLockResult<List<AppUsageRecord>>> recentUsage() async =>
      AppLockSuccess<List<AppUsageRecord>>(usage);
  @override
  Future<AppLockResult<AppLockPermissionSnapshot>> permissions() async =>
      AppLockSuccess<AppLockPermissionSnapshot>(
        AppLockPermissionSnapshot(usageAccess: usageAccess, overlay: overlay),
      );
  @override
  Future<AppLockResult<void>> requestUsageAccess() async {
    usageRequests += 1;
    return const AppLockSuccess<void>(null);
  }

  @override
  Future<AppLockResult<void>> requestOverlay() async {
    overlayRequests += 1;
    return const AppLockSuccess<void>(null);
  }

  @override
  Future<AppLockResult<void>> publishProjections(
    AppBlockProjectionSnapshot snapshot,
  ) async => const AppLockSuccess<void>(null);
  @override
  Future<AppLockResult<bool>> start(List<String> packageNames) async =>
      const AppLockSuccess<bool>(true);
  @override
  Future<AppLockResult<void>> stop() async => const AppLockSuccess<void>(null);
  @override
  Future<AppLockResult<void>> updatePackages(List<String> packageNames) async =>
      const AppLockSuccess<void>(null);
  @override
  Future<AppLockResult<void>> syncCompletion({
    required bool complete,
    required List<String> incompleteHabitNames,
  }) async => const AppLockSuccess<void>(null);
  @override
  Future<AppLockResult<bool>> isBatteryOptimized() async =>
      const AppLockSuccess<bool>(false);
  @override
  Future<AppLockResult<void>> openBatterySettings() async =>
      const AppLockSuccess<void>(null);
}

Habit _habit(String id, String name) => Habit(
  id: id,
  name: name,
  color: '#000000',
  icon: 'x',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Test',
  createdAt: DateTime(2026, 1, 1),
  isActive: true,
);
