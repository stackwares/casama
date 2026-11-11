import { describe, expect, it } from "vitest";
import { openRouterCostFromText, rewriteOpenRouterRequest } from "../src/gateway/openrouter.ts";
import { cloudCallReserveUsd } from "../src/gateway/registry.ts";

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
});
