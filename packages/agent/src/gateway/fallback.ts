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
  /** Once output has started, a gap this long between events ends the stream as timed out. */
  idleTimeoutMs?: number;
  sleep?: (ms: number) => Promise<void>;
  onAttempt?: (info: { model: string; attempt: number; error?: string; err?: unknown }) => void;
}

/**
 * Tries each model in order. Fails over on retryable errors (429, 5xx, timeouts) that happen
 * before any output was produced; once output has streamed, errors propagate. A bot with one
 * model gets a second try of it, so one stalled request doesn't fail the run.
 */
export function withFallback(
  inner: ModelGateway,
  chain: ResolvedModel[],
  opts: FallbackOptions = {},
) {
  const sleep = opts.sleep ?? ((ms) => new Promise((r) => setTimeout(r, ms)));
  const backoff = opts.backoffMs ?? 500;
  const timeout = opts.firstTokenTimeoutMs ?? 60_000;
  const idle = opts.idleTimeoutMs ?? 90_000;
  if (chain.length === 0) throw new ModelCallError("no model configured", { retryable: false });

  const attempts = chain.length === 1 ? [chain[0], chain[0]] : chain;
  return async function* stream(req: Omit<ModelRequest, "model">): AsyncIterable<GatewayEvent> {
    let lastError: unknown;
    for (let i = 0; i < attempts.length; i++) {
      const model = attempts[i] as ResolvedModel;
      if (i > 0) await sleep(backoff * 2 ** (i - 1));
      const ctrl = new AbortController();
      const onAbort = () => ctrl.abort(req.abortSignal?.reason);
      req.abortSignal?.addEventListener("abort", onAbort, { once: true });
      let produced = false;
      let timer: ReturnType<typeof setTimeout> | undefined;
      const arm = (ms: number) => {
        clearTimeout(timer);
        timer = setTimeout(() => ctrl.abort(new Error("timeout")), ms);
      };
      arm(timeout);
      try {
        for await (const ev of inner.stream({ ...req, model, abortSignal: ctrl.signal })) {
          // The clock is paused while the caller handles the event, so only the model's silence counts.
          clearTimeout(timer);
          timer = undefined;
          produced = true;
          yield ev;
          arm(idle);
        }
        opts.onAttempt?.({ model: model.model, attempt: i });
        return;
      } catch (err) {
        if (req.abortSignal?.aborted) throw err;
        const timedOut = ctrl.signal.aborted && !req.abortSignal?.aborted;
        // A stall reads as "took too long", not as the abort that ended it.
        const failure = timedOut
          ? new ModelCallError(
              `${model.model} sent nothing for ${Math.round((produced ? idle : timeout) / 1000)} s`,
              {
                retryable: true,
                code: "model_timeout",
                cause: err,
              },
            )
          : err;
        const retryable = timedOut || (err instanceof ModelCallError ? err.retryable : true);
        opts.onAttempt?.({
          model: model.model,
          attempt: i,
          error: (failure as Error).message,
          err: failure,
        });
        lastError = failure;
        if (produced || !retryable) throw failure;
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
