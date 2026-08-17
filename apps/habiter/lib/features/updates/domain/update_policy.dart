import 'update_models.dart';

enum UpdateCheckTrigger { startup, resume, foregroundTimer, manual }

final class UpdatePolicy {
  const UpdatePolicy();

  Duration intervalFor(UpdateProfile profile) => switch (profile) {
    UpdateProfile.immediate => const Duration(hours: 1),
    UpdateProfile.balanced => const Duration(hours: 24),
    UpdateProfile.saver => const Duration(days: 7),
  };

  bool shouldCheck({
    required UpdateProfile profile,
    required UpdateCheckTrigger trigger,
    required DateTime now,
    required DateTime? lastCheckedAt,
  }) {
    if (trigger == UpdateCheckTrigger.manual) return true;
    if (profile == UpdateProfile.immediate &&
        (trigger == UpdateCheckTrigger.startup ||
            trigger == UpdateCheckTrigger.resume)) {
      return true;
    }
    if (lastCheckedAt == null) return true;
    return now.toUtc().difference(lastCheckedAt.toUtc()) >=
        intervalFor(profile);
  }

  bool shouldAutoDownload({
    required UpdateProfile profile,
    required bool isOnline,
    required bool isMetered,
  }) {
    if (!isOnline) return false;
    return switch (profile) {
      UpdateProfile.immediate => true,
      UpdateProfile.balanced => !isMetered,
      UpdateProfile.saver => false,
    };
  }
}

final class UpdateSelector {
  const UpdateSelector();

  UpdateCandidate? select({
    required UpdateManifest manifest,
    required UpdateTrack track,
    required int currentBuild,
    required String platform,
    AndroidDistribution? androidDistribution,
  }) {
    final allowedChannels = track == UpdateTrack.stable
        ? const {ReleaseChannel.stable}
        : const {ReleaseChannel.stable, ReleaseChannel.beta};
    for (final release in manifest.releases) {
      if (release.buildNumber <= currentBuild ||
          !allowedChannels.contains(release.channel)) {
        continue;
      }
      final artifact = release.artifacts.cast<UpdateArtifact?>().firstWhere(
        (item) =>
            item!.platform == platform &&
            (platform != 'android' || item.distribution == androidDistribution),
        orElse: () => null,
      );
      if (artifact != null) {
        return UpdateCandidate(release: release, artifact: artifact);
      }
    }
    return null;
  }

  List<UpdateRelease> releasesBetween({
    required UpdateManifest manifest,
    required int previousBuild,
    required int currentBuild,
  }) => manifest.releases
      .where(
        (release) =>
            release.buildNumber > previousBuild &&
            release.buildNumber <= currentBuild,
      )
      .toList(growable: false);
}
