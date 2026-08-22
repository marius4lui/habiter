import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_handoff.dart';

void main() {
  test(
    'desktop loopback moves the fragment through a bounded same-origin POST',
    () async {
      final browserLaunched = Completer<Uri>();
      final callback = Completer<Uri>();
      final handoff = PlatformPersonalSyncHandoff(
        launchExternal: (uri) async {
          browserLaunched.complete(uri);
          return true;
        },
      );
      await handoff.initialize((uri) async => callback.complete(uri));

      final launch = handoff.launch(
        Uri.parse('https://sync.example.com/v1/authorize'),
      );
      expect(
        await browserLaunched.future,
        Uri.parse('https://sync.example.com/v1/authorize'),
      );

      final client = HttpClient();
      final landingRequest = await client.getUrl(
        Uri.parse('http://localhost:43823/callback'),
      );
      final landing = await landingRequest.close();
      expect(landing.statusCode, HttpStatus.ok);
      expect(landing.headers.value('cache-control'), 'no-store');
      expect(
        landing.headers.value('content-security-policy'),
        contains("default-src 'none'"),
      );
      await landing.drain<void>();

      final rejectedRequest = await client.postUrl(
        Uri.parse('http://localhost:43823/complete'),
      );
      rejectedRequest.headers.contentType = ContentType.text;
      rejectedRequest.headers.set('origin', 'https://attacker.example');
      rejectedRequest.write('code=ignored&state=ignored');
      expect((await rejectedRequest.close()).statusCode, HttpStatus.forbidden);
      expect(callback.isCompleted, isFalse);

      final completeRequest = await client.postUrl(
        Uri.parse('http://localhost:43823/complete'),
      );
      completeRequest.headers.contentType = ContentType.text;
      completeRequest.headers.set('origin', 'http://localhost:43823');
      completeRequest.write('code=authorization_code&state=opaque_state');
      expect((await completeRequest.close()).statusCode, HttpStatus.noContent);

      expect(
        await callback.future,
        Uri.parse(
          'http://localhost:43823/callback#code=authorization_code&state=opaque_state',
        ),
      );
      await launch;
      client.close(force: true);
      await handoff.dispose();
    },
  );
}
