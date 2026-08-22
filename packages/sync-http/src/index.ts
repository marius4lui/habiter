import {
  AuthError,
  SyncAuth,
  redactAuthError,
  type AuthorizationAttempt,
} from "@habiter/sync-auth";
import {
  SyncCoreError,
  createOperation,
  type SyncOperation,
  type SyncStorage,
} from "@habiter/sync-core";

export interface SyncHttpConfig {
  instanceName: string;
  baseUrl: string;
  redirectUris: readonly string[];
  corsOrigins?: readonly string[];
  maximumBodyBytes?: number;
  maximumPushOperations?: number;
  maximumPullOperations?: number;
  log?: (event: SyncHttpLogEvent) => void;
}

export interface SyncHttpLogEvent {
  requestId: string;
  method: string;
  path: string;
  status: number;
  durationMs: number;
}

export interface SyncHttpDependencies {
  storage: SyncStorage;
  auth: SyncAuth;
  config: SyncHttpConfig;
}

interface NormalizedConfig {
  instanceName: string;
  baseUrl: string;
  redirectUris: Set<string>;
  corsOrigins: Set<string>;
  maximumBodyBytes: number;
  maximumPushOperations: number;
  maximumPullOperations: number;
  log?: (event: SyncHttpLogEvent) => void;
}

export function createSyncHttpHandler(dependencies: SyncHttpDependencies): (request: Request) => Promise<Response> {
  const config = normalizeConfig(dependencies.config);
  return async (request: Request): Promise<Response> => {
    const started = performance.now();
    const requestId = requestIdFor(request);
    let url: URL | undefined;
    let response: Response;
    try {
      if (request.url.length > 8192) throw requestError("request_target_too_large", "Request target is too large", 414);
      url = safeUrl(request.url);
      if (url.origin !== new URL(config.baseUrl).origin) throw requestError("invalid_request_target", "Request target is invalid", 400);
      enforceOrigin(request, config);
      if (request.method === "OPTIONS") response = preflight(request, config, requestId);
      else response = await dispatch(request, url, requestId, dependencies.storage, dependencies.auth, config);
    } catch (error) {
      response = errorResponse(error, requestId);
    }
    response = secure(response, requestId, request.headers.get("origin"), config);
    try {
      config.log?.({
      requestId,
      method: boundedLogValue(request.method, 16),
      path: boundedLogValue(url?.pathname ?? "/", 256),
        status: response.status,
        durationMs: Math.round((performance.now() - started) * 100) / 100,
      });
    } catch { /* A telemetry sink must never affect the protocol response. */ }
    return response;
  };
}

