import { createAnthropic } from "@ai-sdk/anthropic";
import { createGoogleGenerativeAI } from "@ai-sdk/google";
import { createOpenAI } from "@ai-sdk/openai";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import { createXai } from "@ai-sdk/xai";
import { CLOUD_MAX_OUTPUT_TOKENS } from "@casama/domain";
import {
  APICallError,
  type JSONValue,
  jsonSchema,
  type LanguageModel,
  type ModelMessage,
  streamText,
  type ToolSet,
  tool,
} from "ai";
import { ToolRegistry } from "../tools/registry.ts";
import { type ChatGptOptions, streamChatGpt } from "./chatgpt.ts";
import { type OpenRouterRouting, openRouterFetch } from "./openrouter.ts";
import {
  type ChatMessage,
  type GatewayEvent,
  ModelCallError,
  type ModelGateway,
  type ModelRequest,
  type ResolvedModel,
} from "./types.ts";

export function languageModel(m: ResolvedModel, fetchImpl?: typeof fetch): LanguageModel {
  switch (m.provider) {
    case "openai":
      return createOpenAI({ apiKey: m.apiKey, baseURL: m.baseUrl, headers: m.headers })(m.model);
    case "anthropic":
      return createAnthropic({ apiKey: m.apiKey, baseURL: m.baseUrl, headers: m.headers })(m.model);
    case "google":
      return createGoogleGenerativeAI({ apiKey: m.apiKey, baseURL: m.baseUrl, headers: m.headers })(
        m.model,
      );
    case "xai":
      return createXai({ apiKey: m.apiKey, baseURL: m.baseUrl, headers: m.headers })(m.model);
    case "openrouter":
      return createOpenAICompatible({
        name: "openrouter",
        apiKey: m.apiKey,
        headers: m.headers,
        baseURL: m.baseUrl ?? "https://openrouter.ai/api/v1",
        includeUsage: true,
        fetch: fetchImpl,
      })(m.model);
    case "openai_compatible":
      if (!m.baseUrl)
        throw new ModelCallError("openai_compatible needs a base URL", { retryable: false });
      return createOpenAICompatible({
        name: "custom",
        apiKey: m.apiKey,
        baseURL: m.baseUrl,
        includeUsage: true,
        fetch: fetchImpl,
      })(m.model);
    case "chatgpt":
      // ChatGPT plans use their own adapter (gateway/chatgpt.ts), never the AI SDK.
      throw new ModelCallError("chatgpt models go through streamChatGpt", { retryable: false });
  }
}

/** Reasoning effort in each provider's request format. */
export function reasoningOptions(
  m: ResolvedModel,
): Record<string, Record<string, JSONValue>> | undefined {
  // Anthropic only caches prompts it's asked to: cache everything up to the newest message, so
  // the instructions, tools and conversation so far are read back at a tenth of the price on the
  // next turn (OpenAI, Gemini and xAI cache matching prefixes on their own). See docs/COSTS.md.
  if (m.provider === "anthropic")
    return {
      anthropic: {
        cacheControl: { type: "ephemeral" },
        ...(m.reasoningEffort ? { effort: m.reasoningEffort } : {}),
      },
    };
  if (!m.reasoningEffort) return undefined;
  if (m.provider === "openai") return { openai: { reasoningEffort: m.reasoningEffort } };
  if (m.provider === "openrouter")
    return { openrouter: { reasoning: { effort: m.reasoningEffort } } };
  return undefined;
}

/**
 * Providers whose chat-completions format can't carry pictures in a tool result. The AI SDK would
 * JSON-encode the picture into the tool's text there, so one screenshot became ~600K tokens of
 * base64 resent on every later step until the provider refused the request.
 */
const TOOL_IMAGES_AS_USER = new Set<ResolvedModel["provider"]>(["openrouter", "openai_compatible"]);

export function toModelMessages(
  messages: ChatMessage[],
  opts: { toolImagesAsUser?: boolean } = {},
): ModelMessage[] {
  if (!opts.toolImagesAsUser) return messages.map(toModelMessage);
  // Tool results keep only their text; their pictures follow in one user message after the batch
  // of tool results (tool results must come straight after the call that asked for them).
  const out: ModelMessage[] = [];
  let pending: Array<{ data: string; mediaType: string }> = [];
  const flush = () => {
    if (!pending.length) return;
    out.push({
      role: "user",
      content: [
        { type: "text", text: "The pictures from the tool results above:" },
        ...pending.map((img) => ({
          type: "image" as const,
          image: img.data,
          mediaType: img.mediaType,
        })),
      ],
    });
    pending = [];
  };
  for (const m of messages) {
    if (m.role !== "tool") flush();
    if (m.role === "tool" && m.images?.length) {
      pending.push(...m.images);
      out.push(toModelMessage({ ...m, images: undefined }));
    } else out.push(toModelMessage(m));
  }
  flush();
  return out;
}

