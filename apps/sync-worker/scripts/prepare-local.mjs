import { writeFile } from "node:fs/promises";
import { randomBytes } from "node:crypto";

const target = new URL("../.dev.vars", import.meta.url);
const contents = `HABITER_SYNC_INSTANCE_KEY=${randomBytes(32).toString("base64url")}\nHABITER_SYNC_SETUP_TOKEN=${randomBytes(32).toString("base64url")}\n`;
try {
  await writeFile(target, contents, { encoding: "utf8", mode: 0o600, flag: "wx" });
  console.log("Created private local Worker secrets in .dev.vars.");
} catch (error) {
  if (error?.code === "EEXIST") {
    console.error(".dev.vars already exists; refusing to rotate local secrets implicitly.");
    process.exit(2);
  }
  throw error;
}
