/**
 * Server addresses and sign-in links. A sign-in link is what "Sign In on Another Device" shows in
 * any Casama app: `https://casama.ai/pair#v=1&s=<server>&c=<code>`. The code sits after "#", so
 * it never reaches the page the link points at.
 */

export const CLOUD_API = "https://api.casama.ai";
export const CLOUD_APP = "https://app.casama.ai";

export class InputError extends Error {}

/** Whether plain http is fine for [host]: this computer or a private network. */
function localHost(host: string): boolean {
  const h = host.replace(/^\[|\]$/g, "").toLowerCase();
  return (
    h === "localhost" ||
    h.endsWith(".localhost") ||
    h.endsWith(".local") ||
    h === "::1" ||
    /^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(h)
  );
}

/**
 * Turns what a person typed into a server's API address: adds https:// when there's no scheme,
 * drops a trailing slash, query and fragment. Plain http only for this computer or a private
 * network.
 */
export function normalizeServer(input: string): string {
  const raw = input.trim();
  if (!raw) throw new InputError("Enter the server's address.");
  let url: URL;
  try {
    url = new URL(/^[a-z][a-z0-9+.-]*:\/\//i.test(raw) ? raw : `https://${raw}`);
  } catch {
    throw new InputError("That isn't a web address.");
  }
  if (url.protocol !== "https:" && url.protocol !== "http:")
    throw new InputError("The address must start with https://.");
  if (url.protocol === "http:" && !localHost(url.hostname))
    throw new InputError("Use https:// for a server on the internet.");
  if (url.username || url.password) throw new InputError("Leave the user name out of the address.");
  const path = url.pathname.replace(/\/+$/, "");
  return `${url.protocol}//${url.host}${path}`;
}

/** The host to show for a server: "Casama Cloud" for Casama's own. */
export function serverLabel(server: string): string {
  if (server === CLOUD_API) return "Casama Cloud";
  try {
    return new URL(server).host;
  } catch {
    return server;
  }
}

/** The origin pattern Chrome's permissions use for [url]. */
export function originPattern(url: string): string {
  const u = new URL(url);
  return `${u.protocol}//${u.hostname}/*`;
}

const CODE = /^ksc_[A-Za-z0-9_-]{20,200}$/;

export interface SignInLink {
  /** The server the code is for; absent when only a bare code was pasted. */
  server?: string;
  code: string;
}

/**
 * Reads a pasted sign-in link, or a bare code. Takes the parameters from the fragment (or, for a
 * link someone retyped, the query).
 */
export function parseSignInLink(input: string): SignInLink {
  const raw = input.trim();
  if (CODE.test(raw)) return { code: raw };
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new InputError("Paste the whole sign-in link, or the code that starts with ksc_.");
  }
  const params = new URLSearchParams(url.hash.replace(/^#/, "") || url.search.replace(/^\?/, ""));
  const code = params.get("c") ?? "";
  const server = params.get("s") ?? "";
  if (!CODE.test(code) || !server)
    throw new InputError("That link isn't a Casama sign-in link. Show a new one in the app.");
  return { server: normalizeServer(server), code };
}
