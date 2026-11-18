/**
 * The Cloudflare API envelope, shared by Casama Link's tunnels (D-296) and the sites zone's
 * custom hostnames (D-329). Plain fetch, like the other adapters: one place for the token, the
 * time limit, and turning Cloudflare's errors into a status the callers can act on.
 */

export class CloudflareError extends Error {
  readonly status: number;
  readonly code: number | null;
  constructor(status: number, code: number | null, message: string) {
    super(message);
    this.name = "CloudflareError";
    this.status = status;
    this.code = code;
  }
  /** Worth trying again later: rate limits and the provider's own failures. */
  get retryable() {
    return this.status === 429 || this.status >= 500;
  }
}

export interface CfEnvelope<T> {
  success: boolean;
  errors?: Array<{ code?: number; message?: string }>;
  result: T;
  result_info?: { total_count?: number };
}

export interface CloudflareClientOptions {
  apiToken: string;
  /** Tests point this at a fake. */
  apiUrl?: string;
  fetch?: typeof fetch;
  timeoutMs?: number;
}

export const CLOUDFLARE_API = "https://api.cloudflare.com/client/v4";

/** Makes one call; `onError` builds the error type the caller throws (so instanceof keeps working). */
export function cloudflareClient(
  o: CloudflareClientOptions,
  onError: (status: number, code: number | null, message: string) => Error = (s, c, m) =>
    new CloudflareError(s, c, m),
) {
  const base = (o.apiUrl ?? CLOUDFLARE_API).replace(/\/$/, "");
  const doFetch = o.fetch ?? fetch;
  return async function call<T>(
    method: string,
    path: string,
    body?: unknown,
  ): Promise<CfEnvelope<T>> {
    let res: Response;
    try {
      res = await doFetch(`${base}${path}`, {
        method,
        headers: {
          authorization: `Bearer ${o.apiToken}`,
          ...(body === undefined ? {} : { "content-type": "application/json" }),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(o.timeoutMs ?? 20_000),
      });
    } catch (e) {
      throw onError(503, null, `Cloudflare did not answer: ${(e as Error).message}`);
    }
    let json: CfEnvelope<T> | undefined;
    try {
      json = (await res.json()) as CfEnvelope<T>;
    } catch {
      // A proxy or an outage answered with something that isn't the API's JSON.
    }
    if (!res.ok || !json?.success) {
      const first = json?.errors?.[0];
      throw onError(
        res.ok ? 502 : res.status,
        first?.code ?? null,
        first?.message ?? `Cloudflare answered ${res.status}`,
      );
    }
    return json;
  };
}
