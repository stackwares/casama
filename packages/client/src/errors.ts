import type { components } from "./generated/schema.ts";

export type Problem = components["schemas"]["Problem"];

/**
 * An error answer from the Casama API, built from its RFC 9457 problem details. Match on `code`,
 * which is stable; `detail` is a sentence for people and can change.
 */
export class CasamaError extends Error {
  override readonly name = "CasamaError";
  /** The HTTP status. */
  readonly status: number;
  /** Stable, machine-readable code, such as `bot_not_found` or `rate_limited`. */
  readonly code: string;
  readonly title: string;
  readonly detail: string | undefined;
  /** The request path. */
  readonly instance: string | undefined;
  /** For `validation_failed`: one entry per bad field, with its dotted `path`. */
  readonly errors: Array<{ path: string; message: string }>;
  /** The `x-request-id` header; include it when you report a problem. */
  readonly requestId: string | undefined;
  /** For 429: seconds to wait, from `Retry-After`. */
  readonly retryAfter: number | undefined;
  /** The problem body as sent, or `undefined` when the answer wasn't problem+json. */
  readonly problem: Problem | undefined;

  constructor(
    status: number,
    problem: Partial<Problem> | undefined,
    meta: { requestId?: string | null; retryAfter?: string | null; statusText?: string } = {},
  ) {
    const code = problem?.code ?? `http_${status}`;
    const title = problem?.title ?? meta.statusText ?? `HTTP ${status}`;
    super(`${problem?.detail ?? title} (${code}, HTTP ${status})`);
    this.status = status;
    this.code = code;
    this.title = title;
    this.detail = problem?.detail;
    this.instance = problem?.instance;
    this.errors = problem?.errors ?? [];
    this.requestId = meta.requestId ?? undefined;
    const retry = meta.retryAfter ? Number(meta.retryAfter) : Number.NaN;
    this.retryAfter = Number.isFinite(retry) ? retry : undefined;
    this.problem = isProblem(problem) ? problem : undefined;
  }

  /**
   * Builds the error from a failed response. Pass `body` when it was already read (openapi-fetch
   * reads it into `error`); otherwise the response body is read here.
   */
  static async fromResponse(response: Response, body?: unknown): Promise<CasamaError> {
    let parsed = body;
    if (parsed === undefined && !response.bodyUsed) {
      const text = await response.text().catch(() => "");
      try {
        parsed = text ? JSON.parse(text) : undefined;
      } catch {
        parsed = undefined;
      }
    }
    return new CasamaError(
      response.status,
      parsed && typeof parsed === "object" ? (parsed as Partial<Problem>) : undefined,
      {
        requestId: response.headers.get("x-request-id"),
        retryAfter: response.headers.get("retry-after"),
        statusText: response.statusText || undefined,
      },
    );
  }
}

function isProblem(v: unknown): v is Problem {
  return (
    !!v &&
    typeof v === "object" &&
    typeof (v as Problem).code === "string" &&
    typeof (v as Problem).status === "number"
  );
}
