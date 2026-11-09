import { parseRunEventPayload, RUN_EVENT_TYPES, type RunEventType } from "@kasama/contracts";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import type { Redactor } from "./redact.ts";

/**
 * Appends run events: written to Postgres first (gap-free seq per run, in one transaction);
 * a trigger then broadcasts on Realtime and notifies the API's SSE listeners.
 */
export class EventBus {
  private readonly db: Database;
  private readonly redactor?: Redactor;
  constructor(db: Database, redactor?: Redactor) {
    this.db = db;
    this.redactor = redactor;
  }

  async append(runId: string, type: string, payload: Record<string, unknown>): Promise<number> {
    const clean = this.redactor ? this.redactor.value(payload) : payload;
    if ((RUN_EVENT_TYPES as string[]).includes(type))
      parseRunEventPayload(type as RunEventType, clean);
    const rows = await this.db.execute<{ seq: number }>(
      sql`select seq from public.append_run_event(${runId}::uuid, ${type}, ${JSON.stringify(clean)}::jsonb)`,
    );
    return rows[0]?.seq ?? 0;
  }
}

/** Buffers message.delta text so a run writes at most one delta per interval (default 200 ms = 5/s). */
export class DeltaCoalescer {
  private buffer = "";
  private timer: ReturnType<typeof setTimeout> | undefined;
  private chain: Promise<void> = Promise.resolve();

  private readonly flushFn: (text: string) => Promise<void>;
  private readonly intervalMs: number;
  constructor(flushFn: (text: string) => Promise<void>, intervalMs = 200) {
    this.flushFn = flushFn;
    this.intervalMs = intervalMs;
  }

  push(text: string) {
    this.buffer += text;
    if (!this.timer) this.timer = setTimeout(() => this.flush(), this.intervalMs);
  }

  private flush() {
    this.timer = undefined;
    if (!this.buffer) return this.chain;
    const text = this.buffer;
    this.buffer = "";
    this.chain = this.chain.then(() => this.flushFn(text));
    return this.chain;
  }

  /** Writes anything buffered and waits for pending writes. */
  async drain() {
    if (this.timer) clearTimeout(this.timer);
    await this.flush();
    await this.chain;
  }
}
