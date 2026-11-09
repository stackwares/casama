/** Neutral model types: nothing here depends on a vendor SDK. */

export type ProviderId =
  | "openai"
  | "anthropic"
  | "google"
  | "xai"
  | "openrouter"
  | "openai_compatible";

/** A model choice from a bot's model_policy. */
export interface ModelChoice {
  credential_id: string;
  model: string;
  reasoning_effort?: "none" | "low" | "medium" | "high" | "xhigh" | "max";
}

/** A model choice with its credential resolved (the key never leaves the worker). */
export interface ResolvedModel {
  provider: ProviderId;
  model: string;
  apiKey?: string;
  baseUrl?: string;
  credentialId?: string;
  /** Reasoning effort for reasoning models (OpenAI and OpenRouter). */
  reasoningEffort?: "none" | "low" | "medium" | "high" | "xhigh" | "max";
}

export type ChatMessage =
  | { role: "user"; content: string; images?: Array<{ data: Uint8Array; mediaType: string }> }
  | { role: "assistant"; content: string; toolCalls?: ToolCall[] }
  | { role: "tool"; callId: string; name: string; content: string };

export interface ToolCall {
  callId: string;
  name: string;
  args: Record<string, unknown>;
}

export interface ToolSpec {
  name: string;
  description: string;
  /** JSON Schema of the arguments object. */
  inputSchema: Record<string, unknown>;
}

export interface Usage {
  inputTokens: number;
  outputTokens: number;
}

export type GatewayEvent =
  | { type: "text"; text: string }
  | { type: "tool_call"; call: ToolCall }
  | { type: "finish"; usage: Usage; finishReason: string; model: string };

export interface ModelRequest {
  model: ResolvedModel;
  /** System blocks, in order. The first blocks are kept byte-stable for prompt caching. */
  system: string[];
  messages: ChatMessage[];
  tools?: ToolSpec[];
  maxOutputTokens?: number;
  abortSignal?: AbortSignal;
}

export interface ModelGateway {
  stream(req: ModelRequest): AsyncIterable<GatewayEvent>;
}

/** Error from a provider call, classified for failover. */
export class ModelCallError extends Error {
  readonly retryable: boolean;
  readonly status?: number;
  constructor(message: string, opts: { retryable: boolean; status?: number; cause?: unknown }) {
    super(message, { cause: opts.cause });
    this.retryable = opts.retryable;
    this.status = opts.status;
  }
}

/** Collects a stream into text, tool calls and usage. */
export async function collect(stream: AsyncIterable<GatewayEvent>) {
  let text = "";
  const toolCalls: ToolCall[] = [];
  let usage: Usage = { inputTokens: 0, outputTokens: 0 };
  let finishReason = "stop";
  let model = "";
  for await (const ev of stream) {
    if (ev.type === "text") text += ev.text;
    else if (ev.type === "tool_call") toolCalls.push(ev.call);
    else {
      usage = ev.usage;
      finishReason = ev.finishReason;
      model = ev.model;
    }
  }
  return { text, toolCalls, usage, finishReason, model };
}
