import { existsSync } from "node:fs";
import { isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  CloudRelayPushSender,
  ComputerService,
  callDeclineSecret,
  computerRates,
  createSafeFetch,
  GlancePusher,
  NotificationService,
  RecordingPushSender,
  widgetPushSender,
} from "@casama/agent";
import { GA4_TWINS } from "@casama/contracts";
import { contentKeys, createDb } from "@casama/db";
import {
  captureError,
  createLogger,
  initObservability,
  initProductAnalytics,
  shutdownObservability,
} from "@casama/observability";
import {
  LocalProvider,
  objectStoreFromEnv,
  SupervisorProvider,
  unavailableProvider,
} from "@casama/sandbox";
import { serve } from "@hono/node-server";
import { sql } from "drizzle-orm";
import { createApp } from "./api/app.ts";
import { createTokenVerifier } from "./api/auth.ts";
import { type DrainMode, drainApi, requestCounter } from "./api/drain.ts";
import { attachLiveRelay, relayedCalls } from "./api/live-relay.ts";
import { CASAMA_VERSION } from "./api/routes/admin.ts";
import { attachTerminal } from "./api/routes/computers.ts";
import { attachStream, liveConfigFromEnv } from "./api/routes/live.ts";
import { attachLocalConnect, DeviceRegistry, internalToken } from "./api/routes/local.ts";
import { attachTelephony, phoneCalls } from "./api/routes/telephony.ts";
import { pgRunEventHub } from "./api/run-event-hub.ts";
import { dbosWorkflows } from "./api/workflows.ts";
import {
  apnsWatchFromEnv,
  apnsWidgetsFromEnv,
  billingFromEnv,
  casamaCloudProvider,
  inlineOrFile,
  linkFromEnv,
  linkUpkeepFromEnv,
} from "./billing/index.ts";
import { configureContentKeys } from "./content-keys.ts";
import { ee } from "./ee.ts";
import { cloudModelChatRouting, cloudModelRouting, loadEnv, voiceContext } from "./env.ts";
import { createPagesApp } from "./pages/app.ts";
import { createHostDispatcher } from "./pages/hosts.ts";
import { createSitesApp } from "./pages/sites.ts";
import { abuseControlsOn } from "./services/abuse.ts";
import { startAccountEmails } from "./services/account-emails.ts";
import { startCapacityMonitor } from "./services/capacity.ts";
import { disabledEmail, resendEmail, smtpEmail } from "./services/email.ts";
import { OutsideRelay } from "./services/outside-relay.ts";
import { chromiumPdf, remotePdf } from "./services/pdf.ts";
import { serverPushSender } from "./services/push-sender.ts";
import { referralConfig } from "./services/referrals.ts";
import { remoteAccessFromEnv } from "./services/remote-access.ts";
import { startGalleryPrompts, startRemoteSettings } from "./services/remote-settings.ts";
import { domainsBuyingFromEnv } from "./sites/buying.ts";
import { domainsUpkeepFromEnv, siteInstanceId } from "./sites/domains.ts";

const env = loadEnv();
// Encryption at rest (D-136): the key that wraps workspace data keys, if configured.
configureContentKeys(env);
// The worker reaches personal computers through the API's internal tunnel (D-066).
const localOpts = {
  apiUrl: env.API_INTERNAL_URL ?? `http://127.0.0.1:${env.PORT}`,
  internalToken: internalToken(env),
};
const logger = createLogger(`server-${env.MODE}`, env.LOG_LEVEL);
// Casama Link, self-hosted side: computers on Casama Cloud (D-071).
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
// Product events and daily rollups: Casama Cloud only, off unless PRODUCT_ANALYTICS=on (D-208); to PostHog
// and/or GA4, picked by ANALYTICS_PROVIDERS or by which keys are set (D-397).
initProductAnalytics({
  enabled: env.PRODUCT_ANALYTICS === "on",
  apiKey: env.POSTHOG_API_KEY,
  host: env.POSTHOG_HOST,
  providers: env.ANALYTICS_PROVIDERS,
  ga4: {
    measurementId: env.GA4_MEASUREMENT_ID,
    apiSecret: env.GA4_API_SECRET,
    debug: env.GA4_DEBUG === "1",
    twins: GA4_TWINS,
  },
  version: CASAMA_VERSION,
  environment: env.ANALYTICS_ENVIRONMENT ?? env.NODE_ENV,
});

