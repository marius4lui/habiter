import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const source = resolve(root, "src");
const output = resolve(root, "dist");
const production = process.argv.includes("--production");
if (process.argv.length !== (production ? 3 : 2)) fail("Usage: node scripts/build.mjs [--production]");

const appleAppId = process.env.HABITER_APPLE_APP_ID;
if (appleAppId && !/^[A-Z0-9]{10}\.[A-Za-z0-9.-]+$/.test(appleAppId)) fail("HABITER_APPLE_APP_ID must be a 10-character Team ID plus bundle ID.");
if (appleAppId) {
  const bundleId = appleAppId.slice(11);
  const xcodeProject = await readFile(resolve(root, "../habiter/ios/Runner.xcodeproj/project.pbxproj"), "utf8");
  const bundleDeclaration = `PRODUCT_BUNDLE_IDENTIFIER = ${bundleId};`;
  if (xcodeProject.split(bundleDeclaration).length - 1 !== 3) fail("HABITER_APPLE_APP_ID must match every Runner build configuration.");
}

await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(source, output, { recursive: true });
const templatePath = resolve(output, ".well-known/apple-app-site-association.template");
const targetPath = resolve(output, ".well-known/apple-app-site-association");
if (appleAppId) {
  const template = await readFile(templatePath, "utf8");
  await writeFile(targetPath, template.replaceAll("__APPLE_APP_ID__", appleAppId), "utf8");
}
await rm(templatePath);
console.log(`Built stateless mobile handoff${production ? " for production" : ""}${appleAppId ? " with Apple association" : " (Android-only)"}.`);

function fail(message) {
  console.error(message);
  process.exit(2);
}
