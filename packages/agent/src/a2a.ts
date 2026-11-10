/**
 * Agent-to-agent (SPEC: Agent-to-agent; D-140), A2A protocol v1.0 over its JSON-RPC binding:
 * agent cards at /.well-known/agent-card.json, methods SendMessage, GetTask, CancelTask and
 * ListTasks, `A2A-Version: 1.0`, messages with role ROLE_USER/ROLE_AGENT and text parts
 * `{ text }`, and tasks whose status.state is one of TASK_STATE_*. Written from the public spec.
 *
 * This file holds the shared shapes and the client: an external A2A agent added as an
 * integration (`kind = a2a`) becomes one tool, `a2a.<name>.send`, for the bots it's attached to.
 */
import { randomUUID } from "node:crypto";
import type { CallToolOptions, IntegrationAdapter, IntegrationRecord } from "./integrations.ts";

export const A2A_VERSION = "1.0";
export type A2aState =
  | "TASK_STATE_SUBMITTED"
  | "TASK_STATE_WORKING"
  | "TASK_STATE_COMPLETED"
  | "TASK_STATE_FAILED"
  | "TASK_STATE_CANCELED"
  | "TASK_STATE_INPUT_REQUIRED"
  | "TASK_STATE_REJECTED"
  | "TASK_STATE_AUTH_REQUIRED";
export const TERMINAL: A2aState[] = ["TASK_STATE_COMPLETED", "TASK_STATE_FAILED", "TASK_STATE_CANCELED", "TASK_STATE_REJECTED"];

export interface A2aPart {
  text?: string;
  url?: string;
  raw?: string;
  filename?: string;
  mediaType?: string;
  data?: unknown;
}
export interface A2aMessage {
  role: "ROLE_USER" | "ROLE_AGENT";
  parts: A2aPart[];
  messageId: string;
  contextId?: string;
  taskId?: string;
}
export interface A2aTask {
  id: string;
  contextId: string;
  status: { state: A2aState; message?: A2aMessage; timestamp?: string };
  artifacts?: Array<{ artifactId: string; name?: string; parts: A2aPart[] }>;
  history?: A2aMessage[];
}
export interface A2aAgentCard {
  name: string;
  description: string;
  version: string;
  supportedInterfaces: Array<{ url: string; protocolBinding: string; protocolVersion: string }>;
  capabilities: { streaming?: boolean; pushNotifications?: boolean };
  defaultInputModes: string[];
  defaultOutputModes: string[];
  skills: Array<{ id: string; name: string; description: string; tags: string[]; examples?: string[] }>;
  securitySchemes?: Record<string, unknown>;
  securityRequirements?: Array<Record<string, string[]>>;
}

export const a2aPartsText = (parts: A2aPart[] | undefined) =>
  (parts ?? [])
    .map((p) => p.text ?? (p.url ? `[file: ${p.filename ?? p.url}]` : p.data !== undefined ? JSON.stringify(p.data) : ""))
    .filter(Boolean)
    .join("\n");

/** The agent's answer in a task: its artifacts, else its latest status message. */
export function taskText(t: A2aTask) {
  const fromArtifacts = (t.artifacts ?? []).map((a) => a2aPartsText(a.parts)).filter(Boolean).join("\n\n");
  return fromArtifacts || a2aPartsText(t.status.message?.parts);
}

export class A2aError extends Error {
  readonly code: number;
  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

/** A JSON-RPC client for one A2A agent. */
export class A2aClient {
  private readonly o: { url: string; token: string | null; fetch: typeof fetch };
  private endpoint: string | null = null;
  card: A2aAgentCard | null = null;
  constructor(o: { url: string; token?: string | null; fetch?: typeof fetch }) {
    this.o = { url: o.url.replace(/\/$/, ""), token: o.token ?? null, fetch: o.fetch ?? fetch };
  }
  private headers() {
    return { "content-type": "application/json", accept: "application/json", "a2a-version": A2A_VERSION, ...(this.o.token ? { authorization: `Bearer ${this.o.token}` } : {}) };
  }

  /** Reads the agent card and picks its JSON-RPC interface. */
  async discover() {
    if (this.card) return this.card;
    const cardUrl = this.o.url.endsWith(".json") ? this.o.url : `${this.o.url}/.well-known/agent-card.json`;
    const res = await this.o.fetch(cardUrl, { headers: { accept: "application/json", ...(this.o.token ? { authorization: `Bearer ${this.o.token}` } : {}) } });
    if (!res.ok) throw new Error(`The agent card at ${cardUrl} answered ${res.status}`);
    const card = (await res.json()) as A2aAgentCard & { url?: string };
    const rpc = (card.supportedInterfaces ?? []).find((i) => i.protocolBinding === "JSONRPC" && String(i.protocolVersion).startsWith("1"));
    this.endpoint = rpc?.url ?? card.url ?? this.o.url.replace(/\/\.well-known\/agent-card\.json$/, "");
    if (!rpc && !card.url) throw new Error(`${card.name ?? "The agent"} doesn't offer A2A ${A2A_VERSION} over JSON-RPC`);
    this.card = card;
    return card;
  }

