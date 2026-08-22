import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { chmod, mkdir, readFile, rename, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import readline from "node:readline/promises";
import { stdin, stdout } from "node:process";
import { SyncAuth, derivePasswordKey, passwordKdfIterations } from "@habiter/sync-auth";
import { createSyncHttpHandler, type SyncHttpLogEvent } from "@habiter/sync-http";
import { SqliteSyncStorage } from "@habiter/sync-sqlite";

interface ServicePaths { dataDirectory: string; backupDirectory: string; database: string; instanceKey: string }

class ServiceError extends Error {
  constructor(readonly code: string, message: string, readonly exitCode = 1) { super(message); this.name = "ServiceError"; }
}

const command = process.argv[2] ?? "serve";

try {
  await run(command, process.argv.slice(3));
} catch (error) {
  const safe = publicError(error);
  process.stderr.write(`${JSON.stringify(safe)}\n`);
  process.exitCode = error instanceof ServiceError ? error.exitCode : 1;
}

async function run(name: string, args: string[]): Promise<void> {
  const paths = servicePaths();
  if (name === "serve") return serve(paths);
  if (name === "migrate") return migrate(paths);
  if (name === "setup") return setup(paths, args);
  if (name === "backup") return backup(paths, args);
  if (name === "verify") return verify(paths, args);
  if (name === "restore") return restore(paths, args);
  if (name === "rollback") return rollback(paths, args);
  if (name === "health") return health(args);
  if (name === "help" || name === "--help" || name === "-h") { stdout.write(helpText); return; }
  throw new ServiceError("unknown_command", "Unknown command. Run habiter-sync help.", 2);
}

async function serve(paths: ServicePaths): Promise<void> {
  await ensureDirectories(paths);
  const baseUrl = requiredUrl("HABITER_SYNC_BASE_URL");
  const redirectUris = csv("HABITER_SYNC_REDIRECT_URIS", true);
  const storage = new SqliteSyncStorage(paths.database);
  await chmod(paths.database, 0o600);
  const auth = new SyncAuth(storage, {
    issuer: baseUrl,
    audience: process.env.HABITER_SYNC_AUDIENCE?.trim() || "habiter-mobile",
    encryptionKey: await instanceKey(paths),
  });
  const maximumBodyBytes = boundedEnvironmentInteger("HABITER_SYNC_MAX_BODY_BYTES", 256 * 1024, 1024, 1024 * 1024);
  const handler = createSyncHttpHandler({
    storage,
    auth,
    config: {
      instanceName: process.env.HABITER_SYNC_INSTANCE_NAME?.trim() || "Habiter Personal Sync Beta",
      baseUrl,
      redirectUris,
      corsOrigins: csv("HABITER_SYNC_CORS_ORIGINS", false),
      maximumBodyBytes,
      log: accessLog,
    },
  });
  const port = boundedEnvironmentInteger("HABITER_SYNC_PORT", 8787, 1, 65535);
  const host = process.env.HABITER_SYNC_HOST?.trim() || "0.0.0.0";
  const server = createServer(async (incoming, outgoing) => {
    try {
      const body = await readIncoming(incoming, maximumBodyBytes);
      const requestBody = new Uint8Array(body.byteLength);
      requestBody.set(body);
      const request = new Request(`${baseUrl}${incoming.url ?? "/"}`, {
        method: incoming.method,
        headers: requestHeaders(incoming),
        ...(requestBody.byteLength === 0 ? {} : { body: requestBody }),
      });
      await writeResponse(outgoing, await handler(request));
    } catch (error) {
      const status = error instanceof ServiceError && error.code === "payload_too_large" ? 413 : 500;
      await writeResponse(outgoing, Response.json({ error: status === 413 ? "payload_too_large" : "internal_error", message: status === 413 ? "Request body is too large" : "Request failed" }, { status, headers: { "cache-control": "no-store", "content-security-policy": "default-src 'none'", "x-content-type-options": "nosniff" } }));
    }
  });
  server.requestTimeout = 15_000;
  server.headersTimeout = 10_000;
  server.keepAliveTimeout = 5_000;
  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, host, () => resolve());
  });
  stdout.write(`${JSON.stringify({ event: "ready", port, schemaVersion: storage.schemaVersion })}\n`);
  let stopping = false;
  const shutdown = (signal: string) => {
    if (stopping) return;
    stopping = true;
    stdout.write(`${JSON.stringify({ event: "shutdown", signal })}\n`);
    const deadline = setTimeout(() => { server.closeAllConnections(); }, 25_000);
    deadline.unref();
    server.close(() => {
      clearTimeout(deadline);
      storage.close();
      process.exitCode = 0;
    });
  };
  process.once("SIGTERM", () => shutdown("SIGTERM"));
  process.once("SIGINT", () => shutdown("SIGINT"));
}

