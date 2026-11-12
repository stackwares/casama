/**
 * The `local` provider (D-066): a bot's computer is the user's own machine running the Casama
 * desktop app, which embeds computerd and connects to the API over a WebSocket. The worker reaches
 * it through the API's internal tunnel endpoint; there is nothing to create, sleep or destroy.
 */
import { ComputerdClient } from "./computerd-client.ts";
import {
  type CheckpointRef,
  type ExecOptions,
  type InputEvent,
  SandboxError,
  type SandboxHandle,
  type SandboxProvider,
  type SnapshotRef,
} from "./types.ts";

export interface LocalProviderOptions {
  /** The API's base URL as the worker reaches it. */
  apiUrl: string;
  /** Shared secret for /internal/local/* (derived from server secrets). */
  internalToken: string;
}

type Activity = { run_id: string; bot: string; tool: string; summary: string };

export class LocalProvider implements SandboxProvider {
  readonly id = "local" as const;
  readonly capabilities = { desktop: true, snapshots: false, liveStream: false };
  readonly opts: LocalProviderOptions;

  constructor(opts: LocalProviderOptions) {
    this.opts = { ...opts, apiUrl: opts.apiUrl.replace(/\/$/, "") };
  }

  private offline(ref: string): never {
    throw new SandboxError(
      "device_offline",
      `The computer ${ref} is offline. Open the Casama app on it and turn on "Use this computer for bots".`,
      409,
    );
  }

  async online(ref: string) {
    const res = await fetch(`${this.opts.apiUrl}/internal/local/${ref}/status`, {
      headers: { "x-casama-internal": this.opts.internalToken },
      signal: AbortSignal.timeout(5000),
    }).catch(() => null);
    if (!res?.ok) return false;
    return ((await res.json()) as { online: boolean }).online;
  }

  async create(spec: { ref: string }) {
    if (!(await this.online(spec.ref))) this.offline(spec.ref);
    return this.handle(spec.ref);
  }

  async resume(ref: string) {
    return this.create({ ref });
  }

  async get(ref: string) {
    return (await this.online(ref)) ? this.handle(ref) : null;
  }

  async sleep(_ref: string): Promise<SnapshotRef> {
    // Personal computers are never archived; "sleep" just stops using it.
    return { key: "", size: 0, createdAt: new Date().toISOString() };
  }

  async destroy() {}

  handle(ref: string, activity?: Activity): SandboxHandle {
    const headers: Record<string, string> = {
      "x-casama-internal": this.opts.internalToken,
      ...(activity
        ? { "x-casama-activity": Buffer.from(JSON.stringify(activity)).toString("base64") }
        : {}),
    };
    // The tunnel authenticates to the device's computerd itself; this token is unused there.
    const c = new ComputerdClient(
      `${this.opts.apiUrl}/internal/local/${ref}/http`,
      "tunnel",
      headers,
    );
    const unsupported = (what: string) => async (): Promise<never> => {
      throw new SandboxError(
        "not_on_companion",
        `${what} is not available on a personal computer`,
        409,
      );
    };
    return {
      ref,
      exec: (cmd: string, opts?: ExecOptions) => c.exec(cmd, opts),
      kill: (id) => c.kill(id),
      readFile: (p) => c.readFile(p),
      writeFile: (p, data) => c.writeFile(p, data),
      deleteFile: (p) => c.deleteFile(p),
      listDir: (p) => c.listDir(p),
      search: (q, p) => c.search(q, p),
      enableDesktop: async () => {},
      screenshot: () => c.screenshot(),
      input: (e: InputEvent) => c.input(e),
      streamEndpoint: unsupported("Live view"),
      stopStream: async () => {},
      terminalEndpoint: unsupported("The terminal"),
      checkpoint: unsupported("Checkpoints") as (label: string) => Promise<CheckpointRef>,
      restore: unsupported("Checkpoints"),
      health: () => c.health(),
      withActivity: (a) => this.handle(ref, a),
    };
  }
}

/** Base provider when no sandbox supervisor is configured: only personal computers work. */
export function unavailableProvider(): SandboxProvider {
  const no = async (): Promise<never> => {
    throw new SandboxError(
      "computers_unavailable",
      "This server has no sandbox for bot computers. Use a personal computer (desktop app) instead.",
      409,
    );
  };
  return {
    id: "docker",
    capabilities: { desktop: false, snapshots: false, liveStream: false },
    create: no,
    resume: no,
    get: async () => null,
    sleep: no,
    destroy: async () => {},
  };
}