const stoppers: Array<() => Promise<unknown>> = [];
/**
 * How this process is stopping (D-402). SIGTERM: a restart, requests in flight finish first.
 * SIGUSR2 (the API only): a deploy handing over to a new API that is already up, so calls are
 * carried until they end. A second signal while stopping cuts the handover short.
 */
let stopMode: DrainMode | null = null;
let cutShort = false;
const shutdown = async (signal: string, mode: DrainMode = "restart") => {
  if (stopMode) {
    cutShort = true;
    logger.info("stopping sooner", { signal });
    return;
  }
  stopMode = mode;
  logger.info("shutting down", { signal, mode });
  for (const stop of stoppers.reverse()) await stop().catch(() => {});
  await shutdownObservability();
  process.exit(0);
};
process.on("SIGTERM", () => void shutdown("SIGTERM"));
process.on("SIGINT", () => void shutdown("SIGINT"));
if (env.MODE === "api") process.on("SIGUSR2", () => void shutdown("SIGUSR2", "handover"));

process.on("unhandledRejection", async (reason) => {
  logger.error("unhandledRejection", {
    error: reason instanceof Error ? reason.message : String(reason),
  });
  captureError(reason, { service: `casama-${env.MODE}`, type: "unhandledRejection" });
  stopMode ??= "crash";
  for (const stop of stoppers.reverse()) await stop().catch(() => {});
  await shutdownObservability();
  process.exit(1);
});