function toModelMessage(m: ChatMessage): ModelMessage {
  if (m.role === "user") {
    if (!m.images?.length) return { role: "user", content: m.content };
    return {
      role: "user",
      content: [
        { type: "text" as const, text: m.content },
        ...m.images.map((img) => ({
          type: "image" as const,
          image: img.data,
          mediaType: img.mediaType,
        })),
      ],
    };
  }
  if (m.role === "tool") {
    return {
      role: "tool",
      content: [
        {
          type: "tool-result",
          toolCallId: m.callId,
          toolName: ToolRegistry.wireName(m.name),
          output: m.images?.length
            ? {
                type: "content" as const,
                value: [
                  { type: "text" as const, text: m.content },
                  ...m.images.map((img) => ({
                    type: "file" as const,
                    data: { type: "data" as const, data: img.data },
                    mediaType: img.mediaType,
                  })),
                ],
              }
            : { type: "text" as const, value: m.content },
        },
      ],
    };
  }
  if (!m.toolCalls?.length) return { role: "assistant", content: m.content };
  return {
    role: "assistant",
    content: [
      ...(m.content ? [{ type: "text" as const, text: m.content }] : []),
      ...m.toolCalls.map((c) => ({
        type: "tool-call" as const,
        toolCallId: c.callId,
        toolName: ToolRegistry.wireName(c.name),
        input: c.args,
      })),
    ],
  };
}

function classify(err: unknown, model?: ResolvedModel): ModelCallError {
  if (err instanceof ModelCallError) return err;
  const ownKey = model && !model.platformKey && model.provider !== "chatgpt";
  const keyPrefix =
    ownKey && model.credentialLabel
      ? `Your key "${model.credentialLabel}" (${model.provider})`
      : ownKey
        ? `Your ${model.provider} key`
        : null;
  if (APICallError.isInstance(err)) {
    const status = err.statusCode;
    const body =
      typeof err.responseBody === "string"
        ? err.responseBody
        : JSON.stringify(err.responseBody ?? "");
    if (status === 403 && body.includes("openrouter_key_limit") && !ownKey)
      return new ModelCallError(
        "Casama's model key hit its daily limit. Try again tomorrow, or add your own key.",
        { retryable: false, status, code: "openrouter_key_limit", cause: err },
      );
    const defaultRetryable =
      status === undefined || status === 408 || status === 409 || status === 429 || status >= 500;
    // When "If my provider fails, use Casama's models" (fallbackOnLimit) is on, auth and balance
    // failures (401, 402, 403) on an own key also fall back to the next model in the chain (§3.2).
    const retryable =
      defaultRetryable ||
      Boolean(
        ownKey && model?.fallbackOnLimit && (status === 401 || status === 402 || status === 403),
      );
    // The provider's own reason, so a failed run's Details say why instead of just "400".
    let reason = "";
    try {
      const m = (JSON.parse(body) as { error?: { message?: unknown } })?.error?.message;
      if (typeof m === "string") reason = m.replace(/\s+/g, " ").trim().slice(0, 200);
    } catch {}
    const code =
      ownKey && (status === 401 || status === 403)
        ? "model_auth_failed"
        : ownKey && (status === 402 || status === 429)
          ? "own_provider_limit"
          : undefined;
    const message = keyPrefix
      ? `${keyPrefix} returned ${status ?? "no status"}${reason ? `: ${reason}` : ""}`
      : `provider returned ${status ?? "no status"}${reason ? `: ${reason}` : ""}`;
    return new ModelCallError(message, {
      retryable,
      status,
      code,
      credentialId: model?.credentialId,
      cause: err,
    });
  }
  const name = (err as Error)?.name ?? "";
  if (name === "AbortError") return new ModelCallError("aborted", { retryable: false, cause: err });
  const rawMsg = (err as Error)?.message ?? "model call failed";
  return new ModelCallError(keyPrefix ? `${keyPrefix} failed: ${rawMsg}` : rawMsg, {
    retryable: true,
    credentialId: model?.credentialId,
    cause: err,
  });
}

