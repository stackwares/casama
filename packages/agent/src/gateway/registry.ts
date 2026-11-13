import { cloudOpenRouterCharge } from "@casama/domain";

/** Capabilities and prices per model. Unknown models get conservative defaults. */
export interface ModelCapabilities {
  contextWindow: number;
  tools: boolean;
  vision: boolean;
  caching: boolean;
  /** The provider can load tools on demand itself (then lazy loading uses that, D-106). */
  deferredTools?: boolean;
  /** USD per million tokens. */
  inputPrice: number;
  outputPrice: number;
  /** USD per million cached input tokens read or written, when the price list says (D-181). */
  cacheReadPrice?: number;
  cacheWritePrice?: number;
}

/** A model's price from a live price list (D-181), USD per million tokens. */
export interface LivePrice {
  inputPrice: number;
  outputPrice: number;
  cacheReadPrice?: number;
  cacheWritePrice?: number;
  contextWindow?: number;
}

let live = new Map<string, LivePrice>();

/** Replaces the live prices (keys are model ids in lower case). */
export function setLivePrices(prices: Map<string, LivePrice>) {
  live = prices;
}

const DEFAULT: ModelCapabilities = {
  contextWindow: 32_000,
  tools: true,
  vision: false,
  caching: false,
  inputPrice: 1,
  outputPrice: 3,
};

// Prices are list prices at the time of writing; the cost meter is checked against provider bills.
const KNOWN: Array<[RegExp, Partial<ModelCapabilities>]> = [
  // OpenRouter list prices (2026-11-13); default on OpenRouter is DeepSeek V4.1 Flash 1017 (D-258).
  [
    /deepseek-v4\.1-flash-1017/,
    {
      contextWindow: 1_048_576,
      vision: true,
      caching: true,
      inputPrice: 0.038,
      outputPrice: 0.5,
      cacheReadPrice: 0.01,
    },
  ],
  // OpenRouter list prices (2026-11-11); the default before D-258.
  [
    /muse-ember/,
    { contextWindow: 1_048_576, vision: true, caching: true, inputPrice: 0.1, outputPrice: 0.5 },
  ],
  // GPT-6 family (OpenRouter list prices, 2026-11-09); default on direct OpenAI is GPT-6 Luna (D-064).
  [
    /gpt-6(\.\d+)?-luna/,
    { contextWindow: 1_050_000, vision: true, caching: true, inputPrice: 0.1, outputPrice: 0.5 },
  ],
  [
    /gpt-6(\.\d+)?-terra/,
    { contextWindow: 1_050_000, vision: true, caching: true, inputPrice: 1, outputPrice: 5 },
  ],
  [
    /gpt-6(\.\d+)?-sol/,
    { contextWindow: 1_050_000, vision: true, caching: true, inputPrice: 2, outputPrice: 10 },
  ],
  [
    /gpt-6(\.\d+)?-astra/,
    { contextWindow: 1_050_000, vision: true, caching: true, inputPrice: 10, outputPrice: 50 },
  ],
  [
    /claude-(opus|fable)/,
    { contextWindow: 200_000, vision: true, caching: true, inputPrice: 15, outputPrice: 75 },
  ],
  [
    /claude-sonnet/,
    { contextWindow: 200_000, vision: true, caching: true, inputPrice: 3, outputPrice: 15 },
  ],
  [
    /claude-haiku/,
    { contextWindow: 200_000, vision: true, caching: true, inputPrice: 1, outputPrice: 5 },
  ],
  [
    /gpt-5.*mini|gpt-4o-mini|gpt-4\.1-mini/,
    { contextWindow: 128_000, vision: true, caching: true, inputPrice: 0.25, outputPrice: 2 },
  ],
  [
    /gpt-5|gpt-4\.1|gpt-4o/,
    { contextWindow: 128_000, vision: true, caching: true, inputPrice: 2.5, outputPrice: 10 },
  ],
  [
    /gemini-.*flash/,
    { contextWindow: 1_000_000, vision: true, caching: true, inputPrice: 0.3, outputPrice: 2.5 },
  ],
  [
    /gemini-.*pro/,
    { contextWindow: 1_000_000, vision: true, caching: true, inputPrice: 1.25, outputPrice: 10 },
  ],
  [/grok/, { contextWindow: 128_000, vision: true, inputPrice: 3, outputPrice: 15 }],
  [/llama|qwen|mistral|gemma|deepseek/, { contextWindow: 32_000, inputPrice: 0, outputPrice: 0 }],
  [/^fixture/, { contextWindow: 8_000, inputPrice: 1, outputPrice: 2 }],
];

