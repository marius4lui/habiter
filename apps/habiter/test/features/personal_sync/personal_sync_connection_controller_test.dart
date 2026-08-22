import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/personal_sync/application/personal_sync_connection_controller.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_connection.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_operation.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_api_client.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_handoff.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_secure_vault.dart';

void main() {
  group('Personal Sync origin policy', () {
    test('accepts HTTPS and local-development HTTP only', () {
      expect(
        normalizePersonalSyncOrigin('https://sync.example.com/'),
        Uri.parse('https://sync.example.com'),
      );
      expect(
        normalizePersonalSyncOrigin('http://localhost:8787'),
        Uri.parse('http://localhost:8787'),
      );
      expect(
        normalizePersonalSyncOrigin('http://127.0.0.1:8787'),
        Uri.parse('http://127.0.0.1:8787'),
      );
      for (final rejected in <String>[
        'http://sync.example.com',
        'https://user@sync.example.com',
        'https://sync.example.com/path',
        'https://sync.example.com?token=secret',
        'javascript:alert(1)',
      ]) {
        expect(normalizePersonalSyncOrigin(rejected), isNull);
      }
    });
  });

  group('PersonalSyncConnectionController', () {
    late _Vault vault;
    late _Handoff handoff;
    late _Remote remote;
    late _Clock clock;
    late PersonalSyncConnectionController controller;

    setUp(() {
      vault = _Vault();
      handoff = _Handoff();
      remote = _Remote();
      clock = _Clock(DateTime.utc(2026, 8, 22, 12));
      controller = _controller(vault, handoff, remote, clock);
    });

    tearDown(() => controller.dispose());

    test(
      'persists PKCE and state before launching the external browser',
      () async {
        handoff.onLaunch = (_) {
          expect(vault.pending, isNotNull);
          expect(vault.pending!.codeVerifier, isNotEmpty);
          expect(vault.pending!.state, isNotEmpty);
        };

        await controller.initialize();
        expect(
          await controller.beginConnection(
            serverOrigin: 'https://sync.example.com',
            language: 'en',
          ),
          isTrue,
        );

        final authorization = handoff.launched.single;
        expect(authorization.scheme, 'https');
        expect(authorization.path, '/v1/authorize');
        expect(authorization.queryParameters['code_challenge'], isNotEmpty);
        expect(authorization.queryParameters['code_verifier'], isNull);
        expect(authorization.queryParameters['accessToken'], isNull);
        expect(authorization.queryParameters['refreshToken'], isNull);
        expect(authorization.queryParameters['state'], vault.pending!.state);
        expect(controller.isConnected, isFalse);
      },
    );

    test(
      'redeems exact callback once and exposes tab eligibility only after verification',
      () async {
        await _begin(controller, handoff, remote);
        expect(controller.isConnected, isFalse);

        final result = await controller.handleCallback(
          _callback(vault.pending!),
        );

        expect(result, PersonalSyncCallbackResult.completed);
        expect(controller.isConnected, isTrue);
        expect(remote.verifyCalls, 1);
        expect(vault.connection, isNotNull);
        expect(vault.pending, isNull);
        expect(
          await controller.handleCallback(_callbackFromState('replayed-state')),
          PersonalSyncCallbackResult.ignored,
        );
        expect(remote.redeemCalls, 1);
      },
    );

    test(
      'rejects wrong state, instance route, duplicate fields, and query leakage',
      () async {
        await _begin(controller, handoff, remote);
        final pending = vault.pending!;
        final cases = <Uri>[
          _callbackFromState('wrong_state_value_1234567890123456'),
          Uri.parse(
            'https://other.example/auth/callback#code=${_code()}&state=${pending.state}',
          ),
          Uri.parse(
            '${pending.redirectUri}#code=${_code()}&code=${_code()}&state=${pending.state}',
          ),
          Uri.parse(
            '${pending.redirectUri}?code=${_code()}#code=${_code()}&state=${pending.state}',
          ),
        ];

        for (final callback in cases) {
          expect(
            await controller.handleCallback(callback),
            PersonalSyncCallbackResult.rejected,
          );
        }
        expect(controller.isConnected, isFalse);
        expect(remote.redeemCalls, 0);
        expect(vault.pending, isNotNull);
      },
    );

    test('expires pending state and rejects late callbacks', () async {
      await _begin(controller, handoff, remote);
      final callback = _callback(vault.pending!);
      clock.value = clock.value.add(const Duration(minutes: 6));

      expect(
        await controller.handleCallback(callback),
        PersonalSyncCallbackResult.expired,
      );
      expect(vault.pending, isNull);
      expect(remote.redeemCalls, 0);
    });

    test(
      'canceled browser clears pending authorization without credentials',
      () async {
        handoff.launchError = StateError('canceled');
        await controller.initialize();

        expect(
          await controller.beginConnection(
            serverOrigin: 'https://sync.example.com',
            language: 'de',
          ),
          isFalse,
        );
        expect(vault.pending, isNull);
        expect(vault.connection, isNull);
        expect(
          controller.problem,
          PersonalSyncConnectionProblem.browserCanceled,
        );
      },
    );

    test(
      'consumes a cold callback and handles a warm callback through one channel',
      () async {
        final pending = _pending(clock.value);
        vault.pending = pending;
        remote.deviceId = pending.deviceId;
        handoff.initialCallback = _callback(pending);

        await controller.initialize();

        expect(controller.isConnected, isTrue);
        expect(remote.redeemCalls, 1);

        await controller.disconnect();
        final warmPending = _pending(clock.value, suffix: 'b');
        vault.pending = warmPending;
        remote.deviceId = warmPending.deviceId;
        controller.dispose();
        controller = _controller(vault, handoff, remote, clock);
        await controller.initialize();
        await handoff.deliver(_callback(warmPending));
        expect(controller.isConnected, isTrue);
        expect(remote.redeemCalls, 2);
      },
    );

    test('disconnect removes only secure connection state', () async {
      await _begin(controller, handoff, remote);
      await controller.handleCallback(_callback(vault.pending!));
      final localHabits = <String>['habit-a'];
      final remoteHabits = <String>['habit-b'];

      await controller.disconnect();

      expect(controller.isConnected, isFalse);
      expect(vault.connection, isNull);
      expect(vault.pending, isNull);
      expect(localHabits, <String>['habit-a']);
      expect(remoteHabits, <String>['habit-b']);
    });
  });
}