async function dispatch(
  request: Request,
  url: URL,
  requestId: string,
  storage: SyncStorage,
  auth: SyncAuth,
  config: NormalizedConfig,
): Promise<Response> {
  const route = `${request.method} ${url.pathname}`;
  if (url.search !== "" && route !== "GET /v1/authorize" && route !== "GET /v1/pull") throw requestError("invalid_request", "Request is invalid", 400);
  if (route === "GET /v1/health") { noSearch(url); return json({ status: "ok", version: 1 }, 200); }
  if (route === "GET /v1/capabilities") { noSearch(url); return json({
    protocolVersion: 1,
    authentication: { authorizationCode: true, pkceMethods: ["S256"], refreshRotation: true },
    sync: { push: true, pull: true, snapshotRecovery: true, maximumPushOperations: config.maximumPushOperations, maximumPullOperations: config.maximumPullOperations },
  }, 200); }
  if (route === "GET /v1/instance-info") { noSearch(url); return json({
    protocolVersion: 1,
    name: config.instanceName,
    baseUrl: config.baseUrl,
    initialized: (await storage.getAccount()) !== null,
  }, 200); }
  if (route === "GET /v1/authorize") return authorizePage(url, config);
  if (route === "POST /v1/authorize") return authorizeAction(request, auth, config);
  if (route === "POST /v1/token") {
    const body = await bodyObject(request, config);
    exactKeys(body, ["attemptId", "code", "codeVerifier", "grantType", "redirectUri"]);
    if (body.grantType !== "authorization_code") throw requestError("unsupported_grant_type", "Grant type is unsupported", 400);
    assertRedirect(body.redirectUri, config);
    return json(await auth.redeemAuthorizationCode({ code: text(body.code, "code", 512), codeVerifier: text(body.codeVerifier, "codeVerifier", 128), redirectUri: body.redirectUri as string, attemptId: identifier(body.attemptId, "attemptId") }), 200);
  }
  if (route === "POST /v1/refresh") {
    const body = await bodyObject(request, config);
    exactKeys(body, ["grantType", "refreshToken"]);
    if (body.grantType !== "refresh_token") throw requestError("unsupported_grant_type", "Grant type is unsupported", 400);
    return json(await auth.refresh(text(body.refreshToken, "refreshToken", 512)), 200);
  }
  if (route === "POST /v1/revoke") {
    const claims = await bearer(request, auth);
    const body = await bodyObject(request, config);
    exactKeys(body, ["scope"]);
    const scope = body.scope ?? "device";
    if (scope !== "device" && scope !== "all") throw requestError("invalid_request", "Request is invalid", 400);
    const revoked = scope === "all" ? await auth.revokeAll() : await auth.revokeDevice(claims.deviceId);
    return json({ revoked }, 200);
  }
  if (route === "POST /v1/push") {
    await bearer(request, auth);
    const body = await bodyObject(request, config);
    exactKeys(body, ["operations"]);
    if (!Array.isArray(body.operations) || body.operations.length < 1 || body.operations.length > config.maximumPushOperations) throw requestError("invalid_request", "Request is invalid", 400);
    const operations = body.operations.map((operation) => createOperation(operation as SyncOperation));
    const receipts = [];
    for (const operation of operations) receipts.push(await storage.commit(operation));
    return json({ receipts }, 200);
  }
  if (route === "GET /v1/pull") {
    await bearer(request, auth);
    exactSearch(url, ["cursor", "limit"]);
    const limit = boundedInteger(url.searchParams.get("limit") ?? "100", 1, config.maximumPullOperations);
    const cursor = url.searchParams.get("cursor");
    return json(await storage.pull(cursor, limit), 200);
  }
  if (route === "GET /v1/snapshot") {
    await bearer(request, auth);
    noSearch(url);
    return json(await storage.snapshot(), 200);
  }
  if (route === "GET /v1/device") {
    const claims = await bearer(request, auth);
    return json({ deviceId: claims.deviceId, accessExpiresAt: claims.expiresAt }, 200);
  }
  if (route === "DELETE /v1/device") {
    const claims = await bearer(request, auth);
    return json({ revoked: await auth.revokeDevice(claims.deviceId) }, 200);
  }
  throw requestError("not_found", "Route was not found", 404);
}

function authorizePage(url: URL, config: NormalizedConfig): Response {
  exactSearch(url, ["attempt_id", "code_challenge", "device_id", "lang", "redirect_uri", "response_type", "state"]);
  if (url.searchParams.get("response_type") !== "code") throw requestError("invalid_authorization_request", "Authorization request is invalid", 400);
  const attempt = attemptFrom(url.searchParams, config);
  const requestedLanguage = url.searchParams.get("lang");
  if (requestedLanguage !== null && requestedLanguage !== "de" && requestedLanguage !== "en") throw requestError("invalid_authorization_request", "Authorization request is invalid", 400);
  const language = requestedLanguage === "de" ? "de" : "en";
  const nonce = randomToken(18);
  return new Response(loginHtml(language, nonce, attempt), {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "content-language": language,
      "content-security-policy": `default-src 'none'; script-src 'nonce-${nonce}'; style-src 'nonce-${nonce}'; connect-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'`,
    },
  });
}

async function authorizeAction(request: Request, auth: SyncAuth, config: NormalizedConfig): Promise<Response> {
  requireSameSite(request);
  const body = await bodyObject(request, config);
  const csrfHeader = request.headers.get("x-habiter-csrf");
  if (csrfHeader === null || csrfHeader !== body.csrf) throw requestError("csrf_failed", "Request verification failed", 403);
  const action = body.action;
  if (action === "begin") {
    exactKeys(body, ["action", "attempt", "csrf"]);
    const attempt = parseAttempt(body.attempt, config);
    assertCsrf(body.csrf, attempt.state);
    return json(await auth.beginLogin(attempt), 200);
  }
  if (action === "complete") {
    exactKeys(body, ["action", "challengeId", "csrf", "proof"]);
    assertCsrf(body.csrf, undefined);
    const result = await auth.completeLogin(text(body.challengeId, "challengeId", 512), text(body.proof, "proof", 128));
    assertCsrf(body.csrf, result.state);
    assertRedirect(result.redirectUri, config);
    return json(result, 200);
  }
  throw requestError("invalid_request", "Request is invalid", 400);
}