process.on("uncaughtException", async (error) => {
  logger.error("uncaughtException", { error: error.message, stack: error.stack });
  captureError(error, { service: `casama-${env.MODE}`, type: "uncaughtException" });
  stopMode ??= "crash";
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
    objects: objectStoreFromEnv(process.env),
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
    casamaLink: linkFromEnv(env, handle.db),
    remoteAccess: remoteAccessFromEnv(env, cloud, CASAMA_VERSION, logger),
    // Live view away from the computer: a relay phones can reach, from Casama Cloud (D-296).
    outsideRelay:
      cloud && env.CASAMA_REMOTE_ACCESS === "on"
        ? new OutsideRelay({ cloud, upstream: env.CASAMA_LINK_RELAY_UPSTREAM, logger })
        : undefined,
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
    // Widget refresh pushes for answers and routine changes made here (D-405); the worker sends
    // the ones its runs and inbox rows cause.
    glance: apiGlancePusher(handle.db),
    // Pushes the API sends itself: a watch's "Open on phone" (D-410).
    notifications: apiNotifications(handle.db),
    // Outbound calls to addresses people type (password managers, Infisical, invites, memory
    // backends) can't reach private networks unless allowed (audit 2026-11: SSRF).
    apps: { fetch: createSafeFetch({ exemptCidrs: allowCidrs }) },
  };
  // Casama Cloud (D-094): free workspaces start computers only with a verified owner email.
  if (deps.computers) deps.computers.requireVerifiedEmail = abuseControlsOn(env);
  if (deps.computers) deps.computers.rates = computerRates(env.COMPUTER_RATES);
  if (deps.computers) {
    deps.computers.hostMemoryMb = Math.round(env.COMPUTER_HOST_MEMORY_GB * 1024);
    deps.computers.defaultMemoryMb = env.COMPUTER_MEMORY_MB;
  }
  // Models, prices and guard sites from Admin (D-373, D-374): loaded now and every minute.
  const stopRemoteSettings = startRemoteSettings(handle.db, logger);
  stoppers.push(async () => stopRemoteSettings());
  // Check-in and setup prompts from the gallery (D-374), every 15 minutes.
  const stopPrompts = startGalleryPrompts(env, logger);
  stoppers.push(async () => stopPrompts());
  const app = createApp(deps);
  // Requests being answered, so a stopping API lets them finish (D-402).
  const requests = requestCounter();
  const server = serve({ fetch: requests.wrap(app.fetch), port: env.PORT }, (info) =>
    logger.info("api listening", { port: info.port }),
  );
  // The pages origin (D-119) on its own port; put it behind its own host name in production.
  let pages: ReturnType<typeof serve> | undefined;
  if (env.PAGES_PORT) {
    // Site hosts (docs/SITES-AND-DOMAINS-PLAN.md §7.1) share the port, chosen by Host.
    const fetchPages = createHostDispatcher({
      db: handle.db,
      zone: env.CASAMA_SITES_ZONE,
      pagesHost: new URL(env.PAGES_URL).hostname,
      pages: createPagesApp(deps),
      sites: createSitesApp({ ...deps, instanceId: siteInstanceId(env) }),
    });
    pages = serve({ fetch: requests.wrap(fetchPages), port: env.PAGES_PORT }, (info) =>
      logger.info("pages listening", { port: info.port }),
    );
  }
  const http = [server, pages].filter(Boolean) as unknown as import("node:http").Server[];
  const terminals = attachTerminal(server as unknown as import("node:http").Server, deps);
  const liveViews = attachStream(server as unknown as import("node:http").Server, deps);
  attachTelephony(server as unknown as import("node:http").Server, deps);
  attachLiveRelay(server as unknown as import("node:http").Server, deps);
  attachLocalConnect(server as unknown as import("node:http").Server, deps);
  // Stopping without dropping people (D-402, src/api/drain.ts): stop listening (a new API that is
  // already up takes new requests), tell desktop apps, live views (D-360) and terminals to redial
  // ("server restarting", 1012), let requests in flight finish, carry calls through a handover,
  // then close calls with 1012 (the app resumes on the new API) and every connection left.
  stoppers.push(() =>
    drainApi({
      mode: stopMode ?? "restart",
      stopListening: () => {
        for (const s of http) s.close();
      },
      redialing: [
        () => deps.devices?.closeAll(),
        () => liveViews.closeAll(),
        () => terminals.closeAll(),
      ],
      inFlight: () => requests.inFlight,
      calls: [relayedCalls, phoneCalls],
      cutShort: () => cutShort,
      closeConnections: () => {
        for (const s of http) s.closeAllConnections();
      },
      requestMs: env.API_DRAIN_SECONDS * 1000,
      callMs: env.CALL_HANDOVER_SECONDS * 1000,
      logger,
    }),
  );
  // Casama Link (D-296): keep this server's address, or make sure it has none when it's off.
  void deps.remoteAccess.start().catch((e) => captureError(e, { where: "remote_access.start" }));
  stoppers.push(async () => deps.remoteAccess.stop());
} else {
  const { startWorker } = await import("./worker/index.ts");
  const handle = env.BILLING_ENABLED ? createDb(env.DATABASE_URL, { max: 3 }) : undefined;
  if (handle) stoppers.push(handle.close);
  const { galleryApps, galleryCodingAgents } = await import("./services/gallery.ts");
  const { galleryForAgents } = await import("./services/gallery-agent.ts");
  // The workspace gallery rules for the bots' gallery tools (D-315).
  const galleryDb = createDb(env.DATABASE_URL, { max: 1 });
  stoppers.push(galleryDb.close);
  // Models and prices from Admin (D-373): the worker bills runs, calls and media with them.
  const stopRemoteSettings = startRemoteSettings(galleryDb.db, logger);
  stoppers.push(async () => stopRemoteSettings());
  // Check-in and setup prompts from the gallery (D-374): the worker runs the briefs and scans.
  const stopPrompts = startGalleryPrompts(env, logger);
  stoppers.push(async () => stopPrompts());
  const worker = await startWorker({
    // Android rings carry a decline token (D-424), checked by the API with the same secret.
    callDeclineSecret: env.SUPABASE_JWT_SECRET
      ? callDeclineSecret(env.SUPABASE_JWT_SECRET)
      : undefined,
    egressExemptCidrs: allowCidrs,
    galleryApps: () => galleryApps(env),
    codingAgents: () => galleryCodingAgents(env),
    gallery: galleryForAgents(env, fetch, { db: galleryDb.db }),
    billing: handle ? billingFromEnv(env, handle.db, logger) : undefined,
    // Casama Link upkeep (D-296), on a cloud that gives out addresses.
    casamaLink: linkUpkeepFromEnv(env, handle?.db),
    // Connected domains (D-329), when the server has a sites zone and an edge.
    domains: (() => {
      const upkeep = domainsUpkeepFromEnv(env);
      return upkeep ? { ...upkeep, buying: domainsBuyingFromEnv(env) ?? undefined } : null;
    })(),
    telemetry:
      env.TELEMETRY === "on" ? { url: env.TELEMETRY_URL, version: CASAMA_VERSION } : undefined,
    cloud,
    databaseUrl: env.WORKER_DATABASE_URL ?? env.DATABASE_URL,
    apiDatabaseRole: env.WORKER_DATABASE_URL
      ? decodeURIComponent(new URL(env.DATABASE_URL).username) || undefined
      : undefined,
    pagesUrl: env.PAGES_URL,
    sitesZone: env.CASAMA_SITES_ZONE,
    publicApiUrl: env.PUBLIC_API_URL,
    fileLinkKey: internalToken(env),
    phoneCalls: env.PHONE_CALLS,
    geminiLiveModel: env.GEMINI_LIVE_MODEL,
    voiceContext: voiceContext(env),
    livePrices: env.MODEL_PRICES_URL === "off" ? undefined : { url: env.MODEL_PRICES_URL },
    computerRates: env.COMPUTER_RATES,
    computerHostMemoryMb: Math.round(env.COMPUTER_HOST_MEMORY_GB * 1024),
    computerDefaultMemoryMb: env.COMPUTER_MEMORY_MB,
    searxngUrl: env.SEARXNG_URL,
    serverSearch: {
      order: env.SEARCH_PROVIDER_ORDER,
      keys: {
        parallel: env.PARALLEL_API_KEY || undefined,
        serper: env.SERPER_API_KEY || undefined,
        deepseek: env.DEEPSEEK_SEARCH_API_KEY || undefined,
      },
    },
    serverGeminiKey: env.GOOGLE_AI_API_KEY,
    auditForwarding: ee
      ? await ee
          .verifyLicense(env.CASAMA_LICENSE_KEY)
          .then((l) => !!l && l.expiresAt > new Date() && l.features.includes("audit_forwarding"))
          .catch(() => false)
      : false,
    referrals: referralConfig(env),
    platformOpenRouterKey: env.CLOUD_MODEL_UPSTREAM_KEY,
    cloudModelRouting: cloudModelRouting(env),
    cloudModelChatRouting: cloudModelChatRouting(env),
    platformReasoningEffort: env.DEFAULT_REASONING_EFFORT,
    // Only the env override: the model catalog setting (D-373) is read at each run, so an Admin
    // change reaches the worker without a restart.
    cloudLockedModel: env.DEFAULT_MODEL_OPENROUTER,
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
    apnsAppTopic: env.APNS_TOPIC_APP,
    fcmServiceAccountJson: env.FCM_SERVICE_ACCOUNT
      ? inlineOrFile(env.FCM_SERVICE_ACCOUNT)
      : undefined,
    logger,
    logLevel: env.LOG_LEVEL,
    modelFixtures: fromRepoRoot(env.CASAMA_MODEL_FIXTURES),
    modelRecord: fromRepoRoot(env.CASAMA_MODEL_RECORD),
    maxOutputTokens: env.CASAMA_MAX_OUTPUT_TOKENS,
    embeddings: env.EMBEDDINGS,
    runConcurrency: env.RUN_CONCURRENCY,
    runWorkspaceConcurrency: env.RUN_WORKSPACE_CONCURRENCY,
    drainMs: env.WORKER_DRAIN_SECONDS * 1000,
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
    ownUrls: [env.PUBLIC_API_URL, env.PUBLIC_APP_URL, env.SUPABASE_URL].filter(
      (u): u is string => !!u,
    ),
    objects: objectStoreFromEnv(process.env) ?? undefined,
    chatgpt: { authUrl: env.CHATGPT_AUTH_URL, apiUrl: env.CHATGPT_API_URL },
    requireVerifiedEmail: abuseControlsOn(env),
  });
  stoppers.push(worker.stop);
  // One email sender for the worker's own emails (capacity alerts, account emails).
  const workerEmail = env.RESEND_API_KEY
    ? resendEmail(env.RESEND_API_KEY, env.EMAIL_FROM)
    : env.SMTP_HOST
      ? await smtpEmail(
          { host: env.SMTP_HOST, port: env.SMTP_PORT, user: env.SMTP_USER, pass: env.SMTP_PASS },
          env.EMAIL_FROM,
        )
      : undefined;
  // Account emails (D-302): billing changes and the welcome series, from the outbox.
  if (workerEmail && env.ACCOUNT_EMAILS) {
    const outbox = createDb(env.DATABASE_URL, { max: 1 });
    stoppers.push(outbox.close);
    stoppers.push(
      startAccountEmails({
        db: outbox.db,
        email: workerEmail,
        env,
        billing: env.BILLING_ENABLED,
        log: (msg, extra) => logger.info(msg, extra),
      }),
    );
  }
  // Casama's monthly email (D-408): changes Resend missed are sent again every 15 minutes. The
  // API's connection, because it reads sign-in emails (the worker's own role can't).
  {
    const { newsletterConfig, startNewsletterSync } = await import("./services/newsletter.ts");
    const config = newsletterConfig(env);
    if (config) {
      const newsletterDb = createDb(env.DATABASE_URL, { max: 1 });
      stoppers.push(newsletterDb.close);
      stoppers.push(
        startNewsletterSync({
          db: newsletterDb.db,
          config,
          log: (msg, extra) => logger.info(msg, extra),
        }),
      );
    }
  }
  // The waitlist (docs/WAITLIST-PLAN.md): "You're in" emails and tying sign-ups to their entries,
  // every minute. The API's connection, because it reads sign-in emails.
  {
    const { startWaitlist, waitlistAvailable } = await import("./services/waitlist.ts");
    if (waitlistAvailable(env)) {
      const { newsletterConfig } = await import("./services/newsletter.ts");
      const { referralConfig } = await import("./services/referrals.ts");
      const { internalToken } = await import("./api/routes/local.ts");
      const waitlistDb = createDb(env.DATABASE_URL, { max: 1 });
      stoppers.push(waitlistDb.close);
      stoppers.push(
        startWaitlist({
          db: waitlistDb.db,
          email: workerEmail,
          env,
          secret: internalToken(env),
          referrals: referralConfig(env).enabled,
          newsletter: newsletterConfig(env),
          log: (msg, extra) => logger.info(msg, extra),
        }),
      );
    }
  }
  // Gallery v2 (D-315): use counts and rewards hourly, the health check daily, monthly picks.
  {
    const { startGalleryJobs } = await import("./services/gallery-jobs.ts");
    const { setGalleryWarn } = await import("./services/gallery.ts");
    setGalleryWarn((msg, extra) => logger.warn(msg, extra));
    stoppers.push(
      startGalleryJobs({
        db: galleryDb.db,
        env,
        log: (msg, extra) => logger.info(msg, extra),
      }),
    );
  }
  // Server capacity (D-252): samples every 5 minutes and alerts the instance owners.
  const capacity = createDb(env.DATABASE_URL, { max: 1 });
  stoppers.push(capacity.close);
  stoppers.push(
    startCapacityMonitor({
      db: capacity.db,
      budgetMb: Math.round(env.COMPUTER_HOST_MEMORY_GB * 1024),
      adminEmails: env.INSTANCE_ADMIN_EMAILS,
      // The same way as every other notification: a linked server sends through Casama Cloud.
      notifications: new NotificationService(
        capacity.db,
        serverPushSender({
          db: capacity.db,
          fcmServiceAccountJson: env.FCM_SERVICE_ACCOUNT
            ? inlineOrFile(env.FCM_SERVICE_ACCOUNT)
            : undefined,
          cloud,
          onRelayError: (e) => logger.warn("push relay", { error: e.message }),
        }),
      ),
      email: workerEmail,
      log: (msg, extra) => logger.info(msg, extra),
    }),
  );
}

