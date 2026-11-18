/**
 * Casama Link remote access, on the self-hosted server (D-296).
 *
 * When remote access is on, this server holds a public address through a tunnel that Casama Cloud
 * made for it. The connector container runs the tunnel; this service is the part that talks to
 * Casama Cloud: it fetches the tunnel's secret and writes it where the connector reads it, checks
 * in every hour, fetches a new secret when the cloud made the tunnel again (parked servers, a
 * tunnel that disappeared), and takes the secret away when the address was removed or suspended.
 * It also answers "is it working, and if not, where does it stop" for the app and the CLI.
 *
 * Losing touch with Casama Cloud never takes a working address down: the stored secret keeps the
 * connector running, and the next check-in catches up.
 */
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

export type RemoteAccessState = "off" | "starting" | "online" | "offline" | "needs_attention";

export type RemoteAccessProblem =
  /** Remote access is on but the server has no link to Casama Cloud. */
  | "not_linked"
  /** Casama Cloud couldn't be reached; the address keeps working if it already did. */
  | "cloud_unreachable"
  /** The key was revoked, or Casama Cloud doesn't know it. */
  | "key_rejected"
  /** Taken down by Casama Cloud, alone or with the workspace. */
  | "suspended"
  /** Removed from the workspace's servers, or turned off from another place. */
  | "removed"
  /** The workspace's plan connects fewer servers. */
  | "plan_limit"
  /** Casama Cloud has no record of this server (the address was given up long ago). */
  | "unknown_server"
  /** The address Casama Cloud gives isn't the one this server is set up with. */
  | "address_changed"
  /** The connector isn't running. */
  | "connector_missing"
  /** The connector runs but can't reach the tunnel provider (a network that blocks port 7844). */
  | "connector_blocked"
  /** Everything looks connected, yet the address doesn't answer from outside. */
  | "address_unanswered";

export interface RemoteAccessStatus {
  state: RemoteAccessState;
  /** The public address, when remote access is on. */
  address: string | null;
  pages_address: string | null;
  /** The address on the server's own machine, if set. */
  local_address: string | null;
  /** Whether the server has a link to Casama Cloud at all. */
  linked: boolean;
  problem: RemoteAccessProblem | null;
  /** Connections the connector holds to the tunnel provider; null when it couldn't be asked. */
  connections: number | null;
  /** When this was last checked against Casama Cloud. */
  checked_at: string | null;
}

export interface RemoteAccessOptions {
  enabled: boolean;
  cloud?: { url: string; key: string };
  instanceId?: string;
  /** The address the stack is set up with (links, sign-in and webhooks use it). */
  publicUrl: string;
  pagesUrl?: string;
  localUrl?: string;
  tokenFile: string;
  connectorUrl?: string;
  version: string;
  fetch?: typeof fetch;
  now?: () => number;
  logger?: {
    info(msg: string, data?: Record<string, unknown>): void;
    warn(msg: string, data?: Record<string, unknown>): void;
  };
  /** How often the server checks in (default one hour). */
  heartbeatMs?: number;
  /** A connector that stays disconnected this long has its tunnel asked for again. */
  repairAfterMs?: number;
  repairEveryMs?: number;
}

interface Stored {
  generation: number;
}
type Beat = "ok" | "replaced" | "parked" | "released" | "suspended" | "unknown";

