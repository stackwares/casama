/**
 * The model-key providers as the apps show them (D-374, docs/REMOTE-CONTENT-PLAN.md #9): the add-key
 * form's two groups and their order, the keys worth adding on Casama Cloud, the keys that can
 * drive a bot, and the short hint under a provider's name. The server sends this in
 * `GET /v1/config` (`key_providers`); the apps keep one copy of it as the fallback for older
 * servers. Changing it here is a server deploy, never an app build.
 */

export interface KeyProviders {
  /** Chat-model providers, first in the add-key form (D-182). */
  chat: string[];
  /** Search, maps, data and a self-hosted server, under "More providers". */
  more: string[];
  /**
   * The only keys worth adding on Casama Cloud, which runs every model, voice and image itself
   * (D-188). Shrinks as Casama Cloud supplies more keys; empty hides Settings' Service keys row.
   */
  cloud: string[];
  /** Keys that run chat models: the ones that can drive a bot. */
  runs_chat: string[];
  /** The line under a provider's name in the form. */
  hints: Record<string, string>;
}

export const KEY_PROVIDERS: KeyProviders = {
  chat: ["openrouter", "openai", "anthropic", "google", "xai"],
  more: [
    "brave_search",
    "tavily",
    "parallel",
    "serper",
    "google_maps",
    "mapbox",
    "treg",
    "openai_compatible",
  ],
  // No search keys: Casama Cloud searches on its own keys (D-385).
  cloud: ["google_maps", "mapbox", "treg"],
  runs_chat: ["openrouter", "openai", "anthropic", "google", "xai", "openai_compatible"],
  hints: {
    openrouter: "recommended: chat, images, video, voice",
    google: "live calls only",
    openai_compatible: "Ollama, LM Studio, vLLM",
    brave_search: "web search",
    tavily: "web search",
    parallel: "web search",
    serper: "web search (Google results)",
    treg: "paid data (places, emails, SEO)",
    google_maps: "travel times for leave-now",
    mapbox: "travel times for leave-now",
  },
};
