/** Default models (D-064): Muse Ember on OpenRouter, GPT-6 Luna on direct OpenAI; medium reasoning effort unless a bot overrides. */

export const REASONING_EFFORTS = ["none", "low", "medium", "high", "xhigh", "max"] as const;
export type ReasoningEffort = (typeof REASONING_EFFORTS)[number];

/** Default model ids per provider (OpenRouter catalog, 2026-11-11). */
export const DEFAULT_MODELS: Readonly<Record<string, string>> = {
  openrouter: "meta/muse-ember",
  openai: "gpt-6-luna",
};
export const DEFAULT_REASONING_EFFORT: ReasoningEffort = "medium";

/**
 * Each provider's small model, for a bot's background work (conversation summaries, memory,
 * routine briefs) when the bot hasn't picked a cheap model of its own (docs/COSTS.md).
 */
export const SMALL_MODELS: Readonly<Record<string, string>> = {
  openai: "gpt-6-luna",
  anthropic: "claude-haiku-5-5",
  google: "gemini-3.5-flash-lite",
};

/** The default model for a provider, if Casama has one (others need the user to pick). */
export function defaultModelFor(
  provider: string,
  overrides: Partial<Record<string, string | undefined>> = {},
): string | undefined {
  return overrides[provider] || DEFAULT_MODELS[provider];
}

/** A model a bot can use, as shown in the model picker. */
export interface ModelOption {
  id: string;
  name: string;
  context_length?: number;
  featured?: boolean;
}

/**
 * A short list of good chat models per provider, shown first in the picker and used when the
 * provider's live model list can't be fetched. Ids checked against OpenRouter's catalog on
 * 2026-11-11; the live list is the source of truth.
 */
export const FEATURED_MODELS: Readonly<Record<string, readonly ModelOption[]>> = {
  openrouter: [
    { id: "meta/muse-ember", name: "Meta: Muse Ember" },
    { id: "openai/gpt-6-luna", name: "OpenAI: GPT-6 Luna" },
    { id: "openai/gpt-6.1-sol", name: "OpenAI: GPT-6.1 Sol" },
    { id: "openai/gpt-6.1-terra", name: "OpenAI: GPT-6.1 Terra" },
    { id: "anthropic/claude-opus-5.5", name: "Anthropic: Claude Opus 5.5" },
    { id: "anthropic/claude-sonnet-5.5", name: "Anthropic: Claude Sonnet 5.5" },
    { id: "anthropic/claude-haiku-5.5", name: "Anthropic: Claude Haiku 5.5" },
    { id: "google/gemini-3.8-flash", name: "Google: Gemini 3.8 Flash" },
    { id: "x-ai/grok-4.7", name: "xAI: Grok 4.7" },
    { id: "deepseek/deepseek-v4.1-flash", name: "DeepSeek: DeepSeek V4.1 Flash" },
    { id: "moonshotai/kimi-k3.1-pro", name: "MoonshotAI: Kimi K3.1 Pro" },
    { id: "z-ai/glm-5.3", name: "Z.ai: GLM 5.3" },
    { id: "qwen/qwen3.8-max-0902", name: "Qwen: Qwen3.8 Max" },
  ],
  openai: [
    { id: "gpt-6-luna", name: "GPT-6 Luna" },
    { id: "gpt-6.1-sol", name: "GPT-6.1 Sol" },
    { id: "gpt-6.1-terra", name: "GPT-6.1 Terra" },
  ],
  anthropic: [
    { id: "claude-opus-5-5", name: "Claude Opus 5.5" },
    { id: "claude-sonnet-5-5", name: "Claude Sonnet 5.5" },
    { id: "claude-haiku-5-5", name: "Claude Haiku 5.5" },
  ],
  google: [{ id: "gemini-3.8-flash", name: "Gemini 3.8 Flash" }],
  xai: [{ id: "grok-4.7", name: "Grok 4.7" }],
  // ChatGPT plan sign-in: the live list (GET /v1/models, visibility "list") is the source of truth.
  chatgpt: [{ id: "gpt-6.1-sol", name: "GPT-6.1 Sol" }],
};

/** Providers whose keys run chat models (the others are tools: search, images, voice). */
export const CHAT_PROVIDERS = [
  "openrouter",
  "openai",
  "anthropic",
  "google",
  "xai",
  "openai_compatible",
  "chatgpt",
] as const;
