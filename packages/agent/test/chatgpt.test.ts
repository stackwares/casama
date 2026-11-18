import { describe, expect, it } from "vitest";
import {
  type ChatMessage,
  collect,
  type GatewayEvent,
  ModelCallError,
  type ModelGateway,
  type ModelRequest,
  type ResolvedModel,
  responsesBody,
  streamChatGpt,
  withFallback,
} from "../src/index.ts";

const plan = (over: Partial<ResolvedModel> = {}): ResolvedModel => ({
  provider: "chatgpt",
  model: "gpt-6.1-sol",
  apiKey: "at_test",
  baseUrl: "https://chatgpt.test/v1",
  credentialId: "11111111-1111-1111-1111-111111111111",
  ...over,
});

const req = (over: Partial<ModelRequest> = {}): ModelRequest => ({
  model: plan(),
  system: ["You are helpful.", "Be brief."],
  messages: [{ role: "user", content: "hi" }],
  ...over,
});

function sseResponse(events: Array<Record<string, unknown>>) {
  const text = events.map((e) => `event: ${e.type}\ndata: ${JSON.stringify(e)}\n\n`).join("");
  return new Response(text, { status: 200, headers: { "content-type": "text/event-stream" } });
}

const jsonResponse = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

describe("ChatGPT plan request shape", () => {
  it("maps the conversation to Responses input with only accepted fields", () => {
    const messages: ChatMessage[] = [
      {
        role: "user",
        content: "look",
        images: [{ data: new Uint8Array([1, 2, 3]), mediaType: "image/png" }],
      },
      {
        role: "assistant",
        content: "checking",
        toolCalls: [{ callId: "c1", name: "web_search", args: { q: "x" } }],
      },
      { role: "tool", callId: "c1", name: "web_search", content: "result" },
    ];
    const body = responsesBody(
      req({
        messages,
        maxOutputTokens: 100,
        model: plan({ reasoningEffort: "medium" }),
        tools: [{ name: "web_search", description: "Search", inputSchema: { type: "object" } }],
      }),
    );
    expect(body).toMatchObject({
      model: "gpt-6.1-sol",
      instructions: "You are helpful.\n\nBe brief.",
      stream: true,
      store: false,
      reasoning: { effort: "medium" },
      tool_choice: "auto",
    });
    for (const k of ["temperature", "top_p", "max_output_tokens", "previous_response_id", "user"])
      expect(body).not.toHaveProperty(k);
    expect(body.tools).toEqual([
      {
        type: "function",
        name: "web_search",
        description: "Search",
        parameters: { type: "object" },
        strict: false,
      },
    ]);
    const input = body.input as Array<Record<string, unknown>>;
    expect(input[0]).toEqual({
      type: "message",
      role: "user",
      content: [
        { type: "input_text", text: "look" },
        { type: "input_image", image_url: "data:image/png;base64,AQID" },
      ],
    });
    expect(input[1]).toMatchObject({ type: "message", role: "assistant" });
    expect(input[2]).toEqual({
      type: "function_call",
      call_id: "c1",
      name: "web_search",
      arguments: '{"q":"x"}',
    });
    expect(input[3]).toEqual({ type: "function_call_output", call_id: "c1", output: "result" });
    // No system role items: system text goes in `instructions`.
    expect(input.some((i) => i.role === "system")).toBe(false);
  });
});

