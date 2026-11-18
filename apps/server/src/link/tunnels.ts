/**
 * Casama Link (D-296): the tunnels behind a linked server's address. Casama Cloud only creates,
 * checks and removes them; traffic goes from the phone to the provider's edge and down the tunnel
 * to the server, never through Casama Cloud.
 *
 * One provider today, Cloudflare Tunnel, written with plain fetch like the other adapters. Each
 * server gets one remotely managed tunnel and two proxied CNAMEs on the address zone:
 *   <label>.<zone>     the app (API and Auth)
 *   <label>-p.<zone>   bot pages, on their own origin (D-119)
 * Both names are one label deep, so the zone's wildcard certificate covers them and they never
 * show up one by one in certificate logs.
 */
import { CloudflareError, cloudflareClient } from "../cloudflare.ts";

export interface TunnelOrigins {
  /** Where the connector sends the app's requests, as it sees the stack. */
  app: string;
  pages: string;
}

/** What the self-host stack's connector reaches (infra/compose: the `caddy` service). */
export const STACK_ORIGINS: TunnelOrigins = { app: "http://caddy:80", pages: "http://caddy:8790" };

export interface TunnelState {
  /** inactive: never connected. down: was connected, isn't now. */
  state: "inactive" | "healthy" | "degraded" | "down";
  /** When it last connected or disconnected, if known. */
  since: Date | null;
}

export interface TunnelProvider {
  /** The domain the addresses live on. */
  readonly zone: string;
  /** Makes the tunnel for [label], or adopts the one a failed earlier try left, and routes both names to it. */
  provision(label: string, origins?: TunnelOrigins): Promise<{ tunnelId: string }>;
  /** The secret the connector runs with. */
  token(tunnelId: string): Promise<string>;
  /** Whether a connector is attached; null when the tunnel no longer exists. */
  status(tunnelId: string): Promise<TunnelState | null>;
  /** Removes both names and the tunnel. Safe to repeat, and safe when parts are already gone. */
  remove(label: string, tunnelId: string | null): Promise<void>;
  /** How many tunnels the account holds (the provider's included amount is 1,000). */
  count(): Promise<number>;
}

export const appHost = (label: string, zone: string) => `${label}.${zone}`;
export const pagesHost = (label: string, zone: string) => `${label}-p.${zone}`;
export const tunnelName = (label: string) => `casama-${label}`;

export class TunnelProviderError extends CloudflareError {
  constructor(status: number, code: number | null, message: string) {
    super(status, code, message);
    this.name = "TunnelProviderError";
  }
}

interface CfTunnel {
  id: string;
  name: string;
  status?: TunnelState["state"];
  conns_active_at?: string | null;
  conns_inactive_at?: string | null;
  deleted_at?: string | null;
}
interface CfRecord {
  id: string;
  name: string;
  type: string;
  content: string;
}

export interface CloudflareOptions {
  accountId: string;
  zoneId: string;
  zone: string;
  apiToken: string;
  /** Tests point this at a fake. */
  apiUrl?: string;
  fetch?: typeof fetch;
  timeoutMs?: number;
}

export class CloudflareTunnels implements TunnelProvider {
  readonly zone: string;
  private readonly o: CloudflareOptions;
  private readonly call: ReturnType<typeof cloudflareClient>;

  constructor(o: CloudflareOptions) {
    this.o = o;
    this.zone = o.zone.toLowerCase();
    this.call = cloudflareClient(o, (st, code, msg) => new TunnelProviderError(st, code, msg));
  }

  private tunnels = () => `/accounts/${this.o.accountId}/cfd_tunnel`;
  private records = () => `/zones/${this.o.zoneId}/dns_records`;

  private async findTunnel(label: string) {
    const q = new URLSearchParams({ name: tunnelName(label), is_deleted: "false" });
    const { result } = await this.call<CfTunnel[]>("GET", `${this.tunnels()}?${q}`);
    // The name filter isn't documented as exact, so match it here.
    return result.find((t) => t.name === tunnelName(label) && !t.deleted_at) ?? null;
  }

  private async findRecords(host: string) {
    const q = new URLSearchParams({ type: "CNAME", "name.exact": host });
    const { result } = await this.call<CfRecord[]>("GET", `${this.records()}?${q}`);
    return result.filter((r) => r.type === "CNAME" && r.name.toLowerCase() === host);
  }

  private async route(host: string, tunnelId: string) {
    const content = `${tunnelId}.cfargotunnel.com`;
    const [first, ...extra] = await this.findRecords(host);
    for (const r of extra) await this.call("DELETE", `${this.records()}/${r.id}`);
    if (first?.content === content) return;
    const record = { type: "CNAME", name: host, content, proxied: true, ttl: 1 };
    if (first) await this.call("PATCH", `${this.records()}/${first.id}`, record);
    else await this.call("POST", this.records(), { ...record, comment: "Casama Link" });
  }

  async provision(label: string, origins: TunnelOrigins = STACK_ORIGINS) {
    const tunnel =
      (await this.findTunnel(label)) ??
      (
        await this.call<CfTunnel>("POST", this.tunnels(), {
          name: tunnelName(label),
          config_src: "cloudflare",
        })
      ).result;
    const app = appHost(label, this.zone);
    const pages = pagesHost(label, this.zone);
    await this.call("PUT", `${this.tunnels()}/${tunnel.id}/configurations`, {
      config: {
        ingress: [
          { hostname: app, service: origins.app, originRequest: {} },
          { hostname: pages, service: origins.pages, originRequest: {} },
          { service: "http_status:404" },
        ],
      },
    });
    await this.route(app, tunnel.id);
    await this.route(pages, tunnel.id);
    return { tunnelId: tunnel.id };
  }

  async token(tunnelId: string) {
    return (await this.call<string>("GET", `${this.tunnels()}/${tunnelId}/token`)).result;
  }

  async status(tunnelId: string): Promise<TunnelState | null> {
    let t: CfTunnel;
    try {
      t = (await this.call<CfTunnel>("GET", `${this.tunnels()}/${tunnelId}`)).result;
    } catch (e) {
      if (e instanceof TunnelProviderError && e.status === 404) return null;
      throw e;
    }
    if (t.deleted_at) return null;
    const state = t.status ?? "inactive";
    const at =
      state === "healthy" || state === "degraded" ? t.conns_active_at : t.conns_inactive_at;
    return { state, since: at ? new Date(at) : null };
  }

  async remove(label: string, tunnelId: string | null) {
    for (const host of [appHost(label, this.zone), pagesHost(label, this.zone)])
      for (const r of await this.findRecords(host))
        await this.gone(() => this.call("DELETE", `${this.records()}/${r.id}`));
    const id = tunnelId ?? (await this.findTunnel(label))?.id;
    if (!id) return;
    // A tunnel with a connector attached can't be deleted, so its connections go first.
    await this.gone(() => this.call("DELETE", `${this.tunnels()}/${id}/connections`));
    await this.gone(() => this.call("DELETE", `${this.tunnels()}/${id}`));
  }

  /** Already gone counts as removed. */
  private async gone(op: () => Promise<unknown>) {
    try {
      await op();
    } catch (e) {
      if (e instanceof TunnelProviderError && e.status === 404) return;
      throw e;
    }
  }

  async count() {
    const q = new URLSearchParams({ is_deleted: "false", per_page: "1" });
    const r = await this.call<CfTunnel[]>("GET", `${this.tunnels()}?${q}`);
    return r.result_info?.total_count ?? r.result.length;
  }
}
