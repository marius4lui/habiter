import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/domain/update_models.dart';
import 'package:habiter/features/updates/domain/update_platform_gateway.dart';
import 'package:habiter/features/updates/domain/update_policy.dart';
import 'package:habiter/features/updates/infrastructure/io_desktop_update_client.dart';
import 'package:habiter/features/updates/infrastructure/desktop_update_installer.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'update_test_data.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('habiter-update-test.');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'desktop download persists, verifies, and survives recreation',
    () async {
      final bytes = List<int>.generate(128, (index) => index);
      final candidate = _candidate(bytes);
      final client = IoDesktopUpdateClient(
        root: root,
        httpClientFactory: () => MockClient(
          (request) async => http.Response.bytes(bytes, HttpStatus.ok),
        ),
      );

      final id = await client.enqueueDownload(candidate);
      final complete = await _waitForPhase(
        client,
        id,
        UpdateDownloadPhase.complete,
      );
      expect(complete.downloadedBytes, bytes.length);
      expect(
        await client.verifyDownload(id, candidate),
        isA<UpdateVerificationResult>().having(
          (result) => result.isValid,
          'valid',
          isTrue,
        ),
      );
      expect(await client.storedDownloadBytes(), bytes.length);

      final recreated = IoDesktopUpdateClient(
        root: root,
        httpClientFactory: () => MockClient(
          (_) async => throw StateError('completed downloads must not refetch'),
        ),
      );
      expect(
        (await recreated.downloadStatus(id)).phase,
        UpdateDownloadPhase.complete,
      );
      expect((await recreated.verifyDownload(id, candidate)).isValid, isTrue);

      await recreated.removeDownload(id);
      expect(
        (await recreated.downloadStatus(id)).phase,
        UpdateDownloadPhase.missing,
      );
    },
  );

  test('checksum mismatch and redirects fail closed', () async {
    final bytes = List<int>.filled(32, 7);
    final candidate = _candidate(
      bytes,
      declaredDigest: List.filled(64, 'a').join(),
    );
    final mismatch = IoDesktopUpdateClient(
      root: root,
      httpClientFactory: () =>
          MockClient((_) async => http.Response.bytes(bytes, HttpStatus.ok)),
    );
    final mismatchId = await mismatch.enqueueDownload(candidate);
    await _waitForPhase(mismatch, mismatchId, UpdateDownloadPhase.complete);
    final verification = await mismatch.verifyDownload(mismatchId, candidate);
    expect(verification.isValid, isFalse);
    expect(verification.failureCode, 'checksum_mismatch');

    await mismatch.clearDownloads();
    final redirect = IoDesktopUpdateClient(
      root: root,
      httpClientFactory: () => MockClient(
        (_) async => http.Response(
          '',
          HttpStatus.found,
          headers: {
            HttpHeaders.locationHeader:
                'https://other.example/Habiter.AppImage',
          },
        ),
      ),
    );
    final redirectId = await redirect.enqueueDownload(_candidate(bytes));
    final failed = await _waitForPhase(
      redirect,
      redirectId,
      UpdateDownloadPhase.failed,
    );
    expect(failed.failureCode, 'unsafe_redirect');
  });

  test('download identifiers cannot escape the owned update directory', () {
    final client = IoDesktopUpdateClient(root: root);
    expect(client.removeDownload('../../unrelated'), throwsFormatException);
  });

  test(
    'install re-verifies the payload before launching and terminating',
    () async {
      final bytes = List<int>.generate(64, (index) => 255 - index);
      final candidate = _candidate(bytes);
      final installer = _FakeInstaller();
      int? exitCode;
      final client = IoDesktopUpdateClient(
        root: root,
        httpClientFactory: () =>
            MockClient((_) async => http.Response.bytes(bytes, HttpStatus.ok)),
        installer: installer,
        terminate: (code) => exitCode = code,
      );
      final id = await client.enqueueDownload(candidate);
      await _waitForPhase(client, id, UpdateDownloadPhase.complete);

      expect(await client.install(id, candidate), UpdateInstallResult.launched);
      expect(installer.request?.sha256, candidate.artifact.sha256);
      expect(installer.request?.version, candidate.release.version);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(exitCode, 0);
    },
  );
}

final class _FakeInstaller implements DesktopUpdateInstaller {
  DesktopInstallRequest? request;

  @override
  bool canInstall(String platform) => platform == 'linux';

  @override
  Future<bool> launch(DesktopInstallRequest value) async {
    request = value;
    return true;
  }
}

UpdateCandidate _candidate(List<int> bytes, {String? declaredDigest}) {
  final digest = declaredDigest ?? sha256.convert(bytes).toString();
  final manifest = manifestOf([
    releaseJson(
      build: 10800,
      channel: 'stable',
      artifacts: [
        {
          'platform': 'linux',
          'architecture': 'x64',
          'format': 'appimage',
          'primary': true,
          'fileName': 'Habiter-1.8.0-x86_64.AppImage',
          'signed': false,
          'url': 'https://downloads.example/Habiter.AppImage',
          'sha256': digest,
          'size': bytes.length,
        },
      ],
    ),
  ]);
  return const UpdateSelector().select(
    manifest: manifest,
    track: UpdateTrack.stable,
    currentBuild: 10702,
    platform: 'linux',
    architecture: 'x64',
  )!;
}

Future<UpdateDownloadStatus> _waitForPhase(
  IoDesktopUpdateClient client,
  String id,
  UpdateDownloadPhase phase,
) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final status = await client.downloadStatus(id);
    if (status.phase == phase) return status;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw StateError('Download did not reach $phase.');
}
