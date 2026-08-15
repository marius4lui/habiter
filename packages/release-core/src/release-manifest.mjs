import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";

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
    for (const artifact of release.artifacts) {
      const key = `${artifact.platform}:${artifact.architecture}:${artifact.fileName}`;
      if (artifactKeys.has(key)) throw new Error(`Duplicate artifact: ${key}`);
      artifactKeys.add(key);
      if (artifact.platform === "android" && !artifact.signed) {
        throw new Error(`Android artifact must be signed: ${artifact.fileName}`);
      }
    }
    versions.add(release.version);
    builds.add(release.buildNumber);
    previousBuild = release.buildNumber;
  }
  return manifest;
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
  return { ...release, status: "published", publishedAt, artifacts };
}