async function migrate(paths: ServicePaths): Promise<void> {
  await ensureDirectories(paths);
  const storage = new SqliteSyncStorage(paths.database);
  await chmod(paths.database, 0o600);
  const schemaVersion = storage.schemaVersion;
  storage.close();
  stdout.write(`${JSON.stringify({ migrated: true, schemaVersion })}\n`);
}

async function setup(paths: ServicePaths, args: string[]): Promise<void> {
  rejectOption(args, "--password");
  const username = option(args, "--username") ?? await promptLine("Username: ");
  const passwordFromStdin = args.includes("--password-stdin");
  if (args.some((value) => value !== "--password-stdin" && value !== "--username" && value !== username)) throw new ServiceError("invalid_arguments", "Setup arguments are invalid.", 2);
  let password = passwordFromStdin ? await readStdinSecret() : await promptPasswordTwice();
  if (password.length < 12 || password.length > 1024) throw new ServiceError("invalid_password", "Password must contain between 12 and 1024 characters.", 2);
  await ensureDirectories(paths);
  const storage = new SqliteSyncStorage(paths.database);
  await chmod(paths.database, 0o600);
  try {
    const salt = randomBase64Url(16);
    const passwordKey = await derivePasswordKey(password, salt, passwordKdfIterations);
    password = "";
    const auth = new SyncAuth(storage, { issuer: setupIssuer(), audience: "habiter-mobile", encryptionKey: await instanceKey(paths) });
    await auth.setup({ username: username.trim(), passwordKey, salt, iterations: passwordKdfIterations });
    stdout.write(`${JSON.stringify({ initialized: true })}\n`);
  } finally { password = ""; storage.close(); }
}

async function backup(paths: ServicePaths, args: string[]): Promise<void> {
  await ensureDirectories(paths);
  const name = backupName(args[0] ?? `habiter-sync-${new Date().toISOString().replaceAll(/[:.]/g, "-")}.sqlite`);
  const destination = path.join(paths.backupDirectory, name);
  const storage = new SqliteSyncStorage(paths.database);
  await chmod(paths.database, 0o600);
  try {
    const manifest = await storage.backup(destination);
    await chmod(destination, 0o600);
    await writeFile(`${destination}.json`, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600 });
    stdout.write(`${JSON.stringify({ backup: name, manifest })}\n`);
  } finally { storage.close(); }
}

async function verify(paths: ServicePaths, args: string[]): Promise<void> {
  const name = backupName(requiredArgument(args[0], "backup name"));
  const manifest = await SqliteSyncStorage.verifyBackup(path.join(paths.backupDirectory, name), args[1]);
  stdout.write(`${JSON.stringify({ verified: true, backup: name, manifest })}\n`);
}

async function restore(paths: ServicePaths, args: string[]): Promise<void> {
  await ensureDirectories(paths);
  const name = backupName(requiredArgument(args[0], "backup name"));
  const result = await SqliteSyncStorage.restoreBackup(path.join(paths.backupDirectory, name), paths.database, args[1]);
  stdout.write(`${JSON.stringify({ restored: true, backup: name, rollback: result.rollbackPath === null ? null : path.basename(result.rollbackPath), manifest: result.manifest })}\n`);
}

async function rollback(paths: ServicePaths, args: string[]): Promise<void> {
  const name = requiredArgument(args[0], "rollback name");
  if (!/^sync\.sqlite\.rollback-\d+$/.test(name)) throw new ServiceError("invalid_rollback_name", "Rollback name is invalid.", 2);
  await SqliteSyncStorage.rollbackRestore(paths.database, path.join(paths.dataDirectory, name));
  stdout.write(`${JSON.stringify({ rolledBack: true, rollback: name })}\n`);
}

