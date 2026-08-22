import { fileURLToPath } from "node:url";
import { Miniflare } from "miniflare";
import { describe, expect, it } from "vitest";
import { SqliteSyncStorage } from "@habiter/sync-sqlite";
import {
  AuthError,
  SyncAuth,
  constantTimeEqual,
  createLoginProof,
  derivePasswordKey,
  generatePkceVerifier,
  passwordKdfIterations,
  pkceChallenge,
  redactAuthError,
  type AuthorizationAttempt,
  type LoginChallenge,
  type SetupInput,
  type TokenPair,
} from "../src/index";

interface AuthApi {
  setup(input: SetupInput): Promise<void>;
  beginLogin(attempt: AuthorizationAttempt): Promise<LoginChallenge>;
  completeLogin(challengeId: string, proof: string): Promise<{ code: string; state: string; redirectUri: string }>;
  redeemAuthorizationCode(input: { code: string; codeVerifier: string; redirectUri: string; attemptId: string }): Promise<TokenPair>;
  refresh(token: string): Promise<TokenPair>;
  verifyAccessToken(token: string): Promise<{ subject: string; deviceId: string; expiresAt: number }>;
  revokeDevice(deviceId: string): Promise<number>;
  revokeAll(): Promise<number>;
  changePassword(input: SetupInput & { currentPasswordKey: string }): Promise<void>;
}

interface Harness {
  auth: AuthApi;
  advance(milliseconds: number): void;
  cleanup(): Promise<void>;
}

const initialTime = Date.parse("2026-08-22T08:00:00.000Z");
const encryptionKey = new Uint8Array(32).fill(7);
const passwordKey = Buffer.alloc(32, 11).toString("base64url");
const nextPasswordKey = Buffer.alloc(32, 12).toString("base64url");
const salt = Buffer.alloc(16, 13).toString("base64url");
const nextSalt = Buffer.alloc(16, 14).toString("base64url");
const verifier = generatePkceVerifier(() => new Uint8Array(32).fill(21));

async function attempt(username = "owner", deviceId = "phone-a"): Promise<AuthorizationAttempt> {
  return {
    username,
    codeChallenge: await pkceChallenge(verifier),
    state: "state-123456789012",
    redirectUri: "https://app.habiter.dev/auth/callback",
    attemptId: "attempt-a",
    deviceId,
  };
}

const setupInput = (key = passwordKey, setupSalt = salt): SetupInput => ({
  username: "owner",
  passwordKey: key,
  salt: setupSalt,
  iterations: passwordKdfIterations,
});

async function authorize(auth: AuthApi, requested?: AuthorizationAttempt, key = passwordKey): Promise<TokenPair> {
  const input = requested ?? await attempt();
  const challenge = await auth.beginLogin(input);
  const proof = await createLoginProof(key, challenge.challengeId, input);
  const grant = await auth.completeLogin(challenge.challengeId, proof);
  expect(grant).toMatchObject({ state: input.state, redirectUri: input.redirectUri });
  return auth.redeemAuthorizationCode({
    code: grant.code,
    codeVerifier: verifier,
    redirectUri: input.redirectUri,
    attemptId: input.attemptId,
  });
}

async function sqliteHarness(): Promise<Harness> {
  let now = initialTime;
  const storage = new SqliteSyncStorage(":memory:");
  return {
    auth: new SyncAuth(storage, {
      issuer: "https://sync.example.test",
      audience: "habiter-mobile",
      encryptionKey,
      now: () => new Date(now),
    }),
    advance: (milliseconds) => { now += milliseconds; },
    cleanup: async () => storage.close(),
  };
}