/**
 * The API's widget refresh pushes (D-405): the same senders as the worker's (its own Firebase key,
 * else Casama Cloud's relay; Apple with its own key, else the relay). None when it can't push.
 */
function apiGlancePusher(db: import("@casama/db").Database) {
  const push = serverPushSender({
    db,
    fcmServiceAccountJson: env.FCM_SERVICE_ACCOUNT
      ? inlineOrFile(env.FCM_SERVICE_ACCOUNT)
      : undefined,
    cloud,
    onRelayError: (e) => logger.warn("push relay", { error: e.message }),
  });
  const apple = apnsWidgetsFromEnv(env);
  if (push instanceof RecordingPushSender && !apple) return undefined;
  return new GlancePusher(db, widgetPushSender({ push, apple }), {
    onError: (e) => logger.warn("widget push", { error: e.message }),
  });
}

/**
 * The API's own pushes (D-410): the worker's senders, so a watch's "Open on phone" reaches the
 * phone the same way an inbox push does. Apple Watches' own tokens go with Apple's key, else the
 * relay.
 */
function apiNotifications(db: import("@casama/db").Database) {
  const push = serverPushSender({
    db,
    fcmServiceAccountJson: env.FCM_SERVICE_ACCOUNT
      ? inlineOrFile(env.FCM_SERVICE_ACCOUNT)
      : undefined,
    cloud,
    onRelayError: (e) => logger.warn("push relay", { error: e.message }),
  });
  const notifications = new NotificationService(db, push);
  notifications.watch =
    apnsWatchFromEnv(env, logger) ?? (push instanceof CloudRelayPushSender ? push : undefined);
  return notifications;
}

/**
 * A relative fixture path counts from the repo root, where .env lives, not from apps/server,
 * where `pnpm --filter @casama/server dev:worker` runs.
 */
function fromRepoRoot(path: string | undefined) {
  if (!path || isAbsolute(path) || existsSync(path)) return path;
  return resolve(fileURLToPath(new URL("../../../", import.meta.url)), path);
}
