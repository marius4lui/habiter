export function json(data: unknown, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  headers.set("content-type", "application/json; charset=utf-8");
  return new Response(JSON.stringify(data), { ...init, headers });
}

export function apiError(requestId: string, status: number, code: string, message: string): Response {
  return json({ error: { code, message, requestId } }, { status });
}

export function withCache(response: Response, value: string): Response {
  const headers = new Headers(response.headers);
  headers.set("cache-control", value);
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}
