import { describe, expect, it } from "vitest";
import { openRouterCostFromText, rewriteOpenRouterRequest } from "../src/gateway/openrouter.ts";
import { cloudCallReserveUsd } from "../src/gateway/registry.ts";
import { CredentialResolver, PLATFORM_OPENROUTER_CREDENTIAL_ID } from "../src/credentials.ts";

describe("OpenRouter request and cost", () => {
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
      return new Response(JSON.stringify({ text: "hello", usage: { seconds: 2.5, cost: 0.0000083 } }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    }) as unknown as typeof fetch;
    const r = await transcribe("openrouter", "sk-test", new Uint8Array([1, 2]), "audio/wav", {
      fetch: fakeFetch,
    });
    expect(url).toBe("https://openrouter.ai/api/v1/audio/transcriptions");
    expect(model).toBe(OPENROUTER_STT_MODEL);
    expect(r).toEqual({ text: "hello", seconds: 2.5, costUsd: 0.0000083 });
  });
});
