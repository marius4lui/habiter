import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef PersonalSyncCallbackHandler = Future<void> Function(Uri callback);
typedef PersonalSyncExternalLauncher = Future<bool> Function(Uri uri);

abstract interface class PersonalSyncHandoff {
  bool get supported;
  String get redirectUri;
  Future<void> initialize(PersonalSyncCallbackHandler handler);
  Future<void> launch(Uri authorizationUri);
  Future<void> dispose();
}

final class PlatformPersonalSyncHandoff implements PersonalSyncHandoff {
  PlatformPersonalSyncHandoff({
    MethodChannel channel = const MethodChannel(_channelName),
    PersonalSyncExternalLauncher? launchExternal,
  }) : _channel = channel,
       _launchExternal = launchExternal ?? _systemLaunchExternal;

  static const _channelName = 'com.habiter.app/personal_sync_handoff';
  static const _mobileRedirect = 'https://mobile.habiter.dev/auth/callback';
  static const _desktopRedirect = 'http://localhost:43823/callback';
  final MethodChannel _channel;
  final PersonalSyncExternalLauncher _launchExternal;
  PersonalSyncCallbackHandler? _handler;

  bool get _mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get _desktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  bool get supported => _mobile || _desktop;

  @override
  String get redirectUri => _desktop ? _desktopRedirect : _mobileRedirect;

  @override
  Future<void> initialize(PersonalSyncCallbackHandler handler) async {
    _handler = handler;
    if (!_mobile) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'callback' || call.arguments is! String) return;
      final uri = Uri.tryParse(call.arguments as String);
      if (uri != null) await _handler?.call(uri);
    });
    final initial = await _channel.invokeMethod<String>(
      'consumeInitialCallback',
    );
    final uri = initial == null ? null : Uri.tryParse(initial);
    if (uri != null) await _handler?.call(uri);
  }

  @override
  Future<void> launch(Uri authorizationUri) async {
    if (_desktop) {
      await _launchDesktop(authorizationUri);
      return;
    }
    if (!_mobile || !await _launchExternal(authorizationUri)) {
      throw PlatformException(code: 'handoff_unavailable');
    }
  }

  Future<void> _launchDesktop(Uri authorizationUri) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 43823);
    final completion = Completer<Uri>();
    late final StreamSubscription<HttpRequest> subscription;
    subscription = server.listen((request) async {
      try {
        request.response.headers
          ..set('cache-control', 'no-store')
          ..set('referrer-policy', 'no-referrer')
          ..set('x-content-type-options', 'nosniff')
          ..set('cross-origin-opener-policy', 'same-origin');
        if (request.headers.host != 'localhost' &&
            request.headers.host != 'localhost:43823') {
          request.response.statusCode = HttpStatus.misdirectedRequest;
          await request.response.close();
          return;
        }
        if (request.method == 'GET' && request.uri.path == '/callback') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..headers.set(
              'content-security-policy',
              "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'",
            )
            ..write(_desktopLandingPage);
          await request.response.close();
          return;
        }
        if (request.method == 'POST' && request.uri.path == '/complete') {
          if (request.headers.value('origin') != 'http://localhost:43823' ||
              request.headers.contentType?.mimeType != 'text/plain') {
            request.response.statusCode = HttpStatus.forbidden;
            await request.response.close();
            return;
          }
          final bytes = await request.fold<List<int>>(<int>[], (buffer, chunk) {
            if (buffer.length + chunk.length > 4096) {
              throw const FormatException('callback too large');
            }
            return buffer..addAll(chunk);
          });
          final fragment = utf8.decode(bytes);
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          if (!completion.isCompleted) {
            completion.complete(
              Uri.parse(_desktopRedirect).replace(fragment: fragment),
            );
          }
          return;
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      } on Object {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
    });
    try {
      if (!await _launchExternal(authorizationUri)) {
        throw PlatformException(code: 'handoff_unavailable');
      }
      final callback = await completion.future.timeout(
        const Duration(minutes: 5),
      );
      await _handler?.call(callback);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  }

  static Future<bool> _systemLaunchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<void> dispose() async {
    _handler = null;
    if (_mobile) _channel.setMethodCallHandler(null);
  }
}

const _desktopLandingPage = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Habiter</title><style>body{font:1rem system-ui;margin:3rem;line-height:1.5}</style></head>
<body><p id="status">Returning securely to Habiter…</p><script>
const value=location.hash.slice(1);history.replaceState(null,'',location.pathname);
fetch('/complete',{method:'POST',headers:{'content-type':'text/plain'},body:value})
.then(()=>document.querySelector('#status').textContent='You can close this window.')
.catch(()=>document.querySelector('#status').textContent='Return to Habiter and try again.');
</script></body></html>''';
