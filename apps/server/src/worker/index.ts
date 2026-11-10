import { readFileSync } from "node:fs";
import { DBOS, DBOSClient } from "@dbos-inc/dbos-sdk";
import {
  AiSdkGateway,
  BraveSearchProvider,
  builtinTools,
  ComputerService,
  CredentialResolver,
  createSafeFetch,
  type Embedder,
  FalMediaProvider,
  FcmPushSender,
  type FixtureFile,
  type FixtureTurn,
  hashEmbedder,
  LangfuseSink,
  MemoryService,
  type ModelGateway,
  NotificationService,
  openAiEmbedder,
  type PushSender,
  RecordingPushSender,
  ReplayGateway,
  recordingGateway,
  registerAutonomyTools,
  registerBotTools,
  registerCodingTools,
  registerComputerTools,
  registerDesktopTools,
  registerPageTools,
  registerTeachTools,
  registerKnowledgeTools,
  registerReplayTools,
  registerLoginTools,
  registerChannelTools,
  registerPhoneCallTools,
  registerDataTools,
  registerDeviceTools,
  registerDesktopContextTools,
  registerCallTools,
  registerPaymentTools,
  registerLinkTools,
  StripeIssuingProvider,
  TwilioClient,
  TregProvider,
  memoryStoreFor,
  ApnsVoipSender,
  type VoipSender,
  registerProjectTools,
  registerSecretRequestTool,
  registerSetupTools,
  registerSkillTools,
  registerSuggestionTools,
  registerToolsLoad,
  registerWatcherTools,
  TavilySearchProvider,
} from "@kasama/agent";
import { contentKeys, createDb, type Database } from "@kasama/db";
import type { Logger } from "@kasama/observability";
import { LocalProvider, SupervisorProvider, unavailableProvider } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import { kasamaCloudProvider } from "../billing/index.ts";
import {
  billingSettleWorkflow,
  computersIdleWorkflow,
  configureWorkflows,
  maintenanceWorkflow,
  privacyWorkflow,
  QUEUES,
  routinesTickWorkflow,
  telemetryWorkflow,
} from "./workflows.ts";

