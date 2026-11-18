/**
 * One dispatcher in front of the pages port (docs/SITES-AND-DOMAINS-PLAN.md §7.1). A request whose
 * host is under the sites zone, or is a known site host, goes to the sites app; everything else
 * goes to the pages origin, unchanged. With no zone and no host rows, behaviour is what it was:
 * self-hosted servers and Casama Link's <label>-p hosts are untouched.
 *
 * The Host header is trusted because of where the port listens, not because of the header: in
 * production the pages port is on loopback behind the tunnel; on a self-hosted server Caddy only
 * gets a certificate for hosts the API approves.
 */
import type { Database } from "@casama/db";
import { labelUnderZone } from "@casama/domain";
import { sql } from "drizzle-orm";

export type HostRow = {
  id: string;
  hostname: string;
  kind: "address" | "custom";
  status: string;
  status_reason: string | null;
  verified_at: string | null;
  page_id: string | null;
  org_id: string;
  domain_id: string | null;
  is_primary: boolean;
};

const TTL_MS = 60_000;
const MAX_ENTRIES = 10_000;
const cache = new Map<string, { at: number; row: HostRow | null }>();

/** The host's row, from a 60-second cache (hit and miss). */
export async function lookupHost(db: Database, hostname: string): Promise<HostRow | null> {
  const hit = cache.get(hostname);
  if (hit && Date.now() - hit.at < TTL_MS) return hit.row;
  const [row] = await db.execute<HostRow>(sql`
    select id, hostname, kind, status, status_reason, verified_at, page_id, org_id, domain_id, is_primary
    from public.site_hosts where hostname = ${hostname}`);
  if (cache.size >= MAX_ENTRIES) cache.delete(cache.keys().next().value as string);
  cache.set(hostname, { at: Date.now(), row: row ?? null });
  return row ?? null;
}

/** Forgets hosts after a change made in this process, so it shows at once. */
export function forgetHosts(...hostnames: string[]) {
  for (const h of hostnames) cache.delete(h.toLowerCase());
}

/** Tests: start from nothing. */
export function clearHostCache() {
  cache.clear();
}

/** The request's host, lowercase, without its port or a trailing dot. */
export function requestHost(req: Request) {
  const raw = req.headers.get("host") ?? new URL(req.url).host;
  return raw.trim().toLowerCase().replace(/:\d+$/, "").replace(/\.$/, "");
}

/**
 * The pages port's fetch: picks the sites app or the pages origin by host. `pagesHost` (from
 * PAGES_URL) always goes to the pages origin without a lookup.
 */
export function createHostDispatcher(o: {
  db: Database;
  zone?: string | null;
  pagesHost?: string | null;
  pages: { fetch(req: Request): Response | Promise<Response> };
  sites: { fetch(req: Request): Response | Promise<Response> };
}) {
  const zone = o.zone?.toLowerCase() ?? null;
  return async (req: Request): Promise<Response> => {
    const host = requestHost(req);
    if (!host || host === o.pagesHost) return o.pages.fetch(req);
    if (zone && (labelUnderZone(host, zone) !== null || host.endsWith(`.${zone}`)))
      return o.sites.fetch(req);
    if (await lookupHost(o.db, host).catch(() => null)) return o.sites.fetch(req);
    return o.pages.fetch(req);
  };
}
