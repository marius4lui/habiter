import { D1SyncStorage, type D1DatabaseLike } from "@habiter/sync-d1";
import { SyncAuth, benchmarkAuthenticationCrypto, redactAuthError } from "../src/index";

interface Env { DB: D1DatabaseLike }

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const body = await request.json() as { method: string; args: unknown[]; now: string };
      if (body.method === "cryptoBenchmark") return Response.json({ result: await benchmarkAuthenticationCrypto(new Uint8Array(32).fill(7)) });
      const storage = await D1SyncStorage.open(env.DB, { migrate: true, generation: "auth-test-generation" });
      const auth = new SyncAuth(storage, {
        issuer: "https://sync.example.test",
        audience: "habiter-mobile",
        encryptionKey: new Uint8Array(32).fill(7),
        now: () => new Date(body.now),
      });
      const callable = auth as unknown as Record<string, (...args: unknown[]) => unknown>;
      const method = callable[body.method];
      if (typeof method !== "function") throw new Error(`Unknown auth method ${body.method}`);
      return Response.json({ result: await method.apply(auth, body.args) });
    } catch (error) {
      const redacted = redactAuthError(error);
      return Response.json({ error: { code: redacted.error, message: redacted.message, status: redacted.status } }, { status: redacted.status });
    }
  },
};
