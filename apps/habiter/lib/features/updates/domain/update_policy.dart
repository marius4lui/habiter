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
    String architecture = 'universal',
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
      final artifact = artifactFor(
        release: release,
        platform: platform,
        architecture: architecture,
        androidDistribution: androidDistribution,
      );
      if (artifact != null) {
        return UpdateCandidate(release: release, artifact: artifact);
      }
    }
    return null;
  }

  UpdateArtifact? artifactFor({
    required UpdateRelease release,
    required String platform,
    required String architecture,
    AndroidDistribution? androidDistribution,
  }) {
    final matches = release.artifacts
        .where((artifact) {
          if (artifact.platform != platform ||
              !_architectureMatches(artifact.architecture, architecture)) {
            return false;
          }
          return switch (platform) {
            'android' =>
              artifact.distribution == androidDistribution &&
                  artifact.signed &&
                  artifact.format ==
                      (androidDistribution == AndroidDistribution.direct
                          ? UpdateArtifactFormat.apk
                          : UpdateArtifactFormat.aab),
            'windows' =>
              artifact.primary == true &&
                  artifact.format == UpdateArtifactFormat.zip,
            'macos' =>
              artifact.primary == true &&
                  artifact.format == UpdateArtifactFormat.zip,
            'linux' =>
              artifact.primary == true &&
                  artifact.format == UpdateArtifactFormat.appImage,
            _ => false,
          };
        })
        .toList(growable: false);
    return matches.length == 1 ? matches.single : null;
  }

  bool _architectureMatches(String artifact, String runtime) =>
      artifact == runtime || artifact == 'universal';

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
