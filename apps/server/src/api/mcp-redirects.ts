// Rules for apps that register themselves for the hosted MCP endpoint (open dynamic client
// registration, as MCP clients like Claude and ChatGPT expect). Registering grants nothing: a
// token still needs PKCE, an exact redirect match and a signed-in member's consent. These rules
// keep that consent honest: no odd redirect schemes, no apps posing as a well-known one, and a
// "known app" flag the consent screen uses to warn about everything else (security report
// 2026-11-20).

/** Schemes that are never a place to send an authorization code. */
const BLOCKED_SCHEMES = new Set([
  "http", // allowed only to the loopback addresses, below
  "javascript",
  "data",
  "vbscript",
  "file",
  "blob",
  "filesystem",
  "about",
  "view-source",
  "ftp",
  "ws",
  "wss",
  "intent",
  "mailto",
  "tel",
  "sms",
]);

const LOOPBACK = new Set(["localhost", "127.0.0.1", "[::1]"]);

/** Hosts of the AI apps people connect most, matched with their subdomains. */
const KNOWN_HOSTS = [
  "claude.ai",
  "claude.com",
  "anthropic.com",
  "chatgpt.com",
  "openai.com",
  "vscode.dev",
  "github.com",
  "cursor.com",
  "cursor.sh",
  "windsurf.com",
  "codeium.com",
  "zed.dev",
  "gemini.google.com",
  "perplexity.ai",
  "mistral.ai",
  "le-chat.mistral.ai",
];

/** Desktop apps' own schemes: a code sent there stays on the person's device. */
const KNOWN_SCHEMES = new Set([
  "cursor",
  "vscode",
  "vscode-insiders",
  "windsurf",
  "zed",
  "claude",
  "chatgpt",
]);

/** Names that only the real app may use: a client called "Claude" must send people to Claude. */
const RESERVED_NAME =
  /\b(claude|anthropic|chat\s*gpt|openai|cursor|casama|kasama|gemini|copilot|windsurf|codeium|perplexity|mistral)\b/i;

/** Null when [uri] is acceptable as a redirect, else why not. */
export function redirectProblem(uri: string): string | null {
  let u: URL;
  try {
    u = new URL(uri);
  } catch {
    return "isn't a valid address";
  }
  const scheme = u.protocol.replace(/:$/, "").toLowerCase();
  if (u.username || u.password) return "mustn't carry a user name or password";
  if (u.hash) return "mustn't have a #fragment";
  if (scheme === "https") return u.hostname ? null : "needs a host";
  if (scheme === "http") return LOOPBACK.has(u.hostname) ? null : "http is only for localhost";
  if (BLOCKED_SCHEMES.has(scheme)) return `the ${scheme}: scheme isn't allowed`;
  // An app's own scheme (cursor://, com.example.app:/cb).
  return /^[a-z][a-z0-9+.-]*$/.test(scheme) ? null : "has an invalid scheme";
}

/** True when a code sent to [uri] lands with a well-known app or stays on the person's device. */
export function isKnownRedirect(uri: string): boolean {
  let u: URL;
  try {
    u = new URL(uri);
  } catch {
    return false;
  }
  const scheme = u.protocol.replace(/:$/, "").toLowerCase();
  if (scheme === "http") return LOOPBACK.has(u.hostname);
  if (scheme === "https") {
    const host = u.hostname.toLowerCase();
    return LOOPBACK.has(host) || KNOWN_HOSTS.some((h) => host === h || host.endsWith(`.${h}`));
  }
  return KNOWN_SCHEMES.has(scheme);
}

/** True when [name] claims a well-known app but its redirects aren't all that kind of place. */
export function impersonatesKnownApp(name: string, uris: string[]): boolean {
  return RESERVED_NAME.test(name) && !uris.every(isKnownRedirect);
}