async function health(args: string[]): Promise<void> {
  const target = args[0] ?? "http://127.0.0.1:8787/v1/health";
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5_000);
  try {
    const response = await fetch(target, { signal: controller.signal });
    if (!response.ok) throw new ServiceError("health_failed", "Service health check failed.");
    const body = await response.json() as { status?: unknown };
    if (body.status !== "ok") throw new ServiceError("health_failed", "Service health check failed.");
    stdout.write(`${JSON.stringify({ healthy: true })}\n`);
  } finally { clearTimeout(timeout); }
}

function servicePaths(): ServicePaths {
  const dataDirectory = path.resolve(process.env.HABITER_SYNC_DATA_DIR?.trim() || "/var/lib/habiter-sync");
  const backupDirectory = path.resolve(process.env.HABITER_SYNC_BACKUP_DIR?.trim() || "/var/lib/habiter-sync-backups");
  return { dataDirectory, backupDirectory, database: path.join(dataDirectory, "sync.sqlite"), instanceKey: path.join(dataDirectory, "instance-key") };
}

async function ensureDirectories(paths: ServicePaths): Promise<void> {
  await mkdir(paths.dataDirectory, { recursive: true, mode: 0o700 });
  await mkdir(paths.backupDirectory, { recursive: true, mode: 0o700 });
  await chmod(paths.dataDirectory, 0o700);
  await chmod(paths.backupDirectory, 0o700);
}

async function instanceKey(paths: ServicePaths): Promise<Uint8Array> {
  try {
    const value = await readFile(paths.instanceKey);
    if (value.byteLength !== 32) throw new ServiceError("invalid_instance_key", "Instance key is invalid.");
    await chmod(paths.instanceKey, 0o600);
    return new Uint8Array(value);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    const value = crypto.getRandomValues(new Uint8Array(32));
    await writeFile(paths.instanceKey, value, { mode: 0o600, flag: "wx" });
    return value;
  }
}

function requiredUrl(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new ServiceError("missing_configuration", `${name} is required.`, 2);
  let url: URL;
  try { url = new URL(value); } catch { throw new ServiceError("invalid_configuration", `${name} is invalid.`, 2); }
  if (url.protocol !== "https:" && !(url.protocol === "http:" && ["localhost", "127.0.0.1", "::1"].includes(url.hostname))) throw new ServiceError("invalid_configuration", `${name} must use HTTPS.`, 2);
  if (url.username || url.password || url.hash || url.search || url.pathname !== "/") throw new ServiceError("invalid_configuration", `${name} must be an origin without a path.`, 2);
  return url.href.replace(/\/$/, "");
}

function csv(name: string, required: boolean): string[] {
  const values = (process.env[name] ?? "").split(",").map((value) => value.trim()).filter(Boolean);
  if (required && values.length === 0) throw new ServiceError("missing_configuration", `${name} is required.`, 2);
  return values;
}
function setupIssuer(): string { const value = process.env.HABITER_SYNC_BASE_URL?.trim(); return value ? requiredUrl("HABITER_SYNC_BASE_URL") : "http://localhost"; }
function boundedEnvironmentInteger(name: string, fallback: number, minimum: number, maximum: number): number { const raw = process.env[name]; if (raw === undefined) return fallback; const value = Number(raw); if (!Number.isSafeInteger(value) || value < minimum || value > maximum) throw new ServiceError("invalid_configuration", `${name} is invalid.`, 2); return value; }
function backupName(value: string): string { if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.sqlite$/.test(value)) throw new ServiceError("invalid_backup_name", "Backup name must be a safe .sqlite filename.", 2); return value; }
function requiredArgument(value: string | undefined, label: string): string { if (!value) throw new ServiceError("missing_argument", `${label} is required.`, 2); return value; }
function option(args: string[], name: string): string | undefined { const index = args.indexOf(name); return index < 0 ? undefined : args[index + 1]; }
function rejectOption(args: string[], name: string): void { if (args.includes(name) || args.some((value) => value.startsWith(`${name}=`))) throw new ServiceError("secret_argument_forbidden", "Passwords must never be passed as command arguments.", 2); }
function randomBase64Url(length: number): string { return Buffer.from(crypto.getRandomValues(new Uint8Array(length))).toString("base64url"); }

