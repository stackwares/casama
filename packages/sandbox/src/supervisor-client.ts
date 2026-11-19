import { fetchThumbnail } from "./computerd-client.ts";
import { slowFetch, streamFetch } from "./long-fetch.ts";
import { ndjson } from "./ndjson.ts";
import {
  type CheckpointRef,
  type ComputerImageStatus,
  type ComputerSpec,
  type ExecChunk,
  type ExecOptions,
  encodeStreamRelay,
  type FileEntry,
  type HealthStatus,
  type InputEvent,
  type ProviderId,
  SandboxError,
  type SandboxHandle,
  type SandboxProvider,
  type SearchMatch,
  type SnapshotRef,
  STREAM_RELAY_HEADER,
} from "./types.ts";

/** SandboxProvider backed by the supervisor's HTTP API. Used by the API and the worker. */
export class SupervisorProvider implements SandboxProvider {
  readonly id: ProviderId;
  readonly capabilities: { desktop: boolean; snapshots: boolean; liveStream: boolean };
  readonly baseUrl: string;
  private readonly token: string;

  constructor(
    baseUrl: string,
    token: string,
    provider: ProviderId = "docker",
    capabilities = { desktop: true, snapshots: true, liveStream: true },
  ) {
    this.baseUrl = baseUrl.replace(/\/$/, "");
    this.token = token;
    this.id = provider;
    this.capabilities = capabilities;
  }

  /** The same supervisor, routing to another provider (E2B, Daytona); see D-056. */
  forProvider(id: string) {
    return new SupervisorProvider(this.baseUrl, this.token, id as ProviderId);
  }

  private get authHeaders(): Record<string, string> {
    return {
      authorization: `Bearer ${this.token}`,
      ...(this.id === "docker" ? {} : { "x-casama-provider": this.id }),
    };
  }

  /** `via`: `slowFetch` or `streamFetch` for calls that outlast fetch's own 300 second limits. */
  async call(path: string, init: RequestInit = {}, via: typeof fetch = fetch): Promise<Response> {
    let res: Response;
    try {
      res = await via(`${this.baseUrl}${path}`, {
        ...init,
        headers: { ...this.authHeaders, ...(init.headers as Record<string, string>) },
      });
    } catch (err) {
      throw new SandboxError(
        "supervisor_unreachable",
        `supervisor unreachable: ${(err as Error).message}`,
      );
    }
    if (!res.ok) {
      const body = (await res.json().catch(() => ({}))) as { code?: string; message?: string };
      throw new SandboxError(
        body.code ?? "supervisor_error",
        body.message ?? `supervisor returned ${res.status}`,
        res.status,
      );
    }
    return res;
  }

  private json(path: string, method: string, body?: unknown, via: typeof fetch = fetch) {
    return this.call(
      path,
      {
        method,
        headers: { "content-type": "application/json" },
        body: body === undefined ? undefined : JSON.stringify(body),
      },
      via,
    );
  }

  // Starting, waking and sleeping a computer answer when the work is done: pulling an image,
  // restoring or archiving a home folder of several gigabytes takes longer than five minutes.
  async create(spec: ComputerSpec) {
    await this.json("/computers", "POST", spec, slowFetch);
    return this.handle(spec.ref);
  }

  async resume(ref: string, snapshot?: SnapshotRef, spec?: Partial<ComputerSpec>) {
    await this.json(`/computers/${ref}/resume`, "POST", { snapshot, spec }, slowFetch);
    return this.handle(ref);
  }

  async get(ref: string) {
    const r = (await (await this.call(`/computers/${ref}`)).json()) as { running: boolean };
    return r.running ? this.handle(ref) : null;
  }

  async sleep(ref: string) {
    return (await (
      await this.json(`/computers/${ref}/sleep`, "POST", undefined, slowFetch)
    ).json()) as SnapshotRef;
  }

  async destroy(ref: string) {
    await this.call(`/computers/${ref}`, { method: "DELETE" });
  }

  async list(): Promise<string[]> {
    return ((await (await this.call("/computers")).json()) as { running: string[] }).running;
  }

  /**
   * Running Docker computers and whether each is on the current image (D-360). Null when the
   * supervisor is older than this call (404) or the provider isn't Docker.
   */
  async imageStatus(): Promise<ComputerImageStatus[] | null> {
    if (this.id !== "docker") return null;
    try {
      return (
        (await (await this.call("/computers/images")).json()) as {
          items: ComputerImageStatus[];
        }
      ).items;
    } catch (err) {
      if (err instanceof SandboxError && (err.status === 404 || err.status === 501)) return null;
      throw err;
    }
  }

