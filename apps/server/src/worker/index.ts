import { readFileSync } from "node:fs";
import {
  AiSdkGateway,
  ApnsClient,
  ApnsVoipSender,
  ApnsWatchSender,
  ApnsWidgetSender,
  backgroundComplete,
  builtinTools,
  CloudRelayPushSender,
  ComputerService,
  CredentialResolver,
  computerRates,
  createSafeFetch,
  type Embedder,
  EventBus,
  FcmPushSender,
  type FixtureFile,
  type FixtureTurn,
  GlancePusher,
  hashEmbedder,
  LangfuseSink,
  LiveRunPusher,
  MediaRouter,
  type ModelGateway,
  memoryStoreFor,
  NotificationService,
  OPENROUTER_EMBEDDING_MODEL,
  OpenRouterMediaProvider,
  type OpenRouterRouting,
  openAiEmbedder,
  PLATFORM_OPENROUTER_CREDENTIAL_ID,
  type PushSender,
  RecordingPushSender,
  ReplayGateway,
  recordingGateway,
  registerAutonomyTools,
  registerBotTools,
  registerCallTools,
  registerChannelTools,
  registerCodingTools,
  registerComputerTools,
  registerDataTools,
  registerDesktopContextTools,
  registerDesktopTools,
  registerDeviceTools,
  registerGalleryTools,
  registerHighlightTools,
  registerKnowledgeTools,
  registerLibraryTools,
  registerLinkTools,
  registerLoginTools,
  registerMailTools,
  registerPageTools,
  registerPaymentTools,
  registerPhoneCallTools,
  registerProjectTools,
  registerReplayTools,
  registerSecretRequestTool,
  registerSettingsTools,
  registerSetupTools,
  registerSiteTools,
  registerSkillTools,
  registerSuggestionTools,
  registerTeachTools,
  registerToolsLoad,
  registerWatcherTools,
  SearchCache,
  StripeIssuingProvider,
  searchProviderFor,
  serverSearchChain,
  startLivePrices,
  TregProvider,
  TwilioClient,
  type VoipSender,
  type WidgetPushSender,
  WORKSPACE_SEARCH_PROVIDERS,
  widgetPushSender,
  workspaceSearchProvider,
} from "@casama/agent";
import { contentKeys, createDb, type Database } from "@casama/db";
import { openRouterModelId } from "@casama/domain";
import type { Logger } from "@casama/observability";
import { LocalProvider, SupervisorProvider, unavailableProvider } from "@casama/sandbox";
import { DBOS, DBOSClient } from "@dbos-inc/dbos-sdk";
import { sql } from "drizzle-orm";
import { casamaCloudProvider } from "../billing/index.ts";
import { appLink } from "../env.ts";
import {
  type AdminBotDeps,
  adminRunCheck,
  ownerEmails,
  registerAdminTools,
} from "../services/admin-bot.ts";
import { getCloudModels } from "../services/cloud-models.ts";
import { serverPushSender } from "../services/push-sender.ts";
import { countingSearch, createVendorCounter } from "../services/vendors/count.ts";
import { searchDomains } from "../sites/buying.ts";
import { sitesSettings } from "../sites/config.ts";
import { drainSteps } from "./drain.ts";
import { keyQueuedRuns, runPartitionKey } from "./run-queue.ts";
import { RunSlots, STARTED_PER_WORKING } from "./run-slots.ts";
import {
  analyticsDailyWorkflow,
  billingSettleWorkflow,
  computersIdleWorkflow,
  configureWorkflows,
  domainsWorkflow,
  maintenanceWorkflow,
  privacyWorkflow,
  QUEUES,
  routinesTickWorkflow,
  telemetryWorkflow,
} from "./workflows.ts";

