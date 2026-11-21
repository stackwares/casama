/**
 * The person's own browser for a run or a watcher (D-323 Phase 3): which paired Chrome to use, and
 * calls to it through the API's device tunnel (`/internal/browser/:device/call`). Owner only: a run
 * reaches the browser of the person it acts for, when that person let the bot in.
 */
import type { BrowserAction, BrowserResult } from "@casama/contracts";
import type { Database } from "@casama/db";
import {
  APP_BROWSER_FOCUS_S,
  APP_BROWSER_OFF,
  type AppBrowserSettings,
  appBrowserFor,
  type BrowserBlock,
  checkAppBrowserSettings,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import type { BrowserChoice, PhoneBrowser, UserBrowser } from "./tools/browser.ts";

export interface TunnelDeps {
  apiUrl: string;
  internalToken: string;
  fetch?: typeof fetch;
}

/**
 * The browser each run settled on, so refs keep meaning the same page across calls (tool calls run
 * one at a time and don't share state). Lost on a worker restart, when the run simply picks again.
 */
const PICKS = new Map<string, "mine" | "computer" | "phone">();
const PICKS_MAX = 5000;
const remember = (runId: string, w: "mine" | "computer" | "phone") => {
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
    phone: () => phoneFor(db, t, run),
    noteComputer: (blocked) => noteComputer(db, run, blocked),
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

// --- The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md) -----------------------------

let stageCache: { at: number; value: AppBrowserSettings } | null = null;

/** The instance's phone-browser stage, read with a short cache (the owner changes it rarely). */
export async function appBrowserSettings(db: Database): Promise<AppBrowserSettings> {
  if (stageCache && Date.now() - stageCache.at < 15_000) return stageCache.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = 'app_browser'`,
  );
  // A stored value that doesn't pass counts as off.
  const value = row?.value
    ? (checkAppBrowserSettings(row.value).settings ?? APP_BROWSER_OFF)
    : APP_BROWSER_OFF;
  stageCache = { at: Date.now(), value };
  return value;
}

export function resetAppBrowserCache() {
  stageCache = null;
}

/**
 * The phone browser a run may use right now, or null. Every condition of plan §5 at once: the stage
 * and the workspace allow the person, they turned it on for this phone and this bot, the run is
 * their own chat message (never a routine), that chat is open on that very phone, and the phone is
 * connected. The API's tunnel checks all of it again on every call.
 */
export async function phoneFor(
  db: Database,
  t: TunnelDeps,
  run: {
    runId: string;
    orgId: string;
    botId: string;
    actingUserId: string | null;
    signal?: () => AbortSignal | undefined;
  },
): Promise<PhoneBrowser | null> {
  if (!run.actingUserId) return null;
  const settings = await appBrowserSettings(db);
  if (settings.stage === "off") return null;
  const rows = await db.execute<{
    id: string;
    system: "ios" | "android" | null;
    allowed_sites: string[];
    workspace_on: boolean;
  }>(sql`
    select d.id, d.system, d.allowed_sites, o.app_browser as workspace_on
    from public.local_devices d
    join public.organizations o on o.id = d.org_id
    join public.runs r on r.id = ${run.runId}::uuid
    join public.chat_focus f on f.user_id = d.user_id and f.client_id = d.client_id
      and f.conversation_id = r.conversation_id
      and f.updated_at > now() - make_interval(secs => ${APP_BROWSER_FOCUS_S})
    where d.platform = 'app' and d.enabled and d.user_id = ${run.actingUserId}::uuid
      and d.org_id = ${run.orgId}::uuid and ${run.botId}::uuid = any(d.allowed_bot_ids)
      and coalesce((d.capabilities ->> 'browser')::boolean, false)
      and r.trigger = 'chat' and r.routine_id is null and r.created_by = d.user_id
    order by f.updated_at desc`);
  for (const d of rows) {
    const ok = appBrowserFor(settings, {
      userId: run.actingUserId,
      system: d.system,
      workspaceOn: d.workspace_on,
    });
    if (!ok.available) continue;
    if (!(await online(t, d.id))) continue;
    return {
      ...browserCaller(t, d.id, { run_id: run.runId }, run.signal),
      sites: d.allowed_sites ?? [],
      reasons: settings.reasons,
    };
  }
  return null;
}

/** Runs that already counted as "browsed on the computer while someone watched", and their blocks. */
const NOTED = new Map<string, Set<string>>();

/**
 * Counts for the stage rules (plan §6): one audit row the first time a run browses on its computer
 * while its chat is on someone's screen, and one per site that kept the computer out.
 */
async function noteComputer(
  db: Database,
  run: { runId: string; orgId: string; botId: string; actingUserId: string | null },
  blocked?: { host: string | null; block: BrowserBlock },
) {
  let seen = NOTED.get(run.runId);
  if (!seen) {
    if (NOTED.size >= PICKS_MAX) NOTED.delete(NOTED.keys().next().value as string);
    seen = new Set();
    NOTED.set(run.runId, seen);
  }
  const key = blocked ? `blocked:${blocked.host ?? ""}` : "run";
  if (seen.has(key)) return;
  seen.add(key);
  const [w] = await db.execute<{ watched: boolean }>(sql`
    select exists (
      select 1 from public.chat_focus f join public.runs r on r.id = ${run.runId}::uuid
      where f.conversation_id = r.conversation_id
        and f.updated_at > now() - make_interval(secs => ${APP_BROWSER_FOCUS_S})) as watched`);
  if (!w?.watched && !blocked) return;
  await db.execute(sql`
    insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
    values (${run.orgId}::uuid, 'bot', ${run.botId}::uuid,
            ${blocked ? "browser.blocked" : "browser.watched_run"}, 'run', ${run.runId}::uuid,
            ${JSON.stringify({
              run_id: run.runId,
              user_id: run.actingUserId,
              watched: !!w?.watched,
              ...(blocked
                ? { host: blocked.host, kind: blocked.block.kind, sign: blocked.block.sign }
                : {}),
            })}::jsonb)`);
}

/**
 * This turn's line about the phone's browser, only when the run could use it right now (so a bot
 * never reaches for a phone that isn't there).
 */
export function phoneHint(p: PhoneBrowser | null): string | null {
  if (!p) return null;
  const when = [
    p.reasons.asked ? 'when they ask you to do something on their phone or "here"' : null,
    p.reasons.blocked
      ? 'when a site keeps your own computer out (a CAPTCHA, "access denied")'
      : null,
    p.reasons.signed_in && p.sites.length
      ? `for the sites they signed in to there for you (${p.sites.slice(0, 12).join(", ")})`
      : null,
  ].filter(Boolean);
  if (!when.length) return null;
  return `The person has this chat open in Casama on their phone, and its built-in browser is available to you: browser tools with where: "phone". Use it ${when.join("; ")}. Otherwise keep to your own computer. On the phone they see every step, are asked before risky ones, type passwords, card numbers and codes themselves, and can stop you by touching the page. It works only while they stay in this chat, has one page, and has no console or network tools.`;
}
