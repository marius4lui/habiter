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
    String Function()? responseEnvelopeProvider,
    InMemoryKeyValueStore? existingStore,
    bool seedLocalState = true,
  }) async {
    final store = existingStore ?? InMemoryKeyValueStore();
    final repository = UpdateLocalRepository(store);
    if (seedLocalState) {
      await repository.save(
        local ??
            UpdateLocalState(
              profile: UpdateProfile.saver,
              previousAppBuild: platform.info.buildNumber,
              lastCheckedAt: clock.now(),
            ),
      );
    }
    final controller = UpdateController(
      repository: repository,
      client: SignedManifestClient(
        client: MockClient(
          (_) async => http.Response(
            responseEnvelopeProvider?.call() ?? responseEnvelope ?? envelope,
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

  test(
    'automatic downloads never launch an external Store or browser',
    () async {
      final fixture = await signed([
        releaseJson(build: 10500, channel: 'stable'),
      ]);
      final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
      final platform = FakeUpdatePlatform(
        buildNumber: 10400,
        supportsDirectInstall: false,
      );
      final controller = await controllerFor(
        envelope: fixture.envelope,
        publicKey: fixture.publicKey,
        platform: platform,
        clock: clock,
        local: UpdateLocalState(
          profile: UpdateProfile.balanced,
          previousAppBuild: 10400,
          lastCheckedAt: clock.now(),
        ),
      );

      await controller.check(UpdateCheckTrigger.manual);

      expect(controller.state.phase, UpdatePhase.available);
      expect(platform.enqueueCalls, 0);
      expect(platform.openExternalCalls, 0);
      controller.dispose();
    },
  );

  test(
    'Balanced automatically queues a direct download when unmetered',
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
        local: UpdateLocalState(
          profile: UpdateProfile.balanced,
          previousAppBuild: 10400,
          lastCheckedAt: clock.now(),
        ),
      );

      await controller.check(UpdateCheckTrigger.manual);

      expect(controller.state.phase, UpdatePhase.downloading);
      expect(platform.enqueueCalls, 1);
      expect(platform.lastAllowMetered, isFalse);
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

  test(
    'a failed server verification releases an existing mandatory lock',
    () async {
      final fixture = await signed([
        releaseJson(
          build: 10500,
          channel: 'stable',
          mandatoryAfter: DateTime.utc(2026, 8, 16),
        ),
      ]);
      final tampered = jsonDecode(fixture.envelope) as Map<String, Object?>;
      tampered['signature'] = base64UrlEncode(List<int>.filled(64, 7));
      var serverEnvelope = fixture.envelope;
      final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
      final platform = FakeUpdatePlatform(buildNumber: 10400);
      final controller = await controllerFor(
        envelope: fixture.envelope,
        publicKey: fixture.publicKey,
        platform: platform,
        clock: clock,
        responseEnvelopeProvider: () => serverEnvelope,
      );
      await controller.check(UpdateCheckTrigger.manual);
      expect(controller.mandatoryEnforced, isTrue);
      serverEnvelope = jsonEncode(tampered);

      await controller.check(UpdateCheckTrigger.manual);

      expect(controller.state.phase, UpdatePhase.error);
      expect(controller.mandatoryEnforced, isFalse);
      controller.dispose();
    },
  );

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

      await controller.check(UpdateCheckTrigger.manual);
      expect(controller.state.phase, UpdatePhase.ready);
      expect(controller.canCheck, isFalse);
      expect(await controller.install(), UpdateInstallResult.launched);
      controller.dispose();
    },
  );

  test('a persisted DownloadManager ID resumes after app restart', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final platform = FakeUpdatePlatform(buildNumber: 10400);
    final store = InMemoryKeyValueStore();
    final first = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: platform,
      clock: clock,
      existingStore: store,
    );
    await first.check(UpdateCheckTrigger.manual);
    await first.download();
    first.dispose();
    platform.download = const UpdateDownloadStatus(
      phase: UpdateDownloadPhase.running,
      downloadedBytes: 60,
      totalBytes: 100,
    );

    final restored = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: platform,
      clock: clock,
      existingStore: store,
      seedLocalState: false,
    );

    expect(restored.state.phase, UpdatePhase.downloading);
    expect(restored.state.progress, 0.6);
    platform.download = const UpdateDownloadStatus(
      phase: UpdateDownloadPhase.complete,
      downloadedBytes: 100,
      totalBytes: 100,
    );
    await restored.pollDownload();
    expect(restored.state.phase, UpdatePhase.ready);
    restored.dispose();
  });

  test(
    'a ready mandatory update fails open when resume finds no network',
    () async {
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
      await controller.download();
      platform.download = const UpdateDownloadStatus(
        phase: UpdateDownloadPhase.complete,
        downloadedBytes: 100,
        totalBytes: 100,
      );
      await controller.pollDownload();
      expect(controller.state.phase, UpdatePhase.ready);
      platform.network = const UpdateNetworkStatus(
        isOnline: false,
        isMetered: false,
      );

      await controller.handleResume();

      expect(controller.state.phase, UpdatePhase.ready);
      expect(controller.state.isOnline, isFalse);
      controller.dispose();
    },
  );

  test(
    'download status errors fail safely and can be reconciled on resume',
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
      platform.downloadStatusError = StateError('binder unavailable');

      await controller.pollDownload();

      expect(controller.state.phase, UpdatePhase.error);
      expect(controller.state.errorCode, 'download_status_failed');
      platform.downloadStatusError = null;
      await controller.handleResume();
      expect(controller.state.phase, UpdatePhase.downloading);
      controller.dispose();
    },
  );

  test('runtime platform failures leave startup usable', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final platform = FakeUpdatePlatform(buildNumber: 10400)
      ..runtimeInfoError = StateError('channel unavailable');
    final controller = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: platform,
      clock: clock,
    );

    expect(controller.initialized, isTrue);
    expect(controller.state.phase, UpdatePhase.error);
    expect(controller.state.errorCode, 'runtime_info_failed');
    controller.dispose();
  });

  test('an installer failure deletes the candidate and fails safely', () async {
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
    platform.download = const UpdateDownloadStatus(
      phase: UpdateDownloadPhase.complete,
      downloadedBytes: 100,
      totalBytes: 100,
    );
    await controller.pollDownload();
    platform.installError = StateError('APK changed after verification');

    expect(await controller.install(), UpdateInstallResult.unavailable);
    expect(controller.state.phase, UpdatePhase.error);
    expect(platform.removeCalls, 1);
    controller.dispose();
  });

  test('an invalid APK is removed after native verification', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final platform = FakeUpdatePlatform(buildNumber: 10400)
      ..verification = const UpdateVerificationResult.invalid('foreign_signer');
    final controller = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: platform,
      clock: clock,
    );
    await controller.check(UpdateCheckTrigger.manual);
    await controller.download();
    platform.download = const UpdateDownloadStatus(
      phase: UpdateDownloadPhase.complete,
      downloadedBytes: 100,
      totalBytes: 100,
    );

    await controller.pollDownload();

    expect(controller.state.phase, UpdatePhase.error);
    expect(controller.state.errorCode, 'foreign_signer');
    expect(platform.removeCalls, 1);
    controller.dispose();
  });

  test('missing storage becomes a non-blocking download error', () async {
    final fixture = await signed([
      releaseJson(build: 10500, channel: 'stable'),
    ]);
    final clock = FakeClock(DateTime.utc(2026, 8, 17, 12));
    final platform = FakeUpdatePlatform(buildNumber: 10400)
      ..enqueueError = StateError('insufficient_storage');
    final controller = await controllerFor(
      envelope: fixture.envelope,
      publicKey: fixture.publicKey,
      platform: platform,
      clock: clock,
    );
    await controller.check(UpdateCheckTrigger.manual);

    await controller.download();

    expect(controller.state.phase, UpdatePhase.error);
    expect(controller.state.errorCode, 'download_failed');
    controller.dispose();
  });

  test('storage cleanup removes every native update download', () async {
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

    await controller.clearDownloads();

    expect(platform.clearDownloadsCalls, 1);
    expect(controller.state.phase, UpdatePhase.available);
    controller.dispose();
  });

  test(
    'clearing the verified cache also removes its active download',
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

      await controller.clearManifestCache();

      expect(platform.removeCalls, 1);
      expect(controller.manifest, isNull);
      expect(controller.state.phase, UpdatePhase.idle);
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

  test(
    'upgrade story waits for a verified manifest instead of being lost',
    () async {
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
          profile: UpdateProfile.saver,
          previousAppBuild: 10400,
          lastCheckedAt: clock.now(),
        ),
      );
      expect(controller.upgradeReleases, isEmpty);

      await controller.check(UpdateCheckTrigger.manual);

      expect(controller.upgradeReleases.map((release) => release.buildNumber), [
        10500,
      ]);
      controller.dispose();
    },
  );
}

