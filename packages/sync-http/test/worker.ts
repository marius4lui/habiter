import { SyncAuth } from "@habiter/sync-auth";
import { D1SyncStorage, type D1DatabaseLike } from "@habiter/sync-d1";
import { createSyncHttpHandler } from "../src/index";

interface Env { DB: D1DatabaseLike }

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const storage = await D1SyncStorage.open(env.DB, { migrate: true, generation: "http-test-generation" });
    const auth = new SyncAuth(storage, {
      issuer: "https://sync.example.test",
      audience: "habiter-mobile",
      encryptionKey: new Uint8Array(32).fill(7),
    });
    if (new URL(request.url).pathname === "/_test/setup") {
      await auth.setup(await request.json());
      return new Response(null, { status: 204 });
    }
    return createSyncHttpHandler({
      storage,
      auth,
      config: {
        instanceName: "Test instance",
        baseUrl: "https://sync.example.test",
        redirectUris: ["https://app.habiter.dev/auth/callback"],
        corsOrigins: ["https://app.habiter.dev"],
      },
    })(request);
  },
};
