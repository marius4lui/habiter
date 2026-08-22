import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/personal_sync_operation.dart';

final class PersonalSyncRemoteException implements Exception {
  const PersonalSyncRemoteException(this.code);
  final String code;
}

final class PersonalSyncInstanceInfo {
  const PersonalSyncInstanceInfo({
    required this.protocolVersion,
    required this.name,
    required this.baseUrl,
    required this.initialized,
  });
  final int protocolVersion;
  final String name;
  final String baseUrl;
  final bool initialized;
}

final class PersonalSyncTokenPair {
  const PersonalSyncTokenPair({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.deviceId,
  });
  final String accessToken;
  final int expiresIn;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final String deviceId;
}

final class PersonalSyncPullPage {
  const PersonalSyncPullPage({
    required this.operations,
    required this.cursor,
    required this.headOffset,
    required this.compactionFloor,
    required this.requiresSnapshot,
    required this.recoveryReason,
  });

  final List<PersonalSyncOperation> operations;
  final PersonalSyncServerCursor cursor;
  final int headOffset;
  final int compactionFloor;
  final bool requiresSnapshot;
  final String recoveryReason;
}

abstract interface class PersonalSyncRemote {
  Future<PersonalSyncInstanceInfo> instanceInfo();
  Future<PersonalSyncTokenPair> redeem({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String attemptId,
  });
  Future<PersonalSyncTokenPair> refresh(String refreshToken);
  Future<String> verifyDevice(String accessToken);
  Future<void> revokeAll(String accessToken);
  Future<void> push(List<PersonalSyncOperation> operations, String accessToken);
  Future<PersonalSyncPullPage> pull({
    required PersonalSyncServerCursor? cursor,
    required int limit,
    required String accessToken,
  });
  void close();
}

typedef PersonalSyncRemoteFactory = PersonalSyncRemote Function(Uri origin);

