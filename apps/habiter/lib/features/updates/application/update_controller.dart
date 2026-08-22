import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/time/clock.dart';
import '../data/signed_manifest_client.dart';
import '../data/update_local_repository.dart';
import '../domain/update_models.dart';
import '../domain/update_platform_gateway.dart';
import '../domain/update_policy.dart';
import '../domain/update_state.dart';

final class UpdateController extends ChangeNotifier {
  UpdateController({
    required UpdateLocalRepository repository,
    required SignedManifestClient client,
    required ManifestVerifier verifier,
    required UpdatePlatformGateway platform,
    required Clock clock,
    UpdatePolicy policy = const UpdatePolicy(),
    UpdateSelector selector = const UpdateSelector(),
  }) : _repository = repository,
       _client = client,
       _verifier = verifier,
       _platform = platform,
       _clock = clock,
       _policy = policy,
       _selector = selector;

  final UpdateLocalRepository _repository;
  final SignedManifestClient _client;
  final ManifestVerifier _verifier;
  final UpdatePlatformGateway _platform;
  final Clock _clock;
  final UpdatePolicy _policy;
  final UpdateSelector _selector;

  UpdateState _state = const UpdateState();
  UpdateLocalState _local = const UpdateLocalState();
  UpdateRuntimeInfo? _runtime;
  UpdateManifest? _manifest;
  List<UpdateRelease> _upgradeReleases = const [];
  bool _initialized = false;
  bool _checking = false;
  bool _pollingDownload = false;
  bool _mandatoryEnforced = false;
  Timer? _downloadPoller;

  UpdateState get state => _state;
  UpdateTrack get track => _local.track;
  UpdateProfile get profile => _local.profile;
  UpdateRuntimeInfo? get runtime => _runtime;
  UpdateManifest? get manifest => _manifest;
  List<UpdateRelease> get upgradeReleases => _upgradeReleases;
  bool get initialized => _initialized;
  bool get canCheck => !const {
    UpdatePhase.checking,
    UpdatePhase.downloading,
    UpdatePhase.verifying,
    UpdatePhase.installing,
    UpdatePhase.unsupported,
  }.contains(_state.phase);
  bool get mandatoryEnforced => _mandatoryEnforced;
  bool get hasExpiredMandatoryCandidate =>
      _state.candidate?.release.isMandatoryAt(_clock.now()) == true;
  bool get shouldShowAvailableStory =>
      _state.candidate != null &&
      !_local.presentedBuilds.contains(_state.candidate!.release.buildNumber);
  bool get shouldShowUpgradeStory => _upgradeReleases.isNotEmpty;
  int get cachedMetadataBytes => _local.metadataBytes;
  bool get candidateUsesExternalInstaller {
    final runtime = _runtime;
    final candidate = _state.candidate;
    return runtime != null &&
        candidate != null &&
        !_canInstallDirectly(runtime, candidate);
  }

  bool get canCancelDownload =>
      _state.phase == UpdatePhase.downloading &&
      !(_runtime?.platform == 'android' &&
          _runtime?.androidDistribution == AndroidDistribution.play);

  Future<void> initialize() async {
    if (_initialized) return;
    _local = await _repository.load();
    try {
      _runtime = await _platform.runtimeInfo();
    } on Object {
      _state = const UpdateState(
        phase: UpdatePhase.error,
        errorCode: 'runtime_info_failed',
      );
      _initialized = true;
      notifyListeners();
      return;
    }
    if (_runtime?.supportsUpdates != true) {
      _state = const UpdateState(phase: UpdatePhase.unsupported);
      _initialized = true;
      notifyListeners();
      return;
    }
    await _restoreVerifiedCache();
    await _reconcileUpgrade();
    await _reconcileDownload();
    _initialized = true;
    notifyListeners();
    unawaited(check(UpdateCheckTrigger.startup));
  }

  Future<void> _restoreVerifiedCache() async {
    final cached = _local.cachedEnvelope;
    if (cached == null) return;
    try {
      _manifest = (await _verifier.verify(cached)).manifest;
      _applyCandidate(verifiedOnline: false);
    } on Object {
      _local = _local.copyWith(
        cachedEnvelope: null,
        etag: null,
        lastCheckedAt: null,
      );
      await _repository.save(_local);
    }
  }