describe("ChatGPT plan stream", () => {
  it("streams text and tool calls and reports plan usage", async () => {
    let seen: { url: string; auth: string | null } | undefined;
    const f = (async (url: string, init: RequestInit) => {
      seen = { url, auth: new Headers(init.headers).get("authorization") };
      return sseResponse([
        { type: "response.created", response: { id: "r1" } },
        { type: "response.output_text.delta", delta: "Hel" },
        { type: "response.output_text.delta", delta: "lo" },
        {
          type: "response.output_item.done",
          item: { type: "function_call", call_id: "c9", name: "notify_user", arguments: '{"a":1}' },
        },
        {
          type: "response.completed",
          response: { model: "gpt-6.1-sol", usage: { input_tokens: 10, output_tokens: 3 } },
        },
      ]);
    }) as unknown as typeof fetch;
    const r = await collect(streamChatGpt(req(), { fetch: f }));
    expect(seen).toEqual({ url: "https://chatgpt.test/v1/responses", auth: "Bearer at_test" });
    expect(r.text).toBe("Hello");
    expect(r.toolCalls).toEqual([{ callId: "c9", name: "notify_user", args: { a: 1 } }]);
    expect(r.usage).toEqual({ inputTokens: 10, outputTokens: 3 });
    expect(r.provider).toBe("chatgpt");
    expect(r.finishReason).toBe("tool-calls");
  });

  it("maps a plan limit to a non-retryable error unless the owner allowed fallback", async () => {
    const limit = (async () =>
      jsonResponse(429, {
        error: { code: "subscription_sharing_usage_limit_exceeded", message: "limit" },
      })) as unknown as typeof fetch;
    await expect(collect(streamChatGpt(req(), { fetch: limit }))).rejects.toMatchObject({
      code: "chatgpt_plan_limit",
      retryable: false,
      status: 429,
    });
    await expect(
      collect(streamChatGpt(req({ model: plan({ fallbackOnLimit: true }) }), { fetch: limit })),
    ).rejects.toMatchObject({ code: "chatgpt_plan_limit", retryable: true });
  });

  it("maps the other documented errors", async () => {
    const cases: Array<[number, unknown, string, boolean]> = [
      [
        403,
        { error: { code: "subscription_sharing_user_not_eligible" } },
        "chatgpt_not_eligible",
        false,
      ],
      [
        401,
        { error: { code: "subscription_sharing_invalid_user" } },
        "chatgpt_needs_reconnect",
        false,
      ],
      [401, { detail: "not accepted" }, "chatgpt_needs_reconnect", false],
      [
        400,
        { error: { code: "subscription_sharing_unsupported_capability", param: "temperature" } },
        "chatgpt_unsupported_request",
        false,
      ],
      [403, { detail: "region" }, "chatgpt_forbidden", false],
    ];
    for (const [status, body, code, retryable] of cases) {
      const f = (async () => jsonResponse(status, body)) as unknown as typeof fetch;
      await expect(collect(streamChatGpt(req(), { fetch: f }))).rejects.toMatchObject({
        code,
        retryable,
      });
    }
  });

  it("fails on a limit that arrives mid-stream", async () => {
    const f = (async () =>
      sseResponse([
        { type: "response.output_text.delta", delta: "Part" },
        {
          type: "response.failed",
          response: { error: { code: "subscription_sharing_usage_limit_exceeded" } },
        },
      ])) as unknown as typeof fetch;
    const events: GatewayEvent[] = [];
    await expect(
      (async () => {
        for await (const e of streamChatGpt(req(), { fetch: f })) events.push(e);
      })(),
    ).rejects.toMatchObject({ code: "chatgpt_plan_limit" });
    expect(events).toEqual([{ type: "text", text: "Part" }]);
  });

  it("retries 503 with bounded backoff before giving up", async () => {
    let calls = 0;
    const sleeps: number[] = [];
    const f = (async () => {
      calls++;
      if (calls < 3)
        return jsonResponse(503, { error: { code: "subscription_sharing_usage_unavailable" } });
      return sseResponse([
        { type: "response.output_text.delta", delta: "ok" },
        { type: "response.completed", response: { usage: {} } },
      ]);
    }) as unknown as typeof fetch;
    const r = await collect(
      streamChatGpt(req(), { fetch: f, sleep: async (ms) => void sleeps.push(ms) }),
    );
    expect(r.text).toBe("ok");
    expect(sleeps).toEqual([1000, 2000]);
    calls = -10;
    await expect(
      collect(streamChatGpt(req(), { fetch: f, sleep: async () => {} })),
    ).rejects.toMatchObject({ code: "chatgpt_unavailable", retryable: true });
  });

  it("moves to the next model at the plan limit only when allowed", async () => {
    const inner: ModelGateway = {
      async *stream(r) {
        if (r.model.provider === "chatgpt")
          throw new ModelCallError("limit", {
            code: "chatgpt_plan_limit",
            retryable: r.model.fallbackOnLimit === true,
          });
        yield { type: "text", text: "from key" };
        yield {
          type: "finish",
          usage: { inputTokens: 1, outputTokens: 1 },
          finishReason: "stop",
          model: r.model.model,
        };
      },
    };
    const key: ResolvedModel = { provider: "openai", model: "gpt-6.1-sol", apiKey: "sk" };
    const opts = { sleep: async () => {} };
    const allowed = await collect(
      withFallback(
        inner,
        [plan({ fallbackOnLimit: true }), key],
        opts,
      )({
        system: [],
        messages: [],
      }),
    );
    expect(allowed.text).toBe("from key");
    await expect(
      collect(withFallback(inner, [plan(), key], opts)({ system: [], messages: [] })),
    ).rejects.toMatchObject({ code: "chatgpt_plan_limit" });
  });
});
