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
  SENTRY_DSN: z.string().optional(),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string().optional(),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  /** Worker: replay recorded model responses (comma-separated fixture files) instead of calling providers. */
  KASAMA_MODEL_FIXTURES: z.string().optional(),
  /** Worker: append real model exchanges to this file as fixture turns. */
  KASAMA_MODEL_RECORD: z.string().optional(),
  /** Worker: memory embeddings. auto = the org's OpenAI key when present, else full-text search only. */
  EMBEDDINGS: z.enum(["auto", "none", "hash"]).default("auto"),
  RUN_CONCURRENCY: z.coerce.number().int().positive().default(20),
  /** Sandbox supervisor (computers). Both unset: bots have no computers. */
  SUPERVISOR_URL: z.url().optional(),
  SUPERVISOR_TOKEN: z.string().min(16).optional(),
  /** Live view (Phase 5): coturn's static-auth-secret and the TURN address clients use. */
  TURN_SECRET: z.string().min(16).optional(),
  TURN_PUBLIC_HOST: z.string().default("localhost"),
  TURN_PORT: z.coerce.number().int().default(3478),
  TURN_TLS_PORT: z.coerce.number().int().optional(),
  /** Public base URL of this API (signaling URLs); defaults to the request's origin. */
  PUBLIC_API_URL: z.url().optional(),
});
export type Env = z.infer<typeof EnvSchema>;

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  const parsed = EnvSchema.safeParse(source);
  if (!parsed.success) {
    const fields = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid environment: ${fields}`);
  }
  return parsed.data;
}