  async rpc<T>(method: string, params: Record<string, unknown>, signal?: AbortSignal): Promise<T> {
    await this.discover();
    const res = await this.o.fetch(this.endpoint as string, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ jsonrpc: "2.0", id: randomUUID(), method, params }),
      signal,
    });
    const text = await res.text();
    let body: { result?: T; error?: { code: number; message: string } };
    try {
      body = JSON.parse(text);
    } catch {
      throw new Error(`The agent answered ${res.status}: ${text.slice(0, 200)}`);
    }
    if (body.error) throw new A2aError(body.error.code, body.error.message);
    if (!res.ok) throw new Error(`The agent answered ${res.status}`);
    return body.result as T;
  }

  /** Sends a task and waits (polling GetTask) until it's done, needs input, or the time runs out. */
  async send(text: string, opts: { contextId?: string; taskId?: string; signal?: AbortSignal; onProgress?: (s: string) => void; waitMs?: number } = {}) {
    const message: A2aMessage = {
      role: "ROLE_USER",
      parts: [{ text }],
      messageId: randomUUID(),
      ...(opts.contextId ? { contextId: opts.contextId } : {}),
      ...(opts.taskId ? { taskId: opts.taskId } : {}),
    };
    const r = await this.rpc<{ task?: A2aTask; message?: A2aMessage }>(
      "SendMessage",
      { message, configuration: { acceptedOutputModes: ["text/plain", "application/json"], returnImmediately: false } },
      opts.signal,
    );
    if (r.message) return { kind: "message" as const, text: a2aPartsText(r.message.parts), contextId: r.message.contextId ?? null, task: null };
    let task = r.task as A2aTask;
    const until = Date.now() + (opts.waitMs ?? 10 * 60_000);
    while (!TERMINAL.includes(task.status.state) && task.status.state !== "TASK_STATE_INPUT_REQUIRED" && task.status.state !== "TASK_STATE_AUTH_REQUIRED") {
      if (Date.now() > until) break;
      if (opts.signal?.aborted) throw new Error("cancelled");
      opts.onProgress?.(a2aPartsText(task.status.message?.parts) || task.status.state.replace("TASK_STATE_", "").toLowerCase());
      await new Promise((res) => setTimeout(res, 1500));
      task = await this.rpc<A2aTask>("GetTask", { id: task.id }, opts.signal);
    }
    return { kind: "task" as const, text: taskText(task), contextId: task.contextId, task };
  }
}

/** An external A2A agent as an integration: one `send` tool described by its agent card. */
export class A2aAdapter implements IntegrationAdapter {
  private readonly client: A2aClient;
  constructor(rec: IntegrationRecord, ctx: { fetch: typeof fetch }) {
    if (typeof rec.config.url !== "string") throw new Error("A2A integrations need config.url (the agent's address or agent card)");
    this.client = new A2aClient({ url: rec.config.url, token: rec.secret, fetch: ctx.fetch });
  }

  async listTools() {
    const card = await this.client.discover();
    const skills = (card.skills ?? []).map((s) => `${s.name}: ${s.description}`).join("; ");
    return [
      {
        name: "send",
        description: `Hand a task to ${card.name}, an outside AI agent (A2A): ${card.description}${skills ? ` Skills: ${skills}` : ""}. Returns its answer. To continue the same conversation, pass the context_id from its last answer.`.slice(0, 1024),
        inputSchema: {
          type: "object",
          properties: {
            task: { type: "string", description: "What you want it to do, with everything it needs" },
            context_id: { type: "string", description: "Continue an earlier conversation with this agent" },
            task_id: { type: "string", description: "Answer a task that asked you for more input" },
          },
          required: ["task"],
        },
        risk: "medium" as const,
      },
    ];
  }

  async callTool(name: string, args: Record<string, unknown>, opts: CallToolOptions = {}) {
    if (name !== "send") throw new Error(`No tool ${name}`);
    const r = await this.client.send(String(args.task ?? ""), {
      contextId: typeof args.context_id === "string" ? args.context_id : undefined,
      taskId: typeof args.task_id === "string" ? args.task_id : undefined,
      signal: opts.signal,
      onProgress: opts.onProgress,
    });
    const state = r.task?.status.state;
    const note =
      state === "TASK_STATE_INPUT_REQUIRED"
        ? `\n\n[The agent needs more input. Reply with send, task_id ${r.task?.id} and context_id ${r.contextId}.]`
        : state && !TERMINAL.includes(state)
          ? `\n\n[Still ${state.replace("TASK_STATE_", "").toLowerCase()} (task_id ${r.task?.id}).]`
          : state === "TASK_STATE_FAILED" || state === "TASK_STATE_REJECTED"
            ? `\n\n[The agent ${state === "TASK_STATE_FAILED" ? "failed" : "declined"} this task.]`
            : "";
    return `${r.text || "(no text answer)"}${note}${r.contextId ? `\n\n(context_id: ${r.contextId})` : ""}`;
  }
}