  Future<void> _reconcileUpgrade() async {
    final runtime = _runtime!;
    final previous = _local.previousAppBuild;
    if (previous == null) {
      _local = _local.copyWith(previousAppBuild: runtime.buildNumber);
      await _repository.save(_local);
      return;
    }
    if (previous < runtime.buildNumber) {
      final manifest = _manifest;
      if (manifest == null) return;
      _upgradeReleases = _selector.releasesBetween(
        manifest: manifest,
        previousBuild: previous,
        currentBuild: runtime.buildNumber,
      );
      await _platform.cleanupAfterUpgrade(runtime.buildNumber);
      _local = _local.copyWith(
        previousAppBuild: runtime.buildNumber,
        downloadId: null,
        downloadBuild: null,
      );
      await _repository.save(_local);
    }
  }

  Future<void> _reconcileDownload() async {
    var id = _local.downloadId;
    var build = _local.downloadBuild;
    final manifest = _manifest;
    if ((id == null || build == null) &&
        manifest != null &&
        _runtime?.platform == 'android' &&
        _runtime?.androidDistribution == AndroidDistribution.play) {
      final candidate = _selector.select(
        manifest: manifest,
        track: track,
        currentBuild: _runtime!.buildNumber,
        platform: 'android',
        architecture: _runtime!.architecture,
        androidDistribution: AndroidDistribution.play,
      );
      if (candidate != null) {
        try {
          final status = await _platform.downloadStatus(_playDownloadId);
          if (const {
            UpdateDownloadPhase.queued,
            UpdateDownloadPhase.running,
            UpdateDownloadPhase.paused,
            UpdateDownloadPhase.complete,
          }.contains(status.phase)) {
            id = _playDownloadId;
            build = candidate.release.buildNumber;
            _local = _local.copyWith(downloadId: id, downloadBuild: build);
            await _repository.save(_local);
          }
        } on Object {
          // A Store status lookup must not make startup fail.
        }
      }
    }
    if (id == null || build == null || manifest == null) return;
    final candidate = _candidateForBuild(manifest, build);
    if (candidate == null) {
      await _clearDownload(removeNative: true);
      return;
    }
    late final UpdateDownloadStatus download;
    try {
      download = await _platform.downloadStatus(id);
    } on Object {
      _state = UpdateState(
        phase: UpdatePhase.error,
        candidate: candidate,
        errorCode: 'download_status_failed',
        lastCheckedAt: _local.lastCheckedAt,
      );
      return;
    }
    switch (download.phase) {
      case UpdateDownloadPhase.complete:
        _state = UpdateState(
          phase: UpdatePhase.verifying,
          candidate: candidate,
          progress: 1,
        );
        await _verifyCompletedDownload();
      case UpdateDownloadPhase.queued ||
          UpdateDownloadPhase.running ||
          UpdateDownloadPhase.paused:
        _state = UpdateState(
          phase: UpdatePhase.downloading,
          candidate: candidate,
          progress: download.progress,
        );
        _startDownloadPolling();
      case UpdateDownloadPhase.failed || UpdateDownloadPhase.missing:
        await _clearDownload(removeNative: true);
    }
  }

