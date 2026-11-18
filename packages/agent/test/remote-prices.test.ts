/**
 * Models and prices from Admin (D-373). The first block pins today's prices as literal numbers: an
 * empty setting (or none) must bill exactly as the code did before the setting existed. The rest
 * checks that saved values apply and that bad ones fall back to the code.
 */
import {
  defaultModelFor,
  defaultModels,
  featuredModelsFor,
  setCostTables,
  setModelCatalog,
  smallModelFor,
  testModelFor,
} from "@casama/domain";
import { afterEach, describe, expect, it } from "vitest";
import { computerCostUsd, computerRates } from "../src/computers.ts";
import { capabilitiesOf, cloudCallReserveUsd, costOf } from "../src/gateway/registry.ts";
import {
  MEDIA_PRICES,
  mediaPrices,
  OPENROUTER_VIDEO_PER_SECOND,
  openRouterImagePrice,
  openRouterVideoPerSecond,
} from "../src/media.ts";
import {
  GEMINI_LIVE_PRICES,
  geminiLiveCost,
  geminiLivePrices,
  ttsCostUsd,
  VOICE_PRICES,
  voicePrices,
} from "../src/voice.ts";

afterEach(() => {
  setModelCatalog(undefined);
  setCostTables(undefined);
});

const usage = (inputTokens: number, outputTokens: number, cached = 0, written = 0) => ({
  inputTokens,
  outputTokens,
  cachedInputTokens: cached,
  cacheWriteTokens: written,
});

/** Every price the setting can change, as the code billed before D-373. */
function billsAsBefore() {
  // Tokens: DeepSeek V4.1 Flash 1017 with its own cache price.
  expect(
    costOf("deepseek/deepseek-v4.1-flash-1017", usage(1e6, 1e6, 2e5), "openrouter"),
  ).toBeCloseTo(0.5324, 10);
  // Claude Sonnet on Anthropic's API: a tenth for cache reads, 1.25× for writes.
  expect(costOf("claude-sonnet-5-5", usage(1e6, 1e5, 1e5, 2e5), "anthropic")).toBeCloseTo(4.38, 10);
  expect(costOf("gpt-6-luna", usage(1e6, 1e6), "openai")).toBeCloseTo(0.6, 10);
  // Unknown and open models on OpenRouter are never free; on a local server they are.
  expect(costOf("someone/new-model", usage(1e6, 1e6), "openrouter")).toBeCloseTo(4, 10);
  expect(costOf("meta-llama/llama-3.3-70b", usage(1e6, 1e6), "openrouter")).toBeCloseTo(4, 10);
  expect(costOf("llama3.3", usage(1e6, 1e6), "openai_compatible")).toBe(0);
  expect(capabilitiesOf("deepseek/deepseek-v4.1-flash-1017").contextWindow).toBe(1_048_576);
  expect(cloudCallReserveUsd("deepseek/deepseek-v4.1-flash-1017")).toBeCloseTo(
    0.003304 * 1.055 * 1.3,
    12,
  );
  // Voice and calls.
  expect(voicePrices()).toEqual({
    sttPerMinute: 0.0002,
    geminiTtsPerThousandChars: 0.011,
    geminiLivePerMinute: 0.02,
  });
  expect(ttsCostUsd("openrouter", 1000, undefined, new Date("2026-11-18T00:00:00Z"))).toBeCloseTo(
    0.011,
    12,
  );
  expect(
    geminiLiveCost({
      input_audio_tokens: 1e6,
      input_text_tokens: 1e6,
      output_audio_tokens: 1e6,
      output_text_tokens: 1e6,
    }),
  ).toBeCloseTo(20.25, 10);
  // Computers: Docker 2 vCPU / 4 GiB, E2B 2 vCPU / 4 GiB, an hour each.
  expect(computerCostUsd("docker", { cpus: 2, memory_mb: 4096 }, 3600)).toBeCloseTo(0.026, 12);
  expect(computerCostUsd("e2b", { cpus: 2, memory_mb: 4096 }, 3600)).toBeCloseTo(0.1656, 12);
  expect(computerCostUsd("local", { cpus: 4, memory_mb: 8192 }, 3600)).toBe(0);
  expect(computerCostUsd("casama-cloud", { cpus: 2, memory_mb: 4096 }, 3600)).toBeCloseTo(0.1, 12);
  // Media.
  expect(openRouterImagePrice("google/gemini-nano-banana-2.1")).toBe(0.0336);
  expect(openRouterImagePrice("someone/new-image-model")).toBe(0.04);
  expect(mediaPrices()).toEqual({ image: 0.04, videoPerSecond: 0.1 });
  expect(openRouterVideoPerSecond()).toBe(0.069504);
}

