import { Agent, fetch as undiciFetch } from "undici";

/**
 * Calls that take as long as the work behind them (D-413).
 *
 * Node's fetch gives up after 300 seconds without response headers, and after 300 seconds between
 * two pieces of a body. Both limits cut real work off: a command that prints nothing for five
 * minutes (a build piped into `tail`) lost its stream and came back as "exit code -1", and a
 * checkpoint, sleep or restore of a large home folder, which answers only when it is done, failed
 * with "supervisor unreachable: fetch failed" although nothing was unreachable.
 *
 * The work has its own limits: a command is stopped by the computer when its own timeout passes,
 * and the run's stop button cancels the request. TCP keep-alive tells a dead peer from a quiet one.
 */
const connect = { keepAlive: true, keepAliveInitialDelay: 30_000 };

let streams: Agent | undefined;
let slow: Agent | undefined;

const via =
  (agent: () => Agent): typeof fetch =>
  (url, init) =>
    undiciFetch(
      url as string,
      { ...(init as object), dispatcher: agent() } as never,
    ) as unknown as Promise<Response>;

/** How long a stream may take to start: its first line comes as soon as the command is running. */
export const STREAM_START_MS = 120_000;
/** The most a call that answers when its work is done may take (archiving or restoring a home). */
export const SLOW_CALL_MS = 60 * 60_000;

/**
 * For streams that may stay quiet for a long time (a command's output): headers are expected
 * promptly, the body has no silence limit.
 */
export const streamFetch = via(() => {
  streams ??= new Agent({ headersTimeout: STREAM_START_MS, bodyTimeout: 0, connect });
  return streams;
});

/** For calls that answer only when long work is done (checkpoint, sleep, restore, start). */
export const slowFetch = via(() => {
  slow ??= new Agent({ headersTimeout: SLOW_CALL_MS, bodyTimeout: 0, connect });
  return slow;
});
