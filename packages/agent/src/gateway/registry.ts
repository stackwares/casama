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
  // GPT-6 family (OpenRouter list prices, 2026-11-09); the default model is GPT-6 Luna (D-064).
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

export function capabilitiesOf(model: string): ModelCapabilities {
  const id = model.toLowerCase();
  for (const [re, caps] of KNOWN) if (re.test(id)) return { ...DEFAULT, ...caps };
  return DEFAULT;
}

export function costOf(model: string, usage: { inputTokens: number; outputTokens: number }) {
  const c = capabilitiesOf(model);
  return (usage.inputTokens * c.inputPrice + usage.outputTokens * c.outputPrice) / 1_000_000;
}
