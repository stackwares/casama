import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { Env } from "../../env.ts";
import { noticeInstanceOwners } from "../../sites/domains.ts";
import type { EmailSender } from "../email.ts";
import { checkVendor, listVendors, type Vendor } from "./index.ts";

async function queue(
  db: Database,
  key: string,
  vendor: string | null,
  subject: string,
  body: string,
  env: Env,
  notice: boolean,
  push = false,
) {
  await db.transaction(async (tx) => {
    const rows =
      await tx.execute(sql`insert into public.vendor_alerts(dedupe_key,vendor,subject,body)
      values (${key},${vendor},${subject},${body}) on conflict do nothing returning dedupe_key`);
    if (rows.length && notice) {
      await noticeInstanceOwners(tx, env.INSTANCE_ADMIN_EMAILS, "vendor_usage", {
        title: subject,
        body,
        link: "/admin",
        vendor_alert_key: key,
      });
      // Existing durable notification dispatcher handles phone delivery and quiet hours.
      if (push)
        await tx.execute(sql`update public.notifications set push_status='deferred',push_after=now()
        where kind='vendor_usage' and payload->>'vendor_alert_key'=${key}`);
    }
  });
}

export function alertKey(v: Vendor, now: Date): string {
  const status = v.latest!.status;
  const period = v.latest!.resets_at ?? v.period_start ?? "prepaid";
  // Persistent failures and depleted services repeat daily; warning emails repeat only next period.
  if (v.kind === "renewal" && status === "low") {
    const days = (Date.parse(v.expires_at!) - now.getTime()) / 86400000;
    return `${v.vendor}:renewal:${period}:${days <= 3 ? "3" : "14"}`;
  }
  return `${v.vendor}:${status}:${status === "out" || status === "unknown" ? now.toISOString().slice(0, 10) : period}`;
}
export async function vendorUsageSweep(
  db: Database,
  env: Env,
  email: EmailSender,
  opts: {
    now?: Date;
    fetch?: typeof fetch;
    adminDb?: Database;
  } = {},
) {
  const now = opts.now ?? new Date();
  const adminDb = opts.adminDb ?? db;
  const before = await listVendors(db);
  for (const old of before.filter((v) => v.enabled)) {
    const v = await checkVendor(db, env, old.vendor, opts);
    if (!v?.latest) continue;
    const c = v.latest;
    if (c.error === "not_configured" || c.error === "limit_not_configured") continue;
    if (c.status === "unknown") {
      // Consecutive failures must span three hours, not merely three manual clicks.
      const failures = [];
      for (const reading of v.history) {
        if (!reading.error) break;
        failures.push(reading);
      }
      const failureStart = failures.at(-1)?.checked_at;
      if (!failureStart || now.getTime() - Date.parse(failureStart) < 3 * 3600000) continue;
    }
    if (c.status === "ok" && (!old.latest || old.latest.status === "ok")) continue;
    if (c.status === "ok") {
      const [incident] = await db.execute(
        sql`select 1 as found from public.vendor_alerts where vendor=${v.vendor} and dedupe_key not like '%:recovery:%' limit 1`,
      );
      if (!incident) continue;
    }
    const subject = `Casama: ${v.label} ${c.status === "ok" ? "is back to normal" : `is ${c.status}`}`;
    const body = `${v.label}: ${c.status}. Used: ${c.used ?? "unknown"} ${v.unit}. Remaining: ${c.remaining ?? "unknown"}. Resets: ${c.resets_at ?? "not scheduled"}. Open Admin → Vendors to review the reading and refill the service.`;
    // Recovery key follows the preceding incident, allowing a later recovery in the same period.
    const key =
      c.status === "ok" ? `${v.vendor}:recovery:${old.latest?.checked_at}` : alertKey(v, now);
    await queue(
      adminDb,
      key,
      v.vendor,
      subject,
      `${body}\n${v.impact ?? ""}\n${v.billing_url ?? ""}`,
      env,
      c.status !== "ok",
      c.status === "out" || c.status === "unknown",
    );
  }
  // Monday 09:00 Manila = Monday 01:00 UTC; hourly runs after the target hour catch delayed jobs.
  if (now.getUTCDay() === 1 && now.getUTCHours() >= 1) {
    const vendors = await listVendors(db);
    await queue(
      adminDb,
      `weekly:${now.toISOString().slice(0, 10)}`,
      null,
      "Casama: weekly vendor usage",
      vendors
        .filter((v) => v.enabled)
        .map(
          (v) =>
            `${v.label}: ${v.latest?.status ?? "not checked"}, used ${v.latest?.used ?? "?"}, remaining ${v.latest?.remaining ?? "?"}`,
        )
        .join("\n"),
      env,
      false,
    );
  }
  const configured = (env.VENDOR_ALERT_EMAILS ?? env.INSTANCE_ADMIN_EMAILS ?? "")
    .split(",")
    .map((x) => x.trim())
    .filter(Boolean);
  const recipients = configured.length
    ? configured
    : (
        await adminDb.execute<{ email: string }>(
          sql`select email from auth.users where email is not null order by created_at limit 1`,
        )
      ).map((r) => r.email);
  if (email.enabled && recipients.length) {
    const pending = await db.execute<{
      dedupe_key: string;
      subject: string;
      body: string;
    }>(sql`update public.vendor_alerts set lease_until=now()+interval '5 minutes' where dedupe_key in
      (select dedupe_key from public.vendor_alerts where sent_at is null and (lease_until is null or lease_until<now()) order by created_at limit 50 for update skip locked) returning dedupe_key,subject,body`);
    for (const row of pending) {
      try {
        for (const to of recipients) await email.send({ to, subject: row.subject, text: row.body });
        await db.execute(
          sql`update public.vendor_alerts set sent_at=now(),lease_until=null where dedupe_key=${row.dedupe_key}`,
        );
      } catch {
        await db.execute(
          sql`update public.vendor_alerts set lease_until=null where dedupe_key=${row.dedupe_key}`,
        );
      }
    }
  }
  await db.execute(sql`delete from public.vendor_checks where checked_at<now()-interval '90 days'`);
}
