import 'dart:convert';

enum PersonalSyncConnectionPhase {
  loading,
  disconnected,
  authorizing,
  connected,
  checking,
  error,
}

enum PersonalSyncConnectionProblem {
  invalidOrigin,
  unavailable,
  incompatible,
  browserCanceled,
  callbackRejected,
  callbackExpired,
  authorizationFailed,
  credentialStorageFailed,
  authenticationRequired,
  actionRequired,
  network,
}

enum PersonalSyncCallbackResult { completed, ignored, rejected, expired }

final class PersonalSyncPendingAuthorization {
  const PersonalSyncPendingAuthorization({
    required this.instanceOrigin,
    required this.instanceName,
    required this.redirectUri,
    required this.state,
    required this.codeVerifier,
    required this.attemptId,
    required this.deviceId,
    required this.createdAt,
    required this.expiresAt,
    this.redeeming = false,
  });

  factory PersonalSyncPendingAuthorization.fromJson(String source) {
    final value = jsonDecode(source);
    if (value is! Map) {
      throw const FormatException('invalid pending authorization');
    }
    final map = Map<String, Object?>.from(value);
    if (map.keys.toSet().difference(_keys).isNotEmpty ||
        _keys.difference(map.keys.toSet()).isNotEmpty) {
      throw const FormatException('invalid pending authorization');
    }
    return PersonalSyncPendingAuthorization(
      instanceOrigin: _string(map, 'instanceOrigin'),
      instanceName: _string(map, 'instanceName'),
      redirectUri: _string(map, 'redirectUri'),
      state: _string(map, 'state'),
      codeVerifier: _string(map, 'codeVerifier'),
      attemptId: _string(map, 'attemptId'),
      deviceId: _string(map, 'deviceId'),
      createdAt: _date(map, 'createdAt'),
      expiresAt: _date(map, 'expiresAt'),
      redeeming: _boolean(map, 'redeeming'),
    );
  }

  final String instanceOrigin;
  final String instanceName;
  final String redirectUri;
  final String state;
  final String codeVerifier;
  final String attemptId;
  final String deviceId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool redeeming;

  PersonalSyncPendingAuthorization markRedeeming() =>
      PersonalSyncPendingAuthorization(
        instanceOrigin: instanceOrigin,
        instanceName: instanceName,
        redirectUri: redirectUri,
        state: state,
        codeVerifier: codeVerifier,
        attemptId: attemptId,
        deviceId: deviceId,
        createdAt: createdAt,
        expiresAt: expiresAt,
        redeeming: true,
      );

  String toJson() => jsonEncode(<String, Object?>{
    'instanceOrigin': instanceOrigin,
    'instanceName': instanceName,
    'redirectUri': redirectUri,
    'state': state,
    'codeVerifier': codeVerifier,
    'attemptId': attemptId,
    'deviceId': deviceId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'redeeming': redeeming,
  });

  static const _keys = <String>{
    'instanceOrigin',
    'instanceName',
    'redirectUri',
    'state',
    'codeVerifier',
    'attemptId',
    'deviceId',
    'createdAt',
    'expiresAt',
    'redeeming',
  };
}

final class PersonalSyncConnection {
  const PersonalSyncConnection({
    required this.instanceOrigin,
    required this.instanceName,
    required this.deviceId,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.connectedAt,
    required this.lastSuccessAt,
  });

  factory PersonalSyncConnection.fromJson(String source) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException('invalid connection');
    final map = Map<String, Object?>.from(value);
    if (map.keys.toSet().difference(_keys).isNotEmpty ||
        _keys.difference(map.keys.toSet()).isNotEmpty) {
      throw const FormatException('invalid connection');
    }
    return PersonalSyncConnection(
      instanceOrigin: _string(map, 'instanceOrigin'),
      instanceName: _string(map, 'instanceName'),
      deviceId: _string(map, 'deviceId'),
      accessToken: _string(map, 'accessToken'),
      accessExpiresAt: _date(map, 'accessExpiresAt'),
      refreshToken: _string(map, 'refreshToken'),
      refreshExpiresAt: _date(map, 'refreshExpiresAt'),
      connectedAt: _date(map, 'connectedAt'),
      lastSuccessAt: _date(map, 'lastSuccessAt'),
    );
  }

  final String instanceOrigin;
  final String instanceName;
  final String deviceId;
  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final DateTime connectedAt;
  final DateTime lastSuccessAt;

  PersonalSyncConnection copyWith({
    String? accessToken,
    DateTime? accessExpiresAt,
    String? refreshToken,
    DateTime? refreshExpiresAt,
    DateTime? lastSuccessAt,
  }) => PersonalSyncConnection(
    instanceOrigin: instanceOrigin,
    instanceName: instanceName,
    deviceId: deviceId,
    accessToken: accessToken ?? this.accessToken,
    accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
    refreshToken: refreshToken ?? this.refreshToken,
    refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    connectedAt: connectedAt,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
  );

  String toJson() => jsonEncode(<String, Object?>{
    'instanceOrigin': instanceOrigin,
    'instanceName': instanceName,
    'deviceId': deviceId,
    'accessToken': accessToken,
    'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshExpiresAt': refreshExpiresAt.toUtc().toIso8601String(),
    'connectedAt': connectedAt.toUtc().toIso8601String(),
    'lastSuccessAt': lastSuccessAt.toUtc().toIso8601String(),
  });

  static const _keys = <String>{
    'instanceOrigin',
    'instanceName',
    'deviceId',
    'accessToken',
    'accessExpiresAt',
    'refreshToken',
    'refreshExpiresAt',
    'connectedAt',
    'lastSuccessAt',
  };
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw const FormatException('invalid secure value');
  }
  return value;
}

DateTime _date(Map<String, Object?> map, String key) {
  final value = DateTime.tryParse(_string(map, key));
  if (value == null) throw const FormatException('invalid secure date');
  return value.toUtc();
}

bool _boolean(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) throw const FormatException('invalid secure flag');
  return value;
}
