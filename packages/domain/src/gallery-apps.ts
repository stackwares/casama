/**
 * Apps from the open gallery (D-239): a vendor's hosted MCP server anyone can propose by pull
 * request to the gallery repo, reviewed by a maintainer, and offered next to the built-in catalog
 * (apps.ts) without an app or server release. Pure checks: the gallery checker and the server
 * both run them, so an entry the checker let through is still refused by a server it can't fool.
 *
 * A gallery app is deliberately less powerful than a built-in one: no Google category (that shares
 * the server's Google client), no admin-registered OAuth client, no Composio routing, no inbox
 * scopes and no "popular" placement. Those stay in apps.ts, where a code review sees them.
 */
import type { AppApiKeyHelp, AppAuth, AppCategory, CatalogApp } from "./apps.ts";

export const GALLERY_APP_TYPE = "app" as const;

/** The entry's own text and data. Its logo stays the vendor's trademark. */
export const APP_LICENSES = ["CC0-1.0"] as const;

/** Every catalog category except google (D-166: Google's apps share the server's Google client). */
export const GALLERY_APP_CATEGORIES = [
  "developer",
  "productivity",
  "payments",
  "design",
  "sales",
  "data",
  "automation",
] as const satisfies readonly AppCategory[];

export const GALLERY_APP_AUTH = ["oauth", "api_key", "none"] as const satisfies readonly AppAuth[];

/** A logo is a single-color SVG mark (Simple Icons style) the app tints like its bundled ones. */
export const GALLERY_APP_LOGO_MAX_BYTES = 24 * 1024;

/** What app.json holds; the name, author and license are in item.json like every gallery item. */
export interface GalleryAppDocument {
  description: string;
  category: (typeof GALLERY_APP_CATEGORIES)[number];
  color: string;
  homepage: string;
  url: string;
  auth: (typeof GALLERY_APP_AUTH)[number][];
  oauthClient?: "dcr" | "cimd";
  scopes?: string[];
  apiKey?: AppApiKeyHelp;
  note?: string;
  capabilities: string[];
}

const COLOR = /^[0-9A-Fa-f]{6}$/;
const SCOPE = /^[\x21-\x7E]{1,200}$/;
const HEADER = /^[A-Za-z0-9-]{1,40}$/;
/** Headers a key must never replace: they'd change where or how the request goes. */
const RESERVED_HEADERS = new Set([
  "host",
  "cookie",
  "connection",
  "content-length",
  "content-type",
  "transfer-encoding",
  "accept",
  "mcp-session-id",
  "mcp-protocol-version",
]);

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function text(v: unknown, max: number): string | undefined {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length >= 1 && t.length <= max ? t : undefined;
}

/**
 * An https address on a public host name: no IP literals, no localhost, no internal suffixes, no
 * credentials and no non-default port. The server connects to it, so it must not reach inward.
 */
export function publicHttpsUrl(raw: unknown): string | undefined {
  if (typeof raw !== "string" || raw.length > 500) return undefined;
  let u: URL;
  try {
    u = new URL(raw);
  } catch {
    return undefined;
  }
  if (u.protocol !== "https:" || u.username || u.password || u.port) return undefined;
  const host = u.hostname.toLowerCase();
  if (!host.includes(".") || host.startsWith("[") || /^[\d.]+$/.test(host)) return undefined;
  if (
    host === "localhost" ||
    /\.(localhost|local|internal|lan|home|corp|test|invalid|example)$/.test(host)
  )
    return undefined;
  return raw;
}

