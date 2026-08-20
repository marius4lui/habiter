import type { Platform } from "../types/releases";

const supported = new Set<Platform>(["android", "windows", "linux", "macos"]);
const architectures = new Map([
  ["x86_64", "x64"], ["amd64", "x64"], ["x64", "x64"],
  ["aarch64", "arm64"], ["arm64", "arm64"], ["universal", "universal"]
]);
const distroNames = new Set(["ubuntu", "debian", "fedora", "arch", "opensuse", "generic"]);

export function parsePlatform(value: string | null): Platform | null {
  const normalized = value?.toLowerCase() as Platform | undefined;
  return normalized && supported.has(normalized) ? normalized : null;
}

export function detectPlatform(userAgent: string): Platform | null {
  const value = userAgent.toLowerCase();
  if (value.includes("android")) return "android";
  if (value.includes("windows")) return "windows";
  if (value.includes("macintosh") || value.includes("mac os x")) return "macos";
  if (value.includes("linux")) return "linux";
  return null;
}

export function defaultArchitecture(platform: Platform): string {
  return platform === "android" || platform === "macos" ? "universal" : "x64";
}

export function parseArchitecture(value: string | null): string | null {
  return value ? architectures.get(value.toLowerCase()) ?? null : null;
}

export function parseDistro(value: string | null): string {
  if (!value) return "generic";
  const normalized = value.toLowerCase().replace(/_/g, "-");
  if (normalized.startsWith("opensuse") || normalized === "sles") return "opensuse";
  return distroNames.has(normalized) ? normalized : "generic";
}
