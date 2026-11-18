/**
 * Opt-in anonymous telemetry (D-074). Off unless TELEMETRY=on. Once a week a self-hosted instance
 * sends a random instance id, its version, and two counts (bots and users active in the last
 * 7 days). Nothing else: no names, emails, content, IP-derived data or keys.
 */
import { randomUUID } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

export async function telemetryPayload(db: Database, version: string) {
  const [s] = await db.execute<{ value: { id: string } }>(
    sql`select value from public.instance_settings where key = 'instance_id'`,
  );
  let id = s?.value?.id;
  if (!id) {
    id = randomUUID();
    await db.execute(sql`
      insert into public.instance_settings (key, value) values ('instance_id', ${JSON.stringify({ id })}::jsonb)
      on conflict (key) do nothing`);
    const [again] = await db.execute<{ value: { id: string } }>(
      sql`select value from public.instance_settings where key = 'instance_id'`,
    );
    id = again?.value.id ?? id;
  }
  const [c] = await db.execute<{ bots: number; users: number }>(sql`
    select count(distinct bot_id)::int as bots, count(distinct created_by)::int as users
    from public.runs where created_at > now() - interval '7 days'`);
  return {
    instance_id: id,
    version,
    weekly_active_bots: c?.bots ?? 0,
    weekly_active_users: c?.users ?? 0,
  };
}

export async function sendTelemetry(db: Database, url: string, version: string, f = fetch) {
  const body = await telemetryPayload(db, version);
  const res = await f(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(10_000),
  });
  return { ok: res.ok, body };
}
