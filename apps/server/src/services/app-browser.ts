/**
 * The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md): its stage setting, the numbers the
 * stage rules read, and the step rules the server runs before a phone carries a step out.
 */
import { appBrowserSettings, resetAppBrowserCache } from "@casama/agent";
import {
  type AppBrowserSettings,
  clickVerdict,
  crossSite,
  fieldVerdict,
  keyVerdict,
  type Verdict,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import type { AppDeps } from "../api/types.ts";

const KEY = "app_browser";

/** The stage as the API and the worker both read it (one cache, in @casama/agent). */
export const getAppBrowserSettings = (db: AppDeps["db"]) => appBrowserSettings(db);

export async function setAppBrowserSettings(db: AppDeps["db"], value: AppBrowserSettings) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify(value)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  resetAppBrowserCache();
  return value;
}

/** What the stage rules in plan §6 are read from, over the last [days] days. */
export async function appBrowserNumbers(db: AppDeps["db"], days: number) {
  const [n] = await db.execute<{
    blocked_runs: number;
    blocked_people: number;
    watched_browser_runs: number;
    phone_runs: number;
    phone_people: number;
    refused_steps: number;
  }>(sql`
    with a as (
      select l.action, l.metadata, d.user_id as phone_user
      from public.audit_log l
      left join public.local_devices d
        on l.target_type = 'local_device' and d.id = l.target_id and d.platform = 'app'
      where l.created_at > now() - make_interval(days => ${days}) and l.action like 'browser.%'
    )
    select
      count(distinct metadata ->> 'run_id') filter (
        where action = 'browser.blocked' and (metadata ->> 'watched')::boolean)::int as blocked_runs,
      count(distinct metadata ->> 'user_id') filter (
        where action = 'browser.blocked' and (metadata ->> 'watched')::boolean)::int as blocked_people,
      count(distinct metadata ->> 'run_id') filter (
        where action = 'browser.watched_run')::int as watched_browser_runs,
      count(distinct metadata ->> 'run_id') filter (
        where phone_user is not null and action not in ('browser.step_denied', 'browser.step_handed_off'))::int as phone_runs,
      count(distinct phone_user) filter (where phone_user is not null)::int as phone_people,
      count(*) filter (
        where phone_user is not null and action in ('browser.step_denied', 'browser.step_handed_off'))::int as refused_steps
    from a`);
  const [p] = await db.execute<{ paired: number; with_sites: number }>(sql`
    select count(*)::int as paired,
           count(*) filter (where cardinality(allowed_sites) > 0)::int as with_sites
    from public.local_devices where platform = 'app' and enabled`);
  return {
    days,
    blocked_runs: n?.blocked_runs ?? 0,
    blocked_people: n?.blocked_people ?? 0,
    watched_browser_runs: n?.watched_browser_runs ?? 0,
    phone_runs: n?.phone_runs ?? 0,
    phone_people: n?.phone_people ?? 0,
    phones_paired: p?.paired ?? 0,
    phones_with_sites: p?.with_sites ?? 0,
    refused_steps: n?.refused_steps ?? 0,
  };
}

// --- Step rules ------------------------------------------------------------------------------

/** What the page says about the element a step is aimed at (packages/page-agent, `probe`). */
export interface StepFacts {
  role?: string;
  name?: string;
  url?: string;
  host?: string;
  inputType?: string;
  autocomplete?: string;
  submits?: boolean;
  passwordForm?: boolean;
  inForm?: boolean;
  submitName?: string;
  editable?: boolean;
  isFile?: boolean;
}

/**
 * Page text each run read, by site, for the cross-site check. In this process's memory: after a
 * restart a run starts with nothing read, which only makes the check miss, never block.
 */
const READ = new Map<string, Map<string, string[]>>();
const READ_RUNS = 2000;
const READS_PER_SITE = 5;
const READ_CHARS = 100_000;

export function rememberRead(runId: string, host: string | null, text: string) {
  if (!host || !text) return;
  let by = READ.get(runId);
  if (!by) {
    if (READ.size >= READ_RUNS) READ.delete(READ.keys().next().value as string);
    by = new Map();
    READ.set(runId, by);
  }
  const pages = by.get(host) ?? [];
  pages.push(text.slice(0, READ_CHARS));
  by.set(host, pages.slice(-READS_PER_SITE));
}

/** The verdict for one step on a phone, from the page's facts and what the run read elsewhere. */
export function stepVerdict(
  runId: string,
  action: string,
  args: Record<string, unknown>,
  f: StepFacts,
): Verdict {
  const str = (v: unknown) => (typeof v === "string" ? v : "");
  const role = str(f.role);
  const name = str(f.name);
  const typed = () => {
    const v = fieldVerdict({
      role,
      name,
      inputType: str(f.inputType),
      autocomplete: str(f.autocomplete),
    });
    if (v.kind !== "ok") return v;
    const from = crossSite(str(args.text), str(f.host), READ.get(runId) ?? new Map());
    return from
      ? ({
          kind: "ask",
          reason: `This types something read on ${from.from} into ${str(f.host) || "another site"}`,
        } as Verdict)
      : v;
  };
  switch (action) {
    case "click":
      return clickVerdict({
        role,
        name,
        url: str(f.url),
        passwordForm: !!f.passwordForm,
        submits: !!f.submits,
      });
    case "fill":
    case "type":
      return typed();
    case "press":
      return keyVerdict(str(args.key), {
        inForm: !!f.inForm,
        submitName: str(f.submitName),
        passwordForm: !!f.passwordForm,
        editable: !!f.editable,
        inputType: str(f.inputType),
        role,
      });
    case "upload":
      return { kind: "ask", reason: "This uploads a file to the site" };
    default:
      return { kind: "ok" };
  }
}