/** Checks app.json. Returns the clean document when there are no errors. */
export function checkAppDocument(raw: unknown): { doc?: GalleryAppDocument; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["app.json must be an object"] };
  const allowed = new Set([
    "description",
    "category",
    "color",
    "homepage",
    "url",
    "auth",
    "oauthClient",
    "scopes",
    "apiKey",
    "note",
    "capabilities",
  ]);
  for (const key of Object.keys(raw))
    if (!allowed.has(key)) errors.push(`app.json can't have ${key}`);

  const description = text(raw.description, 140);
  if (!description) errors.push("description must be 1 to 140 characters");
  const category = GALLERY_APP_CATEGORIES.find((c) => c === raw.category);
  if (!category) errors.push(`category must be one of ${GALLERY_APP_CATEGORIES.join(", ")}`);
  const color = typeof raw.color === "string" && COLOR.test(raw.color) ? raw.color : undefined;
  if (!color) errors.push("color must be a hex color without # (for example 00C4CC)");
  const homepage = publicHttpsUrl(raw.homepage);
  if (!homepage) errors.push("homepage must be an https link on a public host");
  const url = publicHttpsUrl(raw.url);
  if (!url) errors.push("url must be the vendor's https MCP endpoint on a public host");

  const auth: GalleryAppDocument["auth"] = [];
  if (!Array.isArray(raw.auth) || raw.auth.length < 1)
    errors.push("auth must list how it connects");
  else
    for (const m of raw.auth) {
      const found = GALLERY_APP_AUTH.find((a) => a === m);
      if (!found) errors.push(`auth can only use ${GALLERY_APP_AUTH.join(", ")}`);
      else if (auth.includes(found)) errors.push(`auth lists ${found} twice`);
      else auth.push(found);
    }
  if (auth.includes("none") && auth.length > 1) errors.push('auth "none" can\'t be combined');

  let oauthClient: GalleryAppDocument["oauthClient"];
  if (auth.includes("oauth")) {
    if (raw.oauthClient === "dcr" || raw.oauthClient === "cimd") oauthClient = raw.oauthClient;
    else errors.push('with oauth, oauthClient must be "dcr" or "cimd"');
  } else if (raw.oauthClient !== undefined) errors.push("oauthClient is only for oauth");

  let scopes: string[] | undefined;
  if (raw.scopes !== undefined) {
    if (!auth.includes("oauth")) errors.push("scopes are only for oauth");
    else if (
      !Array.isArray(raw.scopes) ||
      raw.scopes.length > 30 ||
      !raw.scopes.every((s) => typeof s === "string" && SCOPE.test(s))
    )
      errors.push("scopes must be at most 30 scope names");
    else scopes = raw.scopes as string[];
  }

  let apiKey: AppApiKeyHelp | undefined;
  if (auth.includes("api_key")) {
    const k = isRecord(raw.apiKey) ? raw.apiKey : null;
    const label = k ? text(k.label, 40) : undefined;
    const keyUrl = k ? publicHttpsUrl(k.url) : undefined;
    const placeholder = k && k.placeholder !== undefined ? text(k.placeholder, 60) : undefined;
    const steps =
      k && Array.isArray(k.steps) && k.steps.length >= 1 && k.steps.length <= 6
        ? k.steps.map((s) => text(s, 160))
        : [];
    const header = k && k.header !== undefined ? k.header : undefined;
    if (!k) errors.push("with api_key, apiKey must say where to get one");
    else {
      for (const key of Object.keys(k))
        if (!["label", "placeholder", "url", "steps", "header"].includes(key))
          errors.push(`apiKey can't have ${key}`);
      if (!label) errors.push("apiKey.label must be 1 to 40 characters");
      if (!keyUrl) errors.push("apiKey.url must be an https link on a public host");
      if (k.placeholder !== undefined && !placeholder)
        errors.push("apiKey.placeholder must be 1 to 60 characters");
      if (!steps.length || steps.some((s) => !s))
        errors.push("apiKey.steps must be 1 to 6 lines of at most 160 characters");
      if (
        header !== undefined &&
        (typeof header !== "string" ||
          !HEADER.test(header) ||
          RESERVED_HEADERS.has(header.toLowerCase()))
      )
        errors.push("apiKey.header must be a header name such as X-Api-Key");
    }
    if (label && keyUrl && steps.length && steps.every(Boolean))
      apiKey = {
        label,
        url: keyUrl,
        steps: steps as string[],
        ...(placeholder ? { placeholder } : {}),
        ...(typeof header === "string" ? { header } : {}),
      };
  } else if (raw.apiKey !== undefined) errors.push("apiKey is only for api_key");

  const note = raw.note === undefined ? undefined : text(raw.note, 200);
  if (raw.note !== undefined && !note) errors.push("note must be 1 to 200 characters");
  const capabilities = Array.isArray(raw.capabilities)
    ? raw.capabilities.map((c) => text(c, 60))
    : [];
  if (capabilities.length < 1 || capabilities.length > 6 || capabilities.some((c) => !c))
    errors.push("capabilities must be 1 to 6 short phrases of at most 60 characters");

  if (errors.length) return { errors };
  return {
    errors,
    doc: {
      description: description as string,
      category: category as GalleryAppDocument["category"],
      color: (color as string).toUpperCase(),
      homepage: homepage as string,
      url: url as string,
      auth,
      ...(oauthClient ? { oauthClient } : {}),
      ...(scopes ? { scopes } : {}),
      ...(apiKey ? { apiKey } : {}),
      ...(note ? { note } : {}),
      capabilities: capabilities as string[],
    },
  };
}

/**
 * A logo the app can draw safely: one SVG, no scripts, styles, links, images or event handlers,
 * at most GALLERY_APP_LOGO_MAX_BYTES. The app tints it, so colors in it don't matter.
 */
export function checkAppLogo(svg: string, bytes: number): string[] {
  const errors: string[] = [];
  if (bytes > GALLERY_APP_LOGO_MAX_BYTES)
    errors.push(`logo.svg is over ${GALLERY_APP_LOGO_MAX_BYTES / 1024} KB`);
  if (!/^\s*(<\?xml[^>]*\?>\s*)?<svg[\s>]/.test(svg) || !/<\/svg>\s*$/.test(svg))
    errors.push("logo.svg must be one <svg> element");
  if (!/viewBox\s*=\s*"[\d.\s-]+"/.test(svg)) errors.push("logo.svg needs a viewBox");
  if (/<(script|style|foreignObject|image|use|a|iframe|object|embed)[\s>/]/i.test(svg))
    errors.push("logo.svg can't have scripts, styles, links, images or <use>");
  if (/\son[a-z]+\s*=/i.test(svg)) errors.push("logo.svg can't have event handlers");
  if (/(xlink:)?href\s*=|url\s*\(|javascript:|data:/i.test(svg))
    errors.push("logo.svg can't point at other files or URLs");
  if (/<!(DOCTYPE|ENTITY)/i.test(svg)) errors.push("logo.svg can't declare entities");
  return errors;
}

/** The catalog entry a gallery app becomes on a server. */
export function catalogAppFromGallery(
  id: string,
  name: string,
  raw: unknown,
): CatalogApp | undefined {
  const { doc } = checkAppDocument(raw);
  if (!doc) return undefined;
  return {
    id,
    name,
    description: doc.description,
    category: doc.category,
    color: doc.color,
    homepage: doc.homepage,
    url: doc.url,
    auth: doc.auth,
    ...(doc.oauthClient ? { oauthClient: doc.oauthClient } : {}),
    ...(doc.scopes ? { scopes: doc.scopes } : {}),
    ...(doc.apiKey ? { apiKey: doc.apiKey } : {}),
    ...(doc.note ? { note: doc.note } : {}),
    capabilities: doc.capabilities,
  };
}
