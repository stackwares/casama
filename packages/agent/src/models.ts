import { FEATURED_MODELS, type ModelOption } from "@kasama/domain";
import type { ProviderId } from "./gateway/types.ts";

export interface ModelListSource {
  provider: ProviderId | string;
  apiKey?: string;
  baseUrl?: string;
}

export interface ModelList {
  models: ModelOption[];
  /** "live" when the provider answered, "featured" when Kasama's short list was used instead. */
  source: "live" | "featured";
  error?: string;
}

const NOT_CHAT =
  /(embed|whisper|tts|transcribe|dall-e|image|moderation|audio|realtime|search-preview|codex-mini|sora|computer-use|:batch$)/i;

type Fetch = typeof fetch;

async function getJson(f: Fetch, url: string, headers: Record<string, string>) {
  const r = await f(url, { headers, signal: AbortSignal.timeout(10_000) });
  if (!r.ok) {
    const err = new Error(`HTTP ${r.status}`) as Error & { status: number };
    err.status = r.status;
    throw err;
  }
  return (await r.json()) as Record<string, unknown>;
}

const openAiStyle = async (f: Fetch, base: string, key?: string) => {
  const body = await getJson(f, `${base.replace(/\/$/, "")}/models`, {
    ...(key ? { authorization: `Bearer ${key}` } : {}),
  });
  const data = (body.data as Array<{ id: string; created?: number }>) ?? [];
  return data
    .sort((a, b) => (b.created ?? 0) - (a.created ?? 0))
    .map((m) => ({ id: m.id, name: m.id }));
};

/** Fetches the chat models a key can use from the provider's own model list. */
export async function fetchProviderModels(
  src: ModelListSource,
  f: Fetch = fetch,
): Promise<ModelOption[]> {
  switch (src.provider) {
    case "openrouter": {
      // The catalog is public; the key is not needed to read it.
      const body = await getJson(f, `${src.baseUrl ?? "https://openrouter.ai/api/v1"}/models`, {});
      const data =
        (body.data as Array<{
          id: string;
          name?: string;
          context_length?: number;
          created?: number;
          architecture?: { output_modalities?: string[] };
        }>) ?? [];
      return data
        .filter((m) => m.architecture?.output_modalities?.includes("text") ?? true)
        .sort((a, b) => (b.created ?? 0) - (a.created ?? 0))
        .map((m) => ({ id: m.id, name: m.name ?? m.id, context_length: m.context_length }));
    }
    case "openai":
      return openAiStyle(f, src.baseUrl ?? "https://api.openai.com/v1", src.apiKey);
    case "chatgpt": {
      // ChatGPT plans list the models they may use with visibility "list" (slug, display_name).
      const body = await getJson(
        f,
        `${(src.baseUrl ?? "https://api.openai.com/v1").replace(/\/$/, "")}/models`,
        { authorization: `Bearer ${src.apiKey ?? ""}` },
      );
      const data =
        ((body.data ?? body.models) as Array<{
          id?: string;
          slug?: string;
          display_name?: string;
          visibility?: string;
          context_window?: number;
        }>) ?? [];
      return data
        .filter((m) => m.visibility === undefined || m.visibility === "list")
        .map((m) => {
          const id = m.slug ?? m.id ?? "";
          return { id, name: m.display_name ?? id, context_length: m.context_window };
        })
        .filter((m) => m.id);
    }
    case "xai":
      return openAiStyle(f, src.baseUrl ?? "https://api.x.ai/v1", src.apiKey);
    case "openai_compatible":
      if (!src.baseUrl) return [];
      return openAiStyle(f, src.baseUrl, src.apiKey);
    case "anthropic": {
      const body = await getJson(f, "https://api.anthropic.com/v1/models?limit=1000", {
        "x-api-key": src.apiKey ?? "",
        "anthropic-version": "2023-06-01",
      });
      return ((body.data as Array<{ id: string; display_name?: string }>) ?? []).map((m) => ({
        id: m.id,
        name: m.display_name ?? m.id,
      }));
    }
    case "google": {
      const body = await getJson(
        f,
        `https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000&key=${encodeURIComponent(src.apiKey ?? "")}`,
        {},
      );
      return (
        (body.models as Array<{
          name: string;
          displayName?: string;
          inputTokenLimit?: number;
          supportedGenerationMethods?: string[];
        }>) ?? []
      )
        .filter((m) => m.supportedGenerationMethods?.includes("generateContent") ?? true)
        .map((m) => ({
          id: m.name.replace(/^models\//, ""),
          name: m.displayName ?? m.name,
          context_length: m.inputTokenLimit,
        }));
    }
    default:
      return [];
  }
}

/** Featured models first (in Kasama's order), then the rest of the provider's chat models. */
export function mergeModelList(provider: string, live: ModelOption[]): ModelOption[] {
  const featured = FEATURED_MODELS[provider] ?? [];
  const byId = new Map(live.map((m) => [m.id, m]));
  const top = featured
    .filter((m) => live.length === 0 || byId.has(m.id))
    .map((m) => ({ ...m, ...byId.get(m.id), featured: true }));
  const seen = new Set(top.map((m) => m.id));
  const rest = live.filter((m) => !seen.has(m.id) && !NOT_CHAT.test(m.id));
  return [...top, ...rest];
}

/** The picker's list for a key: live from the provider, or Kasama's short list if that fails. */
export async function listModels(src: ModelListSource, f: Fetch = fetch): Promise<ModelList> {
  try {
    const live = await fetchProviderModels(src, f);
    if (live.length > 0) return { models: mergeModelList(src.provider, live), source: "live" };
  } catch (err) {
    const status = (err as { status?: number }).status;
    return {
      models: mergeModelList(src.provider, []),
      source: "featured",
      error:
        status === 401 || status === 403
          ? "The provider rejected the key."
          : "Could not load the provider's model list.",
    };
  }
  return { models: mergeModelList(src.provider, []), source: "featured" };
}
