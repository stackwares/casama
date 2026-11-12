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
import { openRouterFetch } from "./openrouter.ts";
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
  if (m.provider === "anthropic") return { anthropic: { cacheControl: { type: "ephemeral" } } };
  if (!m.reasoningEffort) return undefined;
  if (m.provider === "openai") return { openai: { reasoningEffort: m.reasoningEffort } };
  if (m.provider === "openrouter")
    return { openrouter: { reasoning: { effort: m.reasoningEffort } } };
  return undefined;
}

export function toModelMessages(messages: ChatMessage[]): ModelMessage[] {
  return messages.map((m): ModelMessage => {
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
            output: { type: "text", value: m.content },
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
  });
}

function classify(err: unknown): ModelCallError {
  if (err instanceof ModelCallError) return err;
  if (APICallError.isInstance(err)) {
    const status = err.statusCode;
    const body =
      typeof err.responseBody === "string"
        ? err.responseBody
        : JSON.stringify(err.responseBody ?? "");
    if (status === 403 && body.includes("openrouter_key_limit"))
      return new ModelCallError(
        "Casama's model key hit its daily limit. Try again tomorrow, or add your own key.",
        { retryable: false, status, code: "openrouter_key_limit", cause: err },
      );
    const retryable =
      status === undefined || status === 408 || status === 409 || status === 429 || status >= 500;
    return new ModelCallError(`provider returned ${status ?? "no status"}`, {
      retryable,
      status,
      cause: err,
    });
  }
  const name = (err as Error)?.name ?? "";
  if (name === "AbortError") return new ModelCallError("aborted", { retryable: false, cause: err });
  return new ModelCallError((err as Error)?.message ?? "model call failed", {
    retryable: true,
    cause: err,
  });
}

/** ModelGateway on the Vercel AI SDK. Tools are declared without execute: the agent loop runs them. */
export class AiSdkGateway implements ModelGateway {
  private readonly chatgpt: ChatGptOptions;
  /** `chatgpt` options are for ChatGPT plans (the fetch is overridable for tests). */
  constructor(opts: { chatgpt?: ChatGptOptions } = {}) {
    this.chatgpt = opts.chatgpt ?? {};
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
            track: (cost) => {
              costPromise = cost;
            },
          })
        : undefined;
    let result: ReturnType<typeof streamText>;
    try {
      result = streamText({
        model: languageModel(req.model, fetchImpl),
        system: req.system.join("\n\n"),
        messages: toModelMessages(req.messages),
        tools: req.tools?.length ? tools : undefined,
        maxOutputTokens: req.model.platformKey
          ? Math.min(req.maxOutputTokens ?? CLOUD_MAX_OUTPUT_TOKENS, CLOUD_MAX_OUTPUT_TOKENS)
          : req.maxOutputTokens,
        providerOptions: reasoningOptions(req.model),
        abortSignal: req.abortSignal,
        maxRetries: 0,
      });
    } catch (err) {
      throw classify(err);
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
            },
          };
        }
      }
    } catch (err) {
      throw classify(err);
    }
  }
}
