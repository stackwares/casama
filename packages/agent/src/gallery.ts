/**
 * The gallery for bots (D-315): what a bot can find there, how it ranks, and the cheap check for
 * a request the person keeps repeating. The server hands the catalog in (`GalleryCatalog`), with
 * the workspace's gallery policy already applied; nothing here reads the network.
 */

/** Gallery kinds a bot can search and suggest. Starter sets are added from the app. */
export const GALLERY_AGENT_KINDS = [
  "skill",
  "app",
  "routine",
  "bot",
  "plugin",
  "theme",
  "scheme",
  "wallpaper",
] as const;
export type GalleryAgentKind = (typeof GALLERY_AGENT_KINDS)[number];

/** Looks: device-side items a bot suggests but never installs for the person. */
export const GALLERY_LOOK_KINDS: readonly GalleryAgentKind[] = ["theme", "scheme", "wallpaper"];

/** What an item can touch, in plain words (the catalog's `access` field). */
export interface GalleryEntryAccess {
  reads?: string[];
  writes?: string[];
  runs_code?: boolean;
  computer?: boolean;
  credits?: "none" | "low" | "medium" | "high";
}

/** One gallery item as a bot sees it. */
export interface GalleryEntry {
  type: GalleryAgentKind;
  id: string;
  name: string;
  description?: string;
  /** A Lucide icon name, when the item has one. */
  icon?: string;
  tags?: string[];
  category?: string;
  featured?: boolean;
  retired?: boolean;
  access?: GalleryEntryAccess;
  needs?: { apps?: string[]; skills?: string[] };
  /** The workspace's gallery policy blocks it: never shown or suggested. */
  blocked?: boolean;
}

/** The gallery, from the server (D-315). */
export interface GalleryCatalog {
  /**
   * Every item of every kind for this workspace. The server applies the workspace's gallery
   * policy: blocked items are left out or marked `blocked`.
   */
  items(orgId: string): Promise<GalleryEntry[]>;
  /** `<type>/<id>` keys installed in the workspace, beyond what the agent finds itself (optional). */
  installed?(orgId: string): Promise<string[]>;
  /** The gallery's search words (D-372); the built-in list when absent or empty. */
  searchWords?(): Promise<Record<string, string[]> | undefined>;
}

/** Chat message part types the gallery tools add to the reply (D-315). */
export const GALLERY_SUGGESTION_PART = "gallery_suggestion";
export const GALLERY_DRAFT_PART = "gallery_draft";
/** The run event that carries one of those parts until the reply is saved. */
export const GALLERY_SHOWN_EVENT = "gallery.shown";

/**
 * A few short words people use for the same thing. The fallback for the gallery's search-words
 * list (D-372), which the app and the MCP server read too.
 */
const SYNONYMS: Record<string, string[]> = {
  mail: ["email", "gmail", "outlook", "inbox"],
  email: ["mail", "gmail", "outlook", "inbox"],
  inbox: ["email", "mail"],
  cal: ["calendar"],
  calendar: ["schedule", "meeting", "event"],
  meeting: ["calendar"],
  todo: ["task", "tasks"],
  task: ["todo"],
  note: ["notes", "notion"],
  doc: ["document", "docs", "writing"],
  write: ["writing"],
  blog: ["writing", "article"],
  money: ["finance", "budget", "bill", "expense"],
  bill: ["money", "finance"],
  budget: ["money", "finance"],
  news: ["digest", "brief"],
  digest: ["brief", "summary", "news"],
  brief: ["digest", "summary"],
  summary: ["digest", "summarize"],
  summarize: ["summary", "digest"],
  dark: ["night", "black"],
  look: ["theme", "scheme", "wallpaper"],
  theme: ["look", "scheme"],
  color: ["scheme", "colour"],
  colour: ["scheme", "color"],
  wallpaper: ["background", "pattern"],
  background: ["wallpaper"],
  code: ["github", "developer", "coding"],
  github: ["code", "git"],
  chat: ["slack", "message"],
  workout: ["fitness", "health", "exercise"],
  fitness: ["workout", "health"],
  travel: ["trip", "flight"],
  trip: ["travel"],
  recipe: ["cooking", "meal", "food"],
  meal: ["recipe", "food"],
};

const STOP = new Set(
  "a an and are as at be but by can could do does for from get give has have help how i if in into is it its just let me my need no not of on or our out please so some something that the their them then there these this to up us want was we what when where which who why will with would you your make made show find add new set".split(
    " ",
  ),
);