  Future<void> check(UpdateCheckTrigger trigger) async {
    if (!_initialized || _checking || !canCheck) {
      return;
    }
    if (!_policy.shouldCheck(
      profile: profile,
      trigger: trigger,
      now: _clock.now(),
      lastCheckedAt: _local.lastCheckedAt,
    )) {
      return;
    }
    _checking = true;
    final previousPhase = _state.phase;
    final previousCandidate = _state.candidate;
    _transition(UpdatePhase.checking);
    try {
      final network = await _platform.networkStatus();
      if (!network.isOnline) {
        _mandatoryEnforced = false;
        _state = UpdateState(
          phase: UpdatePhase.error,
          candidate: _state.candidate,
          errorCode: 'offline',
          isOnline: false,
          lastCheckedAt: _local.lastCheckedAt,
        );
        notifyListeners();
        return;
      }
      final fetched = await _client.fetch(etag: _local.etag);
      final envelopeJson = fetched.envelopeJson ?? _local.cachedEnvelope;
      if (envelopeJson == null) {
        throw const FormatException('Server returned no verifiable manifest.');
      }
      final verified = await _verifier.verify(envelopeJson);
      _manifest = verified.manifest;
      await _reconcileUpgrade();
      final checkedAt = _clock.now().toUtc();
      _local = _local.copyWith(
        cachedEnvelope: envelopeJson,
        etag: fetched.etag ?? _local.etag,
        lastCheckedAt: checkedAt,
      );
      await _repository.save(_local);
      final retainedPhase = await _reconcileRefreshedCandidate(
        previousPhase: previousPhase,
        previousCandidate: previousCandidate,
      );
      _applyCandidate(verifiedOnline: true, retainedPhase: retainedPhase);
      final candidate = _state.candidate;
      if (candidate != null &&
          const {
            UpdatePhase.available,
            UpdatePhase.mandatory,
          }.contains(_state.phase) &&
          _canInstallDirectly(_runtime!, candidate) &&
          _policy.shouldAutoDownload(
            profile: profile,
            isOnline: true,
            isMetered: network.isMetered,
          )) {
        await download(allowMetered: profile == UpdateProfile.immediate);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Update check failed: $error\n$stackTrace');
      _mandatoryEnforced = false;
      _state = UpdateState(
        phase: UpdatePhase.error,
        candidate: _state.candidate,
        errorCode: 'check_failed',
        isOnline: true,
        lastCheckedAt: _local.lastCheckedAt,
      );
      notifyListeners();
    } finally {
      _checking = false;
    }
  }

  void _applyCandidate({
    required bool verifiedOnline,
    UpdatePhase? retainedPhase,
  }) {
    final manifest = _manifest;
    final runtime = _runtime;
    if (manifest == null || runtime == null || !runtime.supportsUpdates) {
      _state = UpdateState(
        phase: UpdatePhase.upToDate,
        lastCheckedAt: _local.lastCheckedAt,
      );
      notifyListeners();
      return;
    }
    final candidate = _selector.select(
      manifest: manifest,
      track: track,
      currentBuild: runtime.buildNumber,
      platform: runtime.platform,
      architecture: runtime.architecture,
      androidDistribution: runtime.androidDistribution,
    );
    if (candidate == null) {
      _mandatoryEnforced = false;
      _state = UpdateState(
        phase: UpdatePhase.upToDate,
        lastCheckedAt: _local.lastCheckedAt,
      );
    } else {
      final mandatory =
          verifiedOnline && candidate.release.isMandatoryAt(_clock.now());
      _mandatoryEnforced = mandatory;
      _state = UpdateState(
        phase:
            retainedPhase ??
            (_mandatoryEnforced
                ? UpdatePhase.mandatory
                : UpdatePhase.available),
        candidate: candidate,
        progress: retainedPhase == null ? 0 : 1,
        lastCheckedAt: _local.lastCheckedAt,
      );
    }
    notifyListeners();
  }

  Future<UpdatePhase?> _reconcileRefreshedCandidate({
    required UpdatePhase previousPhase,
    required UpdateCandidate? previousCandidate,
  }) async {
    if (_local.downloadId == null || _local.downloadBuild == null) return null;
    final selected = _selectedCandidate();
    final canRetain =
        selected != null &&
        selected.release.buildNumber == _local.downloadBuild &&
        previousCandidate != null &&
        _sameArtifact(selected.artifact, previousCandidate.artifact);
    if (!canRetain) {
      await _clearDownload(removeNative: true);
      return null;
    }
    return const {
          UpdatePhase.ready,
          UpdatePhase.restartRequired,
        }.contains(previousPhase)
        ? previousPhase
        : null;
  }

  UpdateCandidate? _selectedCandidate() {
    final manifest = _manifest;
    final runtime = _runtime;
    if (manifest == null || runtime == null) return null;
    return _selector.select(
      manifest: manifest,
      track: track,
      currentBuild: runtime.buildNumber,
      platform: runtime.platform,
      architecture: runtime.architecture,
      androidDistribution: runtime.androidDistribution,
    );
  }

  static bool _sameArtifact(UpdateArtifact left, UpdateArtifact right) =>
      left.platform == right.platform &&
      left.architecture == right.architecture &&
      left.format == right.format &&
      left.fileName == right.fileName &&
      left.signed == right.signed &&
      left.distribution == right.distribution &&
      left.url == right.url &&
      left.sha256 == right.sha256 &&
      left.size == right.size;

  UpdateCandidate? _candidateForBuild(UpdateManifest manifest, int build) {
    final runtime = _runtime!;
    final release = manifest.releases
        .where((item) => item.buildNumber == build)
        .firstOrNull;
    if (release == null) return null;
    final artifact = _selector.artifactFor(
      release: release,
      platform: runtime.platform,
      architecture: runtime.architecture,
      androidDistribution: runtime.androidDistribution,
    );
    return artifact == null
        ? null
        : UpdateCandidate(release: release, artifact: artifact);
  }

  Future<void> setTrack(UpdateTrack value) async {
    if (track == value) return;
    if (_local.downloadId != null) {
      await _clearDownload(removeNative: true);
    }
    _local = _local.copyWith(track: value);
    await _repository.save(_local);
    _applyCandidate(verifiedOnline: false);
    await check(UpdateCheckTrigger.manual);
  }

  Future<void> setProfile(UpdateProfile value) async {
    if (profile == value) return;
    _local = _local.copyWith(profile: value);
    await _repository.save(_local);
    notifyListeners();
  }

  Future<void> markAvailableStoryPresented() async {
    final build = _state.candidate?.release.buildNumber;
    if (build == null || _local.presentedBuilds.contains(build)) return;
    _local = _local.copyWith(
      presentedBuilds: {..._local.presentedBuilds, build},
    );
    await _repository.save(_local);
    notifyListeners();
  }

  void dismissUpgradeStory() {
    _upgradeReleases = const [];
    notifyListeners();
  }

  Future<void> download({bool allowMetered = true}) async {
    final candidate = _state.candidate;
    final runtime = _runtime;
    if (candidate == null || runtime == null) return;
    if (!_canInstallDirectly(runtime, candidate)) {
      _transition(UpdatePhase.downloading, candidate: candidate, progress: 0);
      try {
        final result = await _platform.openExternal(candidate);
        if (result == UpdateInstallResult.launched &&
            runtime.platform == 'android' &&
            runtime.androidDistribution == AndroidDistribution.play) {
          _local = _local.copyWith(
            downloadId: _playDownloadId,
            downloadBuild: candidate.release.buildNumber,
          );
          await _repository.save(_local);
          _startDownloadPolling();
        } else if (result == UpdateInstallResult.unavailable) {
          _transition(
            UpdatePhase.error,
            errorCode: 'external_update_unavailable',
          );
        } else {
          _returnToCandidateState();
        }
      } on Object {
        _transition(
          UpdatePhase.error,
          errorCode: 'external_update_unavailable',
        );
      }
      return;
    }
    try {
      _transition(UpdatePhase.downloading, candidate: candidate, progress: 0);
      final id = await _platform.enqueueDownload(
        candidate,
        allowMetered: allowMetered,
      );
      _local = _local.copyWith(
        downloadId: id,
        downloadBuild: candidate.release.buildNumber,
      );
      await _repository.save(_local);
      _startDownloadPolling();
    } on Object {
      _transition(UpdatePhase.error, errorCode: 'download_failed');
    }
  }

  void _startDownloadPolling() {
    _downloadPoller?.cancel();
    _downloadPoller = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(pollDownload()),
    );
  }