describe("models and prices with no setting (D-373)", () => {
  it("bill exactly as before", () => {
    billsAsBefore();
    expect(voicePrices()).toBe(VOICE_PRICES);
    expect(geminiLivePrices()).toBe(GEMINI_LIVE_PRICES);
    expect(mediaPrices()).toBe(MEDIA_PRICES);
    expect(openRouterVideoPerSecond()).toBe(OPENROUTER_VIDEO_PER_SECOND);
  });

  it("bill exactly as before with an empty setting saved", () => {
    setModelCatalog({});
    setCostTables({});
    billsAsBefore();
  });

  it("bill exactly as before when the stored setting is broken", () => {
    setModelCatalog("not an object");
    setCostTables({
      voice: "cheap",
      media: { image: -1 },
      computers: { docker: { cpu_hour: "x" } },
    });
    billsAsBefore();
  });

  it("keep the default, small and test models", () => {
    expect(defaultModels()).toEqual({
      openrouter: "deepseek/deepseek-v4.1-flash-1017",
      openai: "gpt-6-luna",
    });
    expect(defaultModelFor("openrouter")).toBe("deepseek/deepseek-v4.1-flash-1017");
    expect(defaultModelFor("openrouter", { openrouter: "env/override" })).toBe("env/override");
    expect(smallModelFor("anthropic")).toBe("claude-haiku-5-5");
    expect(featuredModelsFor("openrouter")[0]?.id).toBe("deepseek/deepseek-v4.1-flash-1017");
    // The key check's models: no more gemini-2.5-flash or grok-3-mini.
    expect(testModelFor("openrouter")).toBe("deepseek/deepseek-v4.1-flash-1017");
    expect(testModelFor("openai")).toBe("gpt-6-luna");
    expect(testModelFor("anthropic")).toBe("claude-haiku-5-5");
    expect(testModelFor("google")).toBe("gemini-3.5-flash-lite");
    expect(testModelFor("xai")).toBe("grok-4.7");
    expect(testModelFor("openai_compatible")).toBeUndefined();
    expect(testModelFor("chatgpt")).toBeUndefined();
  });
});

describe("a saved setting (D-373)", () => {
  it("changes token prices: exact ids first, then patterns, then the code's table", () => {
    setModelCatalog({
      models: [
        { pattern: "claude-sonnet", input_price: 2, output_price: 10, caching: true },
        { id: "Someone/New-Model", input_price: 0.5, output_price: 1, context_window: 400_000 },
      ],
    });
    expect(costOf("someone/new-model", usage(1e6, 1e6), "openrouter")).toBeCloseTo(1.5, 10);
    expect(capabilitiesOf("someone/new-model").contextWindow).toBe(400_000);
    expect(costOf("claude-sonnet-5-5", usage(1e6, 0), "anthropic")).toBeCloseTo(2, 10);
    // Not in the setting: the table still prices it.
    expect(costOf("gpt-6-luna", usage(1e6, 1e6), "openai")).toBeCloseTo(0.6, 10);
  });

  it("changes default, small, featured and test models, and an env override still wins", () => {
    setModelCatalog({
      default_models: { openrouter: "z-ai/glm-5.3" },
      small_models: { google: "gemini-3.8-flash" },
      featured_models: { xai: [{ id: "grok-5", name: "Grok 5" }] },
      test_models: { xai: "grok-5-mini" },
    });
    expect(defaultModelFor("openrouter")).toBe("z-ai/glm-5.3");
    expect(defaultModelFor("openrouter", { openrouter: "env/override" })).toBe("env/override");
    expect(defaultModels().openai).toBe("gpt-6-luna");
    expect(smallModelFor("google")).toBe("gemini-3.8-flash");
    expect(smallModelFor("anthropic")).toBe("claude-haiku-5-5");
    expect(featuredModelsFor("xai")).toEqual([{ id: "grok-5", name: "Grok 5" }]);
    expect(featuredModelsFor("openai")[0]?.id).toBe("gpt-6-luna");
    expect(testModelFor("xai")).toBe("grok-5-mini");
    expect(testModelFor("google")).toBe("gemini-3.8-flash");
  });

  it("changes image, video, voice, call and computer prices", () => {
    setModelCatalog({ image_prices: { "google/gemini-nano-banana-2.1": 0.05 } });
    setCostTables({
      voice: { stt_per_minute: 0.001 },
      gemini_live: { output_audio: 20 },
      media: { image: 0.06, openrouter_video_per_second: 0.08 },
      computers: { docker: { cpu_hour: 0.01, gb_hour: 0.01 } },
    });
    expect(openRouterImagePrice("google/gemini-nano-banana-2.1")).toBe(0.05);
    expect(openRouterImagePrice("someone/new-image-model")).toBe(0.06);
    expect(openRouterVideoPerSecond()).toBe(0.08);
    expect(voicePrices().sttPerMinute).toBe(0.001);
    expect(voicePrices().geminiLivePerMinute).toBe(0.02);
    expect(
      geminiLiveCost({
        input_audio_tokens: 0,
        input_text_tokens: 0,
        output_audio_tokens: 1e6,
        output_text_tokens: 0,
      }),
    ).toBeCloseTo(20, 10);
    expect(computerCostUsd("docker", { cpus: 1, memory_mb: 1024 }, 3600)).toBeCloseTo(0.02, 12);
    // A provider the setting doesn't name keeps its code price.
    expect(computerCostUsd("e2b", { cpus: 2, memory_mb: 4096 }, 3600)).toBeCloseTo(0.1656, 12);
  });

  it("wins over COMPUTER_RATES, which still wins over the code", () => {
    const env = computerRates(JSON.stringify({ docker: { cpu_hour: 0.004 } }));
    expect(computerCostUsd("docker", { cpus: 1, memory_mb: 1024 }, 3600, env)).toBeCloseTo(
      0.009,
      12,
    );
    setCostTables({ computers: { docker: { cpu_hour: 0.001, gb_hour: 0.001 } } });
    expect(computerCostUsd("docker", { cpus: 1, memory_mb: 1024 }, 3600, env)).toBeCloseTo(
      0.002,
      12,
    );
  });

  it("keeps the good parts of a stored value and drops the bad ones", () => {
    setModelCatalog({
      models: [
        { id: "a/b", input_price: 99_999, output_price: 1 },
        { pattern: "([", input_price: 1, output_price: 1 },
        { id: "c/d", input_price: 0.2, output_price: 0.4 },
      ],
    });
    expect(costOf("a/b", usage(1e6, 0), "openrouter")).toBeCloseTo(1, 10);
    expect(costOf("c/d", usage(1e6, 1e6), "openrouter")).toBeCloseTo(0.6, 10);
  });
});
