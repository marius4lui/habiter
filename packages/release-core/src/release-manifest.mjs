import {
  createHash,
  createPrivateKey,
  createPublicKey,
  sign,
  verify
} from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";

export { parseRawPublicKeyRing } from "./public-key-ring.mjs";

const semverPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

export async function readJson(file) {
  return JSON.parse(await readFile(file, "utf8"));
}

export async function validateManifest(manifest, schema) {
  const ajv = new Ajv2020({ allErrors: true, strict: true });
  addFormats(ajv);
  const validate = ajv.compile(schema);
  if (!validate(manifest)) {
    throw new Error(ajv.errorsText(validate.errors, { separator: "\n" }));
  }

  const versions = new Set();
  const builds = new Set();
  let previousBuild = Number.POSITIVE_INFINITY;
  for (const release of manifest.releases) {
    if (versions.has(release.version)) throw new Error(`Duplicate version: ${release.version}`);
    if (builds.has(release.buildNumber)) throw new Error(`Duplicate build number: ${release.buildNumber}`);
    if (release.buildNumber >= previousBuild) {
      throw new Error("Releases must be newest-first with strictly decreasing build numbers");
    }
    if (release.status === "published" && release.publishedAt === null) {
      throw new Error(`Published release ${release.version} requires publishedAt`);
    }
    if (release.status === "draft" && release.publishedAt !== null) {
      throw new Error(`Draft release ${release.version} must not set publishedAt`);
    }
    const artifactKeys = new Set();
    const primaryInstallerKeys = new Set();
    for (const artifact of release.artifacts) {
      const key = `${artifact.platform}:${artifact.architecture}:${artifact.fileName}`;
      if (artifactKeys.has(key)) throw new Error(`Duplicate artifact: ${key}`);
      artifactKeys.add(key);
      if (artifact.primary === true) {
        if (!artifact.format) {
          throw new Error(`Primary artifact requires a format: ${artifact.fileName}`);
        }
        const primaryKey = `${artifact.platform}:${artifact.architecture}`;
        if (primaryInstallerKeys.has(primaryKey)) {
          throw new Error(`Ambiguous primary artifact: ${primaryKey}`);
        }
        primaryInstallerKeys.add(primaryKey);
      }
      if (artifact.platform === "android" && !artifact.signed) {
        throw new Error(`Android artifact must be signed: ${artifact.fileName}`);
      }
      if (artifact.platform === "android" && !artifact.distribution) {
        throw new Error(`Android artifact requires a distribution: ${artifact.fileName}`);
      }
      if (artifact.platform !== "android" && artifact.distribution) {
        throw new Error(`Only Android artifacts may set distribution: ${artifact.fileName}`);
      }
      if (release.status === "published") assertPublishedAsset(artifact, artifact.fileName);
    }

    const mediaIds = new Set();
    for (const media of release.media ?? []) {
      if (mediaIds.has(media.id)) throw new Error(`Duplicate release media id: ${media.id}`);
      mediaIds.add(media.id);
      if (release.status === "published") assertPublishedAsset(media, media.fileName);
    }
    for (const locale of ["de", "en"]) {
      for (const highlight of release.presentation?.[locale]?.highlights ?? []) {
        if (highlight.mediaId && !mediaIds.has(highlight.mediaId)) {
          throw new Error(`Unknown media id ${highlight.mediaId} in ${release.version} ${locale}`);
        }
      }
    }
    versions.add(release.version);
    builds.add(release.buildNumber);
    previousBuild = release.buildNumber;
  }
  return manifest;
}

function assertPublishedAsset(asset, label) {
  if (!asset.url || !asset.sha256 || !asset.size) {
    throw new Error(`Published asset metadata is incomplete for ${label}`);
  }
  const url = new URL(asset.url);
  if (url.protocol !== "https:") throw new Error(`Published asset must use HTTPS: ${label}`);
}