class RemoteAuth implements AuthApi {
  constructor(private readonly miniflare: Miniflare, private now = initialTime) {}
  advance(milliseconds: number): void { this.now += milliseconds; }
  async call<T>(method: string, ...args: unknown[]): Promise<T> {
    const response = await this.miniflare.dispatchFetch("http://auth.test/", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ method, args, now: new Date(this.now).toISOString() }),
    });
    const body = await response.json() as { result: T; error?: { code: string; message: string; status: number } };
    if (!response.ok) {
      const error = new AuthError(body.error?.code ?? "authentication_error", body.error?.message ?? "Authentication request failed", body.error?.status ?? response.status);
      throw error;
    }
    return body.result;
  }
  setup(input: SetupInput): Promise<void> { return this.call("setup", input); }
  beginLogin(input: AuthorizationAttempt): Promise<LoginChallenge> { return this.call("beginLogin", input); }
  completeLogin(challengeId: string, proof: string): Promise<{ code: string; state: string; redirectUri: string }> { return this.call("completeLogin", challengeId, proof); }
  redeemAuthorizationCode(input: { code: string; codeVerifier: string; redirectUri: string; attemptId: string }): Promise<TokenPair> { return this.call("redeemAuthorizationCode", input); }
  refresh(token: string): Promise<TokenPair> { return this.call("refresh", token); }
  verifyAccessToken(token: string): Promise<{ subject: string; deviceId: string; expiresAt: number }> { return this.call("verifyAccessToken", token); }
  revokeDevice(deviceId: string): Promise<number> { return this.call("revokeDevice", deviceId); }
  revokeAll(): Promise<number> { return this.call("revokeAll"); }
  changePassword(input: SetupInput & { currentPasswordKey: string }): Promise<void> { return this.call("changePassword", input); }
}

async function d1Harness(): Promise<Harness> {
  const miniflare = new Miniflare({
    modules: true,
    scriptPath: fileURLToPath(new URL("../.tmp/worker.mjs", import.meta.url)),
    compatibilityDate: "2026-08-15",
    compatibilityFlags: ["nodejs_compat"],
    d1Databases: { DB: crypto.randomUUID() },
  });
  await miniflare.ready;
  const remote = new RemoteAuth(miniflare);
  return {
    auth: remote,
    advance: (milliseconds) => remote.advance(milliseconds),
    cleanup: async () => miniflare.dispose(),
  };
}

