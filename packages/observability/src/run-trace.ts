/**
 * Run tracing (SPEC: Post-v1 roadmap → Run tracing; D-107). One trace per run whose id comes from
 * the run id, with spans for the run, each model step and each tool call, named and attributed per
 * OpenTelemetry's GenAI conventions. Spans carry no prompt, message or tool content.
 *
 * Runs are durable and replay finished steps, so spans are only emitted by steps that actually
 * execute, and every id is deterministic: child spans hang off the run span's id, and the run span
 * itself is recorded when the run ends, with that same id (via ForcedIdGenerator).
 */
import { createHash } from "node:crypto";
import {
  type Attributes,
  context,
  type Span,
  SpanStatusCode,
  TraceFlags,
  trace,
} from "@opentelemetry/api";

/** The run's trace id: its uuid as 32 hex digits (a valid W3C trace id). */
export const runTraceId = (runId: string) => runId.replace(/-/g, "").toLowerCase();

/** A stable 16-hex span id for something inside a run. */
export const runSpanId = (runId: string, name: string) =>
  createHash("sha256").update(`${runId}:${name}`).digest("hex").slice(0, 16);

/**
 * Hands out a chosen trace and span id once (for the run span), random ids otherwise. Install it
 * as the SDK's idGenerator.
 */
export class ForcedIdGenerator {
  private forced: { traceId?: string; spanId?: string } = {};
  force(ids: { traceId: string; spanId: string }) {
    this.forced = { ...ids };
  }
  generateTraceId(): string {
    const t = this.forced.traceId;
    this.forced.traceId = undefined;
    return (
      t ??
      createHash("sha256")
        .update(`${Math.random()}${process.hrtime.bigint()}`)
        .digest("hex")
        .slice(0, 32)
    );
  }
  generateSpanId(): string {
    const s = this.forced.spanId;
    this.forced.spanId = undefined;
    return (
      s ??
      createHash("sha256")
        .update(`${Math.random()}${process.hrtime.bigint()}`)
        .digest("hex")
        .slice(0, 16)
    );
  }
}

export const forcedIds = new ForcedIdGenerator();

const tracer = () => trace.getTracer("kasama.runs");

/** The context whose parent is the run span (remote, so it works across processes and replays). */
function runContext(runId: string) {
  return trace.setSpanContext(context.active(), {
    traceId: runTraceId(runId),
    spanId: runSpanId(runId, "run"),
    traceFlags: TraceFlags.SAMPLED,
    isRemote: true,
  });
}

/** Starts a child span of the run (a model step or tool call); end it with endRunSpan. */
export function startRunChildSpan(runId: string, name: string, attributes: Attributes) {
  return tracer().startSpan(name, { attributes }, runContext(runId));
}

export function endRunSpan(
  span: Span,
  attributes: Attributes,
  error?: { type: string; message?: string },
) {
  span.setAttributes(attributes);
  if (error) {
    span.setAttribute("error.type", error.type);
    span.setStatus({ code: SpanStatusCode.ERROR });
  }
  span.end();
}

/** Records the run span itself, with the run's trace id and the id its children point at. */
export function recordRunSpan(
  runId: string,
  name: string,
  attributes: Attributes,
  times: { start: Date; end: Date },
  error?: { type: string },
) {
  forcedIds.force({ traceId: runTraceId(runId), spanId: runSpanId(runId, "run") });
  const span = tracer().startSpan(name, { attributes, startTime: times.start, root: true });
  if (error) {
    span.setAttribute("error.type", error.type);
    span.setStatus({ code: SpanStatusCode.ERROR });
  }
  span.end(times.end);
}
