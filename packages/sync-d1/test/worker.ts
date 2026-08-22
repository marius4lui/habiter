import { D1SyncStorage, d1Migrations, type D1DatabaseLike, type D1ExportFixture } from "../src/index";

interface Env { DB?: D1DatabaseLike }

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const body = await request.json() as { method: string; args?: unknown[]; fixture?: D1ExportFixture; migrate?: boolean; version?: number };
      if (body.method === "rawVersion") {
        await env.DB!.prepare("CREATE TABLE IF NOT EXISTS sync_schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL) STRICT").run();
        const result = await env.DB!.prepare("INSERT INTO sync_schema_migrations(version, name, applied_at) VALUES (?, 'test', '2026-08-22T00:00:00.000Z')").bind(body.version!).run();
        return Response.json({ result });
      }
      if (body.method === "sql") {
        const [sql, ...values] = body.args ?? [];
        const result = await env.DB!.prepare(String(sql)).bind(...values as never[]).all();
        return Response.json({ result });
      }
      if (body.method === "failingMigration") {
        await D1SyncStorage.open(env.DB, {
          migrate: true,
          migrations: [
            d1Migrations[0]!,
            {
              version: 2,
              name: "failing_migration",
              statements: ["CREATE TABLE should_rollback(value TEXT) STRICT", "INVALID SQL"],
            },
          ],
        });
      }
      if (body.method === "open") {
        const storage = await D1SyncStorage.open(env.DB, { migrate: body.migrate });
        return Response.json({ result: storage.schemaVersion });
      }
      if (body.method === "restore") {
        const storage = await D1SyncStorage.restoreFixture(env.DB, body.fixture!);
        const result = await storage.snapshot();
        return Response.json({ result });
      }
      const usage = { statements: 0, rowsRead: 0, rowsWritten: 0 };
      const storage = await D1SyncStorage.open(env.DB, {
        migrate: true,
        generation: "local-d1-generation",
        onUsage: (value) => {
          usage.statements += value.statements;
          usage.rowsRead += value.rowsRead;
          usage.rowsWritten += value.rowsWritten;
        },
      });
      const callable = storage as unknown as Record<string, (...args: unknown[]) => unknown>;
      const method = callable[body.method];
      if (typeof method !== "function") throw new Error(`Unknown method ${body.method}`);
      const result = await method.apply(storage, body.args ?? []);
      return Response.json({ result, usage });
    } catch (error) {
      const value = error as Error & { code?: string };
      return Response.json({ error: { code: value.code ?? "worker_error", message: value.message, cause: String(value.cause ?? "") } }, { status: 400 });
    }
  },
};
