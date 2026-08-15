import type { Platform } from "../types/releases";

const supported = new Set<Platform>(["android", "windows", "linux", "macos"]);

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
