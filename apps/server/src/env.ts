import { z } from "zod";

const bool = z.enum(["true", "false", "1", "0"]).transform((v) => v === "true" || v === "1");

export const EnvSchema = z.object({
  MODE: z.enum(["api", "worker"]).default("api"),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().default(8787),
  DATABASE_URL: z.string().min(1),
  SUPABASE_URL: z.url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  /** Legacy HS256 secret. When unset, tokens are verified against the project's JWKS. */
  SUPABASE_JWT_SECRET: z.string().optional(),
  PUBLIC_APP_URL: z.url().default("http://localhost:3000"),
  /** Extra comma-separated origins allowed to call the API from a browser. */
  CORS_ORIGINS: z.string().default(""),
  BILLING_ENABLED: bool.default(false),
  RESEND_API_KEY: z.string().optional(),
  EMAIL_FROM: z.string().default("Kasama <no-reply@localhost>"),
  RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(120),
  /** Error reporting (D-063): auto = Sentry if SENTRY_DSN, else PostHog if POSTHOG_API_KEY. */
  ERROR_REPORTING: z.enum(["auto", "sentry", "posthog", "none"]).default("auto"),
  /** Sentry protocol: sentry.io, self-hosted Sentry or GlitchTip. */
  SENTRY_DSN: z.string().optional(),
  POSTHOG_API_KEY: z.string().optional(),
  POSTHOG_HOST: z.url().optional(),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string().optional(),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  /** Worker: replay recorded model responses (comma-separated fixture files) instead of calling providers. */
  KASAMA_MODEL_FIXTURES: z.string().optional(),
  /** Worker: append real model exchanges to this file as fixture turns. */
  KASAMA_MODEL_RECORD: z.string().optional(),
  /** Worker: memory embeddings. auto = the org's OpenAI key when present, else full-text search only. */
  EMBEDDINGS: z.enum(["auto", "none", "hash"]).default("auto"),
  /** Default models (D-064): GPT-6 Luna on OpenRouter and OpenAI unless overridden. */
  DEFAULT_MODEL_OPENROUTER: z.string().optional(),
  DEFAULT_MODEL_OPENAI: z.string().optional(),
  DEFAULT_REASONING_EFFORT: z
    .enum(["none", "low", "medium", "high", "xhigh", "max"])
    .default("medium"),
  /** Worker: cap on output tokens per model call (live checks use a small cap). */
  KASAMA_MAX_OUTPUT_TOKENS: z.coerce.number().int().positive().optional(),
  RUN_CONCURRENCY: z.coerce.number().int().positive().default(20),
  /** Sandbox supervisor (computers). Both unset: bots have no computers. */
  SUPERVISOR_URL: z.url().optional(),
  SUPERVISOR_TOKEN: z.string().min(16).optional(),
  /** Live view (Phase 5): coturn's static-auth-secret and the TURN address clients use. */
  TURN_SECRET: z.string().min(16).optional(),
  TURN_PUBLIC_HOST: z.string().default("localhost"),
  TURN_PORT: z.coerce.number().int().default(3478),
  TURN_TLS_PORT: z.coerce.number().int().optional(),
  /** Owner admin console: comma-separated emails; when unset, the first user to sign up. */
  INSTANCE_ADMIN_EMAILS: z.string().optional(),
  /** Where the console checks for newer releases (GitHub "latest release" API shape); unset = off. */
  UPDATE_CHECK_URL: z.url().optional(),
  /** Desktop companion (D-066): personal computers as bot computers. On by default. */
  LOCAL_COMPUTERS: bool.default(true),
  /** Worker: how it reaches the API's internal endpoints (the companion tunnel). */
  API_INTERNAL_URL: z.url().optional(),
  /** Shared secret for /internal/*; derived from DATABASE_URL when unset. */
  INTERNAL_TOKEN: z.string().min(32).optional(),
  /** Public base URL of this API (signaling URLs); defaults to the request's origin. */
  PUBLIC_API_URL: z.url().optional(),
});
export type Env = z.infer<typeof EnvSchema>;

/** Per-server overrides of the default models. */
export const modelOverrides = (env: Env) => ({
  openrouter: env.DEFAULT_MODEL_OPENROUTER,
  openai: env.DEFAULT_MODEL_OPENAI,
});

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  const parsed = EnvSchema.safeParse(source);
  if (!parsed.success) {
    const fields = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid environment: ${fields}`);
  }
  return parsed.data;
}