export interface WorkerOptions {
  databaseUrl: string;
  /** The pages origin's public address, for public page links (D-119). */
  pagesUrl?: string;
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
  embeddings?: "auto" | "none" | "hash";
  runConcurrency?: number;
  db?: Database;
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
    fal?: string;
    brave?: string;
    tavily?: string;
    openai?: string;
    deepgram?: string;
    elevenlabs?: string;
    cartesia?: string;
    fish_audio?: string;
    cursor?: string;
    treg?: string;
    twilio?: string;
    twilioLookups?: string;
    stripe?: string;
  };
  /** The API's public address, for Twilio's call webhooks and media streams (D-141). */
  publicApiUrl?: string;
  /** Audit-log forwarding (D-146): on when the enterprise license includes it. */
  auditForwarding?: boolean;
  /** Cloudflare AI Gateway for model calls (D-145). */
  aiGateway?: import("@kasama/agent").AiGatewayConfig;
  /** Paid data resale on Kasama Cloud (D-138): Kasama's Treg key, used only when resale is on. */
  dataResale?: { tregKey: string; tregUrl?: string };
  /** Billing (Kasama Cloud only); settles usage into credits every minute. */
  billing?: import("../billing/service.ts").BillingService;
  /** Opt-in anonymous telemetry (D-074); unset = off. */
  telemetry?: { url: string; version: string };
  /** Cloud Connect (self-hosted side): the `kasama-cloud` computer provider. */
  cloud?: { url: string; key: string };
  /** Realtime voice model (default gpt-realtime-2.1). */
  realtimeModel?: string;
  /** ChatGPT plan sign-in endpoints; defaults are OpenAI's (tests point them at a fake). */
  chatgpt?: { authUrl?: string; apiUrl?: string };
  /** Kasama Cloud abuse controls (D-094): free workspaces need a verified owner email for computers. */
  requireVerifiedEmail?: boolean;
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
  opts: Pick<WorkerOptions, "modelFixtures" | "modelRecord" | "maxOutputTokens"> & {
    chatgptFetch?: typeof fetch;
  },
): ModelGateway {
  if (opts.modelFixtures) return new ReplayGateway(loadFixtures(opts.modelFixtures));
  const real = new AiSdkGateway({ chatgpt: { fetch: opts.chatgptFetch } });
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
  const credentials = new CredentialResolver(db, { chatgpt, aiGateway: opts.aiGateway });
  const mode = opts.embeddings ?? "auto";
  const embedderFor = async (orgId: string): Promise<Embedder | null> => {
    if (mode === "none") return null;
    if (mode === "hash") return hashEmbedder();
    const cred = await credentials.embeddingCredential(orgId);
    return cred ? openAiEmbedder(cred) : null;
  };
  // Bot computers: the sandbox supervisor, plus personal computers through the API (D-066).
  const extra = {
    ...(opts.local ? { local: new LocalProvider(opts.local) } : {}),
    ...(opts.cloud ? { "kasama-cloud": kasamaCloudProvider(opts.cloud) } : {}),
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
  const tools = builtinTools({
    db,
    memory: async (orgId) => memoryStoreFor(db, orgId, await embedderFor(orgId), opts.providerBases ? fetch : fetchOut),
  });
  if (computers) {
    registerComputerTools(tools);
    registerDesktopTools(tools);
  }
  // Bots that manage bots (D-100).
  registerBotTools(tools, { db });
  registerSecretRequestTool(tools);
  registerSkillTools(tools, { db });
  registerSetupTools(tools, { db });
  registerToolsLoad(tools);
  // Coding agents (D-097): on the bot's computer, the user's own computer, or Cursor's cloud.
  registerCodingTools(tools, {
    db,
    computers,
    fetch: opts.providerBases?.cursor ? fetch : fetchOut,
    cursorApiUrl: opts.providerBases?.cursor,
  });

  const push =
    opts.push ??
    (opts.fcmServiceAccountJson
      ? new FcmPushSender(opts.fcmServiceAccountJson)
      : new RecordingPushSender());
  const notifications = new NotificationService(db, push);
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
    fetch: fetchOut,
    notifications,
    mediaFor: async (orgId) => {
      const k = await providerKey(orgId, ["fal"]);
      return k?.key
        ? new FalMediaProvider({
            apiKey: k.key,
            fetch: fetchOut,
            syncBase: opts.providerBases?.fal,
            queueBase: opts.providerBases?.fal,
          })
        : null;
    },
    searchFor: async (orgId) => {
      const k = await providerKey(orgId, ["brave_search", "tavily"]);
      if (!k?.key) return null;
      return k.provider === "tavily"
        ? new TavilySearchProvider(k.key, { base: opts.providerBases?.tavily, fetch: fetchOut })
        : new BraveSearchProvider(k.key, { base: opts.providerBases?.brave, fetch: fetchOut });
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
        { queueName: QUEUES.runs, workflowName: "agentRun", workflowID: runId },
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
      await client.enqueue({ queueName: QUEUES.subruns, workflowName: "agentRun", workflowID: runId }, runId);
    },
  });
  // Check-in scans leave suggestions (D-114).
  registerSuggestionTools(tools, { db, notifications });
  registerWatcherTools(tools, { db });
  registerTeachTools(tools, { db });
  registerKnowledgeTools(tools, { db, embedderFor });
  registerReplayTools(tools, { db, fetch: fetchOut });
  registerLoginTools(tools, { db, fetch: fetchOut });
  registerChannelTools(tools, { db, fetch: fetchOut, local: opts.local });
  const voip = opts.voip ?? (opts.apns ? new ApnsVoipSender(opts.apns) : undefined);
  registerPhoneCallTools(tools, { db, notifications, voip });
  // Payments (D-142): the workspace's own card issuing account.
  const payments = {
    db,
    providerFor: async (orgId: string) => {
      const [p] = await db.execute<{ key: string | null; cardholder_id: string; monthly_cap_usd: string; bot_monthly_cap_usd: string }>(sql`
        select v.decrypted_secret as key, p.cardholder_id, p.monthly_cap_usd, p.bot_monthly_cap_usd
        from public.org_payments p left join vault.decrypted_secrets v on v.id = p.vault_secret_id where p.org_id = ${orgId}::uuid`);
      if (!p?.key) return null;
      return {
        provider: new StripeIssuingProvider({ secretKey: p.key, cardholderId: p.cardholder_id, apiUrl: opts.providerBases?.stripe, fetch: opts.providerBases?.stripe ? fetch : fetchOut }),
        monthlyCapUsd: Number(p.monthly_cap_usd),
        botMonthlyCapUsd: Number(p.bot_monthly_cap_usd),
      };
    },
  };
  registerPaymentTools(tools, payments);
  // Calls for you (D-141): the workspace's own Twilio account.
  registerCallTools(tools, {
    db,
    notifications,
    publicApiUrl: opts.publicApiUrl,
    twilioFor: async (orgId) => {
      const [t] = await db.execute<{ account_sid: string; from_number: string; token: string | null; allow_personal_numbers: boolean; daily_cap: number }>(sql`
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
  // Paid data (D-138): the workspace's own Treg key, else Kasama's resale key when it's on.
  registerDataTools(tools, {
    db,
    dataFor: async (orgId) => {
      const tregFetch = opts.providerBases?.treg ? fetch : fetchOut;
      const own = await providerKey(orgId, ["treg"]);
      if (own?.key) return { provider: new TregProvider({ key: own.key, base: opts.providerBases?.treg, fetch: tregFetch }), resale: false };
      if (opts.dataResale)
        return { provider: new TregProvider({ key: opts.dataResale.tregKey, base: opts.dataResale.tregUrl ?? opts.providerBases?.treg, fetch: tregFetch }), resale: true };
      return null;
    },
  });
  registerPageTools(tools, { db, pagesUrl: opts.pagesUrl ?? "http://localhost:8790" });
  // Projects (D-113): the tools start planning runs; the heartbeat lives in the minute tick.
  registerProjectTools(tools, {
    db,
    notifications,
    startRun: async (runId) => {
      if (!client) throw new Error("worker not started");
      await client.enqueue(
        { queueName: QUEUES.runs, workflowName: "agentRun", workflowID: runId },
        runId,
      );
    },
  });
  configureWorkflows({
    db,
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
      realtimeModel: opts.realtimeModel,
    },
    voip,
    auditForwarding: opts.auditForwarding,
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
      notifications,
      fetch: fetchOut,
      logger: opts.logger,
      local: opts.local,
      lazyToolsThreshold: opts.lazyToolsThreshold,
      startRun: async (runId) => {
        if (!client) throw new Error("worker not started");
        await client.enqueue({ queueName: QUEUES.runs, workflowName: "agentRun", workflowID: runId }, runId);
      },
      langfuse: opts.langfuse ? new LangfuseSink(opts.langfuse) : undefined,
    },
  });

  DBOS.setConfig({
    name: "kasama",
    systemDatabaseUrl: opts.databaseUrl,
    systemDatabaseSchemaName: "dbos",
    logLevel: opts.logLevel ?? "info",
  });
  await DBOS.launch();
  // The API enqueues runs through DBOS's tables, which belong to the worker's role (D-095). On
  // Supabase the API's role isn't a superuser, so the worker (the owner) grants it access
  // (audit 2026-11: every chat message failed on self-hosted installs).
  if (opts.apiDatabaseRole) {
    const role = opts.apiDatabaseRole.replace(/"/g, "");
    await db
      .execute(sql.raw(`grant usage on schema dbos to "${role}"; grant all on all tables in schema dbos to "${role}"; grant all on all sequences in schema dbos to "${role}"`))
      .catch((e: Error) => opts.logger?.warn?.("couldn't grant the API role access to dbos", { error: e.message }));
  }
  // Dispatch polling: runs and voice are latency-sensitive (a run should start, and a forwarded
  // voice tool call answer, well within a second); background queues poll less often.
  await DBOS.registerQueue(QUEUES.runs, {
    workerConcurrency: opts.runConcurrency ?? 20,
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
    { scheduleName: "privacy-daily", workflowFn: privacyWorkflow, schedule: "17 3 * * *" },
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
  opts.logger.info("worker started", {
    fixtures: !!opts.modelFixtures,
    push: push instanceof FcmPushSender ? "fcm" : opts.push ? "custom" : "off",
  });
  return {
    async stop() {
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