final class HttpPersonalSyncRemote implements PersonalSyncRemote {
  HttpPersonalSyncRemote(this.origin, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri origin;
  final http.Client _client;

  @override
  Future<PersonalSyncInstanceInfo> instanceInfo() async {
    final map = await _json('GET', '/v1/instance-info');
    final protocolVersion = map['protocolVersion'];
    final name = map['name'];
    final baseUrl = map['baseUrl'];
    final initialized = map['initialized'];
    if (protocolVersion is! int ||
        name is! String ||
        name.isEmpty ||
        name.length > 128 ||
        baseUrl is! String ||
        initialized is! bool) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    final reported = Uri.tryParse(baseUrl);
    if (reported == null || reported.origin != origin.origin) {
      throw const PersonalSyncRemoteException('origin_mismatch');
    }
    return PersonalSyncInstanceInfo(
      protocolVersion: protocolVersion,
      name: name,
      baseUrl: reported.origin,
      initialized: initialized,
    );
  }

  @override
  Future<PersonalSyncTokenPair> redeem({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String attemptId,
  }) async => _tokenPair(
    await _json(
      'POST',
      '/v1/token',
      body: <String, Object?>{
        'grantType': 'authorization_code',
        'code': code,
        'codeVerifier': codeVerifier,
        'redirectUri': redirectUri,
        'attemptId': attemptId,
      },
    ),
  );

  @override
  Future<PersonalSyncTokenPair> refresh(String refreshToken) async =>
      _tokenPair(
        await _json(
          'POST',
          '/v1/refresh',
          body: <String, Object?>{
            'grantType': 'refresh_token',
            'refreshToken': refreshToken,
          },
        ),
      );

  @override
  Future<String> verifyDevice(String accessToken) async {
    final map = await _json('GET', '/v1/device', accessToken: accessToken);
    final deviceId = map['deviceId'];
    if (deviceId is! String || deviceId.isEmpty || deviceId.length > 128) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    return deviceId;
  }

  @override
  Future<void> revokeAll(String accessToken) async {
    await _json(
      'POST',
      '/v1/revoke',
      accessToken: accessToken,
      body: const <String, Object?>{'scope': 'all'},
    );
  }

  @override
  Future<void> push(
    List<PersonalSyncOperation> operations,
    String accessToken,
  ) async {
    if (operations.isEmpty || operations.length > 100) {
      throw const PersonalSyncRemoteException('invalid_batch');
    }
    final map = await _json(
      'POST',
      '/v1/push',
      accessToken: accessToken,
      body: <String, Object?>{
        'operations': operations.map((operation) => operation.toMap()).toList(),
      },
    );
    final receipts = map['receipts'];
    if (receipts is! List ||
        receipts.length != operations.length ||
        receipts.any((receipt) => !_validReceipt(receipt))) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
  }

  @override
  Future<PersonalSyncPullPage> pull({
    required PersonalSyncServerCursor? cursor,
    required int limit,
    required String accessToken,
  }) async {
    if (limit < 1 || limit > 100) {
      throw const PersonalSyncRemoteException('invalid_batch');
    }
    final uri = origin
        .resolve('/v1/pull')
        .replace(
          queryParameters: <String, String>{
            if (cursor != null) 'cursor': cursor.token,
            'limit': '$limit',
          },
        );
    final map = await _jsonUri('GET', uri, accessToken: accessToken);
    final operations = map['operations'];
    final cursorValue = map['cursor'];
    final headOffset = map['headOffset'];
    final compactionFloor = map['compactionFloor'];
    final requiresSnapshot = map['requiresSnapshot'];
    final recoveryReason = map['recoveryReason'];
    if (operations is! List ||
        operations.length > limit ||
        operations.any((operation) => operation is! Map) ||
        cursorValue is! String ||
        headOffset is! int ||
        headOffset < 0 ||
        compactionFloor is! int ||
        compactionFloor < 0 ||
        compactionFloor > headOffset ||
        requiresSnapshot is! bool ||
        recoveryReason is! String ||
        !const <String>{
          'none',
          'missing_compacted_history',
          'generation_changed',
          'cursor_ahead',
        }.contains(recoveryReason)) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    final parsedCursor = PersonalSyncServerCursor.parse(cursorValue);
    if (parsedCursor.offset > headOffset ||
        (requiresSnapshot && operations.isNotEmpty) ||
        (requiresSnapshot == (recoveryReason == 'none'))) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    return PersonalSyncPullPage(
      operations: operations
          .map(
            (operation) => PersonalSyncOperation.fromMap(
              Map<String, Object?>.from(operation as Map),
            ),
          )
          .toList(growable: false),
      cursor: parsedCursor,
      headOffset: headOffset,
      compactionFloor: compactionFloor,
      requiresSnapshot: requiresSnapshot,
      recoveryReason: recoveryReason,
    );
  }

  PersonalSyncTokenPair _tokenPair(Map<String, Object?> map) {
    final tokenType = map['tokenType'];
    final accessToken = map['accessToken'];
    final expiresIn = map['expiresIn'];
    final refreshToken = map['refreshToken'];
    final refreshExpiresAt = map['refreshExpiresAt'];
    final deviceId = map['deviceId'];
    final refreshExpiry = refreshExpiresAt is String
        ? DateTime.tryParse(refreshExpiresAt)?.toUtc()
        : null;
    if (tokenType != 'Bearer' ||
        accessToken is! String ||
        accessToken.isEmpty ||
        accessToken.length > 4096 ||
        expiresIn is! int ||
        expiresIn < 1 ||
        expiresIn > 86400 ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        refreshToken.length > 512 ||
        refreshExpiry == null ||
        deviceId is! String ||
        deviceId.isEmpty ||
        deviceId.length > 128) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    return PersonalSyncTokenPair(
      accessToken: accessToken,
      expiresIn: expiresIn,
      refreshToken: refreshToken,
      refreshExpiresAt: refreshExpiry,
      deviceId: deviceId,
    );
  }

  Future<Map<String, Object?>> _json(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) => _jsonUri(
    method,
    origin.resolve(path),
    body: body,
    accessToken: accessToken,
  );

  Future<Map<String, Object?>> _jsonUri(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['accept'] = 'application/json';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (accessToken != null) {
      request.headers['authorization'] = 'Bearer $accessToken';
    }
    late final http.StreamedResponse streamed;
    try {
      streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
    } on Object {
      throw const PersonalSyncRemoteException('network');
    }
    late final List<int> bytes;
    try {
      bytes = await streamed.stream.toBytes().timeout(
        const Duration(seconds: 15),
      );
    } on Object {
      throw const PersonalSyncRemoteException('network');
    }
    if (bytes.length > 256 * 1024) {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw PersonalSyncRemoteException(
        streamed.statusCode == 401
            ? 'authentication_required'
            : 'request_failed',
      );
    }
    final contentType = streamed.headers['content-type']
        ?.split(';')
        .first
        .trim();
    if (contentType != 'application/json') {
      throw const PersonalSyncRemoteException('invalid_response');
    }
    try {
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map) throw const FormatException();
      return Map<String, Object?>.from(value);
    } on Object {
      throw const PersonalSyncRemoteException('invalid_response');
    }
  }

  @override
  void close() => _client.close();
}

bool _validReceipt(Object? value) {
  if (value is! Map) return false;
  final map = Map<String, Object?>.from(value);
  if (map.keys.toSet().difference(const <String>{
        'cursor',
        'offset',
        'duplicate',
        'changed',
      }).isNotEmpty ||
      map.length != 4 ||
      map['cursor'] is! String ||
      map['offset'] is! int ||
      map['duplicate'] is! bool ||
      map['changed'] is! bool) {
    return false;
  }
  try {
    return PersonalSyncServerCursor.parse(map['cursor']! as String).offset ==
        map['offset'];
  } on Object {
    return false;
  }
}
