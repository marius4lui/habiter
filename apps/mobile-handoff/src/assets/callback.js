const callbackKeys = new Set(["code", "state"]);
const opaque = /^[A-Za-z0-9_-]+$/;

export function parseCallbackFragment(fragment) {
  if (typeof fragment !== "string" || !fragment.startsWith("#") || fragment.length > 1024) throw new Error("invalid_callback");
  const parameters = new URLSearchParams(fragment.slice(1));
  const entries = [...parameters.entries()];
  if (entries.length !== callbackKeys.size || entries.some(([key]) => !callbackKeys.has(key))) throw new Error("invalid_callback");
  for (const key of callbackKeys) if (parameters.getAll(key).length !== 1) throw new Error("invalid_callback");
  const code = parameters.get("code");
  const state = parameters.get("state");
  if (code === null || code.length < 32 || code.length > 512 || !opaque.test(code)) throw new Error("invalid_callback");
  if (state === null || state.length < 16 || state.length > 256 || !opaque.test(state)) throw new Error("invalid_callback");
  return { code, state };
}

export function customSchemeUrl(callback) {
  const fragment = new URLSearchParams(callback).toString();
  return `dev.habiter.app://auth/callback#${fragment}`;
}

function startHandoff() {
  const status = document.querySelector("#status");
  const open = document.querySelector("#open-habiter");
  let target = "";
  try {
    if (location.search !== "") throw new Error("invalid_callback");
    const callback = parseCallbackFragment(location.hash);
    history.replaceState(null, "", location.pathname);
    target = customSchemeUrl(callback);
    open.href = target;
    open.hidden = false;
    status.textContent = "Habiter should open automatically. If it does not, use the button below.";
    window.setTimeout(() => location.assign(target), 150);
    window.setTimeout(() => {
      open.removeAttribute("href");
      open.hidden = true;
      target = "";
      status.textContent = "This callback expired on the page. Return to Habiter and start again.";
    }, 60_000);
  } catch {
    history.replaceState(null, "", location.pathname);
    status.textContent = "This callback is missing, malformed, or expired. Return to Habiter and start again.";
  }
  window.addEventListener("pagehide", () => { target = ""; }, { once: true });
}

if (typeof window !== "undefined") startHandoff();
