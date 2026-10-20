import 'dart:async';

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

  test(
    'restored discovery is recoverable instead of an idle spinner',
    () async {
      final repository = KeyValueAppBlockOnboardingRepository(
        InMemoryKeyValueStore(),
      );
      await repository.save(
        const AppBlockOnboardingState(stage: AppBlockOnboardingStage.discovery),
      );
      final controller = _controller(repository, _Gateway());
      await controller.initialize();
      expect(controller.loading, isFalse);
      expect(controller.diagnostic, isNotNull);
    },
  );

  test('discovery timeout releases loading and supports retry', () async {
    final repository = KeyValueAppBlockOnboardingRepository(
      InMemoryKeyValueStore(),
    );
    final pending = Completer<AppLockResult<List<AppUsageRecord>>>();
    final gateway = _Gateway()..usageResult = () => pending.future;
    final controller = _controller(repository, gateway);
    await controller.initialize();
    await controller.acceptOffer();
    await controller.discover();
    expect(controller.loading, isFalse);
    expect(controller.diagnostic, contains('timed out'));
    expect(controller.state.stage, AppBlockOnboardingStage.discovery);
    expect(
      (await repository.load())?.stage,
      AppBlockOnboardingStage.usageEducation,
    );

    gateway.usageResult = null;
    await controller.discover();
    expect(controller.state.stage, AppBlockOnboardingStage.selection);
    expect(controller.diagnostic, isNull);
    pending.complete(const AppLockSuccess<List<AppUsageRecord>>([]));
    await Future<void>.delayed(Duration.zero);
    expect(controller.candidates, isNotEmpty);
  });

  test('duplicate discovery calls do not repeat platform work', () async {
    final gateway = _Gateway();
    final controller = _controller(
      KeyValueAppBlockOnboardingRepository(InMemoryKeyValueStore()),
      gateway,
    );
    await controller.initialize();
    await Future.wait([controller.discover(), controller.discover()]);
    expect(gateway.usageCalls, 1);
  });

  test(
    'thrown platform and catalog errors leave discovery recoverable',
    () async {
      final gateway = _Gateway()
        ..usageResult = () async => throw StateError('private detail');
      final controller = _controller(
        KeyValueAppBlockOnboardingRepository(InMemoryKeyValueStore()),
        gateway,
      );
      await controller.initialize();
      await controller.discover();
      expect(controller.loading, isFalse);
      expect(controller.diagnostic, isNotNull);
      expect(controller.diagnostic, isNot(contains('private detail')));

      final catalogController = AppBlockOnboardingController(
        repository: KeyValueAppBlockOnboardingRepository(
          InMemoryKeyValueStore(),
        ),
        gateway: _Gateway(),
        loadCatalog: () async => throw StateError('bad catalog'),
      );
      await catalogController.initialize();
      await catalogController.discover();
      expect(catalogController.loading, isFalse);
      expect(catalogController.diagnostic, isNotNull);
    },
  );

  test('late discovery cannot undo Maybe later', () async {
    final pending = Completer<AppLockResult<List<AppUsageRecord>>>();
    final gateway = _Gateway()..usageResult = () => pending.future;
    final repository = KeyValueAppBlockOnboardingRepository(
      InMemoryKeyValueStore(),
    );
    final controller = _controller(repository, gateway);
    await controller.initialize();
    final discovery = controller.discover();
    await controller.defer();
    pending.complete(const AppLockSuccess<List<AppUsageRecord>>([]));
    await discovery;
    expect(controller.loading, isFalse);
    expect(controller.state.stage, AppBlockOnboardingStage.deferred);
    expect((await repository.load())?.stage, AppBlockOnboardingStage.deferred);
  });

  test('late selection save cannot overwrite deferred setup', () async {
    final repository = _DelayedRepository();
    final controller = _controller(repository, _Gateway());
    await controller.initialize();
    await controller.acceptOffer();
    final discovery = controller.discover();
    await repository.selectionStarted.future;
    await controller.defer();
    expect(repository.saved?.stage, AppBlockOnboardingStage.deferred);
    repository.selectionWrite.complete();
    await discovery;
    expect(repository.saved?.stage, AppBlockOnboardingStage.deferred);
    expect(controller.state.stage, AppBlockOnboardingStage.deferred);
  });

  test(
    'timed out selection save restores the last safe persisted stage',
    () async {
      final repository = _DelayedRepository();
      final controller = _controller(repository, _Gateway());
      await controller.initialize();
      await controller.acceptOffer();
      await controller.discover();
      expect(controller.diagnostic, contains('timed out'));
      repository.selectionWrite.complete();
      await Future<void>.delayed(Duration.zero);
      expect(repository.saved?.stage, AppBlockOnboardingStage.usageEducation);
      expect(controller.state.stage, AppBlockOnboardingStage.discovery);
    },
  );

  for (final stalled in [false, true]) {
    test(
      'Maybe later exits even when persistence ${stalled ? 'stalls' : 'throws'}',
      () async {
        final repository = _DelayedRepository()
          ..deferredWrite = stalled
              ? Completer<void>().future
              : Future<void>.value();
        repository.failDeferred = !stalled;
        final pending = Completer<AppLockResult<List<AppUsageRecord>>>();
        final controller = _controller(
          repository,
          _Gateway()..usageResult = () => pending.future,
        );
        await controller.initialize();
        final discovery = controller.discover();
        final exit = controller.defer();
        expect(controller.state.stage, AppBlockOnboardingStage.deferred);
        expect(controller.loading, isFalse);
        await exit;
        expect(controller.diagnostic, contains('could not be saved'));
        pending.complete(const AppLockSuccess<List<AppUsageRecord>>([]));
        await discovery;
        expect(controller.state.stage, AppBlockOnboardingStage.deferred);
      },
    );
  }

  test('obsolete setup save cannot restore older in-memory state', () async {
    final repository = _DelayedRepository()..usageWrite = Completer<void>();
    final controller = _controller(repository, _Gateway());
    await controller.initialize();
    final earlier = controller.acceptOffer();
    await repository.usageStarted.future;
    await controller.reconsider();
    repository.usageWrite!.complete();
    await earlier;
    expect(controller.state.stage, AppBlockOnboardingStage.reconsider);
    expect(repository.saved?.stage, AppBlockOnboardingStage.reconsider);
  });

  test('disposed discovery ignores late results', () async {
    final pending = Completer<AppLockResult<List<AppUsageRecord>>>();
    final controller = _controller(
      KeyValueAppBlockOnboardingRepository(InMemoryKeyValueStore()),
      _Gateway()..usageResult = () => pending.future,
    );
    await controller.initialize();
    final discovery = controller.discover();
    controller.dispose();
    pending.complete(const AppLockSuccess<List<AppUsageRecord>>([]));
    await discovery;
  });
}

