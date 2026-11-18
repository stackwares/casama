/**
 * A local stand-in for the parts of Cloudflare's API that Casama uses: remotely managed tunnels
 * and DNS records for Casama Link (D-296), and Cloudflare for SaaS custom hostnames for connected
 * domains (D-329), with the real paths, envelope and error shapes. Tests can make calls fail, mark
 * a tunnel as connected, move a hostname between states, and remove things behind the server's back.
 */
import { randomUUID } from "node:crypto";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";

export interface FakeTunnel {
  id: string;
  name: string;
  status: "inactive" | "healthy" | "degraded" | "down";
  conns_active_at: string | null;
  conns_inactive_at: string | null;
  deleted_at: string | null;
  ingress: Array<{ hostname?: string; service: string }>;
  connections: number;
}
export interface FakeRecord {
  id: string;
  type: string;
  name: string;
  content: string;
  proxied: boolean;
}

export interface FakeHostname {
  id: string;
  hostname: string;
  status: string;
  ssl: {
    status: string;
    method: string;
    type: string;
    validation_errors?: Array<{ message: string }>;
  };
  ownership_verification: { type: "txt"; name: string; value: string };
  verification_errors?: string[];
  /** PATCH bodies received (a recheck). */
  patches: unknown[];
}

export interface FakeCloudflare {
  url: string;
  accountId: string;
  zoneId: string;
  zone: string;
  apiToken: string;
  tunnels: Map<string, FakeTunnel>;
  records: Map<string, FakeRecord>;
  /** Every call, as "METHOD /path". */
  calls: string[];
  /** The next calls matching [match] answer with [status] (500 by default), [times] times. */
  failNext(match: RegExp, times?: number, status?: number): void;
  /** A connector attached (or dropped) for the tunnel that serves [host]. */
  setConnected(host: string, connected: boolean): void;
  /** The tunnel that [host]'s record points at, as long as it still exists. */
  tunnelFor(host: string): FakeTunnel | undefined;
  /** Tunnels that exist now. */
  live(): FakeTunnel[];
  /** Settings for a harness: the CASAMA_LINK_* environment. */
  env(): Record<string, string>;
  /** Custom hostnames (Cloudflare for SaaS on the sites zone), by id. */
  hostnames: Map<string, FakeHostname>;
  /** The hostname registered for [host], if any. */
  hostnameFor(host: string): FakeHostname | undefined;
  /** Moves a custom hostname: "active" makes it and its certificate active. */
  setHostname(host: string, state: "pending" | "active" | "failed", errors?: string[]): void;
  /** Settings for a harness: the CASAMA_SITES_CF_* environment. */
  sitesEnv(): Record<string, string>;
  stop(): Promise<void>;
}

const readBody = (req: IncomingMessage) =>
  new Promise<string>((resolve) => {
    let data = "";
    req.on("data", (c) => {
      data += c;
    });
    req.on("end", () => resolve(data));
  });

