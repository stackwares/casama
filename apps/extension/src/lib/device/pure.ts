/**
 * The browser as a device (D-323 E2–E6): the pure parts, shaped exactly like the server's strict
 * schemas (BrowserTabSummary, BrowserHistorySummary, ActivitySummary), so nothing else can go.
 */
import { siteMatches } from "../../../../../packages/domain/src/browser-guard.ts";
import type { PageContext } from "../context.ts";

export interface TabSummary {
  type: "tab";
  url: string;
  title: string;
  selection?: string;
  text?: string;
}

/** E2: what a tab read sends, capped like the server's schema. */
export function tabSummary(ctx: PageContext): TabSummary {
  return {
    type: "tab",
    url: (ctx.url ?? "").slice(0, 2000),
    title: (ctx.title ?? "").slice(0, 300),
    ...(ctx.selection ? { selection: ctx.selection.slice(0, 5000) } : {}),
    ...(ctx.text ? { text: ctx.text.slice(0, 20000) } : {}),
  };
}

export interface HistoryHit {
  url: string;
  title: string;
  source: "history" | "bookmark";
  visited_at?: string;
}

/**
 * E6: history and bookmark hits for a search, newest first, without pages the guard keeps out
 * ([blocked] says which), one per address, at most 50.
 */
export function historyItems(
  history: Array<{ url?: string; title?: string; lastVisitTime?: number }>,
  bookmarks: Array<{ url?: string; title?: string; dateAdded?: number }>,
  blocked: (url: string) => boolean,
): HistoryHit[] {
  const seen = new Set<string>();
  const out: HistoryHit[] = [];
  const all = [
    ...history.map((h) => ({ ...h, at: h.lastVisitTime, source: "history" as const })),
    ...bookmarks.map((b) => ({ ...b, at: b.dateAdded, source: "bookmark" as const })),
  ].sort((a, b) => (b.at ?? 0) - (a.at ?? 0));
  for (const h of all) {
    if (!h.url || !/^https?:/.test(h.url) || seen.has(h.url) || blocked(h.url)) continue;
    seen.add(h.url);
    out.push({
      url: h.url.slice(0, 2000),
      title: (h.title || h.url).slice(0, 300),
      source: h.source,
      ...(h.at ? { visited_at: new Date(h.at).toISOString() } : {}),
    });
    if (out.length >= 50) break;
  }
  return out;
}

/** E5: minutes per site, per hour ("2026-11-17T09"), kept until the hour is sent. */
export type ActivityBuckets = Record<string, Record<string, number>>;

export const hourKey = (d: Date) => d.toISOString().slice(0, 13);

/** Counts one minute on [host] in [hour]. */
export function addMinute(b: ActivityBuckets, hour: string, host: string): ActivityBuckets {
  const h = { ...(b[hour] ?? {}) };
  h[host] = Math.min(60, (h[host] ?? 0) + 1);
  return { ...b, [hour]: h };
}

export interface ActivityHour {
  type: "hour";
  hour: string;
  total_minutes: number;
  apps: Array<{ app: string; minutes: number }>;
}

/** The finished hours (before [current]) as ActivitySummary: site names and minutes only. */
export function finishedHours(b: ActivityBuckets, current: string): ActivityHour[] {
  return Object.keys(b)
    .filter((h) => h < current)
    .sort()
    .map((hour) => {
      const sites = Object.entries(b[hour] ?? {})
        .sort((x, y) => y[1] - x[1])
        .slice(0, 30);
      return {
        type: "hour" as const,
        hour,
        total_minutes: Math.min(
          60,
          sites.reduce((n, [, m]) => n + m, 0),
        ),
        apps: sites.map(([app, minutes]) => ({ app: app.slice(0, 100), minutes })),
      };
    });
}

export interface BrowserTrigger {
  event: "site_opened" | "download_done" | "bookmark_added";
  site?: string;
  pattern?: string;
}

/** E4: whether any of the person's routines starts on this event (else nothing is sent). */
export function wanted(
  triggers: BrowserTrigger[],
  e: { event: BrowserTrigger["event"]; host?: string | null; name?: string },
): boolean {
  return triggers.some((t) => {
    if (t.event !== e.event) return false;
    if (t.site && !(e.host && siteMatches(e.host, t.site))) return false;
    if (t.pattern && !globMatch(e.name ?? "", t.pattern)) return false;
    return true;
  });
}

function globMatch(name: string, pattern: string) {
  const re = pattern
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\?/g, ".");
  return new RegExp(`^${re}$`, "i").test(name);
}
