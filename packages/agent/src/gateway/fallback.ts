import {
  type GatewayEvent,
  ModelCallError,
  type ModelGateway,
  type ModelRequest,
  type ResolvedModel,
} from "./types.ts";

export interface FallbackOptions {
  /** Base backoff before trying the next model, doubled each attempt. */
  backoffMs?: number;
  /** A model that sends nothing for this long is treated as timed out. */
  firstTokenTimeoutMs?: number;
  sleep?: (ms: number) => Promise<void>;
  onAttempt?: (info: { model: string; attempt: number; error?: string; err?: unknown }) => void;
}

/**
 * Tries each model in order. Fails over on retryable errors (429, 5xx, timeouts) that happen
 * before any output was produced; once output has streamed, errors propagate.
 */
export function withFallback(
  inner: ModelGateway,
  chain: ResolvedModel[],
  opts: FallbackOptions = {},
) {
  const sleep = opts.sleep ?? ((ms) => new Promise((r) => setTimeout(r, ms)));
  const backoff = opts.backoffMs ?? 500;
  const timeout = opts.firstTokenTimeoutMs ?? 60_000;
  if (chain.length === 0) throw new ModelCallError("no model configured", { retryable: false });

  return async function* stream(req: Omit<ModelRequest, "model">): AsyncIterable<GatewayEvent> {
    let lastError: unknown;
    for (let i = 0; i < chain.length; i++) {
      const model = chain[i] as ResolvedModel;
      if (i > 0) await sleep(backoff * 2 ** (i - 1));
      const ctrl = new AbortController();
      const onAbort = () => ctrl.abort(req.abortSignal?.reason);
      req.abortSignal?.addEventListener("abort", onAbort, { once: true });
      let produced = false;
      let timer: ReturnType<typeof setTimeout> | undefined = setTimeout(
        () => ctrl.abort(new Error("timeout")),
        timeout,
      );
      try {
        for await (const ev of inner.stream({ ...req, model, abortSignal: ctrl.signal })) {
          if (timer) {
            clearTimeout(timer);
            timer = undefined;
          }
          produced = true;
          yield ev;
        }
        opts.onAttempt?.({ model: model.model, attempt: i });
        return;
      } catch (err) {
        if (req.abortSignal?.aborted) throw err;
        const timedOut = ctrl.signal.aborted && !req.abortSignal?.aborted;
        const retryable = timedOut || (err instanceof ModelCallError ? err.retryable : true);
        opts.onAttempt?.({ model: model.model, attempt: i, error: (err as Error).message, err });
        lastError = err;
        if (produced || !retryable) throw err;
      } finally {
        if (timer) clearTimeout(timer);
        req.abortSignal?.removeEventListener("abort", onAbort);
      }
    }
    throw lastError instanceof Error
      ? lastError
      : new ModelCallError("all models failed", { retryable: false });
  };
}
