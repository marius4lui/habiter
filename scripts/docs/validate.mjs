#!/usr/bin/env node
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execute = promisify(execFile);
const root = new URL("../../", import.meta.url);
const rootPath = fileURLToPath(root);

const { stdout } = await execute(
  "git",
  [
    "ls-files",
    "--cached",
    "--others",
    "--exclude-standard",
    "*.md",
    "*.mdx",
  ],
  { cwd: rootPath },
);
const markdownFiles = stdout.trim().split("\n").filter(Boolean);
assert.ok(markdownFiles.length > 0, "No tracked Markdown files were found.");

const forbiddenPathPatterns = [
  {
    pattern: /\/(?:home|Users)\/[^/\s`]+\//,
    label: "user-specific Unix path",
  },
  {
    pattern: /[A-Za-z]:\\Users\\[^\\\s`]+\\/,
    label: "user-specific Windows path",
  },
  {
    pattern: /file:\/\//,
    label: "local file URL",
  },
];

for (const file of markdownFiles) {
  const contents = await readFile(new URL(file, root), "utf8");
  for (const { pattern, label } of forbiddenPathPatterns) {
    assert.doesNotMatch(contents, pattern, `${file} contains a ${label}`);
  }
}

const obsoletePlanReferences = markdownFiles.filter((file) =>
  file.startsWith("docs/plans/"),
);
assert.deepEqual(
  obsoletePlanReferences,
  [],
  "Published execution plans and handoff ledgers do not belong in docs/plans.",
);

const openApi = JSON.parse(
  await readFile(new URL("docs/public/release-api.openapi.json", root), "utf8"),
);
assert.equal(openApi.openapi, "3.1.0");

const expectedPaths = [
  "/",
  "/api/v1/download/{platform}",
  "/api/v1/download/{platform}/{architecture}",
  "/api/v1/manifest",
  "/api/v1/releases",
  "/api/v1/releases/latest",
  "/api/v1/releases/{version}",
  "/api/v1/releases/{version}/downloads",
  "/api/v1/update/{platform}",
  "/download",
  "/health",
].sort();
assert.deepEqual(
  Object.keys(openApi.paths).sort(),
  expectedPaths,
  "The OpenAPI path inventory must match the public Release API.",
);

const operationIds = [];
for (const pathItem of Object.values(openApi.paths)) {
  for (const method of ["get", "post", "put", "patch", "delete"]) {
    if (pathItem[method]?.operationId) operationIds.push(pathItem[method].operationId);
  }
}
assert.equal(
  new Set(operationIds).size,
  operationIds.length,
  "OpenAPI operationId values must be unique.",
);

function resolveReference(document, reference) {
  assert.match(reference, /^#\//, `Only local OpenAPI references are allowed: ${reference}`);
  return reference
    .slice(2)
    .split("/")
    .map((part) => part.replaceAll("~1", "/").replaceAll("~0", "~"))
    .reduce((value, part) => value?.[part], document);
}

function validateReferences(document, value) {
  if (Array.isArray(value)) {
    for (const item of value) validateReferences(document, item);
    return;
  }
  if (value === null || typeof value !== "object") return;
  if (typeof value.$ref === "string") {
    assert.ok(
      resolveReference(document, value.$ref),
      `Unresolved local reference: ${value.$ref}`,
    );
  }
  for (const nested of Object.values(value)) validateReferences(document, nested);
}

validateReferences(openApi, openApi);
assert.deepEqual(
  openApi.components.schemas.ApiError.required,
  ["code", "message", "requestId"],
  "Every documented API error must include its request ID.",
);

const apiReference = await readFile(
  new URL("docs/api/release-api.md", root),
  "utf8",
);
for (const path of expectedPaths) {
  assert.ok(
    apiReference.includes(path),
    `The human-readable Release API reference is missing ${path}.`,
  );
}

const classlyOpenApi = JSON.parse(
  await readFile(
    new URL("docs/public/classly-compatible.openapi.json", root),
    "utf8",
  ),
);
assert.equal(classlyOpenApi.openapi, "3.1.0");
const expectedClasslyPaths = [
  "/api/events",
  "/api/oauth/authorize",
  "/api/oauth/token",
].sort();
assert.deepEqual(
  Object.keys(classlyOpenApi.paths).sort(),
  expectedClasslyPaths,
  "The Classly compatibility contract must expose only routes Habiter consumes.",
);
validateReferences(classlyOpenApi, classlyOpenApi);

const classlyReference = await readFile(
  new URL("docs/api/classly-compatible.md", root),
  "utf8",
);
for (const path of expectedClasslyPaths) {
  assert.ok(
    classlyReference.includes(path),
    `The human-readable Classly reference is missing ${path}.`,
  );
}

const backupSchema = JSON.parse(
  await readFile(new URL("docs/public/habiter-backup.schema.json", root), "utf8"),
);
assert.equal(backupSchema.$schema, "https://json-schema.org/draft/2020-12/schema");
assert.equal(backupSchema.properties.schemaVersion.const, 1);
assert.deepEqual(
  backupSchema.required,
  ["schemaVersion", "exportedAt", "habits", "entries", "settings"],
  "The backup schema must describe every top-level exporter field.",
);
validateReferences(backupSchema, backupSchema);

const backupReference = await readFile(
  new URL("docs/api/backup-format.md", root),
  "utf8",
);
for (const field of backupSchema.required) {
  assert.ok(
    backupReference.includes(`\`${field}\``),
    `The human-readable backup reference is missing ${field}.`,
  );
}

const vitePressConfig = await readFile(
  new URL("docs/.vitepress/config.mts", root),
  "utf8",
);
for (const link of [
  "/api/release-api",
  "/api/release-manifest",
  "/api/classly-compatible",
  "/api/backup-format",
  "/dev/platform-contracts",
  "/dev/testing",
  "/dev/agent-workflows/issue-trigger",
  "/guide/data-and-privacy",
  "/guide/reminders",
  "/guide/updates",
]) {
  assert.ok(vitePressConfig.includes(link), `VitePress navigation is missing ${link}.`);
}

const agentInstructions = await readFile(new URL("AGENTS.md", root), "utf8");
assert.match(
  agentInstructions,
  /!issue[\s\S]*issue-trigger contract/,
  "AGENTS.md must route !issue commands to the issue-trigger contract.",
);

const issueTrigger = await readFile(
  new URL("docs/dev/agent-workflows/issue-trigger.md", root),
  "utf8",
);
for (const requiredRule of [
  "--workspace=auto|worktree|repo",
  "--goal=auto|on|off",
  "--mode=implement|plan",
  "--deliver=none|push|pr",
  "Fail-closed conditions",
]) {
  assert.ok(
    issueTrigger.includes(requiredRule),
    `The issue-trigger contract is missing ${requiredRule}.`,
  );
}

const checklists = await readFile(
  new URL("docs/dev/agent-workflows/checklists.md", root),
  "utf8",
);
assert.match(
  checklists,
  /## `!issue` trigger/,
  "Execution checklists must include the !issue trigger.",
);

const readme = await readFile(new URL("README.md", root), "utf8");
assert.doesNotMatch(
  readme,
  /img\.shields\.io\/badge\/version-[0-9]/,
  "README release badges must not hard-code an application version.",
);

console.log(
  `Documentation contract is valid (${markdownFiles.length} Markdown files, ${expectedPaths.length} Release API paths, ${expectedClasslyPaths.length} integration paths).`,
);
