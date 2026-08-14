import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../features/integrations/classly/classly_endpoint.dart';
import 'classly_client.dart';

typedef OAuthLauncher =
    Future<String> Function(String authorizationUrl, String callbackScheme);

class ClasslyOAuthService {
  ClasslyOAuthService({OAuthLauncher? launcher, Random? random})
    : _launcher = launcher ?? _launch,
      _random = random ?? Random.secure();

  static const String clientId = 'habiter-app';
  static const String _mobileRedirectScheme = 'habiter';
  static const String _mobileRedirectUri = 'habiter://auth/callback';
  static const String _desktopCallbackPath = '/callback';

  final OAuthLauncher _launcher;
  final Random _random;

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<Map<String, dynamic>> authenticate({
    required String baseUrl,
    required ClasslyClient client,
  }) async {
    final endpoint = ClasslyEndpoint.parse(baseUrl).origin;
    final redirectUri = _isDesktop
        ? 'http://localhost:43823$_desktopCallbackPath'
        : _mobileRedirectUri;
    final callbackScheme = _isDesktop
        ? 'http://localhost:43823'
        : _mobileRedirectScheme;
    final state = _randomToken(32);
    final verifier = _randomToken(64);
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final authUri = endpoint
        .resolve('/api/oauth/authorize')
        .replace(
          queryParameters: <String, String>{
            'client_id': clientId,
            'redirect_uri': redirectUri,
            'response_type': 'code',
            'scope': 'read:events',
            'state': state,
            'code_challenge': challenge,
            'code_challenge_method': 'S256',
          },
        );

    final callback = Uri.parse(
      await _launcher(authUri.toString(), callbackScheme),
    );
    if (callback.queryParameters['state'] != state) {
      throw ClasslyApiException('OAuth state validation failed.');
    }
    final code = callback.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw ClasslyApiException('OAuth authorization code is missing.');
    }
    return client.exchangeCodeForToken(
      code: code,
      redirectUri: redirectUri,
      clientId: clientId,
      codeVerifier: verifier,
    );
  }

  String _randomToken(int length) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static Future<String> _launch(String url, String callbackScheme) =>
      FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          useWebview: false,
          preferEphemeral: true,
          timeout: 300000,
        ),
      );
}
