import { apiError, json, withCache } from "./responses/http";
import { defaultArchitecture, detectPlatform, parsePlatform } from "./services/platform";
import { ReleaseService } from "./services/release-service";
import type { ReleaseManifest } from "./types/releases";

const shortCache = "public, max-age=60, s-maxage=300";
const immutableCache = "public, max-age=86400, s-maxage=31536000, immutable";

function positiveInteger(value: string | null, fallback: number, maximum: number): number | null {
  if (value === null) return fallback;
  if (!/^\d+$/.test(value)) return null;
  const parsed = Number(value);
  return parsed >= 1 && parsed <= maximum ? parsed : null;
}

export function createHandler(manifest: ReleaseManifest) {
  const releases = new ReleaseService(manifest);

  return async function handle(request: Request, env: Env): Promise<Response> {
    const requestId = crypto.randomUUID();
    const url = new URL(request.url);
    const segments = url.pathname.split("/").filter(Boolean);

    if (url.pathname === "/health") {
      return json({ status: "ok", environment: env.ENVIRONMENT, requestId });
    }

    if (url.pathname === "/download") {
      const platform = parsePlatform(url.searchParams.get("platform")) ?? detectPlatform(request.headers.get("user-agent") ?? "");
      if (!platform) return Response.redirect(env.WEBSITE_URL, 302);
      const architecture = url.searchParams.get("arch") ?? defaultArchitecture(platform);
      return Response.redirect(new URL(`/api/v1/download/${platform}/${architecture}`, url).toString(), 302);
    }

    if (segments[0] !== "api" || segments[1] !== "v1") {
      return apiError(requestId, 404, "not_found", "Route not found");
    }

    if (segments[2] === "releases" && segments.length === 3) {
      const page = positiveInteger(url.searchParams.get("page"), 1, 100000);
      const limit = positiveInteger(url.searchParams.get("limit"), 20, 100);
      if (page === null || limit === null) return apiError(requestId, 400, "invalid_pagination", "page and limit must be positive integers");
      return withCache(json(releases.list(url.searchParams.get("channel") ?? "stable", page, limit)), shortCache);
    }

    if (segments[2] === "releases" && segments[3] === "latest" && segments.length === 4) {
      const release = releases.latest(url.searchParams.get("channel") ?? "stable");
      return release
        ? withCache(json(release), shortCache)
        : apiError(requestId, 404, "release_not_found", "No published release exists for this channel");
    }

    if (segments[2] === "releases" && segments[3] && segments.length >= 4) {
      const release = releases.find(segments[3]);
      if (!release) return apiError(requestId, 404, "release_not_found", "Release not found");
      const payload = segments[4] === "downloads" ? { version: release.version, artifacts: release.artifacts } : release;
      return withCache(json(payload), immutableCache);
    }

    if (segments[2] === "update" && segments[3] && segments.length === 4) {
      const platform = parsePlatform(segments[3]);
      const version = url.searchParams.get("version");
      const build = positiveInteger(url.searchParams.get("build"), 0, Number.MAX_SAFE_INTEGER);
      if (!platform || !version || build === null) return apiError(requestId, 400, "invalid_update_request", "platform, version and build are required");
      const result = releases.checkUpdate(platform, version, build, url.searchParams.get("channel") ?? "stable", new Date());
      return result ? withCache(json(result), shortCache) : apiError(requestId, 404, "release_not_found", "No published release exists for this channel");
    }

    if (segments[2] === "download" && segments[3] && segments.length <= 5) {
      const platform = parsePlatform(segments[3]);
      if (!platform) return apiError(requestId, 404, "platform_not_supported", "Platform not supported");
      const release = releases.latest(url.searchParams.get("channel") ?? "stable");
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
