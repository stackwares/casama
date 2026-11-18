/**
 * Device connections (SPEC: Device connections; D-149). Bots read summaries the person's phone or
 * computer shared, ask for access per kind with a one-tap card, and add calendar events or
 * reminders on the device. The data is the person's own: only runs acting for them, by bots they
 * allowed, read it.
 */
import { type Database, withoutTimeouts } from "@casama/db";
import { osPermissionList, osPermissionOn } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { wrapUntrusted } from "./context.ts";
import {
  botOwnComputer,
  cardForDeviceKind,
  cardText,
  PERMISSION_IDS,
  type PermissionDevice,
  personDevices,
  showPermissionCard,
} from "./permission-cards.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./tools/registry.ts";

export const DEVICE_KINDS = [
  "calendar",
  "reminders",
  "contacts",
  "places",
  "photos",
  "health",
  "notifications",
  "activity",
  "browser_tab",
  "browser_history",
] as const;
export type DeviceKind = (typeof DEVICE_KINDS)[number];
const KIND = z.enum(DEVICE_KINDS);

/** Default retention: daily summaries a year, place visits and notifications 90 days. */
export const DEFAULT_RETENTION_DAYS: Record<DeviceKind, number> = {
  calendar: 365,
  reminders: 365,
  contacts: 365,
  places: 90,
  photos: 90,
  health: 365,
  notifications: 90,
  activity: 365,
  // Casama for Chrome (D-323): live reads, never stored.
  browser_tab: 0,
  browser_history: 0,
};
const LABEL: Record<DeviceKind, string> = {
  calendar: "calendar",
  reminders: "reminders",
  contacts: "contacts",
  places: "places",
  photos: "photos",
  health: "health data",
  notifications: "notifications",
  activity: "computer activity",
  browser_tab: "current browser tab",
  browser_history: "browser history and bookmarks",
};
/** Kinds that only a live read answers (nothing is stored to fall back on). */
const LIVE_ONLY = new Set<DeviceKind>(["browser_tab", "browser_history"]);
/** A device seen this recently is asked for a fresh read. */
const ONLINE_MS = 15 * 60_000;

type Settings = { retention_days?: number; private_model?: boolean };
type Source = {
  id: string;
  name: string;
  platform: string;
  kinds: Record<string, Settings>;
  last_seen_at: Date;
};

/** A model server on this machine or a private network (a local model). */
export function isPrivateBaseUrl(url: string | null | undefined): boolean {
  if (!url) return false;
  let host: string;
  try {
    host = new URL(url).hostname.replace(/^\[|\]$/g, "").toLowerCase();
  } catch {
    return false;
  }
  if (host === "localhost" || host === "::1" || host === "host.docker.internal") return true;
  if (host.endsWith(".local") || host.endsWith(".internal") || host.endsWith(".lan")) return true;
  const m = host.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (!m) return /^f[cd][0-9a-f]{2}:/.test(host);
  const [a, b] = [Number(m[1]), Number(m[2])];
  return (
    a === 127 ||
    a === 10 ||
    (a === 192 && b === 168) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 100 && b >= 64 && b <= 127)
  );
}

type HealthDay = {
  type?: string;
  date?: string;
  sleep?: { minutes?: number };
  steps?: number;
  active_energy_kcal?: number;
  resting_hr?: number;
  hrv_ms?: number;
};
const HEALTH_METRICS: Array<[string, (d: HealthDay) => number | undefined]> = [
  ["sleep_minutes", (d) => d.sleep?.minutes],
  ["steps", (d) => d.steps],
  ["active_energy_kcal", (d) => d.active_energy_kcal],
  ["resting_hr", (d) => d.resting_hr],
  ["hrv_ms", (d) => d.hrv_ms],
];

/**
 * How a day compares with the person's own previous 30 days (D-150), computed without a model.
 * Neutral words only; a metric needs at least 5 earlier days to have a "usual".
 */
