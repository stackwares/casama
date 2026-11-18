/**
 * Device connections (SPEC: Device connections; D-149). The app registers each device with the
 * kinds the user turned on, uploads summaries, answers fresh-read and write requests, and manages
 * which bots may read which kinds. Everything here is the signed-in person's own data.
 */

import { botModelsPrivate, requestScan } from "@casama/agent";
import {
  ActivitySummary,
  BROWSER_DEVICE_KINDS,
  BrowserHistorySummary,
  BrowserTabSummary,
  HealthSummary,
  routes,
} from "@casama/contracts";
import { contentKeys, type JwtClaims, withUserSession } from "@casama/db";
import { browserTriggerSite, isCasamaAddress } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { type DeviceEvent, fireDeviceEvent, maskCodes } from "../../worker/device-triggers.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const MAX_SUMMARY_BYTES = 64 * 1024;
/** Kinds only Casama for Chrome shares (D-323): live reads, never stored. */
const BROWSER_KINDS = new Set<string>(BROWSER_DEVICE_KINDS);
/** How long a person's own device waits for their browser (E3), like a bot's fresh read. */
const ASK_BROWSER_MS = 10_000;

type SourceRow = {
  id: string;
  device_key: string;
  name: string;
  platform: string;
  kinds: Record<string, unknown>;
  last_seen_at: Date;
  created_at: Date;
};
const outSource = (s: SourceRow) => ({
  id: s.id,
  device_key: s.device_key,
  name: s.name,
  platform: s.platform as "ios",
  kinds: s.kinds as Record<string, { retention_days?: number; private_model?: boolean }>,
  last_seen_at: iso(s.last_seen_at),
  created_at: iso(s.created_at),
});