  async deleteObjects(keys: string[]) {
    if (keys.length) await this.json("/objects/delete", "POST", { keys });
  }

  handle(ref: string): SandboxHandle {
    const base = `/computers/${ref}`;
    const self = this;
    return {
      ref,
      async *exec(cmd: string, opts: ExecOptions = {}): AsyncIterable<ExecChunk> {
        // A command may print nothing for a long time; its own timeout ends it, not the stream's.
        const res = await self.call(
          `${base}/exec`,
          {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({
              cmd,
              cwd: opts.cwd,
              env: opts.env,
              timeoutMs: opts.timeoutMs,
              stdin: opts.stdin,
            }),
            signal: opts.signal,
          },
          streamFetch,
        );
        if (!res.body) throw new SandboxError("supervisor_error", "exec returned no body");
        yield* ndjson<ExecChunk>(res.body);
      },
      kill: async (id) =>
        void (await self.call(`${base}/exec/${encodeURIComponent(id)}/kill`, { method: "POST" })),
      readFile: async (p) =>
        new Uint8Array(
          await (await self.call(`${base}/files?path=${encodeURIComponent(p)}`)).arrayBuffer(),
        ),
      writeFile: async (p, data) =>
        void (await self.call(`${base}/files?path=${encodeURIComponent(p)}`, {
          method: "PUT",
          body: data,
        })),
      deleteFile: async (p) =>
        void (await self.call(`${base}/files?path=${encodeURIComponent(p)}`, { method: "DELETE" })),
      listDir: async (p) =>
        (
          (await (await self.call(`${base}/files/list?path=${encodeURIComponent(p)}`)).json()) as {
            entries: FileEntry[];
          }
        ).entries,
      search: async (q, p) =>
        (
          (await (
            await self.json(`${base}/files/search`, "POST", { query: q, path: p })
          ).json()) as { matches: SearchMatch[] }
        ).matches,
      enableDesktop: async () => {
        const h = (await (await self.call(`${base}/health`)).json()) as HealthStatus;
        if (!h.display)
          throw new SandboxError("desktop_unavailable", "This computer has no desktop", 409);
      },
      screenshot: async () =>
        new Uint8Array(await (await self.call(`${base}/screenshot`)).arrayBuffer()),
      // The supervisor answers 409 when the computer isn't running; it never starts one for this.
      thumbnail: (p, size) =>
        fetchThumbnail(
          `${self.baseUrl}${base}/files/thumbnail?path=${encodeURIComponent(p)}&size=${size}`,
          self.authHeaders,
        ),
      input: async (e: InputEvent) => void (await self.json(`${base}/input`, "POST", e)),
      setMcpServers: async (servers) =>
        void (await self.json(`${base}/mcp-servers`, "PUT", servers)),
      mcpFetch: (key, init) =>
        fetch(`${self.baseUrl}${base}/mcp/${encodeURIComponent(key)}`, {
          ...init,
          headers: { ...(init.headers as Record<string, string>), ...self.authHeaders },
        }),
      streamEndpoint: async (opts = {}) => ({
        url: `${self.baseUrl.replace(/^http/, "ws")}${base}/stream?mode=${opts.mode ?? "view"}`,
        headers: {
          ...self.authHeaders,
          ...(opts.relay ? { [STREAM_RELAY_HEADER]: encodeStreamRelay(opts.relay) } : {}),
        },
      }),
      stopStream: async () => void (await self.json(`${base}/stream/stop`, "POST", {})),
      terminalEndpoint: async (opts = {}) => ({
        url: `${self.baseUrl.replace(/^http/, "ws")}${base}/terminal?cols=${opts.cols ?? 120}&rows=${opts.rows ?? 32}`,
        headers: self.authHeaders,
      }),
      checkpoint: async (label) =>
        (await (
          await self.json(`${base}/checkpoints`, "POST", { label }, slowFetch)
        ).json()) as CheckpointRef,
      restore: async (cp) =>
        void (await self.json(`${base}/checkpoints/restore`, "POST", cp, slowFetch)),
      health: async () => (await (await self.call(`${base}/health`)).json()) as HealthStatus,
    };
  }
}
