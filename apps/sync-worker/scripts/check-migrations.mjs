import { readFile } from "node:fs/promises";

for (const name of ["0001_initial_sync_storage.sql", "0002_bounded_query_indexes.sql"]) {
  const local = await readFile(new URL(`../migrations/${name}`, import.meta.url), "utf8");
  const shared = await readFile(new URL(`../../../packages/sync-d1/migrations/${name}`, import.meta.url), "utf8");
  if (local !== shared) {
    console.error(`Worker migration ${name} differs from the shared D1 adapter migration.`);
    process.exit(1);
  }
}
console.log("Worker D1 migrations match the shared adapter.");
