/**
 * Device connections (SPEC: Device connections; D-149). The app registers each device with the
 * kinds the user turned on, uploads summaries, answers fresh-read and write requests, and manages
 * which bots may read which kinds. Everything here is the signed-in person's own data.
 */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { HealthSummary, routes } from "@kasama/contracts";
import { contentKeys, type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const MAX_SUMMARY_BYTES = 64 * 1024;

type SourceRow = { id: string; device_key: string; name: string; platform: string; kinds: Record<string, unknown>; last_seen_at: Date; created_at: Date };
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
    if (!s) throw new ApiError(404, "device_not_found", "This device isn't registered; save it first");
    return s;
  };
  // Health (D-150): sealed with the content key of a workspace the person owns; on Kasama Cloud
  // it isn't stored at all without one.
  const healthNeedsKey = deps.env.HEALTH_REQUIRES_ENCRYPTION === "on" || (deps.env.HEALTH_REQUIRES_ENCRYPTION === "auto" && deps.env.BILLING_ENABLED);
  const keyOrg = async (userId: string) => {
    const owned = await db.execute<{ org_id: string }>(sql`
      select m.org_id from public.memberships m where m.user_id = ${userId}::uuid and m.role = 'owner' order by m.created_at`);
    return owned.map((o) => o.org_id).find((id) => contentKeys.seals(id)) ?? null;
  };
  const grants = async (userId: string, botId?: string) => {
    const rows = await db.execute<{ bot_id: string; bot_name: string; kind: string; created_at: Date }>(sql`
      select g.bot_id, b.name as bot_name, g.kind, g.created_at from public.device_grants g join public.bots b on b.id = g.bot_id
      where g.user_id = ${userId}::uuid ${botId ? sql`and g.bot_id = ${botId}::uuid` : sql``} order by b.name, g.kind`);
    return rows.map((g) => ({ ...g, kind: g.kind as "calendar", created_at: iso(g.created_at) }));
  };

  app.openapi(routes.listDeviceSources, async (c) => {
    const userId = me(c.get("claims"));
    const rows = await db.execute<SourceRow>(sql`select * from public.device_sources where user_id = ${userId}::uuid order by created_at`);
    return c.json({ items: rows.map(outSource) }, 200);
  });

  app.openapi(routes.saveDeviceSource, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const b = c.req.valid("json");
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
        await tx.execute(sql`delete from public.device_readings where source_id = ${rows[0].id}::uuid and kind = any(${`{${off.join(",")}}`}::text[])`);
      return rows;
    });
    return c.json(outSource(s as SourceRow), 200);
  });

  app.openapi(routes.deleteDeviceSource, async (c) => {
    const userId = me(c.get("claims"));
    const { key } = c.req.valid("param");
    const rows = await db.execute(sql`delete from public.device_sources where user_id = ${userId}::uuid and device_key = ${key} returning id`);
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
      throw new ApiError(409, "health_needs_encryption", "Health data is stored only with encryption at rest on. Turn it on for a workspace you own (Settings → Workspace → Encryption).");
    const extras = new Set((s.kinds.health as { extras?: string[] } | undefined)?.extras ?? []);
    for (const r of b.readings) {
      if (!(r.kind in s.kinds)) throw new ApiError(400, "kind_off", `${r.kind} is turned off on this device`);
      if (r.kind === "health") {
        // Summaries only: anything else (raw samples, unknown fields) is refused.
        const parsed = HealthSummary.safeParse(r.summary);
        if (!parsed.success) throw new ApiError(400, "bad_health_summary", `Health uploads are daily or workout summaries: ${parsed.error.issues[0]?.message ?? "invalid"}`);
        // Sensitive extras the person didn't turn on are dropped.
        const v = { ...parsed.data } as Record<string, unknown>;
        for (const k of ["cycle", "glucose", "blood_pressure"]) if (!extras.has(k)) delete v[k];
        r.summary = v;
      }
      if (new Date(r.period_end) < new Date(r.period_start)) throw new ApiError(400, "bad_period", "period_end is before period_start");
      if (JSON.stringify(r.summary).length > MAX_SUMMARY_BYTES) throw new ApiError(400, "summary_too_large", "Each summary must be under 64 KB");
    }
    // "Live only" kinds (retention 0) answer the request without being stored.
    const keep = b.readings.filter((r) => (s.kinds[r.kind] as { retention_days?: number } | undefined)?.retention_days !== 0);
    for (const r of keep)
      await db.execute(sql`
        insert into public.device_readings (user_id, source_id, kind, period_start, period_end, external_id, summary)
        values (${userId}::uuid, ${s.id}::uuid, ${r.kind}, ${r.period_start}::timestamptz, ${r.period_end}::timestamptz, ${r.external_id}, ${contentKeys.sealJson(sealWith, r.summary)}::jsonb)
        on conflict (source_id, kind, external_id) do update set period_start = excluded.period_start, period_end = excluded.period_end, summary = excluded.summary, collected_at = now()`);
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
    const rows = await db.execute<{ id: string; source_id: string; kind: string; action: string; params: Record<string, unknown>; created_at: Date }>(sql`
      select id, source_id, kind, action, params, created_at from public.device_requests
      where source_id = ${s.id}::uuid and status = 'pending' and created_at > now() - interval '10 minutes' order by created_at`);
    return c.json({ items: rows.map((r) => ({ ...r, action: r.action as "read", created_at: iso(r.created_at) })) }, 200);
  });

  app.openapi(routes.answerDeviceRequest, async (c) => {
    const userId = me(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const rows = await db.execute(sql`
      update public.device_requests set status = ${b.ok ? "done" : "failed"}, answered_at = now(),
        result = ${JSON.stringify(b.ok ? (b.result ?? {}) : { error: b.error ?? "failed" })}::jsonb
      where id = ${id}::uuid and user_id = ${userId}::uuid and status = 'pending' returning id`);
    if (!rows.length) throw new ApiError(404, "request_not_found", "No pending request with that id");
    return c.json({ ok: true }, 200);
  });

  app.openapi(routes.listDeviceReadings, async (c) => {
    const userId = me(c.get("claims"));
    const q = c.req.valid("query");
    const rows = await db.execute<{ id: string; source_id: string; kind: string; period_start: Date; period_end: Date; external_id: string; summary: Record<string, unknown>; collected_at: Date }>(sql`
      select id, source_id, kind, period_start, period_end, external_id, summary, collected_at from public.device_readings
      where user_id = ${userId}::uuid ${q.kind ? sql`and kind = ${q.kind}` : sql``} order by period_start desc limit ${q.limit ?? 50}`);
    return c.json(
      { items: rows.map((r) => ({ ...r, kind: r.kind as "calendar", period_start: iso(r.period_start), period_end: iso(r.period_end), collected_at: iso(r.collected_at) })) },
      200,
    );
  });

  app.openapi(routes.listDeviceGrants, async (c) => {
    const userId = me(c.get("claims"));
    return c.json({ items: await grants(userId, c.req.valid("query").bot_id) }, 200);
  });

  app.openapi(routes.setDeviceGrant, async (c) => {
    const claims = c.get("claims");
    const userId = me(claims);
    const b = c.req.valid("json");
    // Only bots the person can use (sharing rules, D-131).
    const [ok] = await withUserSession(db, claims as JwtClaims, (tx) => tx.execute<{ ok: boolean }>(sql`select public.can_access_bot(${b.bot_id}::uuid) as ok`));
    if (!ok?.ok) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (b.allowed)
      await db.execute(sql`insert into public.device_grants (user_id, bot_id, kind) values (${userId}::uuid, ${b.bot_id}::uuid, ${b.kind}) on conflict do nothing`);
    else await db.execute(sql`delete from public.device_grants where user_id = ${userId}::uuid and bot_id = ${b.bot_id}::uuid and kind = ${b.kind}`);
    return c.json({ items: await grants(userId, b.bot_id) }, 200);
  });
}
