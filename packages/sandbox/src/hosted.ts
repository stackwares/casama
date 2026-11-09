/**
 * Hosted sandbox providers (E2B and Daytona, D-057). Both run Kasama's own computer image with
 * computerd inside, reached through the provider's authenticated port URL, so every file, exec,
 * checkpoint and live-view feature is the same code as on Docker. Sleep archives the home
 * directory to Kasama's object store and deletes the sandbox, like Docker.
 */
import { createHmac, randomUUID } from "node:crypto";
import { ComputerdClient } from "./computerd-client.ts";
import type { ObjectStore } from "./object-store.ts";
import { turnCredentials, turnIceServer } from "./turn.ts";
import {
  type CheckpointRef,
  type ComputerSpec,
  type ExecOptions,
  type InputEvent,
  type ProviderId,
  SandboxError,
  type SandboxHandle,
  type SandboxProvider,
  type SnapshotRef,
} from "./types.ts";

/** One running sandbox as the control plane reports it. */
export interface HostedSandbox {
  id: string;
  running: boolean;
}

/** The provider-specific control plane. */
export interface HostedControlPlane {
  create(spec: ComputerSpec, env: Record<string, string>): Promise<HostedSandbox>;
  find(ref: string): Promise<HostedSandbox | null>;
  kill(id: string): Promise<void>;
  /** Base URL (and headers) that reach `port` inside the sandbox. */
  endpoint(id: string, port: number): Promise<{ url: string; headers: Record<string, string> }>;
  /** Keeps a sandbox alive (providers stop idle sandboxes on their own). */
  keepAlive?(id: string): Promise<void>;
}

export interface HostedProviderOptions {
  store: ObjectStore;
  tokenSecret: string;
  /** Public TURN relay for live view; hosted sandboxes reach it over the internet. */
  turn?: { host: string; port: number; secret: string };
}

async function call<T>(
  url: string,
  init: RequestInit & { expect?: number[] },
  label: string,
): Promise<T> {
  let res: Response;
  try {
    res = await fetch(url, init);
  } catch (err) {
    throw new SandboxError(
      `${label}_unreachable`,
      `${label} unreachable: ${(err as Error).message}`,
    );
  }
  if (!(init.expect ?? [200, 201, 202, 204]).includes(res.status)) {
    const body = await res.text().catch(() => "");
    throw new SandboxError(
      `${label}_error`,
      `${label} returned ${res.status}: ${body.slice(0, 300)}`,
      res.status,
    );
  }
  const text = await res.text();
  return (text ? JSON.parse(text) : null) as T;
}

export class HostedProvider implements SandboxProvider {
  readonly id: ProviderId;
  readonly capabilities: SandboxProvider["capabilities"];
  readonly plane: HostedControlPlane;
  readonly opts: HostedProviderOptions;

  constructor(id: ProviderId, plane: HostedControlPlane, opts: HostedProviderOptions) {
    this.id = id;
    this.plane = plane;
    this.opts = opts;
    this.capabilities = { desktop: true, snapshots: true, liveStream: !!opts.turn };
  }

  private token(ref: string) {
    return createHmac("sha256", this.opts.tokenSecret)
      .update(`computerd:${ref}`)
      .digest("base64url");
  }

  private async client(sandboxId: string, ref: string) {
    const ep = await this.plane.endpoint(sandboxId, 7070);
    return new ComputerdClient(ep.url, this.token(ref), ep.headers);
  }

  async create(spec: ComputerSpec): Promise<SandboxHandle> {
    const existing = await this.plane.find(spec.ref);
    if (existing?.running) return this.handle(existing.id, spec.ref);
    if (existing) await this.plane.kill(existing.id).catch(() => {});
    const sb = await this.plane.create(spec, {
      ...spec.env,
      COMPUTERD_TOKEN: this.token(spec.ref),
      KASAMA_COMPUTER: spec.ref,
      KASAMA_PROFILE: spec.profile,
    });
    await (await this.client(sb.id, spec.ref)).waitReady(90_000);
    return this.handle(sb.id, spec.ref);
  }

  async get(ref: string) {
    const sb = await this.plane.find(ref);
    return sb?.running ? this.handle(sb.id, ref) : null;
  }

  async resume(ref: string, snapshot?: SnapshotRef, spec?: Partial<ComputerSpec>) {
    const running = await this.plane.find(ref);
    if (running?.running) return this.handle(running.id, ref);
    const h = await this.create({ profile: "headless", ...spec, ref });
    if (snapshot) {
      const sb = (await this.plane.find(ref)) as HostedSandbox;
      await (await this.client(sb.id, ref)).restore(await this.opts.store.get(snapshot.key));
    }
    return h;
  }

