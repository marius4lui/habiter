import 'update_models.dart';

final class UpdateRuntimeInfo {
  const UpdateRuntimeInfo({
    required this.platform,
    required this.version,
    required this.buildNumber,
    required this.supportsUpdates,
    required this.supportsDirectInstall,
    this.androidDistribution,
    this.installerSource,
  });

  final String platform;
  final String version;
  final int buildNumber;
  final bool supportsUpdates;
  final bool supportsDirectInstall;
  final AndroidDistribution? androidDistribution;
  final String? installerSource;
}

final class UpdateNetworkStatus {
  const UpdateNetworkStatus({required this.isOnline, required this.isMetered});

  final bool isOnline;
  final bool isMetered;
}

enum UpdateDownloadPhase { queued, running, paused, complete, failed, missing }

final class UpdateDownloadStatus {
  const UpdateDownloadStatus({
    required this.phase,
    required this.downloadedBytes,
    required this.totalBytes,
    this.failureCode,
  });

  final UpdateDownloadPhase phase;
  final int downloadedBytes;
  final int totalBytes;
  final String? failureCode;

  double get progress => totalBytes <= 0
      ? 0
      : (downloadedBytes / totalBytes).clamp(0, 1).toDouble();
}

final class UpdateVerificationResult {
  const UpdateVerificationResult.valid() : isValid = true, failureCode = null;

  const UpdateVerificationResult.invalid(this.failureCode) : isValid = false;

  final bool isValid;
  final String? failureCode;
}

enum UpdateInstallResult {
  launched,
  permissionRequired,
  externalOpened,
  unavailable,
}

abstract interface class UpdatePlatformGateway {
  Future<UpdateRuntimeInfo> runtimeInfo();

  Future<UpdateNetworkStatus> networkStatus();

  Future<String> enqueueDownload(
    UpdateCandidate candidate, {
    required bool allowMetered,
  });

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

  Future<void> openInstallerPermission();

  Future<UpdateInstallResult> openExternal(UpdateCandidate candidate);

  Future<int> storedDownloadBytes();

  Future<void> cleanupAfterUpgrade(int currentBuild);
}