export async function startFakeCloudflare(zone = "link.test"): Promise<FakeCloudflare> {
  const accountId = "acct-test";
  const zoneId = "zone-test";
  const apiToken = "cf-test-token";
  const tunnels = new Map<string, FakeTunnel>();
  const hostnames = new Map<string, FakeHostname>();
  const records = new Map<string, FakeRecord>();
  const calls: string[] = [];
  const failures: Array<{ match: RegExp; times: number; status: number }> = [];

  const tunnelOut = (t: FakeTunnel) => ({
    id: t.id,
    name: t.name,
    status: t.status,
    conns_active_at: t.conns_active_at,
    conns_inactive_at: t.conns_inactive_at,
    created_at: "2026-11-14T00:00:00Z",
    deleted_at: t.deleted_at,
    config_src: "cloudflare",
    connections: [],
  });

  const server: Server = createServer(async (req, res) => {
    const url = new URL(req.url ?? "/", "http://fake");
    const path = url.pathname;
    const method = req.method ?? "GET";
    calls.push(`${method} ${path}`);
    const send = (status: number, body: unknown) => {
      res.writeHead(status, { "content-type": "application/json" });
      res.end(JSON.stringify(body));
    };
    const ok = (result: unknown, info?: Record<string, unknown>) =>
      send(200, {
        success: true,
        errors: [],
        messages: [],
        result,
        ...(info ? { result_info: info } : {}),
      });
    const fail = (status: number, code: number, message: string) =>
      send(status, { success: false, errors: [{ code, message }], messages: [], result: null });

    if (req.headers.authorization !== `Bearer ${apiToken}`)
      return fail(403, 9109, "Invalid access token");
    const planned = failures.find((f) => f.match.test(`${method} ${path}`));
    if (planned) {
      planned.times--;
      if (planned.times <= 0) failures.splice(failures.indexOf(planned), 1);
      return fail(planned.status, planned.status === 429 ? 971 : 1000, "Planned failure");
    }
    const raw = await readBody(req);
    const body = raw ? (JSON.parse(raw) as Record<string, unknown>) : {};

    const tunnelBase = `/accounts/${accountId}/cfd_tunnel`;
    const recordBase = `/zones/${zoneId}/dns_records`;

    if (path === tunnelBase && method === "GET") {
      const name = url.searchParams.get("name");
      const all = [...tunnels.values()].filter(
        (t) =>
          (url.searchParams.get("is_deleted") !== "false" || !t.deleted_at) &&
          // Like the real API, the name filter is a loose match, not an exact one.
          (!name || t.name.includes(name)),
      );
      const perPage = Number(url.searchParams.get("per_page") ?? 20);
      return ok(all.slice(0, perPage).map(tunnelOut), {
        count: Math.min(all.length, perPage),
        page: 1,
        per_page: perPage,
        total_count: all.length,
      });
    }
    if (path === tunnelBase && method === "POST") {
      const name = String(body.name ?? "");
      if ([...tunnels.values()].some((t) => t.name === name && !t.deleted_at))
        return fail(409, 1013, "You already have a tunnel with this name");
      const t: FakeTunnel = {
        id: randomUUID(),
        name,
        status: "inactive",
        conns_active_at: null,
        conns_inactive_at: null,
        deleted_at: null,
        ingress: [],
        connections: 0,
      };
      tunnels.set(t.id, t);
      return ok(tunnelOut(t));
    }
    const tm = path.match(
      new RegExp(`^${tunnelBase}/([^/]+)(/token|/configurations|/connections)?$`),
    );
    if (tm) {
      const t = tunnels.get(tm[1] as string);
      if (!t || t.deleted_at) return fail(404, 1003, "Tunnel not found");
      const sub = tm[2] ?? "";
      if (sub === "/token" && method === "GET") return ok(`token-for-${t.id}`);
      if (sub === "/configurations" && method === "PUT") {
        const config = body.config as { ingress?: FakeTunnel["ingress"] } | undefined;
        const ingress = config?.ingress ?? [];
        if (!ingress.length || ingress[ingress.length - 1]?.hostname)
          return fail(400, 1056, "The last ingress rule must match all URLs");
        t.ingress = ingress;
        return ok({ tunnel_id: t.id, version: 1, config, source: "cloudflare" });
      }
      if (sub === "/connections" && method === "DELETE") {
        t.connections = 0;
        return ok(null);
      }
      if (sub === "" && method === "GET") return ok(tunnelOut(t));
      if (sub === "" && method === "DELETE") {
        if (t.connections > 0) return fail(400, 1022, "The tunnel has active connections");
        t.deleted_at = new Date().toISOString();
        return ok(tunnelOut(t));
      }
    }
    const hostnameBase = `/zones/${zoneId}/custom_hostnames`;
    const hostnameOut = (h: FakeHostname) => {
      const { patches: _p, ...rest } = h;
      return { ...rest, created_at: "2026-11-16T00:00:00Z" };
    };
    if (path === `${hostnameBase}/quota` && method === "GET")
      return ok({ allocated: 100, used: hostnames.size });
    if (path === hostnameBase && method === "GET") {
      const want = url.searchParams.get("hostname")?.toLowerCase();
      return ok(
        [...hostnames.values()].filter((h) => !want || h.hostname === want).map(hostnameOut),
      );
    }
    if (path === hostnameBase && method === "POST") {
      const hostname = String(body.hostname ?? "").toLowerCase();
      if ([...hostnames.values()].some((h) => h.hostname === hostname))
        return fail(409, 1406, "Duplicate custom hostname found.");
      const ssl = (body.ssl ?? {}) as { method?: string; type?: string };
      const h: FakeHostname = {
        id: randomUUID(),
        hostname,
        status: "pending",
        ssl: { status: "pending_validation", method: ssl.method ?? "http", type: ssl.type ?? "dv" },
        ownership_verification: {
          type: "txt",
          name: `_cf-custom-hostname.${hostname}`,
          value: randomUUID(),
        },
        patches: [],
      };
      hostnames.set(h.id, h);
      return ok(hostnameOut(h));
    }
    const hm = path.match(new RegExp(`^${hostnameBase}/([^/]+)$`));
    if (hm) {
      const h = hostnames.get(hm[1] as string);
      if (!h) return fail(404, 1436, "The custom hostname was not found.");
      if (method === "GET") return ok(hostnameOut(h));
      if (method === "PATCH") {
        h.patches.push(body);
        return ok(hostnameOut(h));
      }
      if (method === "DELETE") {
        hostnames.delete(h.id);
        return ok({ id: h.id });
      }
    }
    if (path === recordBase && method === "GET") {
      const exact = url.searchParams.get("name.exact")?.toLowerCase();
      const type = url.searchParams.get("type");
      return ok(
        [...records.values()].filter(
          (r) => (!exact || r.name === exact) && (!type || r.type === type),
        ),
      );
    }
    if (path === recordBase && method === "POST") {
      const name = String(body.name ?? "").toLowerCase();
      if (!name.endsWith(`.${zone}`)) return fail(400, 1004, "The name isn't in this zone");
      if ([...records.values()].some((r) => r.name === name))
        return fail(400, 81053, "A record with that host already exists");
      const r: FakeRecord = {
        id: randomUUID(),
        type: String(body.type),
        name,
        content: String(body.content),
        proxied: body.proxied === true,
      };
      records.set(r.id, r);
      return ok(r);
    }
    const rm = path.match(new RegExp(`^${recordBase}/([^/]+)$`));
    if (rm) {
      const r = records.get(rm[1] as string);
      if (!r) return fail(404, 81044, "Record does not exist");
      if (method === "DELETE") {
        records.delete(r.id);
        return ok({ id: r.id });
      }
      if (method === "PATCH") {
        if (body.content) r.content = String(body.content);
        if (typeof body.proxied === "boolean") r.proxied = body.proxied;
        return ok(r);
      }
    }
    return fail(404, 7003, `No route for ${method} ${path}`);
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

  const tunnelFor = (host: string) => {
    const record = [...records.values()].find((r) => r.name === host.toLowerCase());
    const t = record ? tunnels.get(record.content.replace(".cfargotunnel.com", "")) : undefined;
    return t && !t.deleted_at ? t : undefined;
  };

  return {
    url,
    accountId,
    zoneId,
    zone,
    apiToken,
    tunnels,
    records,
    calls,
    failNext(match, times = 1, status = 500) {
      failures.push({ match, times, status });
    },
    setConnected(host, connected) {
      const t = tunnelFor(host);
      if (!t) throw new Error(`No tunnel serves ${host}`);
      t.connections = connected ? 4 : 0;
      t.status = connected ? "healthy" : "down";
      const now = new Date().toISOString();
      if (connected) {
        t.conns_active_at = now;
        t.conns_inactive_at = null;
      } else t.conns_inactive_at = now;
    },
    tunnelFor,
    hostnames,
    hostnameFor: (host) => [...hostnames.values()].find((h) => h.hostname === host.toLowerCase()),
    setHostname(host, state, errors) {
      const h = [...hostnames.values()].find((x) => x.hostname === host.toLowerCase());
      if (!h) throw new Error(`No custom hostname ${host}`);
      if (state === "active") {
        h.status = "active";
        h.ssl.status = "active";
        h.verification_errors = undefined;
      } else if (state === "failed") {
        h.status = "pending";
        h.ssl.status = "validation_timed_out";
        h.verification_errors = errors;
      } else {
        h.status = "pending";
        h.ssl.status = "pending_validation";
        h.verification_errors = errors;
      }
    },
    sitesEnv: () => ({
      CASAMA_SITES_CF_ZONE_ID: zoneId,
      CASAMA_SITES_CF_API_TOKEN: apiToken,
      CASAMA_SITES_CF_API_URL: url,
    }),
    live: () => [...tunnels.values()].filter((t) => !t.deleted_at),
    env: () => ({
      CASAMA_LINK_ZONE: zone,
      CASAMA_LINK_CF_ACCOUNT_ID: accountId,
      CASAMA_LINK_CF_ZONE_ID: zoneId,
      CASAMA_LINK_CF_API_TOKEN: apiToken,
      CASAMA_LINK_CF_API_URL: url,
    }),
    stop: () => new Promise<void>((r) => server.close(() => r())),
  };
}
