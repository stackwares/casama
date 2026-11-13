/**
 * Server capacity (D-252): how full the host is, how much of the computer memory budget hosted
 * computers take, when it will run out, and alerts to the instance owner before and when it does.
 *
 * The worker samples every 5 minutes. Memory and disk are read from the host's /proc and root
 * filesystem, which a container sees unless something like lxcfs hides them.
 */
import { readFile, statfs } from "node:fs/promises";
import { freemem, loadavg, cpus as osCpus, totalmem } from "node:os";
import type { NotificationService } from "@casama/agent";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { EmailSender } from "./email.ts";

export const SAMPLE_INTERVAL_MS = 5 * 60_000;
/** Early warning: computer memory over this share of the budget... */
export const EARLY_SHARE = 0.6;
/** ...at its daily peak on this many days of the last 7. */
export const EARLY_DAYS = 3;
/** Health: free host memory under this for 10 minutes (three samples in a row). */
export const LOW_MEMORY_MB = 1536;
export const DISK_PCT = 80;
const KEEP_DAYS = 90;

export type AlertKind = "early_warning" | "capacity_full" | "low_memory" | "disk";

export interface HostSample {
  mem_total_mb: number;
  mem_available_mb: number;
  load1: number;
  cpus: number;
  disk_used_pct: number | null;
}

/** Memory, load and root-disk use of the machine this process runs on. */
export async function sampleHost(): Promise<HostSample> {
  let total = totalmem();
  let available = freemem();
  const info = await readFile("/proc/meminfo", "utf8").catch(() => "");
  const kb = (key: string) => {
    const m = info.match(new RegExp(`^${key}:\\s+(\\d+) kB`, "m"));
    return m ? Number(m[1]) * 1024 : null;
  };
  total = kb("MemTotal") ?? total;
  available = kb("MemAvailable") ?? available;
  const disk = await statfs("/").catch(() => null);
  return {
    mem_total_mb: Math.round(total / 2 ** 20),
    mem_available_mb: Math.round(available / 2 ** 20),
    load1: Math.round((loadavg()[0] ?? 0) * 100) / 100,
    cpus: osCpus().length,
    disk_used_pct:
      disk && disk.blocks > 0 ? Math.round((1 - disk.bavail / disk.blocks) * 10_000) / 100 : null,
  };
}

/** Saves one sample: the host, plus hosted computers that are up and the memory they may use. */
export async function recordSample(db: Database, budgetMb: number, host?: HostSample) {
  const h = host ?? (await sampleHost());
  const [c] = await db.execute<{ n: number; mb: number }>(sql`
    select count(*)::int as n, coalesce(sum(coalesce((size ->> 'memory_mb')::int, 1024)), 0)::int as mb
    from public.computers
    where kind <> 'local' and state in ('provisioning', 'starting', 'running', 'idle')`);
  await db.execute(sql`
    insert into public.capacity_samples (mem_total_mb, mem_available_mb, load1, cpus, disk_used_pct,
      computers_running, computers_mem_mb, budget_mb)
    values (${h.mem_total_mb}, ${h.mem_available_mb}, ${h.load1}, ${h.cpus}, ${h.disk_used_pct},
      ${c?.n ?? 0}, ${c?.mb ?? 0}, ${budgetMb})
    on conflict (at) do nothing`);
  await db.execute(
    sql`delete from public.capacity_samples where at < now() - (${KEEP_DAYS} * interval '1 day')`,
  );
  return { ...h, computers_running: c?.n ?? 0, computers_mem_mb: c?.mb ?? 0 };
}

/** A computer start refused because the server is out of room. */
export async function recordCapacityFull(
  db: Database,
  e: { orgId?: string | null; computerId?: string | null; detail?: Record<string, unknown> },
) {
  await db
    .execute(sql`
      insert into public.capacity_events (kind, org_id, computer_id, detail)
      values ('capacity_full', ${e.orgId ?? null}::uuid, ${e.computerId ?? null}::uuid,
        ${JSON.stringify(e.detail ?? {})}::jsonb)`)
    .catch(() => undefined);
}

export interface CapacityAlert {
  kind: AlertKind;
  title: string;
  body: string;
}

