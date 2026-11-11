/** The interface every computer provider implements (Docker, E2B, Daytona, local, cloud). */

export type ProviderId =
  | "docker"
  | "e2b"
  | "daytona"
  | "local"
  | "casama-cloud"
  // More hosted providers (D-139).
  | "novita"
  | "kubernetes"
  | "incus"
  | "railway"
  | "boat";

export interface ComputerSpec {
  /** Stable id for the computer (the computers.id uuid). */
  ref: string;
  profile: "headless" | "desktop";
  size?: { cpus?: number; memoryMb?: number; diskGb?: number };
  /** Extra environment variables (never secrets: those are injected per call). */
  env?: Record<string, string>;
  labels?: Record<string, string>;
}

export interface ExecOptions {
  cwd?: string;
  env?: Record<string, string>;
  timeoutMs?: number;
  stdin?: string;
  signal?: AbortSignal;
}

export type ExecChunk =
  | { type: "start"; execId: string }
  | { type: "stdout" | "stderr"; data: string }
  | { type: "exit"; code: number; timedOut: boolean; killed: boolean; truncated: boolean };

export interface FileEntry {
  name: string;
  path: string;
  type: "file" | "dir" | "link";
  size: number;
  modified: string;
}

export interface SearchMatch {
  path?: string;
  line?: number;
  text?: string;
}

export type InputEvent =
  | { type: "move"; x: number; y: number }
  | { type: "click"; x: number; y: number; button?: 1 | 2 | 3 }
  | { type: "type"; text: string }
  | { type: "key"; key: string }
  | { type: "scroll"; dy: number };

/** Where to open the live-view signaling WebSocket (Neko protocol, D-054). */
export interface StreamEndpoint {
  url: string;
  headers: Record<string, string>;
}

export type StreamMode = "view" | "control";

/** A stored archive of a computer's home directory. */
export interface SnapshotRef {
  key: string;
  size: number;
  createdAt: string;
}

export interface CheckpointRef extends SnapshotRef {
  id: string;
  label: string;
}

export interface HealthStatus {
  ok: boolean;
  uptimeS: number;
  runningExecs: number;
  openTerminals: number;
  idleS: number;
  diskFreeBytes: number;
  display: boolean;
}

export interface SandboxProvider {
  readonly id: ProviderId;
  readonly capabilities: { desktop: boolean; snapshots: boolean; liveStream: boolean };
  create(spec: ComputerSpec): Promise<SandboxHandle>;
  /** Starts the computer again, restoring the snapshot into its home when given. */
  resume(ref: string, snapshot?: SnapshotRef, spec?: Partial<ComputerSpec>): Promise<SandboxHandle>;
  /** Returns a handle to a running computer, or null. */
  get(ref: string): Promise<SandboxHandle | null>;
  sleep(ref: string): Promise<SnapshotRef>; // save home dir, then stop
  destroy(ref: string): Promise<void>;
}

export interface SandboxHandle {
  readonly ref: string;
  exec(cmd: string, opts?: ExecOptions): AsyncIterable<ExecChunk>;
  kill(execId: string): Promise<void>;
  readFile(path: string): Promise<Uint8Array>;
  writeFile(path: string, data: Uint8Array): Promise<void>;
  deleteFile(path: string): Promise<void>;
  listDir(path: string): Promise<FileEntry[]>;
  search(query: string, path?: string): Promise<SearchMatch[]>;
  enableDesktop(): Promise<void>; // start X server, window manager, streamer
  screenshot(): Promise<Uint8Array>;
  input(event: InputEvent): Promise<void>; // mouse and keyboard
  /** Starts the streamer if needed and returns the signaling target for a viewer or controller. */
  streamEndpoint(opts?: { mode?: StreamMode }): Promise<StreamEndpoint>;
  /** Stops the streamer (called 60 s after the last viewer leaves). */
  stopStream(): Promise<void>;
  /** Opens an interactive terminal (WebSocket URL plus auth headers). */
  terminalEndpoint(opts?: {
    cols?: number;
    rows?: number;
  }): Promise<{ url: string; headers: Record<string, string> }>;
  checkpoint(label: string): Promise<CheckpointRef>;
  restore(id: CheckpointRef): Promise<void>;
  health(): Promise<HealthStatus>;
  /** Replaces the MCP servers computerd runs inside the computer (plugins, D-121). */
  setMcpServers?(servers: Record<string, McpServerSpec>): Promise<void>;
  /** One MCP Streamable HTTP request to a server computerd runs (plugins, D-121). */
  mcpFetch?(key: string, init: RequestInit): Promise<Response>;
  /** Where a relative path really points, relative to ~/workspace (team computer folders, D-148). */
  resolvePath?(path: string): string;
  /** Personal computers only: a handle whose calls tell the user which bot is acting (D-066). */
  withActivity?(activity: {
    run_id: string;
    bot: string;
    tool: string;
    summary: string;
  }): SandboxHandle;
}

/** An MCP server computerd starts and bridges (`POST /mcp/<key>`). */
export interface McpServerSpec {
  kind: "stdio";
  command: string;
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
}

export class SandboxError extends Error {
  readonly code: string;
  readonly status?: number;
  constructor(code: string, message: string, status?: number) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

/** Collects an exec stream into output and exit code. */
export async function collectExec(stream: AsyncIterable<ExecChunk>) {
  let stdout = "";
  let stderr = "";
  let exit: Extract<ExecChunk, { type: "exit" }> | undefined;
  let execId = "";
  for await (const c of stream) {
    if (c.type === "start") execId = c.execId;
    else if (c.type === "stdout") stdout += c.data;
    else if (c.type === "stderr") stderr += c.data;
    else if (c.type === "exit") exit = c;
  }
  return {
    execId,
    stdout,
    stderr,
    code: exit?.code ?? -1,
    timedOut: exit?.timedOut ?? false,
    killed: exit?.killed ?? false,
    truncated: exit?.truncated ?? false,
  };
}
