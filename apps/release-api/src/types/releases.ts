export type Platform = "android" | "windows" | "linux" | "macos" | "ios" | "web";
export type ReleaseChannel = "stable" | "beta";

export interface ReleaseArtifact {
  platform: Platform;
  architecture: string;
  fileName: string;
  signed: boolean;
  url?: string;
  sha256?: string;
  size?: number;
}

export interface ReleaseNotes {
  added: string[];
  changed: string[];
  fixed: string[];
  security: string[];
}

export interface Release {
  version: string;
  buildNumber: number;
  channel: ReleaseChannel;
  status: "draft" | "published";
  publishedAt: string | null;
  minimumSupportedVersion: string;
  mandatoryAfter: string | null;
  notes: ReleaseNotes;
  artifacts: ReleaseArtifact[];
}

export interface ReleaseManifest {
  schemaVersion: number;
  releases: Release[];
}
