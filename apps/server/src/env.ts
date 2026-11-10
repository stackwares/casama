import { z } from "zod";

const bool = z.enum(["true", "false", "1", "0"]).transform((v) => v === "true" || v === "1");

export const EnvSchema = z.object({
  MODE: z.enum(["api", "worker"]).default("api"),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().default(8787),
  DATABASE_URL: z.string().min(1),
  /** The worker's least-privilege role (kasama_worker, D-095); unset: the worker uses DATABASE_URL. */
  WORKER_DATABASE_URL: z.string().min(1).optional(),
  SUPABASE_URL: z.url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  /** Legacy HS256 secret. When unset, tokens are verified against the project's JWKS. */
  SUPABASE_JWT_SECRET: z.string().optional(),
  PUBLIC_APP_URL: z.url().default("http://localhost:3000"),
  /** Extra comma-separated origins allowed to call the API from a browser. */
  CORS_ORIGINS: z.string().default(""),
  /**
   * ChatGPT plan sign-in (SPEC: ChatGPT plan sign-in). auto: on for self-hosted servers, off when
   * billing is on (Kasama Cloud needs OpenAI's approval for hosted use first).
   */
  CHATGPT_SIGN_IN: z.enum(["auto", "on", "off"]).default("auto"),
  /**
   * Kasama Cloud abuse controls (D-094): sign-up proofs, a verified email before a free computer
   * starts, and automatic suspension on egress abuse. auto: on when billing is on.
   */
  ABUSE_CONTROLS: z.enum(["auto", "on", "off"]).default("auto"),
  /** Proofs a new account may carry (comma-separated): app_check, pow. */
  SIGNUP_PROOFS: z.string().default("app_check,pow"),
  /** Proof-of-work difficulty in leading zero bits (about 2^n hashes; 18 is a second or two). */
  SIGNUP_POW_DIFFICULTY: z.coerce.number().int().min(8).max(28).default(18),
  /** Firebase project number for App Check tokens; JWKS and issuer are overridable for tests. */
  APP_CHECK_PROJECT_NUMBER: z.string().optional(),
  APP_CHECK_JWKS_URL: z.url().default("https://firebaseappcheck.googleapis.com/v1/jwks"),
  APP_CHECK_ISSUER_BASE: z.url().default("https://firebaseappcheck.googleapis.com"),
  /** Supabase Auth "before user created" hook secret (`v1,whsec_…`, Standard Webhooks). */
  AUTH_HOOK_SECRET: z.string().optional(),
  /** OpenAI's auth server and Responses API; overridable for tests and proxies. */
  CHATGPT_AUTH_URL: z.url().default("https://auth.openai.com"),
  CHATGPT_API_URL: z.url().default("https://api.openai.com/v1"),
  /** Optional wallpaper photo search (D-087). Unset: the app offers its own patterns and photos. */
  UNSPLASH_ACCESS_KEY: z.string().optional(),
  UNSPLASH_API_URL: z.url().default("https://api.unsplash.com"),
  /** Kasama Cloud only (D-070). Self-hosted servers keep it off: no paywall, unlimited use. */
  BILLING_ENABLED: bool.default(false),
  /** Dodo Payments (web, desktop, credit packs). */
  DODO_API_KEY: z.string().optional(),
  DODO_WEBHOOK_SECRET: z.string().optional(),
  DODO_ENVIRONMENT: z.enum(["test", "live"]).default("test"),
  DODO_API_URL: z.url().optional(),
  /** App Store Server API (iOS). The private key is PEM text or a path to the .p8 file. */
  APP_STORE_ISSUER_ID: z.string().optional(),
  APP_STORE_KEY_ID: z.string().optional(),
  APP_STORE_PRIVATE_KEY: z.string().optional(),
  APP_STORE_BUNDLE_ID: z.string().default("dev.kasama.app"),
  APP_STORE_ENVIRONMENT: z.enum(["production", "sandbox"]).default("production"),
  APP_STORE_API_URL: z.url().optional(),
  /** Extra trusted roots (PEM text, or PEM paths comma-separated); Apple Root CA - G3 is built in. */
  APP_STORE_ROOT_CA: z.string().optional(),
  /** Google Play Developer API (Android). The service account is JSON text or a path. */
  GOOGLE_PLAY_PACKAGE_NAME: z.string().default("dev.kasama.app"),
  GOOGLE_PLAY_SERVICE_ACCOUNT: z.string().optional(),
  GOOGLE_PLAY_API_URL: z.url().optional(),
  /** RTDN push auth: a secret ?token= on the push URL and/or the push subscription's OIDC audience. */
  GOOGLE_PLAY_RTDN_TOKEN: z.string().min(16).optional(),
  GOOGLE_PLAY_RTDN_AUDIENCE: z.string().optional(),
  GOOGLE_PLAY_RTDN_EMAIL: z.string().optional(),
  /** Cloud Connect, cloud side (D-071): on whenever billing is on, unless turned off. */
  CLOUD_CONNECT: bool.default(true),
  CLOUD_MODEL_UPSTREAM_URL: z.url().default("https://openrouter.ai/api/v1"),
  CLOUD_MODEL_UPSTREAM_KEY: z.string().optional(),
  CLOUD_MODEL_MARKUP: z.coerce.number().positive().default(1),
  CLOUD_COMPUTER_USD_PER_HOUR: z.coerce.number().nonnegative().default(0.05),
  /** Cloud Connect, self-hosted side: use Kasama Cloud computers with this key. Unset = off. */
  KASAMA_CLOUD_URL: z.url().optional(),
  /** GitHub API base for skill imports (tests point it at a fake). */
  GITHUB_API_URL: z.url().optional(),
  KASAMA_CLOUD_KEY: z.string().optional(),
  /**
   * Push notifications: a Firebase service account (JSON text, or a path to the JSON file) for the
   * Firebase project the apps are built with. Unset: no push; the in-app inbox still works.
   */
  FCM_SERVICE_ACCOUNT: z.string().optional(),
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
  /** Lazy tool loading (D-106): bots with more tools than this load the rest on demand; 0 = off. */
  LAZY_TOOLS_THRESHOLD: z.coerce.number().int().min(0).default(30),
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
  /** Days between an account deletion request and the purge (D-072). */
  ACCOUNT_DELETION_GRACE_DAYS: z.coerce.number().int().min(0).max(30).default(7),
  /** Opt-in anonymous telemetry (D-074): off unless set to "on". */
  TELEMETRY: z.enum(["on", "off"]).default("off"),
  TELEMETRY_URL: z.url().default("https://telemetry.kasama.dev/v1/ping"),
  /** Enterprise features in ee/ (D-073): a signed license key. */
  KASAMA_LICENSE_KEY: z.string().optional(),
  /** Tests only (ignored unless NODE_ENV=test): another license public key. */
  KASAMA_LICENSE_PUBLIC_KEY: z.string().optional(),
  /** Supabase service role key: SSO provider admin (ee). */
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  /** Prometheus metrics at /metrics (D-075); protect with a bearer token in production. */
  METRICS_TOKEN: z.string().min(16).optional(),
  /** OAuth clients for apps that don't allow automatic registration (D-089), as JSON by app id:
   * {"slack": {"client_id": "...", "client_secret": "..."}}. Redirect URI: <API>/oauth/callback. */
  MCP_OAUTH_CLIENTS: z.string().optional(),
  /** A Google OAuth client for Gmail, Calendar and Drive (Google's MCP servers, D-089). */
  GOOGLE_OAUTH_CLIENT_ID: z.string().optional(),
  GOOGLE_OAUTH_CLIENT_SECRET: z.string().optional(),
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
  // An empty value means "not set" (compose files and .env templates write KEY= for optional keys).
  const cleaned = Object.fromEntries(Object.entries(source).filter(([, v]) => v !== ""));
  const parsed = EnvSchema.safeParse(cleaned);
  if (!parsed.success) {
    const fields = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid environment: ${fields}`);
  }
  return parsed.data;
}
