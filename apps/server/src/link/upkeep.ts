/**
 * Casama Link's hourly upkeep on the cloud (D-296).
 *
 * Parks the tunnels of servers that stopped checking in (when parking is on), finishes removals
 * that failed, forgets addresses nobody came back for, and warns the instance owners before the
 * tunnel provider's included amounts run out. Cloudflare includes 1,000 tunnels an account and
 * charges for each one past that, idle ones too, and a zone holds a set number of DNS records
 * (two per server). The warning comes early enough to act: buy more, move the zone up a plan, or
 * turn parking on.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { LinkServers, SweepReport } from "./servers.ts";

export interface LinkUpkeepOptions {
  db: Database;
  servers: LinkServers;
  parking: "off" | "dry-run" | "on";
  /** Tunnels at which the owners are warned (the provider includes 1,000). */
  tunnelAlert: number;
  /** DNS records the address zone holds on its plan; the owners are warned at three quarters. */
  recordLimit: number;
  /** Comma-separated emails; when empty, the first account. */
  adminEmails?: string;
  log?: { info(msg: string, data?: Record<string, unknown>): void };
}

export interface LinkUpkeepReport {
  sweep: SweepReport;
  tunnels: number | null;
  warned: boolean;
}

export async function linkUpkeep(o: LinkUpkeepOptions): Promise<LinkUpkeepReport> {
  const sweep = await o.servers.sweep(o.parking);
  const tunnels = await o.servers.tunnelCount();
  let warned = false;
  if (tunnels != null) {
    const records = tunnels * 2;
    const nearTunnels = tunnels >= o.tunnelAlert;
    const nearRecords = records >= Math.floor(o.recordLimit * 0.75);
    if (nearTunnels || nearRecords) {
      const body = nearTunnels
        ? `${tunnels} tunnels are in use. Cloudflare includes 1,000 and charges for each one past that. Turn parking on (CASAMA_LINK_PARKING), or buy more before the line.`
        : `About ${records} DNS records are in use on the address zone, which holds ${o.recordLimit} on its plan. Move the zone up a plan before new servers stop getting addresses.`;
      warned = await warnOwners(o, body);
    }
  }
  if (sweep.parked || sweep.removed || sweep.forgotten || sweep.failed || warned)
    o.log?.info("casama link upkeep", { ...sweep, tunnels, warned });
  return { sweep, tunnels, warned };
}

/** One notice a day to the instance owners, in their inbox. */
async function warnOwners(o: LinkUpkeepOptions, body: string) {
  const [recent] = await o.db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.notifications
    where kind = 'link_capacity' and created_at > now() - interval '1 day'`);
  if ((recent?.n ?? 0) > 0) return false;
  const admins = (o.adminEmails ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  const payload = JSON.stringify({
    title: "Casama Link is close to a limit",
    body,
    link: "/settings/admin",
  });
  const rows = admins.length
    ? await o.db.execute<{ id: string }>(sql`
        insert into public.notifications (user_id, kind, payload)
        select u.id, 'link_capacity', ${payload}::jsonb
        from auth.users u where lower(u.email) = any(${admins}) returning id`)
    : await o.db.execute<{ id: string }>(sql`
        insert into public.notifications (user_id, kind, payload)
        select u.id, 'link_capacity', ${payload}::jsonb
        from auth.users u order by u.created_at limit 1 returning id`);
  return rows.length > 0;
}