/** The alerts that are due now. Each kind is claimed for the day, so it goes out once a day. */
export async function dueAlerts(db: Database, budgetMb: number): Promise<CapacityAlert[]> {
  const out: CapacityAlert[] = [];
  if (budgetMb > 0) {
    const [early] = await db.execute<{ days: number; peak: number }>(sql`
      select count(*)::int as days, coalesce(max(peak), 0)::int as peak from (
        select date_trunc('day', at) as d, max(computers_mem_mb) as peak from public.capacity_samples
        where at > now() - interval '7 days' group by 1
      ) x where peak > ${budgetMb * EARLY_SHARE}::numeric`);
    if ((early?.days ?? 0) >= EARLY_DAYS)
      out.push({
        kind: "early_warning",
        title: "Order the bigger server",
        body: `Computers used over ${Math.round(EARLY_SHARE * 100)}% of the server's ${gb(budgetMb)} on ${early?.days} of the last 7 days (peak ${gb(early?.peak ?? 0)}). Order the next server before starts are refused.`,
      });
  }
  const [full] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.capacity_events
    where kind = 'capacity_full' and at > now() - interval '1 day'`);
  if ((full?.n ?? 0) > 0)
    out.push({
      kind: "capacity_full",
      title: "Computers are being refused",
      body: `The server ran out of room for computers ${full?.n} time${full?.n === 1 ? "" : "s"} in the last day. Add a server or lower plan limits now.`,
    });
  const recent = await db.execute<{ avail: number; disk: string | null; at: Date }>(sql`
    select mem_available_mb as avail, disk_used_pct::text as disk, at from public.capacity_samples
    where at > now() - interval '16 minutes' order by at desc limit 3`);
  if (recent.length >= 3 && recent.every((r) => r.avail < LOW_MEMORY_MB))
    out.push({
      kind: "low_memory",
      title: "The server is low on memory",
      body: `Free memory has been under ${(LOW_MEMORY_MB / 1024).toFixed(1)} GB for 10 minutes (now ${gb(recent[0]?.avail ?? 0)}). The API and database may slow down or restart.`,
    });
  const disk = Number(recent[0]?.disk ?? Number.NaN);
  if (disk > DISK_PCT)
    out.push({
      kind: "disk",
      title: "The server's disk is filling up",
      body: `The disk is ${Math.round(disk)}% full. Clear old snapshots and backups or add space.`,
    });
  const claimed: CapacityAlert[] = [];
  for (const a of out) {
    const [row] = await db.execute<{ kind: string }>(sql`
      insert into public.capacity_alerts (kind, day, detail) values (${a.kind}, current_date, ${JSON.stringify({ body: a.body })}::jsonb)
      on conflict do nothing returning kind`);
    if (row) claimed.push(a);
  }
  return claimed;
}

/** The people who run this server: INSTANCE_ADMIN_EMAILS, or the first account. */
export async function instanceOwners(db: Database, adminEmails?: string) {
  const list = (adminEmails ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  return db.execute<{ id: string; email: string | null }>(
    list.length
      ? sql`select id, email from auth.users where lower(email) = any(${list})`
      : sql`select id, email from auth.users order by created_at limit 1`,
  );
}

export interface CapacityReport {
  budget_mb: number;
  latest: (HostSample & { at: string; computers_running: number; computers_mem_mb: number }) | null;
  /** One row per day for the last 30 days that have samples: the peaks. */
  days: Array<{
    day: string;
    peak_computers_mem_mb: number;
    peak_computers: number;
    min_available_mb: number;
    peak_load1: number;
  }>;
  refusals_30d: number;
  /** When daily peaks reach the budget at the 30-day trend; null without a budget or growth. */
  full_in_weeks: number | null;
  alerts: Array<{ kind: AlertKind; day: string; body: string }>;
}

export async function capacityReport(db: Database, budgetMb: number): Promise<CapacityReport> {
  const [latest] = await db.execute<{
    at: Date;
    mem_total_mb: number;
    mem_available_mb: number;
    load1: string;
    cpus: number;
    disk_used_pct: string | null;
    computers_running: number;
    computers_mem_mb: number;
  }>(sql`select * from public.capacity_samples order by at desc limit 1`);
  const days = await db.execute<{
    day: string;
    peak_mem: number;
    peak_n: number;
    min_avail: number;
    peak_load: string;
  }>(sql`
    select to_char(date_trunc('day', at), 'YYYY-MM-DD') as day, max(computers_mem_mb)::int as peak_mem,
           max(computers_running)::int as peak_n, min(mem_available_mb)::int as min_avail,
           max(load1)::text as peak_load
    from public.capacity_samples where at > now() - interval '30 days' group by 1 order by 1`);
  const [ref] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.capacity_events
    where kind = 'capacity_full' and at > now() - interval '30 days'`);
  const alerts = await db.execute<{ kind: AlertKind; day: string; body: string | null }>(sql`
    select kind, to_char(day, 'YYYY-MM-DD') as day, detail ->> 'body' as body from public.capacity_alerts
    where day > current_date - 30 order by day desc, kind limit 20`);
  const rows = days.map((d) => ({
    day: d.day,
    peak_computers_mem_mb: d.peak_mem,
    peak_computers: d.peak_n,
    min_available_mb: d.min_avail,
    peak_load1: Number(d.peak_load),
  }));
  return {
    budget_mb: budgetMb,
    latest: latest
      ? {
          at: new Date(latest.at).toISOString(),
          mem_total_mb: latest.mem_total_mb,
          mem_available_mb: latest.mem_available_mb,
          load1: Number(latest.load1),
          cpus: latest.cpus,
          disk_used_pct: latest.disk_used_pct == null ? null : Number(latest.disk_used_pct),
          computers_running: latest.computers_running,
          computers_mem_mb: latest.computers_mem_mb,
        }
      : null,
    days: rows,
    refusals_30d: ref?.n ?? 0,
    full_in_weeks: forecastWeeks(
      rows.map((r) => r.peak_computers_mem_mb),
      budgetMb,
    ),
    alerts: alerts.map((a) => ({ kind: a.kind, day: a.day, body: a.body ?? "" })),
  };
}