AppBlockOnboardingController _controller(
  AppBlockOnboardingRepository repository,
  AppLockGateway gateway,
) => AppBlockOnboardingController(
  repository: repository,
  gateway: gateway,
  discoveryTimeout: const Duration(milliseconds: 30),
  loadCatalog: () async =>
      const LocalDistractionCatalog(<String, DistractionCatalogEntry>{}),
  now: () => DateTime(2026, 8, 19),
);

final class _Gateway implements AppLockGateway {
  _Gateway({this.usageAccess = false});

  final bool usageAccess;
  int usageCalls = 0;
  Future<AppLockResult<List<AppUsageRecord>>> Function()? usageResult;

  @override
  bool get isSupported => true;

  @override
  Future<AppLockResult<List<LockedApp>>> installedApps() async =>
      const AppLockSuccess<List<LockedApp>>(<LockedApp>[
        LockedApp(packageName: 'social.example', appName: 'Social'),
      ]);

  @override
  Future<AppLockResult<List<AppUsageRecord>>> recentUsage() async {
    usageCalls++;
    if (usageResult != null) return usageResult!();
    return const AppLockSuccess<List<AppUsageRecord>>(<AppUsageRecord>[
      AppUsageRecord(
        packageName: 'social.example',
        appName: 'Social',
        foregroundDuration: Duration(hours: 1),
        lastUsed: null,
      ),
    ]);
  }

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

final class _DelayedRepository implements AppBlockOnboardingRepository {
  AppBlockOnboardingState? saved;
  final selectionWrite = Completer<void>();
  final selectionStarted = Completer<void>();
  final usageStarted = Completer<void>();
  Completer<void>? usageWrite;
  Future<void>? deferredWrite;
  bool failDeferred = false;

  @override
  Future<AppBlockOnboardingState?> load() async => saved;

  @override
  Future<void> save(AppBlockOnboardingState state) async {
    if (state.stage == AppBlockOnboardingStage.usageEducation &&
        usageWrite != null) {
      if (!usageStarted.isCompleted) usageStarted.complete();
      await usageWrite!.future;
    }
    if (state.stage == AppBlockOnboardingStage.selection) {
      if (!selectionStarted.isCompleted) selectionStarted.complete();
      await selectionWrite.future;
    }
    if (state.stage == AppBlockOnboardingStage.deferred) {
      await deferredWrite;
      if (failDeferred) throw StateError('storage unavailable');
    }
    saved = state;
  }
}
