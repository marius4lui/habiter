import '../domain/update_models.dart';
import '../domain/update_platform_gateway.dart';
import 'desktop_update_client.dart';

DesktopUpdateClient createDesktopUpdateClient() => _client;

const DesktopUpdateClient _client = _UnsupportedDesktopUpdateClient();

final class _UnsupportedDesktopUpdateClient implements DesktopUpdateClient {
  const _UnsupportedDesktopUpdateClient();

  @override
  bool canSelfUpdate(String platform) => false;

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) async {}

  @override
  Future<void> clearDownloads() async {}

  @override
  Future<String> enqueueDownload(UpdateCandidate candidate) =>
      Future.error(UnsupportedError('Desktop downloads are unavailable.'));

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async =>
      const UpdateDownloadStatus(
        phase: UpdateDownloadPhase.missing,
        downloadedBytes: 0,
        totalBytes: 0,
      );

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async => UpdateInstallResult.unavailable;

  @override
  Future<void> removeDownload(String downloadId) async {}

  @override
  Future<int> storedDownloadBytes() async => 0;

  @override
  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  ) async => const UpdateVerificationResult.invalid('unsupported_platform');
}
