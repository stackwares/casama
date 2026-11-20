import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { Env } from "../../env.ts";
import { type Reading, readBalance, readUsage } from "./readers.ts";
import { balanceStatus, quotaStatus } from "./status.ts";

export type VendorSettings = import("zod").infer<typeof import("@casama/contracts").VendorSettings>;
export type VendorCheck = import("zod").infer<typeof import("@casama/contracts").VendorReading>;
export type Vendor = import("zod").infer<typeof import("@casama/contracts").AdminVendor>;
const iso = (v: unknown): string | null => (v == null ? null : new Date(String(v)).toISOString());
const num = (v: unknown): number | null => (v == null ? null : Number(v));
export async function listVendors(db: Database): Promise<Vendor[]> {
  const limits = await db.execute(sql`select * from public.vendor_limits order by label`);
  const checks = await db.execute(
    sql`select * from public.vendor_checks where checked_at >= now() - interval '90 days' order by checked_at desc, id desc`,
  );
  return limits.map((l) => {
    const history = checks
      .filter((c) => c.vendor === l.vendor)
      .map((c) => ({
        checked_at: iso(c.checked_at)!,
        used: num(c.used),
        remaining: num(c.remaining),
        limit_value: num(c.limit_value),
        resets_at: iso(c.resets_at),
        status: c.status as VendorCheck["status"],
        source: c.source as VendorCheck["source"],
        error: c.error as string | null,
      }));
    return {
      vendor: String(l.vendor),
      label: String(l.label),
      kind: l.kind as Vendor["kind"],
      unit: String(l.unit),
      limit_value: num(l.limit_value),
      period: l.period as Vendor["period"],
      period_start: iso(l.period_start),
      expires_at: iso(l.expires_at),
      warn_at: Number(l.warn_at),
      enabled: Boolean(l.enabled),
      balance_warn_below: Number(l.balance_warn_below),
      billing_url: l.billing_url as string | null,
      impact: l.impact as string | null,
      latest: history[0] ?? null,
      history,
    };
  });
}
export async function updateVendor(
  db: Database,
  vendor: string,
  p: VendorSettings,
): Promise<boolean> {
  const rows =
    await db.execute(sql`update public.vendor_limits set limit_value=${p.limit_value}, period=${p.period},
    period_start=${p.period_start}::timestamptz, expires_at=${p.expires_at}::timestamptz,
    warn_at=${p.warn_at}, balance_warn_below=${p.balance_warn_below}, enabled=${p.enabled} where vendor=${vendor} returning vendor`);
  return rows.length > 0;
}
export async function checkVendor(
  db: Database,
  env: Env,
  vendor: string,
  opts: { fetch?: typeof fetch; now?: Date } = {},
): Promise<Vendor | null> {
  const [l] = await db.execute(sql`select * from public.vendor_limits where vendor=${vendor}`);
  if (!l) return null;
  const now = opts.now ?? new Date();
  let reading: Reading = {
    used: null,
    remaining: null,
    limit_value: num(l.limit_value),
    resets_at: null,
    source: "manual",
  };
  let status: VendorCheck["status"] = "unknown";
  let error: string | null = null;
  try {
    const [observed] =
      await db.execute(sql`select * from public.vendor_observations where vendor=${vendor}
      and observed_at >= ${new Date(now.getTime() - 3600000).toISOString()}::timestamptz
      and observed_at <= ${now.toISOString()}::timestamptz
      and (resets_at is null or resets_at > ${now.toISOString()}::timestamptz)`);
    if (observed) {
      reading = {
        used: num(observed.used),
        remaining: num(observed.remaining),
        limit_value: num(observed.limit_value) ?? num(l.limit_value),
        resets_at: iso(observed.resets_at),
        source: "api",
      };
      if (reading.remaining === null && reading.limit_value !== null && reading.used !== null)
        reading.remaining = Math.max(0, reading.limit_value - reading.used);
      status = quotaStatus(reading.used, reading.limit_value, Number(l.warn_at));
    } else {
      const api = await readBalance(vendor, env, opts.fetch);
      if (api) {
        reading = api;
        status = balanceStatus(api.remaining, Number(l.balance_warn_below));
      } else if (
        await (async () => {
          const usage = await readUsage(vendor, env, now, opts.fetch);
          if (!usage) return false;
          reading = { ...usage, limit_value: usage.limit_value ?? num(l.limit_value) };
          reading.remaining =
            reading.limit_value == null ? null : Math.max(0, reading.limit_value - reading.used!);
          status = quotaStatus(reading.used, reading.limit_value, Number(l.warn_at));
          if (status === "unknown") error = "limit_not_configured";
          return true;
        })()
      ) {
        // Reading already assigned.
      } else if (l.kind === "renewal") {
        if (!l.expires_at) error = "not_configured";
        else {
          const days = (new Date(String(l.expires_at)).getTime() - now.getTime()) / 86400000;
          status = days <= 0 ? "out" : days <= 14 ? "low" : "ok";
          reading.resets_at = iso(l.expires_at);
        }
      } else if (vendor === "gemini") {
        const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)).toISOString();
        const [spend] =
          await db.execute(sql`select coalesce(sum((meta->>'provider_cost_usd')::numeric),0) as used from public.usage_ledger
        where kind='voice_seconds' and meta->>'provider'='gemini' and meta->>'key'='server'
        and created_at >= ${start}::timestamptz and created_at <= ${now.toISOString()}::timestamptz`);
        reading = {
          ...reading,
          used: Number(spend?.used ?? 0),
          source: "own_count",
          resets_at: new Date(
            Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
          ).toISOString(),
        };
        status = quotaStatus(reading.used, reading.limit_value, Number(l.warn_at));
        if (status === "unknown") error = "not_configured";
      } else if (["zeptomail", "resend", "resend_daily", "serper", "parallel"].includes(vendor)) {
        let start: Date;
        if (l.period === "day")
          start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
        else if (l.period === "month")
          start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
        else if (l.period_start) start = new Date(String(l.period_start));
        else {
          throw new Error("not_configured");
        }
        const [count] = await db.execute(
          sql`select coalesce(sum(count),0) as used from public.vendor_counts where vendor=${vendor === "resend_daily" ? "resend" : vendor} and day >= ${start.toISOString().slice(0, 10)}::date and day <= ${now.toISOString().slice(0, 10)}::date`,
        );
        reading = { ...reading, used: Number(count?.used ?? 0), source: "own_count" };
        reading.remaining =
          reading.limit_value == null ? null : Math.max(0, reading.limit_value - reading.used!);
        if (l.period === "day")
          reading.resets_at = new Date(start.getTime() + 86400000).toISOString();
        if (l.period === "month")
          reading.resets_at = new Date(
            Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
          ).toISOString();
        status = quotaStatus(reading.used, reading.limit_value, Number(l.warn_at));
        if (status === "unknown") error = "not_configured";
      } else error = "not_configured";
    }
  } catch (e) {
    // Persist only controlled error codes; credentials and raw response bodies never enter history.
    error =
      e instanceof Error &&
      /^(provider_http_\d{3}|invalid_reading|usd_balance_unavailable|not_configured)$/.test(
        e.message,
      )
        ? e.message
        : "check_failed";
  }
  if (
    !error &&
    l.period === "prepaid" &&
    l.expires_at &&
    Date.parse(String(l.expires_at)) <= now.getTime()
  ) {
    status = "out";
    reading.remaining = 0;
  }
  await db.execute(sql`insert into public.vendor_checks (vendor,checked_at,used,remaining,limit_value,resets_at,status,source,error)
    values (${vendor},${now.toISOString()}::timestamptz,${reading.used},${reading.remaining},${reading.limit_value},${reading.resets_at}::timestamptz,${status},${reading.source},${error})`);
  return (await listVendors(db)).find((v) => v.vendor === vendor) ?? null;
}
