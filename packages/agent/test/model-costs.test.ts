import { describe, expect, it } from "vitest";
import { reasoningOptions } from "../src/gateway/ai-sdk.ts";
import { costOf } from "../src/gateway/registry.ts";
import type { ResolvedModel } from "../src/gateway/types.ts";
import { backgroundChain } from "../src/run.ts";

const model = (provider: ResolvedModel["provider"], name: string): ResolvedModel =>
  ({ provider, model: name, apiKey: "k" }) as ResolvedModel;

describe("model costs (docs/COSTS.md)", () => {
  it("prices cached input at a tenth and Anthropic cache writes at 1.25x", () => {
    // claude-haiku: $1 in / $5 out per 1M in the price table.
    const plain = costOf("claude-haiku-5-5", { inputTokens: 1_000_000, outputTokens: 0 });
    const cached = costOf("claude-haiku-5-5", {
      inputTokens: 1_000_000,
      outputTokens: 0,
      cachedInputTokens: 900_000,
    });
    const written = costOf("claude-haiku-5-5", {
      inputTokens: 1_000_000,
      outputTokens: 0,
      cacheWriteTokens: 1_000_000,
    });
    expect(plain).toBeCloseTo(1, 6);
    expect(cached).toBeCloseTo(0.1 + 0.9 * 0.1, 6);
    expect(written).toBeCloseTo(1.25, 6);
    // Never more cached tokens than input tokens.
    expect(
      costOf("claude-haiku-5-5", { inputTokens: 10, outputTokens: 0, cachedInputTokens: 99 }),
    ).toBeGreaterThan(0);
  });

  it("asks Anthropic to cache the prompt; other providers cache on their own", () => {
    expect(reasoningOptions(model("anthropic", "claude-opus-5-5"))).toEqual({
      anthropic: { cacheControl: { type: "ephemeral" } },
    });
    expect(reasoningOptions(model("google", "gemini-3.8-flash"))).toBeUndefined();
  });

  it("runs background work on the provider's small model, falling back to the main one", async () => {
    const resolve = async (c: Array<{ credential_id: string; model: string } | undefined>) =>
      c.filter((x) => !!x).map((x) => model("anthropic", x.model));
    const chain = await backgroundChain(
      { primary: { credential_id: "c1", model: "claude-opus-5-5" } },
      resolve,
    );
    expect(chain.map((m) => m.model)).toEqual(["claude-haiku-5-5", "claude-opus-5-5"]);
    // The bot's own cheap model wins.
    const own = await backgroundChain(
      {
        primary: { credential_id: "c1", model: "claude-opus-5-5" },
        cheap: { credential_id: "c1", model: "claude-sonnet-5-5" },
      },
      resolve,
    );
    expect(own.map((m) => m.model)).toEqual(["claude-sonnet-5-5"]);
    // Already on the small model: no duplicate.
    const small = await backgroundChain(
      { primary: { credential_id: "c1", model: "claude-haiku-5-5" } },
      resolve,
    );
    expect(small.map((m) => m.model)).toEqual(["claude-haiku-5-5"]);
  });
});