PersonalSyncConnectionController _controller(
  _Vault vault,
  _Handoff handoff,
  _Remote remote,
  Clock clock,
) => PersonalSyncConnectionController(
  vault: vault,
  remoteFactory: (_) => remote,
  handoff: handoff,
  clock: clock,
  randomBytes: (length) => Uint8List.fromList(
    List<int>.generate(length, (index) => (index + length) % 251),
  ),
);

Future<void> _begin(
  PersonalSyncConnectionController controller,
  _Handoff handoff,
  _Remote remote,
) async {
  await controller.initialize();
  expect(
    await controller.beginConnection(
      serverOrigin: 'https://sync.example.com',
      language: 'en',
    ),
    isTrue,
  );
  remote.deviceId = handoff.launched.single.queryParameters['device_id']!;
}

Uri _callback(PersonalSyncPendingAuthorization pending) =>
    Uri.parse('${pending.redirectUri}#code=${_code()}&state=${pending.state}');

Uri _callbackFromState(String state) => Uri.parse(
  'https://mobile.habiter.dev/auth/callback#code=${_code()}&state=$state',
);

String _code() => 'authorization_code_abcdefghijklmnopqrstuvwxyz0123456789';

PersonalSyncPendingAuthorization _pending(
  DateTime now, {
  String suffix = 'a',
}) => PersonalSyncPendingAuthorization(
  instanceOrigin: 'https://sync.example.com',
  instanceName: 'Private Sync',
  redirectUri: 'https://mobile.habiter.dev/auth/callback',
  state: 'state_${suffix}_abcdefghijklmnopqrstuvwxyz0123456789',
  codeVerifier: 'verifier_${suffix}_abcdefghijklmnopqrstuvwxyz0123456789',
  attemptId: 'attempt_${suffix}_abcdefghijklmnopqrstuvwxyz',
  deviceId: 'device_${suffix}_abcdefghijklmnopqrstuvwxyz',
  createdAt: now,
  expiresAt: now.add(const Duration(minutes: 5)),
);

final class _Clock implements Clock {
  _Clock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

final class _Vault implements PersonalSyncSecureVault {
  PersonalSyncPendingAuthorization? pending;
  PersonalSyncConnection? connection;

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
  final launched = <Uri>[];
  void Function(Uri)? onLaunch;
  Object? launchError;
  Uri? initialCallback;
  PersonalSyncCallbackHandler? handler;

  @override
  String get redirectUri => 'https://mobile.habiter.dev/auth/callback';
  @override
  bool get supported => true;
  @override
  Future<void> dispose() async => handler = null;
  @override
  Future<void> initialize(PersonalSyncCallbackHandler value) async {
    handler = value;
    if (initialCallback case final callback?) {
      initialCallback = null;
      await value(callback);
    }
  }

  @override
  Future<void> launch(Uri authorizationUri) async {
    launched.add(authorizationUri);
    onLaunch?.call(authorizationUri);
    if (launchError case final error?) throw error;
  }

  Future<void> deliver(Uri callback) async => handler!.call(callback);
}

final class _Remote implements PersonalSyncRemote {
  String deviceId = 'device_a_abcdefghijklmnopqrstuvwxyz';
  int redeemCalls = 0;
  int verifyCalls = 0;

  @override
  Future<PersonalSyncInstanceInfo> instanceInfo() async =>
      const PersonalSyncInstanceInfo(
        protocolVersion: 1,
        name: 'Private Sync',
        baseUrl: 'https://sync.example.com',
        initialized: true,
      );

  @override
  Future<PersonalSyncTokenPair> redeem({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String attemptId,
  }) async {
    redeemCalls += 1;
    return _pair();
  }

  @override
  Future<PersonalSyncTokenPair> refresh(String refreshToken) async => _pair();

  PersonalSyncTokenPair _pair() => PersonalSyncTokenPair(
    accessToken: 'access-token-value',
    expiresIn: 3600,
    refreshToken: 'refresh-token-value',
    refreshExpiresAt: DateTime.utc(2026, 9, 22),
    deviceId: deviceId,
  );

  @override
  Future<String> verifyDevice(String accessToken) async {
    verifyCalls += 1;
    return deviceId;
  }

  @override
  Future<void> revokeAll(String accessToken) async {}
  @override
  Future<void> push(
    List<PersonalSyncOperation> operations,
    String accessToken,
  ) async {}
  @override
  Future<PersonalSyncPullPage> pull({
    required PersonalSyncServerCursor? cursor,
    required int limit,
    required String accessToken,
  }) => throw UnimplementedError();
  @override
  Future<PersonalSyncSnapshot> snapshot(String accessToken) =>
      throw UnimplementedError();
  @override
  void close() {}
}