  async sleep(ref: string): Promise<SnapshotRef> {
    const sb = await this.plane.find(ref);
    if (!sb) throw new SandboxError("not_found", `Computer ${ref} is not running`, 404);
    const key = `snapshots/${ref}/${new Date().toISOString().replace(/[:.]/g, "-")}.tar.gz`;
    const { size } = await this.opts.store.put(
      key,
      await (await this.client(sb.id, ref)).archive(),
    );
    await this.plane.kill(sb.id);
    return { key, size, createdAt: new Date().toISOString() };
  }

  async destroy(ref: string) {
    const sb = await this.plane.find(ref);
    if (sb) await this.plane.kill(sb.id);
  }

  handle(sandboxId: string, ref: string): SandboxHandle {
    const clientP = this.client(sandboxId, ref);
    const c = async () => clientP;
    const store = this.opts.store;
    const turn = this.opts.turn;
    const plane = this.plane;
    return {
      ref,
      async *exec(cmd: string, opts?: ExecOptions) {
        void plane.keepAlive?.(sandboxId).catch(() => {});
        yield* (await c()).exec(cmd, opts);
      },
      kill: async (id) => (await c()).kill(id),
      readFile: async (p) => (await c()).readFile(p),
      writeFile: async (p, data) => (await c()).writeFile(p, data),
      deleteFile: async (p) => (await c()).deleteFile(p),
      listDir: async (p) => (await c()).listDir(p),
      search: async (q, p) => (await c()).search(q, p),
      enableDesktop: async () => {
        if (!(await (await c()).health()).display)
          throw new SandboxError("desktop_unavailable", "This computer has no desktop", 409);
      },
      screenshot: async () => (await c()).screenshot(),
      input: async (e: InputEvent) => (await c()).input(e),
      streamEndpoint: async (opts = {}) => {
        if (!turn)
          throw new SandboxError("stream_unavailable", "Live view needs a TURN relay", 409);
        const creds = turnCredentials(turn.secret, `computer-${ref}`, 12 * 3600);
        const started = await (await c()).streamStart({
          ice_servers: [turnIceServer(turn.host, turn.port, creds)],
        });
        const user = started.users[opts.mode === "control" ? "controller" : "viewer"];
        const ep = await plane.endpoint(sandboxId, started.port);
        const login = await call<{ token: string }>(
          `${ep.url}/api/login`,
          {
            method: "POST",
            headers: { ...ep.headers, "content-type": "application/json" },
            body: JSON.stringify(user),
          },
          "streamer",
        );
        return {
          url: `${ep.url.replace(/^http/, "ws")}/api/ws?token=${encodeURIComponent(login.token)}`,
          headers: ep.headers,
        };
      },
      stopStream: async () => (await c()).streamStop(),
      terminalEndpoint: async (opts) => {
        const client = await c();
        return { url: client.terminalUrl(opts), headers: client.authHeaders };
      },
      checkpoint: async (label: string): Promise<CheckpointRef> => {
        const id = randomUUID();
        const key = `checkpoints/${ref}/${id}.tar.gz`;
        const { size } = await store.put(key, await (await c()).archive());
        return { id, label, key, size, createdAt: new Date().toISOString() };
      },
      restore: async (cp: CheckpointRef) => (await c()).restore(await store.get(cp.key)),
      health: async () => (await c()).health(),
    };
  }
}

// ---------------------------------------------------------------------------
// E2B (https://e2b.dev): REST control plane, ports at https://{port}-{sandboxID}.{domain}

export interface E2BOptions {
  apiKey: string;
  /** A template built from Kasama's computer image (computerd as the start command). */
  templates: { headless: string; desktop: string };
  apiUrl?: string;
  domain?: string;
  /** Seconds before E2B stops an idle sandbox; renewed on use. */
  timeoutS?: number;
  /** Override for tests: where a sandbox port is reachable. */
  portUrl?: (sandboxId: string, port: number) => Promise<string> | string;
}