export interface WorkerOptions {
  /** INSTANCE_ADMIN_EMAILS: who may use the admin bot (D-435). Empty: no admin tools. */
  instanceAdminEmails?: string;
  /** Signs Android rings' decline tokens (D-424; `callDeclineSecret`). */
  callDeclineSecret?: string;
  /** Where the Library keeps files copied off computers (D-276). */
  objects?: import("@casama/sandbox").ObjectStore;
  /** This server's own addresses (API, web app, sign-in), which bots never open (D-323). */
  ownUrls?: string[];
  databaseUrl: string;
  /** The pages origin's public address, for public page links (D-119). */
  pagesUrl?: string;
  /** Sites (docs/SITES-AND-DOMAINS-PLAN.md): the zone sites.publish puts pages on. */
  sitesZone?: string;
  /** Langfuse LLM traces for every model attempt (D-107). */
  langfuse?: { baseUrl: string; publicKey: string; secretKey: string };
  /** Bots with more tools start with core tools and load the rest (D-106); 0 = off, default 30. */
  lazyToolsThreshold?: number;
  logger: Logger;
  logLevel?: string;
  /** Comma-separated fixture files: replay recorded model responses instead of calling providers. */
  modelFixtures?: string;
  /** Append every real model exchange to this file as fixture turns. */
  modelRecord?: string;
  /** Cap on output tokens per model call (live checks). */
  maxOutputTokens?: number;
  /** Which OpenRouter providers serve calls on the server's shared key (D-354). */
  cloudModelRouting?: OpenRouterRouting;
  /** The same for chat steps a person is waiting on, when it differs (D-355). */
  cloudModelChatRouting?: OpenRouterRouting;
  embeddings?: "auto" | "none" | "hash";
  runConcurrency?: number;
  /** Runs one workspace may have going at once (0 = no limit). */
  runWorkspaceConcurrency?: number;
  /** How long a stopping worker lets steps in flight finish (D-402); default 45 s. */
  drainMs?: number;
  db?: Database;
  vendorUsage?: {
    env: import("../env.ts").Env;
    email: import("../services/email.ts").EmailSender;
    adminDb?: Database;
  };
  /** Desktop companion tunnel (the API's internal URL and token). */
  local?: { apiUrl: string; internalToken: string };
  /** Sandbox supervisor; without it bots have no computers. */
  supervisor?: { url: string; token: string };
  /** Push notifications; defaults to FCM when a service account is given, else recorded only. */
  push?: PushSender;
  fcmServiceAccountJson?: string;
  /** iOS call rings (PushKit, D-135): a sender, or APNs settings. */
  voip?: VoipSender;
  apns?: { keyP8: string; keyId: string; teamId: string; topic: string; url?: string };
  /** Widget refresh pushes (D-405): the app's bundle id they go to; default ai.casama.app. */
  apnsAppTopic?: string;
  /** Widget refresh pushes: a sender (tests), else built from the push sender and APNs. */
  widgets?: WidgetPushSender;
  /** Private address ranges the worker may call (local development and tests only). */
  egressExemptCidrs?: string[];
  /** The API's database role, granted access to DBOS's tables when it isn't the worker's own. */
  apiDatabaseRole?: string;
  /** Base URL overrides for provider APIs (tests). */
  /** Device connections (D-149): how long tools wait for a device (tests shorten it). */
  deviceWaitMs?: { read?: number; write?: number };
  providerBases?: {
    google_maps?: string;
    mapbox?: string;
    brave?: string;
    tavily?: string;
    parallel?: string;
    serper?: string;
    deepseek?: string;
    openrouter?: string;
    openai?: string;
    gemini?: string;
    cursor?: string;
    treg?: string;
    twilio?: string;
    twilioLookups?: string;
    stripe?: string;
  };
  /**
   * The API's public address, for Twilio's call webhooks and media streams (D-141) and coding
   * agents that use the person's browser (D-323 C16).
   */
  publicApiUrl?: string;
  /** Signs chat apps' file links (D-342); the API checks them with the same key. */
  fileLinkKey?: string;
  /** Hosted bot mail (BOT-EMAIL-PLAN §6.4): the server's sender; unset: none goes out. */
  hostedMail?: import("@casama/agent").HostedMailSender | null;
  /** Hosted bot mail: the domain addresses live on (MAIL_DOMAIN). */
  mailDomain?: string;
  /** Hosted bot mail: welcome mail is skipped while sending is paused (MAIL_SEND_PAUSED). */
  mailSendPaused?: boolean;
  /** Phone calls through Twilio (D-141): false leaves the voice.call tool out. Default on. */
  phoneCalls?: boolean;
  /** Audit-log forwarding (D-146): on when the enterprise license includes it. */
  auditForwarding?: boolean;
  /** Invite friends (D-211): rewards for inviters, decided every minute. Unset: off. */
  referrals?: { enabled: boolean; rewardUsd: number; welcomeUsd: number; cap: number };
  /** Cloudflare AI Gateway for model calls (D-145). */
  aiGateway?: import("@casama/agent").AiGatewayConfig;
  /** Casama Cloud's shared OpenRouter key. Workspaces without their own key use it. */
  platformOpenRouterKey?: string;
  /** Reasoning level on the shared key (DEFAULT_REASONING_EFFORT). */
  platformReasoningEffort?: "none" | "low" | "medium" | "high" | "xhigh" | "max";
  /** The one model Casama Cloud runs on that key. */
  cloudLockedModel?: string;
  /** Paid data resale on Casama Cloud (D-138): Casama's Treg key, used only when resale is on. */
  dataResale?: { tregKey: string; tregUrl?: string };
  /** Casama Link upkeep (D-296), on a cloud that gives out addresses: parking and warnings. */
  casamaLink?: Omit<import("../link/upkeep.ts").LinkUpkeepOptions, "db" | "log">;
  /** Connected domains (D-329): proof checks, certificates, cleanup and the plan pause rule. */
  domains?:
    | (import("../sites/domains.ts").DomainsUpkeepOptions & {
        /** Buying domains (Casama Cloud): the registrar and domain payments. */
        buying?: Pick<import("../sites/buying.ts").BuyingContext, "registrar" | "payments">;
      })
    | null;
  /** Billing (Casama Cloud only); settles usage into credits every minute. */
  billing?: import("../billing/service.ts").BillingService;
  /** Opt-in anonymous telemetry (D-074); unset = off. */
  telemetry?: { url: string; version: string };
  /** Casama Link (self-hosted side): the `casama-cloud` computer provider. */
  cloud?: { url: string; key: string };
  /** Gemini Live model for live calls (default gemini-3.8-live). */
  geminiLiveModel?: string;
  /** When a live call's oldest turns are dropped, and down to how much (tokens of conversation). */
  voiceContext?: { triggerTokens?: number; targetTokens?: number };
  /** Refresh model prices from a live list daily (D-181); off unless set. */
  livePrices?: { url?: string };
  /** COMPUTER_RATES: computer prices by provider as JSON (D-180). */
  computerRates?: string;
  /** Hosted computers that may run at once (D-248); 0 or unset = no limit. */
  /** COMPUTER_HOST_MEMORY_GB in MB (D-252). */
  computerHostMemoryMb?: number;
  /** A computer's memory when its size isn't recorded (D-272). */
  computerDefaultMemoryMb?: number;
  /** The server's SearXNG (SEARXNG_URL, D-179): web search for workspaces without their own key. */
  searxngUrl?: string;
  /** The server's own search keys and their order (SEARCH_PROVIDER_ORDER, D-384). */
  serverSearch?: {
    order?: string;
    keys: { parallel?: string; serper?: string; deepseek?: string };
  };
  /** The server's own Google AI key for live calls (GOOGLE_AI_API_KEY). */
  serverGeminiKey?: string;
  /** ChatGPT plan sign-in endpoints; defaults are OpenAI's (tests point them at a fake). */
  chatgpt?: { authUrl?: string; apiUrl?: string };
  /** Casama Cloud abuse controls (D-094): free workspaces need a verified owner email for computers. */
  requireVerifiedEmail?: boolean;
  /** The gallery's apps (D-239), so bots can offer connect buttons for them too (D-259). */
  galleryApps?: () => Promise<Array<{ id: string; name: string; composio?: string }>>;
  /** The whole gallery for gallery.search and gallery.suggest (D-315). */
  gallery?: import("@casama/agent").GalleryCatalog;
  /** The coding agents catalog (D-370): the signed gallery's list over the built-in one. */
  codingAgents?: () => Promise<import("@casama/domain").CodingAgentSpec[]>;
}

