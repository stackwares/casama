import { ComputerService, computerRates, createSafeFetch } from "@casama/agent";
import { contentKeys, createDb } from "@casama/db";
import { defaultModelFor } from "@casama/domain";
import {
  captureError,
  createLogger,
  initObservability,
  initProductAnalytics,
  shutdownObservability,
} from "@casama/observability";
import { LocalProvider, SupervisorProvider, unavailableProvider } from "@casama/sandbox";
import { serve } from "@hono/node-server";
import { sql } from "drizzle-orm";
import { createApp } from "./api/app.ts";
import { createTokenVerifier } from "./api/auth.ts";
import { CASAMA_VERSION } from "./api/routes/admin.ts";
import { attachTerminal } from "./api/routes/computers.ts";
import { attachStream, liveConfigFromEnv } from "./api/routes/live.ts";
import { attachLocalConnect, DeviceRegistry, internalToken } from "./api/routes/local.ts";
import { attachTelephony } from "./api/routes/telephony.ts";
import { pgRunEventHub } from "./api/run-event-hub.ts";
import { dbosWorkflows } from "./api/workflows.ts";
import {
  billingFromEnv,
  casamaCloudProvider,
  connectFromEnv,
  inlineOrFile,
} from "./billing/index.ts";
import { configureContentKeys } from "./content-keys.ts";
import { loadEnv, modelOverrides } from "./env.ts";
import { createPagesApp } from "./pages/app.ts";
import { abuseControlsOn } from "./services/abuse.ts";
import { disabledEmail, resendEmail, smtpEmail } from "./services/email.ts";
import { chromiumPdf, remotePdf } from "./services/pdf.ts";
import { referralConfig } from "./services/referrals.ts";

const env = loadEnv();
// Encryption at rest (D-136): the key that wraps workspace data keys, if configured.
configureContentKeys(env);
// The worker reaches personal computers through the API's internal tunnel (D-066).
const localOpts = {
  apiUrl: env.API_INTERNAL_URL ?? `http://127.0.0.1:${env.PORT}`,
  internalToken: internalToken(env),
};
const logger = createLogger(`server-${env.MODE}`, env.LOG_LEVEL);
// Cloud Connect, self-hosted side: computers on Casama Cloud (D-071).
const cloud =
  env.CASAMA_CLOUD_URL && env.CASAMA_CLOUD_KEY
    ? { url: env.CASAMA_CLOUD_URL, key: env.CASAMA_CLOUD_KEY }
    : undefined;
initObservability({
  service: `casama-${env.MODE}`,
  version: CASAMA_VERSION,
  environment: env.ANALYTICS_ENVIRONMENT ?? env.NODE_ENV,
  errorReporting: env.ERROR_REPORTING,
  sentryDsn: env.SENTRY_DSN,
  posthogKey: env.POSTHOG_API_KEY,
  posthogHost: env.POSTHOG_HOST,
  otlpEndpoint: env.OTEL_EXPORTER_OTLP_ENDPOINT,
});
// Product events and daily rollups: Casama Cloud only, off unless PRODUCT_ANALYTICS=on (D-208).
initProductAnalytics({
  enabled: env.PRODUCT_ANALYTICS === "on",
  apiKey: env.POSTHOG_API_KEY,
  host: env.POSTHOG_HOST,
  version: CASAMA_VERSION,
  environment: env.ANALYTICS_ENVIRONMENT ?? env.NODE_ENV,
});

const stoppers: Array<() => Promise<unknown>> = [];
const shutdown = async (signal: string) => {
  logger.info("shutting down", { signal });
  for (const stop of stoppers.reverse()) await stop().catch(() => {});
  await shutdownObservability();
  process.exit(0);
};
process.once("SIGTERM", () => void shutdown("SIGTERM"));
process.once("SIGINT", () => void shutdown("SIGINT"));

process.on("unhandledRejection", async (reason) => {
  logger.error("unhandledRejection", {
    error: reason instanceof Error ? reason.message : String(reason),
  });
  captureError(reason, { service: `casama-${env.MODE}`, type: "unhandledRejection" });
  for (const stop of stoppers.reverse()) await stop().catch(() => {});
  await shutdownObservability();
  process.exit(1);
});

process.on("uncaughtException", async (error) => {
  logger.error("uncaughtException", { error: error.message, stack: error.stack });
  captureError(error, { service: `casama-${env.MODE}`, type: "uncaughtException" });
  for (const stop of stoppers.reverse()) await stop().catch(() => {});
  await shutdownObservability();
  process.exit(1);
});

