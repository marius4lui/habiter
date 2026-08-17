import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/domain/update_models.dart';
import 'package:habiter/features/updates/domain/update_platform_gateway.dart';
import 'package:habiter/features/updates/infrastructure/method_channel_update_platform_gateway.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Habiter',
      packageName: 'com.habiter.app',
      version: '1.5.0',
      buildNumber: '10500',
      buildSignature: '',
    );
  });

  test(
    'desktop supports checks but delegates installation to the browser',
    () async {
      Uri? opened;
      final gateway = MethodChannelUpdatePlatformGateway(
        platformOverride: TargetPlatform.linux,
        externalUrlLauncher: (uri) async {
          opened = uri;
          return true;
        },
      );
      final runtime = await gateway.runtimeInfo();
      final candidate = _candidateFor(
        platform: 'linux',
        url: 'https://example.com/habiter-linux.tar.gz',
      );

      expect(runtime.supportsUpdates, isTrue);
      expect(runtime.supportsDirectInstall, isFalse);
      expect(
        await gateway.openExternal(candidate),
        UpdateInstallResult.externalOpened,
      );
      expect(opened, candidate.artifact.url);
    },
  );

  test('iOS and web explicitly expose no self-updater', () async {
    final ios = await const MethodChannelUpdatePlatformGateway(
      platformOverride: TargetPlatform.iOS,
    ).runtimeInfo();
    final web = await const MethodChannelUpdatePlatformGateway(
      platformOverride: TargetPlatform.linux,
      webOverride: true,
    ).runtimeInfo();

    expect(ios.supportsUpdates, isFalse);
    expect(web.platform, 'web');
    expect(web.supportsUpdates, isFalse);
  });

  test(
    'Android Store distribution opens Store and never enables direct install',
    () async {
      const channel = MethodChannel('com.habiter.test/updates');
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return switch (call.method) {
              'getRuntimeInfo' => <String, Object?>{
                'distribution': 'play',
                'directInstallAllowed': false,
                'installerSource': 'com.android.vending',
              },
              'openStore' => true,
              _ => null,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      const gateway = MethodChannelUpdatePlatformGateway(
        channel: channel,
        platformOverride: TargetPlatform.android,
      );
      final runtime = await gateway.runtimeInfo();

      expect(runtime.androidDistribution, AndroidDistribution.play);
      expect(runtime.supportsDirectInstall, isFalse);
      expect(
        await gateway.openExternal(
          _candidateFor(
            platform: 'android',
            url: 'https://example.com/habiter.aab',
            distribution: AndroidDistribution.play,
          ),
        ),
        UpdateInstallResult.externalOpened,
      );
      expect(calls, ['getRuntimeInfo', 'openStore']);
    },
  );
}

UpdateCandidate _candidateFor({
  required String platform,
  required String url,
  AndroidDistribution? distribution,
}) {
  final release = manifestOf([
    releaseJson(build: 10500, channel: 'stable'),
  ]).releases.single;
  return UpdateCandidate(
    release: release,
    artifact: UpdateArtifact(
      platform: platform,
      architecture: 'universal',
      fileName: 'habiter-download',
      signed: platform == 'android',
      url: Uri.parse(url),
      sha256: List.filled(64, 'a').join(),
      size: 42,
      distribution: distribution,
    ),
  );
}
