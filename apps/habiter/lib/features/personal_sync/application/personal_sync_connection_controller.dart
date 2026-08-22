import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/time/clock.dart';
import '../domain/personal_sync_connection.dart';
import '../domain/personal_sync_contract.dart';
import '../infrastructure/personal_sync_api_client.dart';
import '../infrastructure/personal_sync_handoff.dart';
import '../infrastructure/personal_sync_secure_vault.dart';

typedef PersonalSyncBytes = Uint8List Function(int length);
typedef PersonalSyncTrigger =
    Future<void> Function(PersonalSyncConnection connection);
typedef PersonalSyncConnectionChanged =
    void Function(PersonalSyncConnection? connection);

final class PersonalSyncConnectionController extends ChangeNotifier {
  PersonalSyncConnectionController({
    required PersonalSyncSecureVault vault,
    required PersonalSyncRemoteFactory remoteFactory,
    required PersonalSyncHandoff handoff,
    required Clock clock,
    PersonalSyncBytes? randomBytes,
    PersonalSyncTrigger? syncTrigger,
    PersonalSyncConnectionChanged? onConnectionChanged,
  }) : _vault = vault,
       _remoteFactory = remoteFactory,
       _handoff = handoff,
       _clock = clock,
       _randomBytes = randomBytes ?? _secureRandomBytes,
       _syncTrigger = syncTrigger,
       _onConnectionChanged = onConnectionChanged;

  final PersonalSyncSecureVault _vault;
  final PersonalSyncRemoteFactory _remoteFactory;
  final PersonalSyncHandoff _handoff;
  final Clock _clock;
  final PersonalSyncBytes _randomBytes;
  final PersonalSyncTrigger? _syncTrigger;
  final PersonalSyncConnectionChanged? _onConnectionChanged;

  PersonalSyncConnectionPhase _phase = PersonalSyncConnectionPhase.loading;
  PersonalSyncConnectionProblem? _problem;
  PersonalSyncPendingAuthorization? _pending;
  PersonalSyncConnection? _connection;
  bool _initialized = false;
  bool _callbackInFlight = false;

