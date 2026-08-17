import type { Platform, Release, ReleaseArtifact, ReleaseChannel, ReleaseManifest } from "../types/releases";

function compareVersions(left: string, right: string): number {
  const a = left.split(".").map(Number);
  const b = right.split(".").map(Number);
  for (let index = 0; index < 3; index += 1) {
    const difference = (a[index] ?? 0) - (b[index] ?? 0);
    if (difference !== 0) return difference;
  }
  return 0;
}

export class ReleaseService {
  readonly #published: Release[];

  constructor(manifest: ReleaseManifest) {
    this.#published = manifest.releases
      .filter((release) => release.status === "published")
      .sort((left, right) => right.buildNumber - left.buildNumber);
  }

  list(channel: ReleaseChannel, page: number, limit: number) {
    const matches = this.#published.filter((release) => release.channel === channel);
    const start = (page - 1) * limit;
    return {
      page,
      limit,
      total: matches.length,
      releases: matches.slice(start, start + limit).map((release) => ({
        version: release.version,
        buildNumber: release.buildNumber,
        channel: release.channel,
        publishedAt: release.publishedAt
      }))
    };
  }

  latest(channel: ReleaseChannel): Release | null {
    return this.#published.find((release) => release.channel === channel) ?? null;
  }

  find(version: string): Release | null {
    return this.#published.find((release) => release.version === version) ?? null;
  }

  artifact(release: Release, platform: Platform, architecture: string): ReleaseArtifact | null {
    return release.artifacts.find((artifact) =>
      artifact.platform === platform && artifact.architecture === architecture && artifact.url
    ) ?? null;
  }

  checkUpdate(platform: Platform, currentVersion: string, currentBuild: number, channel: ReleaseChannel, now: Date) {
    const latest = this.latest(channel);
    if (!latest) return null;
    const updateAvailable = latest.buildNumber > currentBuild || compareVersions(latest.version, currentVersion) > 0;
    return {
      platform,
      updateAvailable,
      mandatory: updateAvailable && latest.mandatoryAfter !== null && now >= new Date(latest.mandatoryAfter),
      current: { version: currentVersion, buildNumber: currentBuild },
      target: { version: latest.version, buildNumber: latest.buildNumber },
      minimumSupportedVersion: latest.minimumSupportedVersion,
      download: `/api/v1/download/${platform}`
    };
  }
}
