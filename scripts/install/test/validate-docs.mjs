#!/usr/bin/env node
import { access, readFile } from "node:fs/promises";

const required = [
  "docs/install/README.md",
  "docs/install/linux/README.md",
  "docs/install/linux/ubuntu.md",
  "docs/install/linux/debian.md",
  "docs/install/linux/fedora.md",
  "docs/install/linux/arch.md",
  "docs/install/linux/opensuse.md",
  "docs/install/linux/generic.md",
  "docs/install/windows.md",
  "docs/install/macos.md"
];
await Promise.all(required.map((file) => access(file)));
const chooser = await readFile("docs/install/linux/README.md", "utf8");
for (const distro of ["ubuntu", "debian", "fedora", "arch", "opensuse", "generic"]) {
  if (!chooser.includes(`./${distro}.md`) && !chooser.includes(`/${distro}`)) {
    throw new Error(`Linux installation chooser does not link ${distro}`);
  }
}
for (const file of required) {
  const text = await readFile(file, "utf8");
  if (/Habiter-\d+\.\d+\.\d+|habiter-\d+\.\d+\.\d+/.test(text)) {
    throw new Error(`${file} contains a stale hard-coded release artifact version`);
  }
}
console.log(`Validated ${required.length} installation documentation pages.`);
