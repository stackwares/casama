/**
 * App events start check-in scans (D-247). When a workspace's managed Composio connection has
 * Gmail, Google Calendar or Outlook, the worker subscribes Composio triggers for them; Composio
 * posts each event to /hooks/composio, and the bots that check in for that workspace scan within
 * minutes instead of waiting for their next scheduled scan. The event itself is never handed to a
 * model: it only says "look now", and the scan reads the app through its normal tools.
 *
 * Composio REST v3: POST /api/v3/trigger_instances/{slug}/upsert ({user_id, trigger_config}).
 * Webhooks are signed like Standard Webhooks but keyed with the secret's raw UTF-8 bytes:
 * base64(HMAC-SHA256(secret, `${webhook-id}.${webhook-timestamp}.${body}`)), sent as "v1,<sig>".
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { requestScan } from "./checkins.ts";
import { loadIntegration } from "./integrations.ts";

/** The triggers each toolkit gets: new mail, and calendar changes. */
export const COMPOSIO_TRIGGERS: Record<string, string[]> = {
  gmail: ["GMAIL_NEW_GMAIL_MESSAGE"],
  googlecalendar: [
    "GOOGLECALENDAR_GOOGLE_CALENDAR_EVENT_CREATED_TRIGGER",
    "GOOGLECALENDAR_GOOGLE_CALENDAR_EVENT_UPDATED_TRIGGER",
  ],
  outlook: ["OUTLOOK_MESSAGE_TRIGGER"],
};

/** A failed subscription is tried again after this long. */
const RETRY_MS = 24 * 3600_000;

type ManagedRow = {
  id: string;
  org_id: string;
  config: {
    toolkits?: unknown;
    triggers?: Record<string, string>;
    trigger_errors?: Record<string, string>;
    user_id?: string;
    base_url?: string;
  };
};

/**
 * Subscribes the triggers still missing on managed Composio connections in workspaces where a
 * bot checks in. Trigger ids are kept in config.triggers; failures in config.trigger_errors.
 */
export async function syncComposioTriggers(
  db: Database,
  fetchImpl: typeof fetch = fetch,
  limit = 20,
  now = new Date(),
) {
  const rows = await db.execute<ManagedRow>(sql`
    select i.id, i.org_id, i.config from public.integrations i
    where i.kind = 'composio' and i.config ->> 'managed' = 'true' and i.status = 'ok'
      and jsonb_typeof(i.config -> 'toolkits') = 'array'
      and exists (select 1 from public.bot_checkins ck where ck.org_id = i.org_id and ck.enabled)
    order by i.created_at limit 500`);
  let made = 0;
  for (const row of rows) {
    if (made >= limit) break;
    const toolkits = (row.config.toolkits as unknown[]).filter(
      (t): t is string => typeof t === "string",
    );
    const missing = toolkits
      .flatMap((t) => COMPOSIO_TRIGGERS[t] ?? [])
      .filter((slug) => !row.config.triggers?.[slug])
      .filter((slug) => {
        const failed = row.config.trigger_errors?.[slug];
        return !failed || now.getTime() - new Date(failed).getTime() > RETRY_MS;
      });
    if (!missing.length) continue;
    const rec = await loadIntegration(db, row.id, fetchImpl);
    if (!rec?.secret) continue;
    const base = (row.config.base_url ?? "https://backend.composio.dev").replace(/\/$/, "");
    const userId = row.config.user_id ?? row.org_id;
    for (const slug of missing) {
      made++;
      let triggerId: string | null = null;
      try {
        const res = await fetchImpl(
          `${base}/api/v3/trigger_instances/${encodeURIComponent(slug)}/upsert`,
          {
            method: "POST",
            headers: { "x-api-key": rec.secret, "content-type": "application/json" },
            body: JSON.stringify({ user_id: userId, trigger_config: {} }),
          },
        );
        const json = (await res.json().catch(() => ({}))) as { trigger_id?: unknown };
        if (res.ok && typeof json.trigger_id === "string") triggerId = json.trigger_id;
      } catch {
        triggerId = null;
      }
      // Updating config alone never counts as a new connection (scan_on_new_connection).
      await db.execute(
        triggerId
          ? sql`update public.integrations set config = jsonb_set(
                  jsonb_set(config, '{triggers}', coalesce(config -> 'triggers', '{}'::jsonb)),
                  array['triggers', ${slug}], to_jsonb(${triggerId}::text))
                where id = ${row.id}::uuid`
          : sql`update public.integrations set config = jsonb_set(
                  jsonb_set(config, '{trigger_errors}', coalesce(config -> 'trigger_errors', '{}'::jsonb)),
                  array['trigger_errors', ${slug}], to_jsonb(${now.toISOString()}::text))
                where id = ${row.id}::uuid`,
      );
    }
  }
  // Nobody in the workspace checks in any more: remove its triggers, so Composio stops polling
  // and posting events nobody reads.
  const idle = await db.execute<ManagedRow>(sql`
    select i.id, i.org_id, i.config from public.integrations i
    where i.kind = 'composio' and i.config ->> 'managed' = 'true'
      and coalesce(i.config -> 'triggers', '{}'::jsonb) <> '{}'::jsonb
      and not exists (select 1 from public.bot_checkins ck where ck.org_id = i.org_id and ck.enabled)
    order by i.created_at limit ${limit}`);
  for (const row of idle) {
    const rec = await loadIntegration(db, row.id, fetchImpl);
    if (!rec?.secret) continue;
    const base = (row.config.base_url ?? "https://backend.composio.dev").replace(/\/$/, "");
    for (const [slug, id] of Object.entries(row.config.triggers ?? {})) {
      const res = await fetchImpl(
        `${base}/api/v3/trigger_instances/manage/${encodeURIComponent(id)}`,
        { method: "DELETE", headers: { "x-api-key": rec.secret } },
      ).catch(() => null);
      // Gone already (404, 409, 410) counts as removed; anything else is tried again next time.
      if (!res || (!res.ok && ![404, 409, 410].includes(res.status))) continue;
      await db.execute(sql`
        update public.integrations set config = config #- array['triggers', ${slug}] where id = ${row.id}::uuid`);
    }
  }
  return made;
}

