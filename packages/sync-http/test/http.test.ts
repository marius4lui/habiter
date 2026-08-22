import { fileURLToPath } from "node:url";
import { JSDOM } from "jsdom";
import { Miniflare } from "miniflare";
import { afterEach, describe, expect, it } from "vitest";
import {
  SyncAuth,
  createLoginProof,
  generatePkceVerifier,
  passwordKdfIterations,
  pkceChallenge,
  type AuthorizationAttempt,
  type SetupInput,
} from "@habiter/sync-auth";
import { createOperation } from "@habiter/sync-core";
import { SqliteSyncStorage } from "@habiter/sync-sqlite";
import { createSyncHttpHandler, type SyncHttpLogEvent } from "../src/index";

interface Harness {
  fetch(request: Request): Promise<Response>;
  cleanup(): Promise<void>;
}

const instances: Harness[] = [];
const base = "https://sync.example.test";
const redirectUri = "https://app.habiter.dev/auth/callback";
const passwordKey = Buffer.alloc(32, 11).toString("base64url");
const setup: SetupInput = { username: "owner", passwordKey, salt: Buffer.alloc(16, 13).toString("base64url"), iterations: passwordKdfIterations };
const verifier = generatePkceVerifier(() => new Uint8Array(32).fill(21));

async function makeAttempt(username = "owner", deviceId = "phone-a"): Promise<AuthorizationAttempt> {
  return { username, codeChallenge: await pkceChallenge(verifier), state: `state-${deviceId}-123456789012`, redirectUri, attemptId: `attempt-${deviceId}`, deviceId };
}

function request(path: string, init: RequestInit = {}): Request { return new Request(`${base}${path}`, init); }
function jsonRequest(path: string, body: unknown, headers: HeadersInit = {}): Request {
  return request(path, { method: "POST", headers: { "content-type": "application/json", ...headers }, body: JSON.stringify(body) });
}
async function body<T>(response: Response): Promise<T> { return response.json() as Promise<T>; }

async function sqliteHarness(log?: (event: SyncHttpLogEvent) => void): Promise<Harness> {
  const storage = new SqliteSyncStorage(":memory:");
  const auth = new SyncAuth(storage, { issuer: base, audience: "habiter-mobile", encryptionKey: new Uint8Array(32).fill(7) });
  await auth.setup(setup);
  const handler = createSyncHttpHandler({ storage, auth, config: { instanceName: "Test instance", baseUrl: base, redirectUris: [redirectUri], corsOrigins: ["https://app.habiter.dev"], ...(log ? { log } : {}) } });
  const harness = { fetch: handler, cleanup: async () => storage.close() };
  instances.push(harness);
  return harness;
}

async function d1Harness(): Promise<Harness> {
  const miniflare = new Miniflare({ modules: true, scriptPath: fileURLToPath(new URL("../.tmp/worker.mjs", import.meta.url)), compatibilityDate: "2026-08-15", compatibilityFlags: ["nodejs_compat"], d1Databases: { DB: crypto.randomUUID() } });
  await miniflare.ready;
  const setupResponse = await miniflare.dispatchFetch(`${base}/_test/setup`, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(setup) });
  expect(setupResponse.status).toBe(204);
  const harness: Harness = {
    fetch: async (input: Request) => {
      const remote = await miniflare.dispatchFetch(input.url, {
        method: input.method,
        headers: Object.fromEntries(input.headers.entries()),
        ...(input.body === null ? {} : { body: await input.arrayBuffer() }),
      });
      return new Response(await remote.arrayBuffer(), { status: remote.status, headers: Object.fromEntries(remote.headers.entries()) });
    },
    cleanup: async () => miniflare.dispose(),
  };
  instances.push(harness);
  return harness;
}

afterEach(async () => { await Promise.all(instances.splice(0).map((item) => item.cleanup())); });

async function login(harness: Harness, username = "owner", key = passwordKey, deviceId = "phone-a") {
  const attempt = await makeAttempt(username, deviceId);
  const begin = await harness.fetch(jsonRequest("/v1/authorize", { action: "begin", csrf: attempt.state, attempt }, { "x-habiter-csrf": attempt.state, "sec-fetch-site": "same-origin" }));
  const challenge = await body<{ challengeId: string; salt: string; iterations: number }>(begin);
  const proof = await createLoginProof(key, challenge.challengeId, attempt);
  const complete = await harness.fetch(jsonRequest("/v1/authorize", { action: "complete", csrf: attempt.state, challengeId: challenge.challengeId, proof }, { "x-habiter-csrf": attempt.state, "sec-fetch-site": "same-origin" }));
  const grant = await body<Record<string, string>>(complete);
  return { attempt, challenge, grant };
}

