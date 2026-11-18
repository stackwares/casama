/** Live model prices (D-181): OpenRouter's list wins, and nothing on OpenRouter is free by accident. */
import { afterEach, describe, expect, it } from "vitest";
import { fetchOpenRouterPrices, startLivePrices } from "../src/gateway/live-prices.ts";
import { capabilitiesOf, costOf, setLivePrices } from "../src/gateway/registry.ts";

const LIST = {
  data: [
    {
      id: "qwen/qwen3-235b",
      context_length: 262_144,
      pricing: { prompt: "0.00000022", completion: "0.00000088" },
    },
    {
      id: "anthropic/claude-sonnet-5.5",
      context_length: 1_000_000,
      pricing: {
        prompt: "0.000003",
        completion: "0.000015",
        input_cache_read: "0.0000003",
        input_cache_write: "0.00000375",
      },
    },
    { id: "openrouter/auto", pricing: { prompt: "-1", completion: "-1" } },
    { id: "meta-llama/llama-4:free", pricing: { prompt: "0", completion: "0" } },
  ],
};
const fake = (async () => Response.json(LIST)) as unknown as typeof fetch;

afterEach(() => setLivePrices(new Map()));

describe("live model prices", () => {
  it("reads OpenRouter's per-token prices as per-million prices and skips variable ones", async () => {
    const prices = await fetchOpenRouterPrices({ fetch: fake });
    expect(prices.get("qwen/qwen3-235b")?.inputPrice).toBeCloseTo(0.22, 6);
    expect(prices.get("qwen/qwen3-235b")?.outputPrice).toBeCloseTo(0.88, 6);
    expect(prices.get("anthropic/claude-sonnet-5.5")).toMatchObject({ contextWindow: 1_000_000 });
    expect(prices.get("anthropic/claude-sonnet-5.5")?.cacheReadPrice).toBeCloseTo(0.3, 6);
    expect(prices.has("openrouter/auto")).toBe(false);
  });

  it("a live price wins over the table, including its cache prices", async () => {
    // Without live prices an open-weight model on OpenRouter is never free; locally it is.
    expect(capabilitiesOf("qwen/qwen3-235b", "openrouter").inputPrice).toBe(1);
    expect(capabilitiesOf("qwen/qwen3-235b", "openai_compatible").inputPrice).toBe(0);
    expect(capabilitiesOf("meta-llama/llama-4:free", "openrouter").inputPrice).toBe(0);

    setLivePrices(await fetchOpenRouterPrices({ fetch: fake }));
    expect(capabilitiesOf("qwen/qwen3-235b", "openrouter")).toMatchObject({
      contextWindow: 262_144,
    });
    expect(
      costOf("qwen/qwen3-235b", { inputTokens: 1_000_000, outputTokens: 1_000_000 }, "openrouter"),
    ).toBeCloseTo(1.1, 6);
    // 1M input of which 800k cached reads and 100k cache writes, at the list's own cache prices.
    expect(
      costOf("anthropic/claude-sonnet-5.5", {
        inputTokens: 1_000_000,
        outputTokens: 0,
        cachedInputTokens: 800_000,
        cacheWriteTokens: 100_000,
      }),
    ).toBeCloseTo(0.1 * 3 + 0.8 * 0.3 + 0.1 * 3.75, 6);
  });

  it("models called on the provider's own API use their OpenRouter price", async () => {
    setLivePrices(await fetchOpenRouterPrices({ fetch: fake }));
    expect(capabilitiesOf("claude-sonnet-5-5", "anthropic").outputPrice).toBeCloseTo(15, 6);
    expect(capabilitiesOf("claude-sonnet-5.5", "anthropic").outputPrice).toBeCloseTo(15, 6);
    // Unlisted: the table.
    expect(capabilitiesOf("claude-haiku-5-5", "anthropic").inputPrice).toBe(1);
  });

  it("keeps the last good list when a refresh fails", async () => {
    setLivePrices(await fetchOpenRouterPrices({ fetch: fake }));
    const errors: string[] = [];
    const stop = startLivePrices({
      fetch: (async () => new Response("down", { status: 503 })) as unknown as typeof fetch,
      onError: (e) => errors.push(e.message),
    });
    await new Promise((r) => setTimeout(r, 20));
    stop();
    expect(errors).toEqual(["OpenRouter models returned 503"]);
    expect(capabilitiesOf("qwen/qwen3-235b").inputPrice).toBeCloseTo(0.22, 6);
  });
});
