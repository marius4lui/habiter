#!/usr/bin/env node
import { parseRawPublicKeyRing } from "../../packages/release-core/src/public-key-ring.mjs";

const encoded = process.env.HABITER_UPDATE_PUBLIC_KEYS;
if (!encoded) throw new Error("HABITER_UPDATE_PUBLIC_KEYS is required");

const ring = parseRawPublicKeyRing(encoded, process.env.RELEASE_MANIFEST_KEY_ID);
console.log(`Validated ${Object.keys(ring).length} embedded update public key(s).`);
