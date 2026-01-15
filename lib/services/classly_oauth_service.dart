import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'classly_client.dart';

class ClasslyOAuthService {
  static const String clientId = 'habiter-app';
  
  // For mobile platforms, use custom URL scheme
  static const String _mobileRedirectScheme = 'habiter';
  static const String _mobileRedirectUri = 'habiter://auth/callback';
  
  // For desktop platforms, we'll use localhost with a dynamic port
  static const String _desktopCallbackPath = '/callback';
  
  /// Check if running on desktop (Windows, Linux, macOS)
  static bool get _isDesktop => 
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Performs the OAuth 2.0 Authorization Code Flow.
  /// 
  /// 1. Opens the browser for user to login at [baseUrl]/api/oauth/authorize
  /// 2. Waits for redirect to callback URL
  /// 3. Extracts authorization code
  /// 4. Exchanges code for access token
  /// 
  /// Returns a map containing the token response (access_token, class_id, etc.)
  Future<Map<String, dynamic>> authenticate({
    required String baseUrl,
    required ClasslyClient client,
  }) async {
    final cleanBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    
    // Determine redirect URI and callback scheme based on platform
    final String redirectUri;
    final String callbackUrlScheme;
    
    if (_isDesktop) {
      // On desktop, use localhost with a fixed port
      // The port must match what's configured in the Classly OAuth app settings
      const port = 43823; // Fixed port for OAuth callback
      redirectUri = 'http://localhost:$port$_desktopCallbackPath';
      callbackUrlScheme = 'http://localhost:$port';
    } else {
      // On mobile, use custom URL scheme
      redirectUri = _mobileRedirectUri;
      callbackUrlScheme = _mobileRedirectScheme;
    }
    
    // Construct the authorization URL
    final authUri = Uri.parse('$cleanBaseUrl/api/oauth/authorize').replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'read:events', // Default scope
      },
    );

    debugPrint('OAuth: Starting authentication flow');
    debugPrint('OAuth: Auth URL: $authUri');
    debugPrint('OAuth: Redirect URI: $redirectUri');
    debugPrint('OAuth: Callback scheme: $callbackUrlScheme');
    debugPrint('OAuth: Is desktop: $_isDesktop');

    // Configure options for system browser on desktop
    const options = FlutterWebAuth2Options(
      // Use system browser instead of webview on desktop
      useWebview: false,
      // Use ephemeral session (don't persist cookies)
      preferEphemeral: true,
      // Timeout after 5 minutes (300000 milliseconds)
      timeout: 300000,
    );

    // Present the dialog to the user
    final result = await FlutterWebAuth2.authenticate(
      url: authUri.toString(),
      callbackUrlScheme: callbackUrlScheme,
      options: options,
    );

    debugPrint('OAuth: Received callback');

    // Extract code from result URL
    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      throw ClasslyApiException('No code found in redirect URL');
    }

    debugPrint('OAuth: Extracted code, exchanging for token...');

    // Exchange code for token
    final tokenData = await client.exchangeCodeForToken(
      code: code,
      redirectUri: redirectUri,
      clientId: clientId,
    );

    debugPrint('OAuth: Token exchange successful');
    return tokenData;
  }
}