// Without INTERNAL_TOKEN the internal endpoints use a token derived from DATABASE_URL, which a weak
// database URL makes guessable (audit 2026-11). install.sh and the Helm chart always set one.
if (!env.INTERNAL_TOKEN && env.NODE_ENV === "production")
  logger.warn(
    "INTERNAL_TOKEN is not set: internal endpoints fall back to a token derived from DATABASE_URL. Set a random 32+ character INTERNAL_TOKEN.",
  );
// Private networks outbound calls may reach (OUTBOUND_ALLOW_CIDRS; SSRF guard otherwise).
const allowCidrs = env.OUTBOUND_ALLOW_CIDRS?.split(",")
  .map((c) => c.trim())
  .filter(Boolean);
if (env.MODE === "api") {
  const handle = createDb(env.DATABASE_URL);
  stoppers.push(handle.close);
  await contentKeys.attach(handle.client);
  const workflows = await dbosWorkflows(env.DATABASE_URL);
  stoppers.push(workflows.close);
  const hub = await pgRunEventHub(handle.client);
  stoppers.push(hub.close);
  const deps = {
    workflows,
    hub,
    computers:
      (env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN) || env.LOCAL_COMPUTERS || cloud
        ? new ComputerService(
            handle.db,
            env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
              ? new SupervisorProvider(env.SUPERVISOR_URL, env.SUPERVISOR_TOKEN)
              : unavailableProvider(),
            {
              ...(env.LOCAL_COMPUTERS ? { local: new LocalProvider(localOpts) } : {}),
              ...(cloud ? { "casama-cloud": casamaCloudProvider(cloud) } : {}),
            },
          )
        : undefined,
    billing: billingFromEnv(env, handle.db, logger),
    connect: connectFromEnv(env),
    devices: env.LOCAL_COMPUTERS ? new DeviceRegistry() : undefined,
    live: liveConfigFromEnv(env),
    env,
    db: handle.db,
    logger,
    verifyToken: createTokenVerifier({
      supabaseUrl: env.SUPABASE_URL,
      jwtSecret: env.SUPABASE_JWT_SECRET,
    }),
    email: env.RESEND_API_KEY
      ? resendEmail(env.RESEND_API_KEY, env.EMAIL_FROM)
      : env.SMTP_HOST
        ? await smtpEmail(
            { host: env.SMTP_HOST, port: env.SMTP_PORT, user: env.SMTP_USER, pass: env.SMTP_PASS },
            env.EMAIL_FROM,
          )
        : disabledEmail,
    pdf: env.PDF_RENDERER_URL
      ? remotePdf(env.PDF_RENDERER_URL)
      : env.PDF_CHROMIUM_PATH
        ? chromiumPdf(env.PDF_CHROMIUM_PATH)
        : null,
    readiness: { database: async () => void (await handle.db.execute(sql`select 1`)) },
    // Outbound calls to addresses people type (password managers, Infisical, invites, memory
    // backends) can't reach private networks unless allowed (audit 2026-11: SSRF).
    apps: { fetch: createSafeFetch({ exemptCidrs: allowCidrs }) },
  };
  // Casama Cloud (D-094): free workspaces start computers only with a verified owner email.
  if (deps.computers) deps.computers.requireVerifiedEmail = abuseControlsOn(env);
  if (deps.computers) deps.computers.rates = computerRates(env.COMPUTER_RATES);
  if (deps.computers) deps.computers.maxRunning = env.COMPUTER_HOST_CAPACITY;
  const app = createApp(deps);
  const server = serve({ fetch: app.fetch, port: env.PORT }, (info) =>
    logger.info("api listening", { port: info.port }),
  );
  // The pages origin (D-119) on its own port; put it behind its own host name in production.
  if (env.PAGES_PORT) {
    const pages = serve({ fetch: createPagesApp(deps).fetch, port: env.PAGES_PORT }, (info) =>
      logger.info("pages listening", { port: info.port }),
    );
    stoppers.push(() => new Promise((r) => pages.close(r)));
  }
  attachTerminal(server as unknown as import("node:http").Server, deps);
  attachStream(server as unknown as import("node:http").Server, deps);
  attachTelephony(server as unknown as import("node:http").Server, deps);
  attachLocalConnect(server as unknown as import("node:http").Server, deps);
  stoppers.push(() => new Promise((r) => server.close(r)));
} else {
  const { startWorker } = await import("./worker/index.ts");
  const handle = env.BILLING_ENABLED ? createDb(env.DATABASE_URL, { max: 3 }) : undefined;
  if (handle) stoppers.push(handle.close);
  const worker = await startWorker({
    egressExemptCidrs: allowCidrs,
    billing: handle ? billingFromEnv(env, handle.db, logger) : undefined,
    telemetry:
      env.TELEMETRY === "on" ? { url: env.TELEMETRY_URL, version: CASAMA_VERSION } : undefined,
    cloud,
    databaseUrl: env.WORKER_DATABASE_URL ?? env.DATABASE_URL,
    apiDatabaseRole: env.WORKER_DATABASE_URL
      ? decodeURIComponent(new URL(env.DATABASE_URL).username) || undefined
      : undefined,
    pagesUrl: env.PAGES_URL,
    publicApiUrl: env.PUBLIC_API_URL,
    phoneCalls: env.PHONE_CALLS,
    geminiLiveModel: env.GEMINI_LIVE_MODEL,
    livePrices: env.MODEL_PRICES_URL === "off" ? undefined : { url: env.MODEL_PRICES_URL },
    computerRates: env.COMPUTER_RATES,
    computerHostCapacity: env.COMPUTER_HOST_CAPACITY,
    searxngUrl: env.SEARXNG_URL,
    serverGeminiKey: env.GOOGLE_AI_API_KEY,
    auditForwarding: await import("@casama/ee")
      .then((m) => m.verifyLicense(env.CASAMA_LICENSE_KEY))
      .then((l) => !!l && l.expiresAt > new Date() && l.features.includes("audit_forwarding"))
      .catch(() => false),
    referrals: referralConfig(env),
    platformOpenRouterKey: env.CLOUD_MODEL_UPSTREAM_KEY,
    platformReasoningEffort: env.DEFAULT_REASONING_EFFORT,
    cloudLockedModel: defaultModelFor("openrouter", modelOverrides(env)),
    aiGateway: env.AI_GATEWAY_URL
      ? {
          url: env.AI_GATEWAY_URL,
          token: env.AI_GATEWAY_TOKEN,
          providers: env.AI_GATEWAY_PROVIDERS
            ? (env.AI_GATEWAY_PROVIDERS.split(",").map((p) => p.trim()) as never)
            : undefined,
        }
      : undefined,
    dataResale:
      env.TREG_RESALE === "on" && env.TREG_API_KEY
        ? { tregKey: env.TREG_API_KEY, tregUrl: env.TREG_API_URL }
        : undefined,
    apns:
      env.APNS_KEY_P8 && env.APNS_KEY_ID && env.APNS_TEAM_ID
        ? {
            keyP8: inlineOrFile(env.APNS_KEY_P8),
            keyId: env.APNS_KEY_ID,
            teamId: env.APNS_TEAM_ID,
            topic: env.APNS_VOIP_TOPIC,
            url: env.APNS_URL,
          }
        : undefined,
    fcmServiceAccountJson: env.FCM_SERVICE_ACCOUNT
      ? inlineOrFile(env.FCM_SERVICE_ACCOUNT)
      : undefined,
    logger,
    logLevel: env.LOG_LEVEL,
    modelFixtures: env.CASAMA_MODEL_FIXTURES,
    modelRecord: env.CASAMA_MODEL_RECORD,
    maxOutputTokens: env.CASAMA_MAX_OUTPUT_TOKENS,
    embeddings: env.EMBEDDINGS,
    runConcurrency: env.RUN_CONCURRENCY,
    lazyToolsThreshold: env.LAZY_TOOLS_THRESHOLD,
    langfuse:
      env.LANGFUSE_BASE_URL && env.LANGFUSE_PUBLIC_KEY && env.LANGFUSE_SECRET_KEY
        ? {
            baseUrl: env.LANGFUSE_BASE_URL,
            publicKey: env.LANGFUSE_PUBLIC_KEY,
            secretKey: env.LANGFUSE_SECRET_KEY,
          }
        : undefined,
    supervisor:
      env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
        ? { url: env.SUPERVISOR_URL, token: env.SUPERVISOR_TOKEN }
        : undefined,
    local: env.LOCAL_COMPUTERS ? localOpts : undefined,
    chatgpt: { authUrl: env.CHATGPT_AUTH_URL, apiUrl: env.CHATGPT_API_URL },
    requireVerifiedEmail: abuseControlsOn(env),
  });
  stoppers.push(worker.stop);
}
