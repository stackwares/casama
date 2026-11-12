import { ndjson } from "./ndjson.ts";
import {
  type ExecChunk,
  type ExecOptions,
  type FileEntry,
  type FileThumbnail,
  type HealthStatus,
  type InputEvent,
  SandboxError,
  type SearchMatch,
} from "./types.ts";

type RawChunk =
  | { type: "start"; exec_id: string }
  | { type: "stdout" | "stderr"; data: string }
  | { type: "exit"; code: number; timed_out: boolean; killed: boolean; truncated: boolean };

/** HTTP client for computerd, the daemon inside each computer. */
export class ComputerdClient {
  readonly baseUrl: string;
  private readonly token: string;
  private readonly extraHeaders: Record<string, string>;
  /** extraHeaders: sent with every call (for example a hosted provider's preview token). */
  constructor(baseUrl: string, token: string, extraHeaders: Record<string, string> = {}) {
    this.baseUrl = baseUrl.replace(/\/$/, "");
    this.token = token;
    this.extraHeaders = extraHeaders;
  }

  get authHeaders(): Record<string, string> {
    // When the route to computerd needs Authorization for itself (the Kubernetes API server's pod
    // proxy, D-139), computerd's token goes in its own header.
    if (Object.keys(this.extraHeaders).some((k) => k.toLowerCase() === "authorization"))
      return { ...this.extraHeaders, "x-computerd-token": this.token };
    return { ...this.extraHeaders, authorization: `Bearer ${this.token}` };
  }

  private async call(path: string, init: RequestInit = {}, expectOk = true) {
    let res: Response;
    try {
      res = await fetch(`${this.baseUrl}${path}`, {
        ...init,
        headers: { ...this.authHeaders, ...(init.headers as Record<string, string>) },
      });
    } catch (err) {
      throw new SandboxError(
        "computer_unreachable",
        `computerd unreachable: ${(err as Error).message}`,
      );
    }
    if (expectOk && !res.ok) {
      const body = (await res.json().catch(() => ({}))) as { code?: string; message?: string };
      throw new SandboxError(
        body.code ?? "computerd_error",
        body.message ?? `computerd returned ${res.status}`,
        res.status,
      );
    }
    return res;
  }