async function tokens(harness: Harness, deviceId = "phone-a") {
  const { attempt, grant } = await login(harness, "owner", passwordKey, deviceId);
  const response = await harness.fetch(jsonRequest("/v1/token", { grantType: "authorization_code", code: grant.code, codeVerifier: verifier, redirectUri, attemptId: attempt.attemptId }));
  expect(response.status).toBe(200);
  return body<{ accessToken: string; refreshToken: string }>(response);
}

function operation() {
  const payload = { id: "habit-a", name: "Walk", description: "Daily", color: "#4CAF50", icon: "walk", frequency: "daily", targetCount: 1, category: "Health", customDays: null, createdAt: "2026-08-22T08:00:00.000Z", isActive: true, notificationEnabled: false, notificationTime: null };
  return createOperation({ kind: "create", revision: { deviceId: "phone-a", sequence: 1 }, document: { schemaVersion: 1, entityId: "habit/habit-a", deleted: false, payload }, changedFields: Object.keys(payload), changedMetadataFields: [] });
}

function patchOperation(deviceId: string, sequence: number, changes: { name?: string; description?: string }) {
  const base = operation().document.payload!;
  const payload = { ...base, ...changes };
  return createOperation({
    kind: "patch",
    revision: { deviceId, sequence },
    document: { schemaVersion: 1, entityId: "habit/habit-a", deleted: false, payload },
    changedFields: Object.keys(changes),
    changedMetadataFields: [],
  });
}

