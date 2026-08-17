import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/application/update_controller.dart';
import 'package:habiter/features/updates/data/signed_manifest_client.dart';
import 'package:habiter/features/updates/data/update_local_repository.dart';
import 'package:habiter/features/updates/domain/update_models.dart';
import 'package:habiter/features/updates/domain/update_platform_gateway.dart';
import 'package:habiter/features/updates/domain/update_policy.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';
import 'update_test_data.dart';

void main() {
  Future<({String envelope, List<int> publicKey})> signed(
    List<Map<String, Object?>> releases,
  ) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(
      List<int>.generate(32, (index) => index),
    );
    final payload = manifestPayload(releases);
    final signature = await algorithm.sign(payload, keyPair: keyPair);
    final publicKey = await keyPair.extractPublicKey();
    String encode(List<int> bytes) =>
        base64UrlEncode(bytes).replaceAll('=', '');
    return (
      envelope: jsonEncode({
        'schemaVersion': 1,
        'keyId': 'test-key',
        'algorithm': 'ed25519',
        'payload': encode(payload),
        'signature': encode(signature.bytes),
      }),
      publicKey: publicKey.bytes,
    );
  }

  Future<UpdateController> controllerFor({
    required String envelope,
    required List<int> publicKey,
    required FakeUpdatePlatform platform,
    required FakeClock clock,
    UpdateLocalState? local,
    String? responseEnvelope,
  }) async {
    final store = InMemoryKeyValueStore();
    final repository = UpdateLocalRepository(store);
    await repository.save(
      local ??
          UpdateLocalState(
            profile: UpdateProfile.saver,
            previousAppBuild: platform.info.buildNumber,
            lastCheckedAt: clock.now(),
          ),
    );
    final controller = UpdateController(
      repository: repository,
      client: SignedManifestClient(
        client: MockClient(
          (_) async => http.Response(
            responseEnvelope ?? envelope,
            200,
            headers: {'etag': '"new"'},
          ),
        ),
      ),
      verifier: ManifestVerifier(publicKeyRing: {'test-key': publicKey}),
      platform: platform,
      clock: clock,
    );
    await controller.initialize();
    return controller;
  }

  test(
    'checks manually, selects an update and keeps installation voluntary',
    () async {
      final fixture = await signed([
        releaseJson(build: 10500, channel: 'stable'),
      ]);
      final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
      final platform = FakeUpdatePlatform(buildNumber: 10400);
      final controller = await controllerFor(
        envelope: fixture.envelope,
        publicKey: fixture.publicKey,
        platform: platform,
        clock: clock,
      );

      await controller.check(UpdateCheckTrigger.manual);
      expect(controller.state.phase, UpdatePhase.available);
      expect(controller.state.candidate?.release.buildNumber, 10500);
      expect(controller.shouldShowAvailableStory, isTrue);
      expect(platform.enqueueCalls, 0);
      controller.dispose();
    },
  );

  test('mandatory mode requires a successful online verification', () async {
    final fixture = await signed([
      releaseJson(
        build: 10500,
        channel: 'stable',
        mandatoryAfter: DateTime.utc(2026, 8, 16),
      ),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final platform = FakeUpdatePlatform(buildNumber: 10400);
    final controller = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: platform,
      clock: clock,
    );
    await controller.check(UpdateCheckTrigger.manual);
    expect(controller.state.phase, UpdatePhase.mandatory);

    platform.network = const UpdateNetworkStatus(
      isOnline: false,
      isMetered: false,
    );
    await controller.check(UpdateCheckTrigger.manual);
    expect(controller.state.phase, UpdatePhase.error);
    expect(controller.state.isMandatory, isFalse);
    expect(controller.state.isOnline, isFalse);
    expect(controller.state.candidate, isNotNull);
    controller.dispose();
  });

  test('tampered server data cannot replace the last verified cache', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
    ]);
    final tampered = jsonDecode(fixture.envelope) as Map<String, Object?>;
    tampered['payload'] = base64UrlEncode(
      manifestPayload([releaseJson(build: 10600, channel: 'stable')]),
    );
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final controller = await controllerFor(
      envelope: fixture.envelope,
      responseEnvelope: jsonEncode(tampered),
      publicKey: fixture.publicKey,
      platform: FakeUpdatePlatform(buildNumber: 10400),
      clock: clock,
      local: UpdateLocalState(
        cachedEnvelope: fixture.envelope,
        previousAppBuild: 10400,
        lastCheckedAt: clock.now(),
      ),
    );
    expect(controller.state.candidate?.release.buildNumber, 10500);
    await controller.check(UpdateCheckTrigger.manual);
    expect(controller.state.phase, UpdatePhase.error);
    expect(controller.state.candidate?.release.buildNumber, 10500);
    controller.dispose();
  });

  test(
    'download resumes through verification and becomes install-ready',
    () async {
      final fixture = await signed([
        releaseJson(build: 10500, channel: 'stable'),
      ]);
      final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
      final platform = FakeUpdatePlatform(buildNumber: 10400);
      final controller = await controllerFor(
        envelope: fixture.envelope,
        publicKey: fixture.publicKey,
        platform: platform,
        clock: clock,
      );
      await controller.check(UpdateCheckTrigger.manual);
      await controller.download();
      expect(controller.state.phase, UpdatePhase.downloading);
      expect(platform.enqueueCalls, 1);

      platform.download = const UpdateDownloadStatus(
        phase: UpdateDownloadPhase.complete,
        downloadedBytes: 100,
        totalBytes: 100,
      );
      await controller.pollDownload();
      expect(controller.state.phase, UpdatePhase.ready);
      expect(platform.verifyCalls, 1);
      controller.dispose();
    },
  );

  test('fresh installs do not show an upgrade story', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
      releaseJson(build: 10400, channel: 'stable'),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final controller = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: FakeUpdatePlatform(buildNumber: 10500),
      clock: clock,
      local: UpdateLocalState(
        cachedEnvelope: fixture.envelope,
        lastCheckedAt: clock.now(),
      ),
    );
    expect(controller.shouldShowUpgradeStory, isFalse);
    controller.dispose();
  });

  test('skipped versions are aggregated after a real upgrade', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
      releaseJson(build: 10400, channel: 'stable'),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final controller = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: FakeUpdatePlatform(buildNumber: 10500),
      clock: clock,
      local: UpdateLocalState(
        cachedEnvelope: fixture.envelope,
        previousAppBuild: 10300,
        lastCheckedAt: clock.now(),
      ),
    );
    expect(controller.upgradeReleases.map((release) => release.buildNumber), [
      10500,
      10400,
    ]);
    expect(controller.shouldShowUpgradeStory, isTrue);
    controller.dispose();
  });
}