  Future<void> pollDownload() async {
    if (_pollingDownload) return;
    final id = _local.downloadId;
    if (id == null) return;
    _pollingDownload = true;
    try {
      final status = await _platform.downloadStatus(id);
      switch (status.phase) {
        case UpdateDownloadPhase.queued ||
            UpdateDownloadPhase.running ||
            UpdateDownloadPhase.paused:
          _transition(UpdatePhase.downloading, progress: status.progress);
        case UpdateDownloadPhase.complete:
          _downloadPoller?.cancel();
          _transition(UpdatePhase.verifying, progress: 1);
          await _verifyCompletedDownload();
        case UpdateDownloadPhase.failed || UpdateDownloadPhase.missing:
          _downloadPoller?.cancel();
          await _clearDownload(removeNative: true);
          _transition(
            UpdatePhase.error,
            errorCode: status.failureCode ?? 'download_failed',
          );
      }
    } on Object {
      _downloadPoller?.cancel();
      _transition(UpdatePhase.error, errorCode: 'download_status_failed');
    } finally {
      _pollingDownload = false;
    }
  }

  Future<void> _verifyCompletedDownload() async {
    final id = _local.downloadId;
    final candidate = _state.candidate;
    if (id == null || candidate == null) return;
    late final UpdateVerificationResult result;
    try {
      result = await _platform.verifyDownload(id, candidate);
    } on Object {
      _transition(UpdatePhase.error, errorCode: 'verification_failed');
      return;
    }
    if (result.isValid) {
      final restart =
          _runtime?.platform == 'android' &&
          _runtime?.androidDistribution == AndroidDistribution.play;
      _transition(
        restart ? UpdatePhase.restartRequired : UpdatePhase.ready,
        progress: 1,
      );
    } else {
      await _clearDownload(removeNative: true);
      _transition(
        UpdatePhase.error,
        errorCode: result.failureCode ?? 'verification_failed',
      );
    }
  }