function registerRouteSuite(name: string, factory: () => Promise<Harness>): void {
  describe(`${name} HTTP contract`, () => {
    it("serves public discovery routes with stable security headers", async () => {
      const harness = await factory();
      for (const path of ["/v1/health", "/v1/capabilities", "/v1/instance-info"]) {
        const response = await harness.fetch(request(path, { headers: { "x-request-id": "request-12345678" } }));
        expect(response.status).toBe(200);
        expect(response.headers.get("cache-control")).toBe("no-store");
        expect(response.headers.get("x-content-type-options")).toBe("nosniff");
        expect(response.headers.get("referrer-policy")).toBe("no-referrer");
        expect(response.headers.get("x-frame-options")).toBe("DENY");
        expect(response.headers.get("strict-transport-security")).toContain("max-age=31536000");
        expect(response.headers.get("content-security-policy")).toContain("default-src 'none'");
        expect(response.headers.get("x-request-id")).toBe("request-12345678");
      }
    });

    it("completes auth, push, pull, snapshot, device, refresh, and revoke routes", async () => {
      const harness = await factory();
      const pair = await tokens(harness);
      const authorization = { authorization: `Bearer ${pair.accessToken}` };
      const pushed = await harness.fetch(jsonRequest("/v1/push", { operations: [operation()] }, authorization));
      expect(pushed.status).toBe(200);
      expect(await body<{ receipts: unknown[] }>(pushed)).toMatchObject({ receipts: [{ duplicate: false }] });
      const pulled = await harness.fetch(request("/v1/pull?limit=100", { headers: authorization }));
      expect(await body<{ operations: unknown[] }>(pulled)).toMatchObject({ operations: [{ operationId: "operation/phone-a/1" }] });
      const snapshot = await harness.fetch(request("/v1/snapshot", { headers: authorization }));
      expect(snapshot.status).toBe(200);
      expect(await body<{ schemaVersion: number; entities: unknown[] }>(snapshot)).toMatchObject({ schemaVersion: 1, entities: [{ entityId: "habit/habit-a" }] });
      const device = await harness.fetch(request("/v1/device", { headers: authorization }));
      expect(await body(device)).toMatchObject({ deviceId: "phone-a" });
      const refreshed = await harness.fetch(jsonRequest("/v1/refresh", { grantType: "refresh_token", refreshToken: pair.refreshToken }));
      expect(refreshed.status).toBe(200);
      const revoked = await harness.fetch(jsonRequest("/v1/revoke", { scope: "device" }, authorization));
      expect(revoked.status).toBe(200);
    });

    it("returns the same generic login failure for missing and wrong accounts", async () => {
      const harness = await factory();
      const missing = await login(harness, "missing");
      const wrong = await login(harness, "owner", Buffer.alloc(32, 99).toString("base64url"));
      expect(missing.grant).toMatchObject({ error: "authentication_failed", message: "Authentication failed" });
      expect(wrong.grant).toMatchObject({ error: "authentication_failed", message: "Authentication failed" });
      expect({ error: missing.grant.error, message: missing.grant.message }).toEqual({ error: wrong.grant.error, message: wrong.grant.message });
    });

    it("validates a complete push batch before its first write", async () => {
      const harness = await factory();
      const pair = await tokens(harness);
      const authorization = { authorization: `Bearer ${pair.accessToken}` };
      const valid = operation();
      const invalid = { ...operation(), revision: { deviceId: "phone-a", sequence: 2 } };
      const rejected = await harness.fetch(jsonRequest("/v1/push", { operations: [valid, invalid] }, authorization));
      expect(rejected.status).toBe(400);
      const pulled = await harness.fetch(request("/v1/pull?limit=100", { headers: authorization }));
      expect(await body<{ operations: unknown[] }>(pulled)).toMatchObject({ operations: [] });
    });

    it("converges two authenticated offline devices and enforces revocation", async () => {
      const harness = await factory();
      const phoneA = await tokens(harness, "phone-a");
      const phoneB = await tokens(harness, "phone-b");
      const authA = { authorization: `Bearer ${phoneA.accessToken}` };
      const authB = { authorization: `Bearer ${phoneB.accessToken}` };

      expect((await harness.fetch(jsonRequest("/v1/push", { operations: [operation()] }, authA))).status).toBe(200);
      const fromA = patchOperation("phone-a", 2, { description: "From A while offline" });
      const fromB = patchOperation("phone-b", 1, { name: "From B while offline" });
      expect((await harness.fetch(jsonRequest("/v1/push", { operations: [fromB] }, authB))).status).toBe(200);
      expect((await harness.fetch(jsonRequest("/v1/push", { operations: [fromA] }, authA))).status).toBe(200);

      const duplicate = await harness.fetch(jsonRequest("/v1/push", { operations: [fromB] }, authB));
      expect(await body<{ receipts: unknown[] }>(duplicate)).toMatchObject({ receipts: [{ duplicate: true }] });
      const snapshot = await body<{ entities: Array<{ payloadFields: Record<string, { value: unknown }> }> }>(
        await harness.fetch(request("/v1/snapshot", { headers: authA })),
      );
      expect(snapshot.entities[0]?.payloadFields.name?.value).toBe("From B while offline");
      expect(snapshot.entities[0]?.payloadFields.description?.value).toBe("From A while offline");

      expect((await harness.fetch(jsonRequest("/v1/revoke", { scope: "all" }, authA))).status).toBe(200);
      // Already-issued access tokens intentionally retain their short five-minute
      // lifetime; revocation cuts off every durable refresh session immediately.
      expect((await harness.fetch(request("/v1/pull?limit=100", { headers: authB }))).status).toBe(200);
      expect((await harness.fetch(jsonRequest("/v1/refresh", {
        grantType: "refresh_token",
        refreshToken: phoneB.refreshToken,
      }))).status).toBe(401);
    });
  });
}

registerRouteSuite("SQLite", sqliteHarness);
registerRouteSuite("D1 Worker", d1Harness);

