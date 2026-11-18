/**
 * The person's own browser for a run or a watcher (D-323 Phase 3): which paired Chrome to use, and
 * calls to it through the API's device tunnel (`/internal/browser/:device/call`). Owner only: a run
 * reaches the browser of the person it acts for, when that person let the bot in.
 */
import type { BrowserAction, BrowserResult } from "@casama/contracts";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { BrowserChoice, UserBrowser } from "./tools/browser.ts";

export interface TunnelDeps {
  apiUrl: string;
  internalToken: string;
  fetch?: typeof fetch;
}

/**
 * The browser each run settled on, so refs keep meaning the same page across calls (tool calls run
 * one at a time and don't share state). Lost on a worker restart, when the run simply picks again.
 */
const PICKS = new Map<string, "mine" | "computer">();
const PICKS_MAX = 5000;
const remember = (runId: string, w: "mine" | "computer") => {
  if (PICKS.size >= PICKS_MAX) PICKS.delete(PICKS.keys().next().value as string);
  PICKS.set(runId, w);
};

const base = (t: TunnelDeps) => t.apiUrl.replace(/\/$/, "");

async function online(t: TunnelDeps, deviceId: string) {
  const res = await (t.fetch ?? fetch)(`${base(t)}/internal/browser/${deviceId}/status`, {
    headers: { "x-casama-internal": t.internalToken },
    signal: AbortSignal.timeout(5000),
  }).catch(() => null);
  if (!res?.ok) return false;
  return ((await res.json()) as { online: boolean }).online;
}

/** Calls one browser device for a run or a watcher. */
export function browserCaller(
  t: TunnelDeps,
  deviceId: string,
  who: { run_id: string } | { watcher_id: string },
  signal?: () => AbortSignal | undefined,
): UserBrowser {
  return {
    deviceId,
    async call(action: BrowserAction, args: Record<string, unknown>): Promise<BrowserResult> {
      const res = await (t.fetch ?? fetch)(`${base(t)}/internal/browser/${deviceId}/call`, {
        method: "POST",
        headers: { "x-casama-internal": t.internalToken, "content-type": "application/json" },
        body: JSON.stringify({ action, args, ...who }),
        signal: signal?.() ?? AbortSignal.timeout(11 * 60 * 1000),
      }).catch((err: unknown) => {
        if ((err as Error).name === "AbortError") throw err;
        return null;
      });
      if (!res) return { ok: false, code: "offline", message: "The browser is offline" };
      return (await res.json().catch(() => ({
        ok: false,
        code: "bad_answer",
        message: `The browser's answer couldn't be read (${res.status})`,
      }))) as BrowserResult;
    },
  };
}

/** Paired browsers of [userId] in [orgId] that let [botId] in, most recently seen first. */
export async function browserDevicesFor(
  db: Database,
  input: { orgId: string; botId: string; userId: string | null },
) {
  if (!input.userId) return [];
  const rows = await db.execute<{ id: string }>(sql`
    select id from public.local_devices
    where platform = 'chrome' and enabled and user_id = ${input.userId}::uuid and org_id = ${input.orgId}::uuid
      and ${input.botId}::uuid = any(allowed_bot_ids) and coalesce((capabilities ->> 'browser')::boolean, false)
    order by last_seen_at desc nulls last`);
  return rows.map((r) => r.id);
}

/** The first of [ids] that's online, or null. */
export async function firstOnline(t: TunnelDeps, ids: string[]) {
  for (const id of ids) if (await online(t, id)) return id;
  return null;
}

/**
 * What a run knows about browsers. [preferred]: a routine's `browser` setting, else
 * "mine_or_computer" when the conversation started in the extension (it has a page address).
 */
export function browserChoiceFor(
  db: Database,
  t: TunnelDeps,
  run: {
    runId: string;
    orgId: string;
    botId: string;
    actingUserId: string | null;
    preferred: BrowserChoice["preferred"];
    ownUrls: string[];
    signal?: () => AbortSignal | undefined;
  },
  extra: Pick<BrowserChoice, "keep" | "libraryFile"> = {},
): BrowserChoice {
  const find = async () => {
    const ids = await browserDevicesFor(db, {
      orgId: run.orgId,
      botId: run.botId,
      userId: run.actingUserId,
    });
    const id = await firstOnline(t, ids);
    return id ? browserCaller(t, id, { run_id: run.runId }, run.signal) : null;
  };
  return {
    preferred: run.preferred,
    get picked() {
      return PICKS.get(run.runId) ?? null;
    },
    pick(w) {
      remember(run.runId, w);
    },
    ownUrls: run.ownUrls,
    mine: find,
    async waitMine(ms) {
      const until = Date.now() + ms;
      for (;;) {
        const m = await find();
        if (m || Date.now() >= until) return m;
        if (run.signal?.()?.aborted) return null;
        await new Promise((r) => setTimeout(r, 15_000));
      }
    },
    ...extra,
  };
}

/**
 * Whether a run may use the person's own browser at all. A routine changed by someone other than
 * its creator can't (it runs for the creator, with their sign-ins), until the creator edits it.
 */
export async function mineAllowed(db: Database, runId: string): Promise<boolean> {
  const [r] = await db.execute<{ locked: boolean | null }>(sql`
    select rt.edited_by_other as locked from public.runs r
    left join public.routines rt on rt.id = r.routine_id where r.id = ${runId}::uuid`);
  return !r?.locked;
}

/** The run's default browser: a routine's setting, else the person's when the chat began in it. */
export async function preferredBrowser(
  db: Database,
  runId: string,
): Promise<BrowserChoice["preferred"]> {
  const [r] = await db.execute<{ routine: string | null; source_url: string | null }>(sql`
    select rt.browser as routine, c.source_url from public.runs r
    left join public.routines rt on rt.id = r.routine_id
    left join public.conversations c on c.id = r.conversation_id
    where r.id = ${runId}::uuid`);
  if (r?.routine === "mine" || r?.routine === "mine_or_computer") return r.routine;
  return r?.source_url ? "mine_or_computer" : "computer";
}