  Future<UpdateInstallResult> install() async {
    final id = _local.downloadId;
    final candidate = _state.candidate;
    if (id == null || candidate == null) return UpdateInstallResult.unavailable;
    _transition(UpdatePhase.installing);
    try {
      final result = await _platform.install(id, candidate);
      if (result != UpdateInstallResult.launched) {
        _transition(
          id == _playDownloadId
              ? UpdatePhase.restartRequired
              : UpdatePhase.ready,
        );
      }
      return result;
    } on Object {
      await _clearDownload(removeNative: true);
      _transition(UpdatePhase.error, errorCode: 'install_failed');
      return UpdateInstallResult.unavailable;
    }
  }

  Future<void> openInstallerPermission() => _platform.openInstallerPermission();

  Future<void> clearDownloads() async {
    _downloadPoller?.cancel();
    try {
      await _platform.clearDownloads();
    } on Object {
      _state = UpdateState(
        phase: UpdatePhase.error,
        candidate: _state.candidate,
        errorCode: 'storage_cleanup_failed',
        isOnline: _state.isOnline,
        lastCheckedAt: _local.lastCheckedAt,
      );
      notifyListeners();
      return;
    }
    _local = _local.copyWith(downloadId: null, downloadBuild: null);
    await _repository.save(_local);
    final candidate = _state.candidate;
    _state = UpdateState(
      phase: candidate == null ? UpdatePhase.idle : UpdatePhase.available,
      candidate: candidate,
      lastCheckedAt: _local.lastCheckedAt,
    );
    notifyListeners();
  }

  Future<void> cancelDownload() async {
    if (_state.phase != UpdatePhase.downloading) return;
    await _clearDownload(removeNative: true);
    _returnToCandidateState();
  }

  Future<void> clearManifestCache() async {
    _downloadPoller?.cancel();
    final id = _local.downloadId;
    if (id != null) {
      try {
        await _platform.removeDownload(id);
      } on Object {
        _state = UpdateState(
          phase: UpdatePhase.error,
          candidate: _state.candidate,
          errorCode: 'storage_cleanup_failed',
          isOnline: _state.isOnline,
          lastCheckedAt: _local.lastCheckedAt,
        );
        notifyListeners();
        return;
      }
    }
    _manifest = null;
    _mandatoryEnforced = false;
    _local = _local.copyWith(
      cachedEnvelope: null,
      etag: null,
      lastCheckedAt: null,
      downloadId: null,
      downloadBuild: null,
    );
    await _repository.save(_local);
    _state = const UpdateState();
    notifyListeners();
  }

  Future<int> storedDownloadBytes() => _platform.storedDownloadBytes();

  Future<void> _clearDownload({required bool removeNative}) async {
    _downloadPoller?.cancel();
    final id = _local.downloadId;
    if (removeNative && id != null) await _platform.removeDownload(id);
    _local = _local.copyWith(downloadId: null, downloadBuild: null);
    await _repository.save(_local);
  }

  void _transition(
    UpdatePhase phase, {
    UpdateCandidate? candidate,
    double? progress,
    String? errorCode,
  }) {
    _state = _state.transition(
      phase,
      candidate: candidate,
      progress: progress,
      errorCode: errorCode,
      lastCheckedAt: _local.lastCheckedAt,
    );
    notifyListeners();
  }

  Future<void> handleResume() async {
    await _reconcileDownload();
    await _refreshConnectivity();
    await check(UpdateCheckTrigger.resume);
  }

  Future<void> _refreshConnectivity() async {
    var isOnline = false;
    try {
      isOnline = (await _platform.networkStatus()).isOnline;
    } on Object {
      // Unknown connectivity must never keep a mandatory screen locked.
    }
    if (_state.isOnline == isOnline) return;
    _state = UpdateState(
      phase: _state.phase,
      candidate: _state.candidate,
      progress: _state.progress,
      errorCode: _state.errorCode,
      isOnline: isOnline,
      lastCheckedAt: _state.lastCheckedAt,
    );
    notifyListeners();
  }

  Future<void> handleForegroundTick() =>
      check(UpdateCheckTrigger.foregroundTimer);

  bool _canInstallDirectly(
    UpdateRuntimeInfo runtime,
    UpdateCandidate candidate,
  ) =>
      runtime.supportsDirectInstall &&
      (!const {'windows', 'macos'}.contains(runtime.platform) ||
          candidate.artifact.signed);

  void _returnToCandidateState() {
    _transition(
      _mandatoryEnforced ? UpdatePhase.mandatory : UpdatePhase.available,
    );
  }

  @override
  void dispose() {
    _downloadPoller?.cancel();
    super.dispose();
  }

  static const String _playDownloadId = 'play';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
