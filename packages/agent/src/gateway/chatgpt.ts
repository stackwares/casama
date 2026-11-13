/**
 * ChatGPT plan adapter (SPEC: ChatGPT plan sign-in). Calls the Responses API with the person's
 * OAuth access token, under the constraints OpenAI sets for plan usage: `store: false`,
 * `stream: true`, history in `input`, system text in `instructions`, and none of the request fields
 * that route rejects (temperature, top_p, max_output_tokens, metadata, user, truncation, ...).
 */
import { ToolRegistry } from "../tools/registry.ts";
import {
  type ChatMessage,
  type GatewayEvent,
  ModelCallError,
  type ModelRequest,
  type ResolvedModel,
  type ToolCall,
} from "./types.ts";

export const CHATGPT_API_URL = "https://api.openai.com/v1";

type Json = Record<string, unknown>;

/** The Responses API `input` for a conversation. */
export function toResponsesInput(messages: ChatMessage[]): Json[] {
  const out: Json[] = [];
  for (const m of messages) {
    if (m.role === "user") {
      const content: Json[] = [{ type: "input_text", text: m.content }];
      for (const img of m.images ?? []) {
        content.push({
          type: "input_image",
          image_url: `data:${img.mediaType};base64,${Buffer.from(img.data).toString("base64")}`,
        });
      }
      out.push({ type: "message", role: "user", content });
    } else if (m.role === "assistant") {
      if (m.content)
        out.push({
          type: "message",
          role: "assistant",
          content: [{ type: "output_text", text: m.content }],
        });
      for (const c of m.toolCalls ?? []) {
        out.push({
          type: "function_call",
          call_id: c.callId,
          name: ToolRegistry.wireName(c.name),
          arguments: JSON.stringify(c.args ?? {}),
        });
      }
    } else {
      out.push({ type: "function_call_output", call_id: m.callId, output: m.content });
    }
  }
  return out;
}

/** The request body. Only fields the plan-usage route accepts. */
export function responsesBody(req: ModelRequest): Json {
  const body: Json = {
    model: req.model.model,
    instructions: req.system.join("\n\n"),
    input: toResponsesInput(req.messages),
    stream: true,
    store: false,
  };
  if (req.tools?.length) {
    body.tools = req.tools.map((t) => ({
      type: "function",
      name: t.name,
      description: t.description,
      parameters: t.inputSchema,
      strict: false,
    }));
    body.tool_choice = "auto";
  }
  if (req.model.reasoningEffort) body.reasoning = { effort: req.model.reasoningEffort };
  return body;
}

interface PlanError {
  code?: string;
  message?: string;
  param?: string;
}

/** Maps OpenAI's plan-usage errors to Casama's (SPEC: Limits and errors). */
export function planError(
  status: number | undefined,
  err: PlanError,
  model: ResolvedModel,
  requestId?: string,
): ModelCallError {
  const code = err.code ?? "";
  const base = { status, credentialId: model.credentialId };
  const detail = [err.message, requestId ? `request ${requestId}` : ""].filter(Boolean).join("; ");
  if (code === "subscription_sharing_usage_limit_exceeded")
    return new ModelCallError(`ChatGPT plan limit reached${detail ? ` (${detail})` : ""}`, {
      ...base,
      code: "chatgpt_plan_limit",
      // Moving to the next model may cost money, so it happens only when the owner allowed it.
      retryable: model.fallbackOnLimit === true,
    });
  if (code === "subscription_sharing_user_not_eligible")
    return new ModelCallError("This ChatGPT plan is not eligible for use in other apps", {
      ...base,
      code: "chatgpt_not_eligible",
      retryable: false,
    });
  if (code === "subscription_sharing_invalid_user" || (status === 401 && !code))
    return new ModelCallError("The ChatGPT sign-in is no longer valid; sign in again", {
      ...base,
      code: "chatgpt_needs_reconnect",
      retryable: model.fallbackOnLimit === true,
    });
  if (code === "subscription_sharing_unsupported_capability")
    return new ModelCallError(
      `ChatGPT plan request rejected: unsupported ${err.param ?? "capability"}${detail ? ` (${detail})` : ""}`,
      { ...base, code: "chatgpt_unsupported_request", retryable: false },
    );
  if (
    code === "subscription_sharing_usage_unavailable" ||
    code === "subscription_sharing_user_unavailable" ||
    status === 503
  )
    return new ModelCallError("ChatGPT plan usage is unavailable right now", {
      ...base,
      code: "chatgpt_unavailable",
      retryable: true,
    });
  if (status === 403)
    return new ModelCallError(`ChatGPT plan request not allowed${detail ? ` (${detail})` : ""}`, {
      ...base,
      code: "chatgpt_forbidden",
      retryable: false,
    });
  const retryable =
    status === undefined || status === 408 || status === 409 || status === 429 || status >= 500;
  return new ModelCallError(
    `ChatGPT returned ${status ?? "an error"}${detail ? `: ${detail}` : ""}`,
    {
      ...base,
      retryable,
    },
  );
}

