import { serve } from "@hono/node-server";
import { ComputerService } from "@kasama/agent";
import { contentKeys, createDb } from "@kasama/db";
import { configureContentKeys } from "./content-keys.ts";
import { createLogger, initObservability, shutdownObservability } from "@kasama/observability";
import { LocalProvider, SupervisorProvider, unavailableProvider } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import { createApp } from "./api/app.ts";
import { createTokenVerifier } from "./api/auth.ts";
import { KASAMA_VERSION } from "./api/routes/admin.ts";
import { attachTerminal } from "./api/routes/computers.ts";
import { attachStream, liveConfigFromEnv } from "./api/routes/live.ts";
import { attachLocalConnect, DeviceRegistry, internalToken } from "./api/routes/local.ts";
import { pgRunEventHub } from "./api/run-event-hub.ts";
import { dbosWorkflows } from "./api/workflows.ts";
import {
  billingFromEnv,
  connectFromEnv,
  inlineOrFile,
  kasamaCloudProvider,
} from "./billing/index.ts";
import { loadEnv } from "./env.ts";
import { createPagesApp } from "./pages/app.ts";
import { abuseControlsOn } from "./services/abuse.ts";
import { disabledEmail, resendEmail } from "./services/email.ts";
import { chromiumPdf } from "./services/pdf.ts";

const env = loadEnv();
// Encryption at rest (D-136): the key that wraps workspace data keys, if configured.
configureContentKeys(env);
// The worker reaches personal computers through the API's internal tunnel (D-066).
const localOpts = {
  apiUrl: env.API_INTERNAL_URL ?? `http://127.0.0.1:${env.PORT}`,
  internalToken: internalToken(env),
};
const logger = createLogger(`server-${env.MODE}`, env.LOG_LEVEL);
// Cloud Connect, self-hosted side: computers on Kasama Cloud (D-071).
const cloud =
  env.KASAMA_CLOUD_URL && env.KASAMA_CLOUD_KEY
    ? { url: env.KASAMA_CLOUD_URL, key: env.KASAMA_CLOUD_KEY }
    : undefined;
initObservability({
  service: `kasama-${env.MODE}`,
  environment: env.NODE_ENV,
  errorReporting: env.ERROR_REPORTING,
  sentryDsn: env.SENTRY_DSN,
  posthogKey: env.POSTHOG_API_KEY,
  posthogHost: env.POSTHOG_HOST,
  otlpEndpoint: env.OTEL_EXPORTER_OTLP_ENDPOINT,
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
              ...(cloud ? { "kasama-cloud": kasamaCloudProvider(cloud) } : {}),
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
    email: env.RESEND_API_KEY ? resendEmail(env.RESEND_API_KEY, env.EMAIL_FROM) : disabledEmail,
    pdf: env.PDF_CHROMIUM_PATH ? chromiumPdf(env.PDF_CHROMIUM_PATH) : null,
    readiness: { database: async () => void (await handle.db.execute(sql`select 1`)) },
  };
  // Kasama Cloud (D-094): free workspaces start computers only with a verified owner email.
  if (deps.computers) deps.computers.requireVerifiedEmail = abuseControlsOn(env);
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
  attachLocalConnect(server as unknown as import("node:http").Server, deps);
  stoppers.push(() => new Promise((r) => server.close(r)));
} else {
  const { startWorker } = await import("./worker/index.ts");
  const handle = env.BILLING_ENABLED ? createDb(env.DATABASE_URL, { max: 3 }) : undefined;
  if (handle) stoppers.push(handle.close);
  const worker = await startWorker({
    billing: handle ? billingFromEnv(env, handle.db, logger) : undefined,
    telemetry:
      env.TELEMETRY === "on" ? { url: env.TELEMETRY_URL, version: KASAMA_VERSION } : undefined,
    cloud,
    databaseUrl: env.WORKER_DATABASE_URL ?? env.DATABASE_URL,
    pagesUrl: env.PAGES_URL,
    apns:
      env.APNS_KEY_P8 && env.APNS_KEY_ID && env.APNS_TEAM_ID
        ? { keyP8: inlineOrFile(env.APNS_KEY_P8), keyId: env.APNS_KEY_ID, teamId: env.APNS_TEAM_ID, topic: env.APNS_VOIP_TOPIC, url: env.APNS_URL }
        : undefined,
    fcmServiceAccountJson: env.FCM_SERVICE_ACCOUNT
      ? inlineOrFile(env.FCM_SERVICE_ACCOUNT)
      : undefined,
    logger,
    logLevel: env.LOG_LEVEL,
    modelFixtures: env.KASAMA_MODEL_FIXTURES,
    modelRecord: env.KASAMA_MODEL_RECORD,
    maxOutputTokens: env.KASAMA_MAX_OUTPUT_TOKENS,
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
