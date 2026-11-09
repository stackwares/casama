import { appendFileSync } from "node:fs";
import type { ChatMessage, GatewayEvent, ModelGateway, ModelRequest } from "./types.ts";

/**
 * Recorded model responses for tests: the agent loop runs without paid API calls.
 * A turn is chosen by matching the request, so replays are deterministic and a
 * resumed (re-executed) step gets the same answer.
 */
export interface FixtureTurn {
  when?: {
    /** Case-insensitive substring of the last user message. */
    lastUserIncludes?: string;
    /** Role of the last message ("user" or "tool"). */
    lastRole?: "user" | "tool";
    /** Name of the tool whose result is the last message. */
    lastToolName?: string;
    /** Case-insensitive substring of the joined system blocks. */
    systemIncludes?: string;
    /** Exact model id the request is for. */
    model?: string;
  };
  events: GatewayEvent[];
  /** Delay before each event, to exercise streaming, cancel and crash paths. */
  delayMs?: number;
  /** Throw this error instead of answering (for failover tests). */
  error?: { message: string; status?: number; retryable?: boolean };
}

export interface FixtureFile {
  name: string;
  turns: FixtureTurn[];
}

const lastOf = (messages: ChatMessage[]) => messages[messages.length - 1];
const lastUser = (messages: ChatMessage[]) =>
  [...messages].reverse().find((m) => m.role === "user")?.content ?? "";

export function matches(turn: FixtureTurn, req: ModelRequest) {
  const w = turn.when;
  if (!w) return true;
  const last = lastOf(req.messages);
  if (
    w.lastUserIncludes &&
    !lastUser(req.messages).toLowerCase().includes(w.lastUserIncludes.toLowerCase())
  )
    return false;
  if (w.lastRole && last?.role !== w.lastRole) return false;
  if (w.lastToolName && !(last?.role === "tool" && last.name === w.lastToolName)) return false;
  if (
    w.systemIncludes &&
    !req.system.join("\n").toLowerCase().includes(w.systemIncludes.toLowerCase())
  )
    return false;
  if (w.model && req.model.model !== w.model) return false;
  return true;
}

export class ReplayGateway implements ModelGateway {
  readonly requests: ModelRequest[] = [];
  private readonly fixtures: FixtureFile[];
  constructor(fixtures: FixtureFile[]) {
    this.fixtures = fixtures;
  }

  async *stream(req: ModelRequest): AsyncIterable<GatewayEvent> {
    this.requests.push(req);
    const turn = this.fixtures.flatMap((f) => f.turns).find((t) => matches(t, req));
    if (!turn)
      throw new Error(
        `no fixture turn matches the request (last user: "${lastUser(req.messages).slice(0, 80)}")`,
      );
    if (turn.error) {
      const { ModelCallError } = await import("./types.ts");
      throw new ModelCallError(turn.error.message, {
        retryable: turn.error.retryable ?? true,
        status: turn.error.status,
      });
    }
    for (const ev of turn.events) {
      if (turn.delayMs) await sleep(turn.delayMs, req.abortSignal);
      if (req.abortSignal?.aborted)
        throw Object.assign(new Error("aborted"), { name: "AbortError" });
      yield ev.type === "finish" ? { ...ev, model: req.model.model } : ev;
    }
  }
}

function sleep(ms: number, signal?: AbortSignal) {
  return new Promise<void>((resolve) => {
    const t = setTimeout(resolve, ms);
    signal?.addEventListener(
      "abort",
      () => {
        clearTimeout(t);
        resolve();
      },
      { once: true },
    );
  });
}

/** Wraps a real gateway and appends each exchange as a fixture turn (JSON lines) for later replay. */
export function recordingGateway(inner: ModelGateway, file: string): ModelGateway {
  return {
    async *stream(req) {
      const events: GatewayEvent[] = [];
      for await (const ev of inner.stream(req)) {
        events.push(ev);
        yield ev;
      }
      const last = lastOf(req.messages);
      const turn: FixtureTurn = {
        when:
          last?.role === "tool"
            ? {
                lastRole: "tool",
                lastToolName: last.name,
                lastUserIncludes: lastUser(req.messages).slice(0, 60),
              }
            : { lastRole: "user", lastUserIncludes: lastUser(req.messages).slice(0, 60) },
        events,
      };
      appendFileSync(file, `${JSON.stringify(turn)}\n`);
    },
  };
}