export function e2bControlPlane(o: E2BOptions): HostedControlPlane {
  const api = (o.apiUrl ?? "https://api.e2b.app").replace(/\/$/, "");
  const headers = { "X-API-Key": o.apiKey, "content-type": "application/json" };
  const timeout = o.timeoutS ?? 3600;
  type Listed = { sandboxID: string; state?: string; metadata?: Record<string, string> };
  return {
    async create(spec, env) {
      const r = await call<{ sandboxID: string; domain?: string | null }>(
        `${api}/sandboxes`,
        {
          method: "POST",
          headers,
          body: JSON.stringify({
            templateID: spec.profile === "desktop" ? o.templates.desktop : o.templates.headless,
            timeout,
            metadata: { kasama_ref: spec.ref, ...spec.labels },
            envVars: env,
          }),
        },
        "e2b",
      );
      return { id: r.sandboxID, running: true };
    },
    async find(ref) {
      const q = encodeURIComponent(`kasama_ref=${ref}`);
      const list = await call<Listed[]>(`${api}/sandboxes?metadata=${q}`, { headers }, "e2b");
      const hit = list.find((s) => s.metadata?.kasama_ref === ref);
      return hit ? { id: hit.sandboxID, running: (hit.state ?? "running") === "running" } : null;
    },
    async kill(id) {
      await call(
        `${api}/sandboxes/${id}`,
        { method: "DELETE", headers, expect: [200, 204, 404] },
        "e2b",
      );
    },
    async endpoint(id, port) {
      const url = o.portUrl
        ? await o.portUrl(id, port)
        : `https://${port}-${id}.${o.domain ?? "e2b.app"}`;
      return { url, headers: {} };
    },
    async keepAlive(id) {
      await call(
        `${api}/sandboxes/${id}/timeout`,
        { method: "POST", headers, body: JSON.stringify({ timeout }), expect: [200, 204] },
        "e2b",
      );
    },
  };
}

// ---------------------------------------------------------------------------
// Daytona (https://daytona.io): REST control plane, ports through signed preview URLs

export interface DaytonaOptions {
  apiKey: string;
  /** Daytona snapshots built from Kasama's computer image. */
  snapshots: { headless: string; desktop: string };
  apiUrl?: string;
  organizationId?: string;
}

export function daytonaControlPlane(o: DaytonaOptions): HostedControlPlane {
  const api = (o.apiUrl ?? "https://app.daytona.io/api").replace(/\/$/, "");
  const headers: Record<string, string> = {
    authorization: `Bearer ${o.apiKey}`,
    "content-type": "application/json",
    ...(o.organizationId ? { "X-Daytona-Organization-ID": o.organizationId } : {}),
  };
  type Sandbox = { id: string; state: string; labels?: Record<string, string> };
  const previews = new Map<string, { url: string; headers: Record<string, string> }>();
  return {
    async create(spec, env) {
      const sb = await call<Sandbox>(
        `${api}/sandbox`,
        {
          method: "POST",
          headers,
          body: JSON.stringify({
            snapshot: spec.profile === "desktop" ? o.snapshots.desktop : o.snapshots.headless,
            env,
            labels: { kasama_ref: spec.ref, ...spec.labels },
            public: false,
            autoStopInterval: 0,
            cpu: spec.size?.cpus,
            memory: spec.size?.memoryMb ? Math.ceil(spec.size.memoryMb / 1024) : undefined,
          }),
        },
        "daytona",
      );
      for (let i = 0; i < 240; i++) {
        const cur = await call<Sandbox>(`${api}/sandbox/${sb.id}`, { headers }, "daytona");
        if (cur.state === "started") return { id: sb.id, running: true };
        if (["error", "build_failed", "destroyed"].includes(cur.state))
          throw new SandboxError("daytona_error", `Daytona sandbox ${sb.id} is ${cur.state}`);
        await new Promise((r) => setTimeout(r, 500));
      }
      throw new SandboxError("computer_start_timeout", "Daytona sandbox did not start");
    },
    async find(ref) {
      const q = encodeURIComponent(JSON.stringify({ kasama_ref: ref }));
      const list = await call<Sandbox[]>(`${api}/sandbox?labels=${q}`, { headers }, "daytona");
      const hit = list.find((s) => s.labels?.kasama_ref === ref && s.state !== "destroyed");
      return hit ? { id: hit.id, running: hit.state === "started" } : null;
    },
    async kill(id) {
      for (const k of [...previews.keys()]) if (k.startsWith(`${id}:`)) previews.delete(k);
      await call(
        `${api}/sandbox/${id}`,
        { method: "DELETE", headers, expect: [200, 204, 404] },
        "daytona",
      );
    },
    async endpoint(id, port) {
      const key = `${id}:${port}`;
      const cached = previews.get(key);
      if (cached) return cached;
      const p = await call<{ url: string; token: string }>(
        `${api}/sandbox/${id}/ports/${port}/preview-url`,
        { headers },
        "daytona",
      );
      const ep = { url: p.url.replace(/\/$/, ""), headers: { "x-daytona-preview-token": p.token } };
      previews.set(key, ep);
      return ep;
    },
  };
}

export const e2bProvider = (o: E2BOptions, h: HostedProviderOptions) =>
  new HostedProvider("e2b", e2bControlPlane(o), h);
export const daytonaProvider = (o: DaytonaOptions, h: HostedProviderOptions) =>
  new HostedProvider("daytona", daytonaControlPlane(o), h);
