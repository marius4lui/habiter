import { apiError, json, withCache } from "./responses/http";
import { defaultArchitecture, detectPlatform, parsePlatform } from "./services/platform";
import { ReleaseService } from "./services/release-service";
import type { ReleaseChannel, ReleaseManifest, SignedManifestEnvelope } from "./types/releases";

const shortCache = "public, max-age=60, s-maxage=300";
const immutableCache = "public, max-age=86400, s-maxage=31536000, immutable";
const semanticVersion = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

/** Route templates that must stay aligned with the published OpenAPI document. */
export const releaseApiContractPaths = {
  health: "/health",
  downloadSelector: "/download",
  manifest: "/api/v1/manifest",
  releases: "/api/v1/releases",
  latestRelease: "/api/v1/releases/latest",
  release: "/api/v1/releases/{version}",
  releaseDownloads: "/api/v1/releases/{version}/downloads",
  update: "/api/v1/update/{platform}",
  download: "/api/v1/download/{platform}",
  downloadArchitecture: "/api/v1/download/{platform}/{architecture}",
} as const;

function positiveInteger(value: string | null, fallback: number, maximum: number): number | null {
  if (value === null) return fallback;
  if (!/^\d+$/.test(value)) return null;
  const parsed = Number(value);
  return parsed >= 1 && parsed <= maximum ? parsed : null;
}

function releaseChannel(value: string | null): ReleaseChannel | null {
  if (value === null) return "stable";
  return value === "stable" || value === "beta" ? value : null;
}

function manifestResponse(request: Request, envelope: SignedManifestEnvelope | undefined, requestId: string): Response {
  if (!envelope) {
    const response = apiError(requestId, 503, "manifest_unavailable", "Signed manifest is unavailable");
    response.headers.set("cache-control", "no-store");
    return response;
  }
  const etag = `"${envelope.keyId}.${envelope.signature.slice(0, 32)}"`;
  if (request.headers.get("if-none-match") === etag) {
    return new Response(null, { status: 304, headers: { etag, "cache-control": shortCache } });
  }
  const response = json(envelope);
  response.headers.set("etag", etag);
  return withCache(response, shortCache);
}

/** Builds the complete read-only HTTP handler from immutable release data. */
export function createHandler(manifest: ReleaseManifest, envelope?: SignedManifestEnvelope) {
  const releases = new ReleaseService(manifest);

  return async function handle(request: Request, env: Env): Promise<Response> {
    const requestId = crypto.randomUUID();
    const url = new URL(request.url);
    const segments = url.pathname.split("/").filter(Boolean);

    if (url.pathname === releaseApiContractPaths.health) {
      return json({ status: "ok", environment: env.ENVIRONMENT, requestId });
    }

    if (url.pathname === releaseApiContractPaths.downloadSelector) {
      const platform = parsePlatform(url.searchParams.get("platform")) ?? detectPlatform(request.headers.get("user-agent") ?? "");
      if (!platform) return Response.redirect(env.WEBSITE_URL, 302);
      const channel = releaseChannel(url.searchParams.get("channel"));
      if (channel === null) return apiError(requestId, 400, "invalid_channel", "channel must be stable or beta");
      const architecture = url.searchParams.get("arch") ?? defaultArchitecture(platform);
      const target = new URL(`/api/v1/download/${platform}/${architecture}`, url);
      if (url.searchParams.has("channel")) target.searchParams.set("channel", channel);
      return Response.redirect(target.toString(), 302);
    }

    if (segments[0] !== "api" || segments[1] !== "v1") {
      return apiError(requestId, 404, "not_found", "Route not found");
    }

    if (segments[2] === "manifest" && segments.length === 3) {
      return manifestResponse(request, envelope, requestId);
    }

    if (segments[2] === "releases" && segments.length === 3) {
      const page = positiveInteger(url.searchParams.get("page"), 1, 100000);
      const limit = positiveInteger(url.searchParams.get("limit"), 20, 100);
      if (page === null || limit === null) return apiError(requestId, 400, "invalid_pagination", "page and limit must be positive integers");
      const channel = releaseChannel(url.searchParams.get("channel"));
      if (channel === null) return apiError(requestId, 400, "invalid_channel", "channel must be stable or beta");
      return withCache(json(releases.list(channel, page, limit)), shortCache);
    }

    if (segments[2] === "releases" && segments[3] === "latest" && segments.length === 4) {
      const channel = releaseChannel(url.searchParams.get("channel"));
      if (channel === null) return apiError(requestId, 400, "invalid_channel", "channel must be stable or beta");
      const release = releases.latest(channel);
      return release
        ? withCache(json(release), shortCache)
        : apiError(requestId, 404, "release_not_found", "No published release exists for this channel");
    }

    if (
      segments[2] === "releases"
      && segments[3]
      && (segments.length === 4 || (segments.length === 5 && segments[4] === "downloads"))
    ) {
      const release = releases.find(segments[3]);
      if (!release) return apiError(requestId, 404, "release_not_found", "Release not found");
      const payload = segments[4] === "downloads" ? { version: release.version, artifacts: release.artifacts } : release;
      return withCache(json(payload), immutableCache);
    }

    if (segments[2] === "update" && segments[3] && segments.length === 4) {
      const platform = parsePlatform(segments[3]);
      const version = url.searchParams.get("version");
      const buildValue = url.searchParams.get("build");
      const build = positiveInteger(buildValue, 0, Number.MAX_SAFE_INTEGER);
      if (!platform || !version || !semanticVersion.test(version) || buildValue === null || build === null) {
        return apiError(requestId, 400, "invalid_update_request", "platform, semantic version and positive build are required");
      }
      const channel = releaseChannel(url.searchParams.get("channel"));
      if (channel === null) return apiError(requestId, 400, "invalid_channel", "channel must be stable or beta");
      const result = releases.checkUpdate(platform, version, build, channel, new Date());
      return result ? withCache(json(result), shortCache) : apiError(requestId, 404, "release_not_found", "No published release exists for this channel");
    }

    if (segments[2] === "download" && segments[3] && segments.length <= 5) {
      const platform = parsePlatform(segments[3]);
      if (!platform) return apiError(requestId, 404, "platform_not_supported", "Platform not supported");
      const channel = releaseChannel(url.searchParams.get("channel"));
      if (channel === null) return apiError(requestId, 400, "invalid_channel", "channel must be stable or beta");
      const release = releases.latest(channel);
      if (!release) return apiError(requestId, 404, "release_not_found", "No published release exists for this channel");
      const architecture = segments[4] ?? defaultArchitecture(platform);
      const artifact = releases.artifact(release, platform, architecture);
      return artifact?.url
        ? Response.redirect(artifact.url, 302)
        : apiError(requestId, 404, "artifact_not_found", "No matching artifact exists");
    }

    return apiError(requestId, 404, "not_found", "Route not found");
  };
}
