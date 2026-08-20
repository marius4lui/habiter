const sources = new Map([
  ["/install.sh", {
    url: "https://raw.githubusercontent.com/marius4lui/habiter/main/scripts/install/install.sh",
    contentType: "text/x-shellscript; charset=utf-8",
    marker: "#!/bin/sh"
  }],
  ["/install.ps1", {
    url: "https://raw.githubusercontent.com/marius4lui/habiter/main/scripts/install/install.ps1",
    contentType: "text/plain; charset=utf-8",
    marker: "# Habiter PowerShell installer"
  }]
]);

export type InstallerFetcher = (input: string, init?: RequestInit) => Promise<Response>;

export async function repositoryInstaller(pathname: string, request: Request, fetcher: InstallerFetcher): Promise<Response | null> {
  const source = sources.get(pathname);
  if (!source) return null;
  const upstream = await fetcher(source.url, {
    headers: {
      accept: "text/plain",
      ...(request.headers.get("if-none-match") ? { "if-none-match": request.headers.get("if-none-match")! } : {})
    },
    redirect: "error"
  });
  const headers = new Headers({
    "cache-control": "public, max-age=60, s-maxage=300",
    "content-type": source.contentType,
    "x-content-type-options": "nosniff",
    "x-habiter-installer-source": "repository"
  });
  const etag = upstream.headers.get("etag");
  if (etag) headers.set("etag", etag);
  if (upstream.status === 304) return new Response(null, { status: 304, headers });
  if (!upstream.ok) return new Response("Installer source is unavailable.\n", {
    status: 503,
    headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store", "x-content-type-options": "nosniff" }
  });
  const upstreamType = upstream.headers.get("content-type")?.toLowerCase() ?? "";
  const body = await upstream.text();
  if (upstreamType.includes("text/html") || !body.startsWith(source.marker)) {
    return new Response("Installer source failed validation.\n", {
      status: 502,
      headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store", "x-content-type-options": "nosniff" }
    });
  }
  return new Response(body, { headers });
}