async function promptLine(label: string): Promise<string> { if (!stdin.isTTY) throw new ServiceError("interactive_terminal_required", "Use --username and --password-stdin for non-interactive setup.", 2); const terminal = readline.createInterface({ input: stdin, output: stdout }); try { return await terminal.question(label); } finally { terminal.close(); } }
async function promptPasswordTwice(): Promise<string> { if (!stdin.isTTY || typeof stdin.setRawMode !== "function") throw new ServiceError("interactive_terminal_required", "Use --password-stdin for non-interactive setup.", 2); const first = await promptSecret("Password: "); const second = await promptSecret("Confirm password: "); if (first !== second) throw new ServiceError("password_mismatch", "Passwords do not match.", 2); return first; }
async function promptSecret(label: string): Promise<string> {
  stdout.write(label); stdin.setRawMode!(true); stdin.resume(); stdin.setEncoding("utf8");
  return new Promise((resolve, reject) => {
    let value = "";
    const finish = () => { stdin.off("data", onData); stdin.setRawMode!(false); stdin.pause(); stdout.write("\n"); };
    const onData = (chunk: string) => {
      for (const character of chunk) {
        if (character === "\u0003") { finish(); reject(new ServiceError("setup_cancelled", "Setup cancelled.", 130)); return; }
        if (character === "\r" || character === "\n") { finish(); resolve(value); return; }
        if (character === "\u007f") { value = value.slice(0, -1); continue; }
        if (value.length < 1024 && character >= " ") value += character;
      }
    };
    stdin.on("data", onData);
  });
}
async function readStdinSecret(): Promise<string> { if (stdin.isTTY) throw new ServiceError("password_stdin_expected", "Pipe the password to standard input without a terminal.", 2); const chunks: Buffer[] = []; let size = 0; for await (const chunk of stdin) { const bytes = Buffer.from(chunk); size += bytes.length; if (size > 4096) throw new ServiceError("secret_input_too_large", "Password input is too large.", 2); chunks.push(bytes); } return Buffer.concat(chunks).toString("utf8").replace(/[\r\n]+$/, ""); }

async function readIncoming(request: IncomingMessage, maximum: number): Promise<Uint8Array> { const declared = Number(request.headers["content-length"]); if (Number.isFinite(declared) && declared > maximum) throw new ServiceError("payload_too_large", "Request body is too large."); const chunks: Buffer[] = []; let size = 0; for await (const chunk of request) { const value = Buffer.from(chunk); size += value.length; if (size > maximum) throw new ServiceError("payload_too_large", "Request body is too large."); chunks.push(value); } return Buffer.concat(chunks); }
function requestHeaders(request: IncomingMessage): Headers { const headers = new Headers(); for (const [name, value] of Object.entries(request.headers)) { if (Array.isArray(value)) for (const item of value) headers.append(name, item); else if (value !== undefined) headers.set(name, value); } return headers; }
async function writeResponse(output: ServerResponse, response: Response): Promise<void> { output.writeHead(response.status, Object.fromEntries(response.headers)); output.end(Buffer.from(await response.arrayBuffer())); }
function accessLog(event: SyncHttpLogEvent): void { stdout.write(`${JSON.stringify({ event: "request", ...event })}\n`); }
function publicError(error: unknown): { error: string; message: string } { return error instanceof ServiceError ? { error: error.code, message: error.message } : { error: "service_failed", message: "Service command failed." }; }

const helpText = `Habiter Personal Sync Beta\n\nCommands:\n  serve\n  migrate\n  setup [--username NAME] [--password-stdin]\n  backup [NAME.sqlite]\n  verify NAME.sqlite [SHA256]\n  restore NAME.sqlite [SHA256]\n  rollback sync.sqlite.rollback-TIMESTAMP\n  health [URL]\n`;
