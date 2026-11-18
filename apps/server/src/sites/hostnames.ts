/**
 * Custom hostnames at the edge (docs/SITES-AND-DOMAINS-PLAN.md §7.3): what makes a connected
 * domain reach the pages server with a certificate. Shaped like Casama Link's TunnelProvider.
 *
 * The edge saying "active" proves nothing about who owns a domain (§7.4); Casama's own proof is
 * kept on the host row, and `hostIsLive` needs both.
 */
import { randomBytes } from "node:crypto";
import type { HostReason } from "@casama/domain";
import { CloudflareError, cloudflareClient } from "../cloudflare.ts";

export type EdgeState = "pending" | "active" | "failed";

export interface HostnameProvider {
  /** "cloudflare" or "own_edge": which records the screen shows and which proofs count. */
  readonly kind: "cloudflare" | "own_edge";
  /** Registers the host at the edge. Safe to repeat: adopts one that already exists. */
  add(hostname: string): Promise<{ ref: string; ownership: { name: string; value: string } }>;
  /** null when it no longer exists. */
  get(ref: string): Promise<{ state: EdgeState; reason?: HostReason } | null>;
  /** Asks the edge to look again now (resets its back-off). */
  recheck(ref: string): Promise<void>;
  /** Safe to repeat, and safe when already gone. */
  remove(ref: string): Promise<void>;
  /** How many the account holds, and how many it may, for the cost notice. */
  usage(): Promise<{ used: number; allocated: number } | null>;
}

interface CfCustomHostname {
  id: string;
  hostname: string;
  status?: string;
  ssl?: {
    status?: string;
    method?: string;
    type?: string;
    validation_errors?: Array<{ message?: string }>;
  };
  ownership_verification?: { type?: string; name?: string; value?: string };
  verification_errors?: string[];
}

/** Maps what the edge says went wrong to a reason the app can explain (§7.3). */
export function edgeReason(h: CfCustomHostname): HostReason {
  const text = [
    ...(h.verification_errors ?? []),
    ...(h.ssl?.validation_errors ?? []).map((e) => e.message ?? ""),
    h.status ?? "",
    h.ssl?.status ?? "",
  ]
    .join(" ")
    .toLowerCase();
  if (text.includes("caa")) return "caa_blocks";
  if (/zone hold|another account|already exists in another|moved/.test(text))
    return "held_elsewhere";
  if (/timed_out|timed out|timeout/.test(text)) return "timed_out";
  if (/blocked|refused|banned/.test(text)) return "refused";
  return "not_pointed";
}

export interface CloudflareHostnamesOptions {
  zoneId: string;
  apiToken: string;
  apiUrl?: string;
  fetch?: typeof fetch;
  timeoutMs?: number;
}

/** Cloudflare for SaaS on the sites zone (§2.1). */
export class CloudflareHostnames implements HostnameProvider {
  readonly kind = "cloudflare" as const;
  private readonly call: ReturnType<typeof cloudflareClient>;
  private readonly base: string;

  constructor(o: CloudflareHostnamesOptions) {
    this.call = cloudflareClient(o);
    this.base = `/zones/${o.zoneId}/custom_hostnames`;
  }

  private async find(hostname: string) {
    const q = new URLSearchParams({ hostname });
    const { result } = await this.call<CfCustomHostname[]>("GET", `${this.base}?${q}`);
    return result.find((h) => h.hostname.toLowerCase() === hostname) ?? null;
  }

  private async read(ref: string) {
    return (await this.call<CfCustomHostname>("GET", `${this.base}/${ref}`)).result;
  }

  async add(hostname: string) {
    let h: CfCustomHostname | null = null;
    try {
      h = (
        await this.call<CfCustomHostname>("POST", this.base, {
          hostname,
          ssl: { method: "http", type: "dv" },
        })
      ).result;
    } catch (e) {
      // Already registered (a failed earlier try): adopt it.
      if (!(e instanceof CloudflareError) || e.status !== 409) throw e;
    }
    h ??= await this.find(hostname);
    if (!h) throw new CloudflareError(502, null, `Cloudflare lost the hostname ${hostname}`);
    // The ownership record can come a moment after the hostname is made.
    if (!h.ownership_verification?.name) h = await this.read(h.id);
    const o = h.ownership_verification;
    if (!o?.name || !o.value)
      throw new CloudflareError(502, null, "Cloudflare returned no ownership record");
    return { ref: h.id, ownership: { name: o.name.toLowerCase(), value: o.value } };
  }

  async get(ref: string) {
    let h: CfCustomHostname;
    try {
      h = await this.read(ref);
    } catch (e) {
      if (e instanceof CloudflareError && e.status === 404) return null;
      throw e;
    }
    // Live needs the hostname and its certificate both active.
    if (h.status === "active" && h.ssl?.status === "active") return { state: "active" as const };
    const failed =
      ["blocked", "moved", "deleted"].includes(h.status ?? "") ||
      ["validation_timed_out", "issuance_timed_out", "deleted", "expired"].includes(
        h.ssl?.status ?? "",
      );
    return { state: failed ? ("failed" as const) : ("pending" as const), reason: edgeReason(h) };
  }

  async recheck(ref: string) {
    const h = await this.read(ref);
    // Send the ssl settings back: a bare PATCH can reset them.
    await this.call("PATCH", `${this.base}/${ref}`, {
      ssl: { method: h.ssl?.method ?? "http", type: h.ssl?.type ?? "dv" },
    });
  }

  async remove(ref: string) {
    try {
      await this.call("DELETE", `${this.base}/${ref}`);
    } catch (e) {
      if (e instanceof CloudflareError && e.status === 404) return;
      throw e;
    }
  }

  async usage() {
    try {
      const { result } = await this.call<{ allocated?: number; used?: number }>(
        "GET",
        `${this.base}/quota`,
      );
      if (typeof result?.used !== "number") return null;
      return { used: result.used, allocated: result.allocated ?? 100 };
    } catch {
      return null;
    }
  }
}

/**
 * A self-hosted server whose own Caddy answers on 80 and 443 (§7.12). Casama makes the ownership
 * record itself, and a host is live once `https://<host>/_casama/probe` answers with this
 * server's instance id, which means Caddy got the certificate (after `/internal/tls-ask` said yes).
 */
export class OwnEdgeHostnames implements HostnameProvider {
  readonly kind = "own_edge" as const;
  private readonly instanceId: string;
  private readonly fetch: typeof fetch;

  constructor(o: { instanceId: string; fetch?: typeof fetch }) {
    this.instanceId = o.instanceId;
    this.fetch = o.fetch ?? fetch;
  }

  async add(hostname: string) {
    // A new value every time, so a TXT record left from an earlier claim never proves this one.
    return {
      ref: `own:${hostname}`,
      ownership: {
        name: `_casama.${hostname}`,
        value: `casama-verify=${randomBytes(18).toString("base64url")}`,
      },
    };
  }

  async get(ref: string) {
    const host = ref.replace(/^own:/, "");
    try {
      const res = await this.fetch(`https://${host}/_casama/probe`, {
        signal: AbortSignal.timeout(5000),
        redirect: "manual",
      });
      const text = res.ok ? await res.text() : "";
      if (text.includes(this.instanceId)) return { state: "active" as const };
    } catch {
      // No certificate yet, or the name doesn't reach this server.
    }
    return { state: "pending" as const, reason: "not_pointed" as const };
  }

  async recheck() {}
  async remove() {}
  async usage() {
    return null;
  }
}
