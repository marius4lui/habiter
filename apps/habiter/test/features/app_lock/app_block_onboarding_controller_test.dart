import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/application/app_block_onboarding_controller.dart';
import 'package:habiter/features/app_lock/application/app_block_onboarding_state.dart';
import 'package:habiter/features/app_lock/domain/app_block_candidate.dart';
import 'package:habiter/features/app_lock/domain/app_block_projection.dart';
import 'package:habiter/features/app_lock/domain/app_lock_gateway.dart';
import 'package:habiter/features/app_lock/infrastructure/app_block_onboarding_repository.dart';
import 'package:habiter/features/app_lock/infrastructure/local_distraction_catalog.dart';
import 'package:habiter/models/locked_app.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('decline is persisted as reconsider then a terminal skip', () async {
    final repository = KeyValueAppBlockOnboardingRepository(
      InMemoryKeyValueStore(),
    );
    final controller = _controller(repository, _Gateway());
    await controller.initialize();

    await controller.reconsider();
    expect(controller.state.stage, AppBlockOnboardingStage.reconsider);
    await controller.skip();

    expect((await repository.load())?.result, AppBlockOnboardingResult.skipped);
  });

  test(
    'permission return advances from education using real permission state',
    () async {
      final repository = KeyValueAppBlockOnboardingRepository(
        InMemoryKeyValueStore(),
      );
      final gateway = _Gateway(usageAccess: true);
      final controller = _controller(repository, gateway);
      await controller.initialize();
      await controller.acceptOffer();

      await controller.reconcilePermissions();

      expect(controller.state.stage, AppBlockOnboardingStage.selection);
      expect(
        (await repository.load())?.stage,
        AppBlockOnboardingStage.selection,
      );
    },
  );
}

AppBlockOnboardingController _controller(
  AppBlockOnboardingRepository repository,
  AppLockGateway gateway,
) => AppBlockOnboardingController(
  repository: repository,
  gateway: gateway,
  loadCatalog: () async =>
      const LocalDistractionCatalog(<String, DistractionCatalogEntry>{}),
  now: () => DateTime(2026, 8, 19),
);

final class _Gateway implements AppLockGateway {
  _Gateway({this.usageAccess = false});

  final bool usageAccess;

  @override
  bool get isSupported => true;

  @override
  Future<AppLockResult<List<LockedApp>>> installedApps() async =>
      const AppLockSuccess<List<LockedApp>>(<LockedApp>[
        LockedApp(packageName: 'social.example', appName: 'Social'),
      ]);

  @override
  Future<AppLockResult<List<AppUsageRecord>>> recentUsage() async =>
      const AppLockSuccess<List<AppUsageRecord>>(<AppUsageRecord>[
        AppUsageRecord(
          packageName: 'social.example',
          appName: 'Social',
          foregroundDuration: Duration(hours: 1),
          lastUsed: null,
        ),
      ]);

  @override
  Future<AppLockResult<AppLockPermissionSnapshot>> permissions() async =>
      AppLockSuccess<AppLockPermissionSnapshot>(
        AppLockPermissionSnapshot(usageAccess: usageAccess, overlay: false),
      );

  @override
  Future<AppLockResult<void>> publishProjections(
    AppBlockProjectionSnapshot snapshot,
  ) async => const AppLockSuccess<void>(null);

  @override
  Future<AppLockResult<void>> requestOverlay() async =>
      const AppLockSuccess<void>(null);

  @override
  Future<AppLockResult<void>> requestUsageAccess() async =>
      const AppLockSuccess<void>(null);

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
