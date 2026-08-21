import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/domain/update_models.dart';
import 'package:habiter/features/updates/domain/update_platform_gateway.dart';
import 'package:habiter/features/updates/infrastructure/desktop_update_client.dart';
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
    'desktop routes downloads to its durable client and retains browser fallback',
    () async {
      Uri? opened;
      final desktop = _FakeDesktopUpdateClient();
      final gateway = MethodChannelUpdatePlatformGateway(
        platformOverride: TargetPlatform.linux,
        desktopClient: desktop,
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
      expect(runtime.supportsDirectInstall, isTrue);
      expect((await gateway.networkStatus()).isMetered, isTrue);
      expect(
        await gateway.enqueueDownload(candidate, allowMetered: true),
        'desktop-download',
      );
      expect(
        (await gateway.downloadStatus('desktop-download')).phase,
        UpdateDownloadPhase.complete,
      );
      expect(desktop.enqueued, candidate);
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
    'Android Store distribution uses Play flow and never enables APK install',
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
              'startStoreUpdate' => 'launched',
              'getStoreUpdateStatus' => <String, Object?>{
                'phase': 'complete',
                'downloadedBytes': 42,
                'totalBytes': 42,
              },
              'completeStoreUpdate' => 'launched',
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
      final candidate = _candidateFor(
        platform: 'android',
        url: 'https://example.com/habiter.aab',
        distribution: AndroidDistribution.play,
      );
      expect(
        await gateway.openExternal(candidate),
        UpdateInstallResult.launched,
      );
      expect(
        (await gateway.downloadStatus('play')).phase,
        UpdateDownloadPhase.complete,
      );
      expect((await gateway.verifyDownload('play', candidate)).isValid, isTrue);
      expect(
        await gateway.install('play', candidate),
        UpdateInstallResult.launched,
      );
      expect(calls, [
        'getRuntimeInfo',
        'startStoreUpdate',
        'getStoreUpdateStatus',
        'getStoreUpdateStatus',
        'completeStoreUpdate',
      ]);
    },
  );
}

final class _FakeDesktopUpdateClient implements DesktopUpdateClient {
  UpdateCandidate? enqueued;

  @override
  bool canSelfUpdate(String platform) => platform == 'linux';

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) async {}

  @override
  Future<void> clearDownloads() async {}

  @override
  Future<String> enqueueDownload(UpdateCandidate candidate) async {
    enqueued = candidate;
    return 'desktop-download';
  }

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async =>
      const UpdateDownloadStatus(
        phase: UpdateDownloadPhase.complete,
        downloadedBytes: 42,
        totalBytes: 42,
      );

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async => UpdateInstallResult.launched;

  @override
  Future<void> removeDownload(String downloadId) async {}

  @override
  Future<int> storedDownloadBytes() async => 42;

  @override
  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  ) async => const UpdateVerificationResult.valid();
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
      format: platform == 'android'
          ? UpdateArtifactFormat.aab
          : UpdateArtifactFormat.tarGz,
      primary: platform == 'android' ? null : true,
      fileName: 'habiter-download',
      signed: platform == 'android',
      url: Uri.parse(url),
      sha256: List.filled(64, 'a').join(),
      size: 42,
      distribution: distribution,
    ),
  );
}
