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
}

const LABEL = "dev.kasama.computer";

export class DockerProvider implements SandboxProvider {
  readonly id = "docker" as const;
  readonly capabilities: SandboxProvider["capabilities"];
  readonly opts: DockerProviderOptions;

  constructor(opts: DockerProviderOptions) {
    this.opts = opts;
    this.capabilities = { desktop: true, snapshots: true, liveStream: !!opts.turn };
  }

  private names(ref: string) {
    if (!/^[a-zA-Z0-9-]{1,64}$/.test(ref))
      throw new SandboxError("bad_ref", "computer ref must be alphanumeric");
    const p = this.opts.namePrefix ?? "kasama";
    return { container: `${p}-c-${ref}`, network: `${p}-n-${ref}`, volume: `${p}-h-${ref}` };
  }

  private token(kind: string, ref: string) {
    return createHmac("sha256", this.opts.tokenSecret).update(`${kind}:${ref}`).digest("base64url");
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
    const n = this.names(spec.ref);
    const d = this.opts.docker;
    const existing = await d.inspectOrNull<ContainerInspect>(`/containers/${n.container}/json`);
    if (existing?.State.Running) return this.handle(spec.ref);
    if (existing) await d.call("DELETE", `/containers/${n.container}?force=true`);

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
      ...this.opts.defaults,
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
      KASAMA_COMPUTER: spec.ref,
    };

    await d.call("POST", `/containers/create?name=${n.container}`, {
      Image: spec.profile === "desktop" ? this.opts.images.desktop : this.opts.images.headless,
      Hostname: "computer",
      User: "1000:1000",
      Env: Object.entries(env).map(([k, v]) => `${k}=${v}`),
      Labels: { [LABEL]: spec.ref, "dev.kasama.profile": spec.profile, ...spec.labels },
      HostConfig: {
        NetworkMode: n.network,
        Runtime: this.opts.runtime,
        Init: true,
        ReadonlyRootfs: true,
        Mounts: [{ Type: "volume", Source: n.volume, Target: "/home/kasama" }],
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
    const c = await this.opts.docker.inspectOrNull<ContainerInspect>(
      `/containers/${this.names(ref).container}/json`,
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
    const n = this.names(ref);
    const d = this.opts.docker;
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
    await this.opts.egress.control.unregister(ref).catch(() => {});
  }

  /** Refs of computers that are running now. */
  async list(): Promise<string[]> {
    const filters = encodeURIComponent(JSON.stringify({ label: [LABEL] }));
    const items = await this.opts.docker.call<
      Array<{ Labels: Record<string, string>; State: string; Names: string[] }>
    >("GET", `/containers/json?filters=${filters}`);
    const prefix = `/${this.opts.namePrefix ?? "kasama"}-c-`;
    return items
      .filter((c) => c.Names.some((x) => x.startsWith(prefix)))
      .map((c) => c.Labels[LABEL] as string);
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