/**
 * Weeks until daily peaks reach the budget, by a least-squares line through them (one point per
 * day). Null without a budget, with under 7 days of data, or when peaks aren't growing; 0 when
 * the latest trend value is already at the budget.
 */
export function forecastWeeks(peaks: number[], budgetMb: number): number | null {
  if (!(budgetMb > 0) || peaks.length < 7) return null;
  const n = peaks.length;
  const mx = (n - 1) / 2;
  const my = peaks.reduce((a, b) => a + b, 0) / n;
  let num = 0;
  let den = 0;
  peaks.forEach((y, x) => {
    num += (x - mx) * (y - my);
    den += (x - mx) ** 2;
  });
  const slope = den ? num / den : 0;
  const now = my + slope * (n - 1 - mx);
  if (now >= budgetMb) return 0;
  if (slope <= 0) return null;
  return Math.round(((budgetMb - now) / slope / 7) * 10) / 10;
}

const gb = (mb: number) => `${(mb / 1024).toFixed(1)} GB`;

/**
 * Samples every 5 minutes and sends due alerts to the instance owners: an inbox row with a push,
 * and an email when email is set up. Returns a stop function.
 */
export function startCapacityMonitor(opts: {
  db: Database;
  budgetMb: number;
  adminEmails?: string;
  notifications?: NotificationService;
  email?: EmailSender;
  log?: (msg: string, extra?: Record<string, unknown>) => void;
  intervalMs?: number;
}) {
  const tick = async () => {
    try {
      await recordSample(opts.db, opts.budgetMb);
      const alerts = await dueAlerts(opts.db, opts.budgetMb);
      if (!alerts.length) return;
      const owners = await instanceOwners(opts.db, opts.adminEmails);
      for (const a of alerts)
        for (const o of owners) {
          await opts.notifications
            ?.notify(o.id, null, "server_capacity", {
              title: a.title,
              body: a.body,
              link: "/settings/admin",
              urgent: a.kind !== "early_warning",
            })
            .catch(() => undefined);
          if (o.email && opts.email?.enabled)
            await opts.email
              .send({
                to: o.email,
                subject: `Casama server: ${a.title}`,
                text: `${a.body}\n\nSee Settings > Admin > Server capacity.`,
              })
              .catch(() => undefined);
        }
      opts.log?.("capacity alerts sent", { kinds: alerts.map((a) => a.kind) });
    } catch (err) {
      opts.log?.("capacity sample failed", { error: (err as Error).message });
    }
  };
  const first = setTimeout(tick, 30_000);
  const timer = setInterval(tick, opts.intervalMs ?? SAMPLE_INTERVAL_MS);
  first.unref?.();
  timer.unref?.();
  return async () => {
    clearTimeout(first);
    clearInterval(timer);
  };
}