function attemptFrom(parameters: URLSearchParams, config: NormalizedConfig): AuthorizationAttempt {
  const redirectUri = parameters.get("redirect_uri");
  assertRedirect(redirectUri, config);
  return parseAttempt({
    username: "placeholder",
    codeChallenge: parameters.get("code_challenge"),
    state: parameters.get("state"),
    redirectUri,
    attemptId: parameters.get("attempt_id"),
    deviceId: parameters.get("device_id"),
  }, config, true);
}

function parseAttempt(value: unknown, config: NormalizedConfig, placeholder = false): AuthorizationAttempt {
  if (!record(value)) throw requestError("invalid_authorization_request", "Authorization request is invalid", 400);
  exactKeys(value, ["attemptId", "codeChallenge", "deviceId", "redirectUri", "state", "username"]);
  const redirectUri = text(value.redirectUri, "redirectUri", 2048);
  assertRedirect(redirectUri, config);
  return {
    username: placeholder ? "placeholder" : text(value.username, "username", 128),
    codeChallenge: opaque(value.codeChallenge, "codeChallenge", 43, 43),
    state: opaque(value.state, "state", 16, 256),
    redirectUri,
    attemptId: identifier(value.attemptId, "attemptId"),
    deviceId: identifier(value.deviceId, "deviceId"),
  };
}

async function bearer(request: Request, auth: SyncAuth) {
  const authorization = request.headers.get("authorization");
  if (authorization === null || !authorization.startsWith("Bearer ") || authorization.length > 4096) throw new AuthError("invalid_access_token", "Access token is invalid", 401);
  return auth.verifyAccessToken(authorization.slice(7));
}

async function bodyObject(request: Request, config: NormalizedConfig): Promise<Record<string, unknown>> {
  if (request.headers.get("content-type")?.split(";", 1)[0]?.trim().toLowerCase() !== "application/json") throw requestError("unsupported_media_type", "Content type must be application/json", 415);
  const declared = Number(request.headers.get("content-length"));
  if (Number.isFinite(declared) && declared > config.maximumBodyBytes) throw requestError("payload_too_large", "Request body is too large", 413);
  const raw = await request.text();
  if (new TextEncoder().encode(raw).byteLength > config.maximumBodyBytes) throw requestError("payload_too_large", "Request body is too large", 413);
  try {
    const value: unknown = JSON.parse(raw);
    if (!record(value)) throw new Error("not_object");
    return value;
  } catch {
    throw requestError("invalid_json", "Request body is invalid", 400);
  }
}

function preflight(request: Request, config: NormalizedConfig, requestId: string): Response {
  const origin = request.headers.get("origin");
  if (origin === null || !config.corsOrigins.has(origin)) throw requestError("cors_denied", "Cross-origin request is not allowed", 403);
  const method = request.headers.get("access-control-request-method");
  if (!new Set(["GET", "POST", "DELETE"]).has(method ?? "")) throw requestError("cors_denied", "Cross-origin request is not allowed", 403);
  const allowedRoutes = new Set(["/v1/authorize", "/v1/capabilities", "/v1/device", "/v1/health", "/v1/instance-info", "/v1/pull", "/v1/push", "/v1/refresh", "/v1/revoke", "/v1/snapshot", "/v1/token"]);
  if (!allowedRoutes.has(new URL(request.url).pathname)) throw requestError("cors_denied", "Cross-origin request is not allowed", 403);
  const requested = (request.headers.get("access-control-request-headers") ?? "").toLowerCase().split(",").map((item) => item.trim()).filter(Boolean);
  if (requested.some((header) => !["authorization", "content-type", "x-habiter-csrf", "x-request-id"].includes(header))) throw requestError("cors_denied", "Cross-origin request is not allowed", 403);
  return new Response(null, { status: 204, headers: { "access-control-max-age": "600", "x-request-id": requestId } });
}