/** OpenRouter's vendor prefix for models called on the provider's own API. */
const OPENROUTER_VENDOR: Record<string, string> = {
  anthropic: "anthropic",
  openai: "openai",
  google: "google",
  xai: "x-ai",
};

/**
 * The live price for a model id; a model called directly (`claude-sonnet-5-5` on Anthropic) is
 * looked up under its OpenRouter name too (`anthropic/claude-sonnet-5.5`).
 */
function livePrice(id: string, provider?: string): LivePrice | undefined {
  const exact = live.get(id);
  if (exact || !provider) return exact;
  const vendor = OPENROUTER_VENDOR[provider];
  if (!vendor || id.includes("/")) return undefined;
  return (
    live.get(`${vendor}/${id}`) ?? live.get(`${vendor}/${id.replace(/(\d)-(\d)(?!\d)/g, "$1.$2")}`)
  );
}

/**
 * A model's capabilities and price. A live price for the exact id wins over the table. On
 * OpenRouter (Casama's key, or the person's) a model with no known price is never free: it gets
 * the default price, unless its id says `:free` (D-181).
 */
export function capabilitiesOf(model: string, provider?: string): ModelCapabilities {
  const id = model.toLowerCase();
  let caps = DEFAULT;
  for (const [re, known] of KNOWN)
    if (re.test(id)) {
      caps = { ...DEFAULT, ...known };
      break;
    }
  const price = livePrice(id, provider);
  if (price)
    return {
      ...caps,
      ...price,
      caching: caps.caching || price.cacheReadPrice !== undefined,
      contextWindow: price.contextWindow ?? caps.contextWindow,
    };
  if (
    provider === "openrouter" &&
    caps.inputPrice === 0 &&
    caps.outputPrice === 0 &&
    !id.endsWith(":free")
  )
    return { ...caps, inputPrice: DEFAULT.inputPrice, outputPrice: DEFAULT.outputPrice };
  return caps;
}

/**
 * What a call cost, in USD. Cached input is read back at a tenth of the input price on models that
 * cache (Anthropic, OpenAI; Gemini is a quarter, so a tenth may undercharge slightly there),
 * and Anthropic charges cache writes at 1.25×; a live price list's own cache prices win. Input
 * tokens include cached and written ones.
 */
export function costOf(
  model: string,
  usage: {
    inputTokens: number;
    outputTokens: number;
    cachedInputTokens?: number;
    cacheWriteTokens?: number;
  },
  provider?: string,
) {
  const c = capabilitiesOf(model, provider);
  const cached = c.caching ? Math.min(usage.cachedInputTokens ?? 0, usage.inputTokens) : 0;
  const written = c.caching ? Math.min(usage.cacheWriteTokens ?? 0, usage.inputTokens - cached) : 0;
  const fresh = usage.inputTokens - cached - written;
  const readFactor = /gemini/.test(model.toLowerCase()) ? 0.25 : 0.1;
  const writeFactor = /claude/.test(model.toLowerCase()) ? 1.25 : 1;
  const readPrice = c.cacheReadPrice ?? c.inputPrice * readFactor;
  const writePrice = c.cacheWritePrice ?? c.inputPrice * writeFactor;
  return (
    (fresh * c.inputPrice +
      cached * readPrice +
      written * writePrice +
      usage.outputTokens * c.outputPrice) /
    1_000_000
  );
}

/**
 * Credits a call on Casama's key must have left before it starts (D-186).
 * 8k input and 2k output, with output tripled because reasoning models write past the cap.
 */
export function cloudCallReserveUsd(model: string): number {
  const c = capabilitiesOf(model, "openrouter");
  const raw = (8_000 * c.inputPrice + 6_000 * c.outputPrice) / 1_000_000;
  return cloudOpenRouterCharge(raw);
}