  PersonalSyncConnectionPhase get phase => _phase;
  PersonalSyncConnectionProblem? get problem => _problem;
  bool get initialized => _initialized;
  bool get supported => _handoff.supported;
  bool get isConnected => _connection != null;
  bool get hasPendingAuthorization => _pending != null;
  String? get instanceOrigin => _connection?.instanceOrigin;
  String? get instanceName => _connection?.instanceName;
  String? get deviceId => _connection?.deviceId;
  DateTime? get connectedAt => _connection?.connectedAt;
  DateTime? get lastSuccessAt => _connection?.lastSuccessAt;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _connection = await _vault.readConnection();
      _pending = await _vault.readPending();
      if (_connection != null && _pending != null) {
        _pending = null;
        await _vault.deletePending();
      } else if (_pending case final pending?
          when pending.redeeming ||
              !_clock.now().toUtc().isBefore(pending.expiresAt)) {
        _pending = null;
        await _vault.deletePending();
      }
      _phase = _connection == null
          ? PersonalSyncConnectionPhase.disconnected
          : PersonalSyncConnectionPhase.connected;
    } on Object {
      await _clearSecureState();
      _phase = PersonalSyncConnectionPhase.disconnected;
    }
    _initialized = true;
    _onConnectionChanged?.call(_connection);
    notifyListeners();
    try {
      await _handoff.initialize((callback) async {
        await handleCallback(callback);
      });
    } on Object {
      _problem = PersonalSyncConnectionProblem.unavailable;
      if (_connection == null) _phase = PersonalSyncConnectionPhase.error;
      notifyListeners();
    }
  }

  Future<bool> beginConnection({
    required String serverOrigin,
    required String language,
  }) async {
    if (!_initialized ||
        !_handoff.supported ||
        _phase == PersonalSyncConnectionPhase.authorizing ||
        _phase == PersonalSyncConnectionPhase.checking) {
      return false;
    }
    final origin = normalizePersonalSyncOrigin(serverOrigin);
    if (origin == null) {
      _setProblem(PersonalSyncConnectionProblem.invalidOrigin);
      return false;
    }
    _problem = null;
    _phase = PersonalSyncConnectionPhase.authorizing;
    notifyListeners();
    PersonalSyncRemote? remote;
    try {
      remote = _remoteFactory(origin);
      final info = await remote.instanceInfo();
      if (!info.initialized) {
        throw const PersonalSyncRemoteException('not_initialized');
      }
      if (PersonalSyncVersions.negotiateProtocol(info.protocolVersion) !=
          PersonalSyncCompatibility.compatible) {
        throw const PersonalSyncRemoteException('incompatible');
      }
      final now = _clock.now().toUtc();
      final verifier = _token(64);
      final pending = PersonalSyncPendingAuthorization(
        instanceOrigin: origin.origin,
        instanceName: info.name,
        redirectUri: _handoff.redirectUri,
        state: _token(32),
        codeVerifier: verifier,
        attemptId: _token(18),
        deviceId: _token(18),
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
      );
      _pending = pending;
      await _vault.writePending(pending);
      final authorization = origin
          .resolve('/v1/authorize')
          .replace(
            queryParameters: <String, String>{
              'response_type': 'code',
              'redirect_uri': pending.redirectUri,
              'code_challenge': _base64Url(
                Uint8List.fromList(
                  sha256.convert(ascii.encode(verifier)).bytes,
                ),
              ),
              'state': pending.state,
              'attempt_id': pending.attemptId,
              'device_id': pending.deviceId,
              'lang': language == 'de' ? 'de' : 'en',
            },
          );
      await _handoff.launch(authorization);
      return true;
    } on PersonalSyncRemoteException catch (error) {
      await _discardPending();
      _setProblem(switch (error.code) {
        'incompatible' => PersonalSyncConnectionProblem.incompatible,
        'network' => PersonalSyncConnectionProblem.network,
        _ => PersonalSyncConnectionProblem.unavailable,
      });
      return false;
    } on Object {
      if (_connection == null || _pending != null) await _discardPending();
      _setProblem(PersonalSyncConnectionProblem.browserCanceled);
      return false;
    } finally {
      remote?.close();
      if (_phase == PersonalSyncConnectionPhase.authorizing &&
          _pending == null) {
        _phase = _connection == null
            ? PersonalSyncConnectionPhase.error
            : PersonalSyncConnectionPhase.connected;
        notifyListeners();
      }
    }
  }

  Future<PersonalSyncCallbackResult> handleCallback(Uri callback) async {
    if (_callbackInFlight) return PersonalSyncCallbackResult.ignored;
    final pending = _pending;
    if (pending == null) return PersonalSyncCallbackResult.ignored;
    if (!_matchesCallback(callback, pending) || callback.query.isNotEmpty) {
      _setProblem(
        PersonalSyncConnectionProblem.callbackRejected,
        preservePhase: true,
      );
      return PersonalSyncCallbackResult.rejected;
    }
    final values = Uri(query: callback.fragment).queryParametersAll;
    if (values.length != 2 ||
        values.keys.toSet().difference(const <String>{
          'code',
          'state',
        }).isNotEmpty ||
        values.values.any((items) => items.length != 1)) {
      _setProblem(
        PersonalSyncConnectionProblem.callbackRejected,
        preservePhase: true,
      );
      return PersonalSyncCallbackResult.rejected;
    }
    final code = values['code']?.single;
    final state = values['state']?.single;
    if (!_opaque(code, 32, 512) ||
        !_opaque(state, 16, 256) ||
        !_constantTimeEquals(state!, pending.state)) {
      _setProblem(
        PersonalSyncConnectionProblem.callbackRejected,
        preservePhase: true,
      );
      return PersonalSyncCallbackResult.rejected;
    }
    if (!_clock.now().toUtc().isBefore(pending.expiresAt)) {
      await _discardPending();
      _setProblem(PersonalSyncConnectionProblem.callbackExpired);
      return PersonalSyncCallbackResult.expired;
    }

    _callbackInFlight = true;
    _phase = PersonalSyncConnectionPhase.authorizing;
    _problem = null;
    notifyListeners();
    final redeeming = pending.markRedeeming();
    _pending = redeeming;
    PersonalSyncRemote? remote;
    try {
      await _vault.writePending(redeeming);
      remote = _remoteFactory(Uri.parse(pending.instanceOrigin));
      final pair = await remote.redeem(
        code: code!,
        codeVerifier: pending.codeVerifier,
        redirectUri: pending.redirectUri,
        attemptId: pending.attemptId,
      );
      if (pair.deviceId != pending.deviceId ||
          await remote.verifyDevice(pair.accessToken) != pending.deviceId) {
        throw const PersonalSyncRemoteException('device_mismatch');
      }
      final now = _clock.now().toUtc();
      final connection = PersonalSyncConnection(
        instanceOrigin: pending.instanceOrigin,
        instanceName: pending.instanceName,
        deviceId: pending.deviceId,
        accessToken: pair.accessToken,
        accessExpiresAt: now.add(Duration(seconds: pair.expiresIn)),
        refreshToken: pair.refreshToken,
        refreshExpiresAt: pair.refreshExpiresAt,
        connectedAt: now,
        lastSuccessAt: now,
      );
      await _vault.writeConnection(connection);
      await _vault.deletePending();
      _connection = connection;
      _onConnectionChanged?.call(connection);
      _pending = null;
      _phase = PersonalSyncConnectionPhase.connected;
      _problem = null;
      notifyListeners();
      return PersonalSyncCallbackResult.completed;
    } on Object {
      await _discardPending();
      _setProblem(PersonalSyncConnectionProblem.authorizationFailed);
      return PersonalSyncCallbackResult.rejected;
    } finally {
      remote?.close();
      _callbackInFlight = false;
    }
  }

  Future<void> cancelConnection() async {
    await _discardPending();
    _problem = null;
    _phase = _connection == null
        ? PersonalSyncConnectionPhase.disconnected
        : PersonalSyncConnectionPhase.connected;
    notifyListeners();
  }

  Future<bool> syncNow() async {
    final current = _connection;
    if (current == null || _phase == PersonalSyncConnectionPhase.checking) {
      return false;
    }
    _phase = PersonalSyncConnectionPhase.checking;
    _problem = null;
    notifyListeners();
    try {
      final connection = await _connectionWithFreshAccess(current);
      if (_syncTrigger case final trigger?) await trigger(connection);
      final now = _clock.now().toUtc();
      final updated = connection.copyWith(lastSuccessAt: now);
      await _vault.writeConnection(updated);
      _connection = updated;
      _onConnectionChanged?.call(updated);
      _phase = PersonalSyncConnectionPhase.connected;
      notifyListeners();
      return true;
    } on PersonalSyncRemoteException catch (error) {
      _setProblem(switch (error.code) {
        'authentication_required' =>
          PersonalSyncConnectionProblem.authenticationRequired,
        'action_required' => PersonalSyncConnectionProblem.actionRequired,
        'invalid_response' ||
        'invalid_batch' => PersonalSyncConnectionProblem.incompatible,
        _ => PersonalSyncConnectionProblem.network,
      });
      return false;
    } on Object {
      _setProblem(PersonalSyncConnectionProblem.network);
      return false;
    }
  }

  Future<bool> reconnect({required String language}) async {
    final origin = _connection?.instanceOrigin;
    return origin != null &&
        await beginConnection(serverOrigin: origin, language: language);
  }

  Future<void> disconnect() async {
    await _clearSecureState();
    _onConnectionChanged?.call(null);
    _phase = PersonalSyncConnectionPhase.disconnected;
    _problem = null;
    notifyListeners();
  }

  Future<bool> revokeAll() async {
    final current = _connection;
    if (current == null) return true;
    _phase = PersonalSyncConnectionPhase.checking;
    notifyListeners();
    PersonalSyncRemote? remote;
    try {
      final connection = await _connectionWithFreshAccess(current);
      remote = _remoteFactory(Uri.parse(connection.instanceOrigin));
      await remote.revokeAll(connection.accessToken);
      await disconnect();
      return true;
    } on Object {
      _setProblem(PersonalSyncConnectionProblem.network);
      return false;
    } finally {
      remote?.close();
    }
  }

  Future<PersonalSyncConnection> _connectionWithFreshAccess(
    PersonalSyncConnection current,
  ) async {
    final now = _clock.now().toUtc();
    final remote = _remoteFactory(Uri.parse(current.instanceOrigin));
    try {
      if (now
          .add(const Duration(seconds: 30))
          .isBefore(current.accessExpiresAt)) {
        if (await remote.verifyDevice(current.accessToken) !=
            current.deviceId) {
          throw const PersonalSyncRemoteException('authentication_required');
        }
        return current;
      }
      if (!now.isBefore(current.refreshExpiresAt)) {
        throw const PersonalSyncRemoteException('authentication_required');
      }
      final pair = await remote.refresh(current.refreshToken);
      if (pair.deviceId != current.deviceId ||
          await remote.verifyDevice(pair.accessToken) != current.deviceId) {
        throw const PersonalSyncRemoteException('authentication_required');
      }
      final updated = current.copyWith(
        accessToken: pair.accessToken,
        accessExpiresAt: now.add(Duration(seconds: pair.expiresIn)),
        refreshToken: pair.refreshToken,
        refreshExpiresAt: pair.refreshExpiresAt,
      );
      await _vault.writeConnection(updated);
      _connection = updated;
      _onConnectionChanged?.call(updated);
      return updated;
    } finally {
      remote.close();
    }
  }

  bool _matchesCallback(
    Uri callback,
    PersonalSyncPendingAuthorization pending,
  ) {
    final primary = Uri.tryParse(pending.redirectUri);
    final exactPrimary =
        primary != null &&
        callback.scheme == primary.scheme &&
        callback.host == primary.host &&
        callback.port == primary.port &&
        callback.path == primary.path;
    final fallback =
        primary?.scheme == 'https' &&
        callback.scheme == 'dev.habiter.app' &&
        callback.host == 'auth' &&
        callback.path == '/callback';
    return exactPrimary || fallback;
  }

  Future<void> _discardPending() async {
    _pending = null;
    try {
      await _vault.deletePending();
    } on Object {
      /* Best-effort removal is retried at initialization. */
    }
  }

  Future<void> _clearSecureState() async {
    _pending = null;
    _connection = null;
    await Future.wait<void>(<Future<void>>[
      _vault.deletePending(),
      _vault.deleteConnection(),
    ]);
  }

  void _setProblem(
    PersonalSyncConnectionProblem problem, {
    bool preservePhase = false,
  }) {
    _problem = problem;
    if (!preservePhase) {
      _phase = _connection == null
          ? PersonalSyncConnectionPhase.error
          : PersonalSyncConnectionPhase.connected;
    }
    notifyListeners();
  }

  String _token(int bytes) => _base64Url(_randomBytes(bytes));

  static Uint8List _secureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static String _base64Url(Uint8List bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static bool _opaque(String? value, int minimum, int maximum) =>
      value != null &&
      value.length >= minimum &&
      value.length <= maximum &&
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

  static bool _constantTimeEquals(String first, String second) {
    final left = utf8.encode(first);
    final right = utf8.encode(second);
    var difference = left.length ^ right.length;
    for (var index = 0; index < max(left.length, right.length); index += 1) {
      difference |=
          (index < left.length ? left[index] : 0) ^
          (index < right.length ? right[index] : 0);
    }
    return difference == 0;
  }

  @override
  void dispose() {
    _handoff.dispose();
    super.dispose();
  }
}

Uri? normalizePersonalSyncOrigin(String value) {
  final parsed = Uri.tryParse(value.trim());
  if (parsed == null ||
      parsed.host.isEmpty ||
      parsed.userInfo.isNotEmpty ||
      parsed.query.isNotEmpty ||
      parsed.fragment.isNotEmpty ||
      (parsed.path.isNotEmpty && parsed.path != '/')) {
    return null;
  }
  final loopback =
      parsed.host == 'localhost' ||
      parsed.host == '127.0.0.1' ||
      parsed.host == '::1';
  if (parsed.scheme != 'https' && !(parsed.scheme == 'http' && loopback)) {
    return null;
  }
  return Uri(
    scheme: parsed.scheme,
    host: parsed.host,
    port: parsed.hasPort ? parsed.port : null,
  );
}