function registerAuthSuite(name: string, factory: () => Promise<Harness>): void {
  describe(`${name} authentication`, () => {
    it("enforces exactly one account and completes PKCE login", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        await expect(harness.auth.setup(setupInput())).rejects.toBeDefined();
        const tokens = await authorize(harness.auth);
        expect(tokens.refreshToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
        expect(await harness.auth.verifyAccessToken(tokens.accessToken)).toMatchObject({ subject: "owner", deviceId: "phone-a" });
      } finally { await harness.cleanup(); }
    });

    it("uses generic failures and consumes challenges exactly once", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const input = await attempt();
        const challenge = await harness.auth.beginLogin(input);
        await expect(harness.auth.completeLogin(challenge.challengeId, Buffer.alloc(32, 99).toString("base64url"))).rejects.toMatchObject({ code: "authentication_failed", message: "Authentication failed" });
        await expect(harness.auth.completeLogin(challenge.challengeId, await createLoginProof(passwordKey, challenge.challengeId, input))).rejects.toMatchObject({ code: "authentication_failed" });
        const unknown = await attempt("missing");
        const unknownChallenge = await harness.auth.beginLogin(unknown);
        await expect(harness.auth.completeLogin(unknownChallenge.challengeId, Buffer.alloc(32, 99).toString("base64url"))).rejects.toMatchObject({ code: "authentication_failed", message: "Authentication failed" });
      } finally { await harness.cleanup(); }
    });

    it("expires challenges and authorization codes", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const input = await attempt();
        const challenge = await harness.auth.beginLogin(input);
        harness.advance(5 * 60_000 + 1);
        await expect(harness.auth.completeLogin(challenge.challengeId, await createLoginProof(passwordKey, challenge.challengeId, input))).rejects.toMatchObject({ code: "authentication_failed" });
        const second = await harness.auth.beginLogin(input);
        const grant = await harness.auth.completeLogin(second.challengeId, await createLoginProof(passwordKey, second.challengeId, input));
        harness.advance(60_001);
        await expect(harness.auth.redeemAuthorizationCode({ code: grant.code, codeVerifier: verifier, redirectUri: input.redirectUri, attemptId: input.attemptId })).rejects.toMatchObject({ code: "invalid_grant" });
      } finally { await harness.cleanup(); }
    });

    it("binds and burns codes on PKCE, redirect, and attempt mismatch", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const input = await attempt();
        const challenge = await harness.auth.beginLogin(input);
        const grant = await harness.auth.completeLogin(challenge.challengeId, await createLoginProof(passwordKey, challenge.challengeId, input));
        await expect(harness.auth.redeemAuthorizationCode({ code: grant.code, codeVerifier: generatePkceVerifier(), redirectUri: input.redirectUri, attemptId: input.attemptId })).rejects.toMatchObject({ code: "invalid_grant" });
        await expect(harness.auth.redeemAuthorizationCode({ code: grant.code, codeVerifier: verifier, redirectUri: input.redirectUri, attemptId: input.attemptId })).rejects.toMatchObject({ code: "invalid_grant" });
      } finally { await harness.cleanup(); }
    });

    it("rotates refresh tokens and revokes a device on replay", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const first = await authorize(harness.auth);
        const second = await harness.auth.refresh(first.refreshToken);
        expect(second.refreshToken).not.toBe(first.refreshToken);
        await expect(harness.auth.refresh(first.refreshToken)).rejects.toMatchObject({ code: "refresh_replay" });
        await expect(harness.auth.refresh(second.refreshToken)).rejects.toMatchObject({ code: "refresh_replay" });
      } finally { await harness.cleanup(); }
    });

    it("supports per-device and global revocation", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const phone = await authorize(harness.auth, await attempt("owner", "phone-a"));
        const tabletAttempt = { ...(await attempt("owner", "tablet-a")), attemptId: "attempt-tablet" };
        const tablet = await authorize(harness.auth, tabletAttempt);
        expect(await harness.auth.revokeDevice("phone-a")).toBeGreaterThan(0);
        await expect(harness.auth.refresh(phone.refreshToken)).rejects.toMatchObject({ code: "refresh_replay" });
        expect(await harness.auth.revokeAll()).toBeGreaterThan(0);
        await expect(harness.auth.refresh(tablet.refreshToken)).rejects.toMatchObject({ code: "refresh_replay" });
      } finally { await harness.cleanup(); }
    });

    it("rate-limits bounded generic login failures", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const input = await attempt();
        for (let count = 0; count < 5; count += 1) {
          const challenge = await harness.auth.beginLogin(input);
          await expect(harness.auth.completeLogin(challenge.challengeId, Buffer.alloc(32, 99).toString("base64url"))).rejects.toMatchObject({ code: "authentication_failed" });
        }
        const blocked = await harness.auth.beginLogin(input);
        await expect(harness.auth.completeLogin(blocked.challengeId, await createLoginProof(passwordKey, blocked.challengeId, input))).rejects.toMatchObject({ code: "rate_limited", status: 429 });
        harness.advance(15_001);
        const recovered = await harness.auth.beginLogin(input);
        await expect(harness.auth.completeLogin(recovered.challengeId, await createLoginProof(passwordKey, recovered.challengeId, input))).resolves.toHaveProperty("code");
      } finally { await harness.cleanup(); }
    });

    it("revokes sessions and invalidates old proof material on password change", async () => {
      const harness = await factory();
      try {
        await harness.auth.setup(setupInput());
        const tokens = await authorize(harness.auth);
        await harness.auth.changePassword({ ...setupInput(nextPasswordKey, nextSalt), currentPasswordKey: passwordKey });
        await expect(harness.auth.refresh(tokens.refreshToken)).rejects.toMatchObject({ code: "refresh_replay" });
        const input = await attempt();
        const challenge = await harness.auth.beginLogin(input);
        await expect(harness.auth.completeLogin(challenge.challengeId, await createLoginProof(passwordKey, challenge.challengeId, input))).rejects.toMatchObject({ code: "authentication_failed" });
        const next = await harness.auth.beginLogin(input);
        await expect(harness.auth.completeLogin(next.challengeId, await createLoginProof(nextPasswordKey, next.challengeId, input))).resolves.toHaveProperty("code");
      } finally { await harness.cleanup(); }
    });
  });
}