/** Checks a Composio webhook signature; tolerance in seconds (0 turns the time check off). */
export function verifyComposioSignature(
  secret: string,
  headers: { id?: string; timestamp?: string; signature?: string },
  body: string,
  toleranceS = 300,
  now = Date.now(),
) {
  const { id, timestamp, signature } = headers;
  if (!id || !timestamp || !signature) return false;
  const ts = Number(timestamp);
  if (!Number.isFinite(ts)) return false;
  if (toleranceS > 0 && Math.abs(now / 1000 - ts) > toleranceS) return false;
  const expected = Buffer.from(
    createHmac("sha256", secret).update(`${id}.${timestamp}.${body}`).digest("base64"),
  );
  return signature.split(" ").some((part) => {
    const [version, sig] = part.split(",", 2);
    if (version !== "v1" || !sig) return false;
    const got = Buffer.from(sig);
    return got.length === expected.length && timingSafeEqual(got, expected);
  });
}

/** Who an event is for: V3 (metadata), V2 (data) and V1 payloads. */
function eventTarget(p: Record<string, unknown>) {
  const meta = (p.metadata ?? {}) as Record<string, unknown>;
  const data = (p.data ?? {}) as Record<string, unknown>;
  const s = (v: unknown) => (typeof v === "string" && v ? v : null);
  if (
    typeof p.type === "string" &&
    p.type.startsWith("composio.") &&
    p.type !== "composio.trigger.message"
  )
    return null;
  return {
    userId: s(meta.user_id) ?? s(data.user_id) ?? null,
    triggerId: s(meta.trigger_id) ?? s(data.trigger_id) ?? s(p.trigger_id) ?? null,
  };
}

/**
 * A Composio event: verified, matched to the workspace whose connection it came from (by its
 * Composio user id and the trigger id we stored), then a scan request for each bot there that
 * checks in. Returns how many bots will look.
 */
export async function handleComposioEvent(
  db: Database,
  secret: string,
  headers: { id?: string; timestamp?: string; signature?: string },
  body: string,
): Promise<{ ok: boolean; reason?: string; scans?: number }> {
  if (!verifyComposioSignature(secret, headers, body))
    return { ok: false, reason: "bad_signature" };
  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(body) as Record<string, unknown>;
  } catch {
    return { ok: false, reason: "bad_json" };
  }
  const target = eventTarget(payload);
  if (!target?.userId && !target?.triggerId) return { ok: true, scans: 0 };
  const isUuid = (v: string | null) =>
    !!v && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
  const [integration] = await db.execute<{ id: string; org_id: string }>(sql`
    select i.id, i.org_id from public.integrations i
    where i.kind = 'composio' and i.config ->> 'managed' = 'true'
      and (
        (${target.triggerId}::text is not null and exists (
          select 1 from jsonb_each_text(coalesce(i.config -> 'triggers', '{}'::jsonb)) t where t.value = ${target.triggerId}::text))
        or (${target.userId}::text is not null and (
          i.config ->> 'user_id' = ${target.userId}::text
          or (i.config ->> 'user_id' is null and ${isUuid(target.userId)}::boolean and i.org_id::text = ${target.userId}::text)))
      )
    limit 1`);
  if (!integration) return { ok: true, scans: 0 };
  const bots = await db.execute<{ bot_id: string }>(sql`
    select ck.bot_id from public.bot_checkins ck
    where ck.org_id = ${integration.org_id}::uuid and ck.enabled
      and (exists (select 1 from public.bot_integrations bi where bi.bot_id = ck.bot_id and bi.integration_id = ${integration.id}::uuid)
           or not exists (select 1 from public.bot_integrations bi where bi.integration_id = ${integration.id}::uuid))`);
  let scans = 0;
  for (const b of bots) if (await requestScan(db, b.bot_id, "event")) scans++;
  return { ok: true, scans };
}