describe("HTTP boundary security", () => {
  it("rejects open redirects, unknown parameters, cross-site requests, and missing CSRF", async () => {
    const harness = await sqliteHarness();
    const attempt = await makeAttempt();
    const unsafe = new URLSearchParams({ response_type: "code", redirect_uri: "https://evil.example/callback", code_challenge: attempt.codeChallenge, state: attempt.state, attempt_id: attempt.attemptId, device_id: attempt.deviceId });
    expect((await harness.fetch(request(`/v1/authorize?${unsafe}`))).status).toBe(400);
    const valid = new URLSearchParams({ response_type: "code", redirect_uri: redirectUri, code_challenge: attempt.codeChallenge, state: attempt.state, attempt_id: attempt.attemptId, device_id: attempt.deviceId, lang: "en" });
    expect((await harness.fetch(request(`/v1/authorize?${valid}&lang=de`))).status).toBe(400);
    expect((await harness.fetch(request(`/v1/authorize?${valid.toString().replace("lang=en", "lang=fr")}`))).status).toBe(400);
    expect((await harness.fetch(request(`/v1/health?value=${"a".repeat(8192)}`))).status).toBe(414);
    expect((await harness.fetch(request("/v1/health?unexpected=yes"))).status).toBe(400);
    expect((await harness.fetch(jsonRequest("/v1/authorize", { action: "begin", csrf: attempt.state, attempt }, { origin: "https://evil.example", "x-habiter-csrf": attempt.state }))).status).toBe(403);
    expect((await harness.fetch(jsonRequest("/v1/authorize", { action: "begin", csrf: attempt.state, attempt }))).status).toBe(403);
  });

  it("enforces CORS, preflight, JSON content types, and body bounds", async () => {
    const harness = await sqliteHarness();
    const allowed = await harness.fetch(request("/v1/health", { headers: { origin: "https://app.habiter.dev" } }));
    expect(allowed.headers.get("access-control-allow-origin")).toBe("https://app.habiter.dev");
    const denied = await harness.fetch(request("/v1/health", { headers: { origin: "https://evil.example" } }));
    expect(denied.status).toBe(403);
    const preflight = await harness.fetch(request("/v1/push", { method: "OPTIONS", headers: { origin: "https://app.habiter.dev", "access-control-request-method": "POST", "access-control-request-headers": "authorization, content-type" } }));
    expect(preflight.status).toBe(204);
    const unknownPreflight = await harness.fetch(request("/v1/unknown", { method: "OPTIONS", headers: { origin: "https://app.habiter.dev", "access-control-request-method": "POST" } }));
    expect(unknownPreflight.status).toBe(403);
    expect((await harness.fetch(request("/v1/refresh", { method: "POST", body: "{}" }))).status).toBe(415);
    const huge = "x".repeat(256 * 1024 + 1);
    expect((await harness.fetch(jsonRequest("/v1/refresh", { grantType: "refresh_token", refreshToken: huge }))).status).toBe(413);
  });

  it("sanitizes logs to metadata and excludes query strings and credentials", async () => {
    const events: SyncHttpLogEvent[] = [];
    const harness = await sqliteHarness((event) => events.push(event));
    await harness.fetch(request("/v1/pull?cursor=secret-token&limit=1", { headers: { authorization: "Bearer secret-token" } }));
    expect(events).toHaveLength(1);
    expect(JSON.stringify(events)).not.toContain("secret-token");
    expect(events[0]).toMatchObject({ method: "GET", path: "/v1/pull" });
  });

  it("does not let a failing log sink or untrusted request origin affect safety", async () => {
    const harness = await sqliteHarness(() => { throw new Error("sink unavailable"); });
    expect((await harness.fetch(request("/v1/health"))).status).toBe(200);
    expect((await harness.fetch(new Request("https://spoofed.example/v1/health"))).status).toBe(400);
  });
});

describe("browser login document", () => {
  it.each(["en", "de"])("is responsive, localized, semantic, and self-contained in %s", async (lang) => {
    const harness = await sqliteHarness();
    const attempt = await makeAttempt();
    const query = new URLSearchParams({ response_type: "code", redirect_uri: redirectUri, code_challenge: attempt.codeChallenge, state: attempt.state, attempt_id: attempt.attemptId, device_id: attempt.deviceId, lang });
    const response = await harness.fetch(request(`/v1/authorize?${query}`));
    const html = await response.text();
    const dom = new JSDOM(html);
    const document = dom.window.document;
    expect(response.headers.get("content-security-policy")).toContain("default-src 'none'");
    expect(document.documentElement.lang).toBe(lang);
    expect(document.querySelector("meta[name=viewport]")).not.toBeNull();
    expect(document.querySelector("main h1")).not.toBeNull();
    expect(document.querySelector("label[for=username]")).not.toBeNull();
    expect(document.querySelector("input[autocomplete=username][autofocus]")).not.toBeNull();
    expect(document.querySelector("input[type=password][autocomplete=current-password]")).not.toBeNull();
    expect(document.querySelector("[role=alert][aria-live=polite]")).not.toBeNull();
    expect(document.querySelectorAll("script[src],link[rel=stylesheet],img")).toHaveLength(0);
    expect(html).not.toContain("analytics");
    expect(html).toContain("target.hash=new URLSearchParams({code:result.code,state:result.state}).toString()");
    expect(html).not.toContain("target.searchParams.set('code'");
    dom.window.close();
  });
});
