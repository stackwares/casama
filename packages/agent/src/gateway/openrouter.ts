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
  return openRouterCostFromText(await new Response(body).text());
}

/** Adds the workspace id and refuses providers that train on prompts, on Casama's key. */
export function rewriteOpenRouterRequest(
  body: string,
  opts: { user?: string; denyDataCollection?: boolean },
): string {
  if (!opts.user && !opts.denyDataCollection) return body;
  let json: Record<string, unknown>;
  try {
    json = JSON.parse(body) as Record<string, unknown>;
  } catch {
    return body;
  }
  if (opts.user) json.user = opts.user;
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
