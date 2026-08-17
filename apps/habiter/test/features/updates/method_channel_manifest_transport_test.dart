import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/infrastructure/method_channel_manifest_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/native-manifest');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passes endpoint and ETag to the native Android transport', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'fetchManifest');
          expect(call.arguments, {
            'url': 'https://get.habiter.dev/api/v1/manifest',
            'etag': '"old"',
          });
          return <String, Object?>{
            'statusCode': 200,
            'body': '{"schemaVersion":1}',
            'etag': '"new"',
          };
        });

    final response = await const MethodChannelManifestTransport(
      channel: channel,
    ).get(Uri.parse('https://get.habiter.dev/api/v1/manifest'), etag: '"old"');

    expect(response.statusCode, 200);
    expect(response.body, '{"schemaVersion":1}');
    expect(response.etag, '"new"');
  });

  test('rejects malformed native responses', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => {'statusCode': 200});

    expect(
      () => const MethodChannelManifestTransport(
        channel: channel,
      ).get(Uri.parse('https://get.habiter.dev/api/v1/manifest')),
      throwsA(isA<FormatException>()),
    );
  });
}
