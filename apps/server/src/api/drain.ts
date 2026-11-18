/**
 * How the API stops without dropping people (D-402, docs/SMOOTH-DEPLOYS-PLAN.md).
 *
 * A deploy starts the new API before it stops the old one. The old one then stops listening (Caddy
 * sends new requests to the new one), tells the sockets that redial on their own that it is
 * restarting (close code 1012), lets the requests it is answering finish, and, when it was asked to
 * hand over, keeps carrying the calls it holds until they end or the handover time runs out. Only
 * then does it close what is left and exit.
 */

/** WebSocket close code 1012: "service restart". The apps redial when they see it. */
export const RESTART_CODE = 1012;
export const RESTART_REASON = "server restarting";

/** A socket that closes with the restart code; the promise settles once its last writes are done. */
type Closer = (code: number, reason: string) => void | Promise<void>;

/** The open sockets of one kind in this process (call relays, phone bridges, terminals). */
export class OpenSockets {
  private readonly closers = new Set<Closer>();

  /** Tracks a socket until the returned function is called (when it closes). */
  add(close: Closer): () => void {
    this.closers.add(close);
    return () => {
      this.closers.delete(close);
    };
  }

  get size() {
    return this.closers.size;
  }

  /** Closes every socket with the restart code and waits for their last writes. */
  async closeAll(code = RESTART_CODE, reason = RESTART_REASON) {
    const all = [...this.closers];
    this.closers.clear();
    await Promise.allSettled(all.map(async (close) => close(code, reason)));
  }
}

/** Counts requests being answered, so a stopping API can let them finish. */
export function requestCounter() {
  let n = 0;
  return {
    get inFlight() {
      return n;
    },
    /** Wraps a fetch handler. A streamed response counts until its handler returned. */
    wrap<A extends unknown[], R>(fetch: (...args: A) => R | Promise<R>) {
      return async (...args: A): Promise<R> => {
        n++;
        try {
          return await fetch(...args);
        } finally {
          n--;
        }
      };
    },
  };
}

export type DrainMode = "restart" | "handover" | "crash";

export interface DrainOptions {
  mode: DrainMode;
  /** Stops accepting connections (the listening sockets close; open ones stay). */
  stopListening: () => void;
  /** Sockets that redial on their own: told to at once (live views, desktop apps, terminals). */
  redialing: Array<() => void | Promise<void>>;
  /** Requests being answered now. */
  inFlight: () => number;
  /** Live calls: kept through a handover, closed with the restart code otherwise. */
  calls: Array<{ readonly size: number; closeAll: () => Promise<void> }>;
  /** A second stop signal: stop carrying calls now. */
  cutShort?: () => boolean;
  /** Closes every connection still open, last. */
  closeConnections: () => void;
  /** How long requests in flight may take to finish. */
  requestMs: number;
  /** How long calls are carried in a handover. */
  callMs: number;
  logger?: { info: (msg: string, meta?: Record<string, unknown>) => void };
  /** For tests. */
  pollMs?: number;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** Waits until `done()` or until `ms` passed; returns whether it was done. */
export async function waitUntil(done: () => boolean, ms: number, pollMs = 250) {
  const deadline = Date.now() + ms;
  while (!done()) {
    if (Date.now() >= deadline) return false;
    await sleep(Math.min(pollMs, Math.max(1, deadline - Date.now())));
  }
  return true;
}

/** Stops serving in the order the module comment describes. */
export async function drainApi(o: DrainOptions) {
  const poll = o.pollMs ?? 250;
  const calls = () => o.calls.reduce((n, c) => n + c.size, 0);
  o.stopListening();
  await Promise.allSettled(o.redialing.map(async (close) => close()));
  if (o.mode !== "crash") {
    const settled = await waitUntil(() => o.inFlight() === 0, o.requestMs, poll);
    if (!settled) o.logger?.info("requests still open at shutdown", { open: o.inFlight() });
  }
  if (o.mode === "handover" && calls() > 0) {
    o.logger?.info("carrying calls before handing over", { calls: calls() });
    const ended = await waitUntil(() => calls() === 0 || !!o.cutShort?.(), o.callMs, poll);
    if (!ended) o.logger?.info("calls moved to the new server", { calls: calls() });
  }
  await Promise.allSettled(o.calls.map((c) => c.closeAll()));
  o.closeConnections();
}