function loadFixtures(paths: string): FixtureFile[] {
  return paths.split(",").map((p) => {
    const text = readFileSync(p.trim(), "utf8");
    if (p.trim().endsWith(".jsonl")) {
      const turns = text
        .split("\n")
        .filter(Boolean)
        .map((l) => JSON.parse(l) as FixtureTurn);
      return { name: p, turns };
    }
    return JSON.parse(text) as FixtureFile;
  });
}

export function buildGateway(
  opts: Pick<
    WorkerOptions,
    | "modelFixtures"
    | "modelRecord"
    | "maxOutputTokens"
    | "cloudModelRouting"
    | "cloudModelChatRouting"
  > & {
    chatgptFetch?: typeof fetch;
  },
): ModelGateway {
  if (opts.modelFixtures) return new ReplayGateway(loadFixtures(opts.modelFixtures));
  const real = new AiSdkGateway({
    chatgpt: { fetch: opts.chatgptFetch },
    platformRouting: opts.cloudModelRouting,
    platformChatRouting: opts.cloudModelChatRouting,
  });
  const inner = opts.modelRecord ? recordingGateway(real, opts.modelRecord) : real;
  const cap = opts.maxOutputTokens;
  if (!cap) return inner;
  return {
    stream: (req) =>
      inner.stream({ ...req, maxOutputTokens: Math.min(req.maxOutputTokens ?? cap, cap) }),
  };
}

