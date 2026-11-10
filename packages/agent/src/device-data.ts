/**
 * Device connections (SPEC: Device connections; D-149). Bots read summaries the person's phone or
 * computer shared, ask for access per kind with a one-tap card, and add calendar events or
 * reminders on the device. The data is the person's own: only runs acting for them, by bots they
 * allowed, read it.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { wrapUntrusted } from "./context.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./tools/registry.ts";

export const DEVICE_KINDS = ["calendar", "reminders", "contacts", "places", "photos", "health", "notifications", "activity"] as const;
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
};
/** A device seen this recently is asked for a fresh read. */
const ONLINE_MS = 15 * 60_000;

type Settings = { retention_days?: number; private_model?: boolean };
type Source = { id: string; name: string; platform: string; kinds: Record<string, Settings>; last_seen_at: Date };

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
  return a === 127 || a === 10 || (a === 192 && b === 168) || (a === 172 && b >= 16 && b <= 31) || (a === 100 && b >= 64 && b <= 127);
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
    if (!user) throw new ToolError("no_person", "This run isn't acting for a person, so there's no device data to use.");
    return user;
  };
  const allowed = async (user: string, botId: string, kind: DeviceKind) =>
    (await db.execute(sql`select 1 from public.device_grants where user_id = ${user}::uuid and bot_id = ${botId}::uuid and kind = ${kind}`)).length > 0;
  const needGrant = async (user: string, ctx: ToolContext, kind: DeviceKind) => {
    if (!(await allowed(user, ctx.botId, kind)))
      throw new ToolError("no_device_access", `You don't have access to the person's ${LABEL[kind]}. Ask with device.request_access (they get a one-tap card), and carry on without it meanwhile.`);
  };
  const sources = async (user: string, kind: DeviceKind) =>
    db.execute<Source>(sql`select id, name, platform, kinds, last_seen_at from public.device_sources where user_id = ${user}::uuid and kinds ? ${kind} order by last_seen_at desc`);
  /** Every model this bot may use runs on a private server. */
  const privateModels = async (ctx: ToolContext) => {
    const rows = await db.execute<{ base_url: string | null }>(sql`
      with p as (select b.model_policy as m from public.bots b where b.id = ${ctx.botId}::uuid),
      ids as (
        select (p.m -> 'primary' ->> 'credential_id') as id from p
        union select f ->> 'credential_id' from p, jsonb_array_elements(coalesce(p.m -> 'fallbacks', '[]'::jsonb)) f
        union select (p.m -> 'cheap' ->> 'credential_id') from p
      )
      select c.base_url from ids join public.credentials c on c.id::text = ids.id where ids.id is not null`);
    return rows.length > 0 && rows.every((r) => isPrivateBaseUrl(r.base_url));
  };
  /** Asks an online device to do something and waits for its answer; null if it didn't answer in time. */
  const ask = async (user: string, s: Source, kind: string, action: string, params: Record<string, unknown>, runId: string, waitMs: number) => {
    const [req] = await db.execute<{ id: string }>(sql`
      insert into public.device_requests (user_id, source_id, kind, action, params, run_id)
      values (${user}::uuid, ${s.id}::uuid, ${kind}, ${action}, ${JSON.stringify(params)}::jsonb, ${runId}::uuid) returning id`);
    const until = Date.now() + waitMs;
    while (Date.now() < until) {
      await sleep(Math.min(250, waitMs));
      const [r] = await db.execute<{ status: string; result: Record<string, unknown> | null }>(sql`select status, result from public.device_requests where id = ${req!.id}::uuid`);
      if (r && r.status !== "pending") return r;
    }
    return null;
  };
  const age = (d: Date) => {
    const m = Math.round((Date.now() - new Date(d).getTime()) / 60_000);
    return m < 2 ? "just now" : m < 120 ? `${m} min ago` : m < 2880 ? `${Math.round(m / 60)} h ago` : `${Math.round(m / 1440)} days ago`;
  };

  registry.register({
    name: "device.read",
    readOnly: true,
    untrustedOutput: true,
    description:
      "Read data the person shares from their phone or computer: calendar, reminders, contacts, places (arrive and leave visits), photos, health (daily summaries), notifications or computer activity. Returns summaries with their age; an online device is asked for a fresh read first.",
    risk: "low",
    schema: z.object({
      kind: KIND,
      from: z.iso.datetime({ offset: true }).optional().describe("Start of the range (default: now minus 1 day)"),
      to: z.iso.datetime({ offset: true }).optional().describe("End of the range (default: now plus 14 days)"),
    }),
    async execute(args, ctx) {
      const user = await owner(ctx);
      const kind = args.kind as DeviceKind;
      await needGrant(user, ctx, kind);
      const list = await sources(user, kind);
      if (!list.length)
        throw new ToolError("device_kind_off", `The person hasn't turned on ${LABEL[kind]} on any device. They can in Settings → Device connections.`);
      if (list.some((s) => s.kinds[kind]?.private_model) && !(await privateModels(ctx)))
        throw new ToolError("private_model_required", `The person keeps their ${LABEL[kind]} to private models only, and this bot uses a hosted model.`);
      const from = args.from ?? new Date(Date.now() - 86_400_000).toISOString();
      const to = args.to ?? new Date(Date.now() + 14 * 86_400_000).toISOString();
      // A fresh read from the most recently seen device, if it's around.
      let live: unknown[] = [];
      const online = list.find((s) => Date.now() - new Date(s.last_seen_at).getTime() < ONLINE_MS);
      if (online) {
        const r = await ask(user, online, kind, "read", { from, to }, ctx.runId, deps.waitMs?.read ?? 10_000);
        if (!r) await db.execute(sql`update public.device_requests set status = 'expired' where run_id = ${ctx.runId}::uuid and status = 'pending' and action = 'read'`);
        live = ((r?.result as { live?: unknown[] } | null)?.live ?? []).map((x) => ({ ...(x as object), age: "just now" }));
      }
      const rows = await db.execute<{ period_start: Date; period_end: Date; summary: unknown; collected_at: Date; source: string }>(sql`
        select r.period_start, r.period_end, r.summary, r.collected_at, s.name as source from public.device_readings r
        join public.device_sources s on s.id = r.source_id
        where r.user_id = ${user}::uuid and r.kind = ${kind} and r.period_end >= ${from}::timestamptz and r.period_start <= ${to}::timestamptz
        order by r.period_start limit 200`);
      const items = [
        ...rows.map((r) => ({ from: new Date(r.period_start).toISOString(), to: new Date(r.period_end).toISOString(), device: r.source, age: age(r.collected_at), summary: r.summary })),
        ...live,
      ];
      // The timeline shows exactly what device data reached the model.
      await ctx.emit("device.data_used", { kind, count: items.length, from, to, devices: [...new Set(rows.map((r) => r.source))] });
      if (!items.length) return { content: `No ${LABEL[kind]} between ${from} and ${to}.`, preview: `0 ${LABEL[kind]} items` };
      const extra = kind === "health" ? "\nHealth data is for context only: describe it neutrally (\"lower than your usual\"), never as a diagnosis, and say it isn't medical advice when giving health suggestions." : "";
      return { content: wrapUntrusted(`device ${kind}`, items.map((i) => JSON.stringify(i)).join("\n")) + extra, preview: `${items.length} ${LABEL[kind]} items` };
    },
  });

  registry.register({
    name: "device.request_access",
    readOnly: true,
    description: "Ask the person for access to one kind of their device data. They see a one-tap card; carry on without it until they allow it.",
    risk: "low",
    schema: z.object({ kind: KIND, reason: z.string().trim().min(1).max(300).describe("Why you need it, in one short sentence") }),
    async execute(args, ctx) {
      const user = await owner(ctx);
      const kind = args.kind as DeviceKind;
      if (await allowed(user, ctx.botId, kind)) return { content: `You already have access to their ${LABEL[kind]}.`, preview: "already allowed" };
      await ctx.emit("device.access_requested", { kind, reason: args.reason, bot_id: ctx.botId });
      return { content: `Asked for their ${LABEL[kind]}. They'll see a card to allow it; don't wait for it.`, preview: `asked for ${LABEL[kind]}` };
    },
  });

  const write = (name: string, kind: "calendar" | "reminders", description: string, schema: z.ZodObject<z.ZodRawShape>) =>
    registry.register({
      name,
      description,
      risk: "medium",
      // Changes the person's own calendar: asks first by default (action rules can allow it).
      confirm: true,
      schema,
      async execute(args, ctx) {
        const user = await owner(ctx);
        await needGrant(user, ctx, kind);
        const list = await sources(user, kind);
        const target = list.find((s) => Date.now() - new Date(s.last_seen_at).getTime() < ONLINE_MS) ?? list[0];
        if (!target) throw new ToolError("device_kind_off", `The person hasn't turned on ${LABEL[kind]} on any device.`);
        const action = `${kind}.create`;
        const r = await ask(user, target, kind, action, args as Record<string, unknown>, ctx.runId, deps.waitMs?.write ?? 20_000);
        if (!r) return { content: `Sent to ${target.name}; it will be added when the device is next online.`, preview: `queued on ${target.name}` };
        if (r.status !== "done") throw new ToolError("device_failed", `${target.name} couldn't add it: ${String((r.result as { error?: string } | null)?.error ?? "unknown error")}`);
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
    z.object({ title: z.string().trim().min(1).max(200), due: z.iso.datetime({ offset: true }).optional(), notes: z.string().max(2000).optional() }),
  );
}

/** Retention and stale requests (the worker's minute tick). */
export async function purgeDeviceData(db: Database) {
  const defaults = JSON.stringify(DEFAULT_RETENTION_DAYS);
  const removed = await db.execute(sql`
    delete from public.device_readings r using public.device_sources s
    where s.id = r.source_id
      and r.period_end < now() - make_interval(days => coalesce((s.kinds -> r.kind ->> 'retention_days')::int, (${defaults}::jsonb ->> r.kind)::int, 365))
    returning r.id`);
  await db.execute(sql`update public.device_requests set status = 'expired' where status = 'pending' and created_at < now() - interval '1 hour'`);
  await db.execute(sql`delete from public.device_requests where created_at < now() - interval '7 days'`);
  return removed.length;
}
