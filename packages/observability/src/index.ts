/**
 * Observability: OpenTelemetry traces (OTLP) and Sentry errors.
 * Both are off unless configured, so tests and local dev need nothing.
 */
import { type Attributes, type Span, SpanStatusCode, trace } from "@opentelemetry/api";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from "@opentelemetry/semantic-conventions";
import * as Sentry from "@sentry/node";

export interface ObservabilityOptions {
  service: string;
  version?: string;
  environment?: string;
  sentryDsn?: string;
  otlpEndpoint?: string;
}

let sdk: NodeSDK | undefined;
let sentryOn = false;

export function initObservability(opts: ObservabilityOptions) {
  if (opts.sentryDsn) {
    Sentry.init({
      dsn: opts.sentryDsn,
      environment: opts.environment,
      release: opts.version,
      enableOpenTelemetrySetup: false,
      // Never send request bodies: they may contain messages or secrets.
      beforeSend(event) {
        if (event.request) delete event.request.data;
        return event;
      },
    });
    sentryOn = true;
  }
  if (opts.otlpEndpoint) {
    sdk = new NodeSDK({
      resource: resourceFromAttributes({
        [ATTR_SERVICE_NAME]: opts.service,
        [ATTR_SERVICE_VERSION]: opts.version ?? "dev",
      }),
      traceExporter: new OTLPTraceExporter({
        url: `${opts.otlpEndpoint.replace(/\/$/, "")}/v1/traces`,
      }),
    });
    sdk.start();
  }
}

export async function shutdownObservability() {
  await Promise.allSettled([sdk?.shutdown(), sentryOn ? Sentry.close(2000) : undefined]);
}

export const tracer = () => trace.getTracer("kasama");

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
  if (sentryOn) Sentry.captureException(err, context ? { extra: context } : undefined);
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
