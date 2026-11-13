/** Neutral model types: nothing here depends on a vendor SDK. */

export type ProviderId =
  | "openai"
  | "anthropic"
  | "google"
  | "xai"
  | "openrouter"
  | "openai_compatible"
  /** A person's ChatGPT plan (ChatGPT plan sign-in): Responses API with an OAuth access token. */
  | "chatgpt";

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
  /** Reasoning effort for reasoning models (OpenAI, OpenRouter and ChatGPT plans). */
  reasoningEffort?: "none" | "low" | "medium" | "high" | "xhigh" | "max";
  /** chatgpt: the owner allows moving to the next model when the plan limit is reached. */
  fallbackOnLimit?: boolean;
  /** Extra request headers (an authenticated Cloudflare AI Gateway, D-145). */
  headers?: Record<string, string>;
  /** Casama Cloud's shared OpenRouter key (D-186). */
  platformKey?: boolean;
  /** Sent as OpenRouter's `user`, so one workspace can't get the whole account blocked. */
  openRouterUser?: string;
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
  /** The provider may load this tool on demand (native deferred tools; D-106). */
  deferred?: boolean;
}

export interface Usage {
  inputTokens: number;
  outputTokens: number;
  /** Input tokens served from the provider's prompt cache, when it reports them. */
  cachedInputTokens?: number;
  /** Input tokens written to the prompt cache (Anthropic charges these at 1.25×). */
  cacheWriteTokens?: number;
  /** What the provider reported the call cost, in USD (OpenRouter's `usage.cost`). */
  providerCostUsd?: number;
}

export type GatewayEvent =
  | { type: "text"; text: string }
  /**
   * The model is working but has produced nothing to show yet: thinking, or writing a tool call's
   * arguments. It only keeps the silence timers from firing (D-268); withFallback doesn't pass it on.
   */
  | { type: "progress" }
  | { type: "tool_call"; call: ToolCall }
  | {
      type: "finish";
      usage: Usage;
      finishReason: string;
      model: string;
      /** Set by adapters whose usage is billed elsewhere (a ChatGPT plan costs Casama nothing). */
      provider?: ProviderId;
    };

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
  /** A stable error code for the run's error (for example chatgpt_plan_limit). */
  readonly code?: string;
  /** The credential the failing call used, when the error is about that credential. */
  readonly credentialId?: string;
  constructor(
    message: string,
    opts: {
      retryable: boolean;
      status?: number;
      cause?: unknown;
      code?: string;
      credentialId?: string;
    },
  ) {
    super(message, { cause: opts.cause });
    this.retryable = opts.retryable;
    this.status = opts.status;
    this.code = opts.code;
    this.credentialId = opts.credentialId;
  }
}

/** Collects a stream into text, tool calls and usage. */
export async function collect(stream: AsyncIterable<GatewayEvent>) {
  let text = "";
  const toolCalls: ToolCall[] = [];
  let usage: Usage = { inputTokens: 0, outputTokens: 0 };
  let finishReason = "stop";
  let model = "";
  let provider: ProviderId | undefined;
  for await (const ev of stream) {
    if (ev.type === "text") text += ev.text;
    else if (ev.type === "tool_call") toolCalls.push(ev.call);
    else if (ev.type === "finish") {
      usage = ev.usage;
      finishReason = ev.finishReason;
      model = ev.model;
      provider = ev.provider;
    }
  }
  return { text, toolCalls, usage, finishReason, model, provider };
}