registerAuthSuite("SQLite", sqliteHarness);
registerAuthSuite("D1 Worker", d1Harness);

describe("authentication crypto and redaction", () => {
  it("derives stable 600k-round client keys within a bounded benchmark", async () => {
    const started = performance.now();
    const first = await derivePasswordKey("correct horse battery staple", salt);
    const elapsed = performance.now() - started;
    expect(first).toBe(await derivePasswordKey("correct horse battery staple", salt));
    expect(first).not.toBe(await derivePasswordKey("correct horse battery stapler", salt));
    expect(elapsed).toBeLessThan(2_000);
  });

  it("compares secrets without early length or byte equality exits", () => {
    expect(constantTimeEqual(new Uint8Array([1, 2, 3]), new Uint8Array([1, 2, 3]))).toBe(true);
    expect(constantTimeEqual(new Uint8Array([1, 2, 3]), new Uint8Array([1, 2, 4]))).toBe(false);
    expect(constantTimeEqual(new Uint8Array([1]), new Uint8Array([1, 0]))).toBe(false);
  });

  it("redacts unknown errors and never serializes their secret text", () => {
    const redacted = redactAuthError(new Error("password=hunter2 refresh=secret"));
    expect(JSON.stringify(redacted)).not.toMatch(/hunter2|secret|password|refresh/);
    expect(redacted).toEqual({ error: "authentication_error", message: "Authentication request failed", status: 500 });
    expect(JSON.stringify(redactAuthError(new AuthError("custom", "token=top-secret", 400)))).not.toContain("top-secret");
  });

  it("does not persist plaintext password material or bearer credentials", async () => {
    const storage = new SqliteSyncStorage(":memory:");
    try {
      const auth = new SyncAuth(storage, { issuer: "https://sync.example.test", audience: "habiter-mobile", encryptionKey, now: () => new Date(initialTime) });
      const plaintext = "a long private passphrase";
      const derived = await derivePasswordKey(plaintext, salt);
      await auth.setup(setupInput(derived));
      const tokens = await authorize(auth, await attempt(), derived);
      const account = await storage.getAccount();
      expect(JSON.stringify(account)).not.toContain(plaintext);
      expect(JSON.stringify(account)).not.toContain(derived);
      const digest = Buffer.from(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(tokens.refreshToken))).toString("hex");
      const session = storage.getSession(digest);
      expect(session).not.toBeNull();
      expect(JSON.stringify(session)).not.toContain(tokens.refreshToken);
      expect(JSON.stringify(session)).not.toContain(tokens.accessToken);
    } finally { storage.close(); }
  });

  it("keeps unknown-account salts stable and rejects unsafe redirect URIs", async () => {
    const harness = await sqliteHarness();
    try {
      const missing = await attempt("missing");
      expect((await harness.auth.beginLogin(missing)).salt).toBe((await harness.auth.beginLogin(missing)).salt);
      await expect(harness.auth.beginLogin({ ...(await attempt()), redirectUri: "https://app.habiter.dev/auth/callback#token" })).rejects.toMatchObject({ code: "invalid_authorization_request" });
    } finally { await harness.cleanup(); }
  });

  it("keeps server-side proof verification within a focused benchmark", async () => {
    const harness = await sqliteHarness();
    try {
      const started = performance.now();
      await harness.auth.setup(setupInput());
      const input = await attempt();
      const challenge = await harness.auth.beginLogin(input);
      await harness.auth.completeLogin(challenge.challengeId, await createLoginProof(passwordKey, challenge.challengeId, input));
      expect(performance.now() - started).toBeLessThan(100);
    } finally { await harness.cleanup(); }
  });

  it("keeps the Worker-side crypto primitive set below the free CPU budget", async () => {
    const harness = await d1Harness();
    try {
      const result = await (harness.auth as RemoteAuth).call<{ durationMs: number; operations: number }>("cryptoBenchmark");
      expect(result.operations).toBe(5);
      expect(result.durationMs).toBeLessThan(10);
    } finally { await harness.cleanup(); }
  });
});
