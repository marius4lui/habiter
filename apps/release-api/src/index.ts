import manifest from "./generated/releases.json";
import { createHandler } from "./router";
import type { ReleaseManifest } from "./types/releases";

const handle = createHandler(manifest as ReleaseManifest);

export default {
  async fetch(request, env): Promise<Response> {
    try {
      return await handle(request, env);
    } catch (error) {
      console.error(JSON.stringify({ event: "unhandled_request_error", error: error instanceof Error ? error.message : "unknown" }));
      return new Response(JSON.stringify({ error: { code: "internal_error", message: "Internal server error" } }), {
        status: 500,
        headers: { "content-type": "application/json; charset=utf-8" }
      });
    }
  }
} satisfies ExportedHandler<Env>;
