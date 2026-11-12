/**
 * Observability: OpenTelemetry traces (OTLP) and error reporting (D-063).
 * Errors go to one reporter: Sentry's protocol (Sentry, self-hosted Sentry or GlitchTip, by DSN)
 * or PostHog error tracking (cloud or self-hosted, by host). Everything is off unless configured,
 * and every payload is scrubbed: no secrets, prompts, messages or tool arguments.
 */
import { type Attributes, type Span, SpanStatusCode, trace } from "@opentelemetry/api";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from "@opentelemetry/semantic-conventions";
import * as Sentry from "@sentry/node";
import { PostHog } from "posthog-node";
import { closeProductAnalytics } from "./analytics.ts";
import { forcedIds } from "./run-trace.ts";

export type ErrorReporting = "auto" | "sentry" | "posthog" | "none";

export interface ObservabilityOptions {
  service: string;
  version?: string;
  environment?: string;
  /** auto (default): Sentry when a DSN is set, else PostHog when a key is set, else nothing. */
  errorReporting?: ErrorReporting;
  sentryDsn?: string;
  posthogKey?: string;
  posthogHost?: string;
  otlpEndpoint?: string;
}

/** Where captured errors go. */
export interface ErrorReporter {
  capture(err: unknown, context?: Record<string, unknown>): void;
  close(): Promise<void>;
}

// --- scrubbing ---------------------------------------------------------------

const SENSITIVE_KEY =
  /authorization|cookie|token|secret|password|passwd|api[_-]?key|credential|prompt|content|message|text|args|arguments|input|output|body|email|persona/i;
const SECRET_VALUE = [
  /\b(sk|pk|rk)-[A-Za-z0-9_-]{12,}/g,
  /\bBearer\s+[A-Za-z0-9._~+/=-]{8,}/gi,
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}/g,
  /\b(gh[pousr]_[A-Za-z0-9]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16})\b/g,
  /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
];

/** Removes anything that looks like a secret or an email, and truncates. */
export function scrubText(s: string, max = 500) {
  let out = s;
  for (const re of SECRET_VALUE) out = out.replace(re, "[redacted]");
  return out.length > max ? `${out.slice(0, max)}…` : out;
}

/** Keeps only safe context: ids, codes, numbers and booleans; drops sensitive keys. */
export function scrubContext(ctx: Record<string, unknown> = {}): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(ctx)) {
    if (SENSITIVE_KEY.test(k)) continue;
    if (typeof v === "number" || typeof v === "boolean" || v === null) out[k] = v;
    else if (typeof v === "string") out[k] = scrubText(v, 200);
  }
  return out;
}

function scrubError(err: unknown): Error {
  const e = err instanceof Error ? err : new Error(String(err));
  const clean = new Error(scrubText(e.message));
  clean.name = e.name;
  clean.stack = e.stack ? scrubText(e.stack, 8000) : undefined;
  return clean;
}

// --- reporters ---------------------------------------------------------------

function sentryReporter(opts: ObservabilityOptions): ErrorReporter {
  Sentry.init({
    dsn: opts.sentryDsn,
    environment: opts.environment,
    release: opts.version,
    enableOpenTelemetrySetup: false,
    beforeSend(event) {
      if (event.request) {
        delete event.request.data;
        delete event.request.cookies;
        delete event.request.query_string;
        event.request.headers = {};
      }
      delete event.user;
      if (event.message) event.message = scrubText(event.message);
      for (const ex of event.exception?.values ?? []) if (ex.value) ex.value = scrubText(ex.value);
      event.extra = scrubContext(event.extra as Record<string, unknown>);
      return event;
    },
    beforeBreadcrumb(b) {
      return { ...b, message: b.message ? scrubText(b.message) : undefined, data: undefined };
    },
  });
  return {
    capture: (err, context) =>
      Sentry.captureException(scrubError(err), { extra: scrubContext(context) }),
    close: async () => void (await Sentry.close(2000)),
  };
}

