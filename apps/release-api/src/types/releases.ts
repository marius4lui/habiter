export type Platform = "android" | "windows" | "linux" | "macos" | "ios" | "web";
export type ReleaseChannel = "stable" | "beta";
export type AndroidDistribution = "direct" | "play";

export interface ReleaseArtifact {
  platform: Platform;
  architecture: string;
  fileName: string;
  signed: boolean;
  distribution?: AndroidDistribution;
  url?: string;
  sha256?: string;
  size?: number;
}

export interface ReleaseMedia {
  id: string;
  fileName: string;
  mimeType: "image/avif" | "image/jpeg" | "image/png" | "image/webp";
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

export interface ReleaseHighlight {
  id: string;
  title: string;
  description: string;
  icon: string;
  mediaId?: string;
}

export interface LocalizedReleasePresentation {
  headline: string;
  summary: string;
  highlights: ReleaseHighlight[];
  changes: ReleaseNotes;
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
  presentation?: {
    de: LocalizedReleasePresentation;
    en: LocalizedReleasePresentation;
  };
  media?: ReleaseMedia[];
  artifacts: ReleaseArtifact[];
}

export interface SignedManifestEnvelope {
  schemaVersion: 1;
  keyId: string;
  algorithm: "ed25519";
  payload: string;
  signature: string;
}

export interface ReleaseManifest {
  schemaVersion: number;
  releases: Release[];
}
