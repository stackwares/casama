/**
 * Which browser origins may call the API. The API takes bearer tokens, not cookies, so this keeps
 * other sites from reading responses in someone's browser rather than guarding sign-in itself.
 *
 * Allowed: the web app's address, CORS_ORIGINS, and Casama for Chrome (D-323) by its extension id
 * (Chrome's and Edge's store ids both go in CHROME_EXTENSION_IDS). Outside production also
 * localhost and any extension, so a dev build or a fresh unpacked copy works against a local server.
 *
 * Casama for Firefox (Phase 5) can't be listed by id: Firefox gives every install its own random
 * `moz-extension://<uuid>` origin. With FIREFOX_EXTENSIONS on (the default) any such origin is
 * allowed. That gives nothing away: every call still needs the person's bearer token, and no web
 * page can have a moz-extension origin.
 */
export interface CorsEnv {
  PUBLIC_APP_URL: string;
  CORS_ORIGINS: string;
  CHROME_EXTENSION_IDS: string;
  FIREFOX_EXTENSIONS?: boolean;
  NODE_ENV?: string;
}

const list = (v: string) =>
  v
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);

const FIREFOX_ORIGIN =
  /^moz-extension:\/\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** Returns a function giving the origin to echo back, or null to refuse. */
export function corsOrigins(env: CorsEnv): (origin: string | undefined) => string | null {
  const allowed = new Set([
    env.PUBLIC_APP_URL,
    ...list(env.CORS_ORIGINS),
    ...list(env.CHROME_EXTENSION_IDS)
      .filter((id) => /^[a-p]{32}$/.test(id))
      .map((id) => `chrome-extension://${id}`),
  ]);
  const dev = env.NODE_ENV !== "production";
  const firefox = env.FIREFOX_EXTENSIONS ?? true;
  return (origin) => {
    if (!origin) return null;
    if (allowed.has(origin)) return origin;
    if (firefox && FIREFOX_ORIGIN.test(origin)) return origin;
    if (dev && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) return origin;
    if (dev && /^chrome-extension:\/\/[a-p]{32}$/.test(origin)) return origin;
    return null;
  };
}
