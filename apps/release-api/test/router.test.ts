import { describe, expect, it } from "vitest";
import openApi from "../../../docs/public/release-api.openapi.json";
import { createHandler, releaseApiContractPaths } from "../src/router";
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
      { platform: "windows", architecture: "x64", format: "zip", primary: true, fileName: "habiter.zip", signed: false, url: "https://example.com/habiter.zip", sha256: "b".repeat(64), size: 10 },
      { platform: "linux", architecture: "x64", format: "appimage", primary: true, fileName: "Habiter.AppImage", signed: false, url: "https://example.com/Habiter.AppImage", sha256: "d".repeat(64), size: 20 },
      { platform: "macos", architecture: "universal", format: "zip", primary: true, fileName: "Habiter-macos.zip", signed: false, url: "https://example.com/Habiter-macos.zip", sha256: "e".repeat(64), size: 30 }
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
const installers = {
  "install.sh": { body: "#!/bin/sh\necho Habiter\n", etag: '"shell-installer"' },
  "install.ps1": { body: "# Habiter PowerShell installer\nWrite-Output Habiter\n", etag: '"powershell-installer"' },
};
const handler = createHandler(manifest, envelope, installers);
const call = (path: string, headers?: HeadersInit) => handler(new Request(`https://get.habiter.dev${path}`, { headers }), env);

