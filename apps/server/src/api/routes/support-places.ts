import {
  loadSupportPlaces,
  type PlacePlatform,
  type PlaceRole,
  type SupportPlaceDefinition,
} from "@casama/contracts";

export type ResolvedSupportPlace = {
  id: string;
  label: string;
  route?: string;
  url: string;
};

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const PLACE_LINK_RE = /\[([^\]\n]{1,120})\]\(place:([a-z0-9_]+)(?:\?([^)\s]+))?\)/g;
const RAW_CASAMA_LINK_RE = /\[([^\]\n]{1,120})\]\(casama:\/\/[^)\s]+\)/g;

/** Extracts the numeric build from `app_version` such as `"1.2.3 (45)"` or `"45"`. */
export function parseBuildNumber(appVersion?: string | null): number | null {
  if (!appVersion) return null;
  const trimmed = appVersion.trim();
  const paren = /\((\d+)\)/.exec(trimmed);
  if (paren?.[1]) return Number.parseInt(paren[1], 10);
  if (/^\d+$/.test(trimmed)) return Number.parseInt(trimmed, 10);
  return null;
}

/** Maps client platform strings (`"iOS"`, `"macOS"`, etc.) to catalog platform keys. */
export function normalizePlatform(platform?: string | null): PlacePlatform | null {
  if (!platform) return null;
  const p = platform.trim().toLowerCase();
  if (
    p === "ios" ||
    p === "android" ||
    p === "macos" ||
    p === "windows" ||
    p === "linux" ||
    p === "web"
  ) {
    return p;
  }
  return null;
}

/** Maps an organization role string to the catalog's role enum. */
export function normalizeRole(role?: string | null): PlaceRole | null {
  if (!role) return null;
  const r = role.trim().toLowerCase();
  if (r === "owner" || r === "admin" || r === "member") return r;
  return null;
}

export interface FilterPlacesOptions {
  publicOnly?: boolean;
  cloud: boolean;
  platform: PlacePlatform | null;
  build: number | null;
  role: PlaceRole | null;
}

/** Returns only the places that make sense for this surface, account, platform, and build. */
export function filterPlaces(opts: FilterPlacesOptions): SupportPlaceDefinition[] {
  return loadSupportPlaces().filter((p) => {
    if (opts.publicOnly && !p.public) return false;
    if (p.cloudOnly && !opts.cloud) return false;
    if (opts.platform && p.platforms?.length && !p.platforms.includes(opts.platform)) return false;
    if (p.minBuild != null && (opts.build == null || opts.build < p.minBuild)) return false;
    if (p.roles?.length && (!opts.role || !p.roles.includes(opts.role))) return false;
    return true;
  });
}

export function placesPromptSection(places: SupportPlaceDefinition[], mode: "app" | "web"): string {
  if (!places.length) return "";
  const lines = places.map((p) => {
    const extras = [
      p.params?.length ? `params: ${p.params.join(", ")}` : "",
      p.highlights?.length ? `highlights: ${p.highlights.join(", ")}` : "",
    ]
      .filter(Boolean)
      .join("; ");
    return `- \`${p.id}\` ("${p.label}"): ${p.description}${extras ? ` [${extras}]` : ""}`;
  });
  const intro =
    mode === "app"
      ? "Clickable places in the app (at most two per answer, only when pointing the person there helps):"
      : "Clickable places to open in the Casama app or store (at most two per answer, only when helpful):";
  return [
    intro,
    "- Write a place link in markdown as `[Label](place:id)` or `[Label](place:id?highlight=name)` (use the exact screen name as Label when natural).",
    mode === "app"
      ? "- For `bot_*` places, always pass `?botId=<id>` using the exact `id` returned by `get_bot`. Never guess a bot id."
      : "- Never invent place ids, params, highlights, or `casama://` URLs.",
    ...lines,
  ].join("\n");
}

function splitMarkdownCode(text: string): { code: boolean; text: string }[] {
  const parts: { code: boolean; text: string }[] = [];
  // Keep fenced code blocks and inline code spans intact so literal examples aren't rewritten.
  const re = /(```[\s\S]*?```|`[^`\n]+`)/g;
  let last = 0;
  for (const m of text.matchAll(re)) {
    const idx = m.index ?? 0;
    if (idx > last) parts.push({ code: false, text: text.slice(last, idx) });
    parts.push({ code: true, text: m[0] });
    last = idx + m[0].length;
  }
  if (last < text.length) parts.push({ code: false, text: text.slice(last) });
  return parts;
}

export interface LinkPlacesOptions {
  mode: "app" | "web";
  enabled: boolean;
  allowed: SupportPlaceDefinition[];
  verifiedBotIds?: Set<string>;
}

/**
 * Validates and rewrites `[label](place:<id>[?query])` links into `casama://app/...` (app),
 * `https://casama.ai/open/...` (web), or allowlisted external `https://...` URLs. Invalid or
 * disallowed links, as well as any raw `casama://` links, degrade to plain link labels.
 * Returns up to two deduplicated `places` chips in order of first appearance.
 */
export function linkPlaces(
  rawReply: string,
  opts: LinkPlacesOptions,
): { reply: string; places: ResolvedSupportPlace[] } {
  const byId = new Map(opts.allowed.map((p) => [p.id, p]));
  const chips: ResolvedSupportPlace[] = [];
  const seenUrls = new Set<string>();

  const segments = splitMarkdownCode(rawReply);
  const rewritten = segments
    .map((seg) => {
      if (seg.code) return seg.text;
      // Never pass through raw casama:// URLs written directly by the model.
      const withoutRaw = seg.text.replace(RAW_CASAMA_LINK_RE, (_m, label: string) => label);
      return withoutRaw.replace(
        PLACE_LINK_RE,
        (_full, label: string, id: string, rawQuery?: string) => {
          if (!opts.enabled) return label;
          const def = byId.get(id);
          if (!def) return label;

          const query = new URLSearchParams(rawQuery ?? "");
          for (const key of query.keys()) {
            const allowedParam = def.params?.includes(key) || key === "highlight";
            if (!allowedParam) return label;
          }

          let route = def.route;
          if (route) {
            for (const param of def.params ?? []) {
              const val = query.get(param)?.trim() ?? "";
              if (!val) return label;
              if (param === "botId") {
                if (!UUID_RE.test(val) || !opts.verifiedBotIds?.has(val)) return label;
              }
              route = route.replace(`{${param}}`, encodeURIComponent(val));
            }
            const hl = query.get("highlight")?.trim();
            if (hl && def.highlights?.includes(hl)) {
              route = `${route}?highlight=${encodeURIComponent(hl)}`;
            }
          }

          const url = def.url
            ? def.url
            : opts.mode === "web"
              ? `https://casama.ai/open${route}`
              : `casama://app${route}`;

          if (!seenUrls.has(url) && chips.length < 2) {
            seenUrls.add(url);
            chips.push({
              id: def.id,
              label: def.label,
              ...(opts.mode === "app" && route ? { route } : {}),
              url,
            });
          }

          return `[${label}](${url})`;
        },
      );
    })
    .join("");

  return { reply: rewritten, places: chips };
}