  async *exec(cmd: string, opts: ExecOptions = {}): AsyncIterable<ExecChunk> {
    const res = await this.call("/exec", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        cmd,
        cwd: opts.cwd,
        env: opts.env,
        timeout_ms: opts.timeoutMs,
        stdin: opts.stdin,
      }),
      signal: opts.signal,
    });
    if (!res.body) throw new SandboxError("computerd_error", "exec returned no body");
    for await (const c of ndjson<RawChunk>(res.body)) {
      if (c.type === "start") yield { type: "start", execId: c.exec_id };
      else if (c.type === "exit")
        yield {
          type: "exit",
          code: c.code,
          timedOut: c.timed_out,
          killed: c.killed,
          truncated: c.truncated,
        };
      else yield c;
    }
  }

  async kill(execId: string) {
    await this.call(`/exec/${encodeURIComponent(execId)}/kill`, { method: "POST" });
  }

  async readFile(path: string) {
    const res = await this.call(`/files?path=${encodeURIComponent(path)}`);
    return new Uint8Array(await res.arrayBuffer());
  }

  async writeFile(path: string, data: Uint8Array) {
    await this.call(`/files?path=${encodeURIComponent(path)}`, { method: "PUT", body: data });
  }

  async deleteFile(path: string) {
    await this.call(`/files?path=${encodeURIComponent(path)}`, { method: "DELETE" });
  }

  async listDir(path: string): Promise<FileEntry[]> {
    const res = await this.call(`/files/list?path=${encodeURIComponent(path)}`);
    return ((await res.json()) as { entries: FileEntry[] }).entries;
  }

  async search(query: string, path?: string): Promise<SearchMatch[]> {
    const res = await this.call("/files/search", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ query, path }),
    });
    return ((await res.json()) as { matches: SearchMatch[] }).matches;
  }

  /** Streams a gzip tarball of the home directory. */
  async archive(): Promise<ReadableStream<Uint8Array>> {
    const res = await this.call("/archive", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{}",
    });
    if (!res.body) throw new SandboxError("computerd_error", "archive returned no body");
    return res.body;
  }

  /** Replaces the home directory with a gzip tarball. */
  async restore(archive: Uint8Array | ReadableStream<Uint8Array>) {
    await this.call("/restore", { method: "POST", body: archive, duplex: "half" } as RequestInit);
  }

  async health(): Promise<HealthStatus> {
    const res = await this.call("/health");
    const h = (await res.json()) as Record<string, number | boolean>;
    return {
      ok: Boolean(h.ok),
      uptimeS: Number(h.uptime_s ?? 0),
      runningExecs: Number(h.running_execs ?? 0),
      openTerminals: Number(h.open_terminals ?? 0),
      idleS: Number(h.idle_s ?? 0),
      diskFreeBytes: Number(h.disk_free_bytes ?? -1),
      display: Boolean(h.display),
    };
  }

  async setMcpServers(servers: Record<string, import("./types.ts").McpServerSpec>) {
    await this.call("/mcp-servers", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(servers),
    });
  }

  /** Raw MCP request to a bridged server; the caller reads the status and body. */
  async mcpFetch(key: string, init: RequestInit) {
    try {
      return await fetch(`${this.baseUrl}/mcp/${encodeURIComponent(key)}`, {
        ...init,
        headers: { ...(init.headers as Record<string, string>), ...this.authHeaders },
      });
    } catch (err) {
      throw new SandboxError(
        "computer_unreachable",
        `computerd unreachable: ${(err as Error).message}`,
      );
    }
  }

  /** A file's thumbnail (D-226), or null when computerd has none for it. */
  async thumbnail(path: string, size: number): Promise<FileThumbnail | null> {
    return fetchThumbnail(
      `${this.baseUrl}/files/thumbnail?path=${encodeURIComponent(path)}&size=${size}`,
      this.authHeaders,
    );
  }

  async screenshot() {
    const res = await this.call("/screenshot");
    try {
      return new Uint8Array(await res.arrayBuffer());
    } catch (err) {
      // The computer went away mid-response (stopping or restarting): undici says "terminated".
      throw new SandboxError(
        "computer_unreachable",
        `computerd unreachable: ${(err as Error).message}`,
      );
    }
  }

  async input(event: InputEvent) {
    await this.call("/input", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(event),
    });
  }

  /** Starts the Neko streamer (idempotent) and returns its port and per-start logins. */
  async streamStart(body: { ice_servers?: unknown[]; screen?: string } = {}) {
    const res = await this.call("/stream/start", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    return (await res.json()) as {
      port: number;
      users: Record<"viewer" | "controller", { username: string; password: string }>;
    };
  }

  async streamStop() {
    await this.call("/stream/stop", { method: "POST" });
  }

  terminalUrl(opts: { cols?: number; rows?: number } = {}) {
    const ws = this.baseUrl.replace(/^http/, "ws");
    return `${ws}/terminal?cols=${opts.cols ?? 120}&rows=${opts.rows ?? 32}`;
  }

  /** Waits until computerd answers /health. */
  async waitReady(timeoutMs = 30_000) {
    const until = Date.now() + timeoutMs;
    for (;;) {
      try {
        const res = await fetch(`${this.baseUrl}/health`, { headers: this.extraHeaders });
        if (res.ok) return;
      } catch {}
      if (Date.now() > until)
        throw new SandboxError("computer_start_timeout", "computerd did not become ready");
      await new Promise((r) => setTimeout(r, 150));
    }
  }
}

/**
 * computerd's queue plus its 8-second tool limit, with room for the relay. A thumbnail that takes
 * longer isn't worth waiting for: the app shows its plain tile.
 */
export const THUMBNAIL_TIMEOUT_MS = 15_000;

/** GET a `/files/thumbnail` response (computerd, the supervisor or the device tunnel). */
export async function fetchThumbnail(
  url: string,
  headers: Record<string, string>,
): Promise<FileThumbnail | null> {
  let res: Response;
  try {
    res = await fetch(url, { headers, signal: AbortSignal.timeout(THUMBNAIL_TIMEOUT_MS) });
  } catch (err) {
    throw new SandboxError(
      "computer_unreachable",
      `computerd unreachable: ${(err as Error).message}`,
    );
  }
  if (res.status === 404) {
    await res.body?.cancel().catch(() => {});
    return null;
  }
  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as { code?: string; message?: string };
    throw new SandboxError(
      body.code ?? "computerd_error",
      body.message ?? `computerd returned ${res.status}`,
      res.status,
    );
  }
  const num = (h: string) => {
    const v = Number(res.headers.get(h) ?? Number.NaN);
    return Number.isFinite(v) && v >= 0 ? v : undefined;
  };
  return {
    data: new Uint8Array(await res.arrayBuffer()),
    contentType: res.headers.get("content-type") ?? "image/jpeg",
    mtimeMs: num("x-file-mtime"),
    durationMs: num("x-duration-ms"),
  };
}