/** Builds the service from the environment; `enabled` is false unless remote access was turned on. */
export function remoteAccessFromEnv(
  env: {
    CASAMA_REMOTE_ACCESS: "on" | "off";
    CASAMA_INSTANCE_ID?: string;
    CASAMA_LOCAL_URL?: string;
    CASAMA_LINK_TOKEN_FILE: string;
    CONNECTOR_URL?: string;
    PUBLIC_API_URL?: string;
    SUPABASE_URL: string;
    PAGES_URL: string;
  },
  cloud: { url: string; key: string } | undefined,
  version: string,
  logger?: RemoteAccessOptions["logger"],
) {
  return new RemoteAccess({
    enabled: env.CASAMA_REMOTE_ACCESS === "on",
    cloud,
    instanceId: env.CASAMA_INSTANCE_ID,
    publicUrl: env.PUBLIC_API_URL ?? env.SUPABASE_URL,
    pagesUrl: env.PAGES_URL,
    localUrl: env.CASAMA_LOCAL_URL,
    tokenFile: env.CASAMA_LINK_TOKEN_FILE,
    connectorUrl: env.CONNECTOR_URL,
    version,
    logger,
  });
}

const sameAddress = (a: string, b: string) =>
  a.replace(/\/+$/, "").toLowerCase() === b.replace(/\/+$/, "").toLowerCase();

export class RemoteAccess {
  private readonly o: RemoteAccessOptions;
  private readonly fetch: typeof fetch;
  private readonly now: () => number;
  private problem: RemoteAccessProblem | null = null;
  private liveViewAway: string | null = null;
  private checkedAt: number | null = null;
  private connections: number | null = null;
  private connectedOnce = false;
  private disconnectedSince: number | null = null;
  private lastRepair = 0;
  private startedAt = 0;
  private timers: NodeJS.Timeout[] = [];
  private running: Promise<void> | null = null;

  constructor(o: RemoteAccessOptions) {
    this.o = o;
    this.fetch = o.fetch ?? fetch;
    this.now = o.now ?? Date.now;
  }

  get enabled() {
    return this.o.enabled;
  }

  /**
   * Live view away from the computer, as Casama Cloud said at the last check-in: "included" (the
   * workspace's plan has it), "plan" (a higher plan has it), or null (not known, or that cloud
   * runs no relay).
   */
  get liveView() {
    return this.o.enabled ? this.liveViewAway : null;
  }

  private get stateFile() {
    return `${this.o.tokenFile}.json`;
  }

  /** Starts the hourly check-in and the connector watch. Returns once the first check is done. */
  async start() {
    this.startedAt = this.now();
    if (!this.o.enabled) {
      // Turned off: the connector must not find a secret to run with.
      await this.dropToken();
      return;
    }
    await this.checkIn();
    const beat = setInterval(() => void this.checkIn(), this.o.heartbeatMs ?? 3_600_000);
    const watch = setInterval(() => void this.watchConnector(), 60_000);
    beat.unref();
    watch.unref();
    this.timers.push(beat, watch);
  }

  stop() {
    for (const t of this.timers) clearInterval(t);
    this.timers = [];
  }

  // -------------------------------------------------------------------------
  // Casama Cloud
  // -------------------------------------------------------------------------

