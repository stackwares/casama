/** The last `"cost"` OpenRouter put in a response body (SSE or JSON), in USD. */
export function openRouterCostFromText(text: string): number | undefined {
  let cost: number | undefined;
  for (const match of text.matchAll(/"cost"\s*:\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/g)) {
    const n = Number(match[1]);
    if (Number.isFinite(n) && n >= 0) cost = n;
  }
  return cost;
}

export async function readOpenRouterCost(
  body: ReadableStream<Uint8Array>,
): Promise<number | undefined> {
  // A stopped reply aborts the fetch, which errors this copy of the body too. Nothing awaits the
  // cost then, so a rejection here was unhandled and took the whole worker down: cost unknown.
  try {
    return openRouterCostFromText(await new Response(body).text());
  } catch {
    return undefined;
  }
}

/**
 * Which of a model's providers on OpenRouter serve the server's shared key (D-354). One model is
 * sold by dozens of providers at prices many times apart, and each keeps its own prompt cache.
 * Left to itself OpenRouter spreads calls across them, so a run pays the dearer ones and loses its
 * cache whenever the next step lands somewhere else.
 */
export interface OpenRouterRouting {
  /** Provider tags tried first, in this order (`wafer`, `deepinfra/fp8`); the rest follow. */
  order?: string[];
  /** How the remaining providers are ranked. Unset: OpenRouter's own spread. */
  sort?: "price" | "throughput" | "latency";
}

/** `routing` as fields of OpenRouter's `provider` object; undefined when it sets nothing. */
export function openRouterProviderPreferences(
  routing: OpenRouterRouting | undefined,
): Record<string, unknown> | undefined {
  const order = (routing?.order ?? []).map((p) => p.trim()).filter(Boolean);
  if (!order.length && !routing?.sort) return undefined;
  return {
    ...(order.length ? { order } : {}),
    ...(routing?.sort ? { sort: routing.sort } : {}),
  };
}

/** `body` with the routing added to its `provider` object; what the body already says wins. */
export function withOpenRouterRouting<T extends Record<string, unknown>>(
  body: T,
  routing: OpenRouterRouting | undefined,
): T {
  const preferences = openRouterProviderPreferences(routing);
  if (!preferences) return body;
  const own =
    typeof body.provider === "object" && body.provider
      ? (body.provider as Record<string, unknown>)
      : {};
  return { ...body, provider: { ...preferences, ...own } };
}

/**
 * Adds the workspace id, refuses providers that train on prompts and sets which providers serve
 * the call, on Casama's key.
 */
export function rewriteOpenRouterRequest(
  body: string,
  opts: {
    user?: string;
    denyDataCollection?: boolean;
    routing?: OpenRouterRouting;
    /** Keeps the calls of one run on the provider that served its first (at most 256 characters). */
    sessionId?: string;
  },
): string {
  const routed = openRouterProviderPreferences(opts.routing) !== undefined;
  if (!opts.user && !opts.denyDataCollection && !routed && !opts.sessionId) return body;
  let json: Record<string, unknown>;
  try {
    json = JSON.parse(body) as Record<string, unknown>;
  } catch {
    return body;
  }
  if (opts.user) json.user = opts.user;
  if (opts.sessionId) json.session_id = opts.sessionId.slice(0, 256);
  if (routed) json = withOpenRouterRouting(json, opts.routing);
  if (opts.denyDataCollection) {
    const provider =
      typeof json.provider === "object" && json.provider
        ? (json.provider as Record<string, unknown>)
        : {};
    json.provider = { ...provider, data_collection: "deny" };
  }
  return JSON.stringify(json);
}

/**
 * Fetch for OpenRouter: optional request fields, and the exact cost from the response.
 * `track` receives the cost once the body has been read.
 */
export function openRouterFetch(opts: {
  user?: string;
  denyDataCollection?: boolean;
  routing?: OpenRouterRouting;
  sessionId?: string;
  track: (cost: Promise<number | undefined>) => void;
  fetchImpl?: typeof fetch;
}): typeof fetch {
  const base = opts.fetchImpl ?? fetch;
  return async (input, init) => {
    let next = init;
    if (typeof init?.body === "string") {
      const body = rewriteOpenRouterRequest(init.body, opts);
      if (body !== init.body) next = { ...init, body };
    }
    const res = await base(input, next);
    if (!res.body) return res;
    const [keep, copy] = res.body.tee();
    opts.track(readOpenRouterCost(copy));
    return new Response(keep, {
      status: res.status,
      statusText: res.statusText,
      headers: res.headers,
    });
  };
}
