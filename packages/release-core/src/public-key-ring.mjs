/**
 * Parses the client key-ring environment value and enforces canonical raw
 * Ed25519 public keys plus the presence of the active signing key.
 */
export function parseRawPublicKeyRing(encoded, requiredKeyId) {
  let ring;
  try {
    ring = JSON.parse(encoded);
  } catch {
    throw new Error("Update public-key ring must be valid JSON");
  }
  if (!ring || Array.isArray(ring) || typeof ring !== "object" || Object.keys(ring).length === 0) {
    throw new Error("Update public-key ring must be a non-empty object");
  }
  for (const [keyId, value] of Object.entries(ring)) {
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]+$/.test(keyId)) {
      throw new Error(`Invalid update public-key id: ${keyId}`);
    }
    if (typeof value !== "string" || !/^[A-Za-z0-9_-]+$/.test(value)) {
      throw new Error(`Update public key ${keyId} must be unpadded Base64URL`);
    }
    const bytes = Buffer.from(value, "base64url");
    if (bytes.length !== 32 || bytes.toString("base64url") !== value) {
      throw new Error(`Update public key ${keyId} must contain exactly 32 canonical bytes`);
    }
  }
  if (requiredKeyId && !Object.hasOwn(ring, requiredKeyId)) {
    throw new Error(`Update public-key ring does not contain active key ${requiredKeyId}`);
  }
  return ring;
}
