const sources = new Map([
  ["/install.sh", {
    key: "install.sh",
    contentType: "text/x-shellscript; charset=utf-8",
    marker: "#!/bin/sh"
  }],
  ["/install.ps1", {
    key: "install.ps1",
    contentType: "text/plain; charset=utf-8",
    marker: "# Habiter PowerShell installer"
  }]
]);

export type InstallerBundle = Record<string, { body: string; etag: string }>;

export function repositoryInstaller(pathname: string, request: Request, bundle: InstallerBundle): Response | null {
  const source = sources.get(pathname);
  if (!source) return null;
  const installer = bundle[source.key];
  if (!installer) return new Response("Installer source is unavailable.\n", {
    status: 503,
    headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store", "x-content-type-options": "nosniff" }
  });
  const headers = new Headers({
    "cache-control": "public, max-age=60, s-maxage=300",
    "content-type": source.contentType,
    "x-content-type-options": "nosniff",
    "x-habiter-installer-source": "repository"
  });
  headers.set("etag", installer.etag);
  if (request.headers.get("if-none-match") === installer.etag) return new Response(null, { status: 304, headers });
  if (!installer.body.startsWith(source.marker)) {
    return new Response("Installer source failed validation.\n", {
      status: 502,
      headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store", "x-content-type-options": "nosniff" }
    });
  }
  return new Response(installer.body, { headers });
}
