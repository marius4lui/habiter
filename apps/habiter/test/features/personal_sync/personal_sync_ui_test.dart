import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/persistence/storage_envelope.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/personal_sync/application/personal_sync_connection_controller.dart';
import 'package:habiter/features/personal_sync/application/personal_sync_engine.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_connection.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_contract.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_operation.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_replica.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_api_client.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_handoff.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_secure_vault.dart';
import 'package:habiter/features/personal_sync/infrastructure/syncing_habit_repository.dart';
import 'package:habiter/features/personal_sync/presentation/personal_sync_screen.dart';
import 'package:habiter/features/personal_sync/presentation/personal_sync_settings_card.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('setup is localized and contains only a server URL field', (
    tester,
  ) async {
    final controller = _controller();
    await controller.initialize();
    addTearDown(controller.dispose);

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      await tester.pumpWidget(
        _fixture(
          controller,
          locale: locale,
          child: const Scaffold(
            body: SingleChildScrollView(child: PersonalSyncSettingsCard()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(
        find.textContaining(
          locale.languageCode == 'de' ? 'Passwort' : 'password',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('personal-sync-connect')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('connected diagnostics remain usable at 200 percent text', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 22, 12);
    final controller = _controller(
      connection: PersonalSyncConnection(
        instanceOrigin: 'https://sync.example.com',
        instanceName: 'Private Sync',
        deviceId: 'phone-a',
        accessToken: 'access-secret',
        accessExpiresAt: now.add(const Duration(hours: 1)),
        refreshToken: 'refresh-secret',
        refreshExpiresAt: now.add(const Duration(days: 30)),
        connectedAt: now,
        lastSuccessAt: now,
      ),
    );
    await controller.initialize();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _fixture(
        controller,
        locale: const Locale('de'),
        textScaler: const TextScaler.linear(2),
        child: const Scaffold(body: PersonalSyncScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Private Sync'), findsOneWidget);
    expect(find.textContaining('access-secret'), findsNothing);
    expect(find.textContaining('refresh-secret'), findsNothing);
    expect(find.byKey(const Key('personal-sync-now')), findsOneWidget);
    expect(find.byKey(const Key('personal-sync-disconnect')), findsOneWidget);
    expect(find.byKey(const Key('personal-sync-revoke-all')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial merge action is explicit, localized, and accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026, 8, 22, 12);
    final connection = PersonalSyncConnection(
      instanceOrigin: 'https://sync.example.com',
      instanceName: 'Private Sync',
      deviceId: 'phone-a',
      accessToken: 'access-secret',
      accessExpiresAt: now.add(const Duration(hours: 1)),
      refreshToken: 'refresh-secret',
      refreshExpiresAt: now.add(const Duration(days: 30)),
      connectedAt: now,
      lastSuccessAt: now,
    );
    final controller = _controller(connection: connection);
    await controller.initialize();
    final store = InMemoryKeyValueStore();
    await store.write(
      StorageEnvelope.storageKey,
      StorageEnvelope(
        schemaVersion: 1,
        migratedAt: now,
        data: const <String, Object?>{},
      ).toJson(),
    );
    final remoteOperation = _remoteHabitOperation();
    final remoteState = PersonalSyncReplica.empty()
        .apply(remoteOperation)
        .replica;
    final remote = _Remote(
      snapshotValue: PersonalSyncSnapshot(
        cursor: PersonalSyncServerCursor(generation: 'epoch-a', offset: 1),
        entities: remoteState.entities.values.toList(),
      ),
    );
    final engine = PersonalSyncEngine(
      store: store,
      remoteFactory: (_) => remote,
      clock: _Clock(),
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
    await engine.initialize();
    await repository.transact((draft) => draft.upsertHabit(_habit('Local')));
    engine.configureConnection(connection);
    await expectLater(engine.synchronize(connection), throwsException);
    addTearDown(controller.dispose);
    addTearDown(engine.dispose);

    await tester.pumpWidget(
      _fixture(
        controller,
        engine: engine,
        locale: const Locale('de'),
        textScaler: const TextScaler.linear(2),
        child: const Scaffold(body: PersonalSyncScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('personal-sync-reconciliation')),
      findsOneWidget,
    );
    expect(find.text('Erste Zusammenführung prüfen'), findsOneWidget);
    expect(
      find.byKey(const Key('personal-sync-confirm-reconciliation')),
      findsOneWidget,
    );
    expect(find.textContaining('access-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _fixture(
  PersonalSyncConnectionController controller, {
  required Locale locale,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
  PersonalSyncEngine? engine,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: controller),
    if (engine != null)
      ChangeNotifierProvider<PersonalSyncEngine?>.value(value: engine),
  ],
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: app!,
    ),
    home: child,
  ),
);

PersonalSyncConnectionController _controller({
  PersonalSyncConnection? connection,
}) => PersonalSyncConnectionController(
  vault: _Vault(connection),
  remoteFactory: (_) => _Remote(),
  handoff: _Handoff(),
  clock: _Clock(),
);

final class _Vault implements PersonalSyncSecureVault {
  _Vault(this.connection);
  PersonalSyncConnection? connection;
  PersonalSyncPendingAuthorization? pending;
  @override
  Future<void> deleteConnection() async => connection = null;
  @override
  Future<void> deletePending() async => pending = null;
  @override
  Future<PersonalSyncConnection?> readConnection() async => connection;
  @override
  Future<PersonalSyncPendingAuthorization?> readPending() async => pending;
  @override
  Future<void> writeConnection(PersonalSyncConnection value) async =>
      connection = value;
  @override
  Future<void> writePending(PersonalSyncPendingAuthorization value) async =>
      pending = value;
}

final class _Handoff implements PersonalSyncHandoff {
  @override
  String get redirectUri => 'https://mobile.habiter.dev/auth/callback';
  @override
  bool get supported => true;
  @override
  Future<void> dispose() async {}
  @override
  Future<void> initialize(PersonalSyncCallbackHandler handler) async {}
  @override
  Future<void> launch(Uri authorizationUri) async {}
}

final class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 8, 22, 12);
}

final class _Remote implements PersonalSyncRemote {
  _Remote({PersonalSyncSnapshot? snapshotValue})
    : snapshotValue =
          snapshotValue ??
          PersonalSyncSnapshot(
            cursor: PersonalSyncServerCursor(generation: 'epoch-a', offset: 0),
            entities: const <PersonalSyncEntityState>[],
          );

  final PersonalSyncSnapshot snapshotValue;
  @override
  void close() {}
  @override
  Future<PersonalSyncInstanceInfo> instanceInfo() => throw UnimplementedError();
  @override
  Future<PersonalSyncTokenPair> redeem({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String attemptId,
  }) => throw UnimplementedError();
  @override
  Future<PersonalSyncTokenPair> refresh(String refreshToken) =>
      throw UnimplementedError();
  @override
  Future<void> revokeAll(String accessToken) => throw UnimplementedError();
  @override
  Future<String> verifyDevice(String accessToken) => throw UnimplementedError();
  @override
  Future<void> push(
    List<PersonalSyncOperation> operations,
    String accessToken,
  ) => throw UnimplementedError();
  @override
  Future<PersonalSyncPullPage> pull({
    required PersonalSyncServerCursor? cursor,
    required int limit,
    required String accessToken,
  }) async => PersonalSyncPullPage(
    operations: const <PersonalSyncOperation>[],
    cursor:
        cursor ?? PersonalSyncServerCursor(generation: 'epoch-a', offset: 0),
    headOffset: cursor?.offset ?? 0,
    compactionFloor: 0,
    requiresSnapshot: false,
    recoveryReason: 'none',
  );
  @override
  Future<PersonalSyncSnapshot> snapshot(String accessToken) async =>
      snapshotValue;
}

Habit _habit(String name) => Habit(
  id: 'habit-a',
  name: name,
  description: null,
  color: '#6750A4',
  icon: 'walk',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  customDays: null,
  createdAt: DateTime.utc(2026, 8, 22),
  isActive: true,
);

PersonalSyncOperation _remoteHabitOperation() => PersonalSyncOperation(
  kind: PersonalSyncOperationKind.create,
  revision: PersonalSyncRevision(deviceId: 'remote-phone', sequence: 1),
  document: PersonalSyncEntityDocument(
    entityId: PersonalSyncEntityId.habit('habit-a'),
    deleted: false,
    payload: Map<String, Object?>.from(_habit('Remote').toMap()),
  ),
  changedFields: _habit('Remote').toMap().keys,
);
