import 'dart:convert';

import 'package:http/http.dart' as http;

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
  }) async {
    final request = http.Request(method, origin.resolve(path))
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