/** Launches DBOS on the application Postgres, in its own `dbos` schema. */
export async function startWorker(opts: WorkerOptions) {
  const handle = opts.db
    ? undefined
    : createDb(opts.databaseUrl, { max: (opts.runConcurrency ?? 20) + 5 });
  const db = opts.db ?? (handle as NonNullable<typeof handle>).db;
  // Encryption at rest (D-136): load workspace keys and follow changes.
  if (handle) await contentKeys.attach(handle.client);
  const fetchOut = createSafeFetch({ exemptCidrs: opts.egressExemptCidrs });
  // OpenAI's public endpoints go through the safe fetch; an admin's override (a local fake in
  // tests, or a proxy) is called directly.
  const customChatGpt = [opts.chatgpt?.authUrl, opts.chatgpt?.apiUrl].some(
    (u) => u && !/^https:\/\/(auth|api)\.openai\.com(\/|$)/.test(u),
  );
  const chatgptFetch = customChatGpt ? fetch : fetchOut;
  const chatgpt = { ...opts.chatgpt, fetch: chatgptFetch };
  const gateway = buildGateway({ ...opts, chatgptFetch });
  const credentials = new CredentialResolver(db, {
    chatgpt,
    aiGateway: opts.aiGateway,
    platformOpenRouterKey: opts.platformOpenRouterKey,
    platformReasoningEffort: opts.platformReasoningEffort,
  });
  const mode = opts.embeddings ?? "auto";
  const embedderFor = async (orgId: string): Promise<Embedder | null> => {
    if (mode === "none") return null;
    if (mode === "hash") return hashEmbedder();
    const cred = await credentials.embeddingCredential(orgId);
    if (cred && opts.billing) cred.model = (await getCloudModels(db)).embedding;
    if (cred) return openAiEmbedder(cred);
    // No OpenAI key of their own: the shared OpenRouter key, on OpenAI's text-embedding-3-small
    // (1536 dimensions, like every stored vector; $0.02 per million tokens) (D-194).
    if (!opts.platformOpenRouterKey) return null;
    return openAiEmbedder({
      provider: "openrouter",
      model: OPENROUTER_EMBEDDING_MODEL,
      apiKey: opts.platformOpenRouterKey,
      baseUrl: opts.providerBases?.openrouter ?? "https://openrouter.ai/api/v1",
      credentialId: PLATFORM_OPENROUTER_CREDENTIAL_ID,
    });
  };
  // Bot computers: the sandbox supervisor, plus personal computers through the API (D-066).
  const extra = {
    ...(opts.local ? { local: new LocalProvider(opts.local) } : {}),
    ...(opts.cloud ? { "casama-cloud": casamaCloudProvider(opts.cloud) } : {}),
  };
  const computers =
    opts.supervisor || Object.keys(extra).length
      ? new ComputerService(
          db,
          opts.supervisor
            ? new SupervisorProvider(opts.supervisor.url, opts.supervisor.token)
            : unavailableProvider(),
          extra,
        )
      : undefined;
  if (computers) computers.requireVerifiedEmail = opts.requireVerifiedEmail ?? false;
  if (computers) computers.rates = computerRates(opts.computerRates);
  if (computers) {
    computers.hostMemoryMb = opts.computerHostMemoryMb ?? 0;
    computers.defaultMemoryMb = opts.computerDefaultMemoryMb ?? 2048;
  }
  const tools = builtinTools({
    db,
    memory: async (orgId) =>
      memoryStoreFor(db, orgId, await embedderFor(orgId), opts.providerBases ? fetch : fetchOut),
    // A bot's reaction goes to the chat app its conversation came from (D-331), like replies.
    fetch: fetchOut,
  });
  if (computers) {
    registerComputerTools(tools);
    registerDesktopTools(tools);
  }
  // Bots that manage bots (D-100).
  registerBotTools(tools, {
    db,
    lockCloudModel: Boolean(opts.platformOpenRouterKey),
  });
  registerSecretRequestTool(tools);
  // The admin bot (D-435): offered only in the instance owner's own chat with the chosen bot.
  const adminBot: AdminBotDeps = {
    db,
    ownerEmails: ownerEmails(opts.instanceAdminEmails),
    billingEnabled: opts.billing?.enabled === true,
    stopComputer: computers
      ? async (id) => {
          await computers.sleep(id);
        }
      : undefined,
  };
  registerAdminTools(tools, adminBot);
  registerSkillTools(tools, { db });
  registerSetupTools(tools, { db });
  // Bots that change their own setup: connections, theme, rules, knowledge, notifications (D-242).
  registerSettingsTools(tools, { db, fetch: fetchOut, galleryApps: opts.galleryApps });
  // Gallery search, suggestion cards and skill drafts (D-315).
  registerGalleryTools(tools, { db, gallery: opts.gallery });
  registerToolsLoad(tools);
  // Coding agents (D-097): on the bot's computer, the user's own computer, or Cursor's cloud.
  registerCodingTools(tools, {
    db,
    computers,
    fetch: opts.providerBases?.cursor ? fetch : fetchOut,
    cursorApiUrl: opts.providerBases?.cursor,
    catalog: opts.codingAgents,
    browserMcp:
      opts.local && opts.publicApiUrl
        ? { publicApiUrl: opts.publicApiUrl, tunnel: opts.local }
        : undefined,
  });

  // A server's own Firebase key first. Without one, a server linked to Casama Cloud sends through
  // the cloud's relay (D-296): only Casama's key can address the store apps.
  const push =
    opts.push ??
    serverPushSender({
      db,
      fcmServiceAccountJson: opts.fcmServiceAccountJson,
      cloud: opts.cloud,
      onRelayError: (e) => opts.logger.warn("push relay", { error: e.message }),
    });
  const notifications = new NotificationService(db, push);
  // Apple Watches' own tokens (D-410): this server's Apple key, else the cloud's relay, since only
  // Casama's key can reach the store's watch app.
  notifications.watch = opts.apns
    ? new ApnsWatchSender(new ApnsClient(opts.apns), {
        appBundleId: opts.apnsAppTopic,
        onError: (info) => opts.logger.warn("watch push", info),
      })
    : push instanceof CloudRelayPushSender
      ? push
      : undefined;
  // The island's pushes (D-324): a followed run's state to the phones that follow it, while the
  // app sleeps. Every run event this worker appends passes by.
  const livePusher = new LiveRunPusher(db, push, {
    onError: (e) => opts.logger.warn("live push", { error: e.message }),
  });
  // A server with no way to push (the recording stand-in) keeps the app-driven behaviour.
  const canPush = Boolean(opts.push) || !(push instanceof RecordingPushSender);
  const stopLive = livePusher.enabled && canPush ? EventBus.observe(livePusher.observe) : () => {};
  // Widget refresh pushes (D-405): run events and inbox rows this worker writes tell the person's
  // widgets to fetch the glance again (Apple with this server's own key, else the cloud's relay).
  const appleWidgets = opts.apns
    ? new ApnsWidgetSender(new ApnsClient(opts.apns), { appBundleId: opts.apnsAppTopic })
    : null;
  const glancePusher =
    opts.widgets || canPush || appleWidgets
      ? new GlancePusher(
          db,
          opts.widgets ??
            widgetPushSender({
              push,
              apple: appleWidgets,
              onNoApple: () =>
                opts.logger.info(
                  "widget pushes to Apple devices are off: set APNS_KEY_P8, APNS_KEY_ID and APNS_TEAM_ID",
                ),
            }),
          { onError: (e) => opts.logger.warn("widget push", { error: e.message }) },
        )
      : null;
  const stopGlance = glancePusher ? EventBus.observe(glancePusher.observe) : () => {};
  if (glancePusher) notifications.onNotify = glancePusher.notified;
  // The server's own search chain (D-384), built once; vendor APIs through the egress guard.
  // Parallel and Serper queries on the server's keys are counted for Admin → Vendors
  // (docs/VENDOR-USAGE-PLAN.md); a workspace's own search key is its own bill and isn't.
  const vendorCounter = createVendorCounter(db, {
    log: (msg, extra) => opts.logger.warn(msg, extra),
  });
  const serverSearch = serverSearchChain({
    order: opts.serverSearch?.order,
    keys: opts.serverSearch?.keys ?? {},
    searxngUrl: opts.searxngUrl,
    fetch: fetchOut,
    bases: opts.providerBases,
  }).map((p) => countingSearch(p, vendorCounter));
  const searchCache = new SearchCache();
  const searchError = (provider: string, err: unknown) =>
    opts.logger.warn("web search provider failed", { provider, error: (err as Error).message });
  const providerKey = async (orgId: string, providers: string[]) => {
    const [row] = await db.execute<{ provider: string; key: string | null }>(sql`
      select c.provider, v.decrypted_secret as key from public.model_credentials c
      left join vault.decrypted_secrets v on v.id = c.vault_secret_id
      where c.org_id = ${orgId}::uuid and c.provider = any(${`{${providers.join(",")}}`}::text[])
      order by array_position(${`{${providers.join(",")}}`}::text[], c.provider), c.created_at limit 1`);
    return row?.key ? row : null;
  };
  let client: DBOSClient | undefined;
  registerAutonomyTools(tools, {
    db,
    // Noto Sans CJK for Chinese, Japanese and Korean PDFs (D-351); the image has it at the default.
    cjkFontDir: process.env.CJK_FONT_DIR || undefined,
    fetch: fetchOut,
    notifications,
    objects: opts.objects,
    // Images (Nano Banana 2.1 at 1K) and video (Gemini Omni Flash 1.2 at 720p) on OpenRouter
    // (D-185, D-189, D-261).
    mediaFor: async (orgId) => {
      const assigned = opts.billing ? await getCloudModels(db) : null;
      const or = await providerKey(orgId, ["openrouter"]);
      // A workspace without its own OpenRouter key draws on the server's shared key, like chat,
      // dictation and memory search (D-186, D-194): on any server that has one, not only with
      // billing. Self-hosted, the usage row is at cost and nobody is charged.
      const key = or?.key || opts.platformOpenRouterKey;
      if (!key) return null;
      const openrouter = new OpenRouterMediaProvider(key, {
        fetch: fetchOut,
        base: opts.providerBases?.openrouter,
        imageModel: assigned?.image,
        resolution: assigned?.image_resolution,
        videoModel: assigned?.video,
      });
      // With billing on, media made on the server's own key is charged with markup and needs
      // credits (D-246).
      const payer = opts.billing?.enabled === true && !or?.key ? "openrouter" : null;
      return new MediaRouter(openrouter, openrouter, { image: payer, video: payer });
    },
    // The check on image and video prompts (D-419): the bot's background model, whatever key or
    // local model it runs on, its cost in the usage ledger like other background calls.
    mediaSafetyFor: (ctx) => (input) =>
      backgroundComplete(
        {
          db,
          gateway,
          credentials,
          billCloudModels: Boolean(opts.billing && opts.platformOpenRouterKey),
          cloudLockedModel: opts.cloudLockedModel,
          cloudModels: opts.billing ? () => getCloudModels(db) : undefined,
        },
        {
          orgId: ctx.orgId,
          botId: ctx.botId,
          userId: ctx.actingUserId ?? null,
          system: input.system,
          text: input.text,
          maxOutputTokens: 200,
          purpose: input.purpose,
        },
      ),
    log: (message, fields) => opts.logger.warn(message, fields),
    // Spoken audio (D-284): Gemini TTS on OpenRouter, like read-aloud (D-261).
    speechFor: async (orgId) => {
      const assigned = opts.billing ? await getCloudModels(db) : null;
      const or = await providerKey(orgId, ["openrouter"]);
      const key = or?.key || opts.platformOpenRouterKey;
      if (!key) return null;
      return {
        key,
        billable: opts.billing?.enabled === true && !or?.key,
        model: assigned?.tts ? openRouterModelId(assigned.tts) : undefined,
        bases: opts.providerBases?.openrouter
          ? { openrouter: opts.providerBases.openrouter }
          : undefined,
      };
    },
    // The workspace's own key, then the server's chain, SearXNG last; cached per workspace (D-384).
    searchFor: async (orgId) => {
      const k = await providerKey(orgId, [...WORKSPACE_SEARCH_PROVIDERS]);
      const own = k?.key
        ? workspaceSearchProvider(
            { provider: k.provider, key: k.key },
            { fetch: fetchOut, bases: opts.providerBases },
          )
        : null;
      return searchProviderFor({
        orgId,
        own,
        server: serverSearch,
        cache: searchCache,
        onError: searchError,
      });
    },
    // Child runs (subagents, delegation) run on their own queue and are awaited from the tool step.
    runChild: async (childRunId) => {
      if (!client) throw new Error("worker not started");
      const handle = await client.enqueue<(id: string) => Promise<{ status: string }>>(
        { queueName: QUEUES.subruns, workflowName: "agentRun", workflowID: childRunId },
        childRunId,
      );
      return handle.getResult({ pollingIntervalMs: 250 });
    },
    startRun: async (runId) => {
      if (!client) throw new Error("worker not started");
      await client.enqueue(
        {
          queueName: QUEUES.runs,
          workflowName: "agentRun",
          workflowID: runId,
          queuePartitionKey: await runPartitionKey(db, runId),
        },
        runId,
      );
    },
  });
  // Linked agents (D-143): the linked bot's run is awaited from the tool, so it uses the sub-run queue.
  registerLinkTools(tools, {
    db,
    notifications,
    fetch: fetchOut,
    startRun: async (runId) => {
      if (!client) throw new Error("worker not started");
      await client.enqueue(
        { queueName: QUEUES.subruns, workflowName: "agentRun", workflowID: runId },
        runId,
      );
    },
  });
  // Check-in scans leave suggestions (D-114).
  registerSuggestionTools(tools, { db, notifications });
  registerWatcherTools(tools, { db });
  registerHighlightTools(tools, { db });
  registerTeachTools(tools, { db });
  registerKnowledgeTools(tools, { db, embedderFor });
  registerReplayTools(tools, { db, fetch: fetchOut });
  registerLoginTools(tools, { db, fetch: fetchOut });
  const fileLinks =
    opts.publicApiUrl && opts.fileLinkKey
      ? { base: opts.publicApiUrl, key: opts.fileLinkKey }
      : undefined;
  registerChannelTools(tools, {
    db,
    fetch: fetchOut,
    local: opts.local,
    objects: opts.objects,
    links: fileLinks,
    hostedMail: opts.hostedMail,
  });
  // Offered only where hosted mail exists; elsewhere the bot never hears of addresses.
  if (opts.hostedMail && opts.mailDomain)
    registerMailTools(tools, {
      db,
      fetch: fetchOut,
      mail: {
        domain: opts.mailDomain,
        sender: opts.hostedMail,
        sendPaused: opts.mailSendPaused ?? false,
      },
      objects: opts.objects,
      logger: opts.logger,
    });
  // iPhone call rings: this server's own Apple key, or Casama Cloud's relay when it is linked
  // (D-296), since only Casama's key can ring the store app.
  const voip =
    opts.voip ??
    (opts.apns
      ? new ApnsVoipSender(opts.apns)
      : push instanceof CloudRelayPushSender
        ? push.voip()
        : undefined);
  registerPhoneCallTools(tools, { db, notifications, voip, declineSecret: opts.callDeclineSecret });
  // Payments (D-142): the workspace's own card issuing account.
  const payments = {
    db,
    providerFor: async (orgId: string) => {
      const [p] = await db.execute<{
        key: string | null;
        cardholder_id: string;
        monthly_cap_usd: string;
        bot_monthly_cap_usd: string;
      }>(sql`
        select v.decrypted_secret as key, p.cardholder_id, p.monthly_cap_usd, p.bot_monthly_cap_usd
        from public.org_payments p left join vault.decrypted_secrets v on v.id = p.vault_secret_id where p.org_id = ${orgId}::uuid`);
      if (!p?.key) return null;
      return {
        provider: new StripeIssuingProvider({
          secretKey: p.key,
          cardholderId: p.cardholder_id,
          apiUrl: opts.providerBases?.stripe,
          fetch: opts.providerBases?.stripe ? fetch : fetchOut,
        }),
        monthlyCapUsd: Number(p.monthly_cap_usd),
        botMonthlyCapUsd: Number(p.bot_monthly_cap_usd),
      };
    },
  };
  registerPaymentTools(tools, payments);
  // Calls for you (D-141): the workspace's own Twilio account. Off in the product for now (PHONE_CALLS).
  if (opts.phoneCalls !== false)
    registerCallTools(tools, {
      db,
      notifications,
      publicApiUrl: opts.publicApiUrl,
      twilioFor: async (orgId) => {
        const [t] = await db.execute<{
          account_sid: string;
          from_number: string;
          token: string | null;
          allow_personal_numbers: boolean;
          daily_cap: number;
        }>(sql`
          select t.account_sid, t.from_number, v.decrypted_secret as token, t.allow_personal_numbers, t.daily_cap
          from public.org_telephony t left join vault.decrypted_secrets v on v.id = t.vault_secret_id where t.org_id = ${orgId}::uuid`);
        if (!t?.token) return null;
        return {
          accountSid: t.account_sid,
          authToken: t.token,
          fromNumber: t.from_number,
          allowPersonal: t.allow_personal_numbers,
          dailyCap: t.daily_cap,
          client: new TwilioClient({
            accountSid: t.account_sid,
            authToken: t.token,
            apiUrl: opts.providerBases?.twilio,
            lookupsUrl: opts.providerBases?.twilioLookups,
            fetch: opts.providerBases?.twilio ? fetch : fetchOut,
          }),
        };
      },
    });
  // Device connections (D-149): the person's own phone and computer data, per-bot grants.
  registerDeviceTools(tools, { db, waitMs: opts.deviceWaitMs });
  // Desktop context (D-152): file search on the person's own computer.
  registerDesktopContextTools(tools, { db });
  // Paid data (D-138): the workspace's own Treg key, else Casama's resale key when it's on.
  registerDataTools(tools, {
    db,
    dataFor: async (orgId) => {
      const tregFetch = opts.providerBases?.treg ? fetch : fetchOut;
      const own = await providerKey(orgId, ["treg"]);
      if (own?.key)
        return {
          provider: new TregProvider({
            key: own.key,
            base: opts.providerBases?.treg,
            fetch: tregFetch,
          }),
          resale: false,
        };
      if (opts.dataResale)
        return {
          provider: new TregProvider({
            key: opts.dataResale.tregKey,
            base: opts.dataResale.tregUrl ?? opts.providerBases?.treg,
            fetch: tregFetch,
          }),
          resale: true,
        };
      return null;
    },
  });
  registerPageTools(tools, {
    db,
    pagesUrl: opts.pagesUrl ?? "http://localhost:8790",
    objects: opts.objects,
  });
  const buying = opts.domains?.buying;
  const domainsEnv = opts.domains?.env;
  registerSiteTools(tools, {
    db,
    zone: opts.sitesZone ?? null,
    requireVerifiedEmail: opts.requireVerifiedEmail,
    domainSearch:
      buying && domainsEnv
        ? async (orgId, query) => {
            if (!(await sitesSettings(domainsEnv, db)).buy_domains) return null;
            const r = await searchDomains(
              { db, env: domainsEnv, registrar: buying.registrar },
              { orgId, query },
            );
            return {
              items: r.items,
              findUrl: (name) =>
                appLink(domainsEnv, `/settings/domains/find?q=${encodeURIComponent(name)}`),
            };
          }
        : undefined,
  });
  // The Library (D-274, D-276): a bot finds its own earlier work and keeps files on purpose.
  registerLibraryTools(tools, { db, objects: opts.objects });
  // Projects (D-113): the tools start planning runs; the heartbeat lives in the minute tick.
  registerProjectTools(tools, {
    db,
    notifications,
    startRun: async (runId) => {
      if (!client) throw new Error("worker not started");
      await client.enqueue(
        {
          queueName: QUEUES.runs,
          workflowName: "agentRun",
          workflowID: runId,
          queuePartitionKey: await runPartitionKey(db, runId),
        },
        runId,
      );
    },
  });
  configureWorkflows({
    db,
    vendorUsage: opts.vendorUsage,
    slots: new RunSlots(
      opts.runConcurrency ?? 20,
      Math.min(opts.runWorkspaceConcurrency ?? 5, opts.runConcurrency ?? 20),
    ),
    billing: opts.billing,
    telemetry: opts.telemetry,
    gateway,
    computers,
    fetch: fetchOut,
    offlineModels: !!opts.modelFixtures,
    chatgpt,
    voice: {
      db,
      key: providerKey,
      bases: opts.providerBases,
      fetch: opts.providerBases ? fetch : fetchOut,
      tools,
      computers: !!computers,
      geminiLiveModel: opts.geminiLiveModel,
      voiceContext: opts.voiceContext,
      serverGeminiKey: opts.serverGeminiKey,
      cloudModels: opts.billing ? () => getCloudModels(db) : undefined,
      platformOpenRouterKey: opts.platformOpenRouterKey,
      billPlatform: opts.billing?.enabled === true,
    },
    voip,
    auditForwarding: opts.auditForwarding,
    referrals: opts.referrals,
    casamaLink: opts.casamaLink ? { ...opts.casamaLink, log: opts.logger } : undefined,
    domains: opts.domains ?? undefined,
    leaveNow: {
      fetch: opts.providerBases?.google_maps || opts.providerBases?.mapbox ? fetch : fetchOut,
      bases: opts.providerBases,
      mapsKey: async (orgId) => {
        const k = await providerKey(orgId, ["google_maps", "mapbox"]);
        return k?.key ? { provider: k.provider as "google_maps" | "mapbox", key: k.key } : null;
      },
    },
    agent: {
      payments,
      db,
      gateway,
      credentials,
      embedderFor,
      tools,
      computers,
      objects: opts.objects,
      notifications,
      fetch: fetchOut,
      logger: opts.logger,
      local: opts.local,
      fileLinks,
      hostedMail: opts.hostedMail,
      ownUrls: opts.ownUrls,
      lazyToolsThreshold: opts.lazyToolsThreshold,
      instanceAdmin: adminRunCheck(adminBot),
      startRun: async (runId) => {
        if (!client) throw new Error("worker not started");
        await client.enqueue(
          {
            queueName: QUEUES.runs,
            workflowName: "agentRun",
            workflowID: runId,
            queuePartitionKey: await runPartitionKey(db, runId),
          },
          runId,
        );
      },
      langfuse: opts.langfuse ? new LangfuseSink(opts.langfuse) : undefined,
      billCloudModels: Boolean(opts.billing && opts.platformOpenRouterKey),
      cloudLockedModel: opts.cloudLockedModel,
      cloudModels: opts.billing ? () => getCloudModels(db) : undefined,
    },
  });

  DBOS.setConfig({
    name: "casama",
    systemDatabaseUrl: opts.databaseUrl,
    systemDatabaseSchemaName: "dbos",
    logLevel: opts.logLevel ?? "info",
    // One version across deploys (D-228). DBOS otherwise stamps each build with a hash of its
    // code and only recovers workflows carrying its own hash, so a run waiting on an approval or a
    // key when the worker is redeployed was never picked up again: answering it did nothing, and
    // the chat replayed the stuck run under every reopen. A run whose recorded steps no longer
    // match the code now fails (agentRunWorkflow marks it failed) instead of hanging forever.
    applicationVersion: process.env.DBOS__APPVERSION || "casama",
  });
  await DBOS.launch();
  // The API enqueues runs through DBOS's tables, which belong to the worker's role (D-095). On
  // Supabase the API's role isn't a superuser, so the worker (the owner) grants it access
  // (audit 2026-11: every chat message failed on self-hosted installs).
  if (opts.apiDatabaseRole) {
    const role = opts.apiDatabaseRole.replace(/"/g, "");
    await db
      .execute(
        sql.raw(
          `grant usage on schema dbos to "${role}"; grant all on all tables in schema dbos to "${role}"; grant all on all sequences in schema dbos to "${role}"`,
        ),
      )
      .catch((e: Error) =>
        opts.logger?.warn?.("couldn't grant the API role access to dbos", { error: e.message }),
      );
  }
  // Dispatch polling: runs and voice are latency-sensitive (a run should start, and a forwarded
  // voice tool call answer, well within a second); background queues poll less often.
  // Runs are partitioned by workspace (billing audit 2026-11-17); queued runs from before get
  // their key first, or they'd never start.
  await keyQueuedRuns(db).catch((e: Error) =>
    opts.logger?.warn?.("couldn't key queued runs", { error: e.message }),
  );
  // How many runs work at once is kept by RunSlots (D-413). The queue admits more than that,
  // because it counts a run until it ends: runs waiting for a person would otherwise use up the
  // places and leave every new message queued. Its limits now only bound how many started runs
  // (working, waiting for a slot, or waiting for a person) a worker holds.
  const perWorkspace = Math.min(opts.runWorkspaceConcurrency ?? 5, opts.runConcurrency ?? 20);
  await DBOS.registerQueue(QUEUES.runs, {
    workerConcurrency: (opts.runConcurrency ?? 20) * STARTED_PER_WORKING,
    ...(perWorkspace > 0 ? { partitionConcurrency: perWorkspace * STARTED_PER_WORKING } : {}),
    minPollingIntervalMs: 100,
  });
  await DBOS.registerQueue(QUEUES.system, { workerConcurrency: 5, minPollingIntervalMs: 250 });
  await DBOS.registerQueue(QUEUES.subruns, {
    workerConcurrency: opts.runConcurrency ?? 20,
    minPollingIntervalMs: 200,
  });
  await DBOS.registerQueue(QUEUES.voice, { workerConcurrency: 20, minPollingIntervalMs: 50 });
  client = await DBOSClient.create({
    systemDatabaseUrl: opts.databaseUrl,
    systemDatabaseSchemaName: "dbos",
  });
  await DBOS.applySchedules([
    { scheduleName: "maintenance-hourly", workflowFn: maintenanceWorkflow, schedule: "0 * * * *" },
    { scheduleName: "computers-idle", workflowFn: computersIdleWorkflow, schedule: "* * * * *" },
    { scheduleName: "routines-tick", workflowFn: routinesTickWorkflow, schedule: "* * * * *" },
    ...(opts.domains
      ? [{ scheduleName: "domains-minute", workflowFn: domainsWorkflow, schedule: "* * * * *" }]
      : []),
    { scheduleName: "privacy-daily", workflowFn: privacyWorkflow, schedule: "17 3 * * *" },
    { scheduleName: "analytics-daily", workflowFn: analyticsDailyWorkflow, schedule: "20 0 * * *" },
    ...(opts.telemetry
      ? [
          {
            scheduleName: "telemetry-weekly",
            workflowFn: telemetryWorkflow,
            schedule: "23 4 * * 1",
          },
        ]
      : []),
    ...(opts.billing?.enabled
      ? [
          {
            scheduleName: "billing-settle",
            workflowFn: billingSettleWorkflow,
            schedule: "* * * * *",
          },
        ]
      : []),
  ]);
  const stopPrices = opts.livePrices
    ? startLivePrices({
        url: opts.livePrices.url,
        onError: (e) => opts.logger.warn("model prices not refreshed", { error: e.message }),
      })
    : undefined;
  opts.logger.info("worker started", {
    fixtures: !!opts.modelFixtures,
    push:
      push instanceof FcmPushSender
        ? "fcm"
        : push instanceof CloudRelayPushSender
          ? "relay"
          : opts.push
            ? "custom"
            : "off",
  });
  return {
    async stop() {
      // Steps in flight finish and are saved; runs hold at their next step for the next worker
      // (D-402). Only a step longer than the drain is cut, and D-268 covers running it again.
      const cut = await drainSteps(opts.drainMs ?? 45_000);
      opts.logger.info("worker drained", { steps_cut: cut });
      stopLive();
      stopGlance();
      glancePusher?.stop();
      stopPrices?.();
      await client?.destroy();
      await DBOS.shutdown();
      await handle?.close();
    },
  };
}

export {
  agentRunWorkflow,
  listCredentialModelsWorkflow,
  pingWorkflow,
  QUEUES,
  testCredentialWorkflow,
  WORKFLOWS,
} from "./workflows.ts";