export function healthTrends(history: HealthDay[], day: HealthDay) {
  if (!day.date) return {};
  const start = new Date(new Date(`${day.date}T00:00:00Z`).getTime() - 30 * 86_400_000)
    .toISOString()
    .slice(0, 10);
  const prior = history.filter(
    (h) => h.type === "day" && h.date && h.date < day.date! && h.date >= start,
  );
  const out: Record<string, { value: number; usual: number; compared: string }> = {};
  for (const [name, get] of HEALTH_METRICS) {
    const value = get(day);
    const values = prior.map(get).filter((v): v is number => typeof v === "number");
    if (typeof value !== "number" || values.length < 5) continue;
    const usual = values.reduce((a, b) => a + b, 0) / values.length;
    const ratio = usual === 0 ? 1 : value / usual;
    out[name] = {
      value,
      usual: Math.round(usual * 10) / 10,
      compared:
        ratio > 1.1
          ? "higher than your usual"
          : ratio < 0.9
            ? "lower than your usual"
            : "about your usual",
    };
  }
  return out;
}

/** Every model [botId] may use runs on a private server (a local model): the private model rule. */
export async function botModelsPrivate(db: Database, botId: string): Promise<boolean> {
  const rows = await db.execute<{ base_url: string | null }>(sql`
      with p as (select b.model_policy as m from public.bots b where b.id = ${botId}::uuid),
      ids as (
        select (p.m -> 'primary' ->> 'credential_id') as id from p
        union select f ->> 'credential_id' from p, jsonb_array_elements(coalesce(p.m -> 'fallbacks', '[]'::jsonb)) f
        union select (p.m -> 'cheap' ->> 'credential_id') from p
      )
      select c.base_url from ids join public.model_credentials c on c.id::text = ids.id where ids.id is not null`);
  return rows.length > 0 && rows.every((r) => isPrivateBaseUrl(r.base_url));
}

