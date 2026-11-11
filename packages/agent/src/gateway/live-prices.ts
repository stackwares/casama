/**
 * Live model prices from OpenRouter's public model list (D-181): no key, nothing about the server
 * is sent. The worker refreshes them once a day; `capabilitiesOf` prefers them over the
 * hand-written table for models named by their OpenRouter id (for example `qwen/qwen3-235b`).
 */
import { type LivePrice, setLivePrices } from "./registry.ts";

export const OPENROUTER_MODELS_URL = "https://openrouter.ai/api/v1/models";
const DAY_MS = 24 * 60 * 60_000;

interface OpenRouterModel {
  id?: string;
  context_length?: number | null;
  pricing?: Record<string, string | number | null | undefined>;
}

/** USD per token (OpenRouter's unit) to USD per million tokens; negative means "varies". */
function perMillion(v: string | number | null | undefined): number | undefined {
  const n = typeof v === "string" ? Number(v) : v;
  return typeof n === "number" && Number.isFinite(n) && n >= 0 ? n * 1_000_000 : undefined;
}

export async function fetchOpenRouterPrices(
  opts: { url?: string; fetch?: typeof fetch } = {},
): Promise<Map<string, LivePrice>> {
  const res = await (opts.fetch ?? fetch)(opts.url ?? OPENROUTER_MODELS_URL, {
    headers: { accept: "application/json" },
    signal: AbortSignal.timeout(20_000),
  });
  if (!res.ok) throw new Error(`OpenRouter models returned ${res.status}`);
  const json = (await res.json()) as { data?: OpenRouterModel[] };
  const out = new Map<string, LivePrice>();
  for (const m of json.data ?? []) {
    const input = perMillion(m.pricing?.prompt);
    const output = perMillion(m.pricing?.completion);
    if (!m.id || input === undefined || output === undefined) continue;
    const cacheRead = perMillion(m.pricing?.input_cache_read);
    const cacheWrite = perMillion(m.pricing?.input_cache_write);
    out.set(m.id.toLowerCase(), {
      inputPrice: input,
      outputPrice: output,
      ...(cacheRead !== undefined ? { cacheReadPrice: cacheRead } : {}),
      ...(cacheWrite !== undefined ? { cacheWritePrice: cacheWrite } : {}),
      ...(m.context_length ? { contextWindow: m.context_length } : {}),
    });
  }
  return out;
}

/** Loads the prices now and once a day; failures keep the last good list. Returns a stop function. */
export function startLivePrices(
  opts: {
    url?: string;
    fetch?: typeof fetch;
    everyMs?: number;
    onError?: (err: Error) => void;
  } = {},
): () => void {
  const load = async () => {
    try {
      const prices = await fetchOpenRouterPrices(opts);
      if (prices.size) setLivePrices(prices);
    } catch (err) {
      opts.onError?.(err as Error);
    }
  };
  void load();
  const timer = setInterval(load, opts.everyMs ?? DAY_MS);
  timer.unref?.();
  return () => clearInterval(timer);
}