export function publishedManifest(manifest) {
  return {
    schemaVersion: manifest.schemaVersion,
    releases: manifest.releases.filter((release) => release.status === "published")
  };
}

export function manifestPayloadBytes(manifest) {
  return Buffer.from(JSON.stringify(publishedManifest(manifest)), "utf8");
}

export function signManifestEnvelope({ manifest, keyId, privateKey }) {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]+$/.test(keyId)) {
    throw new Error("Invalid manifest signing key id");
  }
  const payload = manifestPayloadBytes(manifest);
  const key = privateKey?.type === "private" ? privateKey : createPrivateKey(privateKey);
  if (key.asymmetricKeyType !== "ed25519") throw new Error("Manifest signing key must use Ed25519");
  return {
    schemaVersion: 1,
    keyId,
    algorithm: "ed25519",
    payload: payload.toString("base64url"),
    signature: sign(null, payload, key).toString("base64url")
  };
}

export function verifyManifestEnvelope(envelope, publicKeyRing) {
  if (
    envelope?.schemaVersion !== 1
    || envelope.algorithm !== "ed25519"
    || typeof envelope.keyId !== "string"
    || typeof envelope.payload !== "string"
    || typeof envelope.signature !== "string"
  ) {
    throw new Error("Invalid signed manifest envelope");
  }
  const publicKey = publicKeyRing[envelope.keyId];
  if (!publicKey) throw new Error(`Unknown manifest signing key: ${envelope.keyId}`);
  const key = publicKey?.type === "public" ? publicKey : createPublicKey(publicKey);
  if (key.asymmetricKeyType !== "ed25519") throw new Error("Manifest verification key must use Ed25519");
  const payload = Buffer.from(envelope.payload, "base64url");
  const signature = Buffer.from(envelope.signature, "base64url");
  if (!verify(null, payload, key, signature)) throw new Error("Manifest signature verification failed");
  const manifest = JSON.parse(payload.toString("utf8"));
  if (manifest.releases?.some((release) => release.status !== "published")) {
    throw new Error("Signed manifest contains an unpublished release");
  }
  return { manifest, payload };
}

export function parsePubspecVersion(contents) {
  const match = contents.match(/^version:\s*([^+\s]+)\+(\d+)\s*$/m);
  if (!match || !semverPattern.test(match[1])) throw new Error("Invalid or missing pubspec version");
  return { version: match[1], buildNumber: Number(match[2]) };
}

export function assertTagMatches({ tag, pubspec, manifest }) {
  if (!/^v\d+\.\d+\.\d+$/.test(tag)) throw new Error(`Invalid release tag: ${tag}`);
  const expected = `v${pubspec.version}`;
  if (tag !== expected) throw new Error(`Tag ${tag} does not match ${expected}`);
  const release = manifest.releases.find((item) => item.version === pubspec.version);
  if (!release) throw new Error(`No release manifest entry for ${pubspec.version}`);
  if (release.buildNumber !== pubspec.buildNumber) {
    throw new Error(`Build number ${pubspec.buildNumber} does not match manifest ${release.buildNumber}`);
  }
  return release;
}

export function compareVersions(left, right) {
  const a = left.split(".").map(Number);
  const b = right.split(".").map(Number);
  for (let index = 0; index < 3; index += 1) {
    if (a[index] !== b[index]) return a[index] - b[index];
  }
  return 0;
}

export function renderNotes(release) {
  const labels = { added: "Added", changed: "Changed", fixed: "Fixed", security: "Security" };
  const sections = [];
  for (const [key, label] of Object.entries(labels)) {
    if (release.notes[key].length === 0) continue;
    sections.push(`## ${label}\n\n${release.notes[key].map((note) => `- ${note}`).join("\n")}`);
  }
  const unsigned = release.artifacts.filter((artifact) => !artifact.signed);
  if (unsigned.length > 0) {
    sections.push("## Desktop signing\n\nWindows, Linux and macOS downloads include SHA-256 checksums but are not code-signed in this release.");
  }
  return `${sections.join("\n\n")}\n`;
}