final class FakeUpdatePlatform implements UpdatePlatformGateway {
  FakeUpdatePlatform({required int buildNumber})
    : info = UpdateRuntimeInfo(
        platform: 'android',
        version: '1.4.0',
        buildNumber: buildNumber,
        supportsUpdates: true,
        supportsDirectInstall: true,
        androidDistribution: AndroidDistribution.direct,
      );

  final UpdateRuntimeInfo info;
  UpdateNetworkStatus network = const UpdateNetworkStatus(
    isOnline: true,
    isMetered: false,
  );
  UpdateDownloadStatus download = const UpdateDownloadStatus(
    phase: UpdateDownloadPhase.running,
    downloadedBytes: 25,
    totalBytes: 100,
  );
  UpdateVerificationResult verification =
      const UpdateVerificationResult.valid();
  int enqueueCalls = 0;
  int verifyCalls = 0;
  int removeCalls = 0;

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) async {}

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async =>
      download;

  @override
  Future<String> enqueueDownload(
    UpdateCandidate candidate, {
    required bool allowMetered,
  }) async {
    enqueueCalls += 1;
    return '42';
  }

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async => UpdateInstallResult.launched;

  @override
  Future<UpdateNetworkStatus> networkStatus() async => network;

  @override
  Future<void> openInstallerPermission() async {}

  @override
  Future<UpdateInstallResult> openExternal(UpdateCandidate candidate) async =>
      UpdateInstallResult.externalOpened;

  @override
  Future<void> removeDownload(String downloadId) async {
    removeCalls += 1;
  }

  @override
  Future<UpdateRuntimeInfo> runtimeInfo() async => info;

  @override
  Future<int> storedDownloadBytes() async => 100;

  @override
  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  ) async {
    verifyCalls += 1;
    return verification;
  }
}
