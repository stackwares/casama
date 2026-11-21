import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { describe, expect, it } from "vitest";
import { CredentialResolver, PLATFORM_OPENROUTER_CREDENTIAL_ID } from "../src/credentials.ts";
import { AiSdkGateway } from "../src/gateway/ai-sdk.ts";
import {
  openRouterCostFromText,
  openRouterProviderPreferences,
  readOpenRouterCost,
  rewriteOpenRouterRequest,
  withOpenRouterRouting,
} from "../src/gateway/openrouter.ts";
import { cloudCallReserveUsd } from "../src/gateway/registry.ts";

describe("OpenRouter request and cost", () => {
  it("gives no cost, not a rejection, when the stream is cut off by a stopped reply", async () => {
    const body = new ReadableStream<Uint8Array>({
      start(c) {
        c.enqueue(new TextEncoder().encode('data: {"choices":[]}\n'));
        c.error(new Error("cancelled"));
      },
    });
    await expect(readOpenRouterCost(body)).resolves.toBeUndefined();
  });

  it("reads the last cost in a streamed response", () => {
    const sse = [
      'data: {"choices":[{"delta":{"content":"hi"}}]}',
      'data: {"usage":{"cost":0.0000091,"prompt_tokens":5}}',
      "data: [DONE]",
    ].join("\n");
    expect(openRouterCostFromText(sse)).toBeCloseTo(0.0000091, 10);
    expect(openRouterCostFromText("no cost here")).toBeUndefined();
  });

  it("tags the workspace and refuses providers that train on prompts", () => {
    const body = rewriteOpenRouterRequest(
      '{"model":"meta/muse-ember","provider":{"sort":"price"}}',
      {
        user: "org-1",
        denyDataCollection: true,
      },
    );
    expect(JSON.parse(body)).toEqual({
      model: "meta/muse-ember",
      user: "org-1",
      provider: { sort: "price", data_collection: "deny" },
    });
  });

  it("sends the shared key's calls to the chosen providers, cheapest first (D-354)", () => {
    const body = rewriteOpenRouterRequest('{"model":"deepseek/deepseek-v4.1-flash-1017"}', {
      user: "org-1",
      denyDataCollection: true,
      routing: { order: [" wafer ", "", "deepinfra/fp8"], sort: "price" },
    });
    expect(JSON.parse(body)).toEqual({
      model: "deepseek/deepseek-v4.1-flash-1017",
      user: "org-1",
      provider: { order: ["wafer", "deepinfra/fp8"], sort: "price", data_collection: "deny" },
    });
    // Routing alone is enough to rewrite the request.
    expect(
      JSON.parse(rewriteOpenRouterRequest('{"model":"m"}', { routing: { sort: "price" } })),
    ).toEqual({ model: "m", provider: { sort: "price" } });
  });

  it("keeps a run's calls in one session, so they stay on the provider that holds their cache", () => {
    const body = rewriteOpenRouterRequest('{"model":"m"}', { sessionId: "run-abc" });
    expect(JSON.parse(body)).toEqual({ model: "m", session_id: "run-abc" });
    expect(
      (
        JSON.parse(rewriteOpenRouterRequest('{"model":"m"}', { sessionId: "x".repeat(400) })) as {
          session_id: string;
        }
      ).session_id,
    ).toHaveLength(256);
  });

  it("keeps a request's own provider choices over the server's routing", () => {
    expect(
      withOpenRouterRouting(
        { model: "m", provider: { sort: "latency", only: ["wafer"] } },
        { order: ["sail-research"], sort: "price" },
      ),
    ).toEqual({
      model: "m",
      provider: { order: ["sail-research"], sort: "latency", only: ["wafer"] },
    });
  });

  it("leaves a request alone when no routing is set", () => {
    expect(openRouterProviderPreferences(undefined)).toBeUndefined();
    expect(openRouterProviderPreferences({ order: [" "] })).toBeUndefined();
    const body = { model: "m" };
    expect(withOpenRouterRouting(body, {})).toBe(body);
    expect(rewriteOpenRouterRequest('{"model":"m"}', { routing: {} })).toBe('{"model":"m"}');
  });

  it("routes only the shared key: a workspace's own OpenRouter key keeps its account's routing", async () => {
    const bodies: Record<string, unknown>[] = [];
    const server = createServer((req, res) => {
      let raw = "";
      req.on("data", (c) => (raw += c));
      req.on("end", () => {
        bodies.push(JSON.parse(raw));
        res.writeHead(200, { "content-type": "text/event-stream" });
        res.end(
          'data: {"id":"x","choices":[{"index":0,"delta":{"content":"ok"}}]}\n\n' +
            'data: {"id":"x","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1,"cost":0.00001}}\n\ndata: [DONE]\n\n',
        );
      });
    });
    await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
    const baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    const gateway = new AiSdkGateway({ platformRouting: { sort: "price" } });
    for (const platformKey of [true, false]) {
      for await (const _ of gateway.stream({
        model: {
          provider: "openrouter",
          model: "deepseek/deepseek-v4.1-flash-1017",
          apiKey: "k",
          baseUrl,
          platformKey,
          openRouterUser: "org-1",
        },
        system: ["s"],
        messages: [{ role: "user", content: "hi" }],
        sessionId: "run-abc",
      })) {
        // drain
      }
    }
    server.close();
    expect(bodies[0]?.session_id).toBe("run-abc");
    expect(bodies[1]?.session_id).toBeUndefined();
    expect(bodies[0]?.provider).toEqual({ sort: "price", data_collection: "deny" });
    expect(bodies[0]?.user).toBe("org-1");
    expect(bodies[1]?.provider).toBeUndefined();
  });

  it("can put chats a person is waiting on on a faster provider, and nothing else", async () => {
    const bodies: Record<string, unknown>[] = [];
    const server = createServer((req, res) => {
      let raw = "";
      req.on("data", (c) => (raw += c));
      req.on("end", () => {
        bodies.push(JSON.parse(raw));
        res.writeHead(200, { "content-type": "text/event-stream" });
        res.end(
          'data: {"id":"x","choices":[{"index":0,"delta":{"content":"ok"}}]}\n\n' +
            'data: {"id":"x","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1}}\n\ndata: [DONE]\n\n',
        );
      });
    });
    await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
    const baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    const gateway = new AiSdkGateway({
      platformRouting: { order: ["wafer"], sort: "price" },
      platformChatRouting: { sort: "throughput" },
    });
    const call = async (platformKey: boolean, interactive: boolean) => {
      for await (const _ of gateway.stream({
        model: { provider: "openrouter", model: "m", apiKey: "k", baseUrl, platformKey },
        system: ["s"],
        messages: [{ role: "user", content: "hi" }],
        interactive,
      })) {
        // drain
      }
    };
    await call(true, true);
    await call(true, false);
    await call(false, true);
    server.close();
    // A chat step: the fast route, without the cheap route's provider order.
    expect(bodies[0]?.provider).toEqual({ sort: "throughput", data_collection: "deny" });
    // A routine or background call on the shared key: the cheapest.
    expect(bodies[1]?.provider).toEqual({
      order: ["wafer"],
      sort: "price",
      data_collection: "deny",
    });
    // A workspace's own key: untouched either way.
    expect(bodies[2]?.provider).toBeUndefined();
  });

  it("reserves enough for a reasoning overrun on the default price", () => {
    expect(cloudCallReserveUsd("meta/muse-ember")).toBeGreaterThan(0);
  });

  it("runs the shared key at the server's thinking level, whatever the bot asked for", async () => {
    const resolver = new CredentialResolver({} as never, {
      platformOpenRouterKey: "sk-test",
      platformReasoningEffort: "low",
    });
    const m = await resolver.resolve("org-1", {
      credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
      model: "meta/muse-ember",
      reasoning_effort: "max",
    });
    expect(m.reasoningEffort).toBe("low");
    expect(m.platformKey).toBe(true);
    expect(m.openRouterUser).toBe("org-1");
  });
});

describe("dictation on OpenRouter", () => {
  it("sends Whisper Large V3 Turbo to OpenRouter and reads its cost", async () => {
    const { transcribe, OPENROUTER_STT_MODEL } = await import("../src/voice.ts");
    let url = "";
    let model: unknown;
    const fakeFetch = (async (u: string, init: RequestInit) => {
      url = u;
      model = (init.body as FormData).get("model");
      return new Response(
        JSON.stringify({ text: "hello", usage: { seconds: 2.5, cost: 0.0000083 } }),
        {
          status: 200,
          headers: { "content-type": "application/json" },
        },
      );
    }) as unknown as typeof fetch;
    const r = await transcribe("openrouter", "sk-test", new Uint8Array([1, 2]), "audio/wav", {
      fetch: fakeFetch,
    });
    expect(url).toBe("https://openrouter.ai/api/v1/audio/transcriptions");
    expect(model).toBe(OPENROUTER_STT_MODEL);
    expect(r).toEqual({ text: "hello", seconds: 2.5, costUsd: 0.0000083 });
  });
});