describe("release API", () => {
  it("publishes every supported route in OpenAPI", () => {
    expect(Object.keys(openApi.paths).sort()).toEqual(
      Object.values(releaseApiContractPaths).sort(),
    );
  });

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

    const beta = await call("/api/v1/update/android?version=1.0.0&build=10000&channel=beta");
    expect(await beta.json()).toMatchObject({ download: "/api/v1/download/android?channel=beta" });
  });

  it("rejects incomplete or malformed update coordinates", async () => {
    for (const path of [
      "/api/v1/update/android?version=1.0.0",
      "/api/v1/update/android?version=current&build=10000",
      "/api/v1/update/android?version=1.0.0&build=0",
    ]) {
      const response = await call(path);
      expect(response.status).toBe(400);
      expect(await response.json()).toMatchObject({ error: { code: "invalid_update_request" } });
    }
  });

  it("serves only allow-listed repository installers with executable-safe headers", async () => {
    const shell = await call("/install.sh");
    expect(shell.status).toBe(200);
    expect(shell.headers.get("content-type")).toContain("shellscript");
    expect(shell.headers.get("x-content-type-options")).toBe("nosniff");
    expect(shell.headers.get("x-habiter-installer-source")).toBe("repository");
    expect(shell.headers.get("cache-control")).toContain("s-maxage=300");
    expect(await shell.text()).toContain("#!/bin/sh");

    const powershell = await call("/install.ps1");
    expect(powershell.status).toBe(200);
    expect(await powershell.text()).toContain("Habiter PowerShell installer");
    expect(powershell.headers.get("etag")).toBe('"powershell-installer"');
    expect((await call("/install.ps1", { "if-none-match": '"powershell-installer"' })).status).toBe(304);
    expect((await call("/install.sh/other")).status).toBe(404);
  });

  it("fails closed when bundled repository content is unavailable or malformed", async () => {
    const unavailable = createHandler(manifest, envelope, {});
    const missing = await unavailable(new Request("https://get.habiter.dev/install.sh"), env);
    expect(missing.status).toBe(503);
    expect(missing.headers.get("cache-control")).toBe("no-store");

    const malformed = createHandler(manifest, envelope, {
      "install.ps1": { body: "<html>error</html>", etag: '"bad"' },
    });
    const rejected = await malformed(new Request("https://get.habiter.dev/install.ps1"), env);
    expect(rejected.status).toBe(502);
    expect(rejected.headers.get("content-type")).toContain("text/plain");
  });

  it("resolves a complete primary desktop install artifact", async () => {
    const response = await call("/api/v1/install/windows/amd64?channel=stable");
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      version: "1.0.0",
      channel: "stable",
      platform: "windows",
      architecture: "x64",
      artifact: {
        format: "zip",
        fileName: "habiter.zip",
        url: "https://example.com/habiter.zip",
        sha256: "b".repeat(64),
        size: 10,
        signed: false
      },
      docsUrl: "https://docs.habiter.dev/install/windows"
    });
  });

  it("fails closed for unsupported or ambiguous install artifacts", async () => {
    expect((await call("/api/v1/install/windows/sparc")).status).toBe(404);
    expect(await (await call("/api/v1/install/linux/x64?distro=unknown")).json()).toMatchObject({ distro: "generic", artifact: { format: "appimage" } });
    expect((await call("/api/v1/install/windows/x64?version=latest")).status).toBe(400);
    expect((await call("/api/v1/install/windows/x64?channel=beta")).status).toBe(404);

    const ambiguousManifest = structuredClone(manifest);
    const duplicate = structuredClone(ambiguousManifest.releases[1]!.artifacts.find((item) => item.platform === "windows")!);
    duplicate.fileName = "habiter-other.zip";
    ambiguousManifest.releases[1]!.artifacts.push(duplicate);
    const ambiguous = createHandler(ambiguousManifest, envelope, installers);
    expect((await ambiguous(new Request("https://get.habiter.dev/api/v1/install/windows/x64"), env)).status).toBe(404);
  });

  it("maps CPU-specific macOS requests to the universal artifact", async () => {
    for (const architecture of ["arm64", "x64"]) {
      const response = await call(`/api/v1/install/macos/${architecture}`);
      expect(response.status).toBe(200);
      expect(await response.json()).toMatchObject({ architecture, artifact: { fileName: "Habiter-macos.zip" } });
    }
  });

  it("keeps Android direct downloads while routing desktop browsers to install guides", async () => {
    expect((await call("/download", { "user-agent": "Mozilla Android" })).headers.get("location")).toContain("/api/v1/download/android/universal");
    expect((await call("/download?platform=windows&arch=x64")).headers.get("location")).toBe("https://github.com/marius4lui/habiter/blob/main/docs/install/windows.md");
    expect((await call("/download", { "user-agent": "Mozilla Macintosh" })).headers.get("location")).toBe("https://github.com/marius4lui/habiter/blob/main/docs/install/macos.md");
    expect((await call("/download?platform=android&channel=beta")).headers.get("location")).toContain("/api/v1/download/android/universal?channel=beta");
    expect((await call("/api/v1/download/windows/x64")).headers.get("location")).toBe("https://example.com/habiter.zip");
  });

  it("routes Linux only from explicit, reliable distro hints", async () => {
    expect((await call("/download", { "user-agent": "Mozilla Linux x86_64" })).headers.get("location")).toBe("https://github.com/marius4lui/habiter/tree/main/docs/install/linux");
    for (const distro of ["ubuntu", "debian", "fedora", "arch", "opensuse"]) {
      expect((await call(`/download?platform=linux&distro=${distro}`, { "user-agent": "Mozilla Windows" })).headers.get("location"))
        .toBe(`https://github.com/marius4lui/habiter/blob/main/docs/install/linux/${distro}.md`);
    }
    expect((await call("/download?platform=linux&distro=gentoo")).headers.get("location")).toBe("https://github.com/marius4lui/habiter/blob/main/docs/install/linux/generic.md");
  });

  it("redirects unknown clients and returns consistent API errors", async () => {
    expect((await call("/download", { "user-agent": "curl" })).headers.get("location")).toBe("https://github.com/marius4lui/habiter/blob/main/docs/install/README.md");
    expect((await call("/download?platform=plan9", { "user-agent": "Mozilla Windows" })).headers.get("location")).toBe("https://github.com/marius4lui/habiter/blob/main/docs/install/README.md");
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
