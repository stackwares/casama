/**
 * Check-ins fetch first (docs/USAGE-PLAN.md step 5). A scan used to spend most of its steps on the
 * same reads every time (the inbox, the calendar, the board), each step re-sending everything
 * before it, and 10 of 39 production scans ran out of steps with nothing to show. Now the run makes
 * those reads itself before the first model call, so the model starts with the results and judges
 * in a step or two. What was read is also reduced to a digest: a scheduled scan that finds the
 * same digest as last time ends without calling the model at all (watchers work the same way,
 * D-116).
 */
import { createHash } from "node:crypto";
import type { ToolCall } from "./gateway/types.ts";

const DAY_MS = 86_400_000;
/** `composio.apps.gmail_fetch_emails` → `gmail_fetch_emails`; null for Casama's own tools. */
const appTool = (name: string) =>
  /^(?:mcp|openapi|composio|pipedream|app)\.[^.]+\.(.+)$/.exec(name)?.[1] ?? null;

/** The first reads, by the app's own tool name, with the arguments the scan instructions ask for. */
const APP_READS: Record<string, (now: Date) => Record<string, unknown>> = {
  // Recent mail a person would act on: about ten, newest first, without bodies.
  gmail_fetch_emails: () => ({
    query: "in:inbox -category:promotions -category:social -category:forums newer_than:3d",
    max_results: 10,
    verbose: false,
    include_payload: false,
  }),
  // The next two days of the main calendar.
  googlecalendar_events_list: (now) => ({
    calendarId: "primary",
    timeMin: now.toISOString(),
    timeMax: new Date(now.getTime() + 2 * DAY_MS).toISOString(),
    singleEvents: true,
    orderBy: "startTime",
    maxResults: 20,
  }),
};
/** Casama's own reads that cost nothing and that every check-in makes. */
const OWN_READS: Record<string, () => Record<string, unknown>> = {
  "tasks.list": () => ({ limit: 20 }),
};
/** Apps whose first read covers what a check-in looks at there (their other reads only go deeper). */
const COVERED_APPS = [...new Set(Object.keys(APP_READS).map((t) => t.split("_")[0] as string))];

export const PREFETCH_CALL_PREFIX = "prefetch-";

/**
 * The reads a check-in run makes before its first model call, from the tools it is offered.
 * `now` is the run's recorded start, so a resumed run asks for the same window.
 */
export function checkinPrefetch(available: Array<{ name: string }>, now: Date): ToolCall[] {
  const calls: ToolCall[] = [];
  const seen = new Set<string>();
  for (const { name } of [...available].sort((a, b) => a.name.localeCompare(b.name))) {
    const tool = appTool(name);
    const args = tool ? APP_READS[tool]?.(now) : OWN_READS[name]?.();
    // One account per app is read up front; a second Gmail is the model's to open if it matters.
    const key = tool ?? name;
    if (!args || seen.has(key)) continue;
    seen.add(key);
    calls.push({ callId: `${PREFETCH_CALL_PREFIX}${calls.length}`, name, args });
  }
  return calls;
}

/**
 * Whether the first reads cover everything this check-in could look at: no tool from an app other
 * than the ones read up front. When they don't, an unchanged digest proves nothing about the other
 * apps, so the scan runs.
 */
export function prefetchCoversApps(available: Array<{ name: string }>): boolean {
  return available.every(({ name }) => {
    const tool = appTool(name);
    return !tool || COVERED_APPS.includes(tool.split("_")[0] as string);
  });
}

/** Every value of `key` in `text`, parsed or not (a long result is cut mid-JSON). */
const valuesOf = (text: string, key: string) =>
  [...text.matchAll(new RegExp(`"${key}"\\s*:\\s*"([^"\\\\]*)"`, "g"))].map((m) => m[1] as string);

/** What identifies one read's contents, or null when the result isn't recognised. */
function identity(name: string, content: string): string[] | null {
  if (/^Error\b/.test(content.trim())) return null;
  const tool = appTool(name);
  if (tool === "gmail_fetch_emails") {
    const ids = [...valuesOf(content, "messageId"), ...valuesOf(content, "message_id")];
    // An empty inbox is a state too, but only when the reply is clearly a list.
    return ids.length ? ids.sort() : /"messages"\s*:\s*\[\s*\]/.test(content) ? [] : null;
  }
  if (tool === "googlecalendar_events_list") {
    // An event's etag changes whenever the event does; ids alone would miss a moved meeting.
    const etags = valuesOf(content, "etag");
    const ids = valuesOf(content, "id");
    if (!ids.length && !etags.length) return /"items"\s*:\s*\[\s*\]/.test(content) ? [] : null;
    return [...ids, ...etags].sort();
  }
  // Casama's own reads are plain text that only changes when the data does.
  return tool ? null : [content.replace(/<\/?untrusted[^>]*>/g, "").trim()];
}

/**
 * A short digest of what the first reads returned: message ids, event ids and their change marks,
 * the board as listed. Null when any read failed or came back in a shape we don't know, which
 * always means "look again".
 */
export function scanDigest(results: Array<{ name: string; content: string }>): string | null {
  if (!results.length) return null;
  const hash = createHash("sha256");
  for (const r of [...results].sort((a, b) => a.name.localeCompare(b.name))) {
    const id = identity(r.name, r.content);
    if (id === null) return null;
    hash.update(`${r.name}\n${id.join("\n")}\n\n`);
  }
  return hash.digest("hex").slice(0, 32);
}