export interface DeviceDataDeps {
  db: Database;
  /** How long a tool waits for an online device (fresh reads 10 s; tests shorten it). */
  waitMs?: { read?: number; write?: number };
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export function registerDeviceTools(registry: ToolRegistry, deps: DeviceDataDeps) {
  const { db } = deps;
  const owner = async (ctx: ToolContext) => {
    const user = await actingUserOf(db, ctx.runId);
    if (!user)
      throw new ToolError(
        "no_person",
        "This run isn't acting for a person, so there's no device data to use.",
      );
    return user;
  };
  const allowed = async (user: string, botId: string, kind: DeviceKind) =>
    (
      await db.execute(
        sql`select 1 from public.device_grants where user_id = ${user}::uuid and bot_id = ${botId}::uuid and kind = ${kind}`,
      )
    ).length > 0;
  const sources = async (user: string, kind: DeviceKind) =>
    db.execute<Source>(
      sql`select id, name, platform, kinds, last_seen_at from public.device_sources where user_id = ${user}::uuid and kinds ? ${kind} order by last_seen_at desc`,
    );
  /** Runs that already showed the Allow card for a kind, so a run shows it once. */
  const asked = new Set<string>();
  const askOnce = async (ctx: ToolContext, kind: DeviceKind, reason: string) => {
    const key = `${ctx.runId}:${kind}`;
    if (asked.has(key)) return false;
    if (asked.size > 2000) asked.clear();
    asked.add(key);
    // Browser kinds get their own event: app builds before D-323 read device.access_requested's
    // kind strictly and would fail to load the conversation; unknown event types they skip.
    await ctx.emit(
      LIVE_ONLY.has(kind) ? "device.browser_access_requested" : "device.access_requested",
      { kind, reason, bot_id: ctx.botId },
    );
    return true;
  };
  const needGrant = async (user: string, ctx: ToolContext, kind: DeviceKind) => {
    if (await allowed(user, ctx.botId, kind)) return;
    // The person shares this kind but hasn't allowed this bot: show the Allow card now rather
    // than trusting the model to ask (it sometimes says it asked without calling the tool).
    if ((await sources(user, kind)).length) {
      await askOnce(ctx, kind, `So I can use your ${LABEL[kind]} to answer you.`);
      throw new ToolError(
        "no_device_access",
        `You don't have access to the person's ${LABEL[kind]} yet. They now see a one-tap card to allow it: tell them to tap Allow and ask again. Don't call device.request_access, and carry on without it meanwhile.`,
      );
    }
    throw new ToolError(
      "no_device_access",
      `You don't have access to the person's ${LABEL[kind]}, and they don't share it from any device. They can turn it on in Settings → Device connections; then ask with device.request_access.`,
    );
  };
  /**
   * The system permission behind a kind (D-376): when every device sharing it reports that
   * permission off, the person gets a card for the most recently seen one and the tool stops.
   */
  const needOsPermission = async (ctx: ToolContext, list: Source[], kind: DeviceKind) => {
    const card = await cardForDeviceKind(
      db,
      { runId: ctx.runId, botId: ctx.botId, emit: ctx.emit },
      list,
      kind,
    );
    if (card) throw new ToolError("permission_off", card);
  };
  const privateModels = (ctx: ToolContext) => botModelsPrivate(db, ctx.botId);
  /** Asks an online device to do something and waits for its answer; null if it didn't answer in time. */
  const ask = async (
    user: string,
    s: Source,
    kind: string,
    action: string,
    params: Record<string, unknown>,
    runId: string,
    waitMs: number,
  ) => {
    const [req] = await db.execute<{ id: string }>(sql`
      insert into public.device_requests (user_id, source_id, kind, action, params, run_id)
      values (${user}::uuid, ${s.id}::uuid, ${kind}, ${action}, ${JSON.stringify(params)}::jsonb, ${runId}::uuid) returning id`);
    const until = Date.now() + waitMs;
    while (Date.now() < until) {
      await sleep(Math.min(250, waitMs));
      const [r] = await db.execute<{ status: string; result: Record<string, unknown> | null }>(
        sql`select status, result from public.device_requests where id = ${req!.id}::uuid`,
      );
      if (r && r.status !== "pending") {
        // Live-only kinds (the browser's) aren't kept once read: the answer goes to the model only.
        if (LIVE_ONLY.has(kind as DeviceKind))
          await db.execute(
            sql`update public.device_requests set result = null where id = ${req!.id}::uuid`,
          );
        return r;
      }
    }
    return null;
  };
  const age = (d: Date) => {
    const m = Math.round((Date.now() - new Date(d).getTime()) / 60_000);
    return m < 2
      ? "just now"
      : m < 120
        ? `${m} min ago`
        : m < 2880
          ? `${Math.round(m / 60)} h ago`
          : `${Math.round(m / 1440)} days ago`;
  };

  registry.register({
    name: "device.read",
    readOnly: true,
    untrustedOutput: true,
    description:
      "Read data the person shares from their phone, computer or browser: calendar, reminders, contacts, places (arrive and leave visits), photos, health (daily summaries), notifications, computer activity, the browser tab in front (browser_tab: its address, title, selection and text) or pages in their browser history and bookmarks matching a search (browser_history, with query). Returns summaries with their age; an online device is asked for a fresh read first.",
    risk: "low",
    schema: z.object({
      kind: KIND,
      from: z.iso
        .datetime({ offset: true })
        .optional()
        .describe("Start of the range (default: now minus 1 day)"),
      to: z.iso
        .datetime({ offset: true })
        .optional()
        .describe("End of the range (default: now plus 14 days)"),
      query: z
        .string()
        .trim()
        .min(1)
        .max(200)
        .optional()
        .describe("browser_history: words to find in page titles and addresses"),
    }),
    async execute(args, ctx) {
      const user = await owner(ctx);
      const kind = args.kind as DeviceKind;
      await needGrant(user, ctx, kind);
      const list = await sources(user, kind);
      if (!list.length)
        throw new ToolError(
          "device_kind_off",
          `The person hasn't turned on ${LABEL[kind]} on any device. They can in Settings → Device connections.`,
        );
      await needOsPermission(ctx, list, kind);
      if (list.some((s) => s.kinds[kind]?.private_model) && !(await privateModels(ctx)))
        throw new ToolError(
          "private_model_required",
          `The person keeps their ${LABEL[kind]} to private models only, and this bot uses a hosted model.`,
        );
      if (kind === "browser_history" && !args.query)
        throw new ToolError("query_required", "browser_history needs a query: what to look for.");
      const from = args.from ?? new Date(Date.now() - 86_400_000).toISOString();
      const to = args.to ?? new Date(Date.now() + 14 * 86_400_000).toISOString();
      // A fresh read from the most recently seen device, if it's around.
      let live: unknown[] = [];
      const online = list.find((s) => Date.now() - new Date(s.last_seen_at).getTime() < ONLINE_MS);
      if (online) {
        const r = await ask(
          user,
          online,
          kind,
          "read",
          // The browser searches its own history (90 days by default); a range only if asked.
          LIVE_ONLY.has(kind)
            ? {
                ...(args.query ? { query: args.query } : {}),
                ...(args.from ? { from: args.from } : {}),
                ...(args.to ? { to: args.to } : {}),
              }
            : { from, to, ...(args.query ? { query: args.query } : {}) },
          ctx.runId,
          deps.waitMs?.read ?? 10_000,
        );
        if (!r)
          await db.execute(
            sql`update public.device_requests set status = 'expired' where run_id = ${ctx.runId}::uuid and status = 'pending' and action = 'read'`,
          );
        live = ((r?.result as { live?: unknown[] } | null)?.live ?? []).map((x) => ({
          ...(x as object),
          device: online.name,
          age: "just now",
        }));
        if (LIVE_ONLY.has(kind) && r?.status === "failed")
          throw new ToolError(
            "device_failed",
            `${online.name} couldn't read it: ${String((r.result as { error?: string } | null)?.error ?? "unknown error")}`,
          );
      }
      if (LIVE_ONLY.has(kind) && !live.length)
        throw new ToolError(
          "device_offline",
          `The person's browser (${list[0]?.name ?? "Chrome"}) didn't answer. It may be closed; carry on without it.`,
        );
      const rows = await db.execute<{
        period_start: Date;
        period_end: Date;
        summary: unknown;
        collected_at: Date;
        source: string;
      }>(sql`
        select r.period_start, r.period_end, r.summary, r.collected_at, s.name as source from public.device_readings r
        join public.device_sources s on s.id = r.source_id
        where r.user_id = ${user}::uuid and r.kind = ${kind} and r.period_end >= ${from}::timestamptz and r.period_start <= ${to}::timestamptz
        order by r.period_start limit 200`);
      // Health days carry how they compare with the person's own last 30 days.
      let history: HealthDay[] = [];
      if (kind === "health")
        history = (
          await db.execute<{ summary: HealthDay }>(sql`
            select summary from public.device_readings where user_id = ${user}::uuid and kind = 'health'
              and period_start >= ${from}::timestamptz - interval '31 days' and period_start <= ${to}::timestamptz`)
        ).map((r) => r.summary);
      const withTrend = (summary: unknown) => {
        const d = summary as HealthDay;
        if (kind !== "health" || d?.type !== "day") return {};
        const t = healthTrends(
          [...history, ...(live as Array<{ summary?: HealthDay }>).map((l) => l.summary ?? {})],
          d,
        );
        return Object.keys(t).length ? { vs_usual: t } : {};
      };
      const items = [
        ...rows.map((r) => ({
          from: new Date(r.period_start).toISOString(),
          to: new Date(r.period_end).toISOString(),
          device: r.source,
          age: age(r.collected_at),
          summary: r.summary,
          ...withTrend(r.summary),
        })),
        ...(live as Array<{ summary?: unknown }>).map((l) => ({ ...l, ...withTrend(l.summary) })),
      ];
      // The person's own data is in this conversation now: it becomes private to them (audit 2026-11).
      await db.execute(
        sql`update public.conversations set private = true where id = (select conversation_id from public.runs where id = ${ctx.runId}::uuid)`,
      );
      // The timeline shows exactly what device data reached the model.
      await ctx.emit("device.data_used", {
        kind,
        count: items.length,
        from,
        to,
        devices: [
          ...new Set([
            ...rows.map((r) => r.source),
            ...(live.length && online ? [online.name] : []),
          ]),
        ],
      });
      if (!items.length)
        return {
          content: `No ${LABEL[kind]} between ${from} and ${to}.`,
          preview: `0 ${LABEL[kind]} items`,
        };
      const extra =
        kind === "health"
          ? '\nHealth data is for context only: describe it neutrally ("lower than your usual"), never as a diagnosis, and say it isn\'t medical advice when giving health suggestions.'
          : "";
      return {
        content:
          wrapUntrusted(`device ${kind}`, items.map((i) => JSON.stringify(i)).join("\n")) + extra,
        preview: `${items.length} ${LABEL[kind]} items`,
      };
    },
  });

  registry.register({
    name: "device.request_access",
    readOnly: true,
    description:
      "Ask the person for access to one kind of their device data. They see a one-tap card; carry on without it until they allow it.",
    risk: "low",
    schema: z.object({
      kind: KIND,
      reason: z.string().trim().min(1).max(300).describe("Why you need it, in one short sentence"),
    }),
    async execute(args, ctx) {
      const user = await owner(ctx);
      const kind = args.kind as DeviceKind;
      if (await allowed(user, ctx.botId, kind))
        return {
          content: `You already have access to their ${LABEL[kind]}.`,
          preview: "already allowed",
        };
      await askOnce(ctx, kind, args.reason);
      return {
        content: `Asked for their ${LABEL[kind]}. They'll see a card to allow it; don't wait for it.`,
        preview: `asked for ${LABEL[kind]}`,
      };
    },
  });

  registry.register({
    name: "device.request_permission",
    readOnly: true,
    description:
      "Ask the person to turn on a system permission on one of their own devices (Accessibility or Screen Recording on their Mac, Location or Camera on their phone…). They get a card with a button for each; use it before a task you know needs one. Failed tools on their own computer show this card by themselves.",
    risk: "low",
    schema: z.object({
      permissions: z
        .array(z.enum(PERMISSION_IDS))
        .min(1)
        .max(10)
        .describe("System permissions to ask for"),
      device: z
        .string()
        .trim()
        .min(1)
        .max(80)
        .optional()
        .describe("The device's name, when they have several (default: the one that fits)"),
      reason: z.string().trim().min(1).max(300).describe("Why you need it, in one short sentence"),
    }),
    async execute(args, ctx) {
      const user = await owner(ctx);
      const ids = [...new Set(args.permissions as string[])];
      const devices = await personDevices(db, user);
      const has = (d: PermissionDevice) => ids.every((id) => osPermissionOn(id, d.platform));
      let target: PermissionDevice | undefined;
      if (args.device) {
        const name = args.device.toLowerCase();
        target =
          devices.find((d) => d.name.toLowerCase() === name) ??
          devices.find((d) => d.name.toLowerCase().includes(name));
        if (!target)
          throw new ToolError(
            "device_not_found",
            `They have no device called "${args.device}". Their devices: ${devices.map((d) => d.name).join(", ") || "none"}.`,
          );
        const missing = ids.filter((id) => !osPermissionOn(id, target!.platform));
        if (missing.length)
          throw new ToolError(
            "permission_not_here",
            `${target.name} has no ${osPermissionList(missing)} setting Casama can ask for.`,
          );
      } else {
        const own = await botOwnComputer(db, ctx.botId);
        target =
          own && own.userId === user && has(own)
            ? own
            : devices
                .filter((d) => d.type === "source" && has(d))
                .sort((a, b) => (b.lastSeenAt?.getTime() ?? 0) - (a.lastSeenAt?.getTime() ?? 0))[0];
        if (!target)
          throw new ToolError(
            "no_device",
            `None of their devices has ${osPermissionList(ids)} for Casama to ask for. They may need Casama on a phone or computer that does.`,
          );
      }
      const on = ids.filter((id) => target!.permissions[id] === "granted");
      const ask = ids.filter((id) => !on.includes(id));
      const already = on.length ? `Already on: ${osPermissionList(on)}.` : "";
      if (!ask.length) return { content: already, preview: "already on" };
      const outcome = await showPermissionCard(
        { runId: ctx.runId, botId: ctx.botId, emit: ctx.emit },
        target,
        ask,
        args.reason,
      );
      const text = [
        already,
        outcome.shown.length
          ? `Showed them a card to turn on ${osPermissionList(outcome.shown)} on ${target.name}. Wait for them; don't repeat the steps in text.`
          : "",
        outcome.snoozed.length ? cardText({ shown: [], snoozed: outcome.snoozed }, target) : "",
      ]
        .filter(Boolean)
        .join(" ");
      return {
        content: text,
        preview: outcome.shown.length
          ? `asked for ${osPermissionList(outcome.shown)} on ${target.name}`
          : "not now",
      };
    },
  });

  const write = (
    name: string,
    kind: "calendar" | "reminders",
    description: string,
    schema: z.ZodObject<z.ZodRawShape>,
  ) =>
    registry.register({
      name,
      description,
      // Changes the person's own calendar or reminders: runs without asking under the default
      // autonomy; an "ask" action rule makes it ask (D-213, was D-149).
      risk: "medium",
      schema,
      async execute(args, ctx) {
        const user = await owner(ctx);
        await needGrant(user, ctx, kind);
        const list = await sources(user, kind);
        const target =
          list.find((s) => Date.now() - new Date(s.last_seen_at).getTime() < ONLINE_MS) ?? list[0];
        if (!target)
          throw new ToolError(
            "device_kind_off",
            `The person hasn't turned on ${LABEL[kind]} on any device.`,
          );
        await needOsPermission(ctx, list, kind);
        const action = `${kind}.create`;
        const r = await ask(
          user,
          target,
          kind,
          action,
          args as Record<string, unknown>,
          ctx.runId,
          deps.waitMs?.write ?? 20_000,
        );
        if (!r)
          return {
            content: `Sent to ${target.name}; it will be added when the device is next online.`,
            preview: `queued on ${target.name}`,
          };
        if (r.status !== "done")
          throw new ToolError(
            "device_failed",
            `${target.name} couldn't add it: ${String((r.result as { error?: string } | null)?.error ?? "unknown error")}`,
          );
        return { content: `Added on ${target.name}.`, preview: `added on ${target.name}` };
      },
    });
  write(
    "device.calendar.create",
    "calendar",
    "Add an event to the calendar on the person's phone or computer.",
    z.object({
      title: z.string().trim().min(1).max(200),
      start: z.iso.datetime({ offset: true }),
      end: z.iso.datetime({ offset: true }),
      location: z.string().max(300).optional(),
      notes: z.string().max(2000).optional(),
    }),
  );
  write(
    "device.reminders.create",
    "reminders",
    "Add a reminder on the person's phone or computer.",
    z.object({
      title: z.string().trim().min(1).max(200),
      due: z.iso.datetime({ offset: true }).optional(),
      notes: z.string().max(2000).optional(),
    }),
  );
}

/** Retention and stale requests (the worker's minute tick). */
export async function purgeDeviceData(db: Database) {
  const defaults = JSON.stringify(DEFAULT_RETENTION_DAYS);
  // Only rows older than the shortest retention (7 days, or 0 for live only) can be due, so the
  // per-row retention check runs on that slice (indexed on period_end), not the whole table.
  // A backlog (or the first run) can be large.
  const [removed] = await withoutTimeouts(db, (tx) =>
    tx.execute<{ n: number }>(sql`
    with gone as (
      delete from public.device_readings r using public.device_sources s
      where s.id = r.source_id and r.period_end < now()
        and r.period_end < now() - make_interval(days => coalesce((s.kinds -> r.kind ->> 'retention_days')::int, (${defaults}::jsonb ->> r.kind)::int, 365))
      returning 1)
    select count(*)::int as n from gone`),
  );
  await db.execute(
    sql`update public.device_requests set status = 'expired' where status = 'pending' and created_at < now() - interval '1 hour'`,
  );
  // The event log is kept 30 days ("where am I now" answers are cleared by checkLeaveNow each minute).
  await db.execute(
    sql`delete from public.device_event_log where received_at < now() - interval '30 days'`,
  );
  await db.execute(
    sql`delete from public.device_requests where created_at < now() - interval '7 days'`,
  );
  // The browser's answers (tab text, history hits) are live only: gone within minutes.
  await db.execute(
    sql`delete from public.device_requests where kind in ('browser_tab', 'browser_history') and created_at < now() - interval '10 minutes'`,
  );
  // Read notifications go after 180 days (the inbox shows the latest 100).
  await db.execute(
    sql`delete from public.notifications where read_at is not null and created_at < now() - interval '180 days'`,
  );
  return removed?.n ?? 0;
}