/** ModelGateway on the Vercel AI SDK. Tools are declared without execute: the agent loop runs them. */
export class AiSdkGateway implements ModelGateway {
  private readonly chatgpt: ChatGptOptions;
  private readonly platformRouting: OpenRouterRouting | undefined;
  private readonly platformChatRouting: OpenRouterRouting | undefined;
  private readonly customFetch: typeof fetch | undefined;
  /**
   * `chatgpt` options are for ChatGPT plans (the fetch is overridable for tests).
   * `platformRouting` picks the providers for calls on the server's shared OpenRouter key (D-354);
   * a workspace's own OpenRouter key keeps the routing set on its OpenRouter account.
   * `platformChatRouting`, when set, replaces it for calls a person is waiting on, so live chat can
   * run on a faster provider while background work stays on the cheapest (D-355).
   * `customFetch` guards `openai_compatible` base URLs on Casama Cloud (§8).
   */
  constructor(
    opts: {
      chatgpt?: ChatGptOptions;
      platformRouting?: OpenRouterRouting;
      platformChatRouting?: OpenRouterRouting;
      customFetch?: typeof fetch;
    } = {},
  ) {
    this.chatgpt = opts.chatgpt ?? {};
    this.platformRouting = opts.platformRouting;
    this.platformChatRouting = opts.platformChatRouting;
    this.customFetch = opts.customFetch;
  }

  async *stream(req: ModelRequest): AsyncIterable<GatewayEvent> {
    if (req.model.provider === "chatgpt") {
      yield* streamChatGpt(req, this.chatgpt);
      return;
    }
    const tools: ToolSet = {};
    for (const t of req.tools ?? []) {
      tools[t.name] = tool({
        description: t.description,
        inputSchema: jsonSchema(t.inputSchema as never),
      });
    }
    let costPromise = Promise.resolve<number | undefined>(undefined);
    const fetchImpl =
      req.model.provider === "openrouter"
        ? openRouterFetch({
            user: req.model.platformKey ? req.model.openRouterUser : undefined,
            denyDataCollection: req.model.platformKey === true,
            routing: req.model.platformKey
              ? (req.interactive && this.platformChatRouting) || this.platformRouting
              : undefined,
            sessionId: req.model.platformKey ? req.sessionId : undefined,
            track: (cost) => {
              costPromise = cost;
            },
          })
        : req.model.provider === "openai_compatible"
          ? this.customFetch
          : undefined;
    let result: ReturnType<typeof streamText>;
    try {
      result = streamText({
        model: languageModel(req.model, fetchImpl),
        system: req.system.join("\n\n"),
        messages: toModelMessages(req.messages, {
          toolImagesAsUser: TOOL_IMAGES_AS_USER.has(req.model.provider),
        }),
        tools: req.tools?.length ? tools : undefined,
        maxOutputTokens: req.model.platformKey
          ? Math.min(req.maxOutputTokens ?? CLOUD_MAX_OUTPUT_TOKENS, CLOUD_MAX_OUTPUT_TOKENS)
          : req.maxOutputTokens,
        providerOptions: reasoningOptions(req.model),
        abortSignal: req.abortSignal,
        maxRetries: 0,
      });
    } catch (err) {
      throw classify(err, req.model);
    }
    try {
      for await (const part of result.fullStream) {
        if (part.type === "text-delta") yield { type: "text", text: part.text };
        else if (part.type === "tool-call") {
          yield {
            type: "tool_call",
            call: {
              callId: part.toolCallId,
              name: part.toolName,
              args: (part.input ?? {}) as Record<string, unknown>,
            },
          };
        } else if (part.type.startsWith("reasoning") || part.type.startsWith("tool-input")) {
          // Thinking, and a long tool call being written: not shown, but not silence either.
          yield { type: "progress" };
        } else if (part.type === "error") throw part.error;
        else if (part.type === "abort") throw new ModelCallError("aborted", { retryable: false });
        else if (part.type === "finish") {
          const providerCostUsd = await costPromise;
          yield {
            type: "finish",
            finishReason: part.finishReason,
            model: req.model.model,
            usage: {
              inputTokens: part.totalUsage.inputTokens ?? 0,
              outputTokens: part.totalUsage.outputTokens ?? 0,
              ...(part.totalUsage.inputTokenDetails?.cacheReadTokens
                ? { cachedInputTokens: part.totalUsage.inputTokenDetails.cacheReadTokens }
                : {}),
              ...(part.totalUsage.inputTokenDetails?.cacheWriteTokens
                ? { cacheWriteTokens: part.totalUsage.inputTokenDetails.cacheWriteTokens }
                : {}),
              ...(providerCostUsd !== undefined ? { providerCostUsd } : {}),
              ...(part.totalUsage.outputTokenDetails?.reasoningTokens
                ? { reasoningTokens: part.totalUsage.outputTokenDetails.reasoningTokens }
                : {}),
            },
          };
        }
      }
    } catch (err) {
      throw classify(err, req.model);
    }
  }
}
