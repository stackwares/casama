/**
 * Own counts of the calls the server makes with its own vendor accounts (docs/VENDOR-USAGE-PLAN.md,
 * phase 1). One row per vendor and UTC day in public.vendor_counts, added to atomically.
 *
 * Counting is bookkeeping: it never throws, never rejects and never delays the call it counts. A
 * failed write is logged (without anything secret) and dropped. Only calls made with the server's
 * own key are counted; a workspace's own key (BYOK) is that workspace's bill, not ours.
 */
import type { SearchProvider } from "@casama/agent";
import { type SQL, sql } from "drizzle-orm";
import { type EmailSender, isUndeliverableAddress } from "../email.ts";
import type { WallpaperSource } from "../wallpapers.ts";

/** The vendors that are counted here. Each needs a public.vendor_limits row (the table's foreign key). */
export const COUNTED_VENDORS = ["zeptomail", "resend", "serper", "parallel", "unsplash"] as const;
export type CountedVendor = (typeof COUNTED_VENDORS)[number];

/** The only part of the database client the counter uses. */
export interface CountDb {
  execute(query: SQL): PromiseLike<unknown>;
}

export interface VendorCounter {
  /** Adds `n` calls to today's (UTC) count. Resolves true when written; never rejects. */
  count(vendor: string, n?: number): Promise<boolean>;
}

type Log = (msg: string, extra?: Record<string, unknown>) => void;

const LOG_EVERY_MS = 60_000;

/** A count of whole calls: finite, an integer, and not negative (public.vendor_counts.count is a bigint ≥ 0). */
export function validCount(n: unknown): n is number {
  return typeof n === "number" && Number.isFinite(n) && Number.isSafeInteger(n) && n >= 0;
}

/** What went wrong, short enough for a log line and with no query text or parameters. */
function reason(err: unknown): string {
  const e = err as {
    code?: unknown;
    cause?: { code?: unknown; message?: unknown };
    message?: unknown;
  };
  const code = e?.cause?.code ?? e?.code;
  // Driver errors can contain connection strings or query parameters. Keep only SQLSTATE.
  return typeof code === "string" && /^[0-9A-Z]{5}$/.test(code) ? code : "count_write_failed";
}

export function createVendorCounter(
  db: CountDb,
  opts: { log?: Log; now?: () => number } = {},
): VendorCounter {
  const now = opts.now ?? Date.now;
  const lastLogged = new Map<string, number>();
  // A missing vendor_limits row fails every send; one line a minute per vendor is enough.
  const warn = (vendor: string, extra: Record<string, unknown>) => {
    const t = now();
    const last = lastLogged.get(vendor);
    if (last !== undefined && t - last < LOG_EVERY_MS) return;
    lastLogged.set(vendor, t);
    try {
      opts.log?.("vendor count not saved", { vendor, ...extra });
    } catch {
      // A broken logger must not break the call being counted.
    }
  };
  return {
    async count(vendor, n = 1) {
      try {
        if (typeof vendor !== "string" || !vendor.trim()) {
          warn(String(vendor), { error: "vendor is empty" });
          return false;
        }
        if (!validCount(n)) {
          warn(vendor, { error: "count must be a whole number, zero or more" });
          return false;
        }
        if (n === 0) return true;
        // The UTC day comes from the database, so every process agrees on it whatever its clock says.
        await db.execute(sql`
          insert into public.vendor_counts (vendor, day, count)
          values (${vendor}, (now() at time zone 'utc')::date, ${n}::bigint)
          on conflict (vendor, day)
          do update set count = public.vendor_counts.count + excluded.count`);
        return true;
      } catch (err) {
        warn(String(vendor), { error: reason(err) });
        return false;
      }
    },
  };
}

/**
 * An email sender that counts each send that succeeded. An address that can never receive mail is
 * skipped by the sender without a request, so it is not counted either.
 */
export function countingEmail(
  sender: EmailSender,
  vendor: CountedVendor,
  counter: VendorCounter,
): EmailSender {
  return {
    enabled: sender.enabled,
    async send(msg) {
      await sender.send(msg);
      if (!isUndeliverableAddress(msg.to)) void counter.count(vendor);
    },
  };
}

/** Which vendor an SMTP host is: ZeptoMail is counted; any other SMTP server is a self-hoster's own. */
export function smtpVendor(host: string | undefined): CountedVendor | null {
  return host && /(^|\.)zeptomail\./i.test(host.trim()) ? "zeptomail" : null;
}

const SEARCH_VENDORS: Record<string, CountedVendor> = { parallel: "parallel", serper: "serper" };

/**
 * A server-owned search provider that counts each query that got an answer from the vendor (an
 * empty result list is still a query the vendor charged for). Providers that aren't metered here
 * (DeepSeek, SearXNG) pass through unchanged. Only wrap the server's own chain, never a
 * workspace's own key.
 */
export function countingSearch(inner: SearchProvider, counter: VendorCounter): SearchProvider {
  const vendor = SEARCH_VENDORS[inner.id];
  if (!vendor) return inner;
  return {
    id: inner.id,
    costUsd: inner.costUsd,
    async search(query, count) {
      const results = await inner.search(query, count);
      void counter.count(vendor);
      return results;
    },
  };
}

/**
 * A wallpaper source that counts each photo search, the calls Unsplash's hourly limit applies to.
 * Reporting a download is not counted: Unsplash does not count it against the limit.
 */
export function countingWallpapers(
  inner: WallpaperSource,
  counter: VendorCounter,
): WallpaperSource {
  return {
    name: inner.name,
    async search(query, page) {
      const photos = await inner.search(query, page);
      void counter.count("unsplash");
      return photos;
    },
    trackDownload: (downloadLocation) => inner.trackDownload(downloadLocation),
  };
}

/**
 * Resend's quota headers on a send response: emails used today and this month on the account.
 * Missing or invalid values come back null. Nothing stores them yet: public.vendor_counts has no
 * column for them, so this waits for a table to put them in.
 */
export function parseResendQuota(headers: Pick<Headers, "get">): {
  daily: number | null;
  monthly: number | null;
} {
  const read = (name: string) => {
    const raw = headers.get(name);
    if (raw === null || raw.trim() === "") return null;
    const n = Number(raw);
    return validCount(n) ? n : null;
  };
  return { daily: read("x-resend-daily-quota"), monthly: read("x-resend-monthly-quota") };
}
