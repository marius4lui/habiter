import { SyncAuth, constantTimeEqual, type SetupInput } from "@habiter/sync-auth";
import { D1SyncStorage, type D1DatabaseLike, type D1QueryUsage } from "@habiter/sync-d1";
import { createSyncHttpHandler } from "@habiter/sync-http";

export interface Env {
  DB?: D1DatabaseLike;
  BASE_URL: string;
  REDIRECT_URIS: string;
  CORS_ORIGINS?: string;
  INSTANCE_NAME?: string;
  AUDIENCE?: string;
  HABITER_SYNC_INSTANCE_KEY?: string;
  HABITER_SYNC_SETUP_TOKEN?: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const usage: D1QueryUsage = { statements: 0, rowsRead: 0, rowsWritten: 0 };
    try {
      const storage = await D1SyncStorage.open(env.DB, { onUsage: (item) => addUsage(usage, item) });
      const auth = new SyncAuth(storage, {
        issuer: requiredOrigin(env.BASE_URL),
        audience: env.AUDIENCE?.trim() || "habiter-mobile",
        encryptionKey: decodeSecret(env.HABITER_SYNC_INSTANCE_KEY, "instance_key", 32),
      });
      const url = new URL(request.url);
      let response: Response;
      if (url.pathname === "/_admin/setup") response = await setup(request, env, auth);
      else {
        response = await createSyncHttpHandler({
          storage,
          auth,
          config: {
            instanceName: env.INSTANCE_NAME?.trim() || "Habiter Personal Sync Worker Beta",
            baseUrl: env.BASE_URL,
            redirectUris: csv(env.REDIRECT_URIS),
            corsOrigins: csv(env.CORS_ORIGINS ?? ""),
          },
        })(request);
      }
      safeUsageLog(request, response.status, usage);
      return response;
    } catch {
      safeUsageLog(request, 503, usage);
      return securedJson({ error: "service_unavailable", message: "Personal Sync is unavailable" }, 503);
    }
  },
};

async function setup(request: Request, env: Env, auth: SyncAuth): Promise<Response> {
  if (request.method !== "POST" || new URL(request.url).origin !== requiredOrigin(env.BASE_URL)) return securedJson({ error: "not_found", message: "Route was not found" }, 404);
  const expected = env.HABITER_SYNC_SETUP_TOKEN;
  const authorization = request.headers.get("authorization");
  const supplied = authorization?.startsWith("Bearer ") ? authorization.slice(7) : "";
  if (expected === undefined || expected.length < 32 || supplied.length > 256 || !await secretEqual(supplied, expected)) return securedJson({ error: "setup_unauthorized", message: "Setup authorization failed" }, 401);
  if (request.headers.get("content-type")?.split(";", 1)[0]?.trim().toLowerCase() !== "application/json") return securedJson({ error: "unsupported_media_type", message: "Content type must be application/json" }, 415);
  const declared = Number(request.headers.get("content-length"));
  if (Number.isFinite(declared) && declared > 4096) return securedJson({ error: "payload_too_large", message: "Request body is too large" }, 413);
  const raw = await request.text();
  if (new TextEncoder().encode(raw).byteLength > 4096) return securedJson({ error: "payload_too_large", message: "Request body is too large" }, 413);
  try {
    const body = JSON.parse(raw) as SetupInput;
    if (body === null || typeof body !== "object" || Array.isArray(body) || Object.keys(body).sort().join(",") !== "iterations,passwordKey,salt,username") throw new Error("invalid setup body");
    await auth.setup(body);
    return new Response(null, { status: 204, headers: securityHeaders() });
  } catch {
    return securedJson({ error: "setup_failed", message: "Setup could not be completed" }, 409);
  }
}

function requiredOrigin(value: string): string { const url = new URL(value); if (url.protocol !== "https:" && !(url.protocol === "http:" && ["localhost", "127.0.0.1", "::1"].includes(url.hostname))) throw new Error("unsafe origin"); if (url.username || url.password || url.hash || url.search || url.pathname !== "/") throw new Error("invalid origin"); return url.origin; }
function csv(value: string): string[] { return value.split(",").map((item) => item.trim()).filter(Boolean); }
function decodeSecret(value: string | undefined, name: string, length: number): Uint8Array { if (value === undefined) throw new Error(`missing ${name}`); try { const normalized = value.replaceAll("-", "+").replaceAll("_", "/").padEnd(Math.ceil(value.length / 4) * 4, "="); const bytes = Uint8Array.from(atob(normalized), (character) => character.charCodeAt(0)); if (bytes.byteLength !== length || encode(bytes) !== value) throw new Error("length"); return bytes; } catch { throw new Error(`invalid ${name}`); } }
function encode(value: Uint8Array): string { let binary = ""; for (const byte of value) binary += String.fromCharCode(byte); return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", ""); }
async function secretEqual(left: string, right: string): Promise<boolean> { const digest = async (value: string) => new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value))); return constantTimeEqual(await digest(left), await digest(right)); }
function addUsage(total: D1QueryUsage, item: D1QueryUsage): void { total.statements += item.statements; total.rowsRead += item.rowsRead; total.rowsWritten += item.rowsWritten; }
function usageLog(request: Request, status: number, usage: D1QueryUsage): void { console.log(JSON.stringify({ event: "d1_usage", requestId: safeRequestId(request.headers.get("x-request-id")), path: new URL(request.url).pathname.slice(0, 256), status, ...usage })); }
function safeUsageLog(request: Request, status: number, usage: D1QueryUsage): void { try { usageLog(request, status, usage); } catch { /* Observability must never alter protocol behavior. */ } }
function safeRequestId(value: string | null): string | null { return value !== null && /^[A-Za-z0-9._~-]{8,128}$/.test(value) ? value : null; }
function securityHeaders(): Headers { return new Headers({ "cache-control": "no-store", "content-security-policy": "default-src 'none'; frame-ancestors 'none'; base-uri 'none'", "cross-origin-resource-policy": "same-origin", "referrer-policy": "no-referrer", "strict-transport-security": "max-age=31536000; includeSubDomains", "x-content-type-options": "nosniff", "x-frame-options": "DENY" }); }
function securedJson(value: object, status: number): Response { const headers = securityHeaders(); headers.set("content-type", "application/json; charset=utf-8"); return Response.json(value, { status, headers }); }
