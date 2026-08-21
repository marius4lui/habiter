import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/update_models.dart';
import '../domain/update_platform_gateway.dart';
import 'desktop_update_client.dart';
import 'desktop_update_client_factory.dart';
import 'runtime_architecture.dart';

final class MethodChannelUpdatePlatformGateway
    implements UpdatePlatformGateway {
  const MethodChannelUpdatePlatformGateway({
    MethodChannel channel = const MethodChannel('com.habiter.app/updates'),
    TargetPlatform? platformOverride,
    bool? webOverride,
    Future<bool> Function(Uri)? externalUrlLauncher,
    DesktopUpdateClient? desktopClient,
  }) : _channel = channel,
       _platformOverride = platformOverride,
       _webOverride = webOverride,
       _externalUrlLauncher = externalUrlLauncher,
       _desktopClient = desktopClient;

  final MethodChannel _channel;
  final TargetPlatform? _platformOverride;
  final bool? _webOverride;
  final Future<bool> Function(Uri)? _externalUrlLauncher;
  final DesktopUpdateClient? _desktopClient;

  DesktopUpdateClient get _desktop =>
      _desktopClient ?? createDesktopUpdateClient();

  @override
  Future<UpdateRuntimeInfo> runtimeInfo() async {
    final package = await PackageInfo.fromPlatform();
    final build = int.tryParse(package.buildNumber) ?? 0;
    final platform = _platformName;
    if (platform == 'android') {
      final data = await _channel.invokeMapMethod<String, Object?>(
        'getRuntimeInfo',
      );
      final distribution = switch (data?['distribution']) {
        'direct' => AndroidDistribution.direct,
        _ => AndroidDistribution.play,
      };
      return UpdateRuntimeInfo(
        platform: platform,
        architecture: runtimeArchitecture(platform),
        version: package.version,
        buildNumber: build,
        supportsUpdates: true,
        supportsDirectInstall:
            distribution == AndroidDistribution.direct &&
            data?['directInstallAllowed'] == true,
        androidDistribution: distribution,
        installerSource: data?['installerSource'] as String?,
      );
    }
    return UpdateRuntimeInfo(
      platform: platform,
      architecture: runtimeArchitecture(platform),
      version: package.version,
      buildNumber: build,
      supportsUpdates: const {'windows', 'linux', 'macos'}.contains(platform),
      supportsDirectInstall: _desktop.canSelfUpdate(platform),
    );
  }

  @override
  Future<UpdateNetworkStatus> networkStatus() async {
    if (_platformName != 'android') {
      return const UpdateNetworkStatus(isOnline: true, isMetered: false);
    }
    final data = await _channel.invokeMapMethod<String, Object?>(
      'getNetworkStatus',
    );
    return UpdateNetworkStatus(
      isOnline: data?['isOnline'] == true,
      isMetered: data?['isMetered'] == true,
    );
  }

  @override
  Future<String> enqueueDownload(
    UpdateCandidate candidate, {
    required bool allowMetered,
  }) async {
    if (_isDesktop) return _desktop.enqueueDownload(candidate);
    final id = await _channel.invokeMethod<Object?>('enqueueDownload', {
      'url': candidate.artifact.url.toString(),
      'fileName': candidate.artifact.fileName,
      'sha256': candidate.artifact.sha256,
      'size': candidate.artifact.size,
      'buildNumber': candidate.release.buildNumber,
      'allowMetered': allowMetered,
    });
    if (id == null) throw PlatformException(code: 'download_rejected');
    return id.toString();
  }

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async {
    if (_isDesktop) return _desktop.downloadStatus(downloadId);
    if (_platformName == 'android' && downloadId == _playDownloadId) {
      final data = await _channel.invokeMapMethod<String, Object?>(
        'getStoreUpdateStatus',
      );
      return _downloadStatusFromData(data);
    }
    final data = await _channel.invokeMapMethod<String, Object?>(
      'getDownloadStatus',
      {'downloadId': downloadId},
    );
    return _downloadStatusFromData(data);
  }

  UpdateDownloadStatus _downloadStatusFromData(Map<String, Object?>? data) {
    return UpdateDownloadStatus(
      phase: switch (data?['phase']) {
        'queued' => UpdateDownloadPhase.queued,
        'running' => UpdateDownloadPhase.running,
        'paused' => UpdateDownloadPhase.paused,
        'complete' => UpdateDownloadPhase.complete,
        'failed' => UpdateDownloadPhase.failed,
        _ => UpdateDownloadPhase.missing,
      },
      downloadedBytes: (data?['downloadedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (data?['totalBytes'] as num?)?.toInt() ?? 0,
      failureCode: data?['failureCode'] as String?,
    );
  }

  @override
  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  ) async {
    if (_isDesktop) return _desktop.verifyDownload(downloadId, candidate);
    if (_platformName == 'android' && downloadId == _playDownloadId) {
      final status = await downloadStatus(downloadId);
      return status.phase == UpdateDownloadPhase.complete
          ? const UpdateVerificationResult.valid()
          : const UpdateVerificationResult.invalid('store_update_not_ready');
    }
    final data = await _channel
        .invokeMapMethod<String, Object?>('verifyDownload', {
          'downloadId': downloadId,
          'sha256': candidate.artifact.sha256,
          'size': candidate.artifact.size,
          'buildNumber': candidate.release.buildNumber,
          'version': candidate.release.version,
        });
    return data?['valid'] == true
        ? const UpdateVerificationResult.valid()
        : UpdateVerificationResult.invalid(
            data?['failureCode'] as String? ?? 'verification_failed',
          );
  }

  @override
  Future<void> removeDownload(String downloadId) => _isDesktop
      ? _desktop.removeDownload(downloadId)
      : _platformName == 'android' && downloadId == _playDownloadId
      ? Future<void>.value()
      : _channel.invokeMethod<void>('removeDownload', {
          'downloadId': downloadId,
        });

  @override
  Future<void> clearDownloads() async {
    if (_isDesktop) return _desktop.clearDownloads();
    if (_platformName != 'android') return;
    await _channel.invokeMethod<void>('clearDownloads');
  }

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async {
    if (_isDesktop) return _desktop.install(downloadId, candidate);
    if (_platformName == 'android' &&
        candidate.artifact.distribution == AndroidDistribution.play) {
      final result = await _channel.invokeMethod<String>('completeStoreUpdate');
      return result == 'launched'
          ? UpdateInstallResult.launched
          : UpdateInstallResult.unavailable;
    }
    final result = await _channel.invokeMethod<String>('installUpdate', {
      'downloadId': downloadId,
      'buildNumber': candidate.release.buildNumber,
    });
    return switch (result) {
      'launched' => UpdateInstallResult.launched,
      'permissionRequired' => UpdateInstallResult.permissionRequired,
      _ => UpdateInstallResult.unavailable,
    };
  }

  @override
  Future<void> openInstallerPermission() =>
      _channel.invokeMethod<void>('openInstallerPermission');

  @override
  Future<UpdateInstallResult> openExternal(UpdateCandidate candidate) async {
    final artifact = candidate.artifact;
    if (_platformName == 'android') {
      final result = await _channel.invokeMethod<String>('startStoreUpdate', {
        'immediate': candidate.release.isMandatoryAt(DateTime.now().toUtc()),
      });
      return switch (result) {
        'launched' => UpdateInstallResult.launched,
        'externalOpened' => UpdateInstallResult.externalOpened,
        'canceled' => UpdateInstallResult.canceled,
        _ => UpdateInstallResult.unavailable,
      };
    }
    final opened = await (_externalUrlLauncher ?? _launchExternal)(
      artifact.url,
    );
    return opened
        ? UpdateInstallResult.externalOpened
        : UpdateInstallResult.unavailable;
  }

  Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<int> storedDownloadBytes() async {
    if (_isDesktop) return _desktop.storedDownloadBytes();
    if (_platformName != 'android') return 0;
    return await _channel.invokeMethod<int>('storedDownloadBytes') ?? 0;
  }

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) async {
    if (_isDesktop) return _desktop.cleanupAfterUpgrade(currentBuild);
    if (_platformName != 'android') return;
    await _channel.invokeMethod<void>('cleanupAfterUpgrade', {
      'currentBuild': currentBuild,
    });
  }

  String get _platformName {
    if (_webOverride ?? kIsWeb) return 'web';
    return switch (_platformOverride ?? defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.fuchsia => 'unknown',
    };
  }

  bool get _isDesktop =>
      const {'windows', 'linux', 'macos'}.contains(_platformName);

  static const String _playDownloadId = 'play';
}
