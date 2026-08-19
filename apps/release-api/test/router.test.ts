import { describe, expect, it } from "vitest";
import { createHandler } from "../src/router";
import type { ReleaseManifest, SignedManifestEnvelope } from "../src/types/releases";

const manifest: ReleaseManifest = {
  schemaVersion: 1,
  releases: [{
    version: "1.1.0",
    buildNumber: 10100,
    channel: "beta",
    status: "published",
    publishedAt: "2026-08-16T12:00:00Z",
    minimumSupportedVersion: "1.0.0",
    mandatoryAfter: null,
    notes: { added: [], changed: ["beta"], fixed: [], security: [] },
    artifacts: [
      { platform: "android", architecture: "universal", fileName: "habiter-beta.apk", signed: true, url: "https://example.com/habiter-beta.apk", sha256: "c".repeat(64), size: 10 }
    ]
  }, {
    version: "1.0.0",
    buildNumber: 10000,
    channel: "stable",
    status: "published",
    publishedAt: "2026-08-15T12:00:00Z",
    minimumSupportedVersion: "1.0.0",
    mandatoryAfter: null,
    notes: { added: ["v1"], changed: [], fixed: [], security: [] },
    artifacts: [
      { platform: "android", architecture: "universal", fileName: "habiter.apk", signed: true, url: "https://example.com/habiter.apk", sha256: "a".repeat(64), size: 10 },
      { platform: "windows", architecture: "x64", fileName: "habiter.zip", signed: false, url: "https://example.com/habiter.zip", sha256: "b".repeat(64), size: 10 }
    ]
  }]
};

const env = { ENVIRONMENT: "development", WEBSITE_URL: "https://habiter.dev/#download" } as Env;
const envelope: SignedManifestEnvelope = {
  schemaVersion: 1,
  keyId: "test-2026-01",
  algorithm: "ed25519",
  payload: "eyJzY2hlbWFWZXJzaW9uIjoxLCJyZWxlYXNlcyI6W119",
  signature: "a".repeat(86)
};
const handler = createHandler(manifest, envelope);
const call = (path: string, headers?: HeadersInit) => handler(new Request(`https://get.habiter.dev${path}`, { headers }), env);

describe("release API", () => {
  it("serves the immutable signed bytes through an ETag-aware envelope", async () => {
    const response = await call("/api/v1/manifest");
    expect(response.status).toBe(200);
    expect(response.headers.get("cache-control")).toContain("s-maxage");
    expect(await response.json()).toEqual(envelope);

    const cached = await call("/api/v1/manifest", { "if-none-match": response.headers.get("etag")! });
    expect(cached.status).toBe(304);
    expect(await cached.text()).toBe("");
  });

  it("serves health and paginated release summaries", async () => {
    expect(await (await call("/health")).json()).toMatchObject({ status: "ok", environment: "development" });
    const response = await call("/api/v1/releases?page=1&limit=1");
    expect(await response.json()).toMatchObject({ page: 1, limit: 1, total: 1 });
  });

  it("serves latest, version details and downloads", async () => {
    expect(await (await call("/api/v1/releases/latest")).json()).toMatchObject({ version: "1.0.0" });
    expect(await (await call("/api/v1/releases/latest?channel=beta")).json()).toMatchObject({ version: "1.1.0", channel: "beta" });
    expect((await call("/api/v1/releases/1.0.0")).headers.get("cache-control")).toContain("immutable");
    expect((await call("/api/v1/releases/1.0.0/downloads")).status).toBe(200);
  });

  it("computes update availability", async () => {
    const response = await call("/api/v1/update/android?version=0.9.0&build=9000");
    expect(await response.json()).toMatchObject({ updateAvailable: true, target: { version: "1.0.0", buildNumber: 10000 } });
  });

  it("detects platforms and accepts deterministic overrides", async () => {
    expect((await call("/download", { "user-agent": "Mozilla Android" })).headers.get("location")).toContain("/api/v1/download/android/universal");
    expect((await call("/download?platform=windows&arch=x64")).headers.get("location")).toContain("/api/v1/download/windows/x64");
    expect((await call("/download?platform=android&channel=beta")).headers.get("location")).toContain("/api/v1/download/android/universal?channel=beta");
    expect((await call("/api/v1/download/windows/x64")).headers.get("location")).toBe("https://example.com/habiter.zip");
  });

  it("redirects unknown clients and returns consistent API errors", async () => {
    expect((await call("/download", { "user-agent": "curl" })).headers.get("location")).toBe("https://habiter.dev/#download");
    const response = await call("/api/v1/releases/9.9.9");
    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({ error: { code: "release_not_found" } });
    const invalidChannel = await call("/api/v1/releases/latest?channel=nightly");
    expect(invalidChannel.status).toBe(400);
    expect(await invalidChannel.json()).toMatchObject({ error: { code: "invalid_channel" } });
  });

  it("does not expose arbitrary release subpaths", async () => {
    expect((await call("/api/v1/releases/1.0.0/private")).status).toBe(404);
    expect((await call("/api/v1/releases/1.0.0/downloads/extra")).status).toBe(404);
  });

  it("includes a request ID when the signed manifest is unavailable", async () => {
    const response = await createHandler(manifest)(
      new Request("https://get.habiter.dev/api/v1/manifest"),
      env,
    );
    expect(response.status).toBe(503);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(await response.json()).toMatchObject({
      error: {
        code: "manifest_unavailable",
        requestId: expect.any(String),
      },
    });
  });
});
