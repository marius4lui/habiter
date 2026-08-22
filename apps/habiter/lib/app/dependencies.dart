import 'package:flutter/foundation.dart';

import '../core/design_system/haptics.dart';
import '../core/ids/id_generator.dart';
import '../core/persistence/key_value_store.dart';
import '../core/persistence/legacy_storage_migrator.dart';
import '../core/persistence/shared_preferences_key_value_store.dart';
import '../core/time/clock.dart';
import '../features/habits/application/habit_repository.dart';
import '../features/habits/data/key_value_habit_repository.dart';
import '../features/personal_sync/application/personal_sync_connection_controller.dart';
import '../features/personal_sync/application/personal_sync_engine.dart';
import '../features/personal_sync/infrastructure/personal_sync_api_client.dart';
import '../features/personal_sync/infrastructure/personal_sync_handoff.dart';
import '../features/personal_sync/infrastructure/personal_sync_secure_vault.dart';
import '../features/personal_sync/infrastructure/syncing_habit_repository.dart';
import '../features/updates/application/update_controller.dart';
import '../features/updates/data/signed_manifest_client.dart';
import '../features/updates/data/update_local_repository.dart';
import '../features/updates/infrastructure/method_channel_manifest_transport.dart';
import '../features/updates/infrastructure/method_channel_update_platform_gateway.dart';

typedef StartupTask = Future<void> Function();

final class AppDependencies {
  AppDependencies({
    required this.store,
    required this.clock,
    this.ids = const UuidIdGenerator(),
    this.haptics = const SystemHapticGateway(),
    required this.migrateStorage,
    required this.verifyRepository,
    required this.initializeOptionalServices,
    UpdateController? updateController,
    PersonalSyncConnectionController? personalSyncConnectionController,
    PersonalSyncEngine? personalSyncEngine,
    HabitRepository? habitRepository,
  }) : habitRepository = habitRepository ?? KeyValueHabitRepository(store),
       personalSyncEngine =
           personalSyncEngine ??
           PersonalSyncEngine(
             store: store,
             remoteFactory: (origin) => HttpPersonalSyncRemote(origin),
             clock: clock,
           ),
       personalSyncConnectionController =
           personalSyncConnectionController ??
           PersonalSyncConnectionController(
             vault: const FlutterPersonalSyncSecureVault(),
             remoteFactory: (origin) => HttpPersonalSyncRemote(origin),
             handoff: PlatformPersonalSyncHandoff(),
             clock: clock,
           ),
       updateController =
           updateController ??
           UpdateController(
             repository: UpdateLocalRepository(store),
             client: SignedManifestClient(),
             verifier: ManifestVerifier(publicKeyRing: const {}),
             platform: const MethodChannelUpdatePlatformGateway(),
             clock: clock,
           );

  factory AppDependencies.production() {
    final store = SharedPreferencesKeyValueStore();
    const clock = SystemClock();
    final engine = PersonalSyncEngine(
      store: store,
      remoteFactory: (origin) => HttpPersonalSyncRemote(origin),
      clock: clock,
    );
    final repository = SyncingHabitRepository(
      delegate: KeyValueHabitRepository(
        store,
        transactionalSidecarKeys: const <String>{
          PersonalSyncEngine.storageKey,
          PersonalSyncEngine.recoveryKey,
        },
      ),
      recorder: engine,
    );
    engine.attachRepository(repository);
    late final PersonalSyncConnectionController personalSyncConnection;
    personalSyncConnection = PersonalSyncConnectionController(
      vault: const FlutterPersonalSyncSecureVault(),
      remoteFactory: (origin) => HttpPersonalSyncRemote(origin),
      handoff: PlatformPersonalSyncHandoff(),
      clock: clock,
      syncTrigger: engine.synchronize,
      onConnectionChanged: (connection) => engine.configureConnection(
        connection,
        requestSync: personalSyncConnection.syncNow,
      ),
    );
    final updates = UpdateController(
      repository: UpdateLocalRepository(store),
      client: SignedManifestClient(
        transport: defaultTargetPlatform == TargetPlatform.android && !kIsWeb
            ? const MethodChannelManifestTransport()
            : null,
      ),
      verifier: ManifestVerifier.fromEnvironment(),
      platform: const MethodChannelUpdatePlatformGateway(),
      clock: clock,
    );
    return AppDependencies(
      store: store,
      clock: clock,
      habitRepository: repository,
      personalSyncEngine: engine,
      personalSyncConnectionController: personalSyncConnection,
      updateController: updates,
      migrateStorage: () async {
        await migratorFor(store, clock).migrate();
      },
      verifyRepository: () async {
        await repository.load();
      },
      // Integrations are user-initiated. Keeping this task explicit prevents a
      // network or platform plugin from silently becoming a startup dependency.
      initializeOptionalServices: () async {},
    );
  }

  final KeyValueStore store;
  final Clock clock;
  final IdGenerator ids;
  final HapticGateway haptics;
  final HabitRepository habitRepository;
  final UpdateController updateController;
  final PersonalSyncConnectionController personalSyncConnectionController;
  final PersonalSyncEngine personalSyncEngine;
  final StartupTask migrateStorage;
  final StartupTask verifyRepository;
  final StartupTask initializeOptionalServices;

  static LegacyStorageMigrator migratorFor(KeyValueStore store, Clock clock) =>
      LegacyStorageMigrator(store: store, clock: clock);
}