export function finalizeRelease(manifest, runtimeManifest, version) {
  const source = manifest.releases.find((release) => release.version === version);
  if (!source) throw new Error(`Unknown release version: ${version}`);

  const published = runtimeManifest.releases.find((release) => release.version === version);
  if (!published || published.status !== "published" || published.publishedAt === null) {
    throw new Error(`Runtime metadata for ${version} is not published`);
  }
  if (published.buildNumber !== source.buildNumber) {
    throw new Error(`Runtime build number for ${version} does not match the manifest`);
  }

  const runtimeArtifacts = new Map(published.artifacts.map((artifact) => [artifact.fileName, artifact]));
  const artifacts = source.artifacts.map((artifact) => {
    const runtimeArtifact = runtimeArtifacts.get(artifact.fileName);
    if (!runtimeArtifact?.url || !runtimeArtifact.sha256 || !runtimeArtifact.size) {
      throw new Error(`Runtime metadata is incomplete for ${artifact.fileName}`);
    }
    if (
      runtimeArtifact.platform !== artifact.platform
      || runtimeArtifact.architecture !== artifact.architecture
      || runtimeArtifact.signed !== artifact.signed
      || runtimeArtifact.distribution !== artifact.distribution
      || runtimeArtifact.format !== artifact.format
      || runtimeArtifact.primary !== artifact.primary
    ) {
      throw new Error(`Runtime artifact contract does not match for ${artifact.fileName}`);
    }
    return {
      ...artifact,
      url: runtimeArtifact.url,
      sha256: runtimeArtifact.sha256,
      size: runtimeArtifact.size
    };
  });
  if (runtimeArtifacts.size !== artifacts.length) {
    throw new Error(`Runtime artifact set does not match for ${version}`);
  }

  const runtimeMedia = new Map((published.media ?? []).map((media) => [media.id, media]));
  const media = (source.media ?? []).map((item) => {
    const runtimeItem = runtimeMedia.get(item.id);
    if (
      !runtimeItem?.url
      || !runtimeItem.sha256
      || !runtimeItem.size
      || runtimeItem.fileName !== item.fileName
      || runtimeItem.mimeType !== item.mimeType
    ) {
      throw new Error(`Runtime media metadata is incomplete or mismatched for ${item.id}`);
    }
    return { ...item, url: runtimeItem.url, sha256: runtimeItem.sha256, size: runtimeItem.size };
  });
  if (runtimeMedia.size !== media.length) throw new Error(`Runtime media set does not match for ${version}`);

  return {
    ...manifest,
    releases: manifest.releases.map((release) => release.version === version ? {
      ...release,
      status: "published",
      publishedAt: published.publishedAt,
      artifacts,
      ...(media.length > 0 ? { media } : {})
    } : release)
  };
}

export async function enrichRelease({ release, artifactDirectory, repository, publishedAt }) {
  const artifacts = [];
  for (const artifact of release.artifacts) {
    const file = path.join(artifactDirectory, artifact.fileName);
    const data = await readFile(file);
    const info = await stat(file);
    artifacts.push({
      ...artifact,
      size: info.size,
      sha256: createHash("sha256").update(data).digest("hex"),
      url: `https://github.com/${repository}/releases/download/v${release.version}/${artifact.fileName}`
    });
  }
  const media = [];
  for (const item of release.media ?? []) {
    const file = path.join(artifactDirectory, item.fileName);
    const data = await readFile(file);
    const info = await stat(file);
    media.push({
      ...item,
      size: info.size,
      sha256: createHash("sha256").update(data).digest("hex"),
      url: `https://github.com/${repository}/releases/download/v${release.version}/${item.fileName}`
    });
  }
  return {
    ...release,
    status: "published",
    publishedAt,
    artifacts,
    ...(media.length > 0 ? { media } : {})
  };
}
