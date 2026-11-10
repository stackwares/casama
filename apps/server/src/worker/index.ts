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
  MemoryService,
  type ModelGateway,
  NotificationService,
  openAiEmbedder,
  type PushSender,
  RecordingPushSender,
  ReplayGateway,
  recordingGateway,
  registerAutonomyTools,
  registerCodingTools,
  registerComputerTools,
  registerDesktopTools,
  TavilySearchProvider,
} from "@kasama/agent";
import { createDb, type Database } from "@kasama/db";
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
  /** Private address ranges the worker may call (local development and tests only). */
  egressExemptCidrs?: string[];
  /** Base URL overrides for provider APIs (tests). */
  providerBases?: {
    fal?: string;
    brave?: string;
    tavily?: string;
    openai?: string;
    deepgram?: string;
    elevenlabs?: string;
    cartesia?: string;
    fish_audio?: string;
    cursor?: string;
  };
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
  const fetchOut = createSafeFetch({ exemptCidrs: opts.egressExemptCidrs });
  // OpenAI's public endpoints go through the safe fetch; an admin's override (a local fake in
  // tests, or a proxy) is called directly.
  const customChatGpt = [opts.chatgpt?.authUrl, opts.chatgpt?.apiUrl].some(
    (u) => u && !/^https:\/\/(auth|api)\.openai\.com(\/|$)/.test(u),
  );
  const chatgptFetch = customChatGpt ? fetch : fetchOut;
  const chatgpt = { ...opts.chatgpt, fetch: chatgptFetch };
  const gateway = buildGateway({ ...opts, chatgptFetch });
  const credentials = new CredentialResolver(db, { chatgpt });
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
    memory: async (orgId) => new MemoryService(db, await embedderFor(orgId)),
  });
  if (computers) {
    registerComputerTools(tools);
    registerDesktopTools(tools);
  }
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
    agent: {
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
    },
  });

  DBOS.setConfig({
    name: "kasama",
    systemDatabaseUrl: opts.databaseUrl,
    systemDatabaseSchemaName: "dbos",
    logLevel: opts.logLevel ?? "info",
  });
  await DBOS.launch();
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
