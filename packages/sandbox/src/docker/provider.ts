import { createHmac, randomUUID } from "node:crypto";
import { ComputerdClient } from "../computerd-client.ts";
import type { ObjectStore } from "../object-store.ts";
import { turnCredentials, turnIceServer } from "../turn.ts";
import {
  type CheckpointRef,
  type ComputerSpec,
  type ExecOptions,
  type InputEvent,
  SandboxError,
  type SandboxHandle,
  type SandboxProvider,
  type SnapshotRef,
} from "../types.ts";
import type { ContainerInspect, DockerApi } from "./api.ts";

export interface EgressControl {
  register(
    ref: string,
    token: string,
    rules?: { allow?: string[]; deny?: string[] },
  ): Promise<void>;
  unregister(ref: string): Promise<void>;
}

/** Egress control API client (the proxy's control port). */
export function egressControl(baseUrl: string, token: string): EgressControl {
  const call = async (method: string, ref: string, body?: unknown) => {
    const res = await fetch(`${baseUrl.replace(/\/$/, "")}/computers/${ref}`, {
      method,
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok)
      throw new SandboxError(
        "egress_control_failed",
        `egress control ${method} returned ${res.status}`,
      );
  };
  return {
    register: (ref, t, rules) => call("PUT", ref, { token: t, rules }),
    unregister: (ref) => call("DELETE", ref),
  };
}

export interface DockerProviderOptions {
  docker: DockerApi;
  store: ObjectStore;
  images: { headless: string; desktop: string };
  /** Container runtime: "runsc" (gVisor) in production. Unset uses Docker's default (runc). */
  runtime?: string;
  /** Secret used to derive per-computer tokens, so the supervisor stays stateless across restarts. */
  tokenSecret: string;
  egress: { containerName: string; proxyPort: number; control: EgressControl };
  /** Name of the supervisor's own container; it joins each computer network to reach computerd. */
  supervisorContainer?: string;
  defaults?: { cpus?: number; memoryMb?: number; pids?: number; tmpMb?: number; shmMb?: number };
  /** Prefix for container, network and volume names (lets tests run side by side). */
  namePrefix?: string;
  /**
   * The TURN relay for live view (D-055). It joins each desktop computer's network under the
   * alias "turn", so the streamer reaches it without the computer reaching anything else.
   */
  turn?: { containerName: string; secret: string; port?: number };
  /**
   * Warm pool (D-148): this many headless computers kept started and unassigned. A new computer
   * with the default size claims one (renamed to its ref) instead of waiting for a cold start.
   */
  warmPool?: number;
}

const LABEL = "dev.casama.computer";
/** On a pooled container: the pool ref its network, volume, tokens and egress identity use. */
const POOL_LABEL = "dev.casama.pool";

export class DockerProvider implements SandboxProvider {
  readonly id = "docker" as const;
  readonly capabilities: SandboxProvider["capabilities"];
  readonly opts: DockerProviderOptions;
  /** ref → pool ref, for computers that started as warm-pool members (read back from POOL_LABEL). */
  private readonly aliases = new Map<string, string>();
  private filling: Promise<void> | null = null;

  constructor(opts: DockerProviderOptions) {
    this.opts = opts;
    this.capabilities = { desktop: true, snapshots: true, liveStream: !!opts.turn };
  }

  private names(ref: string) {
    if (!/^[a-zA-Z0-9-]{1,64}$/.test(ref))
      throw new SandboxError("bad_ref", "computer ref must be alphanumeric");
    const p = this.opts.namePrefix ?? "casama";
    // A claimed pool member keeps the network and volume it was created with.
    const k = this.aliases.get(ref) ?? ref;
    return { container: `${p}-c-${ref}`, network: `${p}-n-${k}`, volume: `${p}-h-${k}` };
  }

  private token(kind: string, ref: string) {
    const k = this.aliases.get(ref) ?? ref;
    return createHmac("sha256", this.opts.tokenSecret).update(`${kind}:${k}`).digest("base64url");
  }

  /** Records the pool alias a container carries (after a supervisor restart the map is empty). */
  private learn(ref: string, c: ContainerInspect | null) {
    const pool = c?.Config?.Labels?.[POOL_LABEL];
    if (pool && pool !== ref) this.aliases.set(ref, pool);
    return c;
  }

  private client(ref: string) {
    return new ComputerdClient(
      `http://${this.names(ref).container}:7070`,
      this.token("computerd", ref),
    );
  }

  private async connect(network: string, container: string, aliases?: string[]) {
    await this.opts.docker
      .call(
        "POST",
        `/networks/${network}/connect`,
        { Container: container, ...(aliases ? { EndpointConfig: { Aliases: aliases } } : {}) },
        [200],
      )
      .catch((err: SandboxError) => {
        if (!/already exists|is already connected/.test(err.message)) throw err;
      });
  }

  private async disconnect(network: string, container: string) {
    await this.opts.docker
      .call("POST", `/networks/${network}/disconnect`, { Container: container, Force: true }, [200])
      .catch(() => {});
  }

  async create(spec: ComputerSpec): Promise<SandboxHandle> {
    const d = this.opts.docker;
    const p = this.opts.namePrefix ?? "casama";
    const existing = this.learn(
      spec.ref,
      await d.inspectOrNull<ContainerInspect>(`/containers/${p}-c-${spec.ref}/json`),
    );
    if (existing?.State.Running) return this.handle(spec.ref);
    if (existing) await this.destroy(spec.ref);
    if (this.poolable(spec)) {
      const claimed = await this.claim(spec.ref).catch(() => false);
      void this.fillPool().catch(() => {});
      if (claimed) return this.handle(spec.ref);
    }
    return this.start(spec);
  }

  /** Only computers a pool member can stand in for: headless, default size, no extra env. */
  private poolable(spec: ComputerSpec) {
    if (!this.opts.warmPool || spec.profile !== "headless" || spec.ref.startsWith("pool-"))
      return false;
    if (spec.env && Object.keys(spec.env).length) return false;
    const d = this.opts.defaults ?? {};
    const same = (a: number | undefined, b: number | undefined, def: number) =>
      a == null || a === (b ?? def);
    return same(spec.size?.cpus, d.cpus, 1) && same(spec.size?.memoryMb, d.memoryMb, 1024);
  }

  /** Unclaimed pool members (still named <prefix>-c-pool-…), with their state. */
  private async poolMembers() {
    const filters = encodeURIComponent(JSON.stringify({ label: [POOL_LABEL] }));
    const items = await this.opts.docker.call<
      Array<{ Names: string[]; State: string; Labels: Record<string, string> }>
    >("GET", `/containers/json?all=true&filters=${filters}`);
    const prefix = `/${this.opts.namePrefix ?? "casama"}-c-pool-`;
    return items
      .filter((c) => c.Names.some((x) => x.startsWith(prefix)))
      .map((c) => ({ pool: c.Labels[POOL_LABEL] as string, running: c.State === "running" }));
  }

  /** Takes a started pool member for [ref]: renames its container and remembers the alias. */
  private async claim(ref: string): Promise<boolean> {
    const p = this.opts.namePrefix ?? "casama";
    for (const m of (await this.poolMembers()).filter((x) => x.running)) {
      const renamed = await this.opts.docker
        .call("POST", `/containers/${p}-c-${m.pool}/rename?name=${p}-c-${ref}`, undefined, [204])
        .then(() => true)
        .catch(() => false); // another claim took it first
      if (!renamed) continue;
      this.aliases.set(ref, m.pool);
      try {
        await this.client(ref).waitReady();
        return true;
      } catch {
        await this.destroy(ref).catch(() => {});
      }
    }
    return false;
  }

  /** Tops the pool up to its size (one fill at a time); stopped members are replaced. */
  fillPool(): Promise<void> {
    if (!this.opts.warmPool) return Promise.resolve();
    this.filling ??= (async () => {
      try {
        const members = await this.poolMembers();
        for (const m of members.filter((x) => !x.running))
          await this.destroy(m.pool).catch(() => {});
        for (let i = members.filter((x) => x.running).length; i < (this.opts.warmPool ?? 0); i++) {
          const pool = `pool-${randomUUID().replace(/-/g, "").slice(0, 20)}`;
          await this.start({ ref: pool, profile: "headless" }, { [POOL_LABEL]: pool });
        }
      } finally {
        this.filling = null;
      }
    })();
    return this.filling;
  }

  /** Cold start: network, volume, egress registration, container, then wait for computerd. */
  private async start(
    spec: ComputerSpec,
    extraLabels: Record<string, string> = {},
  ): Promise<SandboxHandle> {
    const n = this.names(spec.ref);
    const d = this.opts.docker;

    // A private network with no route out; the egress proxy is the only way to the internet.
    if (!(await d.inspectOrNull(`/networks/${n.network}`))) {
      await d.call("POST", "/networks/create", {
        Name: n.network,
        Driver: "bridge",
        Internal: true,
        Labels: { [LABEL]: spec.ref },
      });
    }
    await d.call("POST", "/volumes/create", { Name: n.volume, Labels: { [LABEL]: spec.ref } });

    const egressToken = this.token("egress", spec.ref);
    await this.opts.egress.control.register(spec.ref, egressToken);
    const proxyHost = `${this.opts.egress.containerName}:${this.opts.egress.proxyPort}`;
    const proxyUrl = `http://${spec.ref}:${egressToken}@${proxyHost}`;
    const def = {
      cpus: 1,
      memoryMb: 1024,
      pids: 512,
      tmpMb: 1024,
      shmMb: 512,
      // Unset overrides must not erase a default (an undefined memory limit means unlimited).
      ...Object.fromEntries(Object.entries(this.opts.defaults ?? {}).filter(([, v]) => v != null)),
    };
    const cpus = spec.size?.cpus ?? def.cpus;
    const memoryMb = spec.size?.memoryMb ?? def.memoryMb;
    const env = {
      ...spec.env,
      COMPUTERD_TOKEN: this.token("computerd", spec.ref),
      HTTPS_PROXY: proxyUrl,
      HTTP_PROXY: proxyUrl,
      https_proxy: proxyUrl,
      http_proxy: proxyUrl,
      NO_PROXY: "localhost,127.0.0.1",
      no_proxy: "localhost,127.0.0.1",
      AGENT_BROWSER_PROXY: `http://${proxyHost}`,
      AGENT_BROWSER_PROXY_USERNAME: spec.ref,
      AGENT_BROWSER_PROXY_PASSWORD: egressToken,
      CASAMA_COMPUTER: spec.ref,
    };

    await d.call("POST", `/containers/create?name=${n.container}`, {
      Image: spec.profile === "desktop" ? this.opts.images.desktop : this.opts.images.headless,
      Hostname: "computer",
      User: "1000:1000",
      Env: Object.entries(env).map(([k, v]) => `${k}=${v}`),
      Labels: {
        [LABEL]: spec.ref,
        "dev.casama.profile": spec.profile,
        ...spec.labels,
        ...extraLabels,
      },
      HostConfig: {
        NetworkMode: n.network,
        Runtime: this.opts.runtime,
        Init: true,
        ReadonlyRootfs: true,
        Mounts: [{ Type: "volume", Source: n.volume, Target: "/home/casama" }],
        Tmpfs: { "/tmp": `rw,nosuid,nodev,size=${def.tmpMb}m` },
        ShmSize: def.shmMb * 1024 * 1024,
        NanoCpus: Math.round(cpus * 1e9),
        Memory: memoryMb * 1024 * 1024,
        MemorySwap: memoryMb * 1024 * 1024,
        PidsLimit: def.pids,
        CapDrop: ["ALL"],
        SecurityOpt: ["no-new-privileges"],
        RestartPolicy: { Name: "no" },
      },
    });
    await this.connect(n.network, this.opts.egress.containerName);
    if (this.opts.supervisorContainer) await this.connect(n.network, this.opts.supervisorContainer);
    if (spec.profile === "desktop" && this.opts.turn)
      await this.connect(n.network, this.opts.turn.containerName, ["turn"]);
    await d.call("POST", `/containers/${n.container}/start`);
    await this.client(spec.ref).waitReady();
    return this.handle(spec.ref);
  }

  async get(ref: string) {
    const c = this.learn(
      ref,
      await this.opts.docker.inspectOrNull<ContainerInspect>(
        `/containers/${this.names(ref).container}/json`,
      ),
    );
    return c?.State.Running ? this.handle(ref) : null;
  }

  async resume(ref: string, snapshot?: SnapshotRef, spec?: Partial<ComputerSpec>) {
    const running = await this.get(ref);
    const handle = running ?? (await this.create({ profile: "headless", ...spec, ref }));
    if (snapshot && !running) {
      await this.client(ref).restore(await this.opts.store.get(snapshot.key));
    }
    return handle;
  }

  async sleep(ref: string): Promise<SnapshotRef> {
    const key = `snapshots/${ref}/${new Date().toISOString().replace(/[:.]/g, "-")}.tar.gz`;
    const { size } = await this.opts.store.put(key, await this.client(ref).archive());
    await this.destroy(ref);
    return { key, size, createdAt: new Date().toISOString() };
  }

  async destroy(ref: string) {
    const d = this.opts.docker;
    if (!this.aliases.has(ref))
      this.learn(
        ref,
        await d
          .inspectOrNull<ContainerInspect>(`/containers/${this.names(ref).container}/json`)
          .catch(() => null),
      );
    const n = this.names(ref);
    const key = this.aliases.get(ref) ?? ref;
    await d
      .call("DELETE", `/containers/${n.container}?force=true&v=true`)
      .catch((e: SandboxError) => {
        if (e.status !== 404) throw e;
      });
    await this.disconnect(n.network, this.opts.egress.containerName);
    if (this.opts.supervisorContainer)
      await this.disconnect(n.network, this.opts.supervisorContainer);
    if (this.opts.turn) await this.disconnect(n.network, this.opts.turn.containerName);
    await d.call("DELETE", `/networks/${n.network}`).catch(() => {});
    await d.call("DELETE", `/volumes/${n.volume}?force=true`).catch(() => {});
    await this.opts.egress.control.unregister(key).catch(() => {});
    this.aliases.delete(ref);
  }

  /** Refs of computers that are running now. */
  async list(): Promise<string[]> {
    const filters = encodeURIComponent(JSON.stringify({ label: [LABEL] }));
    const items = await this.opts.docker.call<
      Array<{ Labels: Record<string, string>; State: string; Names: string[] }>
    >("GET", `/containers/json?filters=${filters}`);
    // The ref comes from the name: a claimed pool member's label still says its pool ref.
    const prefix = `/${this.opts.namePrefix ?? "casama"}-c-`;
    return items
      .flatMap((c) => c.Names.filter((x) => x.startsWith(prefix)).slice(0, 1))
      .map((x) => x.slice(prefix.length))
      .filter((ref) => !ref.startsWith("pool-"));
  }

  handle(ref: string): SandboxHandle {
    const c = this.client(ref);
    const store = this.opts.store;
    return {
      ref,
      exec: (cmd: string, opts?: ExecOptions) => c.exec(cmd, opts),
      kill: (id) => c.kill(id),
      readFile: (p) => c.readFile(p),
      writeFile: (p, data) => c.writeFile(p, data),
      deleteFile: (p) => c.deleteFile(p),
      listDir: (p) => c.listDir(p),
      search: (q, p) => c.search(q, p),
      enableDesktop: async () => {
        if (!(await c.health()).display)
          throw new SandboxError("desktop_unavailable", "This computer has no desktop", 409);
      },
      screenshot: () => c.screenshot(),
      thumbnail: (p, size) => c.thumbnail(p, size),
      setMcpServers: (s) => c.setMcpServers(s),
      mcpFetch: (k, init) => c.mcpFetch(k, init),
      input: (e: InputEvent) => c.input(e),
      streamEndpoint: async (opts = {}) => {
        const turn = this.opts.turn;
        if (!turn)
          throw new SandboxError("stream_unavailable", "Live view needs a TURN relay", 409);
        // The streamer relays through TURN too; its credentials last as long as a stream can.
        const creds = turnCredentials(turn.secret, `computer-${ref}`, 12 * 3600);
        const started = await c.streamStart({
          ice_servers: [turnIceServer("turn", turn.port ?? 3478, creds)],
        });
        const user = started.users[opts.mode === "control" ? "controller" : "viewer"];
        const host = `${this.names(ref).container}:${started.port}`;
        const login = await fetch(`http://${host}/api/login`, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify(user),
          signal: AbortSignal.timeout(10_000),
        }).catch((err: Error) => {
          throw new SandboxError("stream_unreachable", `streamer unreachable: ${err.message}`);
        });
        if (!login.ok)
          throw new SandboxError("stream_login_failed", `streamer login ${login.status}`);
        const { token } = (await login.json()) as { token: string };
        return { url: `ws://${host}/api/ws?token=${encodeURIComponent(token)}`, headers: {} };
      },
      stopStream: () => c.streamStop(),
      terminalEndpoint: async (opts) => ({ url: c.terminalUrl(opts), headers: c.authHeaders }),
      checkpoint: async (label: string): Promise<CheckpointRef> => {
        const id = randomUUID();
        const key = `checkpoints/${ref}/${id}.tar.gz`;
        const { size } = await store.put(key, await c.archive());
        return { id, label, key, size, createdAt: new Date().toISOString() };
      },
      restore: async (cp: CheckpointRef) => {
        await c.restore(await store.get(cp.key));
      },
      health: () => c.health(),
    };
  }
}
