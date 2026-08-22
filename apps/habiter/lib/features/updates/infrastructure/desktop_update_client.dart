import '../domain/update_models.dart';
import '../domain/update_platform_gateway.dart';

abstract interface class DesktopUpdateClient {
  bool canSelfUpdate(String platform);

  Future<String> enqueueDownload(UpdateCandidate candidate);

  Future<UpdateDownloadStatus> downloadStatus(String downloadId);

  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  );

  Future<void> removeDownload(String downloadId);

  Future<void> clearDownloads();

  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  );

  Future<int> storedDownloadBytes();

  Future<void> cleanupAfterUpgrade(int currentBuild);
}
