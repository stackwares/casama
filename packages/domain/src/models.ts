/** Default models (D-064): GPT-6 Luna at medium reasoning effort, configurable per server. */

export const REASONING_EFFORTS = ["none", "low", "medium", "high", "xhigh", "max"] as const;
export type ReasoningEffort = (typeof REASONING_EFFORTS)[number];

/** Model ids for GPT-6 Luna per provider (checked on OpenRouter and OpenAI, 2026-11-09). */
export const DEFAULT_MODELS: Readonly<Record<string, string>> = {
  openrouter: "openai/gpt-6-luna",
  openai: "gpt-6-luna",
};
export const DEFAULT_REASONING_EFFORT: ReasoningEffort = "medium";

/** The default model for a provider, if Kasama has one (others need the user to pick). */
export function defaultModelFor(
  provider: string,
  overrides: Partial<Record<string, string | undefined>> = {},
): string | undefined {
  return overrides[provider] || DEFAULT_MODELS[provider];
}