final class FakeUpdatePlatform implements UpdatePlatformGateway {
  FakeUpdatePlatform({
    required int buildNumber,
    bool supportsDirectInstall = true,
  }) : info = UpdateRuntimeInfo(
         platform: 'android',
         version: '1.4.0',
         buildNumber: buildNumber,
         supportsUpdates: true,
         supportsDirectInstall: supportsDirectInstall,
         androidDistribution: supportsDirectInstall
             ? AndroidDistribution.direct
             : AndroidDistribution.play,
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
  int openExternalCalls = 0;
  int clearDownloadsCalls = 0;
  bool? lastAllowMetered;
  Object? installError;
  Object? enqueueError;
  Object? downloadStatusError;
  Object? runtimeInfoError;

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) async {}

  @override
  Future<void> clearDownloads() async {
    clearDownloadsCalls += 1;
  }

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async {
    if (downloadStatusError case final error?) throw error;
    return download;
  }

  @override
  Future<String> enqueueDownload(
    UpdateCandidate candidate, {
    required bool allowMetered,
  }) async {
    enqueueCalls += 1;
    lastAllowMetered = allowMetered;
    if (enqueueError case final error?) throw error;
    return '42';
  }

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async {
    if (installError case final error?) throw error;
    return UpdateInstallResult.launched;
  }

  @override
  Future<UpdateNetworkStatus> networkStatus() async => network;

  @override
  Future<void> openInstallerPermission() async {}

  @override
  Future<UpdateInstallResult> openExternal(UpdateCandidate candidate) async {
    openExternalCalls += 1;
    return UpdateInstallResult.externalOpened;
  }

  @override
  Future<void> removeDownload(String downloadId) async {
    removeCalls += 1;
  }

  @override
  Future<UpdateRuntimeInfo> runtimeInfo() async {
    if (runtimeInfoError case final error?) throw error;
    return info;
  }

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