export function registerDeviceDataRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const me = (claims: JwtClaims | undefined) => {
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims.sub;
  };
  const source = async (userId: string, key: string) => {
    const [s] = await db.execute<SourceRow>(sql`
      update public.device_sources set last_seen_at = now() where user_id = ${userId}::uuid and device_key = ${key} returning *`);
    if (!s)
      throw new ApiError(404, "device_not_found", "This device isn't registered; save it first");
    return s;
  };
  // Health (D-150): sealed with the content key of a workspace the person owns; on Casama Cloud
  // it isn't stored at all without one.
  const healthNeedsKey =
    deps.env.HEALTH_REQUIRES_ENCRYPTION === "on" ||
    (deps.env.HEALTH_REQUIRES_ENCRYPTION === "auto" && deps.env.BILLING_ENABLED);
  const keyOrg = async (userId: string) => {
    const owned = await db.execute<{ org_id: string }>(sql`
      select m.org_id from public.memberships m where m.user_id = ${userId}::uuid and m.role = 'owner' order by m.created_at`);
    return owned.map((o) => o.org_id).find((id) => contentKeys.seals(id)) ?? null;
  };
  const grants = async (userId: string, botId?: string, allKinds = false) => {
    const rows = await db.execute<{
      bot_id: string;
      bot_name: string;
      kind: string;
      created_at: Date;
    }>(sql`
      select g.bot_id, b.name as bot_name, g.kind, g.created_at from public.device_grants g join public.bots b on b.id = g.bot_id
      where g.user_id = ${userId}::uuid ${botId ? sql`and g.bot_id = ${botId}::uuid` : sql``}
        ${allKinds ? sql`` : sql`and g.kind <> all(${`{${[...BROWSER_KINDS].join(",")}}`}::text[])`}
      order by b.name, g.kind`);
    return rows.map((g) => ({ ...g, kind: g.kind as "calendar", created_at: iso(g.created_at) }));
  };

  app.openapi(routes.listDeviceSources, async (c) => {
    const userId = me(c.get("claims"));
    const rows = await db.execute<SourceRow>(
      sql`select * from public.device_sources where user_id = ${userId}::uuid order by created_at`,
    );
    return c.json({ items: rows.map(outSource) }, 200);
  });

  app.openapi(routes.saveDeviceSource, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const b = c.req.valid("json");
    // Browser kinds come only from the extension (platform web) and are never stored.
    for (const k of Object.keys(b.kinds)) {
      if (!BROWSER_KINDS.has(k)) continue;
      if (b.platform !== "web")
        throw new ApiError(400, "kind_not_here", `${k} comes only from Casama for Chrome`);
      b.kinds[k as "browser_tab"] = { ...b.kinds[k as "browser_tab"], retention_days: 0 };
    }
    const [s] = await db.transaction(async (tx) => {
      const [before] = await tx.execute<{ kinds: Record<string, unknown> }>(sql`
        select kinds from public.device_sources where user_id = ${userId}::uuid and device_key = ${key} for update`);
      const rows = await tx.execute<SourceRow>(sql`
        insert into public.device_sources (user_id, device_key, name, platform, kinds)
        values (${userId}::uuid, ${key}, ${b.name}, ${b.platform}, ${JSON.stringify(b.kinds)}::jsonb)
        on conflict (user_id, device_key) do update set name = excluded.name, platform = excluded.platform, kinds = excluded.kinds, last_seen_at = now()
        returning *`);
      // A kind turned off loses everything this device stored for it.
      const off = Object.keys(before?.kinds ?? {}).filter((k) => !(k in b.kinds));
      if (off.length && rows[0])
        await tx.execute(
          sql`delete from public.device_readings where source_id = ${rows[0].id}::uuid and kind = any(${`{${off.join(",")}}`}::text[])`,
        );
      return rows;
    });
    return c.json(outSource(s as SourceRow), 200);
  });

  app.openapi(routes.deleteDeviceSource, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const rows = await db.execute(
      sql`delete from public.device_sources where user_id = ${userId}::uuid and device_key = ${key} returning id`,
    );
    if (!rows.length) throw new ApiError(404, "device_not_found", "No such device");
    return c.json({ ok: true }, 200);
  });

  app.openapi(routes.uploadDeviceReadings, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const b = c.req.valid("json");
    const s = await source(userId, key);
    const health = b.readings.some((r) => r.kind === "health");
    const sealWith = health || b.readings.length ? await keyOrg(userId) : null;
    if (health && healthNeedsKey && !sealWith)
      throw new ApiError(
        409,
        "health_needs_encryption",
        "Health data is stored only with encryption at rest on. Turn it on for a workspace you own (Settings → Workspace → Encryption).",
      );
    const extras = new Set((s.kinds.health as { extras?: string[] } | undefined)?.extras ?? []);
    for (const r of b.readings) {
      if (!(r.kind in s.kinds))
        throw new ApiError(400, "kind_off", `${r.kind} is turned off on this device`);
      if (r.kind === "browser_tab" && !BrowserTabSummary.safeParse(r.summary).success)
        throw new ApiError(
          400,
          "bad_browser_tab",
          "Tab reads are the address, title, selection and readable text only",
        );
      if (r.kind === "browser_history" && !BrowserHistorySummary.safeParse(r.summary).success)
        throw new ApiError(
          400,
          "bad_browser_history",
          "History reads are matching pages' addresses, titles and visit times only",
        );
      if (r.kind === "activity" && !ActivitySummary.safeParse(r.summary).success)
        throw new ApiError(
          400,
          "bad_activity_summary",
          "Activity uploads are hourly summaries of app time and window titles only",
        );
      if (r.kind === "health") {
        // Summaries only: anything else (raw samples, unknown fields) is refused.
        const parsed = HealthSummary.safeParse(r.summary);
        if (!parsed.success)
          throw new ApiError(
            400,
            "bad_health_summary",
            `Health uploads are daily or workout summaries: ${parsed.error.issues[0]?.message ?? "invalid"}`,
          );
        // Sensitive extras the person didn't turn on are dropped.
        const v = { ...parsed.data } as Record<string, unknown>;
        for (const k of ["cycle", "glucose", "blood_pressure"]) if (!extras.has(k)) delete v[k];
        r.summary = v;
      }
      if (new Date(r.period_end) < new Date(r.period_start))
        throw new ApiError(400, "bad_period", "period_end is before period_start");
      if (JSON.stringify(r.summary).length > MAX_SUMMARY_BYTES)
        throw new ApiError(400, "summary_too_large", "Each summary must be under 64 KB");
    }
    // "Live only" kinds (retention 0) answer the request without being stored.
    const keep = b.readings.filter(
      (r) =>
        !BROWSER_KINDS.has(r.kind) &&
        (s.kinds[r.kind] as { retention_days?: number } | undefined)?.retention_days !== 0,
    );
    let newSoon: string | null = null;
    for (const r of keep) {
      const [row] = await db.execute<{ inserted: boolean }>(sql`
        insert into public.device_readings (user_id, source_id, kind, period_start, period_end, external_id, summary)
        values (${userId}::uuid, ${s.id}::uuid, ${r.kind}, ${r.period_start}::timestamptz, ${r.period_end}::timestamptz, ${r.external_id}, ${contentKeys.sealJson(sealWith, r.summary)}::jsonb)
        on conflict (source_id, kind, external_id) do update set period_start = excluded.period_start, period_end = excluded.period_end, summary = excluded.summary, collected_at = now()
        returning (xmax = 0) as inserted`);
      const start = Date.parse(r.period_start);
      if (
        r.kind === "calendar" &&
        row?.inserted &&
        start > Date.now() &&
        start - Date.now() < 2 * 86_400_000
      ) {
        const sum = r.summary as { title?: unknown; events?: Array<{ title?: unknown }> };
        const title = sum.events?.[0]?.title ?? sum.title;
        newSoon = `Phone calendar: ${typeof title === "string" && title ? title : "a new event"} at ${new Date(start).toISOString()}`;
      }
    }
    // Proactive bots (D-247): a new event in the next two days on the phone's calendar starts a
    // scan (an app event, so at most every 2 hours, a few a day, on plans with event scans).
    if (newSoon && !b.request_id) {
      const bots = await db.execute<{ bot_id: string }>(sql`
        select bot_id from public.bot_checkins where user_id = ${userId}::uuid and enabled`);
      for (const bot of bots)
        await requestScan(db, bot.bot_id, "event", newSoon).catch(() => false);
    }
    // Health uploads also tell wake-ups and finished workouts (D-151): last night's sleep ending
    // today, and workouts that ended in the last 6 hours (so a backfill doesn't fire old ones).
    const derived: DeviceEvent[] = [];
    for (const r of b.readings.filter((x) => x.kind === "health")) {
      const sm = r.summary as {
        type?: string;
        date?: string;
        sleep?: { end?: string };
        activity?: string;
      };
      const nowMs = Date.now();
      if (
        sm.type === "day" &&
        sm.sleep?.end &&
        Date.parse(r.period_start) <= nowMs &&
        nowMs <= Date.parse(r.period_end)
      )
        derived.push({ id: `wake-${s.id}-${sm.date}`, type: "wake", at: new Date().toISOString() });
      if (sm.type === "workout" && nowMs - Date.parse(r.period_end) < 6 * 3600_000)
        derived.push({
          id: `workout-${s.id}-${r.external_id}`,
          type: "workout_ended",
          at: r.period_end,
          title: sm.activity,
        });
    }
    for (const e of derived)
      for (const runId of await fireDeviceEvent(db, userId, e))
        await deps.workflows.startRun(runId);
    if (b.request_id) {
      const live = b.readings.filter((r) => !keep.includes(r));
      await db.execute(sql`
        update public.device_requests set status = 'done', answered_at = now(),
          result = ${contentKeys.sealJson(sealWith, { stored: keep.length, ...(live.length ? { live } : {}) })}::jsonb
        where id = ${b.request_id}::uuid and user_id = ${userId}::uuid and source_id = ${s.id}::uuid and status = 'pending'`);
    }
    return c.json({ stored: keep.length }, 200);
  });

  app.openapi(routes.listDeviceRequests, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const s = await source(userId, key);
    const rows = await db.execute<{
      id: string;
      source_id: string;
      kind: string;
      action: string;
      params: Record<string, unknown>;
      created_at: Date;
    }>(sql`
      select id, source_id, kind, action, params, created_at from public.device_requests
      where source_id = ${s.id}::uuid and status = 'pending' and created_at > now() - interval '10 minutes' order by created_at`);
    return c.json(
      {
        items: rows.map((r) => ({
          ...r,
          action: r.action as "read",
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });

  app.openapi(routes.answerDeviceRequest, async (c) => {
    const userId = me(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const payload = b.ok ? (b.result ?? {}) : { error: b.error ?? "failed" };
    if (JSON.stringify(payload).length > MAX_SUMMARY_BYTES)
      throw new ApiError(400, "result_too_large", "Results must be under 64 KB");
    // Sealed like readings (locations and live reads are personal; audit 2026-11).
    const rows = await db.execute(sql`
      update public.device_requests set status = ${b.ok ? "done" : "failed"}, answered_at = now(),
        result = ${contentKeys.sealJson(await keyOrg(userId), payload)}::jsonb
      where id = ${id}::uuid and user_id = ${userId}::uuid and status = 'pending' returning id`);
    if (!rows.length)
      throw new ApiError(404, "request_not_found", "No pending request with that id");
    return c.json({ ok: true }, 200);
  });

  app.openapi(routes.listDeviceReadings, async (c) => {
    const userId = me(c.get("claims"));
    const q = c.req.valid("query");
    const rows = await db.execute<{
      id: string;
      source_id: string;
      kind: string;
      period_start: Date;
      period_end: Date;
      external_id: string;
      summary: Record<string, unknown>;
      collected_at: Date;
    }>(sql`
      select id, source_id, kind, period_start, period_end, external_id, summary, collected_at from public.device_readings
      where user_id = ${userId}::uuid ${q.kind ? sql`and kind = ${q.kind}` : sql``} order by period_start desc limit ${q.limit ?? 50}`);
    return c.json(
      {
        items: rows.map((r) => ({
          ...r,
          kind: r.kind as "calendar",
          period_start: iso(r.period_start),
          period_end: iso(r.period_end),
          collected_at: iso(r.collected_at),
        })),
      },
      200,
    );
  });

  app.openapi(routes.listDeviceGrants, async (c) => {
    const userId = me(c.get("claims"));
    const q = c.req.valid("query");
    return c.json({ items: await grants(userId, q.bot_id, q.all_kinds === "true") }, 200);
  });

  app.openapi(routes.setDeviceGrant, async (c) => {
    const claims = c.get("claims");
    const userId = me(claims);
    const b = c.req.valid("json");
    // Only bots the person can use (sharing rules, D-131).
    const [ok] = await withUserSession(db, claims as JwtClaims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.can_access_bot(${b.bot_id}::uuid) as ok`),
    );
    if (!ok?.ok) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (b.allowed)
      await db.execute(
        sql`insert into public.device_grants (user_id, bot_id, kind) values (${userId}::uuid, ${b.bot_id}::uuid, ${b.kind}) on conflict do nothing`,
      );
    else
      await db.execute(
        sql`delete from public.device_grants where user_id = ${userId}::uuid and bot_id = ${b.bot_id}::uuid and kind = ${b.kind}`,
      );
    // Only app builds that know the browser kinds send them, so only they get them back.
    return c.json({ items: await grants(userId, b.bot_id, BROWSER_KINDS.has(b.kind)) }, 200);
  });

  // Device triggers (D-151): events start the person's own routines within seconds.
  app.openapi(routes.reportDeviceEvents, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const b = c.req.valid("json");
    const s = await source(userId, key);
    const sealWith = await keyOrg(userId);
    let runs = 0;
    const picked = ((s.kinds.notifications as { apps?: string[] } | undefined)?.apps ?? []).map(
      (a) => a.toLowerCase(),
    );
    for (const e of b.events) {
      if ((e.type === "arrive" || e.type === "leave") && !e.place)
        throw new ApiError(400, "place_required", "Arrive and leave events need the named place");
      if (e.type === "notification" && !e.app)
        throw new ApiError(400, "app_required", "Notification events need the app");
      if (e.type === "file_added" && (!e.folder || !e.name))
        throw new ApiError(400, "file_required", "File events need the folder and the file name");
      if (e.type === "site_opened" || e.type === "download_done" || e.type === "bookmark_added") {
        if (s.platform !== "web")
          throw new ApiError(400, "browser_only", `${e.type} comes only from Casama for Chrome`);
        if (e.type === "site_opened" && !e.site)
          throw new ApiError(400, "site_required", "site_opened needs the site");
        // Casama's own pages and the off-by-default kinds of site never start routines; the
        // extension doesn't send them either.
        if (e.site) {
          const ok = browserTriggerSite(e.site);
          if ("error" in ok || isCasamaAddress(`https://${e.site}/`)) continue;
          e.site = ok.site;
        }
      }
      // Notifications only from apps the person picked (and only with the kind on): others are dropped.
      if (
        e.type === "notification" &&
        (!("notifications" in s.kinds) ||
          !picked.some((p) => (e.app ?? "").toLowerCase().includes(p)))
      )
        continue;
      // Visits and notifications are kept only when that kind is on (and for its retention).
      if (
        (e.type === "arrive" || e.type === "leave") &&
        "places" in s.kinds &&
        (s.kinds.places as { retention_days?: number }).retention_days !== 0
      ) {
        if (e.type === "arrive")
          await db.execute(sql`
            insert into public.device_readings (user_id, source_id, kind, period_start, period_end, external_id, summary)
            values (${userId}::uuid, ${s.id}::uuid, 'places', ${e.at}::timestamptz, ${e.at}::timestamptz, ${`visit-${e.id}`},
              ${contentKeys.sealJson(sealWith, { place: e.place, arrived_at: e.at, left_at: null })}::jsonb)
            on conflict do nothing`);
        else {
          // Close the latest open visit to that place.
          const open = await db.execute<{
            id: string;
            summary: { place?: string; arrived_at?: string; left_at?: string | null };
          }>(sql`
            select id, summary from public.device_readings where source_id = ${s.id}::uuid and kind = 'places' order by period_start desc limit 20`);
          const v = open.find(
            (o) => o.summary?.place?.toLowerCase() === e.place?.toLowerCase() && !o.summary.left_at,
          );
          if (v)
            await db.execute(sql`update public.device_readings set period_end = ${e.at}::timestamptz,
              summary = ${contentKeys.sealJson(sealWith, { ...v.summary, left_at: e.at })}::jsonb where id = ${v.id}::uuid`);
        }
      }
      if (
        e.type === "notification" &&
        "notifications" in s.kinds &&
        (s.kinds.notifications as { retention_days?: number }).retention_days !== 0
      )
        await db.execute(sql`
          insert into public.device_readings (user_id, source_id, kind, period_start, period_end, external_id, summary)
          values (${userId}::uuid, ${s.id}::uuid, 'notifications', ${e.at}::timestamptz, ${e.at}::timestamptz, ${`notif-${e.id}`},
            ${contentKeys.sealJson(sealWith, { app: e.app, title: e.title ? maskCodes(e.title) : undefined, text: e.text ? maskCodes(e.text) : undefined })}::jsonb)
          on conflict do nothing`);
      for (const runId of await fireDeviceEvent(db, userId, { ...e, id: `${s.id}:${e.id}` })) {
        runs++;
        await deps.workflows.startRun(runId);
      }
    }
    return c.json({ accepted: b.events.length, runs }, 200);
  });

  // E4 (D-323): what the extension listens for, so it reports nothing else.
  app.openapi(routes.listBrowserTriggers, async (c) => {
    const userId = me(c.get("claims"));
    const rows = await db.execute<{
      event: string;
      site: string | null;
      pattern: string | null;
    }>(sql`
      select distinct trigger ->> 'event' as event, trigger ->> 'site' as site, trigger ->> 'pattern' as pattern
      from public.routines where created_by = ${userId}::uuid and enabled and (ends_at is null or ends_at > now())
        and trigger ->> 'type' = 'device' and trigger ->> 'event' in ('site_opened', 'download_done', 'bookmark_added')`);
    return c.json(
      {
        items: rows.map((r) => ({
          event: r.event as "site_opened",
          ...(r.site ? { site: r.site } : {}),
          ...(r.pattern ? { pattern: r.pattern } : {}),
        })),
      },
      200,
    );
  });

  // F3 (D-323): the private model rule for page content, checked by the extension.
  app.openapi(routes.getBotModelPrivacy, async (c) => {
    const claims = c.get("claims");
    me(claims);
    const { id } = c.req.valid("param");
    const [ok] = await withUserSession(db, claims as JwtClaims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.can_access_bot(${id}::uuid) as ok`),
    );
    if (!ok?.ok) throw new ApiError(404, "bot_not_found", "Bot not found");
    return c.json({ private_model: await botModelsPrivate(db, id) }, 200);
  });

  // E3 (D-323): one of the person's own devices (the desktop app's quick ask on Windows and Linux)
  // asks their browser for its tab, through the same requests a bot's fresh read uses.
  app.openapi(routes.createDeviceRequest, async (c) => {
    const userId = me(c.get("claims"));
    const b = c.req.valid("json");
    const [src] = await db.execute<{ id: string; name: string; private_model: boolean }>(sql`
      select id, name, coalesce((kinds -> ${b.kind} ->> 'private_model')::boolean, false) as private_model
      from public.device_sources where user_id = ${userId}::uuid and platform = 'web' and kinds ? ${b.kind}
      order by last_seen_at desc limit 1`);
    if (!src)
      throw new ApiError(
        404,
        "browser_not_found",
        "No browser shares its tab. Turn it on in Casama for Chrome's settings.",
      );
    // The quick ask's bot isn't known here, so a browser kept to private models doesn't answer it.
    if (src.private_model)
      throw new ApiError(
        409,
        "private_model_required",
        "This browser shares its tab only with bots on private models.",
      );
    // The quick ask needs only the address and title: the page's text isn't read.
    const [req] = await db.execute<{ id: string }>(sql`
      insert into public.device_requests (user_id, source_id, kind, action, params)
      values (${userId}::uuid, ${src.id}::uuid, ${b.kind}, 'read', '{"brief":true}'::jsonb) returning id`);
    const until = Date.now() + ASK_BROWSER_MS;
    while (Date.now() < until) {
      await new Promise((r) => setTimeout(r, 250));
      const [r] = await db.execute<{ status: string; result: unknown }>(sql`
        select status, result from public.device_requests where id = ${req!.id}::uuid`);
      if (!r || r.status === "pending") continue;
      // Live only: the answer isn't kept once read.
      await db.execute(
        sql`update public.device_requests set result = null where id = ${req!.id}::uuid`,
      );
      const opened = contentKeys.open(r.result) as {
        live?: Array<{ summary?: unknown }>;
        error?: string;
      } | null;
      const tab = BrowserTabSummary.safeParse(opened?.live?.[0]?.summary);
      if (r.status === "done" && tab.success)
        return c.json({ device: src.name, result: tab.data }, 200);
      throw new ApiError(
        409,
        "browser_offline",
        opened?.error ?? "The browser couldn't read its tab.",
      );
    }
    await db.execute(
      sql`update public.device_requests set status = 'expired' where id = ${req!.id}::uuid and status = 'pending'`,
    );
    throw new ApiError(409, "browser_offline", "The browser didn't answer. Is Chrome open?");
  });

  type PlaceRow = {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    radius_m: number;
    created_at: Date;
  };
  const outPlace = (p: PlaceRow) => ({ ...p, created_at: iso(p.created_at) });
  app.openapi(routes.listDevicePlaces, async (c) => {
    const userId = me(c.get("claims"));
    const rows = await db.execute<PlaceRow>(
      sql`select id, name, latitude, longitude, radius_m, created_at from public.device_places where user_id = ${userId}::uuid order by name`,
    );
    return c.json({ items: rows.map(outPlace) }, 200);
  });
  app.openapi(routes.saveDevicePlace, async (c) => {
    const userId = me(c.get("claims"));
    const b = c.req.valid("json");
    const [existing] = await db.execute<{ id: string }>(
      sql`select id from public.device_places where user_id = ${userId}::uuid and lower(name) = lower(${b.name})`,
    );
    if (!existing) {
      const [n] = await db.execute<{ n: number }>(
        sql`select count(*)::int as n from public.device_places where user_id = ${userId}::uuid`,
      );
      // iOS monitors up to 20 regions per app.
      if ((n?.n ?? 0) >= 20) throw new ApiError(400, "too_many_places", "Up to 20 named places");
    }
    const [p] = existing
      ? await db.execute<PlaceRow>(sql`update public.device_places set name = ${b.name}, latitude = ${b.latitude}, longitude = ${b.longitude}, radius_m = ${b.radius_m ?? 150}
          where id = ${existing.id}::uuid returning id, name, latitude, longitude, radius_m, created_at`)
      : await db.execute<PlaceRow>(sql`insert into public.device_places (user_id, name, latitude, longitude, radius_m)
          values (${userId}::uuid, ${b.name}, ${b.latitude}, ${b.longitude}, ${b.radius_m ?? 150}) returning id, name, latitude, longitude, radius_m, created_at`);
    return c.json(outPlace(p as PlaceRow), 200);
  });
  app.openapi(routes.deleteDevicePlace, async (c) => {
    const userId = me(c.get("claims"));
    const rows = await db.execute(
      sql`delete from public.device_places where id = ${c.req.valid("param").id}::uuid and user_id = ${userId}::uuid returning id`,
    );
    if (!rows.length) throw new ApiError(404, "place_not_found", "No such place");
    return c.json({ ok: true }, 200);
  });
}