  private async cloud(method: string, path: string, body?: unknown) {
    const cloud = this.o.cloud as { url: string; key: string };
    const res = await this.fetch(`${cloud.url.replace(/\/$/, "")}/link/v1${path}`, {
      method,
      headers: {
        authorization: `Bearer ${cloud.key}`,
        ...(body === undefined ? {} : { "content-type": "application/json" }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(30_000),
    });
    const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    return { status: res.status, json };
  }

  private info() {
    return { instance_id: this.o.instanceId, platform: "docker", version: this.o.version };
  }

  /** One check-in: tell Casama Cloud this server is here and act on what it says. */
  checkIn(): Promise<void> {
    // One at a time: the hourly check and a check asked for from the app may meet.
    this.running ??= this.checkInOnce().finally(() => {
      this.running = null;
    });
    return this.running;
  }

  private async checkInOnce() {
    if (!this.o.enabled) return;
    if (!this.o.cloud || !this.o.instanceId) {
      this.problem = "not_linked";
      return;
    }
    const stored = await this.readStored();
    let beat: Beat;
    try {
      const r = await this.cloud("POST", "/remote/heartbeat", {
        ...this.info(),
        generation: stored?.generation,
      });
      if (r.status === 401) return this.refused("key_rejected");
      if (r.status === 403) return this.refused("suspended");
      if (r.status >= 400) throw new Error(`Casama Cloud answered ${r.status}`);
      beat = r.json.status as Beat;
      this.liveViewAway = typeof r.json.live_view === "string" ? r.json.live_view : null;
    } catch (e) {
      // The stored secret keeps the connector going; say so and try again at the next check.
      this.problem = "cloud_unreachable";
      this.o.logger?.warn("casama link: check-in failed", { error: (e as Error).message });
      return;
    }
    this.checkedAt = this.now();
    if (beat === "suspended") return this.refused("suspended");
    if (beat === "released") return this.refused("removed");
    if (beat === "unknown") return this.refused("unknown_server");
    if (beat === "ok" && (await this.hasToken())) {
      this.problem = null;
      return;
    }
    // replaced or parked, or the secret went missing: ask for the address again.
    await this.fetchAddress();
  }

  /** Asks Casama Cloud for this server's address and the connector's secret, and stores the secret. */
  private async fetchAddress() {
    try {
      const r = await this.cloud("PUT", "/remote", this.info());
      if (r.status === 401) return this.refused("key_rejected");
      if (r.status === 402) return this.refused("plan_limit");
      if (r.status === 403) return this.refused("suspended");
      if (r.status >= 400) throw new Error(`Casama Cloud answered ${r.status}`);
      const address = String(r.json.address ?? "");
      if (!sameAddress(address, this.o.publicUrl)) {
        // Sign-in links, webhooks and the app all use the address this server was set up with.
        // Running the tunnel for another one would look connected and break all of them.
        this.o.logger?.warn("casama link: the address changed; turn remote access on again", {
          was: this.o.publicUrl,
          now: address,
        });
        return this.refused("address_changed");
      }
      await this.storeToken(String(r.json.token), Number(r.json.generation));
      this.checkedAt = this.now();
      this.problem = null;
      this.o.logger?.info("casama link: tunnel secret stored", {
        generation: Number(r.json.generation),
      });
    } catch (e) {
      this.problem = "cloud_unreachable";
      this.o.logger?.warn("casama link: couldn't get the address", {
        error: (e as Error).message,
      });
    }
  }

  /** Casama Cloud says this server has no address: stop the connector and remember why. */
  private async refused(problem: RemoteAccessProblem) {
    this.problem = problem;
    this.checkedAt = this.now();
    await this.dropToken();
  }

  // -------------------------------------------------------------------------
  // The secret on disk
  // -------------------------------------------------------------------------

  private async hasToken() {
    try {
      return (await readFile(this.o.tokenFile, "utf8")).trim().length > 0;
    } catch {
      return false;
    }
  }

  private async readStored(): Promise<Stored | null> {
    try {
      return JSON.parse(await readFile(this.stateFile, "utf8")) as Stored;
    } catch {
      return null;
    }
  }

  /** Written whole or not at all: the connector must never read half a secret. */
  private async storeToken(token: string, generation: number) {
    await mkdir(dirname(this.o.tokenFile), { recursive: true });
    const tmp = `${this.o.tokenFile}.tmp`;
    await writeFile(tmp, token, { mode: 0o600 });
    await rename(tmp, this.o.tokenFile);
    await writeFile(this.stateFile, JSON.stringify({ generation } satisfies Stored), {
      mode: 0o600,
    });
  }

  private async dropToken() {
    await rm(this.o.tokenFile, { force: true }).catch(() => {});
    await rm(this.stateFile, { force: true }).catch(() => {});
  }

  // -------------------------------------------------------------------------
  // The connector, and the address from outside
  // -------------------------------------------------------------------------

  /** Connections the connector holds, 0 when it runs but can't connect, null when it isn't there. */
  private async askConnector(): Promise<number | null> {
    if (!this.o.connectorUrl) return null;
    try {
      const res = await this.fetch(`${this.o.connectorUrl.replace(/\/$/, "")}/ready`, {
        signal: AbortSignal.timeout(5_000),
      });
      const json = (await res.json().catch(() => ({}))) as { readyConnections?: number };
      return res.ok ? Math.max(1, json.readyConnections ?? 1) : (json.readyConnections ?? 0);
    } catch {
      return null;
    }
  }

  /**
   * Looks at the connector (every minute while running). One that stays disconnected has its
   * tunnel asked for again, which repairs a tunnel that went missing at the provider.
   */
  async watchConnector() {
    if (!this.o.enabled) return;
    this.connections = await this.askConnector();
    const now = this.now();
    if (this.connections && this.connections > 0) {
      this.connectedOnce = true;
      this.disconnectedSince = null;
      return;
    }
    this.disconnectedSince ??= now;
    // The tunnel may be gone at the provider while the cloud's record says it is fine. Asking for
    // the address again has Casama Cloud check it and make it again, at most every few minutes.
    const waited = now - this.disconnectedSince;
    if (
      !this.problem &&
      waited >= (this.o.repairAfterMs ?? 5 * 60_000) &&
      now - this.lastRepair >= (this.o.repairEveryMs ?? 10 * 60_000)
    ) {
      this.lastRepair = now;
      // First ask whether the address should exist at all. It may have been turned off (`casama
      // selfhost remote off` releases it, then restarts the stack, which takes minutes while this
      // still runs), removed or suspended; asking for it then would make it again.
      await this.checkIn();
      if (this.problem && this.problem !== "cloud_unreachable") return;
      this.o.logger?.warn(
        "casama link: the connector stays disconnected; asking for the tunnel again",
      );
      await this.fetchAddress();
    }
  }

  private async answersOutside() {
    try {
      const res = await this.fetch(`${this.o.publicUrl.replace(/\/$/, "")}/readyz`, {
        signal: AbortSignal.timeout(10_000),
        redirect: "manual",
      });
      return res.ok;
    } catch {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // What the app and the CLI see
  // -------------------------------------------------------------------------

  status(): RemoteAccessStatus {
    const base = {
      address: this.o.enabled ? this.o.publicUrl : null,
      pages_address: this.o.enabled ? (this.o.pagesUrl ?? null) : null,
      local_address: this.o.localUrl ?? null,
      linked: !!this.o.cloud,
      connections: this.connections,
      checked_at: this.checkedAt ? new Date(this.checkedAt).toISOString() : null,
    };
    if (!this.o.enabled) return { state: "off", ...base, problem: null };
    // Casama Cloud not answering doesn't by itself mean the address is down.
    const blocking = this.problem && this.problem !== "cloud_unreachable" ? this.problem : null;
    if (blocking) return { state: "needs_attention", ...base, problem: blocking };
    if (this.connections && this.connections > 0)
      return { state: "online", ...base, problem: this.problem };
    // Give a fresh connector a couple of minutes before calling it offline.
    const young = !this.connectedOnce && this.now() - this.startedAt < 2 * 60_000;
    if (young) return { state: "starting", ...base, problem: this.problem };
    const why: RemoteAccessProblem =
      this.problem ?? (this.connections === null ? "connector_missing" : "connector_blocked");
    return { state: "offline", ...base, problem: why };
  }

  /** A full check on request: Casama Cloud, the connector, and the address from outside. */
  async check(): Promise<RemoteAccessStatus> {
    if (!this.o.enabled) return this.status();
    await this.checkIn();
    this.connections = await this.askConnector();
    if (this.connections && this.connections > 0) {
      this.connectedOnce = true;
      this.disconnectedSince = null;
    }
    const s = this.status();
    if (s.state === "online" && !(await this.answersOutside()))
      return { ...s, state: "offline", problem: "address_unanswered" };
    return s;
  }
}