async function readError(res: Response): Promise<PlanError> {
  const text = await res.text().catch(() => "");
  try {
    const body = JSON.parse(text) as { error?: PlanError; detail?: unknown };
    if (body.error && typeof body.error === "object") return body.error;
    if (typeof body.detail === "string") return { message: body.detail };
  } catch {
    // not JSON
  }
  return { message: text.slice(0, 300) || undefined };
}

/** Server-sent events: yields each event's parsed JSON data. */
async function* sse(body: ReadableStream<Uint8Array>): AsyncIterable<Json> {
  const decoder = new TextDecoder();
  let buf = "";
  const reader = body.getReader();
  try {
    for (;;) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += decoder.decode(value, { stream: true });
      let idx = buf.indexOf("\n\n");
      while (idx >= 0) {
        const chunk = buf.slice(0, idx);
        buf = buf.slice(idx + 2);
        const data = chunk
          .split("\n")
          .filter((l) => l.startsWith("data:"))
          .map((l) => l.slice(5).trimStart())
          .join("\n");
        if (data && data !== "[DONE]") {
          try {
            yield JSON.parse(data) as Json;
          } catch {
            // ignore keep-alives and partial garbage
          }
        }
        idx = buf.indexOf("\n\n");
      }
    }
  } finally {
    reader.releaseLock();
  }
}

export interface ChatGptOptions {
  fetch?: typeof fetch;
  /** Bounded retries for 503 before any output (default 2, backoff 1 s then 2 s). */
  retries?: number;
  sleep?: (ms: number) => Promise<void>;
}

/** Streams one model call on a ChatGPT plan. */
export async function* streamChatGpt(
  req: ModelRequest,
  opts: ChatGptOptions = {},
): AsyncIterable<GatewayEvent> {
  const f = opts.fetch ?? fetch;
  const sleep = opts.sleep ?? ((ms) => new Promise((r) => setTimeout(r, ms)));
  const base = (req.model.baseUrl ?? CHATGPT_API_URL).replace(/\/$/, "");
  const body = JSON.stringify(responsesBody(req));
  const maxRetries = opts.retries ?? 2;

  let res: Response | undefined;
  for (let attempt = 0; ; attempt++) {
    try {
      res = await f(`${base}/responses`, {
        method: "POST",
        headers: {
          authorization: `Bearer ${req.model.apiKey ?? ""}`,
          "content-type": "application/json",
          accept: "text/event-stream",
        },
        body,
        signal: req.abortSignal,
      });
    } catch (err) {
      if ((err as Error)?.name === "AbortError" || req.abortSignal?.aborted)
        throw new ModelCallError("aborted", { retryable: false, cause: err });
      throw new ModelCallError("Could not reach ChatGPT", { retryable: true, cause: err });
    }
    if (res.ok) break;
    const err = planError(
      res.status,
      await readError(res),
      req.model,
      res.headers.get("x-request-id") ?? undefined,
    );
    if (err.code === "chatgpt_unavailable" && attempt < maxRetries) {
      await sleep(1000 * 2 ** attempt);
      continue;
    }
    throw err;
  }
  if (!res.body) throw new ModelCallError("ChatGPT sent no stream", { retryable: true });

  const calls: ToolCall[] = [];
  const requestId = res.headers.get("x-request-id") ?? undefined;
  for await (const ev of sse(res.body)) {
    const type = ev.type as string | undefined;
    if (type === "response.output_text.delta") {
      const delta = ev.delta;
      if (typeof delta === "string" && delta) yield { type: "text", text: delta };
    } else if (type === "response.output_item.done") {
      const item = ev.item as Json | undefined;
      if (item?.type === "function_call") {
        let args: Record<string, unknown> = {};
        try {
          args = JSON.parse((item.arguments as string) || "{}") as Record<string, unknown>;
        } catch {
          args = {};
        }
        const call = {
          callId: String(item.call_id ?? item.id ?? ""),
          name: String(item.name ?? ""),
          args,
        };
        calls.push(call);
        yield { type: "tool_call", call };
      }
    } else if (type === "response.completed" || type === "response.incomplete") {
      const response = (ev.response ?? {}) as Json;
      const usage = (response.usage ?? {}) as Json;
      yield {
        type: "finish",
        provider: "chatgpt",
        model: String(response.model ?? req.model.model),
        finishReason:
          type === "response.incomplete" ? "length" : calls.length ? "tool-calls" : "stop",
        usage: {
          inputTokens: Number(usage.input_tokens ?? 0),
          outputTokens: Number(usage.output_tokens ?? 0),
        },
      };
      return;
    } else if (type === "response.failed") {
      const response = (ev.response ?? {}) as Json;
      throw planError(undefined, (response.error ?? {}) as PlanError, req.model, requestId);
    } else if (type === "error") {
      const err = ((ev.error as PlanError | undefined) ?? (ev as PlanError)) as PlanError;
      throw planError(undefined, err, req.model, requestId);
    } else {
      // Reasoning and tool-argument events: nothing to show, but the model isn't silent.
      yield { type: "progress" };
    }
  }
  if (req.abortSignal?.aborted) throw new ModelCallError("aborted", { retryable: false });
  throw new ModelCallError("ChatGPT stream ended early", { retryable: !calls.length });
}