function enforceOrigin(request: Request, config: NormalizedConfig): void {
  const origin = request.headers.get("origin");
  if (origin !== null && origin !== new URL(config.baseUrl).origin && !config.corsOrigins.has(origin)) throw requestError("cors_denied", "Cross-origin request is not allowed", 403);
}

function secure(response: Response, requestId: string, origin: string | null, config: NormalizedConfig): Response {
  const headers = new Headers(response.headers);
  const defaults: Record<string, string> = {
    "cache-control": "no-store",
    "cross-origin-opener-policy": "same-origin",
    "cross-origin-embedder-policy": "require-corp",
    "cross-origin-resource-policy": "same-origin",
    "permissions-policy": "camera=(), geolocation=(), microphone=(), payment=(), usb=()",
    "referrer-policy": "no-referrer",
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "x-request-id": requestId,
  };
  if (new URL(config.baseUrl).protocol === "https:") defaults["strict-transport-security"] = "max-age=31536000; includeSubDomains";
  if (!headers.has("content-security-policy")) defaults["content-security-policy"] = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'";
  for (const [key, value] of Object.entries(defaults)) if (!headers.has(key)) headers.set(key, value);
  if (origin !== null && config.corsOrigins.has(origin)) {
    headers.set("access-control-allow-origin", origin);
    headers.set("access-control-allow-methods", "GET, POST, DELETE, OPTIONS");
    headers.set("access-control-allow-headers", "Authorization, Content-Type, X-Habiter-CSRF, X-Request-ID");
    headers.set("vary", "Origin");
  }
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function errorResponse(error: unknown, requestId: string): Response {
  if (error instanceof HttpError) return json({ error: error.code, message: error.publicMessage, requestId }, error.status);
  if (error instanceof AuthError || (record(error) && error.name === "AuthError")) {
    const redacted = redactAuthError(error);
    return json({ error: redacted.error, message: redacted.message, requestId }, redacted.status);
  }
  if (error instanceof SyncCoreError) return json({ error: "invalid_sync_operation", message: "Sync operation is invalid", requestId }, 400);
  return json({ error: "internal_error", message: "Request failed", requestId }, 500);
}

class HttpError extends Error {
  constructor(readonly code: string, readonly publicMessage: string, readonly status: number) { super(publicMessage); }
}

function requestError(code: string, message: string, status: number): HttpError { return new HttpError(code, message, status); }
function json(value: unknown, status: number): Response { return Response.json(value, { status, headers: { "content-type": "application/json; charset=utf-8" } }); }
function safeUrl(value: string): URL { try { return new URL(value); } catch { throw requestError("invalid_request_target", "Request target is invalid", 400); } }
function record(value: unknown): value is Record<string, unknown> { return typeof value === "object" && value !== null && !Array.isArray(value); }
function exactKeys(value: Record<string, unknown>, allowed: string[]): void { if (Object.keys(value).some((key) => !allowed.includes(key))) throw requestError("invalid_request", "Request is invalid", 400); }
function exactSearch(url: URL, allowed: string[]): void {
  const keys = [...url.searchParams.keys()];
  if (keys.some((key) => !allowed.includes(key)) || new Set(keys).size !== keys.length) throw requestError("invalid_authorization_request", "Authorization request is invalid", 400);
}
function noSearch(url: URL): void { if ([...url.searchParams].length > 0) throw requestError("invalid_request", "Request is invalid", 400); }
function text(value: unknown, _label: string, maximum: number): string { if (typeof value !== "string" || value.length < 1 || value.length > maximum) throw requestError("invalid_request", "Request is invalid", 400); return value; }
function opaque(value: unknown, label: string, minimum: number, maximum: number): string { const result = text(value, label, maximum); if (result.length < minimum || !/^[A-Za-z0-9._~-]+$/.test(result)) throw requestError("invalid_authorization_request", "Authorization request is invalid", 400); return result; }
function identifier(value: unknown, label: string): string { return opaque(value, label, 1, 256); }
function boundedInteger(value: string, minimum: number, maximum: number): number { const result = Number(value); if (!Number.isSafeInteger(result) || result < minimum || result > maximum || String(result) !== value) throw requestError("invalid_request", "Request is invalid", 400); return result; }
function assertRedirect(value: unknown, config: NormalizedConfig): asserts value is string { if (typeof value !== "string" || !config.redirectUris.has(value)) throw requestError("invalid_authorization_request", "Authorization request is invalid", 400); }
function assertCsrf(value: unknown, expected: string | undefined): void { if (typeof value !== "string" || value.length < 16 || value.length > 256 || (expected !== undefined && value !== expected)) throw requestError("csrf_failed", "Request verification failed", 403); }
function requireSameSite(request: Request): void { const site = request.headers.get("sec-fetch-site"); if (site !== null && site !== "same-origin" && site !== "none") throw requestError("csrf_failed", "Request verification failed", 403); }
function requestIdFor(request: Request): string { const supplied = request.headers.get("x-request-id"); return supplied !== null && /^[A-Za-z0-9._~-]{8,128}$/.test(supplied) ? supplied : randomToken(16); }
function randomToken(length: number): string { const value = crypto.getRandomValues(new Uint8Array(length)); let binary = ""; for (const byte of value) binary += String.fromCharCode(byte); return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", ""); }
function boundedLogValue(value: string, maximum: number): string { return value.replaceAll(/[\r\n\t]/g, "_").slice(0, maximum); }

function normalizeConfig(input: SyncHttpConfig): NormalizedConfig {
  const baseUrl = absoluteHttps(input.baseUrl, "baseUrl");
  const redirectUris = new Set(input.redirectUris.map((value) => absoluteRedirect(value)));
  if (redirectUris.size === 0 || redirectUris.size !== input.redirectUris.length) throw new Error("redirectUris must be unique and non-empty");
  const corsOrigins = new Set((input.corsOrigins ?? []).map((value) => new URL(absoluteHttps(value, "corsOrigins")).origin));
  return {
    instanceName: text(input.instanceName, "instanceName", 128),
    baseUrl,
    redirectUris,
    corsOrigins,
    maximumBodyBytes: optionInteger(input.maximumBodyBytes ?? 256 * 1024, 1024, 1024 * 1024),
    maximumPushOperations: optionInteger(input.maximumPushOperations ?? 100, 1, 500),
    maximumPullOperations: optionInteger(input.maximumPullOperations ?? 500, 1, 500),
    ...(input.log === undefined ? {} : { log: input.log }),
  };
}

function absoluteHttps(value: string, label: string): string { const url = new URL(value); if (url.username || url.password || url.hash || (url.protocol !== "https:" && !(url.protocol === "http:" && ["localhost", "127.0.0.1", "::1"].includes(url.hostname)))) throw new Error(`${label} must be an HTTPS URL`); return url.href.replace(/\/$/, ""); }
function absoluteRedirect(value: string): string { const url = new URL(value); if (url.username || url.password || url.hash || (url.protocol !== "https:" && !(url.protocol === "http:" && ["localhost", "127.0.0.1", "::1"].includes(url.hostname)))) throw new Error("redirectUris contains an unsafe URL"); return url.href; }
function optionInteger(value: number, minimum: number, maximum: number): number { if (!Number.isSafeInteger(value) || value < minimum || value > maximum) throw new Error("HTTP bound is invalid"); return value; }

function loginHtml(language: "de" | "en", nonce: string, attempt: AuthorizationAttempt): string {
  const copy = language === "de"
    ? { title: "Mit Habiter verbinden", intro: "Melde dich an, um dieses Gerät sicher zu verbinden.", username: "Benutzername", password: "Passwort", submit: "Sicher anmelden", pending: "Anmeldung wird geprüft …", error: "Die Anmeldung ist fehlgeschlagen. Prüfe deine Angaben und versuche es erneut.", note: "Dein Passwort bleibt in diesem Browser." }
    : { title: "Connect to Habiter", intro: "Sign in to connect this device securely.", username: "Username", password: "Password", submit: "Sign in securely", pending: "Checking your sign-in…", error: "Sign-in failed. Check your details and try again.", note: "Your password stays in this browser." };
  const data = JSON.stringify({ ...attempt, username: undefined }).replaceAll("<", "\\u003c");
  return `<!doctype html><html lang="${language}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${copy.title}</title><style nonce="${nonce}">:root{font-family:system-ui,sans-serif;color-scheme:light dark;background:#f5f2fa;color:#211a2b}*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;padding:clamp(1rem,4vw,3rem)}main{width:min(100%,30rem);background:#fff;color:#211a2b;border-radius:1.5rem;padding:clamp(1.5rem,6vw,3rem);box-shadow:0 1rem 3rem #392b4c22}h1{font-size:clamp(1.75rem,7vw,2.5rem);line-height:1.1;margin:0 0 .75rem}p{line-height:1.55}label{display:block;font-weight:700;margin-top:1.25rem}input{font:inherit;width:100%;min-height:3rem;margin-top:.4rem;padding:.7rem .85rem;border:2px solid #766780;border-radius:.7rem}input:focus-visible,button:focus-visible{outline:4px solid #b69de6;outline-offset:3px}button{font:inherit;font-weight:750;width:100%;min-height:3.25rem;margin-top:1.5rem;border:0;border-radius:999px;background:#6750a4;color:#fff;padding:.75rem 1rem}button:disabled{opacity:.65}.note{font-size:.9rem}.error{color:#a51624;font-weight:650;min-height:3rem}[hidden]{display:none}@media(prefers-reduced-motion:no-preference){button{transition:filter .15s}button:hover{filter:brightness(1.1)}}@media(prefers-color-scheme:dark){:root{background:#17131d;color:#f4effa}main{background:#241d2c;color:#f4effa}input{background:#17131d;color:#fff}}</style></head><body><main><h1>${copy.title}</h1><p>${copy.intro}</p><form id="login"><label for="username">${copy.username}</label><input id="username" name="username" autocomplete="username" maxlength="128" required autofocus><label for="password">${copy.password}</label><input id="password" name="password" type="password" autocomplete="current-password" minlength="12" maxlength="1024" required><button id="submit" type="submit">${copy.submit}</button><p class="note">${copy.note}</p><p id="status" class="error" role="alert" aria-live="polite"></p></form></main><script nonce="${nonce}">const attempt=${data};const form=document.querySelector('#login'),button=document.querySelector('#submit'),status=document.querySelector('#status');const enc=new TextEncoder(),b64=b=>btoa(String.fromCharCode(...b)).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');const post=async body=>{const response=await fetch('/v1/authorize',{method:'POST',headers:{'content-type':'application/json','x-habiter-csrf':attempt.state},body:JSON.stringify(body)});if(!response.ok)throw Error('auth');return response.json()};form.addEventListener('submit',async event=>{event.preventDefault();button.disabled=true;button.textContent=${JSON.stringify(copy.pending)};status.textContent='';try{attempt.username=form.username.value;const challenge=await post({action:'begin',csrf:attempt.state,attempt});const salt=Uint8Array.from(atob(challenge.salt.replaceAll('-','+').replaceAll('_','/').padEnd(Math.ceil(challenge.salt.length/4)*4,'=')),c=>c.charCodeAt(0));const material=await crypto.subtle.importKey('raw',enc.encode(form.password.value),'PBKDF2',false,['deriveBits']);const passwordKey=new Uint8Array(await crypto.subtle.deriveBits({name:'PBKDF2',hash:'SHA-256',salt,iterations:challenge.iterations},material,256));form.password.value='';const message=JSON.stringify({version:1,purpose:'habiter-login',challengeId:challenge.challengeId,username:attempt.username,codeChallenge:attempt.codeChallenge,state:attempt.state,redirectUri:attempt.redirectUri,attemptId:attempt.attemptId,deviceId:attempt.deviceId});const hmac=await crypto.subtle.importKey('raw',passwordKey,{name:'HMAC',hash:'SHA-256'},false,['sign']);passwordKey.fill(0);const proof=b64(new Uint8Array(await crypto.subtle.sign('HMAC',hmac,enc.encode(message))));const result=await post({action:'complete',csrf:attempt.state,challengeId:challenge.challengeId,proof});const target=new URL(result.redirectUri);target.hash=new URLSearchParams({code:result.code,state:result.state}).toString();location.assign(target.href)}catch{form.password.value='';status.textContent=${JSON.stringify(copy.error)};button.disabled=false;button.textContent=${JSON.stringify(copy.submit)};form.password.focus()}});</script></body></html>`;
}