/** Lowercase word stems, without stop words. */
export function galleryTokens(text: string): string[] {
  return (text.toLowerCase().match(/[a-z0-9][a-z0-9'-]*/g) ?? [])
    .map((t) =>
      t
        .replace(/'s$/, "")
        .replace(/(ing|ed|es|s)$/, (m, _g, _i, w) => (w.length - m.length >= 4 ? "" : m)),
    )
    .filter((t) => t.length > 1 && !STOP.has(t));
}

/**
 * The best matches for a query: names count most, then tags and category, then the description.
 * Retired and blocked items never match. Featured items win ties.
 */
export function searchGallery(
  items: GalleryEntry[],
  query: string,
  opts: {
    types?: readonly string[];
    limit?: number;
    /** The gallery's search words (D-372); the built-in list when absent. */
    synonyms?: Record<string, string[]>;
  } = {},
): GalleryEntry[] {
  const words = [...new Set(galleryTokens(query))];
  const expanded = new Map<string, number>();
  for (const w of words) {
    expanded.set(w, Math.max(expanded.get(w) ?? 0, 1));
    for (const s of (opts.synonyms ?? SYNONYMS)[w] ?? [])
      for (const t of galleryTokens(s)) expanded.set(t, Math.max(expanded.get(t) ?? 0, 0.5));
  }
  const types = opts.types?.length ? new Set(opts.types) : null;
  const scored: Array<{ item: GalleryEntry; score: number }> = [];
  for (const item of items) {
    if (item.retired || item.blocked) continue;
    if (types && !types.has(item.type)) continue;
    const name = new Set(galleryTokens(`${item.name} ${item.id.replaceAll("-", " ")}`));
    const tags = new Set(galleryTokens([...(item.tags ?? []), item.category ?? ""].join(" ")));
    const desc = new Set(galleryTokens(item.description ?? ""));
    let score = 0;
    let hits = 0;
    for (const [t, weight] of expanded) {
      const s = (name.has(t) ? 3 : 0) + (tags.has(t) ? 2 : 0) + (desc.has(t) ? 1 : 0);
      if (s > 0) hits += weight === 1 ? 1 : 0;
      score += s * weight;
    }
    // A query of type words only ("a theme") still lists that kind.
    if (!words.length && types) score = 0.1;
    if (score <= 0) continue;
    // More of the person's own words matched beats one strong synonym.
    score += hits * 0.5 + (item.featured ? 0.25 : 0);
    scored.push({ item, score });
  }
  return scored
    .sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name))
    .slice(0, opts.limit ?? 5)
    .map((s) => s.item);
}

/** The card's item: what the app needs to draw it, nothing more. */
export function suggestionItem(e: GalleryEntry) {
  return {
    type: e.type,
    id: e.id,
    name: e.name,
    description: e.description ?? "",
    ...(e.icon ? { icon: e.icon } : {}),
    ...(e.access ? { access: e.access } : {}),
    ...(e.needs && (e.needs.apps?.length || e.needs.skills?.length) ? { needs: e.needs } : {}),
  };
}

// ---------------------------------------------------------------- repeated requests

/** One earlier message from the person, with when they sent it. */
export interface DatedRequest {
  text: string;
  at: Date;
}

/** Calendar day in the person's timezone. */
function dayOf(at: Date, timezone: string) {
  try {
    return new Intl.DateTimeFormat("en-CA", { timeZone: timezone }).format(at);
  } catch {
    return at.toISOString().slice(0, 10);
  }
}

/** Words that say what kind of request it is ("summarize unread email" → summarize, unread, email). */
function requestWords(text: string) {
  return new Set(galleryTokens(text.slice(0, 400)).filter((t) => !/^\d+$/.test(t)));
}

/**
 * When the person asked for the same kind of thing on at least `days` different days (the current
 * message among them), a short note for the system prompt suggesting a routine. Word overlap only:
 * no model call. Short messages ("thanks", "ok") never count.
 */
export function repeatedRequestHint(
  current: DatedRequest,
  earlier: DatedRequest[],
  opts: { timezone?: string; days?: number } = {},
): string | null {
  const tz = opts.timezone ?? "UTC";
  const need = opts.days ?? 3;
  const mine = requestWords(current.text);
  if (mine.size < 2) return null;
  const today = dayOf(current.at, tz);
  const days = new Map<string, string>();
  for (const m of earlier) {
    const day = dayOf(m.at, tz);
    if (day === today || days.has(day)) continue;
    const theirs = requestWords(m.text);
    if (theirs.size < 2) continue;
    let shared = 0;
    for (const t of mine) if (theirs.has(t)) shared++;
    const overlap = shared / Math.min(mine.size, theirs.size);
    if (shared >= 2 && overlap >= 0.6) days.set(day, m.text.replace(/\s+/g, " ").slice(0, 80));
  }
  if (days.size + 1 < need) return null;
  const dates = [...days.keys()].sort().slice(-4);
  return `The person has asked for something like this on ${days.size + 1} different days (before today: ${dates.join(", ")}). After helping, if a routine would save them asking again, look for one with gallery.search (types ["routine"]) and offer the best match with gallery.suggest, or offer to set one up with routines.create. Offer once; don't push.`;
}