function posthogReporter(opts: ObservabilityOptions): ErrorReporter {
  const client = new PostHog(opts.posthogKey as string, {
    host: opts.posthogHost ?? "https://us.i.posthog.com",
    flushAt: 1,
    flushInterval: 0,
    // Strip source lines from stack frames: only file, function and line numbers leave the server.
    before_send: (event) => {
      const list = event?.properties?.$exception_list as
        | Array<{ stacktrace?: { frames?: Array<Record<string, unknown>> } }>
        | undefined;
      for (const ex of list ?? [])
        for (const f of ex.stacktrace?.frames ?? []) {
          delete f.pre_context;
          delete f.context_line;
          delete f.post_context;
        }
      return event;
    },
  });
  return {
    capture: (err, context) =>
      client.captureException(scrubError(err), `service:${opts.service}`, {
        ...scrubContext(context),
        service: opts.service,
        environment: opts.environment,
        release: opts.version,
        $process_person_profile: false,
      }),
    close: () => client.shutdown(2000),
  };
}

/** Picks the reporter from the options (exported for tests). */
export function createErrorReporter(opts: ObservabilityOptions): ErrorReporter | null {
  const mode = opts.errorReporting ?? "auto";
  if (mode === "none") return null;
  if ((mode === "sentry" || mode === "auto") && opts.sentryDsn) return sentryReporter(opts);
  if ((mode === "posthog" || mode === "auto") && opts.posthogKey) return posthogReporter(opts);
  return null;
}

let sdk: NodeSDK | undefined;
let reporter: ErrorReporter | null = null;

export function initObservability(opts: ObservabilityOptions) {
  reporter = createErrorReporter(opts);
  if (opts.otlpEndpoint) {
    sdk = new NodeSDK({
      resource: resourceFromAttributes({
        [ATTR_SERVICE_NAME]: opts.service,
        [ATTR_SERVICE_VERSION]: opts.version ?? "dev",
      }),
      traceExporter: new OTLPTraceExporter({
        url: `${opts.otlpEndpoint.replace(/\/$/, "")}/v1/traces`,
      }),
      // Run spans use ids derived from the run (D-107).
      idGenerator: forcedIds,
    });
    sdk.start();
  }
}

export async function shutdownObservability() {
  await Promise.allSettled([sdk?.shutdown(), reporter?.close(), closeProductAnalytics()]);
}

export const tracer = () => trace.getTracer("casama");

/** Runs fn inside a span; records exceptions and sets error status. */
export async function withSpan<T>(
  name: string,
  attributes: Attributes,
  fn: (span: Span) => Promise<T>,
): Promise<T> {
  return tracer().startActiveSpan(name, { attributes }, async (span) => {
    try {
      return await fn(span);
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR });
      throw err;
    } finally {
      span.end();
    }
  });
}

export function captureError(err: unknown, context?: Record<string, unknown>) {
  reporter?.capture(err, context);
}

/** Structured JSON logger. Never log message content or tool arguments at info level. */
export type LogLevel = "debug" | "info" | "warn" | "error";
const order: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };

export function createLogger(
  service: string,
  level: LogLevel = (process.env.LOG_LEVEL as LogLevel) ?? "info",
) {
  const emit = (lvl: LogLevel, msg: string, fields?: Record<string, unknown>) => {
    if (order[lvl] < order[level]) return;
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      level: lvl,
      service,
      msg,
      ...fields,
    });
    (lvl === "error" || lvl === "warn" ? process.stderr : process.stdout).write(`${line}\n`);
  };
  return {
    debug: (m: string, f?: Record<string, unknown>) => emit("debug", m, f),
    info: (m: string, f?: Record<string, unknown>) => emit("info", m, f),
    warn: (m: string, f?: Record<string, unknown>) => emit("warn", m, f),
    error: (m: string, f?: Record<string, unknown>) => emit("error", m, f),
  };
}
export type Logger = ReturnType<typeof createLogger>;

export * from "./analytics.ts";
export * from "./run-trace.ts";
